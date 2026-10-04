import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView based login/captcha loader that bypasses Cloudflare on OHOS.
///
/// The Rust HTTP client (reqwest) cannot solve Cloudflare's JS challenge, so
/// `checkcode.php` and `login.php` return HTTP 403. This widget keeps a hidden
/// WebView on `login.php` (which passes the CF challenge) and performs both the
/// captcha fetch and the login submission inside that cleared session.
class CfLoginLoader extends StatefulWidget {
  final String apiHost;

  const CfLoginLoader({super.key, required this.apiHost});

  @override
  CfLoginLoaderState createState() => CfLoginLoaderState();
}

class CfLoginLoaderState extends State<CfLoginLoader> {
  late final WebViewController _controller;

  bool _ready = false;
  Completer<bool>? _readyCompleter;
  Completer<void>? _navCompleter;

  /// The page is considered ready once the login form is present and the
  /// Cloudflare challenge has been passed. The captcha input may legitimately
  /// be absent (the site currently serves a login form without a captcha), so
  /// readiness must not depend on it.
  static const String _jsReady = r'''
(function() {
  var text = document.body ? document.body.innerText : '';
  if ((text.indexOf('Just a moment') >= 0) || (text.indexOf('__cf_chl_') >= 0)) return 'no';
  if (document.getElementById('challenge-form') !== null) return 'no';
  var hasForm = document.querySelector('form') !== null ||
    document.querySelector('input[name="username"]') !== null;
  return hasForm ? 'yes' : 'no';
})()
''';

