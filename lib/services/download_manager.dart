import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:wild/services/webview_fetcher.dart';
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/widgets/wenku8_js.dart';

/// 单章下载结果。
enum ChapterDownloadStatus { pending, downloading, success, failed }

/// 一本小说的下载任务（Dart 侧，绕过 Cloudflare）。
///
/// 由于 Rust 端 reqwest 无法通过 Cloudflare 挑战，章节正文与图片改为通过
/// [WebViewFetcher] 在已放行的 WebView 会话中抓取，并保存到应用沙箱目录。
class NovelDownloadManager {
  NovelDownloadManager._();

  static final NovelDownloadManager instance = NovelDownloadManager._();

  /// 章节正文/图片缓存目录（沙箱）。
  String? _root;
  bool _running = false;

  /// 站点限流时的全局冷却截止时间：期间不发起任何新请求。
  DateTime? _cooldownUntil;

  /// 自适应请求间隔：连续遇到 429 时逐步增大（上限 [_maxInterval]）。
  Duration _adaptiveInterval = _minInterval;
  static const Duration _minInterval = Duration(milliseconds: 2000);
  static const Duration _maxInterval = Duration(seconds: 8);

  /// 进行中/排队的任务：novelId -> 任务状态。
  final Map<String, NovelDownloadTask> _tasks = {};

  List<NovelDownloadTask> get tasks => _tasks.values.toList();

  NovelDownloadTask? taskOf(String novelId) => _tasks[novelId];

  /// 公开的下载根目录（供存储管理页使用）。
  Future<String> downloadRoot() => _downloadRoot();

  Future<String> _downloadRoot() async {
    if (_root != null) return _root!;
    final base = await _dataRoot();
    final dir = Directory('$base${Platform.pathSeparator}download');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _root = dir.path;
    return _root!;
  }

  Future<String> _dataRoot() async {
    // 与 Rust 端一致：OHOS 沙箱 files 目录。
    return '/data/storage/el2/base/haps/entry/files';
  }

  File chapterFile(String root, String novelId, String cid) {
    final dir = Directory('$root${Platform.pathSeparator}$novelId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}chapter_$cid.txt');
  }

  File _metaFile(String root, String novelId) {
    final dir = Directory('$root${Platform.pathSeparator}$novelId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}meta.json');
  }

  /// 写入/更新小说元数据（名称、封面、章节数），供存储管理页显示名称。
  Future<void> _writeMeta(NovelDownloadTask task) async {
    try {
      final root = await _downloadRoot();
      final f = _metaFile(root, task.novelId);
      final json = jsonEncode({
        'novelId': task.novelId,
        'novelName': task.novelName,
        'coverUrl': task.coverUrl,
        'total': task.total,
        'downloaded': task.downloadedCount,
      });
      await f.writeAsString(json);
    } catch (e) {
      Log.warning('DownloadManager', 'write meta failed: $e');
    }
  }

  /// 写入小说完整信息 + 目录，供**离线**重建阅读器（断网也能进入阅读）。
  Future<void> _writeManifest(
    NovelDownloadTask task,
    NovelInfo? info,
    List<Volume>? volumes,
  ) async {
    try {
      final root = await _downloadRoot();
      final f = _manifestFile(root, task.novelId);
      final json = jsonEncode({
        'novelId': task.novelId,
        'novelName': task.novelName,
        'coverUrl': task.coverUrl,
        'info':
            info == null
                ? null
                : {
                    'title': info.title,
                    'author': info.author,
                    'status': info.status,
                    'finUpdate': info.finUpdate,
                    'imgUrl': info.imgUrl,
                    'introduce': info.introduce,
                    'tags': info.tags,
                    'heat': info.heat,
                    'trending': info.trending,
                    'isAnimated': info.isAnimated,
                  },
        'volumes':
            volumes
                ?.map(
                  (v) => {
                    'id': v.id,
                    'title': v.title,
                    'chapters':
                        v.chapters
                            .map(
                              (c) => {
                                'title': c.title,
                                'url': c.url,
                                'cid': c.cid,
                                'aid': c.aid,
                              },
                            )
                            .toList(),
                  },
                )
                .toList(),
      });
      await f.writeAsString(json);
    } catch (e) {
      Log.warning('DownloadManager', 'write manifest failed: $e');
    }
  }

