import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../presentation/dashboard_logbox_prepared_row_text_layout.dart';
import 'committed_vertical_geometry_manifest.dart';
import 'dashboard_log_viewport_state.dart';

/// A terminal reason why a decoded vertical page cannot become drawable in the
/// active committed scope. A false cache commit is never intentionally silent.
enum CommittedLogPageCommitRejection {
  queryMismatch,
  revisionMismatch,
  generationMismatch,
  totalCountMismatch,
  pageSizeViolation,
  duplicateDigestMismatch,
  nonContiguousOrdinal,
  geometryMismatch,
  prepareFailure,
}

/// Injectable cooperative-work policy for private committed page text
/// preparation. It measures actual contiguous UI work rather than counting
/// rows. The default yields to a later event turn; it deliberately makes no
/// next-display-frame guarantee.
@immutable
final class CommittedPagePreparationPolicy {
  const CommittedPagePreparationPolicy({
    this.contiguousUiBudgetMicros = 1800,
    this.nowMicros,
    this.yieldToEventTurn,
  }) : assert(contiguousUiBudgetMicros > 0);

  final int contiguousUiBudgetMicros;
  final int Function()? nowMicros;
  final Future<void> Function()? yieldToEventTurn;
}

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

  int get rowCount => payload.previewRowCount;
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
/// Complete exact pages are ready geometry only in the resource sense: their
/// immutable virtual coordinates were published with the committed scope and
/// never grow the Flutter scroll world.
final class CommittedLogViewportCache extends ChangeNotifier {
  CommittedLogViewportCache({
    required this.pageSize,
    this.maximumRetainedPages = 5,
    this.maximumRetainedBytes = 2 * 1024 * 1024,
    this.maximumCursorAnchors = 8192,
    this.pagePreparationPolicy = const CommittedPagePreparationPolicy(),
  }) {
    if (pageSize <= 0 ||
        maximumRetainedPages < 3 ||
        maximumRetainedBytes < 1 ||
        maximumCursorAnchors < 1) {
      throw ArgumentError('Committed page-cache bounds are invalid.');
    }
    if (maximumRetainedPages.isEven) {
      throw ArgumentError.value(
        maximumRetainedPages,
        'maximumRetainedPages',
        'must be odd so the visible page has symmetric neighbours.',
      );
    }
  }

  final int pageSize;

  /// Hard cap for movable committed pages. Root ordinal zero is pinned
  /// separately and does not consume this local prepared working-set budget.
  final int maximumRetainedPages;

  /// Exact cache memory budget. Unlike the former page-count cap this lets a
  /// small scope remain completely hot while a large scope stays bounded.
  final int maximumRetainedBytes;
  final int maximumCursorAnchors;
  final CommittedPagePreparationPolicy pagePreparationPolicy;
  final Stopwatch _pagePreparationClock = Stopwatch()..start();

  // Page zero is the committed scope's root. It has one bounded page of row
  // VMs and must survive local LRU rotation so reverse scroll never reaches a
  // geometry-only, blank top page.
  CommittedLogPage? _rootPage;
  final Map<int, CommittedLogPage> _pages = <int, CommittedLogPage>{};
  final Map<int, CommittedLogPageCursorAnchor> _cursorAnchors =
      <int, CommittedLogPageCursorAnchor>{};
  final Map<int, CommittedPreparedLogPage> _preparedPages =
      <int, CommittedPreparedLogPage>{};
  // Full scope geometry is immutable and independent from the bounded page
  // resource hotset. A page becoming paint-ready must never change Flutter's
  // content dimensions.
  CommittedVerticalGeometryManifest? _geometryManifest;
  int _geometryGeneration = 0;
  int _renderGeneration = 0;
  final ChangeNotifier _resourceChanges = ChangeNotifier();

  LedgerQueryKey? _queryKey;
  int? _coreRevision;
  int? _generation;
  int _totalEntryCount = 0;
  int _highestCommittedOrdinal = -1;
  int _visibleStart = 0;
  int _visibleEnd = 0;
  bool _retainingBackward = false;
  int _evictedPageCount = 0;
  int _stalePageDiscardCount = 0;
  int _presentationGeneration = 0;
  int _textLayoutMissCount = 0;
  int _pageCommitRejectCount = 0;
  int _estimatedBytes = 0;
  int _rootEstimatedBytes = 0;
  int _retainedPageEstimatedBytes = 0;
  final Map<int, int> _pageEstimatedBytes = <int, int>{};
  int _retentionTick = 0;
  int _retentionBudgetOverflowCount = 0;
  final Map<int, int> _pageRetentionTouches = <int, int>{};
  Set<int> _retentionHotset = <int>{};
  double? _surfaceWidth;
  Map<String, Object?>? _nextCursor;
  String? _lastError;
  CommittedLogPageCommitRejection? _lastCommitRejection;
  int _pageFailureCount = 0;
  int _desiredForwardOrdinal = 0;
  bool _endReachedReported = false;
  int _endReachedCount = 0;
  int _rootFallbackGeneration = 0;
  bool _rootFallbackPreparing = false;
  bool _rootPageInvariantReported = false;
  int _rootNotDrawableCount = 0;
  int _virtualPageMissCount = 0;
  int _virtualGeometryMismatchCount = 0;
  final Set<int> _reportedVirtualPageMisses = <int>{};
  int _pagePreparationUiMicros = 0;
  int _largestPagePreparationUiSliceMicros = 0;
  int _pagePreparationYieldCount = 0;
  bool _pagePreparationActive = false;
  bool _verticalRenderingActive = false;
  int _initialPreviewOrdinal = 0;
  bool _disposed = false;

  LedgerQueryKey? get queryKey => _queryKey;
  int? get coreRevision => _coreRevision;
  int? get generation => _generation;
  int get totalEntryCount => _totalEntryCount;

