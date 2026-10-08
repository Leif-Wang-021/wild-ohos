import 'dart:async';

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

  /// 本地兜底数据（合成目录/元数据），联网失败时回退展示。
  List<Volume>? _fallbackVolumes;
  NovelInfo? _fallbackInfo;

  NovelInfoCubit(this.novelId) : super(NovelInfoInitial());

  List<Volume> get volumes => _volumes;

  /// 安全 emit：若 cubit 已关闭（页面已退出）则忽略，避免
  /// `Cannot emit new states after calling close` 异常与卡顿。
  void _safeEmit(NovelInfoState next) {
    if (isClosed) return;
    emit(next);
  }

  Future<void> load() async {
    bool hasLocal = false;
    bool hasVolumes = false;

    // 1) 本地已下载/已缓存内容（离线可用）
    try {
      final offline = await OfflineLibrary.instance.load(novelId);
      if (isClosed) return;
      if (offline != null) {
        // 仅当本地目录为**真实数据**（非文件扫描合成的「第 N 章」）时才视为
        // 已有目录；否则仍需联网补齐真实目录。
        if (offline.volumes.isNotEmpty && offline.realVolumes) {
          _volumes = offline.volumes;
          hasVolumes = true;
        }
        // 无网络时至少有可读内容也要先展示。
        _fallbackVolumes = offline.volumes;
        _fallbackInfo = offline.info;
        final history = await w8.novelHistoryById(novelId: novelId);
        if (isClosed) return;
        _safeEmit(
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
    if (isClosed) return;

    // 2) 联网刷新（本地仅有元数据时也要补齐目录）
    //
    // 重要：本地**已有完整目录**时，直接返回，不再联网。
    // 之前无论本地是否有目录都联网刷新，导致打开详情页要排队等唯一 WebView
    // 会话（最长数秒），这是详情页卡顿的主因。
    if (hasVolumes) return;
    if (!hasLocal) _safeEmit(NovelInfoLoading());
    try {
      final info = await Wenku8Repo.instance.novelInfo(novelId);
      if (isClosed) return;
      // 先拿到详情即可渲染基础信息（标题/作者/简介/动画化），不等目录。
      if (info != null) {
        _safeEmit(NovelInfoLoaded(novelInfo: info, volumes: _volumes));
      }
      final volumes = await Wenku8Repo.instance.novelReader(novelId);
      if (isClosed) return;
      if (info == null || volumes.isEmpty) {
        if (hasLocal) return;
        // 联网失败：回退到本地兜底（如合成目录/元数据），保证仍可阅读。
        if (_fallbackInfo != null) {
          _safeEmit(
            NovelInfoLoaded(
              novelInfo: _fallbackInfo!,
              volumes: _fallbackVolumes ?? const [],
            ),
          );
          return;
        }
        _safeEmit(NovelInfoError('加载失败，请下拉刷新重试'));
        return;
      }
      _volumes = volumes;
      final history = await w8.novelHistoryById(novelId: novelId);
      if (isClosed) return;
      _safeEmit(
        NovelInfoLoaded(
          novelInfo: info,
          volumes: volumes,
          readingHistory: history,
        ),
      );
      // 缓存书架内小说的详情+目录，供断网时展示（不阻塞 UI）。
      unawaited(
        OfflineLibrary.instance.cacheShelfDetail(novelId, info, volumes),
      );
    } catch (e, s) {
      Log.error('NovelInfoCubit', 'load failed: $e', s);
      if (hasVolumes || hasLocal) return;
      if (_fallbackInfo != null) {
        _safeEmit(
          NovelInfoLoaded(
            novelInfo: _fallbackInfo!,
            volumes: _fallbackVolumes ?? const [],
          ),
        );
        return;
      }
      _safeEmit(NovelInfoError('加载失败，请下拉刷新重试'));
    }
  }

  Future<void> loadHistory() async {
    final readingHistory = await w8.novelHistoryById(novelId: novelId);
    if (isClosed) return;
    if (state is NovelInfoLoaded) {
      final current = state as NovelInfoLoaded;
      _safeEmit(
        NovelInfoLoaded(
          novelInfo: current.novelInfo,
          volumes: current.volumes,
          readingHistory: readingHistory,
        ),
      );
    }
  }
}
