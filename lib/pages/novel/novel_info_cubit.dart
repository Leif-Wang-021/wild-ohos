import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/services/offline_library.dart';
import 'package:wild/services/wenku8_repo.dart';
import 'package:wild/src/rust/api/wenku8.dart' as w8;
import 'package:wild/utils/log.dart';

import '../../src/rust/wenku8/models.dart';

abstract class NovelInfoState {}

class NovelInfoInitial extends NovelInfoState {}

class NovelInfoLoading extends NovelInfoState {}

class NovelInfoLoaded extends NovelInfoState {
  final NovelInfo novelInfo;
  final List<Volume> volumes;
  final w8.ReadingHistory? readingHistory;

  NovelInfoLoaded({
    required this.novelInfo,
    required this.volumes,
    this.readingHistory,
  });
}

class NovelInfoError extends NovelInfoState {
  final String message;

  NovelInfoError(this.message);
}

/// 小说详情 + 目录。
///
/// 本地优先（已下载/已缓存则先用本地），联网部分统一走 [Wenku8Repo]
/// （唯一常驻 WebView 会话，内置缓存/去重/冷却/重试）。
class NovelInfoCubit extends Cubit<NovelInfoState> {
  final String novelId;
  List<Volume> _volumes = [];

  NovelInfoCubit(this.novelId) : super(NovelInfoInitial());

  List<Volume> get volumes => _volumes;

  Future<void> load() async {
    bool hasLocal = false;
    bool hasVolumes = false;

    // 1) 本地已下载/已缓存内容（离线可用）
    try {
      final offline = await OfflineLibrary.instance.load(novelId);
      if (offline != null) {
        if (offline.volumes.isNotEmpty) {
          _volumes = offline.volumes;
          hasVolumes = true;
        }
        final history = await w8.novelHistoryById(novelId: novelId);
        emit(
          NovelInfoLoaded(
            novelInfo: offline.info,
            volumes: offline.volumes,
            readingHistory: history,
          ),
        );
        hasLocal = true;
        Log.info('NovelInfoCubit', 'loaded local $novelId (vol=${offline.volumes.length})');
      }
    } catch (e) {
      Log.warning('NovelInfoCubit', 'local load failed: $e');
    }

    // 2) 联网刷新（本地仅有元数据时也要补齐目录）
    if (!hasLocal) emit(NovelInfoLoading());
    try {
      final info = await Wenku8Repo.instance.novelInfo(novelId);
      final volumes = await Wenku8Repo.instance.novelReader(novelId);
      if (info == null || volumes.isEmpty) {
        if (hasVolumes) return;
        if (hasLocal) return;
        emit(NovelInfoError('加载失败，请下拉刷新重试'));
        return;
      }
      _volumes = volumes;
      final history = await w8.novelHistoryById(novelId: novelId);
      emit(
        NovelInfoLoaded(
          novelInfo: info,
          volumes: volumes,
          readingHistory: history,
        ),
      );
      // 缓存书架内小说的详情+目录，供断网时展示。
      await OfflineLibrary.instance.cacheShelfDetail(novelId, info, volumes);
    } catch (e, s) {
      Log.error('NovelInfoCubit', 'load failed: $e', s);
      if (hasVolumes || hasLocal) return;
      emit(NovelInfoError('加载失败，请下拉刷新重试'));
    }
  }

  Future<void> loadHistory() async {
    final readingHistory = await w8.novelHistoryById(novelId: novelId);
    if (state is NovelInfoLoaded) {
      final current = state as NovelInfoLoaded;
      emit(
        NovelInfoLoaded(
          novelInfo: current.novelInfo,
          volumes: current.volumes,
          readingHistory: readingHistory,
        ),
      );
    }
  }
}
