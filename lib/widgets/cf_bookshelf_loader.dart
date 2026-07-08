import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wild/src/rust/api/wenku8.dart' show getSessionCookieString;
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/app_platform.dart';

class CfBookshelfLoader extends StatefulWidget {
  static bool get isOhosFallback => AppPlatform.isOHOS;

  final String apiHost;
  final void Function(
    List<Bookcase> bookcases,
    Map<String, BookcaseDto> contents,
  )?
  onPartialData;
  final void Function(
    List<Bookcase> bookcases,
    Map<String, BookcaseDto> contents,
  )
  onSuccess;
  final void Function(String error) onError;

  const CfBookshelfLoader({
    super.key,
    required this.apiHost,
    this.onPartialData,
    required this.onSuccess,
    required this.onError,
  });

  @override
  CfBookshelfLoaderState createState() => CfBookshelfLoaderState();
}

class CfBookshelfLoaderState extends State<CfBookshelfLoader> {
  late final WebViewController _controller;

  bool _homeLoaded = false;
  bool _cookiesInjected = false;
  bool _active = false;
  int _notReadyCount = 0;
  Timer? _timeout;

  List<Bookcase> _bookcases = [];
  final Map<String, BookcaseDto> _contents = {};

  static const _jsGetBookcases = r'''
(function() {
  var opts = document.querySelectorAll('select[name="classlist"] option');
  var result = [];
  opts.forEach(function(opt) {
    var id = opt.value || '';
    var title = (opt.textContent || opt.innerText || '').trim();
    if (id) result.push({id: id, title: title});
  });
  return JSON.stringify(result);
})()
''';

  static const _jsGetBooks = r'''
(function() {
  var checkboxes = document.querySelectorAll('td.odd > input[type="checkbox"]');
  var items = [];
  function getParam(href, key) {
    try { return new URL(href, location.href).searchParams.get(key) || ''; }
    catch(e) { return ''; }
  }
  checkboxes.forEach(function(cb) {
    try {
      var row = cb.parentElement.parentElement;
      var tds = Array.from(row.getElementsByTagName('td'));
      var idx = tds.indexOf(cb.parentElement);
      if (idx < 0 || idx + 3 >= tds.length) return;
      var titleA = tds[idx+1].querySelector('a');
      var authorA = tds[idx+2].querySelector('a');
      var chapterA = tds[idx+3].querySelector('a');
      if (!titleA || !authorA || !chapterA) return;
      items.push({
        aid: getParam(titleA.getAttribute('href'), 'aid'),
        bid: getParam(titleA.getAttribute('href'), 'bid'),
        title: (titleA.textContent || '').trim(),
        author: (authorA.textContent || '').trim(),
        cid: getParam(chapterA.getAttribute('href'), 'cid'),
        chapterName: (chapterA.textContent || '').trim()
      });
    } catch(e) {}
  });
  var body = document.body ? document.body.innerText : '';
  var tipMatch = body.match(/书架可收藏\s*\d+\s*本[^，,]*[，,]\s*已收藏\s*\d+\s*本/);
  return JSON.stringify({items: items, tip: tipMatch ? tipMatch[0] : ''});
})()
''';

