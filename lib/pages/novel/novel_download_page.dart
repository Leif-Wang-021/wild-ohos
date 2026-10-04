import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/pages/novel/novel_download_cubit.dart';
import 'package:wild/services/download_manager.dart';
import 'package:wild/widgets/cached_image.dart';
import 'package:wild/pages/novel/novel_download_info_page.dart';
import 'package:wild/src/rust/api/wenku8.dart' as w8;

/// 下载管理页：展示进行中的 Dart 下载任务 + 已完成下载记录。
class NovelDownloadPage extends StatelessWidget {
  const NovelDownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NovelDownloadCubit()..loadDownloads(),
      child: const _NovelDownloadContent(),
    );
  }
}

class _NovelDownloadContent extends StatefulWidget {
  const _NovelDownloadContent();

  @override
  State<_NovelDownloadContent> createState() => _NovelDownloadContentState();
}

class _NovelDownloadContentState extends State<_NovelDownloadContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () async {
              context.read<NovelDownloadCubit>().loadDownloads();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 进行中的任务（Dart 侧，可实时刷新进度）
          _ActiveTasksPanel(onChanged: () => setState(() {})),
          Expanded(
            child: BlocBuilder<NovelDownloadCubit, NovelDownloadState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              () => context
                                  .read<NovelDownloadCubit>()
                                  .loadDownloads(),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }
                if (state.downloads.isEmpty) {
                  return const Center(child: Text('暂无已完成的下载'));
                }
                return ListView.builder(
                  itemCount: state.downloads.length,
                  itemBuilder: (context, index) {
                    final download = state.downloads[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => NovelDownloadInfoPage(
                                    novelId: download.novelId,
                                  ),
                            ),
                          );
                          if (context.mounted) {
                            context
                                .read<NovelDownloadCubit>()
                                .loadDownloads();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedImage(
                                  url: download.coverUrl,
                                  width: 80,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      download.novelName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      download.author,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.book_outlined,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${download.downloadChapterCount}/${download.chooseChapterCount} 章节',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.download_outlined,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getStatusText(
                                            download.downloadStatus,
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _getStatusColor(
                                              download.downloadStatus,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusIcon(download.downloadStatus),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(int status) {
    switch (status) {
      case 0:
        return const Icon(Icons.download_outlined);
      case 1:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case 2:
        return const Icon(Icons.error_outline, color: Colors.red);
      case 3:
        return const Icon(Icons.delete_outline, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline);
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '等待下载';
      case 1:
        return '下载完成';
      case 2:
        return '下载失败';
      case 3:
        return '正在删除';
      default:
        return '未知状态';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// 进行中任务面板：监听 Dart 侧下载任务并实时刷新。
class _ActiveTasksPanel extends StatefulWidget {
  final VoidCallback onChanged;

  const _ActiveTasksPanel({required this.onChanged});

  @override
  State<_ActiveTasksPanel> createState() => _ActiveTasksPanelState();
}

class _ActiveTasksPanelState extends State<_ActiveTasksPanel> {
  List<NovelDownloadTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _tasks = NovelDownloadManager.instance.tasks);
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('进行中', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ..._tasks.map((task) {
          return _ActiveTaskTile(
            task: task,
            onChanged: () {
              _refresh();
              widget.onChanged();
            },
          );
        }),
        const Divider(height: 1),
      ],
    );
  }
}

class _ActiveTaskTile extends StatefulWidget {
  final NovelDownloadTask task;
  final VoidCallback onChanged;

  const _ActiveTaskTile({required this.task, required this.onChanged});

  @override
  State<_ActiveTaskTile> createState() => _ActiveTaskTileState();
}

class _ActiveTaskTileState extends State<_ActiveTaskTile> {
  @override
  void initState() {
    super.initState();
    widget.task.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.task.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedImage(
                url: task.coverUrl,
                width: 48,
                height: 72,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.novelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: task.progress),
                  const SizedBox(height: 4),
                  Text(
                    '${task.downloadedCount}/${task.total} 章'
                    '${task.failedCount > 0 ? " · 失败 ${task.failedCount}" : ""}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '取消',
              onPressed: () async {
                await NovelDownloadManager.instance.cancel(task.novelId);
                NovelDownloadManager.instance.removeTask(task.novelId);
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
