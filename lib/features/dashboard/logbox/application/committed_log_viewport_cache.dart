import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../presentation/dashboard_logbox_prepared_row_text_layout.dart';
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

/// The terminal or resumable result of preparing one decoded committed page.
///
/// A vertical input pause is neither a stale identity nor a page failure: the
/// paging coordinator retains the exact decoded page privately and retries its
/// cache-owned presentation work when that input becomes idle.
enum CommittedPagePresentationOutcome {
  committed,
  pausedForVerticalInput,
  superseded,
  rejected,
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
final class CommittedLogViewportCache extends ChangeNotifier {
  CommittedLogViewportCache({
    required this.pageSize,
    this.maximumRetainedPages = 5,
    this.maximumRetainedBytes = 2 * 1024 * 1024,
    this.maximumCursorAnchors = 8192,
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
  // Page zero is the committed scope's root. It has one bounded page of row
  // VMs and must survive local LRU rotation so reverse scroll never reaches a
  // geometry-only, blank top page.
  CommittedLogPage? _rootPage;
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
  bool _retainingBackward = false;
  int _evictedPageCount = 0;
  int _stalePageDiscardCount = 0;
  int _presentationGeneration = 0;
  int _pagePreparationGeneration = 0;
  int _observedPageReadyMicros = 0;
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
  int _frontierStallCount = 0;
  bool _endReachedReported = false;
  bool _frontierStallReported = false;
  int _endReachedCount = 0;
  int _rootFallbackGeneration = 0;
  bool _rootFallbackPreparing = false;
  bool _rootPageInvariantReported = false;
  bool _verticalRenderingActive = false;
  int _initialPreviewOrdinal = 0;
  bool _disposed = false;

  LedgerQueryKey? get queryKey => _queryKey;
  int? get coreRevision => _coreRevision;
  int? get generation => _generation;
  int get totalEntryCount => _totalEntryCount;
  int get loadedEntryCount => _geometry?.readyRowCount ?? 0;
  int get contiguousReadyRowCount => _geometry?.readyRowCount ?? 0;
  int get highestReadyPageOrdinal => _geometry?.highestReadyOrdinal ?? -1;
  int get discoveredPageCount => _geometry?.readyPageCount ?? 0;
  double get drawableExtent => _geometry?.contentHeight ?? 0;
  bool get rootPagePresent => _rootPage != null;
  int? get rootPageViewportId => _rootPage?.payload.viewportId;
  int get rootPageRows => _rootPage?.rowCount ?? 0;
  bool get rootPageUsesRailScene =>
      _rootPage != null && !hasDrawableRootFallback;
  int get endReachedCount => _endReachedCount;
  int get retainedPageCount => _pages.length;
  int get visibleEntryCount =>
      (_visibleEnd - _visibleStart).clamp(0, contiguousReadyRowCount);
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
  int get frontierStallCount => _frontierStallCount;
  double? get surfaceWidth => _surfaceWidth;
  Map<String, Object?>? get nextCursor => _nextCursor;
  bool get hasMorePages => _nextCursor != null;
  bool get isVerticalRenderingActive => _verticalRenderingActive;
  int get highestCommittedOrdinal => _highestCommittedOrdinal;
  int get desiredForwardOrdinal => _desiredForwardOrdinal;
  int get observedPageReadyMicros => _observedPageReadyMicros;
  // The root page is pinned independently. One movable slot remains for the
  // current drawable page; the remaining three retain the two-page minimum
  // safety margin plus one bounded adaptive page.
  int get maximumForwardLookaheadPages => maximumRetainedPages - 2;
  int get lowestRetainedOrdinal => _pages.isEmpty
      ? 0
      : _pages.keys.reduce((value, next) => value < next ? value : next);
  CommittedLogPage? get lowestRetainedPage => _pages[lowestRetainedOrdinal];
  double get contentHeight => drawableExtent;
  int get geometryBytes => _geometry?.estimatedBytes ?? 0;
  bool get hasExactCommittedScope =>
      _queryKey != null && _coreRevision != null && _generation != null;
  bool get hasDrawableRootFallback {
    final root = _preparedPages[_initialPreviewOrdinal];
    return root != null && root.surfaceWidth == _surfaceWidth;
  }

  bool get isRootFallbackPreparing => _rootFallbackPreparing;

  /// Clears an old structural scope and publishes the immutable first page.
  /// The supplied generation is owned by the application paging coordinator,
  /// not by an old frame or renderer callback.
  void seed(CommittedLogPage page, {required int generation}) {
    _ensureUsable();
    if (page.ordinal != 0) {
      throw ArgumentError.value(
        page.ordinal,
        'page.ordinal',
        'A committed scope must be seeded with root page zero.',
      );
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
    _geometry = _CommittedPageGeometry(pageSize: pageSize);
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
    _pagePreparationGeneration += 1;
    _rootFallbackPreparing = false;
    _rootPage = page;
    _rootEstimatedBytes = _estimatePageBytes(page, prepared: null);
    _rememberCursorAnchor(page);
    _geometry!.record(page.ordinal, _pageHeight(page.payload), page.rowCount);
    _nextCursor = page.nextCursor;
    _desiredForwardOrdinal = page.ordinal;
    _endReachedReported = false;
    _frontierStallCount = 0;
    _frontierStallReported = false;
    _endReachedCount = 0;
    _rootPageInvariantReported = false;
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

  bool _commitPreparedPage(
    CommittedLogPage page, {
    required CommittedPreparedLogPage? prepared,
  }) {
    final rejection = _rejectionFor(page);
    if (rejection != null) return _reject(page, rejection);
    final existing = pageForOrdinal(page.ordinal);
    if (existing != null) return true;
    final previousFrontier = highestReadyPageOrdinal;
    if (!_geometry!.record(
      page.ordinal,
      _pageHeight(page.payload),
      page.rowCount,
    )) {
      prepared?.dispose();
      return _reject(page, CommittedLogPageCommitRejection.geometryMismatch);
    }
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
    // The target page is now drawable. Retention may run only around the
    // actual drawable viewport, never around a speculative target ordinal;
    // otherwise a fast prefetch can evict content that is still painting.
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
    if (highestReadyPageOrdinal > previousFrontier) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_FRONTIER_ADVANCED',
          queryKey: page.queryKey.value,
          coreRevision: page.coreRevision,
          entryCount: contiguousReadyRowCount,
          message:
              'fromOrdinal=$previousFrontier toOrdinal='
              '$highestReadyPageOrdinal nextCursorDigest='
              '${_cursorDigest(_nextCursor)} drawableExtent=$drawableExtent',
        ),
      );
    }
    _reportForwardEndReachedIfNeeded(
      page.ordinal,
      advancedFrontier: page.ordinal > previousFrontier,
    );
    notifyListeners();
    return true;
  }

  /// Prepares one bounded committed page in scheduler-sized UI slices. The
  /// cache owns the private task and publishes neither geometry nor layouts
  /// until every page resource is ready.
  Future<bool> prepareAndCommit(
    CommittedLogPage page, {
    Future<void> Function()? yieldToScheduler,
    bool Function()? shouldPreempt,
    bool Function()? shouldPauseForVerticalInput,
  }) async =>
      await prepareAndCommitOutcome(
        page,
        yieldToScheduler: yieldToScheduler,
        shouldPreempt: shouldPreempt,
        shouldPauseForVerticalInput: shouldPauseForVerticalInput,
      ) ==
      CommittedPagePresentationOutcome.committed;

  /// The typed form of [prepareAndCommit]. It preserves the distinction
  /// between a stale page and a page that is valid but must wait for the
  /// stable vertical [ScrollPosition] to become idle.
  Future<CommittedPagePresentationOutcome> prepareAndCommitOutcome(
    CommittedLogPage page, {
    Future<void> Function()? yieldToScheduler,
    bool Function()? shouldPreempt,
    bool Function()? shouldPauseForVerticalInput,
  }) async {
    _ensureUsable();
    final rejection = _rejectionFor(page);
    if (rejection != null) {
      _reject(page, rejection);
      return CommittedPagePresentationOutcome.rejected;
    }
    if (pageForOrdinal(page.ordinal) != null) {
      return CommittedPagePresentationOutcome.committed;
    }
    final width = _verticalRenderingActive ? _surfaceWidth : null;
    if (width == null) {
      return _commitPreparedPage(page, prepared: null)
          ? CommittedPagePresentationOutcome.committed
          : CommittedPagePresentationOutcome.rejected;
    }
    if (shouldPauseForVerticalInput?.call() ?? false) {
      _recordPresentationDeferredForVerticalInput(page);
      return CommittedPagePresentationOutcome.pausedForVerticalInput;
    }
    final preparationGeneration = _pagePreparationGeneration;
    final started = Stopwatch()..start();
    final task = _CommittedPagePreparationTask(
      page: page,
      surfaceWidth: width,
      isCurrent: () =>
          !_disposed &&
          preparationGeneration == _pagePreparationGeneration &&
          _surfaceWidth == width &&
          _rejectionFor(page) == null &&
          pageForOrdinal(page.ordinal) == null,
      shouldPreempt: shouldPreempt,
      shouldPauseForVerticalInput: shouldPauseForVerticalInput,
      yieldToScheduler: yieldToScheduler ?? _yieldToScheduler,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_PRESENTATION_PREPARE_STARTED',
        queryKey: page.queryKey.value,
        coreRevision: page.coreRevision,
        entryCount: page.rowCount,
        message: 'pageOrdinal=${page.ordinal}',
      ),
    );
    try {
      final result = await task.prepare();
      if (result.pausedForVerticalInput) {
        _recordPresentationDeferredForVerticalInput(page);
        return CommittedPagePresentationOutcome.pausedForVerticalInput;
      }
      final prepared = result.prepared;
      if (prepared == null) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'VERTICAL_PAGE_PRESENTATION_PREPARE_SUPERSEDED',
            queryKey: page.queryKey.value,
            coreRevision: page.coreRevision,
            entryCount: page.rowCount,
            message: 'pageOrdinal=${page.ordinal}',
          ),
        );
        return CommittedPagePresentationOutcome.superseded;
      }
      if (!_commitPreparedPage(page, prepared: prepared)) {
        prepared.dispose();
        return CommittedPagePresentationOutcome.rejected;
      }
      _recordPageReadyLatency(started.elapsedMicroseconds);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_PAGE_PRESENTATION_PREPARE_READY',
          queryKey: page.queryKey.value,
          coreRevision: page.coreRevision,
          entryCount: page.rowCount,
          durationMs: started.elapsedMilliseconds,
          message:
              'pageOrdinal=${page.ordinal} '
              'uiIsolateMicros=${task.uiIsolateMicros} '
              'largestContiguousUiSliceMicros='
              '${task.largestContiguousUiSliceMicros} '
              'yieldCount=${task.yieldCount} pauseCount=${task.pauseCount} '
              'resumeCount=${task.resumeCount} '
              'newRowLayouts=${task.newRowLayouts} reusedRowLayouts=0',
        ),
      );
      return CommittedPagePresentationOutcome.committed;
    } on Object catch (error) {
      _reject(
        page,
        CommittedLogPageCommitRejection.prepareFailure,
        error: error,
      );
      rethrow;
    }
  }

  /// Emits the semantic deferral event from the presentation/cache owner. A
  /// caller may use this before starting a task when the vertical input state
  /// is already active.
  void _recordPresentationDeferredForVerticalInput(CommittedLogPage page) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_PRESENTATION_DEFERRED_FOR_INPUT',
        queryKey: page.queryKey.value,
        coreRevision: page.coreRevision,
        entryCount: page.rowCount,
        message: 'pageOrdinal=${page.ordinal}',
      ),
    );
  }

  /// Emits the matching resume event immediately before cache-owned work
  /// restarts. It never publishes a partially prepared page.
  void recordPresentationResumedAfterVerticalInput(CommittedLogPage page) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_PRESENTATION_RESUMED_AFTER_INPUT',
        queryKey: page.queryKey.value,
        coreRevision: page.coreRevision,
        entryCount: page.rowCount,
        message: 'pageOrdinal=${page.ordinal}',
      ),
    );
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
    notifyListeners();
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
    final widthChanged = _surfaceWidth != width;
    _surfaceWidth = width;
    if (widthChanged) _pagePreparationGeneration += 1;
    if (!_verticalRenderingActive) {
      if (widthChanged) {
        // A root fallback is exact-width text layout. Invalidate both a
        // completed old-width page and a pending old-width microtask before
        // scheduling the replacement; the root must never become drawable at
        // the prior geometry after rotation/resizing.
        _rootFallbackGeneration += 1;
        _rootFallbackPreparing = false;
        _preparedPages.remove(_initialPreviewOrdinal)?.dispose();
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
    notifyListeners();
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
    if (width == null || !hasExactCommittedScope) return false;
    final root = _rootPage;
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
        next[entry.key] = _buildPreparedPage(entry.value, width);
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
    _disposePreparedPages(preserve: rootFallback);
    _preparedPages.addAll(next);
    _recalculateRetainedPageEstimatedBytes();
    _verticalRenderingActive = true;
    _refreshEstimatedBytes();
    _presentationGeneration += 1;
    notifyListeners();
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
    notifyListeners();
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

  /// Emits one fail-fast diagnostic for a scope if the user reaches its
  /// drawable frontier while a next cursor still exists but no next ordinal
  /// has been demanded. The viewport remains responsible for scheduling the
  /// actual request; this cache method is deliberately side-effect free.
  void recordFrontierStall({
    required int firstVisibleOrdinal,
    required int lastVisibleOrdinal,
    required double distanceToDrawableEnd,
  }) {
    if (!hasExactCommittedScope || _frontierStallReported) return;
    _frontierStallReported = true;
    _frontierStallCount += 1;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_FRONTIER_STALL',
        queryKey: _queryKey?.value,
        coreRevision: _coreRevision,
        entryCount: contiguousReadyRowCount,
        error:
            'A drawable committed frontier had a next cursor without demand.',
        message:
            'firstVisible=$firstVisibleOrdinal lastVisible=$lastVisibleOrdinal '
            'highestReady=$highestReadyPageOrdinal '
            'desiredForward=$desiredForwardOrdinal '
            'distanceToEnd=${distanceToDrawableEnd.round()}',
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
    'frontierStallCount': frontierStallCount,
    'pageFailures': pageFailureCount,
    'observedPageReadyMicros': observedPageReadyMicros,
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
    final existing = pageForOrdinal(page.ordinal);
    if (existing != null && existing.contentDigest != page.contentDigest) {
      return CommittedLogPageCommitRejection.duplicateDigestMismatch;
    }
    if (page.ordinal > ((_geometry?.highestReadyOrdinal ?? -1) + 1)) {
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
    final width = _verticalRenderingActive ? _surfaceWidth : null;
    return width == null ? null : _buildPreparedPage(page, width);
  }

  void _recordPageReadyLatency(int elapsedMicros) {
    if (elapsedMicros <= 0) return;
    _observedPageReadyMicros = _observedPageReadyMicros == 0
        ? elapsedMicros
        : (_observedPageReadyMicros * 3 + elapsedMicros) ~/ 4;
  }

  /// Schedules the next essential private page slice below touch input, while
  /// avoiding an artificial end-of-frame delay. The test binding keeps a
  /// deterministic microtask boundary without changing production priority.
  Future<void> _yieldToScheduler() {
    if (WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      return Future<void>.microtask(() {});
    }
    return SchedulerBinding.instance.scheduleTask<void>(
      () {},
      Priority.animation,
      debugLabel: 'fluvi-committed-page-preparation',
    );
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
        notifyListeners();
      }).whenComplete(() {
        if (!_disposed && generation == _rootFallbackGeneration) {
          _rootFallbackPreparing = false;
        }
      }),
    );
  }

  void _recordRootNotDrawable() {
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
      surfaceWidth: width,
      rowLayouts: rows,
      dayHeaders: headers,
    );
  }

  void _disposePreparedPages({CommittedPreparedLogPage? preserve}) {
    for (final page in _preparedPages.values) {
      if (!identical(page, preserve)) page.dispose();
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
    _pagePreparationGeneration += 1;
    _pages.clear();
    _rootPage = null;
    _cursorAnchors.clear();
    _disposePreparedPages();
    _geometry = null;
    _nextCursor = null;
    super.dispose();
  }

  static double _pageHeight(DashboardLogViewportState payload) {
    if (payload.previewRowCount == 0) return DashboardLogBoxTokens.rowHeight;
    return payload.previewRowCount * DashboardLogBoxTokens.rowHeight +
        payload.groupCount * DashboardLogBoxTokens.dayHeaderHeight +
        (payload.groupCount - 1) * DashboardLogBoxTokens.dayGroupGap;
  }
}

