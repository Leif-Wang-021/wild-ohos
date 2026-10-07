import 'dart:async';

import 'package:wild/services/local_cache.dart';
import 'package:wild/services/webview_fetcher.dart';
import 'package:wild/src/rust/api/wenku8.dart' show PageStatsNovelCover;
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/utils/wenku8_parse.dart';
import 'package:wild/widgets/wenku8_js.dart';

/// wenku8 站点数据的**统一网络入口**（架构级永久方案）。
///
/// 背景：鸿蒙端 Rust 的 reqwest 没有 JS 引擎，**永远无法通过 Cloudflare 挑战**。
/// 此前各页面「先试 Rust、失败再兜底 WebView」的写法会导致：
///   1. 每次请求都白白撞一次 CF，浪费请求并加重站点 429 限流；
///   2. 每个页面各自创建隐藏 WebView，多个会话并发触发挑战，整体不稳定；
///   3. 失败处理散落各页，改一处漏一处。
///
/// 本类统一为：**所有站点请求只走唯一常驻 WebView 会话**，并内置
///   1. 磁盘缓存（先返回缓存，后台刷新）；
///   2. 请求去重（同一 key 的并发请求合并为一次）；
///   3. 全局冷却（命中 429 时所有请求统一暂停）；
///   4. 自动重试（指数退避）。
///
/// 页面不再直接调用 Rust 网络方法，也不再自建 WebView。
class Wenku8Repo {
  Wenku8Repo._();

  static final Wenku8Repo instance = Wenku8Repo._();

  /// 命中 429 时的全局冷却截止时间。
  DateTime? _cooldownUntil;

  /// 进行中的请求：`key -> Future`，用于合并重复请求。
  final Map<String, Future<FetchResult>> _inflight = {};

  Future<void> _waitCooldown() async {
    final until = _cooldownUntil;
    if (until == null) return;
    final remain = until.difference(DateTime.now());
    if (remain.isNegative) {
      _cooldownUntil = null;
      return;
    }
    Log.info('Wenku8Repo', 'cooldown ${remain.inSeconds}s');
    await Future.delayed(remain);
    _cooldownUntil = null;
  }

  void _triggerCooldown([int attempt = 1]) {
    final secs = (10 * attempt).clamp(10, 60);
    _cooldownUntil = DateTime.now().add(Duration(seconds: secs));
  }

  /// 统一抓取（fetch 模式）并解析。
  ///
  /// [cacheKey] 非空时启用磁盘缓存；[allowStale] 为 true 时先返回旧缓存。
  Future<String?> _fetch(
    String path,
    String parserJs, {
    String? cacheKey,
    int maxAttempts = 4,
  }) async {
    // 1) 磁盘缓存命中直接返回。
    if (cacheKey != null) {
      final cached = await LocalCache.instance.read(cacheKey);
      if (cached is String && cached.isNotEmpty) {
        Log.info('Wenku8Repo', 'cache hit $cacheKey');
        return cached;
      }
    }

    // 2) 合并并发重复请求。
    final dedupKey = '$path\u0000$parserJs';
    final existing = _inflight[dedupKey];
    if (existing != null) {
      Log.info('Wenku8Repo', 'dedup join $path');
      final res = await existing;
      return res.ok ? res.text : null;
    }

    final future = _fetchWithRetry(path, parserJs, maxAttempts: maxAttempts);
    _inflight[dedupKey] = future;
    try {
      final res = await future;
      if (res.ok && res.text != null && cacheKey != null) {
        await LocalCache.instance.write(cacheKey, res.text);
      }
      return res.ok ? res.text : null;
    } finally {
      _inflight.remove(dedupKey);
    }
  }

