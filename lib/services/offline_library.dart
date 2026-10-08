import 'dart:io';

import 'package:wild/services/download_manager.dart';
import 'package:wild/services/local_cache.dart';
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/utils/novel_codec.dart';

/// 本地离线书库数据（从下载目录的 manifest.json 重建）。
class OfflineNovel {
  final String novelId;
  final String novelName;
  final String coverUrl;
  final NovelInfo info;
  final List<Volume> volumes;

  /// 目录是否为**真实数据**。
  ///
  /// 由文件扫描降级生成的「第 N 章」是合成目录（仅有已下载章节、标题为序号），
  /// 为 false。调用方据此决定是否需要联网补齐真实目录。
  final bool realVolumes;

  OfflineNovel({
    required this.novelId,
    required this.novelName,
    required this.coverUrl,
    required this.info,
    required this.volumes,
    this.realVolumes = true,
  });
}

/// 读取沙箱内已下载小说的完整信息与目录，供**离线**阅读使用。
class OfflineLibrary {
  OfflineLibrary._();

  static final OfflineLibrary instance = OfflineLibrary._();

  /// 书架内小说的详情缓存（info + 目录），整体存于单个文件并覆盖写入。
  static const String _shelfDetailsKey = 'shelf_details';
  static const String _bookshelfKey = 'bookshelf';

  /// 是否已有该书的书架详情缓存（真实 info+目录）。
  Future<bool> hasShelfDetail(String novelId) async {
    try {
      final raw = await LocalCache.instance.read(_shelfDetailsKey);
      if (raw is! Map) return false;
      return raw[novelId] is Map;
    } catch (_) {
      return false;
    }
  }