/// Private, cache-owned text preparation for one immutable committed page.
/// It owns no retained resources: until [prepare] returns its completed page,
/// every TextPainter remains private and is disposed on preemption or stale
/// identity. The [CommittedLogViewportCache] alone decides publication.
final class _CommittedPagePreparationTask {
  _CommittedPagePreparationTask({
    required this.page,
    required this.surfaceWidth,
    required this.isCurrent,
    required this.shouldPreempt,
    required this.shouldPauseForVerticalInput,
    required this.yieldToScheduler,
  });

  static const int _maximumRowsPerSlice = 2;
  static const int _maximumSliceMicros = 1000;

  final CommittedLogPage page;
  final double surfaceWidth;
  final bool Function() isCurrent;
  final bool Function()? shouldPreempt;
  final bool Function()? shouldPauseForVerticalInput;
  final Future<void> Function() yieldToScheduler;

  int uiIsolateMicros = 0;
  int largestContiguousUiSliceMicros = 0;
  int yieldCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int newRowLayouts = 0;

  Future<_CommittedPagePreparationResult> prepare() async {
    final rows = <String, DashboardPreparedLogBoxRowTextLayout>{};
    final headers = <String, TextPainter>{};
    var completed = false;
    try {
      if (shouldPauseForVerticalInput?.call() ?? false) {
        return const _CommittedPagePreparationResult.pausedForVerticalInput();
      }
      // Explicitly project while this private preparation task owns the work;
      // a render/layout callback never initiates it.
      page.payload.materializeRichProjection();
      final items = page.payload.flatItems;
      var sliceStartedAt = Stopwatch()..start();
      var rowsInSlice = 0;
      for (final item in items) {
        if (!isCurrent()) {
          return const _CommittedPagePreparationResult.superseded();
        }
        if (shouldPauseForVerticalInput?.call() ?? false) {
          return const _CommittedPagePreparationResult.pausedForVerticalInput();
        }
        if (shouldPreempt?.call() ?? false) {
          pauseCount += 1;
          return const _CommittedPagePreparationResult.superseded();
        }
        rows[item.row.entryId] = DashboardPreparedLogBoxRowTextLayout.prepare(
          row: item.row,
          surfaceWidth: surfaceWidth,
          contentIdentity: item.row.textLayoutId,
        );
        newRowLayouts += 1;
        if (item.dayLabel case final String label) {
          headers[label] = prepareDashboardLogBoxTextPainter(
            label,
            FluviVisualTokens.logBoxDayHeaderTextStyle,
            surfaceWidth,
          );
        }
        rowsInSlice += 1;
        final elapsed = sliceStartedAt.elapsedMicroseconds;
        if (rowsInSlice < _maximumRowsPerSlice &&
            elapsed < _maximumSliceMicros) {
          continue;
        }
        uiIsolateMicros += elapsed;
        largestContiguousUiSliceMicros =
            largestContiguousUiSliceMicros > elapsed
            ? largestContiguousUiSliceMicros
            : elapsed;
        yieldCount += 1;
        await yieldToScheduler();
        if (!isCurrent() || (shouldPreempt?.call() ?? false)) {
          if (shouldPreempt?.call() ?? false) pauseCount += 1;
          return const _CommittedPagePreparationResult.superseded();
        }
        if (shouldPauseForVerticalInput?.call() ?? false) {
          return const _CommittedPagePreparationResult.pausedForVerticalInput();
        }
        sliceStartedAt = Stopwatch()..start();
        rowsInSlice = 0;
      }
      final finalElapsed = sliceStartedAt.elapsedMicroseconds;
      uiIsolateMicros += finalElapsed;
      largestContiguousUiSliceMicros =
          largestContiguousUiSliceMicros > finalElapsed
          ? largestContiguousUiSliceMicros
          : finalElapsed;
      final prepared = CommittedPreparedLogPage._(
        page: page,
        surfaceWidth: surfaceWidth,
        rowLayouts: rows,
        dayHeaders: headers,
      );
      completed = true;
      return _CommittedPagePreparationResult.prepared(prepared);
    } on Object {
      for (final layout in rows.values) {
        layout.dispose();
      }
      for (final header in headers.values) {
        header.dispose();
      }
      rethrow;
    } finally {
      if (!completed) {
        for (final layout in rows.values) {
          layout.dispose();
        }
        for (final header in headers.values) {
          header.dispose();
        }
      }
    }
  }
}

