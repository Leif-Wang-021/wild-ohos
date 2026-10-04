import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/log.dart';

/// 通过 WebView 绕过 Cloudflare 抓取一组 wenku8 页面，并执行解析脚本。
///
/// Rust 端使用 reqwest，无法完成 Cloudflare 的 JS 挑战，因此 index.php 等页面
/// 会返回 403。本组件复刻 `cf_search_loader` 的思路：先在 WebView 中打开站点
/// 通过挑战，随后**不导航**到目标页，而是在同源会话里用 `fetch` 取回 HTML，
/// 用 `DOMParser` 解析后执行 [parserJs]，从而避免目标页自身再次触发挑战。
///
/// 解析脚本可从 `window.__doc` 读取解析后的目标文档（为空时回退到当前文档）。
class CfPageLoader extends StatefulWidget {
  final String apiHost;

  /// 目标页面路径，例如 `/index.php?charset=gbk`。
  final String path;

  /// 在 `window.__doc` 上执行的解析脚本（返回 JSON 字符串）。
  final String parserJs;

  /// 为 true 时不使用 fetch，而是直接导航到目标页。
  ///
  /// 适用于需要浏览器按页面 charset（如 GBK）解析中文链接的场景：导航后
  /// `document` 自身即为目标页，`a.href` 会按页面编码正确百分号编码。
  final bool navigateInsteadOfFetch;

  /// 可选的导航脚本：在已通过挑战的页面上执行，用于构造 form 提交以触发
  /// 浏览器按指定 charset（如 GBK）编码 URL。执行后 `document` 会变为目标页。
  final String? navigateJs;

  final void Function(String json) onSuccess;
  final void Function(String error) onError;

