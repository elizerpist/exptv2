import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../presentation/dashboard_logbox_prepared_row_text_layout.dart';
import 'dashboard_log_viewport_state.dart';

/// One immutable, keyset-addressable committed vertical page.
///
/// This is intentionally not a [DashboardVisibleFrame]: page data belongs to
/// the vertically scrolled list, while the visible frame remains the bounded
/// rail-preview and summary snapshot.
@immutable
final class CommittedLogPage {
  CommittedLogPage({
    required this.queryKey,
    required this.coreRevision,
    required this.generation,
    required this.ordinal,
    required Map<String, Object?>? startCursor,
    required Map<String, Object?>? previousStartCursor,
    required this.payload,
  }) : startCursor = startCursor == null
           ? null
           : Map<String, Object?>.unmodifiable(startCursor),
       previousStartCursor = previousStartCursor == null
           ? null
           : Map<String, Object?>.unmodifiable(previousStartCursor),
       contentDigest = Object.hash(
         queryKey,
         coreRevision,
         ordinal,
         payload.viewportId,
         payload.nextCursor?['entryId'],
       ) {
    if (coreRevision < 0 || generation < 0 || ordinal < 0) {
      throw ArgumentError('Committed LogBox page identity is invalid.');
    }
    if (payload.queryKey != queryKey || payload.revision != coreRevision) {
      throw ArgumentError(
        'A committed page payload must share the exact query and revision.',
      );
    }
  }

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int generation;
  final int ordinal;
  final Map<String, Object?>? startCursor;
  final Map<String, Object?>? previousStartCursor;
  final DashboardLogViewportState payload;
  final int contentDigest;

  int get rowCount => payload.flatItems.length;
  Map<String, Object?>? get nextCursor => payload.nextCursor;
}

/// Compact keyset chain retained independently from row/text pages. It makes
/// an evicted nearby page reloadable without retaining its transaction VMs.
@immutable
final class CommittedLogPageCursorAnchor {
  CommittedLogPageCursorAnchor(CommittedLogPage page)
    : ordinal = page.ordinal,
      startCursor = page.startCursor,
      previousStartCursor = page.previousStartCursor,
      nextCursor = page.nextCursor;

  final int ordinal;
  final Map<String, Object?>? startCursor;
  final Map<String, Object?>? previousStartCursor;
  final Map<String, Object?>? nextCursor;
}

/// Bounded data owner for the committed, vertically scrollable LogBox list.
///
/// It owns only immutable prepared page view models. Exact-width paragraphs
/// are attached by the vertical presentation cache after a normal surface
/// layout is known; neither domain is shared with the rail scene cache.
final class CommittedLogViewportCache extends ChangeNotifier {
  CommittedLogViewportCache({
    required this.pageSize,
    this.maximumRetainedPages = 5,
    this.maximumCursorAnchors = 8192,
  }) {
    if (pageSize <= 0 || maximumRetainedPages < 3 || maximumCursorAnchors < 1) {
      throw ArgumentError('Committed page-cache bounds are invalid.');
    }
    if (maximumRetainedPages.isEven) {
      throw ArgumentError.value(
        maximumRetainedPages,
        'maximumRetainedPages',
        'must be odd so the visible page has symmetric neighbors.',
      );
    }
  }

  final int pageSize;
  final int maximumRetainedPages;
  final int maximumCursorAnchors;
  final Map<int, CommittedLogPage> _pages = <int, CommittedLogPage>{};
  final Map<int, CommittedLogPageCursorAnchor> _cursorAnchors =
      <int, CommittedLogPageCursorAnchor>{};
  final Map<int, CommittedPreparedLogPage> _preparedPages =
      <int, CommittedPreparedLogPage>{};
  _CommittedPageGeometry? _geometry;