@immutable
final class _CommittedPagePreparationResult {
  const _CommittedPagePreparationResult.prepared(this.prepared)
    : pausedForVerticalInput = false;

  const _CommittedPagePreparationResult.pausedForVerticalInput()
    : prepared = null,
      pausedForVerticalInput = true;

  const _CommittedPagePreparationResult.superseded()
    : prepared = null,
      pausedForVerticalInput = false;

  final CommittedPreparedLogPage? prepared;
  final bool pausedForVerticalInput;
}

/// Compact geometry for the contiguous drawable page prefix. It stores actual
/// page height only after a page is complete, never a speculative total-count
/// extent. The page VM/text resources may be evicted independently, while the
/// lightweight page geometry remains sufficient for a bounded reload.
final class _CommittedPageGeometry {
  _CommittedPageGeometry({required this.pageSize});

  final int pageSize;
  final List<double> _pageHeights = <double>[];
  final List<int> _rowCounts = <int>[];
  final List<double> _pageTops = <double>[];

  int get highestReadyOrdinal => _pageHeights.length - 1;
  int get readyPageCount => _pageHeights.length;
  int get readyRowCount => _rowCounts.fold<int>(0, (sum, value) => sum + value);
  double get contentHeight =>
      _pageHeights.isEmpty ? 0 : _pageTops.last + _pageHeights.last;
  int get estimatedBytes =>
      _pageHeights.length * 8 + _rowCounts.length * 4 + _pageTops.length * 8;

