import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wild/services/local_cache.dart';
import 'package:wild/src/rust/api/wenku8.dart' as w8;
import 'package:wild/utils/log.dart';
import 'package:wild/utils/shelf_codec.dart';

abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<w8.ReadingHistory> histories;

  HistoryLoaded(this.histories);
}

class HistoryError extends HistoryState {
  final String message;

  HistoryError(this.message);
}

class HistoryCubit extends Cubit<HistoryState> {
  static const String _cacheKey = 'reading_history';

  HistoryCubit() : super(HistoryInitial());

  /// 本地优先 + 后台刷新：先显示缓存，再读本地库（历史记录本身即本地数据）。
  Future<void> load() async {
    final hasData = state is HistoryLoaded;

    if (!hasData) {
      final cached = await _restoreFromCache();
      if (cached != null && cached.isNotEmpty) {
        emit(HistoryLoaded(cached));
      } else {
        emit(HistoryLoading());
      }
    } else {
      emit(HistoryLoading());
    }

    try {
      final histories = await w8.listReadingHistory(offset: 0, limit: 100);
      emit(HistoryLoaded(histories));
      unawaited(_persist(histories));
    } catch (e) {
      Log.warning('HistoryCubit', 'load failed: $e');
      // 已有本地数据时保持展示，不退回错误态。
      if (state is! HistoryLoaded) {
        emit(HistoryError(e.toString()));
      }
    }
  }

  Future<List<w8.ReadingHistory>?> _restoreFromCache() async {
    try {
      final raw = await LocalCache.instance.read(_cacheKey);
      if (raw is! List) return null;
      return raw.map(ShelfCodec.historyFromJson).toList();
    } catch (e) {
      Log.warning('HistoryCubit', 'restore cache failed: $e');
      return null;
    }
  }

  Future<void> _persist(List<w8.ReadingHistory> histories) => LocalCache.instance
      .write(_cacheKey, histories.map(ShelfCodec.historyToJson).toList());

  Future<void> deleteHistory(String novelId) async {
    if (state is! HistoryLoaded) return;
    
    try {
      await w8.deleteHistoryByNovelId(novelId: novelId);
      final currentState = state as HistoryLoaded;
      final updatedHistories = currentState.histories.where((h) => h.novelId != novelId).toList();
      emit(HistoryLoaded(updatedHistories));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
} 