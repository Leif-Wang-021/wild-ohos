import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/services/webview_fetcher.dart';
import 'package:wild/src/rust/api/wenku8.dart' as wenku8;
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/utils/wenku8_parse.dart';
import 'package:wild/widgets/wenku8_js.dart';

enum AccountStatus { initial, loading, loaded, error }

class AccountState {
  final AccountStatus status;
  final UserDetail? userDetail;
  final String? errorMessage;

  const AccountState({
    this.status = AccountStatus.initial,
    this.userDetail,
    this.errorMessage,
  });

  AccountState copyWith({
    AccountStatus? status,
    UserDetail? userDetail,
    String? errorMessage,
  }) {
    return AccountState(
      status: status ?? this.status,
      userDetail: userDetail ?? this.userDetail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(const AccountState());

  Future<void> loadUserDetail() async {
    if (state.status == AccountStatus.loaded && state.userDetail != null) {
      return;
    }

    emit(state.copyWith(status: AccountStatus.loading));

    // 1) Rust 端（未受 Cloudflare 影响时可用）
    try {
      final userDetail = await wenku8.userDetail();
      Log.info('AccountCubit', 'rust userDetail ok');
      emit(
        state.copyWith(status: AccountStatus.loaded, userDetail: userDetail),
      );
      return;
    } catch (e, s) {
      Log.error('AccountCubit', 'rust userDetail failed: $e', s);
      if (!Wenku8Parse.needsWebViewFallback(e)) {
        emit(
          state.copyWith(status: AccountStatus.error, errorMessage: e.toString()),
        );
        return;
      }
    }

    // 2) WebView 兜底（绕过 Cloudflare）
    try {
      final host = await wenku8.getApiHost();
      WebViewFetcher.instance.setApiHost(
        host.isEmpty ? 'https://www.wenku8.net' : host,
      );
      final json = await WebViewFetcher.instance.fetchParsed(
        '/userdetail.php?charset=gbk',
        Wenku8Js.userDetail,
      );
      if (json == null || json.isEmpty) {
        emit(
          state.copyWith(
            status: AccountStatus.error,
            errorMessage: '无法获取账户信息，请检查网络',
          ),
        );
        return;
      }
      final detail = Wenku8Parse.userDetail(json);
      Log.info('AccountCubit', 'webview userDetail ok: ${detail.username}');
      emit(state.copyWith(status: AccountStatus.loaded, userDetail: detail));
    } catch (e, s) {
      Log.error('AccountCubit', 'webview userDetail failed: $e', s);
      emit(
        state.copyWith(
          status: AccountStatus.error,
          errorMessage: '无法获取账户信息: $e',
        ),
      );
    }
  }
}
