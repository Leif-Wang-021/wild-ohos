import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/services/offline_library.dart';
import 'package:wild/src/rust/api/wenku8.dart' as w8;
import 'package:wild/utils/log.dart';
import 'package:wild/utils/wenku8_parse.dart';

import '../../src/rust/wenku8/models.dart';
import '../../src/rust/api/database.dart';

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

/// 需要通过 WebView 绕过 Cloudflare 抓取详情/目录。
class NovelInfoChallenge extends NovelInfoState {
  final String apiHost;

  NovelInfoChallenge(this.apiHost);
}

class NovelInfoCubit extends Cubit<NovelInfoState> {
  final String novelId;
  List<Volume> _volumes = [];

  /// 该书是否位于书架内（由页面按实时书架状态传入），决定是否缓存详情。
  bool inBookshelf = false;

  NovelInfoCubit(this.novelId) : super(NovelInfoInitial());

  List<Volume> get volumes => _volumes;

  String _apiHost = 'https://www.wenku8.net';
  String get apiHost => _apiHost;

  /// 本地优先 + 后台刷新：已下载/已缓存的小说先用本地目录上屏，再联网更新。
  ///
  /// 注意：仅当本地数据**含目录**时才短路跳过联网；若只有元数据（书名/作者），
  /// 仍需联网或走 WebView 兜底以获取目录。
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
        final readingHistory = await w8.novelHistoryById(novelId: novelId);
        emit(
          NovelInfoLoaded(
            novelInfo: offline.info,
            volumes: offline.volumes,
            readingHistory: readingHistory,
          ),
        );
        hasLocal = true;
        Log.info(
          'NovelInfoCubit',
          'loaded local $novelId (volumes=${offline.volumes.length})',
        );
      }
    } catch (e) {
      Log.warning('NovelInfoCubit', 'local load failed: $e');
    }

    // 2) 联网刷新（本地仅元数据时也要联网补齐目录）
    if (!hasLocal) emit(NovelInfoLoading());
    try {
      final novelInfo = await w8.novelInfo(aid: novelId);
      _volumes = await w8.novelReader(aid: novelId);
      final readingHistory = await w8.novelHistoryById(novelId: novelId);
      emit(
        NovelInfoLoaded(
          novelInfo: novelInfo,
          volumes: _volumes,
          readingHistory: readingHistory,
        ),
      );
      // 仅缓存**书架内**小说的详情+目录，供断网时展示。
      if (_volumes.isNotEmpty) {
        unawaited(
          OfflineLibrary.instance.cacheShelfDetail(
            novelId,
            novelInfo,
            _volumes,
            inBookshelf: inBookshelf,
          ),
        );
      }
    } catch (e, s) {
      Log.error('NovelInfoCubit', 'load failed: $e', s);
      // 已有本地**目录**时静默保留；仅有元数据则继续走 WebView 兜底补目录。
      if (hasVolumes) return;
      if (Wenku8Parse.needsWebViewFallback(e)) {
        try {
          final host = await w8.getApiHost();
          _apiHost = host.isEmpty ? 'https://www.wenku8.net' : host;
        } catch (_) {}
        emit(NovelInfoChallenge(_apiHost));
        return;
      }
      if (hasLocal) return;
      emit(NovelInfoError(e.toString()));
    }
  }

  /// WebView 抓取详情页成功后调用。
  void applyWebViewInfo(String json) {
    try {
      final info = Wenku8Parse.novelInfo(json);
      Log.info('NovelInfoCubit', 'webview info ok: ${info.title}');
      emit(
        NovelInfoLoaded(
          novelInfo: info,
          volumes: _volumes,
        ),
      );
    } catch (e, s) {
      Log.error('NovelInfoCubit', 'parse webview info failed: $e', s);
      emit(NovelInfoError('解析详情失败: $e'));
    }
  }

  /// WebView 抓取章节目录成功后调用（与详情合并）。
  void applyWebViewVolumes(String json, NovelInfo info) {
    try {
      _volumes = Wenku8Parse.volumeList(json);
      Log.info('NovelInfoCubit', 'webview volumes ok: ${_volumes.length}');
      emit(
        NovelInfoLoaded(
          novelInfo: info,
          volumes: _volumes,
        ),
      );
      if (_volumes.isNotEmpty) {
        unawaited(OfflineLibrary.instance.cacheShelfDetail(novelId, info, _volumes));
      }
    } catch (e, s) {
      Log.error('NovelInfoCubit', 'parse webview volumes failed: $e', s);
      emit(NovelInfoError('解析目录失败: $e'));
    }
  }

  void setError(String message) {
    Log.error('NovelInfoCubit', 'webview error: $message');
    emit(NovelInfoError(message));
  }

  Future<void> loadHistory() async {
    final readingHistory = await w8.novelHistoryById(novelId: novelId);
    if (state is NovelInfoLoaded) {
      final currentState = state as NovelInfoLoaded;
      emit(
        NovelInfoLoaded(
          novelInfo: currentState.novelInfo,
          volumes: currentState.volumes,
          readingHistory: readingHistory,
        ),
      );
    }
  }
}
