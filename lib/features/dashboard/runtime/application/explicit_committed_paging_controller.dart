import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../data/dashboard_data_runtime_repository.dart';
import '../domain/prepared_dashboard_index.dart';

/// Lifecycle metadata for one exact cursor/ordinal acquisition. It is not a
/// presentation state machine: page resources belong exclusively to
/// [CommittedLogViewportCache]. The records only suppress duplicate keyset
/// requests and keep a failed identity retryable on a later user epoch.
enum CommittedVerticalPageRequestState {
  unseen,
  requested,
  dataReady,
  committed,
  failed,
}

final class _ForwardRequestRecord {
  _ForwardRequestRecord({required this.state, required this.demandEpoch});

  CommittedVerticalPageRequestState state;
  int demandEpoch;
}

/// A single decoded page can outlive a just-started interaction. Keeping this
/// immutable response privately prevents the `d4a39656` reread regression,
/// while keeping all text/layout ownership in the cache. It is resumed only at
/// an idle boundary and is never visible partially.
final class _DeferredCommittedPage {
  const _DeferredCommittedPage({
    required this.request,
    required this.page,
    required this.advancesForward,
  });

  final DashboardCommittedPageRequest request;
  final CommittedLogPage page;
  final bool advancesForward;
}

/// The sole exact-scope sequential keyset acquisition owner.
///
/// A committed scope has one bounded target. It starts with the five movable
/// page slots available beyond the separately pinned root. Meaningful viewport
/// progress can advance that one target, but completion, layout and render
/// extent callbacks cannot. Active drag/ballistic input records the target and
/// consumes existing complete pages; it never turns an unready page into the
/// normal foreground path.
final class ExplicitCommittedPagingController {
  ExplicitCommittedPagingController({
    required DashboardCommittedPageRepository repository,
    required DashboardVisibleFrameStore visibleFrames,
    required CommittedLogViewportCache committedViewport,
    this.pageSize = 24,
    this.isMotionActive,
    this.isVerticalInteractionActive,
    this.canRunBackgroundPrewarm,
    this.onPageRequested,
    this.onPageCompleted,
    this.onPagePipelineIdle,
  }) : _repository = repository,
       _visibleFrames = visibleFrames,
       _committedViewport = committedViewport;

  /// The root does not consume a movable page slot. Fill those five slots on a
  /// new scope so a normal first fling has a real exact bank, rather than a
  /// page-by-page foreground repair path.
  static const int initialReadyAheadPages = 5;

  /// Once the first bank is consumed, reserve a compact forward safety window
  /// while the five-slot retention policy also keeps the current/reverse side.
  static const int rollingReadyAheadPages = 3;

  final DashboardCommittedPageRepository _repository;
  final DashboardVisibleFrameStore _visibleFrames;
  final CommittedLogViewportCache _committedViewport;
  final int pageSize;
  final bool Function()? isMotionActive;
  final bool Function()? isVerticalInteractionActive;
  final bool Function()? canRunBackgroundPrewarm;
  final ValueChanged<DashboardCommittedPageRequest>? onPageRequested;
  final ValueChanged<DashboardCommittedPageRequest>? onPageCompleted;
  final VoidCallback? onPagePipelineIdle;

  DashboardVisibleFrame? _committedTemplate;
  int _commitGeneration = 0;
  Map<String, Object?>? _nextCursor;
  Map<String, Object?>? _previousStartCursor;
  int _nextPageOrdinal = 1;
  int _desiredForwardOrdinal = 0;
  int _forwardDemandEpoch = 0;
  Future<bool>? _readyWorkDrain;
  bool _readyWorkDeferred = false;
  bool _previousPageReloadPending = false;
  bool _pageInFlight = false;
  bool _pageRequestInFlight = false;
  _DeferredCommittedPage? _deferredPage;
  bool _disposed = false;
  final Map<String, _ForwardRequestRecord> _forwardRequestStates =
      <String, _ForwardRequestRecord>{};