  /// Appends a new contiguous complete page or verifies an already-discovered
  /// page being reloaded after eviction. A gap can never become drawable.
  bool record(int ordinal, double actualHeight, int rowCount) {
    if (ordinal < 0 ||
        actualHeight < 0 ||
        rowCount < 0 ||
        rowCount > pageSize) {
      return false;
    }
    if (ordinal < _pageHeights.length) {
      return _pageHeights[ordinal] == actualHeight &&
          _rowCounts[ordinal] == rowCount;
    }
    if (ordinal != _pageHeights.length) return false;
    _pageTops.add(contentHeight);
    _pageHeights.add(actualHeight);
    _rowCounts.add(rowCount);
    return true;
  }

  int pageOrdinalForOffset(double offset) {
    if (_pageHeights.isEmpty) return 0;
    var low = 0;
    var high = highestReadyOrdinal;
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
    if (ordinal >= _pageTops.length) return contentHeight;
    return _pageTops[ordinal];
  }

  double pageHeightForOrdinal(int ordinal) =>
      ordinal >= 0 && ordinal < _pageHeights.length ? _pageHeights[ordinal] : 0;
}

/// Prepared text resources for one complete committed page. It is created as
/// one unit before publication so a renderer cannot observe an avatar-only
/// or header-less row.
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