  /// Full exact geometry exposed to the stable committed surface. It changes
  /// only when this exact committed scope changes, never when a page commits.
  CommittedVerticalGeometryManifest? get geometryManifest => _geometryManifest;
  bool get hasVirtualGeometry => _geometryManifest != null;
  int get totalPageCount => _geometryManifest?.totalPageCount ?? 0;
  int get loadedEntryCount => contiguousReadyRowCount;
  int get contiguousReadyRowCount =>
      _geometryManifest?.rowCountThrough(_highestCommittedOrdinal) ?? 0;
  int get highestReadyPageOrdinal => _highestCommittedOrdinal;
  int get discoveredPageCount => _highestCommittedOrdinal + 1;
  double get drawableExtent => _geometryManifest?.totalExtent ?? 0;
  int get geometryGeneration => _geometryGeneration;
  int get renderGeneration => _renderGeneration;
  Listenable get resourceChanges => _resourceChanges;
  bool get rootPagePresent => _rootPage != null;
  int? get rootPageViewportId => _rootPage?.payload.viewportId;
  int get rootPageRows => _rootPage?.rowCount ?? 0;
  bool get rootPageUsesRailScene =>
      _rootPage != null && !hasDrawableRootFallback;
  int get endReachedCount => _endReachedCount;
  int get retainedPageCount => _pages.length;
  int get visibleEntryCount =>
      (_visibleEnd - _visibleStart).clamp(0, totalEntryCount);
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
  int get pageCommitRejectCount => _pageCommitRejectCount;
  String? get lastError => _lastError;
  CommittedLogPageCommitRejection? get lastCommitRejection =>
      _lastCommitRejection;
  int get pageFailureCount => _pageFailureCount;
  double? get surfaceWidth => _surfaceWidth;
  Map<String, Object?>? get nextCursor => _nextCursor;
  bool get hasMorePages => _nextCursor != null;
  bool get isVerticalRenderingActive => _verticalRenderingActive;
  int get highestCommittedOrdinal => _highestCommittedOrdinal;
  int get desiredForwardOrdinal => _desiredForwardOrdinal;
  // The root page is pinned independently. One movable slot remains for the
  // current drawable page; the remaining three retain the two-page minimum
  // safety margin plus one bounded adaptive page.
  int get maximumForwardLookaheadPages => maximumRetainedPages - 2;
  int get lowestRetainedOrdinal => _pages.isEmpty
      ? 0
      : _pages.keys.reduce((value, next) => value < next ? value : next);
  CommittedLogPage? get lowestRetainedPage => _pages[lowestRetainedOrdinal];
  double get contentHeight => drawableExtent;
  int get geometryBytes => _geometryManifest?.estimatedBytes ?? 0;
  bool get hasExactCommittedScope =>
      _queryKey != null && _coreRevision != null && _generation != null;
  bool get hasDrawableRootFallback {
    final root = _preparedPages[_initialPreviewOrdinal];
    return root != null && root.surfaceWidth == _surfaceWidth;
  }

  bool get isRootFallbackPreparing => _rootFallbackPreparing;
  int get rootNotDrawableCount => _rootNotDrawableCount;
  int get virtualPageMissCount => _virtualPageMissCount;
  int get virtualGeometryMismatchCount => _virtualGeometryMismatchCount;
  int get pagePreparationUiMicros => _pagePreparationUiMicros;
  int get largestPagePreparationUiSliceMicros =>
      _largestPagePreparationUiSliceMicros;
  int get pagePreparationYieldCount => _pagePreparationYieldCount;
  bool get isPagePreparationActive => _pagePreparationActive;