  LedgerQueryKey? _queryKey;
  int? _coreRevision;
  int? _generation;
  int _totalEntryCount = 0;
  int _highestCommittedOrdinal = -1;
  int _visibleStart = 0;
  int _visibleEnd = 0;
  int _evictedPageCount = 0;
  int _stalePageDiscardCount = 0;
  int _presentationGeneration = 0;
  int _textLayoutMissCount = 0;
  int _estimatedBytes = 0;
  double? _surfaceWidth;
  Map<String, Object?>? _nextCursor;
  String? _lastError;
  int _pageFailureCount = 0;
  bool _disposed = false;

  LedgerQueryKey? get queryKey => _queryKey;
  int? get coreRevision => _coreRevision;
  int? get generation => _generation;
  int get totalEntryCount => _totalEntryCount;
  int get loadedEntryCount => _highestCommittedOrdinal < 0
      ? 0
      : (_highestCommittedOrdinal + 1) * pageSize > _totalEntryCount
      ? _totalEntryCount
      : (_highestCommittedOrdinal + 1) * pageSize;
  int get retainedPageCount => _pages.length;
  int get visibleEntryCount =>
      (_visibleEnd - _visibleStart).clamp(0, _totalEntryCount);
  int get retainedRowCount =>
      _pages.values.fold<int>(0, (count, page) => count + page.rowCount);
  int get evictedPageCount => _evictedPageCount;
  int get stalePageDiscardCount => _stalePageDiscardCount;
  int get presentationGeneration => _presentationGeneration;
  int get preparedTextRowCount => _preparedPages.values.fold<int>(
    0,
    (count, page) => count + page.rowLayoutCount,
  );
  int get preparedDayHeaderCount => _preparedPages.values.fold<int>(
    0,
    (count, page) => count + page.dayHeaderCount,
  );
  int get estimatedBytes => _estimatedBytes;
  int get textLayoutMissCount => _textLayoutMissCount;
  String? get lastError => _lastError;
  int get pageFailureCount => _pageFailureCount;
  double? get surfaceWidth => _surfaceWidth;
  Map<String, Object?>? get nextCursor => _nextCursor;
  bool get hasMorePages => _nextCursor != null;
  int get highestCommittedOrdinal => _highestCommittedOrdinal;
  int get lowestRetainedOrdinal => _pages.isEmpty
      ? 0
      : _pages.keys.reduce((value, next) => value < next ? value : next);
  CommittedLogPage? get lowestRetainedPage => _pages[lowestRetainedOrdinal];
  double get contentHeight => _geometry?.contentHeight ?? 0;
  int get geometryBytes => _geometry?.estimatedBytes ?? 0;
  bool get hasExactCommittedScope =>
      _queryKey != null && _coreRevision != null && _generation != null;