  /// 该小说是否在书架内（读取书架缓存判断）。
  Future<bool> isInBookshelf(String novelId) async {
    try {
      final raw = await LocalCache.instance.read(_bookshelfKey);
      if (raw is! Map) return false;
      final contents = raw['contents'];
      if (contents is! Map) return false;
      for (final list in contents.values) {
        if (list is List) {
          for (final e in list) {
            if (e is Map && e['aid']?.toString() == novelId) return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// 缓存某本书的详情+目录（仅书架内的书）。
  ///
  /// [inBookshelf] 由调用方按实时书架状态传入；为 null 时回退读缓存判断。
  /// 整体覆盖单个文件，不产生堆积。
  Future<void> cacheShelfDetail(
    String novelId,
    NovelInfo info,
    List<Volume> volumes, {
    bool? inBookshelf,
  }) async {
    if (volumes.isEmpty) return;
    // 实时状态为 true 直接放行；否则回退读缓存判断（书架可能后加载）。
    final allowed = inBookshelf == true || await isInBookshelf(novelId);
    if (!allowed) return;
    try {
      final raw = await LocalCache.instance.read(_shelfDetailsKey);
      final map = <String, dynamic>{
        if (raw is Map)
          for (final e in raw.entries) e.key.toString(): e.value,
      };
      map[novelId] = {
        'novelName': info.title,
        'coverUrl': info.imgUrl,
        'info': NovelCodec.infoToJson(info),
        'volumes': NovelCodec.volumesToJson(volumes),
      };
      await LocalCache.instance.write(_shelfDetailsKey, map);
      _mem.remove(novelId); // 失效内存缓存，下次读取拿到最新数据。
      Log.info('OfflineLibrary', 'cached shelf detail $novelId');
    } catch (e) {
      Log.warning('OfflineLibrary', 'cache shelf detail failed: $e');
    }
  }

  /// 读取书架内某本书的详情缓存。
  Future<OfflineNovel?> _loadShelfDetail(String novelId) async {
    try {
      final raw = await LocalCache.instance.read(_shelfDetailsKey);
      if (raw is! Map) return null;
      final entry = raw[novelId];
      if (entry is! Map) return null;
      final m = entry.map((k, v) => MapEntry(k.toString(), v));
      final volumes = NovelCodec.volumesFromJson(m['volumes']);
      if (volumes.isEmpty) return null;
      final info = NovelCodec.infoFromJson(m['info']);
      Log.info('OfflineLibrary', 'loaded shelf detail $novelId');
      return OfflineNovel(
        novelId: novelId,
        novelName: info.title.isNotEmpty ? info.title : _str(m['novelName']),
        coverUrl: _str(m['coverUrl']),
        info: info,
        volumes: volumes,
      );
    } catch (e) {
      Log.warning('OfflineLibrary', 'load shelf detail failed: $e');
      return null;
    }
  }

  /// 从书架缓存构建"仅元数据"的离线详情（书名/作者/封面，无目录）。
  ///
  /// 用于未下载、也未缓存详情、但位于书架内的小说，保证离线时详情页
  /// 至少能显示基本信息而不是"加载失败"。
  Future<OfflineNovel?> _loadShelfMeta(String novelId) async {
    try {
      final raw = await LocalCache.instance.read(_bookshelfKey);
      if (raw is! Map) return null;
      final contents = raw['contents'];
      if (contents is! Map) return null;
      for (final list in contents.values) {
        if (list is! List) continue;
        for (final e in list) {
          if (e is! Map) continue;
          if (e['aid']?.toString() != novelId) continue;
          final title = _str(e['title']);
          final author = _str(e['author']);
          final cover =
              'https://img.wenku8.com/image/${_sub(novelId)}/$novelId/${novelId}s.jpg';
          Log.info('OfflineLibrary', 'loaded shelf meta $novelId: $title');
          return OfflineNovel(
            novelId: novelId,
            novelName: title,
            coverUrl: cover,
            info: NovelInfo(
              title: title,
              author: author,
              status: '',
              finUpdate: '',
              imgUrl: cover,
              introduce: '',
              tags: const [],
              heat: '',
              trending: '',
              isAnimated: false,
            ),
            volumes: const [],
          );
        }
      }
    } catch (e) {
      Log.warning('OfflineLibrary', 'load shelf meta failed: $e');
    }
    return null;
  }

  static String _sub(String aid) {
    final n = int.tryParse(aid) ?? 0;
    return '${n ~/ 1000}';
  }

  /// 内存缓存：避免同一本书被反复读盘/扫描（打开详情页时高频调用）。
  final Map<String, OfflineNovel?> _mem = {};

  /// 读取指定小说的离线数据。自动选择，不做特殊区分：
  /// 本地有的优先用本地，本地没有则由调用方联网。
  ///
  /// 优先级（均为本地真实数据，越靠前越完整）：
  /// 1. 下载 manifest.json（含真实目录与标题）；
  /// 2. 书架详情缓存（书架内的书预取过，含真实目录）；
  /// 3. 旧下载无 manifest 时扫描已下载章节文件（伪目录，仅保证可读）；
  /// 4. 书架元数据兜底（书名/作者，无目录）。
  Future<OfflineNovel?> load(String novelId) async {
    if (_mem.containsKey(novelId)) return _mem[novelId];
    final result = await _loadUncached(novelId);
    // 只缓存命中的结果（null 不缓存，以便下载/缓存后可重新解析）。
    if (result != null) _mem[novelId] = result;
    return result;
  }

  Future<OfflineNovel?> _loadUncached(String novelId) async {
    final manifest = await NovelDownloadManager.instance.readManifest(novelId);
    if (manifest == null) {
      return (await _loadShelfDetail(novelId)) ??
          (await _loadFromFiles(novelId)) ??
          (await _loadShelfMeta(novelId));
    }
    try {
      final infoRaw = _asMap(manifest['info']);
      final info =
          infoRaw == null
              ? NovelInfo(
                title: _str(manifest['novelName']),
                author: '',
                status: '',
                finUpdate: '',
                imgUrl: _str(manifest['coverUrl']),
                introduce: '',
                tags: const [],
                heat: '',
                trending: '',
                isAnimated: false,
              )
              : NovelInfo(
                title: _str(infoRaw['title']),
                author: _str(infoRaw['author']),
                status: _str(infoRaw['status']),
                finUpdate: _str(infoRaw['finUpdate']),
                imgUrl: _str(infoRaw['imgUrl']),
                introduce: _str(infoRaw['introduce']),
                tags: _strList(infoRaw['tags']),
                heat: _str(infoRaw['heat']),
                trending: _str(infoRaw['trending']),
                isAnimated: infoRaw['isAnimated'] == true,
              );

      final volumes = <Volume>[];
      final rawVolumes = manifest['volumes'];
      if (rawVolumes is List) {
        for (final v in rawVolumes) {
          final vm = _asMap(v);
          if (vm == null) continue;
          final chapters = <Chapter>[];
          final rawChapters = vm['chapters'];
          if (rawChapters is List) {
            for (final c in rawChapters) {
              final cm = _asMap(c);
              if (cm == null) continue;
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
          if (chapters.isEmpty) continue;
          volumes.add(
            Volume(
              id: _str(vm['id']),
              title: _str(vm['title']),
              chapters: chapters,
            ),
          );
        }
      }

      if (volumes.isEmpty) return await _loadShelfDetail(novelId);
      Log.info(
        'OfflineLibrary',
        'loaded $novelId: ${volumes.length} volumes',
      );
      return OfflineNovel(
        novelId: novelId,
        novelName: info.title.isNotEmpty
            ? info.title
            : _str(manifest['novelName']),
        coverUrl: _str(manifest['coverUrl']),
        info: info,
        volumes: volumes,
      );
    } catch (e) {
      Log.warning('OfflineLibrary', 'parse manifest failed: $e');
      return null;
    }
  }

  /// 该小说是否可离线阅读（存在 manifest）。
  Future<bool> isAvailable(String novelId) async {
    return (await load(novelId)) != null;
  }

  /// 旧版本下载的降级读取：扫描 `chapter_<cid>.txt` 重建单卷目录。
  ///
  /// 使用**异步**文件 API，避免同步目录遍历阻塞 UI 线程（章节多时尤其明显）。
  Future<OfflineNovel?> _loadFromFiles(String novelId) async {
    try {
      final root = await NovelDownloadManager.instance.downloadRoot();
      final dir = Directory('$root${Platform.pathSeparator}$novelId');
      if (!await dir.exists()) return null;

      final meta = await NovelDownloadManager.instance.readMeta(novelId);
      final name = (meta?['novelName'] as String?)?.trim();
      final cover = (meta?['coverUrl'] as String?) ?? '';

      final cids = <String>[];
      await for (final f in dir.list()) {
        if (f is File && f.path.endsWith('.txt')) {
          final base = f.path.split(Platform.pathSeparator).last;
          final cid = base.replaceFirst('chapter_', '').replaceAll('.txt', '');
          if (cid.isNotEmpty) cids.add(cid);
        }
      }
      if (cids.isEmpty) return null;
      cids.sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

      final chapters = <Chapter>[];
      for (var i = 0; i < cids.length; i++) {
        chapters.add(
          Chapter(
            title: '第 ${i + 1} 章',
            url: '',
            cid: cids[i],
            aid: novelId,
          ),
        );
      }

      Log.info(
        'OfflineLibrary',
        'fallback(file scan) $novelId: ${chapters.length} chapters',
      );
      return OfflineNovel(
        novelId: novelId,
        novelName: (name != null && name.isNotEmpty) ? name : novelId,
        coverUrl: cover,
        info: NovelInfo(
          title: (name != null && name.isNotEmpty) ? name : novelId,
          author: '',
          status: '',
          finUpdate: '',
          imgUrl: cover,
          introduce: '',
          tags: const [],
          heat: '',
          trending: '',
          isAnimated: false,
        ),
        volumes: [
          Volume(id: novelId, title: '已下载章节', chapters: chapters),
        ],
        realVolumes: false,
      );
    } catch (e) {
      Log.warning('OfflineLibrary', 'file scan failed: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _asMap(Object? v) {
    if (v is Map) {
      return v.map((k, value) => MapEntry(k.toString(), value));
    }
    return null;
  }

  static String _str(Object? v) => v == null ? '' : v.toString();

  static List<String> _strList(Object? v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