  int pageReadCount = 0;
  int pageReadCompletedCount = 0;
  int pageCommittedCount = 0;
  int stalePageRejectCount = 0;
  int duplicatePageSuppressCount = 0;
  int motionPageSuppressCount = 0;

  LedgerQueryKey? get committedQueryKey => _committedTemplate?.queryKey;
  int? get committedRevision => _committedTemplate?.coreRevision;
  int get commitGeneration => _commitGeneration;
  int get nextPageOrdinal => _nextPageOrdinal;
  int get desiredForwardOrdinal => _desiredForwardOrdinal;
  int get forwardDemandEpoch => _forwardDemandEpoch;
  bool get hasDeferredForwardDemand => _readyWorkDeferred;
  CommittedLogViewportCache get committedViewport => _committedViewport;
  bool get committedPageRequestInFlight => _pageRequestInFlight;
  bool get committedPageDataPendingPresentation => _deferredPage != null;

  /// Complete page layout is synchronous and idle-owned. There is no separate
  /// async presentation/promotion lane left to report.
  bool get committedPagePresentationActive => false;
  bool get forwardDemandDrainActive => _readyWorkDrain != null;
  bool get backgroundPrewarmActive => _readyWorkDrain != null;

  Map<String, String> get forwardRequestStates =>
      Map<String, String>.unmodifiable(
        _forwardRequestStates.map(
          (key, value) => MapEntry(key, value.state.name),
        ),
      );

  void commitMetadata(DashboardVisibleFrame frame) {
    if (_disposed) return;
    if (frame.mode != DashboardVisibleMode.committed) {
      throw ArgumentError.value(
        frame.mode,
        'frame.mode',
        'paging metadata requires a committed frame',
      );
    }
    final current = _committedTemplate;
    final sameCommit =
        current != null &&
        current.queryKey == frame.queryKey &&
        current.parentQueryKey == frame.parentQueryKey &&
        current.coreRevision == frame.coreRevision &&
        current.presentationEpoch == frame.presentationEpoch &&
        current.navigationEpoch == frame.navigationEpoch;
    _committedTemplate = frame;
    if (sameCommit) return;

    _commitGeneration += 1;
    _nextCursor = frame.logBox.nextCursor;
    _previousStartCursor = null;
    _nextPageOrdinal = 1;
    _desiredForwardOrdinal = _initialReadyTarget(frame);
    _forwardDemandEpoch = 0;
    _readyWorkDeferred = false;
    _previousPageReloadPending = false;
    _deferredPage = null;
    _pageRequestInFlight = false;
    _forwardRequestStates.clear();
    _committedViewport.seed(
      CommittedLogPage(
        queryKey: frame.queryKey,
        coreRevision: frame.coreRevision,
        generation: _commitGeneration,
        ordinal: 0,
        startCursor: null,
        previousStartCursor: null,
        payload: frame.logBox,
      ),
      generation: _commitGeneration,
    );
    _committedViewport.updateForwardDemand(
      _desiredForwardOrdinal,
      trigger: 'committedScope',
    );
    _logReadyTarget(reason: 'committedScope');
  }

  /// Starts an idle-only attempt to fill the initial or already-recorded
  /// rolling target. It is safe to call repeatedly: completed work does not
  /// move the target and therefore cannot recursively preload a ledger.
  Future<bool> prepareReadyAheadAtIdle({required String reason}) {
    if (_disposed) return Future<bool>.value(false);
    return _startReadyWork(reason: reason);
  }

  /// Records meaningful visible progression. The controller, not the viewport
  /// or cache, owns the one rolling target policy.
  Future<bool> recordVisiblePage(int lastVisibleOrdinal) {
    final template = _committedTemplate;
    if (_disposed || template == null) return Future<bool>.value(false);
    final lastPossible = _lastPossibleOrdinal(template);
    final visible = lastVisibleOrdinal.clamp(0, lastPossible).toInt();
    final target = (visible + rollingReadyAheadPages)
        .clamp(0, lastPossible)
        .toInt();
    if (target > _desiredForwardOrdinal) {
      _desiredForwardOrdinal = target;
      _committedViewport.updateForwardDemand(
        _desiredForwardOrdinal,
        trigger: 'viewportProgress',
        lastVisibleOrdinal: visible,
      );
      _logReadyTarget(reason: 'viewportProgress');
    }
    return _startReadyWork(reason: 'viewportProgress');
  }

