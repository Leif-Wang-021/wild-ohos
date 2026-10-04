import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wild/services/local_cache.dart';
import 'package:wild/services/shelf_prefetch.dart';
import 'package:wild/src/rust/api/wenku8.dart';
import 'package:wild/src/rust/wenku8/models.dart';
import 'package:wild/utils/log.dart';
import 'package:wild/utils/shelf_codec.dart';

enum BookshelfStatus { initial, loading, success, error, cloudflareChallenge }

class BookshelfState {
  final String tip;
  final BookshelfStatus status;
  final List<Bookcase> bookcases;
  final String? currentCaseId;
  final Map<String, List<BookcaseItem>> bookcaseContents;
  final String? errorMessage;
  final Set<String> selectedBids; // 选中的书籍 bid 集合
  final bool isSelecting; // 是否处于多选模式

  BookshelfState({
    required this.tip,
    required this.status,
    required this.bookcases,
    this.currentCaseId,
    required this.bookcaseContents,
    this.errorMessage,
    this.selectedBids = const {},
    this.isSelecting = false,
  });

  BookshelfState copyWith({
    String? tip,
    BookshelfStatus? status,
    List<Bookcase>? bookcases,
    String? currentCaseId,
    Map<String, List<BookcaseItem>>? bookcaseContents,
    String? errorMessage,
    Set<String>? selectedBids,
    bool? isSelecting,
  }) {
    return BookshelfState(
      tip: tip ?? this.tip,
      status: status ?? this.status,
      bookcases: bookcases ?? this.bookcases,
      currentCaseId: currentCaseId ?? this.currentCaseId,
      bookcaseContents: bookcaseContents ?? this.bookcaseContents,
      errorMessage: errorMessage,
      selectedBids: selectedBids ?? this.selectedBids,
      isSelecting: isSelecting ?? this.isSelecting,
    );
  }

  List<BookcaseItem>? getCurrentBooks() {
    if (currentCaseId == null) return null;
    return bookcaseContents[currentCaseId];
  }

  bool isBookInBookshelf(String aid) {
    for (final books in bookcaseContents.values) {
      if (books.any((book) => book.aid == aid)) {
        return true;
      }
    }
    return false;
  }

  String? getBookBid(String aid) {
    for (final books in bookcaseContents.values) {
      final book = books.firstWhere(
        (book) => book.aid == aid,
        orElse:
            () => BookcaseItem(
              aid: '',
              bid: '',
              title: '',
              author: '',
              cid: '',
              chapterName: '',
            ),
      );
      if (book.bid.isNotEmpty) {
        return book.bid;
      }
    }
    return null;
  }

  bool isBookSelected(String bid) => selectedBids.contains(bid);
}

class BookshelfCubit extends Cubit<BookshelfState> {
  int _loadSerial = 0;

  /// 整个书架（分类 + 各分类书目）存于单个缓存文件，每次刷新整体覆盖。
  static const String _cacheKey = 'bookshelf';

  BookshelfCubit()
    : super(
        BookshelfState(
          tip: '',
          status: BookshelfStatus.initial,
          bookcases: const [],
          bookcaseContents: const {},
        ),
      );

  /// 本地优先 + 后台刷新：
  /// 1. 先把上次缓存的目录立即显示（断网也能看）；
  /// 2. 再联网拉取最新书目，成功后覆盖缓存（含每个书架的完整内容）。
  Future<void> loadBookcases() async {
    final serial = ++_loadSerial;
    final hasData = state.bookcases.isNotEmpty;

    if (!hasData) {
      unawaited(_cleanupLegacyCache());
    }

    // 1) 本地缓存先上屏
    if (!hasData) {
      final restored = await _restoreFromCache();
      if (serial != _loadSerial) return;
      if (restored && state.bookcases.isNotEmpty) {
        emit(state.copyWith(status: BookshelfStatus.success));
      } else {
        emit(state.copyWith(status: BookshelfStatus.loading));
      }
    } else {
      emit(state.copyWith(status: BookshelfStatus.loading));
    }

    // 2) 联网刷新
    try {
      debugPrint('[BookshelfCubit] loadBookcases start');
      final bookcases = await bookcaseList();
      if (serial != _loadSerial) return;
      debugPrint('[BookshelfCubit] bookcaseList count=${bookcases.length}');
      if (bookcases.isEmpty) {
        debugPrint('[BookshelfCubit] ignore empty Rust bookshelf result');
        emit(state.copyWith(status: BookshelfStatus.success));
        return;
      }

      final contents = <String, List<BookcaseItem>>{};

      // 先載入第一個書架，立即 emit 讓 UI 顯示
      final firstBk = await bookInCase(caseId: bookcases.first.id);
      if (serial != _loadSerial) return;
      debugPrint(
        '[BookshelfCubit] first case ${bookcases.first.id} items=${firstBk.items.length}',
      );
      contents[bookcases.first.id] = firstBk.items;
      emit(
        state.copyWith(
          tip: firstBk.tip,
          status: BookshelfStatus.success,
          bookcases: bookcases,
          currentCaseId: bookcases.first.id,
          bookcaseContents: Map.from(contents),
        ),
      );
      // 後續書架在背景繼續載入，每載完一個就更新
      for (int i = 1; i < bookcases.length; i++) {
        final bk = await bookInCase(caseId: bookcases[i].id);
        if (serial != _loadSerial) return;
        debugPrint(
          '[BookshelfCubit] case ${bookcases[i].id} items=${bk.items.length}',
        );
        contents[bookcases[i].id] = bk.items;
        emit(state.copyWith(tip: bk.tip, bookcaseContents: Map.from(contents)));
      }
      // 全部加载完成后整体覆盖写入缓存（单文件，不累积）。
      unawaited(_persist(bookcases, contents));
      // 后台预取整个书架各书的详情+目录，使离线显示与在线一致。
      final allItems = contents.values.expand((e) => e).toList();
      ShelfPrefetch.instance.prefetchShelf(allItems);
    } catch (e) {
      final msg = e.toString();
      Log.error('BookshelfCubit', 'loadBookcases error: $msg');
      // 403 / CF 封鎖 → 改用 WebView 繞過
      if (msg.contains('403') ||
          msg.contains('Cloudflare') ||
          msg.contains('cf_')) {
        Log.info('BookshelfCubit', 'entering cloudflareChallenge fallback');
        emit(state.copyWith(status: BookshelfStatus.cloudflareChallenge));
      } else {
        emit(
          state.copyWith(
            status: state.bookcases.isNotEmpty
                ? BookshelfStatus.success
                : BookshelfStatus.error,
            errorMessage: state.bookcases.isNotEmpty ? null : msg,
          ),
        );
      }
    }
  }

