import 'package:flutter/material.dart';
import 'package:wild/services/wenku8_repo.dart';
import 'package:wild/src/rust/api/database.dart';
import 'package:wild/src/rust/api/wenku8.dart' show PageStatsNovelCover;
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/widgets/novel_cover_card.dart';
import 'package:wild/widgets/novel_grid.dart';

class CategoryPage extends StatefulWidget {
  final String? initialTag;

  const CategoryPage({super.key, this.initialTag});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<TagGroup>? _tagGroups;
  String? _selectedTag;
  String _viewMode = "0"; // 默认按更新查看
  PageStatsNovelCover? _currentPage;
  bool _isLoading = false;
  String? _errorMessage;
  static const _keyTag = 'category_page_selected_tag';
  static const _keyViewMode = 'category_page_view_mode';

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.initialTag;
    _loadSavedState();
    _loadTags();
  }

  Future<void> _loadSavedState() async {
    try {
      if (_selectedTag == null) {
        final savedTag = await loadProperty(key: _keyTag);
        if (savedTag.isNotEmpty && mounted) {
          setState(() => _selectedTag = savedTag);
        }
      }
      final savedViewMode = await loadProperty(key: _keyViewMode);
      if (mounted && savedViewMode.isNotEmpty) {
        setState(() => _viewMode = savedViewMode);
      }
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      if (_selectedTag != null) {
        await saveProperty(key: _keyTag, value: _selectedTag!);
      }
      await saveProperty(key: _keyViewMode, value: _viewMode);
    } catch (_) {}
  }

  /// 加载分类标签（统一走 [Wenku8Repo]，不再自建 WebView、不再先撞 Rust）。
  Future<void> _loadTags() async {
    Log.info('CategoryPage', 'load tags via Wenku8Repo');
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final result = await Wenku8Repo.instance.tagGroups();
      if (!mounted) return;
      if (result.groups.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载分类失败，请下拉刷新重试';
        });
        return;
      }
      setState(() {
        _tagGroups = result.groups;
        _isLoading = false;
        _errorMessage = null;
      });
      if (_selectedTag == null) {
        final firstTag = result.groups
            .expand((g) => g.tags)
            .firstWhere((t) => t.isNotEmpty, orElse: () => '');
        if (firstTag.isNotEmpty) {
          setState(() => _selectedTag = firstTag);
          _saveState();
        }
      }
      if (_selectedTag != null) {
        _loadTagPage(_selectedTag!, refresh: true);
      }
    } catch (e, s) {
      Log.error('CategoryPage', 'load tags failed: $e', s);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载分类失败: $e';
      });
    }
  }

  Future<void> _loadTagPage(String tag, {bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = null;
        _errorMessage = null;
      }
    });

    final pageNumber = refresh ? 1 : (_currentPage?.currentPage ?? 0) + 1;
    try {
      final page = await Wenku8Repo.instance.tagPage(
        tag: tag,
        v: _viewMode,
        pageNumber: pageNumber,
      );
      if (!mounted) return;
      if (page == null) {
        setState(() {
          _isLoading = false;
          if (_currentPage == null) _errorMessage = '加载失败，请下拉刷新重试';
        });
        return;
      }
      setState(() {
        if (refresh || _currentPage == null) {
          _currentPage = page;
        } else {
          _currentPage = PageStatsNovelCover(
            currentPage: page.currentPage,
            maxPage: page.maxPage,
            records: [..._currentPage!.records, ...page.records],
          );
        }
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, s) {
      Log.error('CategoryPage', 'load tag page failed: $e', s);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_currentPage == null) _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Top bar with view mode and category selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // View mode selector
              Expanded(
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: "0", label: Text('更新')),
                    ButtonSegment(value: "1", label: Text('热门')),
                    ButtonSegment(value: "2", label: Text('完结')),
                    ButtonSegment(value: "3", label: Text('动画')),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (Set<String> selection) {
                    _saveState();
                    setState(() {
                      _viewMode = selection.first;
                    });
                    if (_selectedTag != null) {
                      _loadTagPage(_selectedTag!, refresh: true);
                    }
                  },
                ),
              ),
              // Category selector
              if (_tagGroups != null && _tagGroups!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: PopupMenuButton<String>(
                    tooltip: '分类',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedTag ?? '分类',
                            style: TextStyle(
                              color:
                                  _selectedTag != null
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                              fontWeight:
                                  _selectedTag != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[];
                      final groups = _tagGroups!;
                      for (var gi = 0; gi < groups.length; gi++) {
                        final group = groups[gi];
                        items.add(
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              group.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                        for (final tag in group.tags) {
                          items.add(
                            PopupMenuItem<String>(
                              value: tag,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        _selectedTag == tag
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : null,
                                    fontWeight:
                                        _selectedTag == tag
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        if (gi != groups.length - 1) {
                          items.add(const PopupMenuDivider());
                        }
                      }
                      return items;
                    },
                    onSelected: (tag) async {
                      setState(() => _selectedTag = tag);
                      _loadTagPage(tag, refresh: true);
                      _saveState();
                    },
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextButton.icon(
                    onPressed: _loadTags,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试加载分类'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        // Novel grid or error state
        Expanded(
          child:
              _selectedTag == null
                  ? Center(
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('请选择分类'),
                  )
                  : _errorMessage != null
                  ? RefreshIndicator(
                    onRefresh: () => _loadTags(),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '加载失败 (下拉刷新)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  : _currentPage == null
                  ? const Center(child: CircularProgressIndicator())
                  : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200 &&
                          !_isLoading &&
                          _currentPage!.currentPage < _currentPage!.maxPage) {
                        _loadTagPage(_selectedTag!);
                      }
                      return true;
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: novelGridColumns(context),
                        childAspectRatio: kNovelCardAspectRatio,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount:
                          _currentPage!.records.length +
                          (_currentPage!.currentPage < _currentPage!.maxPage
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index >= _currentPage!.records.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final novel =
                            _currentPage!.records[index] as NovelCover;
                        return NovelCoverCard(novel: novel);
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}
