import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/services/wenku8_repo.dart';
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/utils/wenku8_parse.dart';

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

    // 统一走 [Wenku8Repo]（唯一常驻 WebView 会话）。
    try {
      final json = await Wenku8Repo.instance.userDetail();
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
      Log.info('AccountCubit', 'userDetail ok: ${detail.username}');
      emit(state.copyWith(status: AccountStatus.loaded, userDetail: detail));
    } catch (e, s) {
      Log.error('AccountCubit', 'userDetail failed: $e', s);
      emit(
        state.copyWith(
          status: AccountStatus.error,
          errorMessage: '无法获取账户信息: $e',
        ),
      );
    }
  }
}
