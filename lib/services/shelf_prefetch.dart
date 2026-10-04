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

  /// 后台预取书架内所有书的详情（幂等，重复调用不会并发）。
  void prefetchShelf(List<BookcaseItem> items) {
    if (_running) return;
    _running = true;
    unawaited(_run(items));
  }

  Future<void> _run(List<BookcaseItem> items) async {
    try {
      await WebViewFetcher.instance.ensureReady();
      for (final item in items) {
        final aid = item.aid;
        if (aid.isEmpty) continue;
        // 详情与封面都已缓存才跳过；缺任一则继续补齐。
        final hasDetail = await OfflineLibrary.instance.hasShelfDetail(aid);
        final coverUrl = _coverUrl(aid);
        if (hasDetail && CoverCache.instance.has(coverUrl)) continue;

        await _waitCooldown();
        final ok = await _prefetchOne(aid, coverUrl, skipDetail: hasDetail);
        if (!ok) {
          // 命中限流：冷却后继续下一本。
          _cooldownUntil = DateTime.now().add(const Duration(seconds: 20));
        }
        await Future.delayed(const Duration(milliseconds: 1200));
      }
      Log.info('ShelfPrefetch', 'shelf prefetch done (${items.length} books)');
    } catch (e) {
      Log.warning('ShelfPrefetch', 'prefetch failed: $e');
    } finally {
      _running = false;
    }
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
        final bytes = await WebViewFetcher.instance.fetchBytes(coverUrl);
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
          final bytes = await WebViewFetcher.instance.fetchBytes(info.imgUrl);
          if (bytes != null && bytes.isNotEmpty) {
            await CoverCache.instance.put(info.imgUrl, bytes);
          }
        } catch (_) {}
      }

      // 3) 目录
      final volRes = await WebViewFetcher.instance.fetchParsedEx(
        '/modules/article/reader.php?aid=$aid&charset=gbk',
        Wenku8Js.readerVolumesFromHtml,
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
