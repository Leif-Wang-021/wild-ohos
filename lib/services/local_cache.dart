import 'dart:convert';
import 'dart:io';

import 'package:wild/utils/log.dart';

/// 简单的沙箱文件 KV 缓存（JSON）。
///
/// 用于「本地优先 + 后台刷新」：页面先读缓存立即展示，联网成功后覆盖写回。
/// 缓存文件位于 `files/cache/<key>.json`，与 Rust 端沙箱一致。
class LocalCache {
  LocalCache._();

  static final LocalCache instance = LocalCache._();

  String? _root;

  String get _base => '/data/storage/el2/base/haps/entry/files';

  String _rootPath() {
    if (_root != null) return _root!;
    final dir = Directory('$_base${Platform.pathSeparator}cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _root = dir.path;
    return _root!;
  }

  File _file(String key) {
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return File('${_rootPath()}${Platform.pathSeparator}$safe.json');
  }

  /// 写入任意可 JSON 序列化的值。
  Future<void> write(String key, Object? value) async {
    try {
      await _file(key).writeAsString(jsonEncode(value));
    } catch (e) {
      Log.warning('LocalCache', 'write $key failed: $e');
    }
  }

  /// 读取并解码；不存在或损坏时返回 null。
  Future<Object?> read(String key) async {
    try {
      final f = _file(key);
      if (!f.existsSync()) return null;
      return jsonDecode(await f.readAsString());
    } catch (e) {
      Log.warning('LocalCache', 'read $key failed: $e');
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      final f = _file(key);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }

  /// 删除所有文件名以 [prefix] 开头的缓存（用于清理旧版本遗留文件）。
  Future<void> removeByPrefix(String prefix) async {
    try {
      final dir = Directory(_rootPath());
      if (!dir.existsSync()) return;
      for (final f in dir.listSync()) {
        if (f is File) {
          final name = f.path.split(Platform.pathSeparator).last;
          if (name.startsWith(prefix)) await f.delete();
        }
      }
    } catch (e) {
      Log.warning('LocalCache', 'removeByPrefix $prefix failed: $e');
    }
  }
}
