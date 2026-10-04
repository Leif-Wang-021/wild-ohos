import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:webview_flutter/webview_flutter.dart';

import '../utils/log.dart';

/// 全局 WebView 抓取服务。
///
/// Rust 端使用 reqwest，无法完成 Cloudflare 的 JS 挑战，因此所有对
/// `www.wenku8.net` 的请求（章节内容、图片、详情页等）都会返回 403。
///
/// 本服务在应用根节点常驻一个隐藏 WebView：先访问首页完成 Cloudflare 挑战，
/// 之后即可在同一会话中通过同源 `fetch` 取回任意页面/资源。所有需要绕过
/// Cloudflare 的模块（阅读、下载、图片缓存）都通过这里访问网络。
class WebViewFetcher {
  WebViewFetcher._();

  static final WebViewFetcher instance = WebViewFetcher._();

  static const String _defaultHost = 'https://www.wenku8.net';

  WebViewController? _controller;
  String _apiHost = _defaultHost;
  bool _ready = false;
  Completer<void>? _navCompleter;

  /// 串行锁：所有抓取依次执行，避免并发导航互相干扰。
  Future<void> _lock = Future<void>.value();

  bool get isAttached => _controller != null;
  bool get isReady => _ready;

  void setApiHost(String host) {
    if (host.isNotEmpty) _apiHost = host;
  }

  String get apiHost => _apiHost;