  /// Clears an old structural scope and publishes the immutable first page.
  /// The supplied generation is owned by the application paging coordinator,
  /// not by an old frame or renderer callback.
  void seed(CommittedLogPage page, {required int generation}) {
    _ensureUsable();
    _pages.clear();
    _cursorAnchors.clear();
    _disposePreparedPages();
    _queryKey = page.queryKey;
    _coreRevision = page.coreRevision;
    _generation = generation;
    _totalEntryCount = page.payload.entryCount;
    _geometry = _CommittedPageGeometry(
      totalEntryCount: _totalEntryCount,
      pageSize: pageSize,
    );
    _highestCommittedOrdinal = page.ordinal;
    _visibleStart = 0;
    _visibleEnd = page.rowCount;
    final prepared = _preparePage(page);
    _pages[page.ordinal] = page;
    _rememberCursorAnchor(page);
    if (prepared != null) _preparedPages[page.ordinal] = prepared;
    _geometry!.record(page.ordinal, _pageHeight(page.payload));
    _nextCursor = page.nextCursor;
    _refreshEstimatedBytes();
    _presentationGeneration += 1;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_COMMITTED',
        queryKey: page.queryKey.value,
        entryCount: page.rowCount,
      ),
    );
    if (_nextCursor == null) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_END_REACHED',
          queryKey: page.queryKey.value,
          entryCount: loadedEntryCount,
        ),
      );
    }
    notifyListeners();
  }

  /// Atomically commits a complete decoded/page-projected payload. A stale
  /// page never replaces, extends, or partially mutates the cache.
  bool commit(CommittedLogPage page) {
    _ensureUsable();
    if (!_accepts(page)) {
      _stalePageDiscardCount += 1;
      return false;
    }
    final existing = _pages[page.ordinal];
    if (existing != null && existing.contentDigest != page.contentDigest) {
      throw StateError('One committed page ordinal resolved to two contents.');
    }
    if (existing != null) return true;
    final prepared = _preparePage(page);
    _pages[page.ordinal] = page;
    _rememberCursorAnchor(page);
    if (prepared != null) _preparedPages[page.ordinal] = prepared;
    _geometry!.record(page.ordinal, _pageHeight(page.payload));
    if (page.ordinal >= _highestCommittedOrdinal) _nextCursor = page.nextCursor;
    if (page.ordinal > _highestCommittedOrdinal) {
      _highestCommittedOrdinal = page.ordinal;
    }
    // A near-end append is normally requested while the preceding page is
    // visible. Use that known relationship for immediate boundedness even
    // before the next scroll notification arrives.
    _retainVisibleWindow(centerPage: page.ordinal > 0 ? page.ordinal - 1 : 0);
    _refreshEstimatedBytes();
    _presentationGeneration += 1;
    notifyListeners();
    return true;
  }

  /// Updates only cache-retention policy. It does not start I/O, create
  /// paragraphs, or change scroll metrics; the scroll surface owns those.
  void updateVisibleRowWindow({required int start, required int end}) {
    _ensureUsable();
    if (start < 0 || end < start) {
      throw ArgumentError('Visible committed-row bounds are invalid.');
    }
    if (_visibleStart == start && _visibleEnd == end) return;
    _visibleStart = start;
    _visibleEnd = end;
    _retainVisibleWindow();
    _presentationGeneration += 1;
    _refreshEstimatedBytes();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_ROW_WINDOW_CHANGED',
        queryKey: _queryKey?.value,
        entryCount: visibleEntryCount,
        message: 'start=$start end=$end retainedPages=$retainedPageCount',
      ),
    );
    notifyListeners();
  }

  CommittedLogPage? pageForOrdinal(int ordinal) => _pages[ordinal];

  CommittedPreparedLogPage? preparedPageForOrdinal(int ordinal) =>
      _preparedPages[ordinal];

  CommittedLogPageCursorAnchor? cursorAnchorForOrdinal(int ordinal) =>
      _cursorAnchors[ordinal];

  int pageOrdinalForOffset(double offset) =>
      _geometry?.pageOrdinalForOffset(offset) ?? 0;

  double pageTopForOrdinal(int ordinal) =>
      _geometry?.pageTopForOrdinal(ordinal) ?? 0;

  double pageHeightForOrdinal(int ordinal) =>
      _geometry?.pageHeightForOrdinal(ordinal) ?? 0;

  /// Binds the normal visible surface width. This is an explicit page
  /// preparation step, never a paint-time fallback. Existing ready pages are
  /// rebuilt transactionally on an orientation/width change.
  void configureSurfaceWidth(double width) {
    _ensureUsable();
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(width, 'width');
    }
    if (_surfaceWidth == width && _preparedPages.length == _pages.length) {
      return;
    }
    final next = <int, CommittedPreparedLogPage>{};
    try {
      for (final entry in _pages.entries) {
        next[entry.key] = _buildPreparedPage(entry.value, width);
      }
    } on Object {
      // Width changes must be all-or-nothing: the prior complete page bank is
      // still usable when a new paragraph allocation/layout fails.
      for (final page in next.values) {
        page.dispose();
      }
      rethrow;
    }
    _disposePreparedPages();
    _surfaceWidth = width;
    _preparedPages.addAll(next);
    _refreshEstimatedBytes();
    _presentationGeneration += 1;
    notifyListeners();
  }

  DashboardLogViewportItemViewModel? rowAt(int logicalRow) {
    if (logicalRow < 0) return null;
    final page = _pages[logicalRow ~/ pageSize];
    final local = logicalRow % pageSize;
    if (page == null || local >= page.payload.flatItems.length) return null;
    return page.payload.flatItems[local];
  }

  DashboardPreparedLogBoxRowTextLayout? layoutAt(int logicalRow) {
    if (logicalRow < 0) return null;
    final page = _preparedPages[logicalRow ~/ pageSize];
    final item = rowAt(logicalRow);
    final layout = item == null ? null : page?.rowFor(item);
    if (item != null && layout == null) _textLayoutMissCount += 1;
    return layout;
  }

  TextPainter? dayHeaderAt(int logicalRow) {
    if (logicalRow < 0) return null;
    final item = rowAt(logicalRow);
    if (item?.dayLabel case final String label) {
      return _preparedPages[logicalRow ~/ pageSize]?.dayHeaderFor(label);
    }
    return null;
  }

  /// Leaves the last complete page window untouched while recording a
  /// retryable acquisition/preparation failure.
  void recordPageFailure({
    required LedgerQueryKey queryKey,
    required int coreRevision,
    required int ordinal,
    required Object error,
  }) {
    _ensureUsable();
    _pageFailureCount += 1;
    _lastError = '$error';
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'ERROR',
        queryKey: queryKey.value,
        coreRevision: coreRevision,
        message: 'VERTICAL_PAGE_FAILED ordinal=$ordinal',
        error: _lastError,
      ),
    );
    notifyListeners();
  }

  /// Emits one bounded summary when the user ends a vertical scroll. This is
  /// deliberately cache-owned and never emitted for individual scroll samples.
  void recordScrollSummary({required double scrollOffset}) {
    if (!hasExactCommittedScope) return;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_SCROLL_SUMMARY',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        entryCount: totalEntryCount,
        message:
            'offset=${scrollOffset.round()} visible=$visibleEntryCount '
            'retainedPages=$retainedPageCount retainedRows=$retainedRowCount '
            'cacheBytes=$estimatedBytes',
      ),
    );
  }

  Map<String, Object?> report() => <String, Object?>{
    'state': hasExactCommittedScope ? 'ready' : 'unbound',
    'queryKey': _queryKey?.value,
    'coreRevision': _coreRevision,
    'generation': _generation,
    'totalRows': totalEntryCount,
    'loadedRows': loadedEntryCount,
    'visibleRows': visibleEntryCount,
    'retainedPages': retainedPageCount,
    'retainedRows': retainedRowCount,
    'preparedTextRows': preparedTextRowCount,
    'preparedDayHeaders': preparedDayHeaderCount,
    'cacheBytes': estimatedBytes,
    'geometryBytes': geometryBytes,
    'cursorAnchors': _cursorAnchors.length,
    'maximumRetainedPages': maximumRetainedPages,
    'maximumCursorAnchors': maximumCursorAnchors,
    'textLayoutMisses': textLayoutMissCount,
    'evictedPages': evictedPageCount,
    'hasMorePages': hasMorePages,
    'pageFailures': pageFailureCount,
    'lastError': lastError,
  };

  bool _accepts(CommittedLogPage page) =>
      page.queryKey == _queryKey &&
      page.coreRevision == _coreRevision &&
      page.generation == _generation &&
      page.payload.entryCount == _totalEntryCount &&
      page.rowCount <= pageSize;

  void _retainVisibleWindow({int? centerPage}) {
    if (_pages.length <= maximumRetainedPages) return;
    final visiblePage = centerPage ?? _visibleStart ~/ pageSize;
    final radius = maximumRetainedPages ~/ 2;
    final minimum = visiblePage - radius;
    final maximum = visiblePage + radius;
    final evicted = _pages.keys
        .where((ordinal) => ordinal < minimum || ordinal > maximum)
        .toList(growable: false);
    for (final ordinal in evicted) {
      _pages.remove(ordinal);
      _preparedPages.remove(ordinal)?.dispose();
      _evictedPageCount += 1;
    }
    if (evicted.isNotEmpty) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_PAGE_EVICTED',
          queryKey: _queryKey?.value,
          entryCount: evicted.length,
          message: 'retainedPages=$retainedPageCount',
        ),
      );
    }
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('Committed LogBox viewport cache is disposed.');
    }
  }

  void _rememberCursorAnchor(CommittedLogPage page) {
    _cursorAnchors[page.ordinal] = CommittedLogPageCursorAnchor(page);
    while (_cursorAnchors.length > maximumCursorAnchors) {
      _cursorAnchors.remove(_cursorAnchors.keys.first);
    }
  }

  CommittedPreparedLogPage? _preparePage(CommittedLogPage page) {
    final width = _surfaceWidth;
    return width == null ? null : _buildPreparedPage(page, width);
  }

  CommittedPreparedLogPage _buildPreparedPage(
    CommittedLogPage page,
    double width,
  ) {
    final rows = <String, DashboardPreparedLogBoxRowTextLayout>{};
    final headers = <String, TextPainter>{};
    for (final item in page.payload.flatItems) {
      rows[item.row.entryId] = DashboardPreparedLogBoxRowTextLayout.prepare(
        row: item.row,
        surfaceWidth: width,
        contentIdentity: item.row.textLayoutId,
      );
      if (item.dayLabel case final String label) {
        headers[label] = prepareDashboardLogBoxTextPainter(
          label,
          FluviVisualTokens.logBoxDayHeaderTextStyle,
          width,
        );
      }
    }
    return CommittedPreparedLogPage._(
      page: page,
      rowLayouts: rows,
      dayHeaders: headers,
    );
  }

  void _disposePreparedPages() {
    for (final page in _preparedPages.values) {
      page.dispose();
    }
    _preparedPages.clear();
  }

  void _refreshEstimatedBytes() {
    var units = 0;
    for (final page in _pages.values) {
      for (final item in page.payload.flatItems) {
        final row = item.row;
        units +=
            row.entryId.length +
            row.displayName.length +
            row.categoryDisplayName.length +
            row.formattedAmount.length +
            row.displayTime.length;
      }
    }
    _estimatedBytes = preparedTextRowCount * 2048 + units * 2;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pages.clear();
    _cursorAnchors.clear();
    _disposePreparedPages();
    _geometry = null;
    _nextCursor = null;
    super.dispose();
  }

  static double _pageHeight(DashboardLogViewportState payload) {
    if (payload.flatItems.isEmpty) return DashboardLogBoxTokens.rowHeight;
    return payload.flatItems.length * DashboardLogBoxTokens.rowHeight +
        payload.groups.length * DashboardLogBoxTokens.dayHeaderHeight +
        (payload.groups.length - 1) * DashboardLogBoxTokens.dayGroupGap;
  }
}

