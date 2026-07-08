import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wild/src/rust/api/wenku8.dart'
    show PageStatsNovelCover, getSessionCookieString;
import 'package:wild/src/rust/wenku8/models.dart' show NovelCover;

class CfSearchLoader extends StatefulWidget {
  final String apiHost;
  final String searchType;
  final String searchKey;
  final int page;
  final void Function(PageStatsNovelCover result) onSuccess;
  final void Function(String error) onError;

  const CfSearchLoader({
    super.key,
    required this.apiHost,
    required this.searchType,
    required this.searchKey,
    required this.page,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<CfSearchLoader> createState() => _CfSearchLoaderState();
}

class _CfSearchLoaderState extends State<CfSearchLoader> {
  late final WebViewController _controller;
  Timer? _timeout;
  bool _submitted = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: _onPageFinished,
              onWebResourceError: (err) {
                if (!_done) _fail('WebView 搜索加载失败: ${err.description}');
              },
            ),
          );
    _timeout = Timer(const Duration(seconds: 35), () {
      if (!_done) _fail('搜索加载超时，请稍后重试');
    });
    _log('open search page');
    _controller.loadRequest(
      Uri.parse('${widget.apiHost}/modules/article/search.php'),
    );
  }

  Future<void> _onPageFinished(String url) async {
    _log('page finished: $url submitted=$_submitted');
    if (_done) return;
    await Future.delayed(const Duration(milliseconds: 1000));

    final challenge = await _controller.runJavaScriptReturningResult(
      'document.getElementById("challenge-form") !== null ? "yes" : "no"',
    );
    if (challenge.toString().contains('yes')) {
      _log('cloudflare challenge detected, waiting');
      return;
    }

    if (!_submitted) {
      await _injectCookies();
      _submitted = true;
      await _submitSearchForm();
      return;
    }

    await _parseResults();
  }

  Future<void> _injectCookies() async {
    try {
      final cookieStr = await getSessionCookieString();
      _log('inject cookies, length=${cookieStr.length}');
      for (final part in cookieStr.split('; ')) {
        final eq = part.indexOf('=');
        if (eq <= 0) continue;
        final name = part.substring(0, eq);
        final value = part.substring(eq + 1);
        final assignment = jsonEncode(
          '$name=$value; path=/; domain=.wenku8.net',
        );
        await _controller.runJavaScript('document.cookie = $assignment;');
      }
    } catch (e) {
      _log('inject cookies failed: $e');
    }
  }

  Future<void> _submitSearchForm() async {
    _log('submit form type=${widget.searchType} key=${widget.searchKey}');
    final action = jsonEncode('${widget.apiHost}/modules/article/search.php');
    final searchType = jsonEncode(widget.searchType);
    final searchKey = jsonEncode(widget.searchKey);
    final page = jsonEncode(widget.page.toString());
    await _controller.runJavaScript('''
(function() {
  var f = document.createElement('form');
  f.method = 'POST';
  f.action = $action;
  f.acceptCharset = 'gbk';
  function add(name, value) {
    var input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    f.appendChild(input);
  }
  add('searchtype', $searchType);
  add('searchkey', $searchKey);
  add('page', $page);
  add('charset', 'gbk');
  document.body.appendChild(f);
  f.submit();
})()
''');
  }

  Future<void> _parseResults() async {
    try {
      final raw = await _controller.runJavaScriptReturningResult(r'''
(function() {
  var records = [];
  document.querySelectorAll('table.grid tr td > div').forEach(function(block) {
    var img = block.querySelector('a > img');
    if (!img) return;
    var td = block.closest('td') || block;
    var links = Array.prototype.slice.call(td.querySelectorAll('a[href*="/book/"]'));
    var a = links.find(function(link) {
      return (link.getAttribute('title') || link.textContent || '').trim().length > 0;
    }) || img.closest('a') || links[0];
    if (!a) return;
    var href = a.getAttribute('href') || '';
    var absHref = new URL(href, location.href).href;
    var aidMatch = absHref.match(/\/book\/([^\/]+)\.htm/);
    var aid = aidMatch ? aidMatch[1] : absHref.split('/').pop().replace('.htm', '');
    var title = (a.getAttribute('title') || a.textContent || img.getAttribute('alt') || '').trim();
    if (!title) {
      title = (td.textContent || '').replace(/\s+/g, ' ').trim();
    }
    records.push({
      title: title,
      img: new URL(img.getAttribute('src') || '', location.href).href,
      detailUrl: href,
      aid: aid
    });
  });
  var currentPage = 1;
  var maxPage = 1;
  var stat = document.querySelector('em#pagestats');
  if (stat) {
    var parts = stat.textContent.split('/');
    currentPage = parseInt(parts[0], 10) || 1;
    maxPage = parseInt(parts[1], 10) || currentPage;
  }
  return JSON.stringify({currentPage: currentPage, maxPage: maxPage, records: records});
})()
''');
      final data = jsonDecode(_stripJsonString(raw.toString())) as Map;
      final records =
          (data['records'] as List)
              .map(
                (e) => NovelCover(
                  title: e['title'] ?? '',
                  img: e['img'] ?? '',
                  detailUrl: e['detailUrl'] ?? '',
                  aid: e['aid'] ?? '',
                ),
              )
              .where((e) => e.aid.isNotEmpty)
              .toList();
      _log('parsed records=${records.length}');
      if (records.isEmpty) {
        await _logEmptyResultPageInfo();
      }
      _done = true;
      _timeout?.cancel();
      widget.onSuccess(
        PageStatsNovelCover(
          currentPage: data['currentPage'] ?? widget.page,
          maxPage: data['maxPage'] ?? widget.page,
          records: records,
        ),
      );
    } catch (e) {
      _fail('解析搜索结果失败: $e');
    }
  }

  Future<void> _logEmptyResultPageInfo() async {
    try {
      final raw = await _controller.runJavaScriptReturningResult(r'''
(function() {
  function clean(s) {
    return (s || '').replace(/\s+/g, ' ').trim().slice(0, 500);
  }
  return JSON.stringify({
    href: location.href,
    title: document.title,
    gridCount: document.querySelectorAll('table.grid tr td > div').length,
    imgCount: document.querySelectorAll('img').length,
    pageStats: (document.querySelector('em#pagestats') || {}).textContent || '',
    body: clean(document.body ? document.body.innerText : '')
  });
})()
''');
      _log('empty page info=${_stripJsonString(raw.toString())}');
    } catch (e) {
      _log('empty page info failed: $e');
    }
  }

  String _stripJsonString(String s) {
    if (s.startsWith('"') && s.endsWith('"')) return jsonDecode(s) as String;
    return s;
  }

  void _fail(String message) {
    _done = true;
    _timeout?.cancel();
    _log('failed: $message');
    widget.onError(message);
  }

  void _log(String message) {
    debugPrint('[CfSearch] $message');
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
