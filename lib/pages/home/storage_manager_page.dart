import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wild/pages/novel/reader_page.dart';
import 'package:wild/services/download_manager.dart';
import 'package:wild/services/offline_library.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/widgets/cached_image.dart';

/// 应用内存储管理页。
///
/// 因鸿蒙私有沙箱在系统文件管理器中不可见，这里提供应用内查看/清理能力：
/// 展示每个已下载小说的章节数与磁盘占用，并支持删除整本。
class StorageManagerPage extends StatefulWidget {
  const StorageManagerPage({super.key});

  @override
  State<StorageManagerPage> createState() => _StorageManagerPageState();
}

class _StorageManagerPageState extends State<StorageManagerPage> {
  bool _loading = true;
  String _rootPath = '';
  int _totalBytes = 0;
  final List<_NovelStorage> _items = [];

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    _items.clear();
    _totalBytes = 0;
    try {
      final root = await NovelDownloadManager.instance.downloadRoot();
      _rootPath = root;
      final dir = Directory(root);
      if (dir.existsSync()) {
        for (final entry in dir.listSync()) {
          if (entry is! Directory) continue;
          final novelId = entry.path.split(Platform.pathSeparator).last;
          int chapterCount = 0;
          int bytes = 0;
          for (final f in entry.listSync()) {
            if (f is File) {
              try {
                bytes += f.lengthSync();
              } catch (_) {}
              if (f.path.endsWith('.txt')) chapterCount++;
            }
          }
          // 读取元数据获取小说名称（旧数据无 meta.json 时回退为 ID）。
          final meta = await NovelDownloadManager.instance.readMeta(novelId);
          final name =
              (meta?['novelName'] as String?)?.trim().isNotEmpty == true
                  ? meta!['novelName'] as String
                  : novelId;
          final coverUrl = (meta?['coverUrl'] as String?) ?? '';
          _totalBytes += bytes;
          _items.add(
            _NovelStorage(
              novelId: novelId,
              novelName: name,
              coverUrl: coverUrl,
              chapterCount: chapterCount,
              bytes: bytes,
              dirPath: entry.path,
            ),
          );
        }
      }
      _items.sort((a, b) => b.bytes.compareTo(a.bytes));
      Log.info(
        'StorageManager',
        'scanned ${_items.length} novels, total $_totalBytes bytes',
      );
    } catch (e, s) {
      Log.error('StorageManager', 'scan failed: $e', s);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _deleteNovel(_NovelStorage item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除下载'),
            content: Text('确定要删除《${item.novelName}》的 ${item.chapterCount} 个章节吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      final dir = Directory(item.dirPath);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      Log.info('StorageManager', 'deleted ${item.novelId}');
      await _scan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('清空全部下载'),
            content: const Text('确定要删除所有已下载的章节吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      final dir = Directory(_rootPath);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      await _scan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  /// 离线阅读：从本地 manifest 重建阅读器（不需要网络）。
  Future<void> _readOffline(_NovelStorage item) async {
    try {
      final offline = await OfflineLibrary.instance.load(item.novelId);
      if (!mounted) return;
      if (offline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('该下载缺少目录信息（旧版本下载），无法离线阅读'),
          ),
        );
        return;
      }
      final firstVolume = offline.volumes.first;
      final firstChapter = firstVolume.chapters.first;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ReaderPage(
                aid: offline.novelId,
                cid: firstChapter.cid,
                initialTitle: firstChapter.title,
                volumes: offline.volumes,
                novelInfo: offline.info,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('离线阅读失败: $e')));
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scan,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清空全部',
            onPressed: _items.isEmpty ? null : _deleteAll,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildSummary(context),
                  const Divider(height: 1),
                  Expanded(
                    child:
                        _items.isEmpty
                            ? const Center(child: Text('暂无下载内容'))
                            : ListView.builder(
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return ListTile(
                                  leading:
                                      item.coverUrl.isNotEmpty
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: CachedImage(
                                              url: item.coverUrl,
                                              width: 40,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          )
                                          : const Icon(Icons.menu_book_outlined),
                                  title: Text(
                                    item.novelName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${item.chapterCount} 章 · ${_formatBytes(item.bytes)}',
                                  ),
                                  onTap: () => _readOffline(item),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteNovel(item),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sd_storage_outlined),
              const SizedBox(width: 8),
              Text(
                '总占用: ${_formatBytes(_totalBytes)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '存储位置: $_rootPath',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '共 ${_items.length} 本小说',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NovelStorage {
  final String novelId;
  final String novelName;
  final String coverUrl;
  final int chapterCount;
  final int bytes;
  final String dirPath;

  _NovelStorage({
    required this.novelId,
    required this.novelName,
    required this.coverUrl,
    required this.chapterCount,
    required this.bytes,
    required this.dirPath,
  });
}