  /// 由根组件在首次构建时调用，绑定唯一的 WebView 控制器。
  void attach() {
    if (_controller != null) return;
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) {
                final nav = _navCompleter;
                if (nav != null && !nav.isCompleted) nav.complete();
              },
              onWebResourceError: (err) {
                Log.warning('WebViewFetcher', 'resource error: ${err.description}');
              },
            ),
          );
    Log.info('WebViewFetcher', 'attached');
  }

  WebViewController get controller {
    final c = _controller;
    if (c == null) {
      throw StateError('WebViewFetcher.attach() 尚未被调用');
    }
    return c;
  }

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

  /// 抓取字节（图片）的脚本：返回 base64。
  String _fetchBytesJs(String url) => r'''
(function() {
  window.__fetcherState = 'loading';
  window.__fetcherData = '';
  var url = __URL__;
  fetch(url, { credentials: 'include', cache: 'no-store' })
    .then(function(r) {
      if (!r.ok) { window.__fetcherState = 'http:' + r.status; return null; }
      return r.arrayBuffer();
    })
    .then(function(buf) {
      if (!buf) return;
      var bytes = new Uint8Array(buf);
      var s = '';
      var CHUNK = 0x8000;
      for (var i = 0; i < bytes.length; i += CHUNK) {
        s += String.fromCharCode.apply(null, bytes.subarray(i, i + CHUNK));
      }
      window.__fetcherData = btoa(s);
      window.__fetcherState = 'ok';
    })
    .catch(function(e) { window.__fetcherState = 'error:' + e; });
})()
'''.replaceFirst('__URL__', jsonEncode(url));

  /// 抓取文本的脚本：用 TextDecoder('gbk') 解码（wenku8 正文为 GBK）。
  String _fetchTextJs(String url) => r'''
(function() {
  window.__fetcherState = 'loading';
  window.__fetcherText = '';
  var url = __URL__;
  fetch(url, { credentials: 'include', cache: 'no-store' })
    .then(function(r) {
      if (!r.ok) { window.__fetcherState = 'http:' + r.status; return null; }
      return r.arrayBuffer();
    })
    .then(function(buf) {
      if (!buf) return;
      var html;
      try { html = new TextDecoder('gbk').decode(buf); }
      catch (e) {
        try { html = new TextDecoder('gb18030').decode(buf); }
        catch (e2) { html = new TextDecoder('utf-8').decode(buf); }
      }
      if (html.indexOf('\uFFFD') >= 0) {
        var u = new TextDecoder('utf-8').decode(buf);
        if (u.indexOf('\uFFFD') < 0) html = u;
      }
      window.__fetcherText = html;
      window.__fetcherState = 'ok';
    })
    .catch(function(e) { window.__fetcherState = 'error:' + e; });
})()
'''.replaceFirst('__URL__', jsonEncode(url));

  Future<String> _safeJs(String js) async {
    try {
      final r = await controller.runJavaScriptReturningResult(js);
      return _stripJsonString(r.toString());
    } catch (_) {
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

  /// 确保首页已通过 Cloudflare 挑战。
  Future<void> ensureReady() async {
    if (_ready) return;
    final c = controller;

    for (int attempt = 0; attempt < 4 && !_ready; attempt++) {
      _navCompleter = Completer<void>();
      try {
        await c.loadRequest(Uri.parse('$_apiHost/'));
      } catch (e) {
        Log.warning('WebViewFetcher', 'load home failed: $e');
      }
      try {
        await _navCompleter!.future.timeout(const Duration(seconds: 20));
      } catch (_) {}

      for (int i = 0; i < 12; i++) {
        await Future.delayed(const Duration(milliseconds: 700));
        final r = await _safeJs(_jsChallenge);
        if (r == 'ok') {
          _ready = true;
          break;
        }
      }
    }
    Log.info('WebViewFetcher', 'ready=$_ready');
  }

  /// 串行执行一个抓取任务。
  Future<T> _serial<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _lock = _lock.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  String _absolute(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('/')) return '$_apiHost$pathOrUrl';
    return '$_apiHost/$pathOrUrl';
  }

  /// 抓取原始字节（图片等）。
  Future<Uint8List?> fetchBytes(String url) {
    return _serial(() async {
      final res = await _fetch(_absolute(url));
      return res.bytes;
    });
  }

  /// 抓取站内路径的原始字节。
  Future<Uint8List?> fetchPathBytes(String path) {
    return _serial(() async {
      final res = await _fetch(_absolute(path));
      return res.bytes;
    });
  }

  /// 抓取结果：文本 + 状态（`ok` / `http:429` / `error:…` / `timeout`）。
  Future<FetchResult> fetchParsedEx(String pathOrUrl, String parserJs) {
    return _serial(() async {
      await ensureReady();
      if (!_ready) return FetchResult(null, 'not_ready');
      final url = _absolute(pathOrUrl);
      try {
        await controller.runJavaScript(_fetchParseJs(url, parserJs));
        final state = await _waitState();
        if (state != 'ok') {
          Log.warning('WebViewFetcher', 'fetchParsed $url failed: $state');
          // 仅在会话类错误（403 等）时重置，429 仅表示限流，会话仍然有效。
          if (state.startsWith('http:') && !state.startsWith('http:429')) {
            _ready = false;
          }
          return FetchResult(null, state);
        }
        final text = await _safeJs('window.__fetcherText || ""');
        return FetchResult(text.isEmpty ? null : text, 'ok');
      } catch (e) {
        Log.error('WebViewFetcher', 'fetchParsed $url error: $e');
        return FetchResult(null, 'error');
      }
    });
  }

  /// 抓取页面后，在 WebView 内执行 [parserJs] 解析并返回结果字符串。
  ///
  /// [parserJs] 为一个完整的 IIFE 表达式，接收变量 `html`（已按 GBK 解码的
  /// 页面源码），返回字符串。用于章节正文提取等需要 DOM 解析的场景。
  Future<String?> fetchParsed(String pathOrUrl, String parserJs) async {
    final res = await fetchParsedEx(pathOrUrl, parserJs);
    return res.text;
  }

  String _fetchParseJs(String url, String parserJs) => r'''
(function() {
  window.__fetcherState = 'loading';
  window.__fetcherText = '';
  var url = __URL__;
  fetch(url, { credentials: 'include', cache: 'no-store' })
    .then(function(r) {
      if (!r.ok) { window.__fetcherState = 'http:' + r.status; return null; }
      return r.arrayBuffer();
    })
    .then(function(buf) {
      if (!buf) return;
      var html;
      try { html = new TextDecoder('gbk').decode(buf); }
      catch (e) {
        try { html = new TextDecoder('gb18030').decode(buf); }
        catch (e2) { html = new TextDecoder('utf-8').decode(buf); }
      }
      window.__fetcherText = __PARSER__;
      window.__fetcherState = 'ok';
    })
    .catch(function(e) { window.__fetcherState = 'error:' + e; });
})()
'''
      .replaceFirst('__URL__', jsonEncode(url))
      .replaceFirst('__PARSER__', parserJs);

  /// 抓取页面文本（JS 侧按 GBK 解码）。
  Future<String?> fetchText(String pathOrUrl) {
    return _serial(() async {
      await ensureReady();
      if (!_ready) return null;
      final url = _absolute(pathOrUrl);
      try {
        await controller.runJavaScript(_fetchTextJs(url));
        final state = await _waitState();
        if (state != 'ok') {
          Log.warning('WebViewFetcher', 'fetchText $url failed: $state');
          if (state.startsWith('http:')) _ready = false;
          return null;
        }
        final text = await _safeJs('window.__fetcherText || ""');
        return text.isEmpty ? null : text;
      } catch (e) {
        Log.error('WebViewFetcher', 'fetchText $url error: $e');
        return null;
      }
    });
  }

  Future<_FetchResult> _fetch(String url) async {
    await ensureReady();
    if (!_ready) return _FetchResult(null, 'not_ready');
    try {
      await controller.runJavaScript(_fetchBytesJs(url));
      final state = await _waitState();
      if (state != 'ok') {
        Log.warning('WebViewFetcher', 'fetch $url failed: $state');
        if (state.startsWith('http:')) _ready = false;
        return _FetchResult(null, state);
      }
      final data = await _safeJs('window.__fetcherData || ""');
      if (data.isEmpty) return _FetchResult(null, 'empty');
      return _FetchResult(base64Decode(data), 'ok');
    } catch (e) {
      Log.error('WebViewFetcher', 'fetch $url error: $e');
      return _FetchResult(null, 'error');
    }
  }

  /// 等待 JS 抓取状态变为终态。
  Future<String> _waitState() async {
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      final state = await _safeJs('window.__fetcherState || ""');
      if (state == 'ok' ||
          state.startsWith('http:') ||
          state.startsWith('error:')) {
        return state;
      }
    }
    return 'timeout';
  }
}

class _FetchResult {
  final Uint8List? bytes;
  final String state;

  _FetchResult(this.bytes, this.state);
}

/// 公开的抓取结果。
class FetchResult {
  /// 抓取到的文本（失败时为 null）。
  final String? text;

  /// 状态：`ok` / `http:429` / `error:…` / `timeout` / `not_ready`。
  final String state;

  const FetchResult(this.text, this.state);

  bool get ok => state == 'ok';

  /// 是否被限流（HTTP 429）。
  bool get isRateLimited => state == 'http:429';
}
