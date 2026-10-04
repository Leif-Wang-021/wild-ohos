import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wild/src/rust/api/database.dart' show loadProperty, saveProperty;
import 'package:wild/src/rust/api/wenku8.dart';
import 'package:wild/utils/app_platform.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }
enum CheckcodeStatus { initial, loading, success, error }

/// Persisted flag used on OHOS where login happens inside a WebView and the
/// Rust cookie store therefore cannot see the session cookies.
const String kOhosWebViewLoggedInKey = 'ohos_webview_logged_in';

class AuthState extends Equatable {
  final AuthStatus status;
  final String? username;
  final String? errorMessage;
  final Uint8List? checkcode;
  final CheckcodeStatus checkcodeStatus;

  const AuthState({
    this.status = AuthStatus.initial,
    this.username,
    this.errorMessage,
    this.checkcode,
    this.checkcodeStatus = CheckcodeStatus.initial,
  });

  @override
  List<Object?> get props => [status, username, errorMessage, checkcode, checkcodeStatus];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  Future<void> login(String username, String password, String checkcode) async {
    try {
      emit(AuthState(status: AuthStatus.loading));

      await wenku8Login(
        username: username,
        password: password,
        checkcode: checkcode,
      );

      emit(AuthState(status: AuthStatus.authenticated, username: username));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  void setLoginLoading() {
    emit(AuthState(status: AuthStatus.loading));
  }

  void setError(String message) {
    emit(AuthState(status: AuthStatus.error, errorMessage: message));
  }

  void logout() {
    unawaited(_clearOhosFlag());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _clearOhosFlag() async {
    try {
      await saveProperty(key: kOhosWebViewLoggedInKey, value: '0');
    } catch (_) {}
  }

  Future<void> init() async {
    bool logged = false;
    try {
      logged = await preLoginState();
    } catch (_) {
      logged = false;
    }
    if (!logged && AppPlatform.isOHOS) {
      try {
        logged = (await loadProperty(key: kOhosWebViewLoggedInKey)) == '1';
      } catch (_) {
        logged = false;
      }
    }
    if (logged) {
      emit(AuthState(status: AuthStatus.authenticated));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future loadCheckcode() async {
    emit(AuthState(
      status: state.status,
      checkcode: Uint8List(0),
      checkcodeStatus: CheckcodeStatus.loading,
    ));
    try {
      final checkcode = await downloadCheckcode();
      emit(AuthState(
        status: state.status,
        checkcode: checkcode,
        checkcodeStatus: CheckcodeStatus.success,
      ));
      print("checkcode loaded : ${checkcode}");
    } catch (e, s) {
      print("2");
      print("${e}\n${s}");
      emit(
        AuthState(
          status: state.status,
          checkcode: null,
          checkcodeStatus: CheckcodeStatus.error,
          errorMessage: "无法成功获取验证码，请检查网络",
        ),
      );
    }
  }

  /// Marks the captcha as loading (used by the WebView based flow).
  void startCheckcodeLoading() {
    emit(AuthState(
      status: state.status,
      checkcode: Uint8List(0),
      checkcodeStatus: CheckcodeStatus.loading,
    ));
  }

  /// Stores captcha bytes fetched through a Cloudflare-cleared WebView session.
  void setCheckcode(Uint8List bytes) {
    emit(AuthState(
      status: state.status,
      checkcode: bytes,
      checkcodeStatus: CheckcodeStatus.success,
    ));
  }

  /// Shows the captcha error state (used by the WebView based flow).
  void setCheckcodeError() {
    emit(
      AuthState(
        status: state.status,
        checkcode: null,
        checkcodeStatus: CheckcodeStatus.error,
        errorMessage: "无法成功获取验证码，请检查网络",
      ),
    );
  }

  /// Handles the login result page produced by the WebView login submission.
  ///
  /// Returns true when the login succeeded.
  Future<bool> handleWebViewLoginBody(String username, String body) async {
    final success = body.contains('登录成功') ||
        body.contains('登錄成功') ||
        body.contains('登陆成功');
    if (success) {
      try {
        await saveProperty(key: kOhosWebViewLoggedInKey, value: '1');
      } catch (_) {}
      emit(AuthState(status: AuthStatus.authenticated, username: username));
      return true;
    }
    emit(AuthState(status: AuthStatus.error, errorMessage: body));
    return false;
  }
}
