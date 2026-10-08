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

  /// 缓存结构版本号。修改缓存内容格式（如详情解析逻辑变化）时递增，
  /// 启动时检测到旧版本即清空相关缓存，避免使用历史错误数据。
  static const int schemaVersion = 2;

  String? _root;
  bool _schemaChecked = false;

  /// 内存缓存：避免每次读取都重新读盘 + jsonDecode 大文件（详情页高频调用）。
  final Map<String, Object?> _mem = {};

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

  File get _schemaFile =>
      File('${_rootPath()}${Platform.pathSeparator}_schema.json');

  /// 校验缓存结构版本；不一致则清空所有缓存文件（一次性）。
  Future<void> ensureSchema() async {
    if (_schemaChecked) return;
    _schemaChecked = true;
    try {
      final f = _schemaFile;
      int current = 0;
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is Map) current = (raw['v'] as num?)?.toInt() ?? 0;
      }
      if (current != schemaVersion) {
        Log.info('LocalCache', 'schema $current -> $schemaVersion, clearing');
        final dir = Directory(_rootPath());
        if (await dir.exists()) {
          await for (final e in dir.list()) {
            if (e is File) {
              try {
                await e.delete();
              } catch (_) {}
            }
          }
        }
        await f.writeAsString(jsonEncode({'v': schemaVersion}));
      }
    } catch (e) {
      Log.warning('LocalCache', 'schema check failed: $e');
    }
  }

  /// 写入任意可 JSON 序列化的值。
  Future<void> write(String key, Object? value) async {
    try {
      _mem[key] = value;
      await _file(key).writeAsString(jsonEncode(value));
    } catch (e) {
      Log.warning('LocalCache', 'write $key failed: $e');
    }
  }

  /// 读取并解码；不存在或损坏时返回 null。命中内存缓存则直接返回，避免读盘。
  Future<Object?> read(String key) async {
    await ensureSchema();
    if (_mem.containsKey(key)) return _mem[key];
    try {
      final f = _file(key);
      if (!await f.exists()) return null;
      final decoded = jsonDecode(await f.readAsString());
      _mem[key] = decoded;
      return decoded;
    } catch (e) {
      Log.warning('LocalCache', 'read $key failed: $e');
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      _mem.remove(key);
      final f = _file(key);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// 删除所有文件名以 [prefix] 开头的缓存（用于清理旧版本遗留文件）。
  Future<void> removeByPrefix(String prefix) async {
    try {
      _mem.removeWhere((k, _) => k.startsWith(prefix));
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
