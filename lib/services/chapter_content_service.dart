import 'package:wild/services/download_manager.dart';
import 'package:wild/services/wenku8_repo.dart';
import 'package:wild/utils/log.dart';

/// 统一的章节内容获取入口。
///
/// 获取顺序：
/// 1. 本地内存/磁盘缓存（已下载章节，离线可用，秒开）；
/// 2. 联网抓取（统一走 [Wenku8Repo] 的常驻 WebView 会话，内置缓存/冷却/重试）。
///
/// 返回正文（含 `<!--image-->url<!--image-->` 图片占位）。
class ChapterContentService {
  ChapterContentService._();

  static final ChapterContentService instance = ChapterContentService._();

  /// 正文内存缓存：再次打开同一章时秒开，避免重复网络/读盘。
  final Map<String, String> _mem = {};

  Future<String> load({
    required String novelId,
    required String aid,
    required String cid,
  }) async {
    final key = '$novelId/$cid';
    final cached = _mem[key];
    if (cached != null && cached.isNotEmpty) return cached;

    // 1) 本地已下载缓存
    try {
      final local = await NovelDownloadManager.instance.readLocalChapter(
        novelId,
        cid,
      );
      if (local != null && local.isNotEmpty) {
        Log.info('ChapterContent', 'local cache hit $cid');
        _mem[key] = local;
        return local;
      }
    } catch (e) {
      Log.warning('ChapterContent', 'local read failed: $e');
    }

    // 2) 联网抓取（唯一常驻 WebView 会话）
    try {
      final text = await Wenku8Repo.instance.chapterContent(aid, cid);
      if (text != null && text.isNotEmpty) {
        Log.info('ChapterContent', 'webview ok $cid (${text.length} chars)');
        _mem[key] = text;
        return text;
      }
    } catch (e) {
      Log.warning('ChapterContent', 'fetch failed: $e');
    }

    return '';
  }
}