  File _manifestFile(String root, String novelId) {
    final dir = Directory('$root${Platform.pathSeparator}$novelId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}${Platform.pathSeparator}manifest.json');
  }

  /// 读取本地 manifest（离线重建阅读器用的完整信息 + 目录）。
  Future<Map<String, dynamic>?> readManifest(String novelId) async {
    try {
      final root = await _downloadRoot();
      final f = _manifestFile(root, novelId);
      if (f.existsSync()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
    } catch (e) {
      Log.warning('DownloadManager', 'read manifest failed: $e');
    }
    return null;
  }

  /// 列出所有已下载小说（用于离线书库入口）。
  Future<List<String>> listDownloadedNovelIds() async {
    final out = <String>[];
    try {
      final root = await _downloadRoot();
      final dir = Directory(root);
      if (dir.existsSync()) {
        for (final entry in dir.listSync()) {
          if (entry is Directory) {
            out.add(entry.path.split(Platform.pathSeparator).last);
          }
        }
      }
    } catch (e) {
      Log.warning('DownloadManager', 'list downloads failed: $e');
    }
    return out;
  }

  /// 读取小说元数据（可能为 null，旧数据无 meta.json）。
  Future<Map<String, dynamic>?> readMeta(String novelId) async {
    try {
      final root = await _downloadRoot();
      final f = _metaFile(root, novelId);
      if (f.existsSync()) {
        return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      }
    } catch (e) {
      Log.warning('DownloadManager', 'read meta failed: $e');
    }
    return null;
  }

  /// 读取本地已下载章节内容（离线阅读）。
  Future<String?> readLocalChapter(String novelId, String cid) async {
    try {
      final root = await _downloadRoot();
      final f = chapterFile(root, novelId, cid);
      if (f.existsSync()) return f.readAsString();
    } catch (e) {
      Log.warning('DownloadManager', 'read local chapter failed: $e');
    }
    return null;
  }

  /// 本地是否已缓存该章节。
  Future<bool> hasLocalChapter(String novelId, String cid) async {
    try {
      final root = await _downloadRoot();
      return chapterFile(root, novelId, cid).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// 创建并启动下载任务。
  NovelDownloadTask start({
    required String novelId,
    required String novelName,
    required String coverUrl,
    required List<DownloadChapterRef> chapters,
    NovelInfo? info,
    List<Volume>? volumes,
  }) {
    final existing = _tasks[novelId];
    // 已有进行中/排队中的任务：合并章节而不是新建并发任务（避免重复请求触发限流）。
    if (existing != null &&
        existing.status != ChapterDownloadStatus.success &&
        existing.status != ChapterDownloadStatus.failed) {
      final known = existing.chapters.map((c) => c.cid).toSet();
      for (final c in chapters) {
        if (!known.contains(c.cid)) {
          existing.chapters.add(c);
        }
      }
      existing.info ??= info;
      existing.volumes ??= volumes;
      existing.notify();
      return existing;
    }
    final task = NovelDownloadTask(
      novelId: novelId,
      novelName: novelName,
      coverUrl: coverUrl,
      chapters: chapters,
      info: info,
      volumes: volumes,
    );
    _tasks[novelId] = task;
    // 断点续传：已存在本地文件的章节直接标记成功，避免重复请求。
    _markExistingAsDone(task);
    _ensureRunning();
    return task;
  }

  /// 扫描本地文件，把已下载的章节标记为成功（断点续传）。
  Future<void> _markExistingAsDone(NovelDownloadTask task) async {
    try {
      final root = await _downloadRoot();
      for (final c in task.chapters) {
        if (c.status == ChapterDownloadStatus.success) continue;
        if (chapterFile(root, task.novelId, c.cid).existsSync()) {
          c.status = ChapterDownloadStatus.success;
        }
      }
      task.downloadedCount =
          task.chapters
              .where((c) => c.status == ChapterDownloadStatus.success)
              .length;
      task.notify();
    } catch (e) {
      Log.warning('DownloadManager', 'resume scan failed: $e');
    }
  }

  void _ensureRunning() {
    if (_running) return;
    _running = true;
    unawaited(_loop());
  }

  Future<void> _loop() async {
    Log.info('DownloadManager', 'queue loop started');
    while (true) {
      NovelDownloadTask? next;
      for (final t in _tasks.values) {
        if (t.status == ChapterDownloadStatus.pending) {
          next = t;
          break;
        }
      }
      if (next == null) break;
      await _runTask(next);
    }
    _running = false;
    Log.info('DownloadManager', 'queue loop stopped');
  }

  Future<void> _runTask(NovelDownloadTask task) async {
    final root = await _downloadRoot();
    await WebViewFetcher.instance.ensureReady();
    task.status = ChapterDownloadStatus.downloading;
    task.notify();
    // 先写入元数据与离线目录，保证存储管理页/离线阅读可用（即使下载中途取消）。
    await _writeMeta(task);
    await _writeManifest(task, task.info, task.volumes);

    int downloaded = task.chapters.where((c) => c.status == ChapterDownloadStatus.success).length;

    for (final chapter in task.chapters) {
      if (task.cancelled) break;
      if (chapter.status == ChapterDownloadStatus.success) continue;

      // 全局冷却：站点限流期间任何任务都暂停发请求。
      await _waitCooldown();

      chapter.status = ChapterDownloadStatus.downloading;
      task.notify();

      final content = await _fetchChapterWithRetry(
        task,
        chapter.aid,
        chapter.cid,
      );
      if (content != null && content.isNotEmpty) {
        try {
          final f = chapterFile(root, task.novelId, chapter.cid);
          await f.writeAsString(content);
          chapter.status = ChapterDownloadStatus.success;
          downloaded++;
          task.downloadedCount = downloaded;
          Log.info(
            'DownloadManager',
            'chapter ok ${task.novelName} ${chapter.cid} (${content.length} chars)',
          );
        } catch (e) {
          chapter.status = ChapterDownloadStatus.failed;
          Log.error('DownloadManager', 'write chapter failed: $e');
        }
      } else {
        chapter.status = ChapterDownloadStatus.failed;
        task.failedCount++;
        Log.warning(
          'DownloadManager',
          'chapter failed ${chapter.cid} (${chapter.title})',
        );
      }
      task.notify();

      // 节流：自适应间隔，避免触发站点限流（参考 Venera 的限流思路）。
      await Future.delayed(_adaptiveInterval);
    }

    task.status =
        task.cancelled
            ? ChapterDownloadStatus.failed
            : (task.failedCount > 0
                ? ChapterDownloadStatus.failed
                : ChapterDownloadStatus.success);
    await _writeMeta(task);
    await _writeManifest(task, task.info, task.volumes);
    task.notify();
    Log.info(
      'DownloadManager',
      'task done ${task.novelName}: ok=${task.downloadedCount} fail=${task.failedCount}',
    );
  }

  /// 带限流退避的章节抓取。
  ///
  /// 遇到 HTTP 429（Too Many Requests）时：
  /// 1. 触发**全局冷却**（所有任务暂停发请求），避免持续撞限流；
  /// 2. 增大**自适应间隔**，后续请求整体放慢；
  /// 3. 指数退避重试，直到成功或超出尝试次数。
  Future<String?> _fetchChapterWithRetry(
    NovelDownloadTask task,
    String aid,
    String cid,
  ) async {
    const int maxAttempts = 6;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (task.cancelled) return null;
      await _waitCooldown();

      final aidNum = int.tryParse(aid) ?? 0;
      final subDir = aidNum ~/ 1000;
      final path = '/novel/$subDir/$aid/$cid.htm';
      final res = await WebViewFetcher.instance.fetchParsedEx(
        path,
        Wenku8Js.chapterText,
      );

      if (res.ok && res.text != null && res.text!.isNotEmpty) {
        return _normalize(res.text!);
      }

      if (res.isRateLimited) {
        // 触发全局冷却，并自适应减慢后续请求。
        final cooldown = Duration(
          seconds: (10 * attempt).clamp(10, 60),
        );
        _cooldownUntil = DateTime.now().add(cooldown);
        _slowDown();
        Log.warning(
          'DownloadManager',
          'rate limited (429) on $cid, attempt $attempt/$maxAttempts, '
          'cooldown ${cooldown.inSeconds}s, interval ${_adaptiveInterval.inMilliseconds}ms',
        );
        await _waitCooldown();
        continue;
      }

      // 非限流错误：短重试。
      Log.warning(
        'DownloadManager',
        'fetch $cid failed (${res.state}), attempt $attempt/$maxAttempts',
      );
      await Future.delayed(const Duration(seconds: 2));
    }
    Log.error(
      'DownloadManager',
      'chapter gave up: $cid after $maxAttempts attempts',
    );
    return null;
  }

  /// 增大自适应间隔（上限 [_maxInterval]）。
  void _slowDown() {
    final next = _adaptiveInterval * 2;
    _adaptiveInterval = next > _maxInterval ? _maxInterval : next;
  }

  /// 等待全局冷却结束。
  Future<void> _waitCooldown() async {
    final until = _cooldownUntil;
    if (until == null) return;
    final remain = until.difference(DateTime.now());
    if (remain.isNegative) {
      _cooldownUntil = null;
      return;
    }
    Log.info('DownloadManager', 'cooldown ${remain.inSeconds}s');
    await Future.delayed(remain);
    _cooldownUntil = null;
  }

  /// 归一化正文空白（与 Rust `chapter_content` 处理一致）。
  String _normalize(String content) {
    final lines =
        content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    var joined = lines.join('\n');
    joined = joined.replaceAll(RegExp(r'[ \t\u00a0]+'), ' ');
    final out = StringBuffer();
    var newlineCount = 0;
    for (final c in joined.runes) {
      if (c == 0x0A) {
        newlineCount++;
        if (newlineCount <= 2) out.writeCharCode(c);
      } else {
        if (newlineCount > 2) {
          out.write('\n\n');
        }
        newlineCount = 0;
        out.writeCharCode(c);
      }
    }
    return out.toString();
  }

  /// 取消并删除任务文件。
  Future<void> cancel(String novelId) async {
    final task = _tasks[novelId];
    if (task == null) return;
    task.cancelled = true;
    task.notify();
    try {
      final root = await _downloadRoot();
      final dir = Directory('$root${Platform.pathSeparator}$novelId');
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } catch (e) {
      Log.warning('DownloadManager', 'delete task dir failed: $e');
    }
  }

  /// 移除任务记录（不删文件）。
  void removeTask(String novelId) {
    _tasks.remove(novelId);
  }
}

/// 章节引用（下载用）。
class DownloadChapterRef {
  final String aid;
  final String cid;
  final String title;
  final String volumeId;
  final String volumeTitle;

  ChapterDownloadStatus status;

  DownloadChapterRef({
    required this.aid,
    required this.cid,
    required this.title,
    required this.volumeId,
    required this.volumeTitle,
    this.status = ChapterDownloadStatus.pending,
  });
}

/// 下载任务（Dart 侧）。
class NovelDownloadTask {
  final String novelId;
  final String novelName;
  final String coverUrl;
  final List<DownloadChapterRef> chapters;

  ChapterDownloadStatus status = ChapterDownloadStatus.pending;
  int downloadedCount = 0;
  int failedCount = 0;
  bool cancelled = false;

  final List<void Function()> _listeners = [];

  /// 小说完整信息与目录（用于离线阅读），可能为空（旧调用方未提供）。
  NovelInfo? info;
  List<Volume>? volumes;

  NovelDownloadTask({
    required this.novelId,
    required this.novelName,
    required this.coverUrl,
    required this.chapters,
    this.info,
    this.volumes,
  });

  int get total => chapters.length;
  double get progress => total == 0 ? 0 : downloadedCount / total;

  void addListener(void Function() fn) => _listeners.add(fn);
  void removeListener(void Function() fn) => _listeners.remove(fn);
  void notify() {
    for (final fn in List.of(_listeners)) {
      fn();
    }
  }
}
