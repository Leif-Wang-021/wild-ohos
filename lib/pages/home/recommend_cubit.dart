import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/services/wenku8_repo.dart';
import 'package:wild/src/rust/wenku8/models.dart' as w8;
import 'package:wild/utils/log.dart';

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

/// 首页推荐。
///
/// 所有站点请求统一走 [Wenku8Repo]（唯一常驻 WebView 会话，内置缓存/去重/
/// 冷却/重试）。不再先撞 Rust，也不再自建 WebView 兜底。
class RecommendCubit extends Cubit<RecommendState> {
  RecommendCubit() : super(RecommendInitial());

  Future<void> load() async {
    final hadBlocks = state is RecommendLoaded;
    if (!hadBlocks) emit(RecommendLoading());
    try {
      final blocks = await Wenku8Repo.instance.index();
      if (blocks.isEmpty) {
        if (hadBlocks) return;
        emit(RecommendError('未获取到首页内容，请下拉刷新重试'));
        return;
      }
      Log.info('RecommendCubit', 'index ok: ${blocks.length} blocks');
      emit(RecommendLoaded(blocks));
    } catch (e, s) {
      Log.error('RecommendCubit', 'index failed: $e', s);
      if (hadBlocks) return;
      emit(RecommendError('加载失败，请下拉刷新重试'));
    }
  }
}