/// A compact geometry index is retained after a page VM is evicted. It stores
/// one extent delta per *page*, never transaction text/VM/layout data, so a
/// 100k-row list has about 4,167 doubles rather than 100k paragraphs.
final class _CommittedPageGeometry {
  _CommittedPageGeometry({
    required this.totalEntryCount,
    required this.pageSize,
  }) : pageCount = (totalEntryCount + pageSize - 1) ~/ pageSize,
       _deltas = List<double>.filled(
         (totalEntryCount + pageSize - 1) ~/ pageSize,
         0,
       ),
       _tree = List<double>.filled(
         (totalEntryCount + pageSize - 1) ~/ pageSize + 1,
         0,
       ) {
    var total = 0.0;
    for (var ordinal = 0; ordinal < pageCount; ordinal += 1) {
      total += _baseHeight(ordinal);
    }
    _baseTotal = total;
  }

  final int totalEntryCount;
  final int pageSize;
  final int pageCount;
  final List<double> _deltas;
  final List<double> _tree;
  late final double _baseTotal;

  double get contentHeight => _baseTotal + _prefixDelta(pageCount);
  int get estimatedBytes => _deltas.length * 16 + _tree.length * 8;

  void record(int ordinal, double actualHeight) {
    if (ordinal < 0 || ordinal >= pageCount) return;
    final nextDelta = actualHeight - _baseHeight(ordinal);
    final difference = nextDelta - _deltas[ordinal];
    if (difference == 0) return;
    _deltas[ordinal] = nextDelta;
    for (var index = ordinal + 1; index <= pageCount; index += index & -index) {
      _tree[index] += difference;
    }
  }