  Future<FetchResult> _fetchWithRetry(
    String path,
    String parserJs, {
    required int maxAttempts,
  }) async {
    FetchResult last = const FetchResult(null, 'none');
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      await _waitCooldown();
      last = await WebViewFetcher.instance.fetchParsedEx(path, parserJs);
      if (last.ok && last.text != null && last.text!.isNotEmpty) return last;

      if (last.isRateLimited) {
        _triggerCooldown(attempt);
        Log.warning('Wenku8Repo', '429 on $path, cooldown (attempt $attempt)');
        await _waitCooldown();
        continue;
      }
      // 非限流错误：短暂退避后重试。
      Log.warning('Wenku8Repo', '$path failed (${last.state}), attempt $attempt');
      await Future.delayed(Duration(seconds: attempt));
    }
    return last;
  }

  /// 导航模式抓取（用于含中文、需按 GBK 编码的 URL，如标签页）。
  Future<String?> _fetchByNavigate(
    String path,
    String parserJs,
    String? navigateJs, {
    String? cacheKey,
    int maxAttempts = 3,
  }) async {
    if (cacheKey != null) {
      final cached = await LocalCache.instance.read(cacheKey);
      if (cached is String && cached.isNotEmpty) return cached;
    }
    FetchResult last = const FetchResult(null, 'none');
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      await _waitCooldown();
      last = await WebViewFetcher.instance.navigateParsedEx(
        path,
        parserJs,
        navigateJs: navigateJs,
      );
      if (last.ok && last.text != null && last.text!.isNotEmpty) {
        if (cacheKey != null) await LocalCache.instance.write(cacheKey, last.text);
        return last.text;
      }
      await Future.delayed(Duration(seconds: attempt));
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 公开 API（返回与 Rust 模型一致的类型，页面无需感知抓取细节）
  // ---------------------------------------------------------------------------

  /// 首页（推荐）。
  Future<List<HomeBlock>> index() async {
    final text = await _fetch(
      '/index.php?charset=gbk',
      Wenku8Js.indexBlocks,
      cacheKey: 'repo_index',
    );
    if (text == null) return const [];
    try {
      return Wenku8Parse.homeBlocks(text);
    } catch (e) {
      Log.warning('Wenku8Repo', 'parse index failed: $e');
      return const [];
    }
  }

  /// 分类标签组。
  Future<TagParseResult> tagGroups() async {
    final text = await _fetch(
      '/modules/article/tags.php?charset=gbk',
      Wenku8Js.tagGroups,
      cacheKey: 'repo_tag_groups',
    );
    if (text == null) return const TagParseResult([], {});
    try {
      return Wenku8Parse.tagGroups(text);
    } catch (e) {
      Log.warning('Wenku8Repo', 'parse tagGroups failed: $e');
      return const TagParseResult([], {});
    }
  }

  /// 标签页列表（tags.php，需按 GBK 编码标签名，用导航模式）。
  Future<PageStatsNovelCover?> tagPage({
    required String tag,
    required String v,
    required int pageNumber,
  }) async {
    final text = await _fetchByNavigate(
      '/modules/article/tags.php',
      Wenku8Js.listPage,
      _buildTagNavigateJs(tag, v, pageNumber),
    );
    if (text == null) return null;
    try {
      return Wenku8Parse.listPage(text);
    } catch (e) {
      Log.warning('Wenku8Repo', 'parse tagPage failed: $e');
      return null;
    }
  }

  /// 排行榜（toplist.php）。
  Future<PageStatsNovelCover?> toplist({
    required String sort,
    required int page,
  }) async {
    final text = await _fetch(
      '/modules/article/toplist.php?sort=$sort&page=$page&charset=gbk',
      Wenku8Js.listPage,
      cacheKey: 'repo_toplist_${sort}_$page',
    );
    if (text == null) return null;
    try {
      return Wenku8Parse.listPage(text);
    } catch (e) {
      Log.warning('Wenku8Repo', 'parse toplist failed: $e');
      return null;
    }
  }

  /// 完结文库（articlelist.php）。
  Future<PageStatsNovelCover?> articlelist({
    required int fullflag,
    required int page,
  }) async {
    final text = await _fetch(
      '/modules/article/articlelist.php?fullflag=$fullflag&page=$page&charset=gbk',
      Wenku8Js.listPage,
      cacheKey: 'repo_articlelist_${fullflag}_$page',
    );
    if (text == null) return null;
    try {
      return Wenku8Parse.listPage(text);
    } catch (e) {
      Log.warning('Wenku8Repo', 'parse articlelist failed: $e');
      return null;
    }
  }

  /// 小说详情。
  Future<NovelInfo?> novelInfo(String aid) async {
    final text = await _fetch(
      '/modules/article/articleinfo.php?id=$aid&charset=gbk',
      Wenku8Js.novelInfo,
      cacheKey: 'repo_info_$aid',
    );
    if (text == null) return null;
    try {
      final info = Wenku8Parse.novelInfo(text);
      return info.title.isEmpty ? null : info;
    } catch (e) {
      Log.warning('Wenku8Repo', 'parse novelInfo failed: $e');
      return null;
    }
  }

  /// 小说目录。
  Future<List<Volume>> novelReader(String aid) async {
    final text = await _fetch(
      '/modules/article/reader.php?aid=$aid&charset=gbk',
      Wenku8Js.readerVolumes,
      cacheKey: 'repo_volumes_$aid',
    );
    if (text == null) return const [];
    try {
      return Wenku8Parse.volumeList(text);
    } catch (e) {
      Log.warning('Wenku8Repo', 'parse volumes failed: $e');
      return const [];
    }
  }

  /// 章节正文。
  Future<String?> chapterContent(String aid, String cid) async {
    final subDir = (int.tryParse(aid) ?? 0) ~/ 1000;
    return _fetch('/novel/$subDir/$aid/$cid.htm', Wenku8Js.chapterText);
  }

  /// 账户详情（原始 JSON，交由页面解析）。
  Future<String?> userDetail() => _fetch(
    '/userdetail.php?charset=gbk',
    Wenku8Js.userDetail,
    cacheKey: 'repo_user_detail',
  );

  /// 清除全部网络缓存（登录态变化或用户手动刷新时调用）。
  Future<void> clearCache() async {
    await LocalCache.instance.removeByPrefix('repo_');
  }

  /// 构造标签页导航脚本：用 form GET 提交，`accept-charset=gbk` 让浏览器按
  /// GBK 编码标签名（Dart/JS 无 GBK 编码器，只能借浏览器能力）。
  String _buildTagNavigateJs(String tag, String v, int pageNumber) {
    return '''
(function() {
  var f = document.createElement('form');
  f.method = 'GET';
  f.action = '/modules/article/tags.php';
  f.acceptCharset = 'gbk';
  function add(name, value) {
    var i = document.createElement('input');
    i.type = 'hidden'; i.name = name; i.value = value;
    f.appendChild(i);
  }
  add('t', ${_jsStr(tag)});
  add('v', ${_jsStr(v)});
  add('page', ${_jsStr(pageNumber.toString())});
  add('charset', 'gbk');
  document.body.appendChild(f);
  f.submit();
})()
''';
  }

  static String _jsStr(String s) {
    final escaped = s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '');
    return "'$escaped'";
  }
}
