import 'package:flutter/material.dart';

import '../src/rust/api/wenku8.dart';
import '../src/rust/wenku8/models.dart';
import '../widgets/cached_image.dart';
import '../widgets/cf_search_loader.dart';

class SearchPage extends StatefulWidget {
  final String? initialSearchType;
  final String? initialSearchKey;

  const SearchPage({super.key, this.initialSearchType, this.initialSearchKey});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  late String _searchType;
  PageStatsNovelCover? _searchResults;
  List<SearchHistory>? _searchHistories;
  bool _isLoading = false;
  bool _webViewSearchActive = false;
  String _webViewApiHost = 'https://www.wenku8.net';
  int _webViewSearchPage = 1;
  bool _webViewSearchRefresh = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchType = widget.initialSearchType ?? 'articlename';
    if (widget.initialSearchKey != null) {
      _searchController.text = widget.initialSearchKey!;
      _search(refresh: true);
    }
    _loadSearchHistories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistories() async {
    try {
      final histories = await searchHistories();
      if (!mounted) return;
      setState(() => _searchHistories = histories);
    } catch (_) {}
  }

  Future<void> _search({bool refresh = false}) async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _errorMessage = null;
        _searchResults = null;
      });
      return;
    }
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _searchResults = null;
        _errorMessage = null;
      }
    });

    final page = refresh ? 1 : (_searchResults?.currentPage ?? 0) + 1;
    try {
      final results = await search(
        searchType: _searchType,
        searchKey: _searchController.text,
        page: page,
      );
      if (!mounted) return;
      _applySearchResults(results, refresh: refresh);
      _loadSearchHistories();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('403') ||
          msg.contains('Forbidden') ||
          msg.contains('Cloudflare')) {
        final apiHost = await getApiHost();
        if (!mounted) return;
        setState(() {
          _webViewApiHost =
              apiHost.isEmpty ? 'https://www.wenku8.net' : apiHost;
          _webViewSearchPage = page;
          _webViewSearchRefresh = refresh;
          _webViewSearchActive = true;
          _isLoading = true;
          _errorMessage = null;
          if (refresh) _searchResults = null;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = msg;
        _searchResults = null;
      });
    }
  }

  void _applySearchResults(
    PageStatsNovelCover results, {
    required bool refresh,
  }) {
    setState(() {
      if (refresh || _searchResults == null) {
        _searchResults = results;
      } else {
        _searchResults = PageStatsNovelCover(
          currentPage: results.currentPage,
          maxPage: results.maxPage,
          records: [..._searchResults!.records, ...results.records],
        );
      }
      _isLoading = false;
      _webViewSearchActive = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        actions: [
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'articlename', label: Text('书名')),
              ButtonSegment(value: 'author', label: Text('作者')),
            ],
            selected: {_searchType},
            onSelectionChanged: (selection) {
              setState(() {
                _searchType = selection.first;
                _searchController.clear();
                _searchResults = null;
                _errorMessage = null;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '搜索小说或作者',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) _search(refresh: true);
                  },
                ),
              ),
              Expanded(child: _buildBodyContent(context)),
            ],
          ),
          if (_webViewSearchActive)
            Positioned(
              right: 0,
              bottom: 0,
              width: 1,
              height: 1,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.01,
                  child: CfSearchLoader(
                    apiHost: _webViewApiHost,
                    searchType: _searchType,
                    searchKey: _searchController.text,
                    page: _webViewSearchPage,
                    onSuccess: (result) {
                      if (!mounted) return;
                      _applySearchResults(
                        result,
                        refresh: _webViewSearchRefresh,
                      );
                    },
                    onError: (error) {
                      if (!mounted) return;
                      setState(() {
                        _webViewSearchActive = false;
                        _isLoading = false;
                        _errorMessage = error;
                      });
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    if (_searchController.text.isEmpty &&
        _searchHistories != null &&
        _searchHistories!.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchHistories!.length,
        itemBuilder: (context, index) {
          final history = _searchHistories![index];
          final byName = history.searchType == 'articlename';
          return ListTile(
            leading: Icon(
              byName ? Icons.book : Icons.person,
              color: byName ? Colors.blue : Colors.green,
            ),
            title: Text(
              history.searchKey,
              style: TextStyle(color: byName ? Colors.blue : Colors.green),
            ),
            subtitle: Text(
              byName ? '书名搜索' : '作者搜索',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              _searchController.text = history.searchKey;
              setState(() => _searchType = history.searchType);
              _search(refresh: true);
            },
          );
        },
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: () => _search(refresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height - 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '搜索失败 (下拉刷新)',
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
      );
    }

    if (_searchResults != null) {
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200 &&
              !_isLoading &&
              _searchResults!.currentPage < _searchResults!.maxPage) {
            _search();
          }
          return true;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 207 / 307,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount:
              _searchResults!.records.length +
              (_searchResults!.currentPage < _searchResults!.maxPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _searchResults!.records.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _NovelCoverCard(novel: _searchResults!.records[index]);
          },
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return const Center(child: Text('输入关键词开始搜索'));
  }
}

class _NovelCoverCard extends StatelessWidget {
  final NovelCover novel;

  const _NovelCoverCard({required this.novel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () =>
              Navigator.pushNamed(context, '/novel/info', arguments: novel.aid),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: .5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CachedImage(url: novel.img, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                novel.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
