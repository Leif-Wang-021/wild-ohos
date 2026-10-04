import 'dart:io';
import 'dart:typed_data';

import 'package:wild/utils/log.dart';

/// Dart 侧封面（图片）磁盘缓存。
///
/// 离线时 Rust `downloadImage` 无法联网，若图片从未被缓存就会失败。
/// 此服务把封面字节按 URL 哈希存到沙箱 `files/cover_cache/`，
/// 供 [CachedImageProvider] 在联网失败时回退读取。
class CoverCache {
  CoverCache._();

  static final CoverCache instance = CoverCache._();

  String? _root;

  String get _base => '/data/storage/el2/base/haps/entry/files';

  // v2：URL 归一化（忽略 scheme）后的哈希方案，与旧目录隔离。
  String _rootPath() {
    if (_root != null) return _root!;
    final dir = Directory('$_base${Platform.pathSeparator}cover_cache_v2');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _root = dir.path;
    return _root!;
  }

  /// 规范化 URL：忽略 scheme 与大小写，使 http/https 指向同一封面。
  static String _normalize(String url) {
    var s = url.trim().toLowerCase();
    if (s.startsWith('https://')) s = s.substring(8);
    else if (s.startsWith('http://')) s = s.substring(7);
    return s;
  }

  /// 稳定的 FNV-1a 32 位哈希（跨会话保持一致）。
  static String _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in _normalize(s).codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  File fileFor(String url) =>
      File('${_rootPath()}${Platform.pathSeparator}${_hash(url)}.img');

  /// 读取本地封面文件；不存在返回 null。
  File? get(String url) {
    if (url.isEmpty) return null;
    try {
      final f = fileFor(url);
      if (f.existsSync() && f.lengthSync() > 0) return f;
    } catch (_) {}
    return null;
  }

  /// 写入封面字节。
  Future<void> put(String url, Uint8List bytes) async {
    if (url.isEmpty || bytes.isEmpty) return;
    try {
      await fileFor(url).writeAsBytes(bytes, flush: true);
    } catch (e) {
      Log.warning('CoverCache', 'put failed: $e');
    }
  }

  bool has(String url) => get(url) != null;
}
