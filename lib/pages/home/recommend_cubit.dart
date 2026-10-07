import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/src/rust/api/wenku8.dart' as w8;
import 'package:wild/src/rust/wenku8/models.dart' as w8;
import 'package:wild/utils/log.dart';
import 'package:wild/utils/wenku8_parse.dart';

abstract class RecommendState {}

class RecommendInitial extends RecommendState {}

class RecommendLoading extends RecommendState {}

class RecommendLoaded extends RecommendState {
  final List<w8.HomeBlock> blocks;

  RecommendLoaded(this.blocks);
}

class RecommendError extends RecommendState {
  final String message;

  RecommendError(this.message);
}

/// 需要 WebView 绕过 Cloudflare 的状态（由 UI 层触发）。
class RecommendChallenge extends RecommendState {
  final String apiHost;

  RecommendChallenge(this.apiHost);
}

class RecommendCubit extends Cubit<RecommendState> {
  RecommendCubit() : super(RecommendInitial());

  String _apiHost = 'https://www.wenku8.net';

  Future<void> load() async {
    emit(RecommendLoading());
    try {
      final blocks = await w8.index();
      Log.info('RecommendCubit', 'rust index ok: ${blocks.length} blocks');
      emit(RecommendLoaded(blocks));
    } catch (e, s) {
      Log.error('RecommendCubit', 'rust index failed: $e', s);
      if (Wenku8Parse.needsWebViewFallback(e)) {
        try {
          final host = await w8.getApiHost();
          _apiHost = host.isEmpty ? 'https://www.wenku8.net' : host;
        } catch (_) {}
        emit(RecommendChallenge(_apiHost));
        return;
      }
      emit(RecommendError(e.toString()));
    }
  }

  String get apiHost => _apiHost;

  /// WebView 成功抓取后由 UI 层调用。
  void applyWebViewJson(String json) {
    Log.info(
      'RecommendCubit',
      'webview index raw len=${json.length} head=${json.length > 200 ? json.substring(0, 200) : json}',
    );
    try {
      final blocks = Wenku8Parse.homeBlocks(json);
      Log.info('RecommendCubit', 'webview index ok: ${blocks.length} blocks');
      if (blocks.isEmpty) {
        emit(RecommendError('未获取到首页内容'));
      } else {
        emit(RecommendLoaded(blocks));
      }
    } catch (e, s) {
      Log.error('RecommendCubit', 'parse webview json failed: $e', s);
      emit(RecommendError('解析首页数据失败: $e'));
    }
  }

  void setError(String message) {
    Log.error('RecommendCubit', 'webview error: $message');
    emit(RecommendError(message));
  }
}