  /// 清理旧版本遗留的分文件缓存（避免缓存文件堆积）。
  Future<void> _cleanupLegacyCache() async {
    await LocalCache.instance.removeByPrefix('bookshelf_contents_');
    await LocalCache.instance.remove('bookshelf_bookcases');
  }

  /// 从本地缓存恢复书架（离线可用）。
  Future<bool> _restoreFromCache() async {
    try {
      final raw = await LocalCache.instance.read(_cacheKey);
      if (raw is! Map) return false;
      final m = raw.map((k, v) => MapEntry(k.toString(), v));
      final rawBookcases = m['bookcases'];
      if (rawBookcases is! List || rawBookcases.isEmpty) return false;
      final bookcases = rawBookcases.map(ShelfCodec.bookcaseFromJson).toList();

      final contents = <String, List<BookcaseItem>>{};
      final rawContents = m['contents'];
      if (rawContents is Map) {
        for (final entry in rawContents.entries) {
          final list = entry.value;
          if (list is List) {
            contents[entry.key.toString()] =
                list.map(ShelfCodec.itemFromJson).toList();
          }
        }
      }
      emit(
        state.copyWith(
          status: BookshelfStatus.success,
          bookcases: bookcases,
          currentCaseId: bookcases.first.id,
          bookcaseContents: contents,
        ),
      );
      Log.info(
        'BookshelfCubit',
        'restored from cache: ${bookcases.length} bookcases',
      );
      return true;
    } catch (e) {
      Log.warning('BookshelfCubit', 'restore cache failed: $e');
      return false;
    }
  }

  /// 整体覆盖写入单个缓存文件（分类 + 各分类书目）。
  Future<void> _persist(
    List<Bookcase> bookcases,
    Map<String, List<BookcaseItem>> contents,
  ) => LocalCache.instance.write(_cacheKey, {
    'bookcases': bookcases.map(ShelfCodec.bookcaseToJson).toList(),
    'contents': contents.map(
      (k, v) => MapEntry(k, v.map(ShelfCodec.itemToJson).toList()),
    ),
  });

  /// WebView 成功取得書架資料後呼叫
  void loadFromWebViewData(
    List<Bookcase> bookcases,
    Map<String, BookcaseDto> bookcaseContents,
  ) {
    debugPrint(
      '[BookshelfCubit] WebView data bookcases=${bookcases.length} contents=${bookcaseContents.length}',
    );
    if (bookcases.isEmpty) {
      debugPrint('[BookshelfCubit] ignore empty WebView bookshelf result');
      emit(state.copyWith(status: BookshelfStatus.success));
      return;
    }
    final tip =
        bookcaseContents.values.isNotEmpty
            ? bookcaseContents.values.last.tip
            : '';
    final contents = bookcaseContents.map((k, v) => MapEntry(k, v.items));
    final incomingIds = bookcases.map((b) => b.id).toSet();
    final nextCaseId =
        state.currentCaseId != null && incomingIds.contains(state.currentCaseId)
            ? state.currentCaseId
            : bookcases.first.id;
    emit(
      state.copyWith(
        tip: tip,
        status: BookshelfStatus.success,
        bookcases: bookcases,
        currentCaseId: nextCaseId,
        bookcaseContents: contents,
      ),
    );
    // 联网成功的数据整体覆盖缓存，供下次离线启动展示。
    unawaited(_persist(bookcases, contents));
    // 后台预取整个书架各书的详情+目录，使离线显示与在线一致。
    ShelfPrefetch.instance.prefetchShelf(
      contents.values.expand((e) => e).toList(),
    );
  }

