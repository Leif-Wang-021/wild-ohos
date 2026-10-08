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

  /// 任务队列（单一 WebView 会话只能串行执行）。
  final List<_FetchJob> _queue = [];
  bool _draining = false;

  /// 最近一次前台活动时间。后台任务需等待「静默期」后才执行，避免打断操作。
  DateTime _lastInteractiveAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// 后台任务执行前需要的静默时长。
  static const Duration _quietPeriod = Duration(seconds: 2);

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

  /// 交互请求数量：>0 表示用户正在前台等待（如打开详情、进入阅读）。
  int _interactiveCount = 0;

  /// 以「交互优先级」执行：期间后台预取会主动让路，避免抢占网络队列
  /// 导致前台操作卡顿。
  Future<T> runInteractive<T>(Future<T> Function() task) async {
    _interactiveCount++;
    try {
      return await task();
    } finally {
      _interactiveCount--;
    }
  }

  /// 串行执行一个抓取任务。
  ///
  /// 所有请求共用唯一 WebView 会话，故必须串行。为避免后台预取霸占队列
  /// 拖慢前台操作，前台任务（[interactive] = true）运行期间会登记为交互态，
  /// 后台任务（[interactive] = false）在此期间主动让路。
  /// 优先级队列执行：
  /// - 前台（[interactive]=true）请求**插队**到所有后台任务之前，保证用户
  ///   操作（打开详情、进入阅读）立刻得到响应；
  /// - 后台任务（预取）只有在「无前台等待 + 前台静默 2 秒」时才执行，
  ///   避免霸占唯一 WebView 会话拖慢前台。
  Future<T> _serial<T>(Future<T> Function() task, {bool interactive = true}) {
    final completer = Completer<T>();
    // 用闭包捕获 completer，避免泛型擦除。
    final job = _FetchJob(() async {
      try {
        completer.complete(await task());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    }, interactive);
    if (interactive) {
      _lastInteractiveAt = DateTime.now();
      // 插到第一个后台任务之前（保持前台之间的 FIFO）。
      final idx = _queue.indexWhere((j) => !j.interactive);
      if (idx < 0) {
        _queue.add(job);
      } else {
        _queue.insert(idx, job);
      }
    } else {
      _queue.add(job);
    }
    _drain();
    return completer.future;
  }

  void _drain() {
    if (_draining) return;
    _draining = true;
    unawaited(_drainLoop());
  }

  Future<void> _drainLoop() async {
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.first;
        if (!job.interactive) {
          // 前台有等待任务，或刚有前台活动，则先让路。
          final hasInteractiveWaiting = _queue.any((j) => j.interactive);
          final since = DateTime.now().difference(_lastInteractiveAt);
          if (hasInteractiveWaiting || _interactiveCount > 0 || since < _quietPeriod) {
            await Future.delayed(const Duration(milliseconds: 200));
            continue;
          }
        }
        _queue.removeAt(0);
        if (job.interactive) {
          _lastInteractiveAt = DateTime.now();
          _interactiveCount++;
        }
        try {
          await job.task();
        } finally {
          if (job.interactive) _interactiveCount--;
        }
      }
    } finally {
      _draining = false;
      // 期间可能又有新任务入队。
      if (_queue.isNotEmpty) _drain();
    }
  }

  String _absolute(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('/')) return '$_apiHost$pathOrUrl';
    return '$_apiHost/$pathOrUrl';
  }

  /// 抓取原始字节（图片等）。
  ///
  /// [background] 为 true 时作为后台任务：前台忙碌时让路，避免卡顿。
  Future<Uint8List?> fetchBytes(String url, {bool background = false}) {
    return _serial(() async {
      final res = await _fetch(_absolute(url));
      return res.bytes;
    }, interactive: !background);
  }

  /// 抓取站内路径的原始字节。
  Future<Uint8List?> fetchPathBytes(String path) {
    return _serial(() async {
      final res = await _fetch(_absolute(path));
      return res.bytes;
    });
  }

  /// 抓取结果：文本 + 状态（`ok` / `http:429` / `error:…` / `timeout`）。
  ///
  /// [background] 为 true 时作为后台任务：前台忙碌时让路，避免卡顿。
  Future<FetchResult> fetchParsedEx(
    String pathOrUrl,
    String parserJs, {
    bool background = false,
  }) {
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
    }, interactive: !background);
  }

  /// 抓取页面后，在 WebView 内执行 [parserJs] 解析并返回结果字符串。
  ///
  /// [parserJs] 为一个完整的 IIFE 表达式，接收变量 `html`（已按 GBK 解码的
  /// 页面源码），返回字符串。用于章节正文提取等需要 DOM 解析的场景。
  Future<String?> fetchParsed(String pathOrUrl, String parserJs) async {
    final res = await fetchParsedEx(pathOrUrl, parserJs);
    return res.text;
  }

  /// 导航到目标页后解析（浏览器按页面 charset 编码链接）。
  ///
  /// 用于标签名等含中文、需按 GBK 百分号编码的 URL：Dart/JS 均无 GBK 编码器，
  /// 只能借浏览器表单提交能力（[navigateJs] 在已过挑战的页面执行）。
  Future<FetchResult> navigateParsedEx(
    String path,
    String parserJs, {
    String? navigateJs,
  }) {
    return _serial(() async {
      await ensureReady();
      if (!_ready) return FetchResult(null, 'not_ready');
      final url = _absolute(path);
      try {
        _navCompleter = Completer<void>();
        if (navigateJs != null) {
          await controller.runJavaScript(navigateJs);
        } else {
          await controller.loadRequest(Uri.parse(url));
        }
        try {
          await _navCompleter!.future.timeout(const Duration(seconds: 20));
        } catch (_) {}

        // 目标页可能再次触发挑战，轮询等待就绪。
        for (int i = 0; i < 15; i++) {
          final r = await _safeJs(_jsChallenge);
          if (r == 'ok') {
            final ready = await _safeJs(
              '(document.body && document.body.innerText.length > 50) ? "yes" : "no"',
            );
            if (ready == 'yes') break;
          }
          if (i == 5 || i == 10) {
            await controller.loadRequest(Uri.parse(url));
            await Future.delayed(const Duration(seconds: 2));
          }
          await Future.delayed(const Duration(milliseconds: 800));
        }

        final raw = await controller.runJavaScriptReturningResult(parserJs);
        final json = _stripJsonString(raw.toString());
        return FetchResult(json.isEmpty ? null : json, 'ok');
      } catch (e) {
        Log.error('WebViewFetcher', 'navigateParsed $url error: $e');
        return FetchResult(null, 'error');
      }
    });
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

/// 队列中的一个抓取任务。任务本身负责完成对应的 completer。
class _FetchJob {
  final Future<void> Function() task;
  final bool interactive;

  _FetchJob(this.task, this.interactive);
}