  const CfPageLoader({
    super.key,
    required this.apiHost,
    required this.path,
    required this.parserJs,
    this.navigateInsteadOfFetch = false,
    this.navigateJs,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<CfPageLoader> createState() => _CfPageLoaderState();
}

class _CfPageLoaderState extends State<CfPageLoader> {
  late final WebViewController _controller;
  Timer? _timeout;
  bool _done = false;
  Completer<void>? _navCompleter;

  /// 处理阶段：0=等待首页，1=已开始获取/导航（忽略后续 onPageFinished）。
  int _phase = 0;

  /// 检测当前页面是否仍处于 Cloudflare 挑战（中英文标识）。
  static const String _jsChallenge = r'''
(function() {
  var text = document.body ? document.body.innerText : '';
  var title = document.title || '';
  var markers = [
    'Just a moment', '__cf_chl_', 'Sorry, you have been blocked',
    'Enable JavaScript and cookies',
    '正在进行安全验证', '请稍候', '安全服务防护', '验证您不是自动程序',
    'Checking your browser', 'Attention Required'
  ];
  for (var i = 0; i < markers.length; i++) {
    if (text.indexOf(markers[i]) >= 0 || title.indexOf(markers[i]) >= 0) return 'challenged';
  }
  if (document.getElementById('challenge-form') !== null) return 'challenged';
  return 'ok';
})()
''';

  /// 用 fetch 取回目标页面并解析为 DOM，写入 window.__doc。
  ///
  /// 注意：wenku8 的页面声明 `charset=UTF-8`，实际正文却是 **GBK** 编码，
  /// 直接用 `response.text()` 会得到乱码。这里改为取 `arrayBuffer`，再用
  /// `TextDecoder('gbk')` 正确解码。
  String _fetchJs(String path) => r'''
(function() {
  window.__pageState = 'loading';
  window.__doc = null;
  var url = __URL__;
  fetch(url, { credentials: 'include', cache: 'no-store' })
    .then(function(r) {
      if (!r.ok) { window.__pageState = 'http:' + r.status; return null; }
      return r.arrayBuffer();
    })
    .then(function(buf) {
      if (!buf) return;
      var html;
      try {
        html = new TextDecoder('gbk').decode(buf);
      } catch (e) {
        try { html = new TextDecoder('gb18030').decode(buf); }
        catch (e2) { html = new TextDecoder('utf-8').decode(buf); }
      }
      // 若未成功解码出中文（仍含 U+FFFD），回退 utf-8。
      if (html.indexOf('\uFFFD') >= 0) {
        var u = new TextDecoder('utf-8').decode(buf);
        if (u.indexOf('\uFFFD') < 0) html = u;
      }
      window.__doc = new DOMParser().parseFromString(html, 'text/html');
      window.__pageState = 'ok';
    })
    .catch(function(e) { window.__pageState = 'error:' + e; });
})()
'''.replaceFirst('__URL__', jsonEncode(path));

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
                Log.warning('CfPageLoader', 'resource error: ${err.description}');
              },
            ),
          );
    _timeout = Timer(const Duration(seconds: 45), () {
      if (!_done) _fail('页面加载超时，请稍后重试');
    });
    Log.info('CfPageLoader', 'open ${widget.apiHost}/');
    _controller.loadRequest(Uri.parse('${widget.apiHost}/'));
  }

  Future<void> _onPageFinished(String url) async {
    if (_done) return;
    Log.info('CfPageLoader', 'page finished: $url');
    final nav = _navCompleter;
    if (nav != null && !nav.isCompleted) nav.complete();

    // 只处理第一阶段（首页）；后续导航/抓取由对应方法负责。
    if (_phase != 0) return;
    _phase = 1;

    await Future.delayed(const Duration(milliseconds: 900));
    if (_done) return;

    // 等待首页的 Cloudflare 挑战通过。
    for (int i = 0; i < 12; i++) {
      final r = await _safeJs(_jsChallenge);
      if (r == 'ok') break;
      if (i == 6) {
        Log.info('CfPageLoader', 'home still challenged, reloading');
        await _controller.loadRequest(Uri.parse('${widget.apiHost}/'));
        await Future.delayed(const Duration(seconds: 2));
      }
      await Future.delayed(const Duration(milliseconds: 800));
      if (_done) return;
    }

    if (widget.navigateInsteadOfFetch) {
      await _navigateAndParse();
    } else {
      await _fetchAndParse();
    }
  }

  /// 直接导航到目标页（浏览器按页面 charset 解析链接），等待后再解析。
  Future<void> _navigateAndParse() async {
    Log.info('CfPageLoader', 'navigate target ${widget.path}');
    _navCompleter = Completer<void>();
    try {
      if (widget.navigateJs != null) {
        // 用 JS 构造 form 提交，让浏览器按页面 charset 编码查询串。
        await _controller.runJavaScript(widget.navigateJs!);
      } else {
        await _controller.loadRequest(
          Uri.parse('${widget.apiHost}${widget.path}'),
        );
      }
    } catch (e) {
      Log.warning('CfPageLoader', 'navigate failed: $e');
    }
    try {
      await _navCompleter!.future.timeout(const Duration(seconds: 20));
    } catch (_) {}

    // 目标页可能再次触发 CF 挑战，轮询等待；每次校验页面是否已就绪。
    for (int i = 0; i < 15; i++) {
      final r = await _safeJs(_jsChallenge);
      if (r == 'ok') {
        // 额外确认页面已有内容（非空白/错误页）。
        final ready = await _safeJs(
          '(document.body && document.body.innerText.length > 50) ? "yes" : "no"',
        );
        if (ready == 'yes') break;
      }
      if (i == 5 || i == 10) {
        Log.info('CfPageLoader', 'target not ready ($r), reloading');
        await _controller.loadRequest(
          Uri.parse('${widget.apiHost}${widget.path}'),
        );
        await Future.delayed(const Duration(seconds: 2));
      }
      await Future.delayed(const Duration(milliseconds: 800));
      if (_done) return;
    }

    try {
      final raw = await _controller.runJavaScriptReturningResult(
        widget.parserJs,
      );
      final json = _stripJsonString(raw.toString());
      final diag = await _safeJs(r'''
(function() {
  var t = document.body ? document.body.innerText : '';
  return JSON.stringify({
    href: location.href,
    title: document.title,
    uls: document.querySelectorAll('ul').length,
    ultsops: document.querySelectorAll('ul.ultops').length,
    tagLinks: document.querySelectorAll('a[href*="tags.php"]').length,
    grid: document.querySelectorAll('table.grid').length,
    snippet: t.replace(/\s+/g, ' ').slice(0, 200)
  });
})()
''');
      Log.info(
        'CfPageLoader',
        'nav diag ${widget.path} jsonLen=${json.length}: $diag',
      );
      _done = true;
      _timeout?.cancel();
      Log.info('CfPageLoader', 'parsed ${widget.path} (${json.length} chars)');
      widget.onSuccess(json);
    } catch (e, s) {
      Log.error('CfPageLoader', 'parse failed: $e', s);
      _fail('解析失败: $e');
    }
  }

  Future<void> _fetchAndParse() async {
    try {
      Log.info('CfPageLoader', 'fetch target ${widget.path}');
      await _controller.runJavaScript(_fetchJs('${widget.apiHost}${widget.path}'));

      String state = '';
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        state = await _safeJs('window.__pageState || ""');
        if (state == 'ok' || state.startsWith('http:') || state.startsWith('error:')) {
          break;
        }
      }

      if (state == 'ok') {
        final raw = await _controller.runJavaScriptReturningResult(
          widget.parserJs,
        );
        final json = _stripJsonString(raw.toString());
        if (json.length < 120) {
          final diag = await _safeJs(
            '(window.__doc && window.__doc.body) ? window.__doc.body.innerText.slice(0,300) : "(no doc)"',
          );
          Log.warning('CfPageLoader', 'empty result ${widget.path} diag=$diag');
        }
        _done = true;
        _timeout?.cancel();
        Log.info('CfPageLoader', 'parsed ${widget.path} (${json.length} chars)');
        widget.onSuccess(json);
      } else {
        _fail('获取页面失败 ($state)');
      }
    } catch (e, s) {
      Log.error('CfPageLoader', 'fetch/parse failed: $e', s);
      _fail('解析失败: $e');
    }
  }

  Future<String> _safeJs(String js) async {
    try {
      final r = await _controller.runJavaScriptReturningResult(js);
      return _stripJsonString(r.toString());
    } catch (e) {
      return '';
    }
  }

  String _stripJsonString(String s) {
    if (s.startsWith('"') && s.endsWith('"')) {
      try {
        return jsonDecode(s) as String;
      } catch (_) {
        return s;
      }
    }
    return s;
  }

  void _fail(String message) {
    if (_done) return;
    _done = true;
    _timeout?.cancel();
    Log.error('CfPageLoader', 'failed: $message');
    widget.onError(message);
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
