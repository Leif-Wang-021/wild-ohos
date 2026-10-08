import 'dart:async';

import 'package:wild/services/cover_cache.dart';
import 'package:wild/services/offline_library.dart';
import 'package:wild/services/webview_fetcher.dart';
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/utils/wenku8_parse.dart';
import 'package:wild/widgets/wenku8_js.dart';

/// 后台预取整个书架的详情 + 目录并缓存，使离线时与在线显示一致。
///
/// 走 [WebViewFetcher]（已过 Cloudflare 的会话），串行执行并做限流退避，
/// 避免 429/403。仅抓取尚未缓存的书。
class ShelfPrefetch {
  ShelfPrefetch._();

  static final ShelfPrefetch instance = ShelfPrefetch._();

  bool _running = false;
  DateTime? _cooldownUntil;

  /// 已预取过的书集合（进程内），避免书架每次重载都重跑一轮。
  final Set<String> _done = {};

  /// 待预取的队列（合并多次调用，避免重复整轮预取）。
  List<BookcaseItem>? _pending;

  /// 后台预取书架内所有书的详情（幂等，重复调用不会并发）。
  ///
  /// 若已有预取在跑，则把新书架并入待处理队列，**不新开一轮**，
  /// 避免书架重载导致整架重复预取、长期霸占网络队列。
  void prefetchShelf(List<BookcaseItem> items) {
    if (_running) {
      _pending = items;
      return;
    }
    _running = true;
    unawaited(_run(items));
  }

  Future<void> _run(List<BookcaseItem> items) async {
    try {
      var current = items;
      while (current.isNotEmpty) {
        await _runOnce(current);
        current = _pending ?? const [];
        _pending = null;
      }
      Log.info('ShelfPrefetch', 'prefetch idle');
    } catch (e) {
      Log.warning('ShelfPrefetch', 'prefetch failed: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _runOnce(List<BookcaseItem> items) async {
    await WebViewFetcher.instance.ensureReady();
    var fetched = 0;
    for (final item in items) {
      final aid = item.aid;
      if (aid.isEmpty) continue;
      // 进程内已预取过则跳过（避免书架重载重复抓取）。
      if (_done.contains(aid)) continue;
      // 详情与封面都已缓存才跳过；缺任一则继续补齐。
      final hasDetail = await OfflineLibrary.instance.hasShelfDetail(aid);
      final coverUrl = _coverUrl(aid);
      if (hasDetail && CoverCache.instance.has(coverUrl)) {
        _done.add(aid);
        continue;
      }

      await _waitCooldown();
      final ok = await _prefetchOne(aid, coverUrl, skipDetail: hasDetail);
      if (ok) {
        _done.add(aid);
      } else {
        // 命中限流：冷却后继续下一本。
        _cooldownUntil = DateTime.now().add(const Duration(seconds: 20));
      }
      // 每本之间让出网络队列且更温和，减少对前台操作的干扰。
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    Log.info('ShelfPrefetch', 'shelf prefetch pass done (fetched=$fetched)');
  }

  Future<void> _waitCooldown() async {
    final until = _cooldownUntil;
    if (until == null) return;
    final remain = until.difference(DateTime.now());
    if (remain.isNegative) {
      _cooldownUntil = null;
      return;
    }
    await Future.delayed(remain);
    _cooldownUntil = null;
  }

  /// 由 aid 推导封面 URL（与书架/详情一致）。
  String _coverUrl(String aid) {
    final n = int.tryParse(aid) ?? 0;
    return 'https://img.wenku8.com/image/${n ~/ 1000}/$aid/${aid}s.jpg';
  }

  /// 抓取并缓存一本书的详情 + 目录 + 封面。返回 false 表示遇到限流。
  ///
  /// [skipDetail] 为 true 时表示详情已缓存，仅补封面。
  Future<bool> _prefetchOne(
    String aid,
    String coverUrl, {
    bool skipDetail = false,
  }) async {
    try {
      final subDir = (int.tryParse(aid) ?? 0) ~/ 1000;

      // 1) 封面（离线显示用）
      if (!CoverCache.instance.has(coverUrl)) {
        final bytes = await WebViewFetcher.instance.fetchBytes(coverUrl, background: true);
        if (bytes != null && bytes.isNotEmpty) {
          await CoverCache.instance.put(coverUrl, bytes);
        }
        if (skipDetail) return true; // 详情已缓存，仅补封面即完成。
      } else if (skipDetail) {
        return true;
      }

      // 2) 详情
      final infoRes = await WebViewFetcher.instance.fetchParsedEx(
        '/modules/article/articleinfo.php?id=$aid&charset=gbk',
        Wenku8Js.novelInfoFromHtml,
        background: true,
      );
      if (infoRes.isRateLimited) return false;
      if (!infoRes.ok || infoRes.text == null) {
        Log.warning('ShelfPrefetch', 'info failed $aid: ${infoRes.state}');
        return true;
      }
      final info = Wenku8Parse.novelInfo(infoRes.text!);
      if (info.title.isEmpty) return true;

      // 若详情抓取中拿到更准确的封面 URL，补抓一次。
      if (info.imgUrl.isNotEmpty && !CoverCache.instance.has(info.imgUrl)) {
        try {
          final bytes = await WebViewFetcher.instance.fetchBytes(info.imgUrl, background: true);
          if (bytes != null && bytes.isNotEmpty) {
            await CoverCache.instance.put(info.imgUrl, bytes);
          }
        } catch (_) {}
      }

      // 3) 目录
      final volRes = await WebViewFetcher.instance.fetchParsedEx(
        '/modules/article/reader.php?aid=$aid&charset=gbk',
        Wenku8Js.readerVolumesFromHtml,
        background: true,
      );
      if (volRes.isRateLimited) return false;
      if (!volRes.ok || volRes.text == null) {
        Log.warning('ShelfPrefetch', 'volumes failed $aid: ${volRes.state}');
        return true;
      }
      final volumes = Wenku8Parse.volumeList(volRes.text!);

      if (volumes.isEmpty) return true;
      await OfflineLibrary.instance.cacheShelfDetail(
        aid,
        info,
        volumes,
        inBookshelf: true,
      );
      Log.info(
        'ShelfPrefetch',
        'cached $aid (${info.title}) ${volumes.length} volumes [subDir=$subDir]',
      );
      return true;
    } catch (e) {
      Log.warning('ShelfPrefetch', 'prefetch one $aid failed: $e');
      return true;
    }
  }
}