  /// Compatibility entry point for a direct explicit target. Production
  /// viewport code uses [recordVisiblePage]; direct tests/harnesses can still
  /// request one bounded target without getting a second cursor owner.
  Future<bool> requestForwardDemand(int desiredLastReadyOrdinal) {
    final template = _committedTemplate;
    if (_disposed || template == null || desiredLastReadyOrdinal < 1) {
      return Future<bool>.value(false);
    }
    final target = desiredLastReadyOrdinal
        .clamp(0, _lastPossibleOrdinal(template))
        .toInt();
    if (target > _desiredForwardOrdinal) {
      _desiredForwardOrdinal = target;
      _committedViewport.updateForwardDemand(
        _desiredForwardOrdinal,
        trigger: 'explicitTarget',
      );
      _logReadyTarget(reason: 'explicitTarget');
    }
    return _startReadyWork(reason: 'explicitTarget');
  }

  Future<bool> loadNextPage() => requestForwardDemand(_nextPageOrdinal);

  /// A new user gesture permits retrying a previously failed identity but does
  /// not manufacture new readiness demand.
  void beginForwardDemandEpoch() {
    if (_disposed) return;
    _forwardDemandEpoch += 1;
  }

  /// A reverse request is coalesced into the same serial drain. During input
  /// it is retained as intent and is attempted only after idle, so it cannot
  /// compete with pointer or ballistic work.
  Future<bool> loadPreviousPage() {
    if (_disposed) return Future<bool>.value(false);
    _previousPageReloadPending = true;
    return _startReadyWork(reason: 'reverseDemand');
  }

  Future<bool> _startReadyWork({required String reason}) {
    if (!_canPrepareNow()) {
      _readyWorkDeferred = _hasOutstandingReadyWork;
      if (_readyWorkDeferred) {
        motionPageSuppressCount += 1;
        _logReadyWorkDeferred(reason: reason);
      }
      return Future<bool>.value(false);
    }
    final active = _readyWorkDrain;
    if (active != null) return active;
    if (!_hasOutstandingReadyWork) return Future<bool>.value(false);

    late final Future<bool> operation;
    operation = _drainReadyWork().whenComplete(() {
      if (!identical(_readyWorkDrain, operation)) return;
      _readyWorkDrain = null;
      // `_drainReadyWork` itself consumes every already-recorded serial
      // target. Do not reopen it here: a failed identity is intentionally
      // retryable only after a new user demand epoch, not through an idle
      // completion loop.
      // The core can resume unrelated speculative work only after this exact
      // target is truly settled. Calling it for a failed target would make
      // its reconciliation hook retry the same cursor without a new demand
      // epoch.
      if (!_hasOutstandingReadyWork) onPagePipelineIdle?.call();
    });
    _readyWorkDrain = operation;
    return operation;
  }

  Future<bool> _drainReadyWork() async {
    var committedAny = false;
    while (!_disposed && _canPrepareNow()) {
      final deferred = _deferredPage;
      if (deferred != null) {
        if (!_isCurrentRequest(deferred.request)) {
          _deferredPage = null;
          continue;
        }
        if (!_commitDeferredPage(deferred)) return committedAny;
        committedAny = true;
        continue;
      }
      if (_previousPageReloadPending) {
        _previousPageReloadPending = false;
        final didCommit = await _loadOnePreviousPage();
        if (!didCommit) continue;
        committedAny = true;
        continue;
      }
      if (_nextCursor == null || _nextPageOrdinal > _desiredForwardOrdinal) {
        break;
      }
      final didCommit = await _loadOneNextPage();
      if (!didCommit) return committedAny;
      committedAny = true;
    }
    _readyWorkDeferred = !_canPrepareNow() && _hasOutstandingReadyWork;
    return committedAny;
  }

