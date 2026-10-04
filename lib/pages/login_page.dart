import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wild/pages/auth_cubit.dart';
import 'package:wild/utils/app_platform.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/widgets/cf_login_loader.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _checkcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _loginLoaderKey = GlobalKey<CfLoginLoaderState>();

  static const String _defaultApiHost = 'https://www.wenku8.net';

  /// On OHOS the website's Cloudflare protection blocks the Rust HTTP client,
  /// so captcha fetching and login run inside a WebView session instead.
  bool get _useWebViewFlow => AppPlatform.isOHOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCheckcode());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _checkcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckcode() async {
    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();
    if (!_useWebViewFlow) {
      authCubit.loadCheckcode();
      return;
    }

    Log.info('LoginPage', 'load checkcode via WebView');
    authCubit.startCheckcodeLoading();
    final loader = _loginLoaderKey.currentState;
    if (loader == null) {
      Log.error('LoginPage', 'WebView loader not ready');
      authCubit.setCheckcodeError();
      return;
    }
    final bytes = await loader.fetchCaptcha();
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      Log.warning('LoginPage', 'checkcode fetch returned empty');
      context.read<AuthCubit>().setCheckcodeError();
    } else {
      Log.info('LoginPage', 'checkcode loaded (${bytes.length} bytes)');
      context.read<AuthCubit>().setCheckcode(bytes);
    }
  }

  Future<void> _onLoginPressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final authCubit = context.read<AuthCubit>();
    final username = _usernameController.text;
    final password = _passwordController.text;
    final checkcode = _checkcodeController.text;

    if (!_useWebViewFlow) {
      authCubit.login(username, password, checkcode);
      return;
    }

    Log.info('LoginPage', 'submit login for user=$username');
    authCubit.setLoginLoading();
    final loader = _loginLoaderKey.currentState;
    if (loader == null) {
      Log.error('LoginPage', 'WebView loader not ready');
      authCubit.setError('登录失败，请检查网络连接');
      return;
    }
    final body = await loader.login(username, password, checkcode);
    if (!mounted) return;
    if (body == null) {
      Log.error('LoginPage', 'login returned no body');
      context.read<AuthCubit>().setError('登录失败，请检查网络连接');
      return;
    }
    await context.read<AuthCubit>().handleWebViewLoginBody(username, body);
  }

  Future<void> _onRegisterPressed() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('注册提示'),
            content: const Text('注册需要在网页端进行，是否跳转到注册页面？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    if (result == true) {
      final uri = Uri.parse('https://www.wenku8.net/register.php');
      if (!await launchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法打开注册页面')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The Scaffold (login form) is opaque and sits on top of the WebView.
        _buildScaffold(context),
        // The WebView must stay fullscreen (like the bookshelf loader) so that
        // Cloudflare's JS challenge is actually executed on OHOS.
        if (_useWebViewFlow)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.01,
                child: CfLoginLoader(
                  key: _loginLoaderKey,
                  apiHost: _defaultApiHost,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录轻小说文库')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            var message = '登录失败，请检查网络连接';
            var err = state.errorMessage ?? "";
            if (err.contains("用户不存在") || err.contains("用戶不存在")) {
              message = "用户不存在";
            } else if (err.contains("密码错误") || err.contains("密碼錯誤")) {
              message = "密码错误";
            } else if (err.contains("校验码错误") || err.contains("校驗碼錯誤")) {
              message = "验证码错误";
            } else if (err.contains("用户登录") || err.contains("用戶登錄")) {
              message = "用户登录";
            } else if (err.contains("验证码过期") || err.contains("驗證碼過期")) {
              message = "验证码过期";
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
            // A captcha is single-use; refresh it after a failed attempt.
            if (_useWebViewFlow) {
              _loadCheckcode();
            }
          } else if (state.status == AuthStatus.authenticated) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        builder: (context, state) {
          if (state.status == AuthStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50.0),
                        child: Image.asset(
                          'lib/assets/icon.png',
                          width: 96,
                          height: 96,
                        ),
                      ),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return '请输入用户名';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: '密码',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return '请输入密码';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          switch (state.checkcodeStatus) {
                            case CheckcodeStatus.loading:
                              return const SizedBox(
                                width: 200,
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            case CheckcodeStatus.success:
                              if (state.checkcode == null ||
                                  state.checkcode!.isEmpty) {
                                return _buildRetryButton(context);
                              }
                              return GestureDetector(
                                onTap: _loadCheckcode,
                                child: Image.memory(
                                  state.checkcode!,
                                  width: 200,
                                  height: 50,
                                  fit: BoxFit.contain,
                                ),
                              );
                            case CheckcodeStatus.error:
                            case CheckcodeStatus.initial:
                              return _buildRetryButton(context);
                          }
                        },
                      ),
                      Container(height: 20),
                      TextFormField(
                        controller: _checkcodeController,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return '请输入验证码';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: _onRegisterPressed,
                              child: const Text('注册'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed:
                                  state.status == AuthStatus.loading
                                      ? null
                                      : _onLoginPressed,
                              child:
                                  state.status == AuthStatus.loading
                                      ? const CircularProgressIndicator()
                                      : const Text('登录'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return InkWell(
      onTap: _loadCheckcode,
      child: Container(
        width: 200,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}