  /// Clears an old structural scope and publishes the immutable first page.
  /// The supplied generation is owned by the application paging coordinator,
  /// not by an old frame or renderer callback.
  void seed(
    CommittedLogPage page, {
    required int generation,
    required CommittedVerticalGeometryManifest geometryManifest,
  }) {
    _ensureUsable();
    if (page.ordinal != 0) {
      throw ArgumentError.value(
        page.ordinal,
        'page.ordinal',
        'A committed scope must be seeded with root page zero.',
      );
    }
    if (geometryManifest.queryKey != page.queryKey ||
        geometryManifest.coreRevision != page.coreRevision ||
        geometryManifest.pageSize != pageSize ||
        geometryManifest.totalEntryCount != page.payload.entryCount) {
      throw StateError('Committed root page does not match virtual geometry.');
    }
    _pages.clear();
    _cursorAnchors.clear();
    _disposePreparedPages();
    _pageEstimatedBytes.clear();
    _retainedPageEstimatedBytes = 0;
    _rootEstimatedBytes = 0;
    _pageRetentionTouches.clear();
    _retentionHotset = <int>{};
    _retentionTick = 0;
    _retentionBudgetOverflowCount = 0;
    _queryKey = page.queryKey;
    _coreRevision = page.coreRevision;
    _generation = generation;
    _totalEntryCount = page.payload.entryCount;
    _geometryManifest = geometryManifest;
    _geometryGeneration += 1;
    _renderGeneration += 1;
    _highestCommittedOrdinal = page.ordinal;
    _initialPreviewOrdinal = page.ordinal;
    _visibleStart = 0;
    _visibleEnd = page.rowCount;
    _retainingBackward = false;
    // A rail settle still only swaps an already-ready rail scene. The bounded
    // root fallback below is scheduled *after* this synchronous commit when a
    // surface width is known; no TextPainter work runs on the settle stack.
    _verticalRenderingActive = false;
    _rootFallbackGeneration += 1;
    _rootFallbackPreparing = false;
    _rootPage = page;
    _rootEstimatedBytes = _estimatePageBytes(page, prepared: null);
    _rememberCursorAnchor(page);
    _nextCursor = page.nextCursor;
    _desiredForwardOrdinal = page.ordinal;
    _endReachedReported = false;
    _endReachedCount = 0;
    _rootPageInvariantReported = false;
    _rootNotDrawableCount = 0;
    _virtualPageMissCount = 0;
    _virtualGeometryMismatchCount = 0;
    _reportedVirtualPageMisses.clear();
    _pagePreparationUiMicros = 0;
    _largestPagePreparationUiSliceMicros = 0;
    _pagePreparationYieldCount = 0;
    _pagePreparationActive = false;
    _lastCommitRejection = null;
    _refreshEstimatedBytes();
    _presentationGeneration += 1;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_COMMITTED',
        queryKey: page.queryKey.value,
        entryCount: page.rowCount,
      ),
    );
    _reportForwardEndReachedIfNeeded(page.ordinal, advancedFrontier: true);
    notifyListeners();
    _notifyResourceChanges();
    _scheduleRootFallbackPreparation();
  }

  /// Atomically commits a complete decoded/page-projected payload. A stale
  /// page never replaces, extends, or partially mutates the cache.
  bool commit(CommittedLogPage page) {
    _ensureUsable();
    final rejection = _rejectionFor(page);
    if (rejection != null) return _reject(page, rejection);
    final existing = pageForOrdinal(page.ordinal);
    if (existing != null) return true;
    final prepareStopwatch = Stopwatch()..start();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_PRESENTATION_PREPARING',
        queryKey: page.queryKey.value,
        coreRevision: page.coreRevision,
        entryCount: page.rowCount,
        message: 'ordinal=${page.ordinal}',
      ),
    );
    CommittedPreparedLogPage? prepared;
    try {
      prepared = _preparePage(page);
    } on Object catch (error) {
      _reject(
        page,
        CommittedLogPageCommitRejection.prepareFailure,
        error: error,
      );
      rethrow;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_PRESENTATION_READY',
        queryKey: page.queryKey.value,
        coreRevision: page.coreRevision,
        entryCount: page.rowCount,
        durationMs: prepareStopwatch.elapsedMilliseconds,
        message: 'ordinal=${page.ordinal}',
      ),
    );
    return _commitPreparedPage(page, prepared: prepared);
  }

  /// Prepares one complete page privately in actual-work-budgeted slices and
  /// publishes it atomically only after every row/header resource is ready.
  ///
  /// [canPublish] is checked before every slice and after every cooperative
  /// yield. A structural/query supersession therefore disposes private
  /// TextPainters instead of letting an obsolete or partial page escape.
  Future<bool> prepareAndCommit(
    CommittedLogPage page, {
    required bool Function() canPublish,
  }) async {
    _ensureUsable();
    final initialRejection = _rejectionFor(page);
    if (initialRejection != null) return _reject(page, initialRejection);
    final existing = pageForOrdinal(page.ordinal);
    if (existing != null) return true;
    final width = _surfaceWidth;
    if (width == null) {
      if (!canPublish()) return false;
      return _commitPreparedPage(page, prepared: null);
    }

    final preparation = _PrivateCommittedPagePreparation(
      page: page,
      surfaceWidth: width,
    );
    final totalStopwatch = Stopwatch()..start();
    final yieldsAtStart = _pagePreparationYieldCount;
    _pagePreparationActive = true;
    try {
      while (!preparation.isComplete) {
        if (!canPublish()) return false;
        final sliceStarted = _pagePreparationNowMicros();
        while (!preparation.isComplete) {
          preparation.prepareNext();
          final elapsed = _nonNegativeMicros(
            _pagePreparationNowMicros() - sliceStarted,
          );
          if (elapsed >= pagePreparationPolicy.contiguousUiBudgetMicros &&
              !preparation.isComplete) {
            _recordPagePreparationSlice(elapsed);
            _pagePreparationYieldCount += 1;
            await _yieldPagePreparation();
            break;
          }
        }
        if (preparation.isComplete) {
          _recordPagePreparationSlice(
            _nonNegativeMicros(_pagePreparationNowMicros() - sliceStarted),
          );
        }
      }
      if (!canPublish()) return false;
      final prepared = preparation.takePreparedPage();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_PAGE_PRESENTATION_READY',
          queryKey: page.queryKey.value,
          coreRevision: page.coreRevision,
          entryCount: page.rowCount,
          durationMs: totalStopwatch.elapsedMilliseconds,
          message:
              'ordinal=${page.ordinal} uiMicros='
              '${totalStopwatch.elapsedMicroseconds} '
              'yieldCount=${_pagePreparationYieldCount - yieldsAtStart}',
        ),
      );
      if (!canPublish()) {
        prepared.dispose();
        return false;
      }
      final committed = _commitPreparedPage(page, prepared: prepared);
      if (!committed) prepared.dispose();
      return committed;
    } finally {
      preparation.dispose();
      _pagePreparationActive = false;
    }
  }

  bool _commitPreparedPage(
    CommittedLogPage page, {
    required CommittedPreparedLogPage? prepared,
  }) {
    final rejection = _rejectionFor(page);
    if (rejection != null) return _reject(page, rejection);
    final existing = pageForOrdinal(page.ordinal);
    if (existing != null) return true;
    final previousReadyFrontier = highestReadyPageOrdinal;
    _pages[page.ordinal] = page;
    _touchPage(page.ordinal);
    _rememberCursorAnchor(page);
    if (prepared != null) _preparedPages[page.ordinal] = prepared;
    final pageBytes = _estimatePageBytes(page, prepared: prepared);
    _pageEstimatedBytes[page.ordinal] = pageBytes;
    _retainedPageEstimatedBytes += pageBytes;
    if (page.ordinal > _highestCommittedOrdinal) {
      _highestCommittedOrdinal = page.ordinal;
      _nextCursor = page.nextCursor;
    }
    // Page readiness is resource state only. The full virtual geometry was
    // published atomically with the committed scope and cannot change here.
    _refreshEstimatedBytes();
    _retainVisibleWindow();
    _lastCommitRejection = null;
    _presentationGeneration += 1;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_COMMITTED',
        queryKey: page.queryKey.value,
        coreRevision: page.coreRevision,
        entryCount: page.rowCount,
        message: 'ordinal=${page.ordinal} retainedPages=$retainedPageCount',
      ),
    );
    if (highestReadyPageOrdinal > previousReadyFrontier) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_READY_FRONTIER_ADVANCED',
          queryKey: page.queryKey.value,
          coreRevision: page.coreRevision,
          entryCount: contiguousReadyRowCount,
          message:
              'fromOrdinal=$previousReadyFrontier toOrdinal='
              '$highestReadyPageOrdinal virtualExtent='
              '${contentHeight.round()} nextCursorDigest='
              '${_cursorDigest(_nextCursor)}',
        ),
      );
    }
    _reportForwardEndReachedIfNeeded(
      page.ordinal,
      advancedFrontier: page.ordinal > previousReadyFrontier,
    );
    // A resource commit can only repaint. It deliberately does not notify the
    // structural listener that owns the `SizedBox`/scroll extent.
    _renderGeneration += 1;
    _notifyResourceChanges();
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
    final previousStart = _visibleStart;
    if (start != previousStart) _retainingBackward = start < previousStart;
    _visibleStart = start;
    _visibleEnd = end;
    _touchVisiblePages();
    _retainVisibleWindow();
    _presentationGeneration += 1;
    _refreshEstimatedBytes();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_DRAWABLE_WINDOW_CHANGED',
        queryKey: _queryKey?.value,
        entryCount: visibleEntryCount,
        message: 'start=$start end=$end retainedPages=$retainedPageCount',
      ),
    );
    _renderGeneration += 1;
    _notifyResourceChanges();
  }

  /// Records a bounded, monotonic target only. It starts neither I/O nor text
  /// work; the paging coordinator owns those operations.
  bool updateForwardDemand(
    int desiredOrdinal, {
    String? trigger,
    int? firstVisibleOrdinal,
    int? lastVisibleOrdinal,
    double? distanceToDrawableEnd,
  }) {
    _ensureUsable();
    final lastOrdinal = _totalEntryCount == 0
        ? 0
        : (_totalEntryCount - 1) ~/ pageSize;
    final normalized = desiredOrdinal.clamp(0, lastOrdinal).toInt();
    if (normalized <= _desiredForwardOrdinal) return false;
    _desiredForwardOrdinal = normalized;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_DEMAND_CHANGED',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        message:
            'desiredLastReadyOrdinal=$_desiredForwardOrdinal '
            'highestReadyOrdinal=$highestReadyPageOrdinal '
            'trigger=${trigger ?? 'unspecified'} '
            'firstVisible=${firstVisibleOrdinal ?? -1} '
            'lastVisible=${lastVisibleOrdinal ?? -1} '
            'distanceToEnd=${distanceToDrawableEnd?.round() ?? -1}',
      ),
    );
    return true;
  }

  CommittedLogPage? pageForOrdinal(int ordinal) {
    if (ordinal != 0) return _pages[ordinal];
    final root = _rootPage;
    if (root != null) return root;
    _recordRootPageInvariantFailure();
    return null;
  }

  CommittedPreparedLogPage? preparedPageForOrdinal(int ordinal) =>
      _preparedPages[ordinal];

  CommittedLogPageCursorAnchor? cursorAnchorForOrdinal(int ordinal) =>
      _cursorAnchors[ordinal];

  /// Maps immutable full-scope geometry. Resource eviction never changes
  /// these answers, which is what keeps Flutter's content dimensions stable.
  int pageOrdinalForOffset(double offset) =>
      _geometryManifest?.pageOrdinalForOffset(offset) ?? 0;

  double pageTopForOrdinal(int ordinal) =>
      _geometryManifest?.pageForOrdinal(ordinal)?.top ?? 0;

  double pageHeightForOrdinal(int ordinal) =>
      _geometryManifest?.pageForOrdinal(ordinal)?.extent ?? 0;

  /// Binds the normal visible surface width. This is an explicit page
  /// preparation step, never a paint-time fallback. Existing ready pages are
  /// rebuilt transactionally on an orientation/width change.
  void configureSurfaceWidth(double width) {
    _ensureUsable();
    if (!width.isFinite || width <= 0) {
      throw ArgumentError.value(width, 'width');
    }
    final widthChanged = _surfaceWidth != width;
    _surfaceWidth = width;
    if (!_verticalRenderingActive) {
      if (widthChanged) {
        // A root fallback is exact-width text layout. Invalidate both a
        // completed old-width page and a pending old-width microtask before
        // scheduling the replacement; the root must never become drawable at
        // the prior geometry after rotation/resizing.
        _rootFallbackGeneration += 1;
        _rootFallbackPreparing = false;
        _disposePreparedPages();
        _recalculateRetainedPageEstimatedBytes();
        _refreshRootEstimatedBytes();
        _refreshEstimatedBytes();
      }
      _scheduleRootFallbackPreparation();
      return;
    }
    if (_preparedPages.length == _pages.length &&
        _preparedPages.values.every((page) => page.surfaceWidth == width)) {
      return;
    }
    final next = <int, CommittedPreparedLogPage>{};
    try {
      for (final entry in _pages.entries) {
        if (entry.key == _initialPreviewOrdinal) continue;
        next[entry.key] = _buildPreparedPage(entry.value, width);
      }
      final root = _rootPage;
      if (root != null) {
        next[_initialPreviewOrdinal] = _buildPreparedPage(root, width);
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
    _preparedPages.addAll(next);
    _recalculateRetainedPageEstimatedBytes();
    _refreshEstimatedBytes();
    _presentationGeneration += 1;
    _renderGeneration += 1;
    _notifyResourceChanges();
  }

  /// Makes the committed virtual surface usable for a real vertical scroll.
  /// It is deliberately invoked from user scroll-start, never rail motion or
  /// a rail-settle callback. Publication is atomic: either every retained
  /// non-preview page has its exact-width text resources. Page zero is backed
  /// either by its exact active rail scene or by the asynchronously prepared
  /// bounded root fallback; promotion itself never does paragraph work.
  bool activateVerticalRendering({bool hasExactRailScene = false}) {
    _ensureUsable();
    if (_verticalRenderingActive) return true;
    final width = _surfaceWidth;
    if (width == null || !hasExactCommittedScope || !hasVirtualGeometry) {
      return false;
    }
    final root = _rootPage;
    final manifest = _geometryManifest!;
    // The rail is permitted to own a bounded preview while no vertical scroll
    // is active. It is never permitted to become a partial page in the
    // committed virtual renderer: promotion requires the root payload to
    // exactly match page zero of the immutable manifest.
    if (root != null && !_matchesManifestPage(root, manifest)) {
      _reject(root, CommittedLogPageCommitRejection.geometryMismatch);
      return false;
    }
    final rootHasRows = root?.rowCount != 0;
    if (rootHasRows && !hasExactRailScene && !hasDrawableRootFallback) {
      _recordRootNotDrawable();
      _scheduleRootFallbackPreparation();
      return false;
    }
    final rootFallback = hasDrawableRootFallback
        ? _preparedPages[_initialPreviewOrdinal]
        : null;
    final next = <int, CommittedPreparedLogPage>{};
    try {
      for (final entry in _pages.entries) {
        if (entry.key == _initialPreviewOrdinal) continue;
        final existing = _preparedPages[entry.key];
        next[entry.key] =
            existing != null &&
                existing.surfaceWidth == width &&
                identical(existing.page, entry.value)
            ? existing
            : _buildPreparedPage(entry.value, width);
      }
      if (root != null && rootFallback != null) {
        next[_initialPreviewOrdinal] = rootFallback;
      }
    } on Object {
      for (final page in next.values) {
        page.dispose();
      }
      rethrow;
    }
    _disposePreparedPages(preserve: next.values.toSet());
    _preparedPages.addAll(next);
    _recalculateRetainedPageEstimatedBytes();
    _verticalRenderingActive = true;
    _refreshEstimatedBytes();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_VIRTUAL_GEOMETRY_ACTIVATED',
        queryKey: manifest.queryKey.value,
        coreRevision: manifest.coreRevision,
        entryCount: manifest.totalEntryCount,
        message:
            'virtualPageCount=${manifest.totalPageCount} '
            'virtualExtent=${manifest.totalExtent.round()} '
            'pageSize=${manifest.pageSize} '
            'geometrySeedBucketCount=${manifest.dayBuckets.length} '
            'estimatedGeometryBytes=${manifest.estimatedBytes} '
            'geometryGeneration=$_geometryGeneration',
      ),
    );
    // The full exact virtual geometry was published with the committed scope.
    // Activation merely selects that immutable surface; later resource commits
    // cannot publish another runway or mutate metrics during ballistic scroll.
    _presentationGeneration += 1;
    _renderGeneration += 1;
    notifyListeners();
    _notifyResourceChanges();
    return true;
  }

  DashboardLogViewportItemViewModel? rowAt(int logicalRow) {
    if (logicalRow < 0) return null;
    final page = pageForOrdinal(logicalRow ~/ pageSize);
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
    _renderGeneration += 1;
    _notifyResourceChanges();
  }

  /// Emits one bounded summary when the user ends a vertical scroll. This is
  /// deliberately cache-owned and never emitted for individual scroll samples.
  void recordScrollStarted({required double scrollOffset}) {
    if (!hasExactCommittedScope) return;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_SCROLL_STARTED',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        entryCount: contiguousReadyRowCount,
        message:
            'offset=${scrollOffset.round()} highestReady='
            '$highestReadyPageOrdinal retainedPages=$retainedPageCount',
      ),
    );
  }

  void recordScrollSummary({
    required double scrollOffset,
    required int firstVisibleOrdinal,
    required int lastVisibleOrdinal,
    required int lastPossibleOrdinal,
    required double distanceToDrawableEnd,
  }) {
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
            'cacheBytes=$estimatedBytes firstVisible=$firstVisibleOrdinal '
            'lastVisible=$lastVisibleOrdinal '
            'highestReady=$highestReadyPageOrdinal '
            'desiredForward=$desiredForwardOrdinal '
            'lastPossible=$lastPossibleOrdinal '
            'distanceToEnd=${distanceToDrawableEnd.round()} '
            'hasMorePages=$hasMorePages',
      ),
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_SCROLL_ENDED',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        entryCount: contiguousReadyRowCount,
        message: 'offset=${scrollOffset.round()}',
      ),
    );
  }

  Map<String, Object?> report() => <String, Object?>{
    'state': hasExactCommittedScope ? 'ready' : 'unbound',
    'renderingActive': isVerticalRenderingActive,
    'queryKey': _queryKey?.value,
    'coreRevision': _coreRevision,
    'generation': _generation,
    'totalRows': totalEntryCount,
    'loadedRows': loadedEntryCount,
    'readyRows': contiguousReadyRowCount,
    'highestReadyOrdinal': highestReadyPageOrdinal,
    'readyExtent': drawableExtent,
    'virtualExtent': contentHeight,
    'virtualPageCount': totalPageCount,
    'geometryGeneration': geometryGeneration,
    'renderGeneration': renderGeneration,
    'discoveredPages': discoveredPageCount,
    'drawableExtent': drawableExtent,
    'desiredForwardOrdinal': desiredForwardOrdinal,
    'visibleRows': visibleEntryCount,
    'visibleStart': _visibleStart,
    'visibleEnd': _visibleEnd,
    'retainedPages': retainedPageCount,
    'maximumRetainedPages': maximumRetainedPages,
    'retainedOrdinals': _retainedOrdinals(),
    'retainedRows': retainedRowCount,
    'rootPagePresent': rootPagePresent,
    'rootPageViewportId': rootPageViewportId,
    'rootPageRows': rootPageRows,
    'rootPageUsesRailScene': rootPageUsesRailScene,
    'preparedTextRows': preparedTextRowCount,
    'preparedDayHeaders': preparedDayHeaderCount,
    'cacheBytes': estimatedBytes,
    'maximumRetainedBytes': maximumRetainedBytes,
    'retentionBudgetOverflows': _retentionBudgetOverflowCount,
    'retentionHotsetOrdinals': _retentionHotset.toList()..sort(),
    'geometryBytes': geometryBytes,
    'cursorAnchors': _cursorAnchors.length,
    'maximumCursorAnchors': maximumCursorAnchors,
    'textLayoutMisses': textLayoutMissCount,
    'pageCommitRejects': pageCommitRejectCount,
    'lastCommitRejection': lastCommitRejection?.name,
    'evictedPages': evictedPageCount,
    'hasMorePages': hasMorePages,
    'endReachedCount': endReachedCount,
    'pageFailures': pageFailureCount,
    'rootNotDrawableCount': rootNotDrawableCount,
    'virtualPageMissCount': virtualPageMissCount,
    'virtualGeometryMismatchCount': virtualGeometryMismatchCount,
    'pagePreparationUiMicros': pagePreparationUiMicros,
    'largestPagePreparationUiSliceMicros': largestPagePreparationUiSliceMicros,
    'pagePreparationYieldCount': pagePreparationYieldCount,
    'pagePreparationActive': isPagePreparationActive,
    'maximumForwardLookaheadPages': maximumForwardLookaheadPages,
    'lastError': lastError,
  };

  CommittedLogPageCommitRejection? _rejectionFor(CommittedLogPage page) {
    if (page.queryKey != _queryKey) {
      return CommittedLogPageCommitRejection.queryMismatch;
    }
    if (page.coreRevision != _coreRevision) {
      return CommittedLogPageCommitRejection.revisionMismatch;
    }
    if (page.generation != _generation) {
      return CommittedLogPageCommitRejection.generationMismatch;
    }
    if (page.payload.entryCount != _totalEntryCount) {
      return CommittedLogPageCommitRejection.totalCountMismatch;
    }
    if (page.rowCount > pageSize) {
      return CommittedLogPageCommitRejection.pageSizeViolation;
    }
    final manifest = _geometryManifest;
    if (manifest == null || !_matchesManifestPage(page, manifest)) {
      return CommittedLogPageCommitRejection.geometryMismatch;
    }
    final existing = pageForOrdinal(page.ordinal);
    if (existing != null && existing.contentDigest != page.contentDigest) {
      return CommittedLogPageCommitRejection.duplicateDigestMismatch;
    }
    if (page.ordinal > _highestCommittedOrdinal + 1) {
      return CommittedLogPageCommitRejection.nonContiguousOrdinal;
    }
    return null;
  }

  bool _reject(
    CommittedLogPage page,
    CommittedLogPageCommitRejection reason, {
    Object? error,
  }) {
    _pageCommitRejectCount += 1;
    _stalePageDiscardCount += 1;
    _lastCommitRejection = reason;
    if (reason == CommittedLogPageCommitRejection.geometryMismatch) {
      _virtualGeometryMismatchCount += 1;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_VIRTUAL_GEOMETRY_MISMATCH',
          queryKey: page.queryKey.value,
          coreRevision: page.coreRevision,
          entryCount: page.rowCount,
          error: error?.toString(),
          message:
              'ordinal=${page.ordinal} expectedRows='
              '${_geometryManifest?.pageForOrdinal(page.ordinal)?.rowCount ?? -1} '
              'expectedGroups='
              '${_geometryManifest?.pageForOrdinal(page.ordinal)?.groupCount ?? -1} '
              'actualGroups=${page.payload.groupCount}',
        ),
      );
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_COMMIT_REJECTED',
        queryKey: page.queryKey.value,
        coreRevision: page.coreRevision,
        entryCount: page.rowCount,
        error: error?.toString(),
        message:
            'requestedOrdinal=${page.ordinal} pageOrdinal=${page.ordinal} '
            'requestGeneration=${page.generation} '
            'cacheGeneration=${_generation ?? -1} '
            'requestRevision=${page.coreRevision} '
            'cacheRevision=${_coreRevision ?? -1} '
            'pageEntryCount=${page.payload.entryCount} '
            'cacheTotalEntryCount=$_totalEntryCount rowCount=${page.rowCount} '
            'pageSize=$pageSize reason=${reason.name}',
      ),
    );
    return false;
  }

  void _retainVisibleWindow() {
    if (_pages.length <= maximumRetainedPages) {
      _refreshEstimatedBytes();
      return;
    }
    final visibleFirst = _visibleStart ~/ pageSize;
    final visibleLast = _visibleEnd <= _visibleStart
        ? visibleFirst
        : (_visibleEnd - 1) ~/ pageSize;
    final orderedTarget = _retentionTargetOrdinals(
      visibleFirst: visibleFirst,
      visibleLast: visibleLast,
    );
    final target = orderedTarget.toSet();
    _retentionHotset = target;
    final evicted = _pages.keys
        .where((ordinal) => !target.contains(ordinal))
        .toList();
    for (final ordinal in evicted) {
      _evictPage(ordinal);
    }
    _refreshEstimatedBytes();
    // Bytes remain a stricter secondary bound. It can only shrink an already
    // hard-bounded five-page working set; it can never expand it.
    while (_estimatedBytes > maximumRetainedBytes) {
      int? candidate;
      for (final ordinal in orderedTarget.reversed) {
        if ((ordinal >= visibleFirst && ordinal <= visibleLast) ||
            ordinal == _initialPreviewOrdinal) {
          continue;
        }
        candidate = ordinal;
        break;
      }
      if (candidate == null) {
        _retentionBudgetOverflowCount += 1;
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'VERTICAL_RETENTION_BUDGET_EXCEEDED',
            queryKey: _queryKey?.value,
            entryCount: retainedRowCount,
            error: 'Protected committed page bank exceeds byte budget.',
            message:
                'retainedBytes=$_estimatedBytes maximumRetainedBytes='
                '$maximumRetainedBytes protectedOrdinals='
                '${target.toList()..sort()}',
          ),
        );
        break;
      }
      _evictPage(candidate);
      evicted.add(candidate);
      orderedTarget.remove(candidate);
      target.remove(candidate);
      _refreshEstimatedBytes();
    }
    if (evicted.isEmpty) return;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_EVICTED',
        queryKey: _queryKey?.value,
        entryCount: evicted.length,
        message:
            'ordinals=${evicted..sort()} reason=workingSet '
            'retainedPages=$retainedPageCount retainedBytes=$_estimatedBytes '
            'maximumRetainedPages=$maximumRetainedPages '
            'maximumRetainedBytes=$maximumRetainedBytes',
      ),
    );
  }

  List<int> _retentionTargetOrdinals({
    required int visibleFirst,
    required int visibleLast,
  }) {
    final ordered = <int>[];

    void addIfRetained(int ordinal) {
      if (ordinal > 0 &&
          _pages.containsKey(ordinal) &&
          !ordered.contains(ordinal)) {
        ordered.add(ordinal);
      }
    }

    // Current drawable pages always take precedence. A normal viewport spans
    // one or two committed ordinals.
    for (var ordinal = visibleFirst; ordinal <= visibleLast; ordinal += 1) {
      addIfRetained(ordinal);
    }
    final primaryForward = !_retainingBackward;
    // While moving backward, retain immediate reversal history first. While
    // moving forward, reserve the next drawable pages first so a demand does
    // not evict its own approaching frontier.
    if (!primaryForward) {
      for (
        var ordinal = visibleFirst - 1;
        ordinal >= 1 && ordered.length < maximumRetainedPages;
        ordinal -= 1
      ) {
        addIfRetained(ordinal);
      }
    }
    final requestedForward = _desiredForwardOrdinal
        .clamp(visibleLast, highestReadyPageOrdinal)
        .toInt();
    final normalForwardSafety = (visibleLast + maximumForwardLookaheadPages)
        .clamp(visibleLast, highestReadyPageOrdinal)
        .toInt();
    final forwardMaximum = requestedForward > normalForwardSafety
        ? requestedForward
        : normalForwardSafety;
    for (
      var ordinal = visibleLast + 1;
      ordinal <= forwardMaximum && ordered.length < maximumRetainedPages;
      ordinal += 1
    ) {
      addIfRetained(ordinal);
    }
    if (primaryForward) {
      for (
        var ordinal = visibleFirst - 1;
        ordinal >= 1 && ordered.length < maximumRetainedPages;
        ordinal -= 1
      ) {
        addIfRetained(ordinal);
      }
    }
    // If the requested safety bank was shorter than the cap, use LRU recency
    // as a deterministic local remainder without exceeding the hard bound.
    final remaining =
        _pages.keys.where((ordinal) => !ordered.contains(ordinal)).toList()
          ..sort(
            (left, right) => (_pageRetentionTouches[right] ?? 0).compareTo(
              _pageRetentionTouches[left] ?? 0,
            ),
          );
    for (final ordinal in remaining) {
      if (ordered.length >= maximumRetainedPages) break;
      ordered.add(ordinal);
    }
    return ordered;
  }

  void _evictPage(int ordinal) {
    _pages.remove(ordinal);
    _pageRetentionTouches.remove(ordinal);
    _preparedPages.remove(ordinal)?.dispose();
    _retainedPageEstimatedBytes -= _pageEstimatedBytes.remove(ordinal) ?? 0;
    _evictedPageCount += 1;
  }

  void _touchPage(int ordinal) {
    if (ordinal <= 0) return;
    _retentionTick += 1;
    _pageRetentionTouches[ordinal] = _retentionTick;
  }

  void _touchVisiblePages() {
    final first = _visibleStart ~/ pageSize;
    final last = _visibleEnd <= _visibleStart
        ? first
        : (_visibleEnd - 1) ~/ pageSize;
    for (var ordinal = first; ordinal <= last; ordinal += 1) {
      _touchPage(ordinal);
    }
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('Committed LogBox viewport cache is disposed.');
    }
  }

  bool _matchesManifestPage(
    CommittedLogPage page,
    CommittedVerticalGeometryManifest manifest,
  ) {
    final expected = manifest.pageForOrdinal(page.ordinal);
    if (expected == null) {
      // An empty exact scope is represented by its bounded empty root payload
      // and has no logical virtual page.
      return manifest.totalEntryCount == 0 &&
          page.ordinal == 0 &&
          page.rowCount == 0 &&
          page.payload.groupCount == 0;
    }
    return expected.rowCount == page.rowCount &&
        expected.groupCount == page.payload.groupCount;
  }

  void _notifyResourceChanges() {
    if (!_disposed) _resourceChanges.notifyListeners();
  }

  /// Reports one fail-closed resource miss per virtual ordinal and scope.
  /// Geometry remains intact; this is diagnostic evidence that the bounded
  /// hotset failed to have exact content ready before it became visible.
  void recordVirtualPageMiss({
    required int ordinal,
    required double scrollOffset,
    required String direction,
  }) {
    if (!hasExactCommittedScope || ordinal < 0 || ordinal >= totalPageCount) {
      return;
    }
    if (!_reportedVirtualPageMisses.add(ordinal)) return;
    _virtualPageMissCount += 1;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_VIRTUAL_PAGE_MISS',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        message:
            'ordinal=$ordinal scrollOffset=${scrollOffset.round()} '
            'direction=$direction retained=${_retainedOrdinals()} '
            'prepared=${_preparedPages.keys.toList()..sort()}',
      ),
    );
  }

  List<int> _retainedOrdinals() {
    final ordinals = _pages.keys.toList();
    if (_rootPage != null) ordinals.add(0);
    ordinals.sort();
    return ordinals;
  }

  void _recordRootPageInvariantFailure() {
    if (_rootPageInvariantReported || !hasExactCommittedScope) return;
    _rootPageInvariantReported = true;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'ROOT_PAGE_INVARIANT_FAILED',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        error: 'An exact committed scope lost pinned page zero.',
      ),
    );
  }

  void _reportForwardEndReachedIfNeeded(
    int ordinal, {
    required bool advancedFrontier,
  }) {
    if (_endReachedReported ||
        !advancedFrontier ||
        _nextCursor != null ||
        contiguousReadyRowCount != totalEntryCount) {
      return;
    }
    _endReachedReported = true;
    _endReachedCount += 1;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_END_REACHED',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        entryCount: contiguousReadyRowCount,
        message: 'ordinal=$ordinal',
      ),
    );
  }

  void _rememberCursorAnchor(CommittedLogPage page) {
    _cursorAnchors[page.ordinal] = CommittedLogPageCursorAnchor(page);
    while (_cursorAnchors.length > maximumCursorAnchors) {
      _cursorAnchors.remove(_cursorAnchors.keys.first);
    }
  }

  String _cursorDigest(Map<String, Object?>? cursor) {
    if (cursor == null) return 'end';
    final fields =
        cursor.entries.map((entry) => '${entry.key}=${entry.value}').toList()
          ..sort();
    return Object.hashAll(fields).toRadixString(16);
  }

  CommittedPreparedLogPage? _preparePage(CommittedLogPage page) {
    // Layout is always prepared before a page becomes drawable and never from
    // build/layout/paint. Idle ready-ahead is normal; a current exact page may
    // also arrive from live same-scope demand before the frontier is reached.
    final width = _surfaceWidth;
    return width == null ? null : _buildPreparedPage(page, width);
  }

  int _pagePreparationNowMicros() =>
      pagePreparationPolicy.nowMicros?.call() ??
      _pagePreparationClock.elapsedMicroseconds;

  Future<void> _yieldPagePreparation() =>
      pagePreparationPolicy.yieldToEventTurn?.call() ??
      // An event-turn handoff is intentionally weaker than a next-frame
      // guarantee. It lets input/render tasks run before another bounded
      // resource slice without altering the global scheduler strategy.
      Future<void>(() {});

  static int _nonNegativeMicros(int value) => value < 0 ? 0 : value;

  void _recordPagePreparationSlice(int elapsedMicros) {
    _pagePreparationUiMicros += elapsedMicros;
    if (elapsedMicros > _largestPagePreparationUiSliceMicros) {
      _largestPagePreparationUiSliceMicros = elapsedMicros;
    }
  }

  /// Builds the root safety net after layout, never in a rail-settle callback.
  /// It remains private until vertical rendering is explicitly promoted.
  void _scheduleRootFallbackPreparation() {
    if (_disposed || _rootFallbackPreparing || hasDrawableRootFallback) return;
    final root = _rootPage;
    final width = _surfaceWidth;
    if (root == null || width == null || root.rowCount == 0) return;
    final generation = ++_rootFallbackGeneration;
    _rootFallbackPreparing = true;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_ROOT_FALLBACK_PREPARE_STARTED',
        queryKey: root.queryKey.value,
        coreRevision: root.coreRevision,
        entryCount: root.rowCount,
      ),
    );
    unawaited(
      Future<void>.microtask(() {
        if (_disposed || generation != _rootFallbackGeneration) return;
        final prepared = _buildPreparedPage(root, width);
        if (_disposed ||
            generation != _rootFallbackGeneration ||
            _surfaceWidth != width ||
            !identical(_rootPage, root)) {
          prepared.dispose();
          return;
        }
        _preparedPages.remove(_initialPreviewOrdinal)?.dispose();
        _preparedPages[_initialPreviewOrdinal] = prepared;
        _refreshRootEstimatedBytes();
        _rootFallbackPreparing = false;
        _refreshEstimatedBytes();
        _presentationGeneration += 1;
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'VERTICAL_ROOT_FALLBACK_READY',
            queryKey: root.queryKey.value,
            coreRevision: root.coreRevision,
            entryCount: root.rowCount,
          ),
        );
        // Root-fallback availability can switch the render domain before a
        // drag starts, so this one-time scope transition is structural. Normal
        // page commits never use the structural listener.
        notifyListeners();
        _renderGeneration += 1;
        _notifyResourceChanges();
      }).whenComplete(() {
        if (!_disposed && generation == _rootFallbackGeneration) {
          _rootFallbackPreparing = false;
        }
      }),
    );
  }

  void _recordRootNotDrawable() {
    _rootNotDrawableCount += 1;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_ROOT_NOT_DRAWABLE',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        entryCount: _rootPage?.rowCount,
        error: 'Committed root has neither an active rail scene nor fallback.',
      ),
    );
  }

  CommittedPreparedLogPage _buildPreparedPage(
    CommittedLogPage page,
    double width,
  ) {
    final preparation = _PrivateCommittedPagePreparation(
      page: page,
      surfaceWidth: width,
    );
    try {
      while (!preparation.isComplete) {
        preparation.prepareNext();
      }
      return preparation.takePreparedPage();
    } finally {
      preparation.dispose();
    }
  }

  void _disposePreparedPages({Set<CommittedPreparedLogPage>? preserve}) {
    for (final page in _preparedPages.values) {
      if (preserve?.contains(page) != true) page.dispose();
    }
    _preparedPages.clear();
  }

  void _refreshEstimatedBytes() {
    // Cursor anchors have their own strict cap, but are included in the same
    // diagnostic budget so the retained-memory report is not optimistic.
    _estimatedBytes =
        _rootEstimatedBytes +
        _retainedPageEstimatedBytes +
        _cursorAnchors.length * _cursorAnchorEstimatedBytes;
  }

  static const int _pageMetadataEstimatedBytes = 512;
  static const int _preparedRowEstimatedBytes = 2048;
  static const int _preparedDayHeaderEstimatedBytes = 1024;
  static const int _cursorAnchorEstimatedBytes = 128;

  int _estimatePageBytes(
    CommittedLogPage page, {
    required CommittedPreparedLogPage? prepared,
  }) {
    var textUnits = 0;
    for (final item in page.payload.flatItems) {
      final row = item.row;
      textUnits +=
          row.entryId.length +
          row.displayName.length +
          row.categoryDisplayName.length +
          row.formattedAmount.length +
          row.displayTime.length;
    }
    return _pageMetadataEstimatedBytes +
        textUnits * 2 +
        (prepared?.rowLayoutCount ?? 0) * _preparedRowEstimatedBytes +
        (prepared?.dayHeaderCount ?? 0) * _preparedDayHeaderEstimatedBytes;
  }

  void _refreshRootEstimatedBytes() {
    final root = _rootPage;
    _rootEstimatedBytes = root == null
        ? 0
        : _estimatePageBytes(
            root,
            prepared: _preparedPages[_initialPreviewOrdinal],
          );
  }

  void _recalculateRetainedPageEstimatedBytes() {
    _retainedPageEstimatedBytes = 0;
    _pageEstimatedBytes.clear();
    for (final entry in _pages.entries) {
      final bytes = _estimatePageBytes(
        entry.value,
        prepared: _preparedPages[entry.key],
      );
      _pageEstimatedBytes[entry.key] = bytes;
      _retainedPageEstimatedBytes += bytes;
    }
    _refreshRootEstimatedBytes();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pages.clear();
    _rootPage = null;
    _cursorAnchors.clear();
    _disposePreparedPages();
    _geometryManifest = null;
    _nextCursor = null;
    _resourceChanges.dispose();
    super.dispose();
  }
}