  Future<bool> _loadOneNextPage() async {
    final template = _committedTemplate;
    final after = _nextCursor;
    if (_disposed ||
        template == null ||
        template.mode != DashboardVisibleMode.committed ||
        after == null ||
        !_canPrepareNow()) {
      return false;
    }
    if (_pageInFlight) {
      duplicatePageSuppressCount += 1;
      return false;
    }
    final request = DashboardCommittedPageRequest(
      scope: template.scope,
      parentQueryKey: template.parentQueryKey,
      coreRevision: template.coreRevision,
      presentationEpoch: template.presentationEpoch,
      commitGeneration: _commitGeneration,
      authoritativeTotalMinor: template.amount.totalMinor,
      authoritativeEntryCount: template.count.entryCount,
      pageSize: pageSize,
      pageOrdinal: _nextPageOrdinal,
      startCursor: after,
      previousStartCursor: _previousStartCursor,
      reason: DataAcquisitionReason.explicitCommittedVerticalPaging,
    );
    return _readAndCommit(request, advancesForward: true);
  }

  Future<bool> _loadOnePreviousPage() async {
    final template = _committedTemplate;
    final anchor = _committedViewport.lowestRetainedPage;
    if (_disposed ||
        template == null ||
        template.mode != DashboardVisibleMode.committed ||
        anchor == null ||
        anchor.ordinal == 0 ||
        _committedViewport.pageForOrdinal(anchor.ordinal - 1) != null ||
        !_canPrepareNow()) {
      return false;
    }
    if (_pageInFlight) {
      duplicatePageSuppressCount += 1;
      return false;
    }
    final targetOrdinal = anchor.ordinal - 1;
    final startCursor = anchor.previousStartCursor;
    if (startCursor == null) return false;
    final known = _committedViewport.cursorAnchorForOrdinal(targetOrdinal);
    final request = DashboardCommittedPageRequest(
      scope: template.scope,
      parentQueryKey: template.parentQueryKey,
      coreRevision: template.coreRevision,
      presentationEpoch: template.presentationEpoch,
      commitGeneration: _commitGeneration,
      authoritativeTotalMinor: template.amount.totalMinor,
      authoritativeEntryCount: template.count.entryCount,
      pageSize: pageSize,
      pageOrdinal: targetOrdinal,
      startCursor: startCursor,
      previousStartCursor: known?.previousStartCursor,
      reason: DataAcquisitionReason.explicitCommittedVerticalPaging,
    );
    return _readAndCommit(
      request,
      advancesForward: false,
      allowsRetainedReload: true,
    );
  }