  @override
  void initState() {
    super.initState();
    _log('init, preloading ${widget.apiHost}/');
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: _onPageFinished,
              onWebResourceError: (err) {
                _log('resource error: ${err.description}');
                if (_active) _fail('WebView 加载失败: ${err.description}');
              },
            ),
          );
    _controller.loadRequest(Uri.parse('${widget.apiHost}/'));
  }

  void reload() {
    _log('reload requested, homeLoaded=$_homeLoaded');
    if (_active) {
      _log('reload ignored because a bookshelf fallback is already active');
      return;
    }
    _active = true;
    _notReadyCount = 0;
    _bookcases = [];
    _contents.clear();
    _startTimeout();

    if (_homeLoaded) {
      unawaited(_navigateToBookcase());
    }
  }

  Future<void> _navigateToBookcase() async {
    _log('navigate to bookcase, cookiesInjected=$_cookiesInjected');
    if (!_cookiesInjected) {
      await _injectCookies();
    }
    await _controller.loadRequest(
      Uri.parse('${widget.apiHost}/modules/article/bookcase.php'),
    );
  }

  Future<void> _injectCookies() async {
    try {
      final cookieStr = await getSessionCookieString();
      _log('inject cookies, length=${cookieStr.length}');
      if (cookieStr.isNotEmpty) {
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
      }
      _cookiesInjected = true;
    } catch (e) {
      _log('inject cookies failed: $e');
    }
  }

  Future<void> _onPageFinished(String url) async {
    _log('page finished: $url active=$_active homeLoaded=$_homeLoaded');
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!_homeLoaded) {
      final blocked = await _controller.runJavaScriptReturningResult(
        'document.title.toLowerCase().includes("blocked") || '
        '(document.body ? document.body.innerText.includes("Sorry, you have been blocked") : false) '
        '? "yes" : "no"',
      );
      if (blocked.toString().contains('yes')) {
        if (_active) _fail('IP 被 Cloudflare 封锁，请更换网络或稍后重试');
        return;
      }

      final isCfChallenge = await _controller.runJavaScriptReturningResult(
        'document.getElementById("challenge-form") !== null ? "yes" : "no"',
      );
      if (isCfChallenge.toString().contains('yes')) {
        _log('cloudflare challenge detected, waiting');
        return;
      }

      _homeLoaded = true;
      _log('home preload ready');
      if (_active) {
        await _navigateToBookcase();
      }
      return;
    }

    if (!_active) return;

    final check = await _controller.runJavaScriptReturningResult(
      'document.querySelector(\'select[name="classlist"]\') ? "ready" : "not_ready"',
    );
    if (check.toString().contains('not_ready')) {
      _notReadyCount++;
      final info = await _pageInfo();
      _log('bookcase DOM not ready #$_notReadyCount: $info');
      if (_notReadyCount >= 3 || info.contains('login.php')) {
        _fail('书架页面未就绪，可能登录态未同步或被站点拦截: $info');
        return;
      }
      _cookiesInjected = false;
      await _navigateToBookcase();
      return;
    }

    if (_bookcases.isEmpty) {
      await _loadBookcaseList();
    } else {
      await _loadCurrentCaseBooks(url);
    }
  }

  Future<void> _loadBookcaseList() async {
    try {
      final raw = await _controller.runJavaScriptReturningResult(
        _jsGetBookcases,
      );
      final json = _stripJsonString(raw.toString());
      final list = jsonDecode(json) as List;
      _bookcases =
          list
              .map((e) => Bookcase(id: e['id'] ?? '', title: e['title'] ?? ''))
              .where((e) => e.id.isNotEmpty)
              .toList();
      _log('bookcase count=${_bookcases.length}');
      if (_bookcases.isEmpty) {
        final info = await _pageInfo();
        _fail('未解析到书架分类，保留现有书架数据: $info');
        return;
      }
      await _extractBooksAndContinue(_bookcases[0].id);
    } catch (e) {
      if (_active) _fail('解析书架分类失败: $e');
    }
  }

  Future<void> _loadCurrentCaseBooks(String url) async {
    final caseId = Uri.tryParse(url)?.queryParameters['classid'];
    if (caseId != null) {
      await _extractBooksAndContinue(caseId);
    }
  }

  Future<void> _extractBooksAndContinue(String caseId) async {
    try {
      final raw = await _controller.runJavaScriptReturningResult(_jsGetBooks);
      final json = _stripJsonString(raw.toString());
      final data = jsonDecode(json) as Map;
      final items =
          (data['items'] as List)
              .map(
                (e) => BookcaseItem(
                  aid: e['aid'] ?? '',
                  bid: e['bid'] ?? '',
                  title: e['title'] ?? '',
                  author: e['author'] ?? '',
                  cid: e['cid'] ?? '',
                  chapterName: e['chapterName'] ?? '',
                ),
              )
              .toList();
      _contents[caseId] = BookcaseDto(items: items, tip: data['tip'] ?? '');
      _log('case $caseId items=${items.length}');

      widget.onPartialData?.call(List.from(_bookcases), Map.from(_contents));

      final pending =
          _bookcases
              .map((b) => b.id)
              .where(
                (id) => id != _bookcases[0].id && !_contents.containsKey(id),
              )
              .toList();

      if (pending.isEmpty) {
        _finish();
        widget.onSuccess(List.from(_bookcases), Map.from(_contents));
      } else {
        await _controller.loadRequest(
          Uri.parse(
            '${widget.apiHost}/modules/article/bookcase.php?classid=${pending.first}',
          ),
        );
      }
    } catch (e) {
      if (_active) _fail('解析书本列表失败: $e');
    }
  }

  Future<String> _pageInfo() async {
    try {
      final raw = await _controller.runJavaScriptReturningResult(r'''
(function() {
  var text = document.body ? document.body.innerText : '';
  return JSON.stringify({
    href: location.href,
    title: document.title,
    text: text.replace(/\s+/g, ' ').slice(0, 180)
  });
})()
''');
      return _stripJsonString(raw.toString());
    } catch (e) {
      return 'pageInfoError=$e';
    }
  }

  String _stripJsonString(String s) {
    if (s.startsWith('"') && s.endsWith('"')) return jsonDecode(s) as String;
    return s;
  }

  void _startTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 30), () {
      if (_active) {
        _fail('书架加载超时，请重新登录或稍后重试');
      }
    });
  }

  void _finish() {
    _timeout?.cancel();
    _active = false;
    _notReadyCount = 0;
    _log('finished');
  }

  void _fail(String message) {
    _timeout?.cancel();
    _active = false;
    _notReadyCount = 0;
    _log('failed: $message');
    widget.onError(message);
  }

  void _log(String message) {
    debugPrint('[CfBookshelf] $message');
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