  /// Diagnostic snapshot used to understand why the page is not ready yet.
  static const String _jsDiag = r'''
(function() {
  var html = document.documentElement.outerHTML || '';
  var text = document.body ? document.body.innerText : '';
  function has(s) { return html.indexOf(s) >= 0; }
  var form = document.querySelector('form');
  return JSON.stringify({
    href: location.href,
    title: document.title,
    cf: (text.indexOf('Just a moment') >= 0) || (text.indexOf('__cf_chl_') >= 0),
    hasCheckcode: has('checkcode'),
    hasCheckcodePhp: has('checkcode.php'),
    hasCaptcha: has('captcha'),
    hasTurnstile: has('turnstile'),
    hasClosed: has('本站正式关闭'),
    form: form ? form.outerHTML.slice(0, 900) : '(none)',
    raw: html.slice(0, 1400)
  });
})()
''';

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) {
                _log('page finished: $url');
                final c = _navCompleter;
                if (c != null && !c.isCompleted) c.complete();
              },
              onWebResourceError: (err) {
                _log('resource error: ${err.description}');
              },
            ),
          );
  }

  void _log(String message) => debugPrint('[CfLogin] $message');

  Future<void> _load(String url) async {
    _navCompleter = Completer<void>();
    try {
      await _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      _log('loadRequest failed: $e');
    }
    try {
      await _navCompleter!.future.timeout(const Duration(seconds: 20));
    } catch (_) {
      _log('navigation timeout for $url');
    }
  }

  /// Ensures the login page is fully loaded and the Cloudflare challenge passed.
  Future<bool> ensureReady() async {
    if (_ready) return true;

    final existing = _readyCompleter;
    if (existing != null && !existing.isCompleted) return existing.future;

    final completer = Completer<bool>();
    _readyCompleter = completer;

    bool done = false;
    for (int attempt = 0; attempt < 3 && !done; attempt++) {
      // Visit the homepage first so the site establishes its session cookies
      // before requesting login.php (mirrors the original Rust init_session).
      _log('ensureReady attempt ${attempt + 1}, loading homepage');
      await _load('${widget.apiHost}/');
      try {
        final homeDiag = await _controller.runJavaScriptReturningResult(_jsDiag);
        _log('home diag: ${_stripJsonString(homeDiag.toString())}');
      } catch (e) {
        _log('home diag failed: $e');
      }

      _log('loading login.php');
      await _load('${widget.apiHost}/login.php');
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 700));
        try {
          final ready = await _controller.runJavaScriptReturningResult(_jsReady);
          if (ready.toString().contains('yes')) {
            _ready = true;
            done = true;
            break;
          }
          if (i == 0 || i == 5) {
            final diag = await _controller.runJavaScriptReturningResult(_jsDiag);
            _log('not ready #$i: ${_stripJsonString(diag.toString())}');
          }
        } catch (e) {
          _log('ready poll failed: $e');
        }
      }
    }
    _log('ensureReady result=$_ready');

    completer.complete(_ready);
    _readyCompleter = null;
    return _ready;
  }

  /// Invalidates readiness so the next call reloads the page.
  Future<void> reset() async {
    _ready = false;
  }

  /// Fetches the captcha image bytes from the cleared session.
  ///
  /// Uses a polled global because `runJavaScriptReturningResult` does not
  /// await Promises. Returns null when the image could not be retrieved.
  Future<Uint8List?> fetchCaptcha() async {
    if (!await ensureReady()) return null;
    try {
      await _controller.runJavaScript(r'''
(function() {
  window.__captchaState = 'loading';
  window.__captchaData = '';
  try {
    var img = document.querySelector('img[src*="checkcode"]');
    var base = img ? img.src : (location.origin + '/checkcode.php');
    var url = base + (base.indexOf('?') >= 0 ? '&' : '?') + 'random=' + Math.random();
    fetch(url, {credentials: 'include', cache: 'no-store'}).then(function(r) {
      if (!r.ok) { window.__captchaState = 'error:' + r.status; return null; }
      return r.arrayBuffer();
    }).then(function(buf) {
      if (!buf) return;
      var bytes = new Uint8Array(buf);
      var s = '';
      for (var i = 0; i < bytes.length; i++) { s += String.fromCharCode(bytes[i]); }
      window.__captchaData = btoa(s);
      window.__captchaState = 'ok';
    }).catch(function(e) {
      window.__captchaState = 'error:' + e;
    });
  } catch (e) {
    window.__captchaState = 'error:' + e;
  }
})()
''');

      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        final stateRaw = await _controller.runJavaScriptReturningResult(
          'window.__captchaState || ""',
        );
        final state = _stripJsonString(stateRaw.toString());
        if (state == 'ok') {
          final dataRaw = await _controller.runJavaScriptReturningResult(
            'window.__captchaData || ""',
          );
          final data = _stripJsonString(dataRaw.toString());
          if (data.isEmpty) return null;
          return base64Decode(data);
        }
        if (state.startsWith('error:')) {
          _log('captcha fetch error: $state');
          await reset();
          return null;
        }
      }
      _log('captcha fetch timeout');
      await reset();
      return null;
    } catch (e) {
      _log('captcha decode failed: $e');
      await reset();
      return null;
    }
  }

  /// Submits the login form inside the WebView session.
  ///
  /// Returns the resulting page body text so the caller can map it to a user
  /// facing message. Returns null when the submission itself failed.
  Future<String?> login(
    String username,
    String password,
    String checkcode, {
    Duration wait = const Duration(seconds: 15),
  }) async {
    if (!await ensureReady()) return null;
    try {
      final action = jsonEncode('${widget.apiHost}/login.php');
      final u = jsonEncode(username);
      final p = jsonEncode(password);
      final c = jsonEncode(checkcode);

      _navCompleter = Completer<void>();
      await _controller.runJavaScript('''
(function() {
  var f = document.createElement('form');
  f.method = 'POST';
  f.action = $action;
  function add(name, value) {
    var i = document.createElement('input');
    i.type = 'hidden'; i.name = name; i.value = value;
    f.appendChild(i);
  }
  add('username', $u);
  add('password', $p);
  add('checkcode', $c);
  add('usecookie', '315360000');
  add('action', 'login');
  document.body.appendChild(f);
  f.submit();
})()
''');
      try {
        await _navCompleter!.future.timeout(wait);
      } catch (_) {
        _log('login navigation timeout');
      }
      await Future.delayed(const Duration(seconds: 1));
      final raw = await _controller.runJavaScriptReturningResult(
        'document.body ? document.body.innerText : ""',
      );
      return _stripJsonString(raw.toString());
    } catch (e) {
      _log('login submit failed: $e');
      return null;
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

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
