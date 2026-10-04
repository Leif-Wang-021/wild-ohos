import 'package:wild/src/rust/wenku8/models.dart';

/// 小说详情 + 目录的 JSON 编解码（用于缓存任意在线查看过的小说）。
class NovelCodec {
  NovelCodec._();

  static Map<String, dynamic> infoToJson(NovelInfo i) => {
    'title': i.title,
    'author': i.author,
    'status': i.status,
    'finUpdate': i.finUpdate,
    'imgUrl': i.imgUrl,
    'introduce': i.introduce,
    'tags': i.tags,
    'heat': i.heat,
    'trending': i.trending,
    'isAnimated': i.isAnimated,
  };

  static NovelInfo infoFromJson(Object? v) {
    final m = _map(v);
    return NovelInfo(
      title: _str(m['title']),
      author: _str(m['author']),
      status: _str(m['status']),
      finUpdate: _str(m['finUpdate']),
      imgUrl: _str(m['imgUrl']),
      introduce: _str(m['introduce']),
      tags: _strList(m['tags']),
      heat: _str(m['heat']),
      trending: _str(m['trending']),
      isAnimated: m['isAnimated'] == true,
    );
  }

  static Map<String, dynamic> volumeToJson(Volume v) => {
    'id': v.id,
    'title': v.title,
    'chapters':
        v.chapters
            .map(
              (c) => {'title': c.title, 'url': c.url, 'cid': c.cid, 'aid': c.aid},
            )
            .toList(),
  };

  static Volume? volumeFromJson(Object? v) {
    final m = _map(v);
    final chapters = <Chapter>[];
    final raw = m['chapters'];
    if (raw is List) {
      for (final c in raw) {
        final cm = _map(c);
        chapters.add(
          Chapter(
            title: _str(cm['title']),
            url: _str(cm['url']),
            cid: _str(cm['cid']),
            aid: _str(cm['aid']),
          ),
        );
      }
    }
    if (chapters.isEmpty) return null;
    return Volume(id: _str(m['id']), title: _str(m['title']), chapters: chapters);
  }

  static List<Map<String, dynamic>> volumesToJson(List<Volume> vs) =>
      vs.map(volumeToJson).toList();

  static List<Volume> volumesFromJson(Object? v) {
    final out = <Volume>[];
    if (v is List) {
      for (final e in v) {
        final vol = volumeFromJson(e);
        if (vol != null) out.add(vol);
      }
    }
    return out;
  }

  static Map<String, dynamic> _map(Object? v) {
    if (v is Map) {
      return v.map((k, value) => MapEntry(k.toString(), value));
    }
    return {};
  }

  static String _str(Object? v) => v == null ? '' : v.toString();

  static List<String> _strList(Object? v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}