  int pageOrdinalForOffset(double offset) {
    if (pageCount == 0) return 0;
    var low = 0;
    var high = pageCount - 1;
    while (low < high) {
      final middle = low + ((high - low + 1) >> 1);
      if (pageTopForOrdinal(middle) <= offset) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  double pageTopForOrdinal(int ordinal) {
    if (ordinal <= 0) return 0;
    final count = ordinal.clamp(0, pageCount);
    return _basePrefix(count) + _prefixDelta(count);
  }

  double pageHeightForOrdinal(int ordinal) =>
      _baseHeight(ordinal) +
      (ordinal >= 0 && ordinal < pageCount ? _deltas[ordinal] : 0);

  double _basePrefix(int count) {
    final rows = (count * pageSize).clamp(0, totalEntryCount);
    return rows * DashboardLogBoxTokens.rowHeight +
        count * DashboardLogBoxTokens.dayHeaderHeight;
  }

  double _baseHeight(int ordinal) {
    final start = ordinal * pageSize;
    final rows = (totalEntryCount - start).clamp(0, pageSize);
    return rows * DashboardLogBoxTokens.rowHeight +
        DashboardLogBoxTokens.dayHeaderHeight;
  }

  double _prefixDelta(int count) {
    var result = 0.0;
    for (var index = count; index > 0; index -= index & -index) {
      result += _tree[index];
    }
    return result;
  }
}

/// Prepared text resources for one complete committed page. It is created as
/// one unit before publication so a renderer cannot observe an avatar-only
/// or header-less row.
final class CommittedPreparedLogPage {
  CommittedPreparedLogPage._({
    required this.page,
    required Map<String, DashboardPreparedLogBoxRowTextLayout> rowLayouts,
    required Map<String, TextPainter> dayHeaders,
  }) : _rowLayouts =
           Map<String, DashboardPreparedLogBoxRowTextLayout>.unmodifiable(
             rowLayouts,
           ),
       _dayHeaders = Map<String, TextPainter>.unmodifiable(dayHeaders);

  final CommittedLogPage page;
  final Map<String, DashboardPreparedLogBoxRowTextLayout> _rowLayouts;
  final Map<String, TextPainter> _dayHeaders;

  int get rowLayoutCount => _rowLayouts.length;
  int get dayHeaderCount => _dayHeaders.length;

  DashboardPreparedLogBoxRowTextLayout? rowFor(
    DashboardLogViewportItemViewModel item,
  ) {
    final layout = _rowLayouts[item.row.entryId];
    return layout?.contentIdentity == item.row.textLayoutId ? layout : null;
  }

  TextPainter? dayHeaderFor(String label) => _dayHeaders[label];

  void dispose() {
    for (final layout in _rowLayouts.values) {
      layout.dispose();
    }
    for (final header in _dayHeaders.values) {
      header.dispose();
    }
  }
}
