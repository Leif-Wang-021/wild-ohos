import 'package:wild/src/rust/api/wenku8.dart' as w8;
import 'package:wild/src/rust/wenku8/models.dart';

/// 书架相关模型的 JSON 编解码（用于本地缓存离线展示）。
class ShelfCodec {
  ShelfCodec._();

  static Map<String, dynamic> bookcaseToJson(Bookcase b) => {
    'id': b.id,
    'title': b.title,
  };

  static Bookcase bookcaseFromJson(Object? v) {
    final m = _map(v);
    return Bookcase(id: _str(m['id']), title: _str(m['title']));
  }

  static Map<String, dynamic> itemToJson(BookcaseItem i) => {
    'aid': i.aid,
    'bid': i.bid,
    'title': i.title,
    'author': i.author,
    'cid': i.cid,
    'chapterName': i.chapterName,
  };

  static BookcaseItem itemFromJson(Object? v) {
    final m = _map(v);
    return BookcaseItem(
      aid: _str(m['aid']),
      bid: _str(m['bid']),
      title: _str(m['title']),
      author: _str(m['author']),
      cid: _str(m['cid']),
      chapterName: _str(m['chapterName']),
    );
  }

  static Map<String, dynamic> historyToJson(w8.ReadingHistory h) => {
    'novelId': h.novelId,
    'novelName': h.novelName,
    'volumeId': h.volumeId,
    'volumeName': h.volumeName,
    'chapterId': h.chapterId,
    'chapterTitle': h.chapterTitle,
    'lastReadAt': h.lastReadAt,
    'progress': h.progress,
    'progressPage': h.progressPage,
    'cover': h.cover,
    'author': h.author,
  };

  static w8.ReadingHistory historyFromJson(Object? v) {
    final m = _map(v);
    return w8.ReadingHistory(
      novelId: _str(m['novelId']),
      novelName: _str(m['novelName']),
      volumeId: _str(m['volumeId']),
      volumeName: _str(m['volumeName']),
      chapterId: _str(m['chapterId']),
      chapterTitle: _str(m['chapterTitle']),
      lastReadAt: _int(m['lastReadAt']),
      progress: _int(m['progress']),
      progressPage: _int(m['progressPage']),
      cover: _str(m['cover']),
      author: _str(m['author']),
    );
  }

  static Map<String, dynamic> _map(Object? v) {
    if (v is Map) {
      return v.map((k, value) => MapEntry(k.toString(), value));
    }
    return {};
  }

  static String _str(Object? v) => v == null ? '' : v.toString();

  static int _int(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