  void setError(String message) {
    debugPrint('[BookshelfCubit] setError: $message');
    emit(
      state.copyWith(
        status:
            state.bookcases.isNotEmpty
                ? BookshelfStatus.success
                : BookshelfStatus.error,
        errorMessage: state.bookcases.isNotEmpty ? null : message,
      ),
    );
  }

  void selectBookcase(String caseId) {
    emit(state.copyWith(currentCaseId: caseId));
    // 该书架内容可能尚未加载（离线启动），从缓存补上。
    if (state.bookcaseContents[caseId] == null) {
      unawaited(_fillCaseFromCache(caseId));
    }
  }

  Future<void> _fillCaseFromCache(String caseId) async {
    final raw = await LocalCache.instance.read(_cacheKey);
    if (raw is! Map) return;
    final contentsRaw = raw['contents'];
    if (contentsRaw is! Map) return;
    final list = contentsRaw[caseId];
    if (list is! List) return;
    final items = list.map(ShelfCodec.itemFromJson).toList();
    final next = Map<String, List<BookcaseItem>>.from(state.bookcaseContents);
    next[caseId] = items;
    emit(state.copyWith(bookcaseContents: next));
  }

  void toggleSelectMode() {
    emit(
      state.copyWith(
        isSelecting: !state.isSelecting,
        selectedBids: state.isSelecting ? {} : state.selectedBids,
      ),
    );
  }

  void toggleBookSelection(String bid) {
    final newSelectedBids = Set<String>.from(state.selectedBids);
    if (newSelectedBids.contains(bid)) {
      newSelectedBids.remove(bid);
    } else {
      newSelectedBids.add(bid);
    }
    emit(state.copyWith(selectedBids: newSelectedBids));
  }

  Future<void> moveSelectedBooks(String toBookcaseId) async {
    if (state.selectedBids.isEmpty || state.currentCaseId == null) return;

    final bidsToMove = Set<String>.from(state.selectedBids);
    final fromId = state.currentCaseId!;

    try {
      await moveBookcase(
        bidList: bidsToMove.toList(),
        fromBookcaseId: fromId,
        toBookcaseId: toBookcaseId,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('403') ||
          msg.contains('Cloudflare') ||
          msg.contains('cf_')) {
        rethrow; // 讓 UI 層用 WebView 重試
      }
      emit(state.copyWith(status: BookshelfStatus.error, errorMessage: msg));
      return;
    }

    // 寫入成功 → 樂觀更新本地狀態，無需等伺服器回傳
    final newContents = Map<String, List<BookcaseItem>>.from(
      state.bookcaseContents,
    );
    newContents[fromId] =
        (newContents[fromId] ?? [])
            .where((b) => !bidsToMove.contains(b.bid))
            .toList();
    emit(
      state.copyWith(
        bookcaseContents: newContents,
        selectedBids: {},
        isSelecting: false,
      ),
    );

    // 背景刷新伺服器資料（失敗不影響已更新的 UI）
    unawaited(_refreshBookcasesInBackground());
  }

  Future<void> addToBookshelf(String aid) async {
    try {
      await addBookshelf(aid: aid);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('403') ||
          msg.contains('Cloudflare') ||
          msg.contains('cf_')) {
        rethrow; // 讓 novel_info_page 用 WebView 重試
      }
      emit(state.copyWith(status: BookshelfStatus.error, errorMessage: msg));
      return;
    }

    // 寫入成功 → 觸發完整書架刷新（loadBookcases 有 CF 備援）
    await loadBookcases();
  }

  Future<void> removeFromBookshelf(String aid) async {
    final bid = state.getBookBid(aid);
    if (bid == null) return;

    try {
      await deleteBookcase(bid: bid);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('403') ||
          msg.contains('Cloudflare') ||
          msg.contains('cf_')) {
        rethrow; // 讓 novel_info_page 用 WebView 重試
      }
      emit(state.copyWith(status: BookshelfStatus.error, errorMessage: msg));
      return;
    }

    // 寫入成功 → 樂觀從本地狀態移除
    final newContents = <String, List<BookcaseItem>>{};
    for (final entry in state.bookcaseContents.entries) {
      newContents[entry.key] = entry.value.where((b) => b.bid != bid).toList();
    }
    emit(state.copyWith(bookcaseContents: newContents));

    // 背景刷新伺服器資料（失敗不影響已更新的 UI）
    unawaited(_refreshBookcasesInBackground());
  }

  /// 背景靜默刷新書架，失敗時不改變 UI 狀態
  Future<void> _refreshBookcasesInBackground() async {
    try {
      final contents = <String, List<BookcaseItem>>{};
      for (final bookcase in state.bookcases) {
        final bk = await bookInCase(caseId: bookcase.id);
        contents[bookcase.id] = bk.items;
      }
      emit(state.copyWith(bookcaseContents: contents));
    } catch (_) {}
  }
}