/// Prepared text resources for one complete committed page. It is created as
/// one unit before publication so a renderer cannot observe an avatar-only
/// or header-less row.
/// Private, resumable construction state. It is never exposed to paint: only
/// [takePreparedPage] can turn it into the immutable complete resource bank.
final class _PrivateCommittedPagePreparation {
  _PrivateCommittedPagePreparation({
    required this.page,
    required this.surfaceWidth,
  });

  final CommittedLogPage page;
  final double surfaceWidth;
  final Map<String, DashboardPreparedLogBoxRowTextLayout> _rows =
      <String, DashboardPreparedLogBoxRowTextLayout>{};
  final Map<String, TextPainter> _headers = <String, TextPainter>{};
  int _nextItemIndex = 0;
  bool _taken = false;

  bool get isComplete => _nextItemIndex >= page.payload.flatItems.length;

  void prepareNext() {
    if (isComplete) return;
    final item = page.payload.flatItems[_nextItemIndex];
    _rows[item.row.entryId] = DashboardPreparedLogBoxRowTextLayout.prepare(
      row: item.row,
      surfaceWidth: surfaceWidth,
      contentIdentity: item.row.textLayoutId,
    );
    if (item.dayLabel case final String label) {
      _headers.putIfAbsent(
        label,
        () => prepareDashboardLogBoxTextPainter(
          label,
          FluviVisualTokens.logBoxDayHeaderTextStyle,
          surfaceWidth,
        ),
      );
    }
    _nextItemIndex += 1;
  }

  CommittedPreparedLogPage takePreparedPage() {
    if (!isComplete || _taken) {
      throw StateError(
        'A prepared LogBox page can only publish once complete.',
      );
    }
    _taken = true;
    return CommittedPreparedLogPage._(
      page: page,
      surfaceWidth: surfaceWidth,
      rowLayouts: _rows,
      dayHeaders: _headers,
    );
  }

  void dispose() {
    if (_taken) return;
    for (final layout in _rows.values) {
      layout.dispose();
    }
    for (final header in _headers.values) {
      header.dispose();
    }
    _rows.clear();
    _headers.clear();
  }
}

final class CommittedPreparedLogPage {
  CommittedPreparedLogPage._({
    required this.page,
    required this.surfaceWidth,
    required Map<String, DashboardPreparedLogBoxRowTextLayout> rowLayouts,
    required Map<String, TextPainter> dayHeaders,
  }) : _rowLayouts =
           Map<String, DashboardPreparedLogBoxRowTextLayout>.unmodifiable(
             rowLayouts,
           ),
       _dayHeaders = Map<String, TextPainter>.unmodifiable(dayHeaders);

  final CommittedLogPage page;
  final double surfaceWidth;
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
