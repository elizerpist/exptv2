import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../logbox/application/committed_vertical_geometry_manifest.dart';
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

/// A single decoded page can outlive a real structural/surface preemption.
/// Keeping this immutable response privately preserves the `d4a39656`
/// no-reread invariant while all text/layout ownership remains in the cache.
/// Same-scope vertical input defers publication until idle, but it does not
/// invalidate this exact response or require another repository read.
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

/// One bounded transfer of the active base paging chain while an ephemeral
/// focus temporarily owns the visible scope. This remains paging-owned: the
/// focus controller only holds the opaque snapshot and cannot mutate cursors
/// or page resources directly.
final class CommittedPagingFocusSnapshot {
  CommittedPagingFocusSnapshot._({
    required this.viewport,
    required this.commitGeneration,
    required this.nextCursor,
    required this.previousStartCursor,
    required this.nextPageOrdinal,
    required this.desiredForwardOrdinal,
    required this.forwardDemandEpoch,
  });

  final CommittedLogViewportFocusSnapshot viewport;
  final int commitGeneration;
  final Map<String, Object?>? nextCursor;
  final Map<String, Object?>? previousStartCursor;
  final int nextPageOrdinal;
  final int desiredForwardOrdinal;
  final int forwardDemandEpoch;
  bool _consumed = false;

  bool get isAvailable => !_consumed && viewport.isAvailable;

  void markConsumed() => _consumed = true;

  void dispose() {
    if (_consumed) return;
    _consumed = true;
    viewport.dispose();
  }
}

/// Distinguishes optional idle warming from demand observed by the stable
/// viewport. It is a drain scheduling policy, not a second cursor or page
/// lifecycle: both paths use the same exact serial request/commit pipeline.
enum _CommittedPagingWorkOrigin { idlePrewarm, liveViewportDemand }

/// The sole exact-scope sequential keyset acquisition owner.
///
/// The viewport supplies a bounded exact target during scrolling. This owner
/// advances one dependent keyset cursor and atomically hands complete pages to
/// the cache. The five-page initial bank is an idle optimization; it is not a
/// correctness prerequisite for geometry, and live vertical demand records its
/// target without starting new ready work during active input.
final class ExplicitCommittedPagingController {
  ExplicitCommittedPagingController({
    required DashboardCommittedPageRepository repository,
    required DashboardVisibleFrameStore visibleFrames,
    required CommittedLogViewportCache committedViewport,
    this.pageSize = 24,
    this.isMotionActive,
    this.isVerticalInteractionActive,
    this.canRunBackgroundPrewarm,
    this.canResumeDeferredPagePresentation,
    this.isVerticalPointerIntentActive,
    this.onPageRequested,
    this.onPageCompleted,
    this.onPagePipelineIdle,
  }) : _repository = repository,
       _visibleFrames = visibleFrames,
       _committedViewport = committedViewport;

  /// The root does not consume a movable page slot. At an idle opportunity,
  /// warm no more than these five movable slots for the first interaction.
  static const int initialReadyAheadPages = 5;

  final DashboardCommittedPageRepository _repository;
  final DashboardVisibleFrameStore _visibleFrames;
  final CommittedLogViewportCache _committedViewport;
  final int pageSize;
  final bool Function()? isMotionActive;
  final bool Function()? isVerticalInteractionActive;
  final bool Function()? isVerticalPointerIntentActive;
  final bool Function()? canRunBackgroundPrewarm;
  final bool Function()? canResumeDeferredPagePresentation;
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
  _CommittedPagingWorkOrigin _readyWorkOrigin =
      _CommittedPagingWorkOrigin.idlePrewarm;
  bool _readyWorkDeferred = false;
  bool _previousPageReloadPending = false;
  String? _lastDeferredWorkSignature;
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
  bool get hasOutstandingReadyWork => _hasOutstandingReadyWork;
  CommittedLogViewportCache get committedViewport => _committedViewport;
  bool get committedPageRequestInFlight => _pageRequestInFlight;
  bool get committedPageDataPendingPresentation => _deferredPage != null;

