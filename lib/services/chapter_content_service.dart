import 'package:wild/services/download_manager.dart';
import 'package:wild/services/webview_fetcher.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/utils/wenku8_parse.dart';
import 'package:wild/widgets/wenku8_js.dart';

/// 统一的章节内容获取入口。
///
/// 获取顺序：
/// 1. 本地已下载缓存（离线可用）；
/// 2. WebView 抓取（绕过 Cloudflare，正文为 GBK 需正确解码）；
/// 3. Rust 端 `chapterContent`（未受 CF 影响时可用，作兜底）。
///
/// 返回正文（含 `<!--image-->url<!--image-->` 图片占位）。
class ChapterContentService {
  ChapterContentService._();

  static final ChapterContentService instance = ChapterContentService._();

  Future<String> load({
    required String novelId,
    required String aid,
    required String cid,
  }) async {
    // 1) 本地缓存
    try {
      final local = await NovelDownloadManager.instance.readLocalChapter(
        novelId,
        cid,
      );
      if (local != null && local.isNotEmpty) {
        Log.info('ChapterContent', 'local cache hit $cid');
        return local;
      }
    } catch (e) {
      Log.warning('ChapterContent', 'local read failed: $e');
    }

    // 2) WebView 抓取
    try {
      final aidNum = int.tryParse(aid) ?? 0;
      final subDir = aidNum ~/ 1000;
      final path = '/novel/$subDir/$aid/$cid.htm';
      final text = await WebViewFetcher.instance.fetchParsed(
        path,
        Wenku8Js.chapterText,
      );
      if (text != null && text.isNotEmpty) {
        Log.info('ChapterContent', 'webview ok $cid (${text.length} chars)');
        return text;
      }
    } catch (e) {
      Log.warning('ChapterContent', 'webview fetch failed: $e');
    }

    // 3) Rust 兜底
    Log.info('ChapterContent', 'fallback to rust $cid');
    return Wenku8Parse.chapterViaRust(aid: aid, cid: cid);
  }
}
