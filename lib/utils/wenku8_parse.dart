import 'dart:convert';

import 'package:wild/src/rust/api/wenku8.dart' as w8;
import 'package:wild/src/rust/api/wenku8.dart' show PageStatsNovelCover;
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';

/// 分类解析结果：分组列表 + `tagName -> href`（站点原始 GBK 编码链接）。
class TagParseResult {
  final List<TagGroup> groups;
  final Map<String, String> hrefs;

  const TagParseResult(this.groups, this.hrefs);
}

/// 将 WebView 中解析得到的 JSON 转换为 Rust 模型。
///
/// 与 `rust/src/wenku8/client.rs` 的解析结构保持一致，供各页面在 Cloudflare
/// 兜底路径中复用。
class Wenku8Parse {
  /// 首页：`[{title, list:[{title,img,detailUrl,aid}]}]`。
  static List<HomeBlock> homeBlocks(String json) {
    final data = jsonDecode(json) as List;
    return data
        .map((e) => e as Map)
        .map(
          (b) => HomeBlock(
            title: (b['title'] ?? '') as String,
            list: _covers((b['list'] ?? []) as List),
          ),
        )
        .where((b) => b.list.isNotEmpty)
        .toList();
  }

  /// 列表页：`{currentPage, maxPage, records:[...]}`。
  static PageStatsNovelCover listPage(String json) {
    final data = jsonDecode(json) as Map;
    return PageStatsNovelCover(
      currentPage: _int(data['currentPage'], 1),
      maxPage: _int(data['maxPage'], 1),
      records: _covers((data['records'] ?? []) as List),
    );
  }

  /// 分类页：`[{title, tags:[{name, href}]}]`。
  ///
  /// 同时返回 `tagName -> href` 映射，href 为站点已按 GBK 编码的链接。
  static TagParseResult tagGroups(String json) {
    final data = jsonDecode(json) as List;
    final groups = <TagGroup>[];
    final hrefs = <String, String>{};
    for (final raw in data) {
      final g = raw as Map;
      final names = <String>[];
      for (final t in (g['tags'] ?? []) as List) {
        final m = t as Map;
        final name = (m['name'] ?? '') as String;
        final href = (m['href'] ?? '') as String;
        if (name.isEmpty) continue;
        names.add(name);
        if (href.isNotEmpty) hrefs[name] = href;
      }
      final title = (g['title'] ?? '') as String;
      if (names.isNotEmpty && !_isTagNoise(title)) {
        groups.add(TagGroup(title: title, tags: names));
      }
    }
    return TagParseResult(groups, hrefs);
  }

  /// 过滤站点 tags.php 里的帮助/说明等非分类文本（会被误当成分组标题）。
  static bool _isTagNoise(String title) {
    if (title.isEmpty) return true;
    const noise = ['检索服务', '使用指南', '说明', '帮助', '指南', 'Tags'];
    for (final n in noise) {
      if (title.contains(n)) return true;
    }
    return false;
  }

  /// 小说详情页：转换为 [NovelInfo]。
  static NovelInfo novelInfo(String json) {
    final d = jsonDecode(json) as Map;
    return NovelInfo(
      title: (d['title'] ?? '') as String,
      author: (d['author'] ?? '') as String,
      status: (d['status'] ?? '') as String,
      finUpdate: (d['finUpdate'] ?? '') as String,
      imgUrl: (d['imgUrl'] ?? '') as String,
      introduce: (d['introduce'] ?? '') as String,
      tags:
          ((d['tags'] ?? []) as List)
              .map((t) => t.toString())
              .where((t) => t.isNotEmpty)
              .toList(),
      heat: (d['heat'] ?? '') as String,
      trending: (d['trending'] ?? '') as String,
      isAnimated: (d['isAnimated'] ?? false) as bool,
    );
  }

  /// 章节目录页：转换为 `List<Volume>`。
  static List<Volume> volumeList(String json) {
    final data = jsonDecode(json) as List;
    return data
        .map((e) => e as Map)
        .map(
          (v) => Volume(
            id: (v['id'] ?? '') as String,
            title: (v['title'] ?? '') as String,
            chapters:
                ((v['chapters'] ?? []) as List)
                    .map((e) => e as Map)
                    .map(
                      (c) => Chapter(
                        title: (c['title'] ?? '') as String,
                        url: (c['url'] ?? '') as String,
                        cid: (c['cid'] ?? '') as String,
                        aid: (c['aid'] ?? '') as String,
                      ),
                    )
                    .where((c) => c.cid.isNotEmpty)
                    .toList(),
          ),
        )
        .where((v) => v.chapters.isNotEmpty)
        .toList();
  }

  static List<NovelCover> _covers(List list) {
    return list
        .map((e) => e as Map)
        .map(
          (n) => NovelCover(
            title: (n['title'] ?? '') as String,
            img: (n['img'] ?? '') as String,
            detailUrl: (n['detailUrl'] ?? '') as String,
            aid: (n['aid'] ?? '') as String,
          ),
        )
        .where((n) => n.aid.isNotEmpty)
        .toList();
  }

  static int _int(Object? v, int fallback) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// 通过 Rust 端获取章节正文（兜底路径）。
  static Future<String> chapterViaRust({
    required String aid,
    required String cid,
  }) {
    return w8.chapterContent(aid: aid, cid: cid);
  }

  /// 用户详情：转换为 [UserDetail]。
  static UserDetail userDetail(String json) {
    final d = jsonDecode(json) as Map;
    String s(String k) => (d[k] ?? '') as String;
    return UserDetail(
      username: s('username'),
      userId: s('userId'),
      nickname: s('nickname'),
      level: s('level'),
      title: s('title'),
      sex: s('sex'),
      email: s('email'),
      qq: s('qq'),
      msn: s('msn'),
      web: s('web'),
      registerDate: s('registerDate'),
      contributePoint: s('contributePoint'),
      experienceValue: s('experienceValue'),
      holdingPoints: s('holdingPoints'),
      quantityOfFriends: s('quantityOfFriends'),
      quantityOfMail: s('quantityOfMail'),
      quantityOfCollection: s('quantityOfCollection'),
      quantityOfRecommendDaily: s('quantityOfRecommendDaily'),
      personalizedSignature: s('personalizedSignature'),
      personalizedDescription: s('personalizedDescription'),
    );
  }

  /// 判断错误是否由 Cloudflare 拦截导致。
  static bool isCloudflare(Object? error) {
    final msg = error.toString();
    final cf =
        msg.contains('403') ||
        msg.contains('Forbidden') ||
        msg.contains('Cloudflare') ||
        msg.contains('cf_');
    if (cf) Log.info('Wenku8Parse', 'cloudflare detected: ${msg.split('\n').first}');
    return cf;
  }

  /// 是否需要回退到 WebView 抓取。
  ///
  /// 除 Cloudflare 403 外，Rust 端拿到非预期页面（如 CF 挑战页、站点改版）
  /// 时解析会失败并抛出 `Failed to find ...` 之类的错误，此时同样必须走
  /// WebView 兜底，否则表现为页面大面积「加载失败」。
  static bool needsWebViewFallback(Object? error) {
    if (isCloudflare(error)) return true;
    final msg = error.toString();
    final parseFailed =
        msg.contains('Failed to find') ||
        msg.contains('Failed to get index') ||
        msg.contains('Failed to parse') ||
        msg.contains('error sending request');
    if (parseFailed) {
      Log.info(
        'Wenku8Parse',
        'parse/network fallback: ${msg.split('\n').first}',
      );
    }
    return parseFailed;
  }
}