  /// Private page text preparation can span bounded event-turn slices. It is
  /// still cache-owned and never exposes a partial drawable page.
  bool get committedPagePresentationActive =>
      _committedViewport.isPagePreparationActive;
  bool get forwardDemandDrainActive => _readyWorkDrain != null;
  bool get backgroundPrewarmActive =>
      _readyWorkDrain != null &&
      _readyWorkOrigin == _CommittedPagingWorkOrigin.idlePrewarm;

  Map<String, String> get forwardRequestStates =>
      Map<String, String>.unmodifiable(
        _forwardRequestStates.map(
          (key, value) => MapEntry(key, value.state.name),
        ),
      );

  void commitMetadata(
    DashboardVisibleFrame frame, {
    required CommittedVerticalGeometryManifest geometryManifest,
  }) {
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

    if (geometryManifest.queryKey != frame.queryKey ||
        geometryManifest.coreRevision != frame.coreRevision ||
        geometryManifest.pageSize != pageSize ||
        geometryManifest.totalEntryCount != frame.logBox.entryCount) {
      throw StateError(
        'Committed page metadata must publish the exact scope geometry.',
      );
    }

    _commitGeneration += 1;
    _nextCursor = frame.logBox.nextCursor;
    _previousStartCursor = null;
    _nextPageOrdinal = 1;
    // A new scope is usable with no speculative page. The initial five-page
    // bank is installed only by an actual idle warmup; live ScrollUpdate
    // demand must work even if that opportunity never happened.
    _desiredForwardOrdinal = 0;
    _forwardDemandEpoch = 0;
    _readyWorkOrigin = _CommittedPagingWorkOrigin.idlePrewarm;
    _readyWorkDeferred = false;
    _previousPageReloadPending = false;
    _lastDeferredWorkSignature = null;
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
      geometryManifest: geometryManifest,
    );
    _committedViewport.updateForwardDemand(
      _desiredForwardOrdinal,
      trigger: 'committedScope',
    );
    _logReadyTarget(reason: 'committedScope');
  }

  /// Moves the current exact base hotset into a single ephemeral-focus
  /// snapshot. It refuses to transfer during an active read/presentation so
  /// no in-flight cursor work can later publish into a restored scope.
  CommittedPagingFocusSnapshot? retainForEphemeralFocus() {
    if (_disposed ||
        _committedTemplate == null ||
        _pageInFlight ||
        _pageRequestInFlight ||
        _readyWorkDrain != null ||
        _deferredPage != null) {
      return null;
    }
    final viewport = _committedViewport.retainForEphemeralFocus();
    if (viewport == null) return null;
    return CommittedPagingFocusSnapshot._(
      viewport: viewport,
      commitGeneration: _commitGeneration,
      nextCursor: _nextCursor,
      previousStartCursor: _previousStartCursor,
      nextPageOrdinal: _nextPageOrdinal,
      desiredForwardOrdinal: _desiredForwardOrdinal,
      forwardDemandEpoch: _forwardDemandEpoch,
    );
  }

  /// Rebinds a retained base chain to the newly published visible frame. The
  /// old page generation intentionally remains intact with its resources;
  /// stale focused requests still fail exact query/revision/presentation
  /// identity checks, while the next base read continues from the retained
  /// cursor rather than rereading ordinals already in the bounded hotset.
  bool restoreEphemeralFocusSnapshot(
    CommittedPagingFocusSnapshot snapshot,
    DashboardVisibleFrame frame, {
    required CommittedVerticalGeometryManifest geometryManifest,
  }) {
    if (_disposed ||
        !snapshot.isAvailable ||
        _pageInFlight ||
        _pageRequestInFlight ||
        _readyWorkDrain != null ||
        _deferredPage != null ||
        frame.mode != DashboardVisibleMode.committed ||
        !_committedViewport.restoreEphemeralFocusSnapshot(
          snapshot.viewport,
          queryKey: frame.queryKey,
          coreRevision: frame.coreRevision,
          geometryManifest: geometryManifest,
        )) {
      return false;
    }
    snapshot.markConsumed();
    _committedTemplate = frame;
    _commitGeneration = snapshot.commitGeneration;
    _nextCursor = snapshot.nextCursor;
    _previousStartCursor = snapshot.previousStartCursor;
    _nextPageOrdinal = snapshot.nextPageOrdinal;
    _desiredForwardOrdinal = snapshot.desiredForwardOrdinal;
    _forwardDemandEpoch = snapshot.forwardDemandEpoch;
    _readyWorkOrigin = _CommittedPagingWorkOrigin.idlePrewarm;
    _readyWorkDeferred = false;
    _previousPageReloadPending = false;
    _lastDeferredWorkSignature = null;
    _forwardRequestStates.clear();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_FOCUS_BASE_PAGING_RESTORED',
        queryKey: frame.queryKey.value,
        coreRevision: frame.coreRevision,
        entryCount: frame.logBox.entryCount,
        message:
            'nextOrdinal=$_nextPageOrdinal desiredOrdinal='
            '$_desiredForwardOrdinal highestReady='
            '${_committedViewport.highestReadyPageOrdinal}',
      ),
    );
    return true;
  }

  /// Fills the bounded initial bank only at an idle opportunity. Repeated
  /// calls cannot recursively preload because page completion never moves the
  /// target.
  Future<bool> prepareReadyAheadAtIdle({required String reason}) {
    if (_disposed) return Future<bool>.value(false);
    // Route/post-layout gates may temporarily prevent execution. The current
    // bounded target remains authoritative intent and must survive until an
    // actual idle opportunity re-admits it.
    _recordInitialReadyAheadTarget();
    return _startReadyWork(
      reason: reason,
      origin: _CommittedPagingWorkOrigin.idlePrewarm,
    );
  }

  /// Gives one already-decoded, identity-current page a bounded foreground
  /// presentation opportunity. This is deliberately not a cursor drain: it
  /// cannot acquire the next page while a drag or ballistic session remains
  /// active.
  Future<bool> resumeDeferredPagePresentation({required String reason}) {
    if (_disposed) return Future<bool>.value(false);
    final active = _readyWorkDrain;
    if (active != null) {
      // A read admitted before raw pointer contact may still be resolving when
      // the pointer lifts. Resume exactly after that one serial operation has
      // either retained the decoded page or become stale; do not create a
      // parallel cursor/presentation owner.
      return active.then((_) => resumeDeferredPagePresentation(reason: reason));
    }
    final deferred = _deferredPage;
    if (deferred == null) return Future<bool>.value(false);
    if (!_isCurrentRequest(deferred.request)) {
      _deferredPage = null;
      return Future<bool>.value(false);
    }
    if (!_canPresentDeferredExactPage()) {
      _readyWorkDeferred = _hasOutstandingReadyWork;
      return Future<bool>.value(false);
    }

    _lastDeferredWorkSignature = null;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_DEFERRED_PAGE_PRESENTATION_RESUMED',
        queryKey: deferred.request.scope.key.value,
        coreRevision: deferred.request.coreRevision,
        entryCount: deferred.page.rowCount,
        message:
            'ordinal=${deferred.request.pageOrdinal} trigger=$reason '
            'pointerIntent=${isVerticalPointerIntentActive?.call() ?? false} '
            'verticalInteraction=${isVerticalInteractionActive?.call() ?? false} '
            'commitGeneration=${deferred.request.commitGeneration}',
      ),
    );

    late final Future<bool> operation;
    operation =
        _commitDeferredPage(
          deferred,
          allowDuringVerticalInteraction: true,
        ).whenComplete(() {
          if (!identical(_readyWorkDrain, operation)) return;
          _readyWorkDrain = null;
          _readyWorkOrigin = _CommittedPagingWorkOrigin.idlePrewarm;
          _readyWorkDeferred = _hasOutstandingReadyWork && !_canRunReadyWork();
          if (!_hasOutstandingReadyWork) onPagePipelineIdle?.call();
        });
    _readyWorkDrain = operation;
    return operation;
  }

  /// Accepts a bounded target observed by the stable viewport. This is live
  /// same-scope demand. Input records the target immediately; the existing
  /// serial acquisition/complete-page pipeline runs only after it is safe.
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
    return _startReadyWork(
      reason: 'explicitTarget',
      origin: _CommittedPagingWorkOrigin.liveViewportDemand,
    );
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
    if (_disposed || !_canReloadPreviousPage()) {
      return Future<bool>.value(false);
    }
    if (_previousPageReloadPending) {
      return _readyWorkDrain ?? Future<bool>.value(false);
    }
    _previousPageReloadPending = true;
    return _startReadyWork(
      reason: 'reverseDemand',
      origin: _CommittedPagingWorkOrigin.idlePrewarm,
    );
  }

  Future<bool> _startReadyWork({
    required String reason,
    required _CommittedPagingWorkOrigin origin,
  }) {
    final active = _readyWorkDrain;
    if (active != null) {
      // A ScrollUpdate may arrive while an idle read is in flight. Upgrade the
      // one existing drain; do not create another cursor owner.
      if (origin == _CommittedPagingWorkOrigin.liveViewportDemand) {
        _readyWorkOrigin = origin;
      }
      return active;
    }
    if (!_hasOutstandingReadyWork) {
      _readyWorkOrigin = _CommittedPagingWorkOrigin.idlePrewarm;
      _readyWorkDeferred = false;
      _lastDeferredWorkSignature = null;
      return Future<bool>.value(false);
    }
    _readyWorkOrigin = origin;
    if (!_canRunReadyWork()) {
      _readyWorkDeferred = _hasOutstandingReadyWork;
      if (_readyWorkDeferred) {
        motionPageSuppressCount += 1;
        _logReadyWorkDeferred(reason: reason);
      }
      return Future<bool>.value(false);
    }
    _lastDeferredWorkSignature = null;

    late final Future<bool> operation;
    operation = _drainReadyWork().whenComplete(() {
      if (!identical(_readyWorkDrain, operation)) return;
      _readyWorkDrain = null;
      _readyWorkOrigin = _CommittedPagingWorkOrigin.idlePrewarm;
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
    while (!_disposed && _canRunReadyWork()) {
      final deferred = _deferredPage;
      if (deferred != null) {
        if (!_isCurrentRequest(deferred.request)) {
          _deferredPage = null;
          continue;
        }
        if (!await _commitDeferredPage(deferred)) return committedAny;
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
    _readyWorkDeferred = !_canRunReadyWork() && _hasOutstandingReadyWork;
    return committedAny;
  }

  Future<bool> _loadOneNextPage() async {
    final template = _committedTemplate;
    final after = _nextCursor;
    if (_disposed ||
        template == null ||
        template.mode != DashboardVisibleMode.committed ||
        after == null ||
        !_canRunReadyWork()) {
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
    if (!_canReloadPreviousPage() ||
        template == null ||
        anchor == null ||
        !_canRunReadyWork()) {
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
    if (_pageInFlight || !_canRunReadyWork()) {
      return false;
    }
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
      if (!_canCommitCurrentPage()) {
        _deferredPage = _DeferredCommittedPage(
          request: request,
          page: page,
          advancesForward: advancesForward,
        );
        _readyWorkDeferred = true;
        _logControllerReject(
          request,
          reason: (isVerticalPointerIntentActive?.call() ?? false)
              ? 'pointerIntentBeforeCommit'
              : 'structuralOrSurfacePreemptedBeforeCommit',
        );
        return false;
      }
      return await _commitPage(
        request: request,
        page: page,
        advancesForward: advancesForward,
        identity: identity,
        canPublish: _canCommitCurrentPage,
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

  Future<bool> _commitDeferredPage(
    _DeferredCommittedPage deferred, {
    bool allowDuringVerticalInteraction = false,
  }) async {
    final canPublish = allowDuringVerticalInteraction
        ? _canPresentDeferredExactPage
        : _canCommitCurrentPage;
    if (!canPublish() || !_isCurrentRequest(deferred.request)) {
      return false;
    }
    final identity = _requestIdentity(deferred.request);
    final committed = await _commitPage(
      request: deferred.request,
      page: deferred.page,
      advancesForward: deferred.advancesForward,
      identity: identity,
      canPublish: canPublish,
    );
    if (committed || !_isCurrentRequest(deferred.request)) {
      _deferredPage = null;
    }
    return committed;
  }

  Future<bool> _commitPage({
    required DashboardCommittedPageRequest request,
    required CommittedLogPage page,
    required bool advancesForward,
    required String identity,
    required bool Function() canPublish,
  }) async {
    if (!_isCurrentRequest(request) || !canPublish()) return false;
    try {
      final committed = await _committedViewport.prepareAndCommit(
        page,
        canPublish: () => _isCurrentRequest(request) && canPublish(),
      );
      if (!committed) {
        if (_isCurrentRequest(request) && !canPublish()) {
          _deferredPage = _DeferredCommittedPage(
            request: request,
            page: page,
            advancesForward: advancesForward,
          );
          _readyWorkDeferred = true;
          return false;
        }
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

  /// Reverse intent is only real when the bounded cache has evicted an
  /// immediately previous page and retained its exact cursor anchor. A bottom
  /// boundary update cannot manufacture a reverse request merely because it
  /// repeats during input.
  bool _canReloadPreviousPage() {
    final template = _committedTemplate;
    final anchor = _committedViewport.lowestRetainedPage;
    return !_disposed &&
        template != null &&
        template.mode == DashboardVisibleMode.committed &&
        anchor != null &&
        anchor.ordinal > 0 &&
        _committedViewport.pageForOrdinal(anchor.ordinal - 1) == null &&
        anchor.previousStartCursor != null;
  }

  /// Demand provenance remains useful for diagnostics, but all ready work
  /// shares one input-safe execution boundary. Pointer/ballistic input may
  /// update a bounded target without starting repository work or page
  /// publication in the interaction lane.
  bool _canRunReadyWork() =>
      _canCommitCurrentPage() && (canRunBackgroundPrewarm?.call() ?? true);

  /// Real rail/structural motion, raw pointer intent, or an unknown surface
  /// makes complete page publication unsafe. A formal vertical interaction
  /// keeps exact data valid while deferring its presentation until idle.
  bool _canCommitCurrentPage() =>
      !_disposed &&
      !(isMotionActive?.call() ?? false) &&
      !(isVerticalPointerIntentActive?.call() ?? false) &&
      !(isVerticalInteractionActive?.call() ?? false) &&
      _committedViewport.surfaceWidth != null;

  /// A current exact decoded page is foreground render readiness after raw
  /// contact ends. Formal drag/ballistic state intentionally does not appear
  /// here: this method never admits a repository request and the page cache
  /// still checks this condition across every cooperative preparation yield.
  bool _canPresentDeferredExactPage() =>
      !_disposed &&
      !(isMotionActive?.call() ?? false) &&
      !(isVerticalPointerIntentActive?.call() ?? false) &&
      _committedViewport.surfaceWidth != null &&
      (canResumeDeferredPagePresentation?.call() ?? true);

  void _recordInitialReadyAheadTarget() {
    final template = _committedTemplate;
    if (template == null || _desiredForwardOrdinal != 0) return;
    final target = initialReadyAheadPages
        .clamp(0, _lastPossibleOrdinal(template))
        .toInt();
    _desiredForwardOrdinal = target;
    _committedViewport.updateForwardDemand(
      target,
      trigger: 'idleInitialReadyAhead',
    );
    _logReadyTarget(reason: 'idleInitialReadyAhead');
  }

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
    final lastPossible = template == null ? -1 : _lastPossibleOrdinal(template);
    final signature =
        '$reason|$_desiredForwardOrdinal|$_nextPageOrdinal|$lastPossible|'
        '$_previousPageReloadPending|${_nextCursor != null}|'
        '${isVerticalInteractionActive?.call() ?? false}|'
        '${isVerticalPointerIntentActive?.call() ?? false}|${isMotionActive?.call() ?? false}';
    if (_lastDeferredWorkSignature == signature) return;
    _lastDeferredWorkSignature = signature;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_READY_AHEAD_DEFERRED',
        queryKey: template?.queryKey.value,
        coreRevision: template?.coreRevision,
        message:
            'targetOrdinal=$_desiredForwardOrdinal nextOrdinal=$_nextPageOrdinal '
            'lastPossible=$lastPossible '
            'hasMorePages=${_nextCursor != null} '
            'verticalInteraction=${isVerticalInteractionActive?.call() ?? false} '
            'pointerIntent=${isVerticalPointerIntentActive?.call() ?? false} '
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
    _readyWorkOrigin = _CommittedPagingWorkOrigin.idlePrewarm;
    _readyWorkDeferred = false;
    _previousPageReloadPending = false;
    _deferredPage = null;
    _pageRequestInFlight = false;
    _forwardRequestStates.clear();
  }
}