  Future<bool> _readAndCommit(
    DashboardCommittedPageRequest request, {
    required bool advancesForward,
    bool allowsRetainedReload = false,
  }) async {
    if (_pageInFlight || !_canPrepareNow()) return false;
    final identity = _requestIdentity(request);
    final previous = _forwardRequestStates[identity];
    if (!allowsRetainedReload &&
        previous != null &&
        previous.state != CommittedVerticalPageRequestState.failed) {
      duplicatePageSuppressCount += 1;
      return false;
    }
    if (!allowsRetainedReload &&
        previous?.state == CommittedVerticalPageRequestState.failed &&
        previous!.demandEpoch == _forwardDemandEpoch) {
      duplicatePageSuppressCount += 1;
      return false;
    }
    _forwardRequestStates[identity] = _ForwardRequestRecord(
      state: CommittedVerticalPageRequestState.requested,
      demandEpoch: _forwardDemandEpoch,
    );
    request.reason.requirePageRead();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_REQUESTED',
        queryKey: request.scope.key.value,
        coreRevision: request.coreRevision,
        message:
            'ordinal=${request.pageOrdinal} demandEpoch=$_forwardDemandEpoch '
            'cursorDigest=${_cursorDigest(request.startCursor)}',
      ),
    );
    onPageRequested?.call(request);
    _pageInFlight = true;
    _pageRequestInFlight = true;
    pageReadCount += 1;
    final started = Stopwatch()..start();
    try {
      final page = await _repository.readCommittedPage(request);
      _pageRequestInFlight = false;
      pageReadCompletedCount += 1;
      if (!_accepts(page, request: request)) {
        stalePageRejectCount += 1;
        _markRequestFailed(identity);
        _logControllerReject(request, reason: 'staleRequest');
        return false;
      }
      _setRequestState(identity, CommittedVerticalPageRequestState.dataReady);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_PAGE_DATA_READY',
          queryKey: page.queryKey.value,
          coreRevision: page.coreRevision,
          entryCount: page.rowCount,
          durationMs: started.elapsedMilliseconds,
          message:
              'ordinal=${page.ordinal} totalDataReadyMicros='
              '${started.elapsedMicroseconds}',
        ),
      );
      if (!_canPrepareNow()) {
        _deferredPage = _DeferredCommittedPage(
          request: request,
          page: page,
          advancesForward: advancesForward,
        );
        _readyWorkDeferred = true;
        _logControllerReject(request, reason: 'inputPreemptedBeforeCommit');
        return false;
      }
      return _commitPage(
        request: request,
        page: page,
        advancesForward: advancesForward,
        identity: identity,
      );
    } on Object catch (error) {
      if (!_isCurrentRequest(request)) {
        stalePageRejectCount += 1;
        return false;
      }
      _committedViewport.recordPageFailure(
        queryKey: request.scope.key,
        coreRevision: request.coreRevision,
        ordinal: request.pageOrdinal,
        error: error,
      );
      _markRequestFailed(identity);
      return false;
    } finally {
      _pageRequestInFlight = false;
      _pageInFlight = false;
    }
  }

  bool _commitDeferredPage(_DeferredCommittedPage deferred) {
    if (!_canPrepareNow() || !_isCurrentRequest(deferred.request)) return false;
    final identity = _requestIdentity(deferred.request);
    final committed = _commitPage(
      request: deferred.request,
      page: deferred.page,
      advancesForward: deferred.advancesForward,
      identity: identity,
    );
    if (committed || !_isCurrentRequest(deferred.request)) {
      _deferredPage = null;
    }
    return committed;
  }

  bool _commitPage({
    required DashboardCommittedPageRequest request,
    required CommittedLogPage page,
    required bool advancesForward,
    required String identity,
  }) {
    if (!_isCurrentRequest(request) || !_canPrepareNow()) return false;
    try {
      if (!_committedViewport.commit(page)) {
        stalePageRejectCount += 1;
        _markRequestFailed(identity);
        return false;
      }
    } on Object catch (error) {
      _committedViewport.recordPageFailure(
        queryKey: request.scope.key,
        coreRevision: request.coreRevision,
        ordinal: request.pageOrdinal,
        error: error,
      );
      _markRequestFailed(identity);
      return false;
    }
    if (advancesForward) {
      _previousStartCursor = request.startCursor;
      _nextCursor = page.nextCursor;
      _nextPageOrdinal = request.pageOrdinal + 1;
    }
    _setRequestState(identity, CommittedVerticalPageRequestState.committed);
    pageCommittedCount += 1;
    onPageCompleted?.call(request);
    return true;
  }

  bool _accepts(
    CommittedLogPage page, {
    required DashboardCommittedPageRequest request,
  }) =>
      _isCurrentRequest(request) &&
      page.queryKey == request.scope.key &&
      page.coreRevision == request.coreRevision &&
      page.generation == request.commitGeneration &&
      page.ordinal == request.pageOrdinal;

  bool _isCurrentRequest(DashboardCommittedPageRequest request) {
    final current = _committedTemplate;
    final visible = _visibleFrames.value;
    return !_disposed &&
        current != null &&
        visible != null &&
        request.reason ==
            DataAcquisitionReason.explicitCommittedVerticalPaging &&
        request.commitGeneration == _commitGeneration &&
        current.queryKey == request.scope.key &&
        current.parentQueryKey == request.parentQueryKey &&
        current.coreRevision == request.coreRevision &&
        current.presentationEpoch == request.presentationEpoch &&
        visible.queryKey == current.queryKey &&
        visible.coreRevision == current.coreRevision;
  }

  bool get _hasOutstandingReadyWork =>
      _deferredPage != null ||
      _previousPageReloadPending ||
      (_nextCursor != null && _nextPageOrdinal <= _desiredForwardOrdinal);

  bool _canPrepareNow() =>
      !_disposed &&
      !(isMotionActive?.call() ?? false) &&
      !(isVerticalInteractionActive?.call() ?? false) &&
      _committedViewport.surfaceWidth != null &&
      (canRunBackgroundPrewarm?.call() ?? true);

  int _initialReadyTarget(DashboardVisibleFrame frame) =>
      initialReadyAheadPages.clamp(0, _lastPossibleOrdinal(frame)).toInt();

  int _lastPossibleOrdinal(DashboardVisibleFrame frame) =>
      frame.count.entryCount == 0
      ? 0
      : (frame.count.entryCount - 1) ~/ pageSize;

  String _requestIdentity(DashboardCommittedPageRequest request) =>
      '${request.scope.key.value}|r${request.coreRevision}|g'
      '${request.commitGeneration}|o${request.pageOrdinal}|c'
      '${_cursorDigest(request.startCursor)}';

  String _cursorDigest(Map<String, Object?>? cursor) {
    if (cursor == null) return 'root';
    final fields =
        cursor.entries.map((entry) => '${entry.key}=${entry.value}').toList()
          ..sort();
    return Object.hashAll(fields).toRadixString(16);
  }

  void _setRequestState(
    String identity,
    CommittedVerticalPageRequestState state,
  ) {
    final record = _forwardRequestStates[identity];
    if (record != null) record.state = state;
  }

  void _markRequestFailed(String identity) {
    final record = _forwardRequestStates[identity];
    if (record == null) return;
    record.state = CommittedVerticalPageRequestState.failed;
    record.demandEpoch = _forwardDemandEpoch;
  }

  void _logReadyTarget({required String reason}) {
    final template = _committedTemplate;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_READY_AHEAD_TARGET_CHANGED',
        queryKey: template?.queryKey.value,
        coreRevision: template?.coreRevision,
        message:
            'targetOrdinal=$_desiredForwardOrdinal nextOrdinal=$_nextPageOrdinal '
            'retainedPages=${_committedViewport.retainedPageCount} '
            'reason=$reason',
      ),
    );
  }

  void _logReadyWorkDeferred({required String reason}) {
    final template = _committedTemplate;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_READY_AHEAD_DEFERRED',
        queryKey: template?.queryKey.value,
        coreRevision: template?.coreRevision,
        message:
            'targetOrdinal=$_desiredForwardOrdinal nextOrdinal=$_nextPageOrdinal '
            'verticalInteraction=${isVerticalInteractionActive?.call() ?? false} '
            'motionActive=${isMotionActive?.call() ?? false} reason=$reason',
      ),
    );
  }

  void _logControllerReject(
    DashboardCommittedPageRequest request, {
    required String reason,
  }) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_COMMIT_REJECTED',
        queryKey: request.scope.key.value,
        coreRevision: request.coreRevision,
        message:
            'requestedOrdinal=${request.pageOrdinal} '
            'requestGeneration=${request.commitGeneration} '
            'requestRevision=${request.coreRevision} pageSize=${request.pageSize} '
            'cursorDigest=${_cursorDigest(request.startCursor)} reason=$reason',
      ),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _commitGeneration += 1;
    _nextCursor = null;
    _previousStartCursor = null;
    _committedTemplate = null;
    _readyWorkDeferred = false;
    _previousPageReloadPending = false;
    _deferredPage = null;
    _pageRequestInFlight = false;
    _forwardRequestStates.clear();
  }
}
