import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../data/dashboard_data_runtime_repository.dart';
import '../domain/prepared_dashboard_index.dart';

/// Lifecycle of one exact cursor/ordinal acquisition. The state is retained
/// as lightweight metadata, independently from evictable row/text pages, so
/// repeated scroll notifications cannot turn a rejected request into a silent
/// request storm.
enum CommittedVerticalPageRequestState {
  unseen,
  requested,
  dataReady,
  presentationPreparing,
  presentationReady,
  committed,
  failed,
}

final class _ForwardRequestRecord {
  _ForwardRequestRecord({required this.state, required this.demandEpoch});

  CommittedVerticalPageRequestState state;
  int demandEpoch;
}

/// One decoded page held by the sequential paging owner until the cache has
/// atomically prepared and committed its exact presentation resources. It is
/// never visible and never owns cache resources.
final class _PendingCommittedPagePresentation {
  const _PendingCommittedPagePresentation({
    required this.request,
    required this.page,
  });

  final DashboardCommittedPageRequest request;
  final CommittedLogPage page;
}

/// One bounded idle-ready request tied to one exact committed scope. It is
/// intentionally metadata-only: the controller remains the only cursor owner
/// and the viewport cache remains the only page/text-resource owner.
@immutable
final class _BoundedReadyHotsetIntent {
  const _BoundedReadyHotsetIntent({
    required this.queryKey,
    required this.coreRevision,
    required this.commitGeneration,
  });

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int commitGeneration;

  bool matches({
    required DashboardVisibleFrame frame,
    required int generation,
  }) =>
      queryKey == frame.queryKey &&
      coreRevision == frame.coreRevision &&
      commitGeneration == generation;
}

/// The only exact-scope dashboard acquisition owner.
///
/// Committing metadata is synchronous and side-effect free. A repository call
/// can start only from [loadNextPage], which requires an exact committed frame
/// and a prepared next cursor.
final class ExplicitCommittedPagingController {
  ExplicitCommittedPagingController({
    required DashboardCommittedPageRepository repository,
    required DashboardVisibleFrameStore visibleFrames,
    required CommittedLogViewportCache committedViewport,
    this.pageSize = 24,
    this.isMotionActive,
    this.canRunBackgroundPrewarm,
    this.onPageRequested,
    this.onPageCompleted,
    this.onPagePipelineIdle,
  }) : _repository = repository,
       _visibleFrames = visibleFrames,
       _committedViewport = committedViewport;

  final DashboardCommittedPageRepository _repository;
  final DashboardVisibleFrameStore _visibleFrames;
  final CommittedLogViewportCache _committedViewport;
  final int pageSize;
  final bool Function()? isMotionActive;
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
  int _backgroundPrewarmTargetOrdinal = 0;
  int _backgroundPrewarmGeneration = 0;
  _BoundedReadyHotsetIntent? _boundedReadyHotsetIntent;
  String? _lastRetainedHotsetReason;
  int _forwardDemandEpoch = 0;
  Future<bool>? _forwardDemandDrain;
  bool _forwardDemandDeferred = false;
  bool _pageInFlight = false;
  bool _pageRequestInFlight = false;
  bool _presentationPreparing = false;
  _PendingCommittedPagePresentation? _pendingPresentation;
  bool _disposed = false;
  final Map<String, _ForwardRequestRecord> _forwardRequestStates =
      <String, _ForwardRequestRecord>{};

  int pageReadCount = 0;
  int stalePageRejectCount = 0;
  int duplicatePageSuppressCount = 0;
  int motionPageSuppressCount = 0;

  LedgerQueryKey? get committedQueryKey => _committedTemplate?.queryKey;
  int? get committedRevision => _committedTemplate?.coreRevision;
  int get commitGeneration => _commitGeneration;
  int get nextPageOrdinal => _nextPageOrdinal;
  int get desiredForwardOrdinal => _desiredForwardOrdinal;
  int get forwardDemandEpoch => _forwardDemandEpoch;
  bool get hasDeferredForwardDemand => _forwardDemandDeferred;
  CommittedLogViewportCache get committedViewport => _committedViewport;
  bool get committedPageRequestInFlight => _pageRequestInFlight;
  bool get committedPageDataPendingPresentation => _pendingPresentation != null;
  bool get committedPagePresentationActive => _presentationPreparing;
  bool get forwardDemandDrainActive => _forwardDemandDrain != null;
  bool get backgroundPrewarmActive => _backgroundPrewarmTargetOrdinal > 0;

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
    if (!sameCommit) {
      _commitGeneration += 1;
      _nextCursor = frame.logBox.nextCursor;
      _previousStartCursor = null;
      _nextPageOrdinal = 1;
      _desiredForwardOrdinal = 0;
      _backgroundPrewarmTargetOrdinal = 0;
      _backgroundPrewarmGeneration += 1;
      _boundedReadyHotsetIntent = _newBoundedReadyHotsetIntent(frame);
      _lastRetainedHotsetReason = null;
      _forwardDemandEpoch = 0;
      _forwardDemandDeferred = false;
      _pendingPresentation = null;
      _pageRequestInFlight = false;
      _presentationPreparing = false;
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
      _logRetainedHotsetIntent(reason: 'committedScope');
    }
  }

  /// Compatibility entry point for one explicit near-end demand. Repeated
  /// scroll samples never directly issue I/O; callers needing lookahead use
  /// [requestForwardDemand].
  Future<bool> loadNextPage() {
    if (_forwardDemandDrain != null || _pageInFlight) {
      duplicatePageSuppressCount += 1;
      return Future<bool>.value(false);
    }
    return requestForwardDemand(_nextPageOrdinal);
  }

  /// A user-initiated vertical scroll starts a new retry epoch. Failed page
  /// identities remain suppressed during the same gesture/demand epoch, but a
  /// later explicit user interaction can retry them without any timer-based
  /// fallback.
  void beginForwardDemandEpoch() {
    if (_disposed) return;
    _forwardDemandEpoch += 1;
  }

  /// Coalesces vertical demand into one sequential keyset drain. The request
  /// identity advances only after a complete cache commit, so ordinal N cannot
  /// be repeatedly reissued merely because scroll notifications continue.
  Future<bool> requestForwardDemand(int desiredLastReadyOrdinal) {
    if (_disposed || desiredLastReadyOrdinal < 1) {
      return Future<bool>.value(false);
    }
    final previousDesired = _desiredForwardOrdinal;
    if (desiredLastReadyOrdinal > _desiredForwardOrdinal) {
      _desiredForwardOrdinal = desiredLastReadyOrdinal;
    }
    final active = _forwardDemandDrain;
    _logForwardDemand(
      'VERTICAL_FORWARD_DEMAND_ACCEPTED',
      desiredOrdinal: _desiredForwardOrdinal,
      drainActive: active != null,
    );
    if (active != null) {
      // A human demand supersedes only the still-unneeded tail of the idle
      // hotset. The in-flight page remains exact foreground work when its
      // ordinal is now demanded, so no cursor read or private preparation is
      // restarted.
      if (_backgroundPrewarmTargetOrdinal > _desiredForwardOrdinal) {
        cancelBoundedReadyHotset(reason: 'foregroundDemand');
      }
      _promotePendingPresentationForForegroundDemand();
      if (desiredLastReadyOrdinal <= previousDesired) {
        duplicatePageSuppressCount += 1;
      }
      return active;
    }
    late final Future<bool> operation;
    operation = _drainForwardDemand().whenComplete(() {
      if (identical(_forwardDemandDrain, operation)) {
        _forwardDemandDrain = null;
        _reportBackgroundPrewarmReadyIfSettled();
        // If a motion lane became idle in the narrow interval while the old
        // drain was unwinding, its earlier idle callback saw drainActive and
        // correctly did nothing. Recheck here so that race cannot lose the
        // exact still-current pending ordinal.
        resumeDeferredForwardDemand();
        onPagePipelineIdle?.call();
      }
    });
    _forwardDemandDrain = operation;
    return operation;
  }

  /// Records (if necessary) and tries the first bounded forward bank for the
  /// current exact root. A temporarily closed foreground gate never consumes
  /// this intent; an existing lifecycle idle boundary retries it later.
  Future<bool> prewarmBoundedReadyHotset() {
    _retainBoundedReadyHotsetIntent();
    return tryStartBoundedReadyHotset(reason: 'postLayout');
  }

  /// Retries the retained exact-scope hotset only at an explicit lifecycle
  /// boundary supplied by the orchestration owner. It never polls or starts a
  /// second cursor drain.
  Future<bool> tryStartBoundedReadyHotset({required String reason}) {
    final template = _committedTemplate;
    if (_disposed ||
        template == null ||
        !_hasCurrentBoundedReadyHotsetIntent(template)) {
      return Future<bool>.value(false);
    }
    final targetOrdinal = _boundedReadyHotsetTarget(template);
    if (targetOrdinal == null) {
      _boundedReadyHotsetIntent = null;
      _lastRetainedHotsetReason = null;
      return Future<bool>.value(false);
    }
    if (_backgroundPrewarmTargetOrdinal != 0) {
      return _forwardDemandDrain ?? Future<bool>.value(false);
    }
    if (_committedViewport.surfaceWidth == null) {
      _logRetainedHotsetIntent(reason: 'surfaceWidth');
      return Future<bool>.value(false);
    }
    if (!_canRunBackgroundPrewarm()) {
      _logRetainedHotsetIntent(reason: 'foregroundGate');
      return Future<bool>.value(false);
    }
    if (reason != 'postLayout') {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_HOTSET_PREWARM_RETRY',
          queryKey: template.queryKey.value,
          coreRevision: template.coreRevision,
          message:
              'reason=$reason generation=$_backgroundPrewarmGeneration '
              'targetReadyOrdinal=$targetOrdinal',
        ),
      );
    }
    _backgroundPrewarmGeneration += 1;
    _backgroundPrewarmTargetOrdinal = targetOrdinal;
    _lastRetainedHotsetReason = null;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_HOTSET_PREWARM_STARTED',
        queryKey: template.queryKey.value,
        coreRevision: template.coreRevision,
        entryCount: template.count.entryCount,
        message:
            'generation=$_backgroundPrewarmGeneration '
            'highestReady=${_committedViewport.highestReadyPageOrdinal} '
            'targetReadyOrdinal=$targetOrdinal '
            'retainedPages=${_committedViewport.retainedPageCount} '
            'estimatedBytes=${_committedViewport.estimatedBytes}',
      ),
    );
    final active = _forwardDemandDrain;
    if (active != null) return active;
    late final Future<bool> operation;
    operation = _drainForwardDemand().whenComplete(() {
      if (identical(_forwardDemandDrain, operation)) {
        _forwardDemandDrain = null;
        _reportBackgroundPrewarmReadyIfSettled();
        resumeDeferredForwardDemand();
        onPagePipelineIdle?.call();
      }
    });
    _forwardDemandDrain = operation;
    return operation;
  }

  /// Releases only speculative forward readiness. Foreground demand keeps the
  /// same cursor/request identity and may promote an in-flight page later.
  void cancelBoundedReadyHotset({
    required String reason,
    bool discardIntent = false,
  }) {
    if (_disposed) return;
    final template = _committedTemplate;
    final targetOrdinal = _backgroundPrewarmTargetOrdinal;
    _backgroundPrewarmTargetOrdinal = 0;
    _backgroundPrewarmGeneration += 1;
    if (discardIntent) {
      _boundedReadyHotsetIntent = null;
      _lastRetainedHotsetReason = null;
    }
    if (targetOrdinal == 0 && !discardIntent) return;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_HOTSET_PREWARM_PREEMPTED',
        queryKey: template?.queryKey.value,
        coreRevision: template?.coreRevision,
        message: 'reason=$reason targetOrdinal=$targetOrdinal',
      ),
    );
  }

  /// Motion may preempt this low-priority sequential drain, but never erase
  /// its exact target. The dashboard orchestration owner invokes this at the
  /// existing motion-idle boundary; no timer or second user gesture is used.
  void resumeDeferredForwardDemand() {
    if (_disposed) return;
    if (_forwardDemandDeferred &&
        _forwardDemandDrain == null &&
        _nextCursor != null &&
        _nextPageOrdinal <= _desiredForwardOrdinal &&
        !(isMotionActive?.call() ?? false)) {
      _forwardDemandDeferred = false;
      _logForwardDemand(
        'VERTICAL_FORWARD_DEMAND_RESUMED',
        desiredOrdinal: _desiredForwardOrdinal,
        drainActive: false,
      );
      unawaited(requestForwardDemand(_desiredForwardOrdinal));
    }
  }

  Future<bool> _drainForwardDemand() async {
    var committedAny = false;
    while (!_disposed &&
        _nextCursor != null &&
        _nextPageOrdinal <= _targetOrdinal) {
      if (isMotionActive?.call() ?? false) {
        if (_nextPageOrdinal <= _desiredForwardOrdinal) {
          _deferForwardDemand();
        } else {
          cancelBoundedReadyHotset(reason: 'structuralMotion');
        }
        return committedAny;
      }
      if (_nextPageOrdinal > _desiredForwardOrdinal &&
          !_canRunBackgroundPrewarm()) {
        cancelBoundedReadyHotset(reason: 'foregroundOwnership');
        return committedAny;
      }
      final didCommit = await _loadOneNextPage(
        backgroundPrewarmGeneration: _nextPageOrdinal <= _desiredForwardOrdinal
            ? null
            : _backgroundPrewarmGeneration,
      );
      if (!didCommit) return committedAny;
      committedAny = true;
    }
    return committedAny;
  }

  Future<bool> _loadOneNextPage({int? backgroundPrewarmGeneration}) async {
    final template = _committedTemplate;
    final after = _nextCursor;
    if (_disposed ||
        template == null ||
        template.mode != DashboardVisibleMode.committed ||
        after == null) {
      return false;
    }
    if (isMotionActive?.call() ?? false) {
      _deferForwardDemand();
      return false;
    }
    if (_pageInFlight) {
      duplicatePageSuppressCount += 1;
      return false;
    }
    final generation = _commitGeneration;
    final request = DashboardCommittedPageRequest(
      scope: template.scope,
      parentQueryKey: template.parentQueryKey,
      coreRevision: template.coreRevision,
      presentationEpoch: template.presentationEpoch,
      commitGeneration: generation,
      authoritativeTotalMinor: template.amount.totalMinor,
      authoritativeEntryCount: template.count.entryCount,
      pageSize: pageSize,
      pageOrdinal: _nextPageOrdinal,
      startCursor: after,
      previousStartCursor: _previousStartCursor,
      reason: DataAcquisitionReason.explicitCommittedVerticalPaging,
    );
    final identity = _requestIdentity(request);
    final previous = _forwardRequestStates[identity];
    if (previous != null &&
        previous.state != CommittedVerticalPageRequestState.failed) {
      duplicatePageSuppressCount += 1;
      return false;
    }
    if (previous?.state == CommittedVerticalPageRequestState.failed &&
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
    return _readAndCommit(
      request,
      advancesForward: true,
      backgroundPrewarmGeneration: backgroundPrewarmGeneration,
    );
  }

  /// Reloads the immediate prior committed page using the compact keyset
  /// cursor chain. The row/text cache may have evicted it; the rail path is
  /// never involved.
  Future<bool> loadPreviousPage() async {
    final template = _committedTemplate;
    final anchor = _committedViewport.lowestRetainedPage;
    if (_disposed ||
        template == null ||
        template.mode != DashboardVisibleMode.committed ||
        anchor == null ||
        anchor.ordinal == 0 ||
        _committedViewport.pageForOrdinal(anchor.ordinal - 1) != null) {
      return false;
    }
    if (isMotionActive?.call() ?? false) {
      motionPageSuppressCount += 1;
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
    request.reason.requirePageRead();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_REQUESTED',
        queryKey: request.scope.key.value,
        coreRevision: request.coreRevision,
        message: 'ordinal=${request.pageOrdinal} direction=previous',
      ),
    );
    onPageRequested?.call(request);
    return _readAndCommit(request, advancesForward: false);
  }

  Future<bool> _readAndCommit(
    DashboardCommittedPageRequest request, {
    required bool advancesForward,
    int? backgroundPrewarmGeneration,
  }) async {
    _pageInFlight = true;
    _pageRequestInFlight = true;
    pageReadCount += 1;
    final startedAt = Stopwatch()..start();
    final identity = _requestIdentity(request);
    try {
      final page = await _repository.readCommittedPage(request);
      _pageRequestInFlight = false;
      if (!_shouldKeepPageAfterRead(
        request,
        backgroundPrewarmGeneration: backgroundPrewarmGeneration,
      )) {
        // Preserve the established foreground stale-result accounting. A
        // cancelled idle hotset is normal preemption, not a stale user page.
        if (backgroundPrewarmGeneration == null) stalePageRejectCount += 1;
        _forwardRequestStates.remove(identity);
        return false;
      }
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
          durationMs: startedAt.elapsedMilliseconds,
          message:
              'ordinal=${page.ordinal} totalDataReadyMicros='
              '${startedAt.elapsedMicroseconds}',
        ),
      );
      // A low-priority vertical response may finish after rail motion has
      // begun. Its page preparation would allocate paragraph resources on the
      // UI isolate, so discard it rather than letting it perturb the frozen
      // rail path; the next explicit vertical demand can re-read the keyset
      // cursor when the rail is idle.
      if (isMotionActive?.call() ?? false) {
        _forwardRequestStates.remove(identity);
        _deferForwardDemand();
        _logControllerReject(request, reason: 'motionPreempted');
        return false;
      }
      final pending = _PendingCommittedPagePresentation(
        request: request,
        page: page,
      );
      _pendingPresentation = pending;
      final committed = await _prepareAndCommitPendingPresentation(
        pending,
        identity: identity,
        backgroundPrewarmGeneration: backgroundPrewarmGeneration,
      );
      if (!committed) return false;
      _setRequestState(
        identity,
        CommittedVerticalPageRequestState.presentationReady,
      );
      if (advancesForward) {
        _previousStartCursor = request.startCursor;
        _nextCursor = page.nextCursor;
        _nextPageOrdinal = request.pageOrdinal + 1;
      }
      _setRequestState(identity, CommittedVerticalPageRequestState.committed);
      onPageCompleted?.call(request);
      return true;
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
      _presentationPreparing = false;
      if (_pendingPresentation?.request == request) {
        _pendingPresentation = null;
      }
      _pageInFlight = false;
      onPagePipelineIdle?.call();
    }
  }

  Future<bool> _prepareAndCommitPendingPresentation(
    _PendingCommittedPagePresentation pending, {
    required String identity,
    int? backgroundPrewarmGeneration,
  }) async {
    if (!_isCurrentPendingPresentation(pending)) {
      stalePageRejectCount += 1;
      return false;
    }
    if (isMotionActive?.call() ?? false) {
      _forwardRequestStates.remove(identity);
      _deferForwardDemand();
      _logControllerReject(
        pending.request,
        reason: 'presentationMotionPreempted',
      );
      return false;
    }
    _presentationPreparing = true;
    final outcome = await _committedViewport.prepareAndCommitOutcome(
      pending.page,
      shouldPreempt: () => isMotionActive?.call() ?? false,
      shouldPreemptBackground: () =>
          backgroundPrewarmGeneration != null &&
          !_shouldKeepPageAfterRead(
            pending.request,
            backgroundPrewarmGeneration: backgroundPrewarmGeneration,
          ),
      urgency: _urgencyForPageOrdinal(pending.page.ordinal),
    );
    _presentationPreparing = false;
    if (outcome == CommittedPagePresentationOutcome.committed) return true;
    if (isMotionActive?.call() ?? false) {
      _forwardRequestStates.remove(identity);
      _deferForwardDemand();
      _logControllerReject(
        pending.request,
        reason: 'presentationMotionPreempted',
      );
      return false;
    }
    stalePageRejectCount += 1;
    _markRequestFailed(identity);
    return false;
  }

  bool _accepts(
    CommittedLogPage page, {
    required DashboardCommittedPageRequest request,
  }) {
    return _isCurrentRequest(request) &&
        page.queryKey == request.scope.key &&
        page.coreRevision == request.coreRevision &&
        page.generation == request.commitGeneration &&
        page.ordinal == request.pageOrdinal;
  }

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

  bool _isCurrentPendingPresentation(
    _PendingCommittedPagePresentation pending,
  ) =>
      identical(_pendingPresentation, pending) &&
      _isCurrentRequest(pending.request);

  int get _targetOrdinal =>
      _desiredForwardOrdinal > _backgroundPrewarmTargetOrdinal
      ? _desiredForwardOrdinal
      : _backgroundPrewarmTargetOrdinal;

  CommittedPagePreparationUrgency _urgencyForPageOrdinal(int ordinal) =>
      ordinal <= _desiredForwardOrdinal
      ? CommittedPagePreparationUrgency.frontierCritical
      : CommittedPagePreparationUrgency.background;

  bool _shouldKeepPageAfterRead(
    DashboardCommittedPageRequest request, {
    required int? backgroundPrewarmGeneration,
  }) =>
      _isCurrentRequest(request) &&
      (backgroundPrewarmGeneration == null ||
          request.pageOrdinal <= _desiredForwardOrdinal ||
          (backgroundPrewarmGeneration == _backgroundPrewarmGeneration &&
              request.pageOrdinal <= _backgroundPrewarmTargetOrdinal &&
              _canRunBackgroundPrewarm()));

  bool _canRunBackgroundPrewarm() => canRunBackgroundPrewarm?.call() ?? true;

  void _promotePendingPresentationForForegroundDemand() {
    final pending = _pendingPresentation;
    if (pending == null || pending.page.ordinal > _desiredForwardOrdinal) {
      return;
    }
    unawaited(
      _committedViewport.prepareAndCommitOutcome(
        pending.page,
        shouldPreempt: isMotionActive,
        urgency: CommittedPagePreparationUrgency.frontierCritical,
      ),
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_HOTSET_PREWARM_PROMOTED',
        queryKey: pending.page.queryKey.value,
        coreRevision: pending.page.coreRevision,
        entryCount: pending.page.rowCount,
        message: 'pageOrdinal=${pending.page.ordinal}',
      ),
    );
  }

  void _reportBackgroundPrewarmReadyIfSettled() {
    if (_backgroundPrewarmTargetOrdinal == 0 ||
        _nextPageOrdinal <= _backgroundPrewarmTargetOrdinal) {
      return;
    }
    final template = _committedTemplate;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_HOTSET_PREWARM_READY',
        queryKey: template?.queryKey.value,
        coreRevision: template?.coreRevision,
        entryCount: _committedViewport.contiguousReadyRowCount,
        message:
            'highestReady=${_committedViewport.highestReadyPageOrdinal} '
            'retainedPages=${_committedViewport.retainedPageCount} '
            'preparedRows=${_committedViewport.preparedTextRowCount} '
            'estimatedBytes=${_committedViewport.estimatedBytes}',
      ),
    );
    _backgroundPrewarmTargetOrdinal = 0;
    _boundedReadyHotsetIntent = null;
    _lastRetainedHotsetReason = null;
  }

  _BoundedReadyHotsetIntent? _newBoundedReadyHotsetIntent(
    DashboardVisibleFrame frame,
  ) {
    if (frame.logBox.nextCursor == null || frame.count.entryCount <= pageSize) {
      return null;
    }
    return _BoundedReadyHotsetIntent(
      queryKey: frame.queryKey,
      coreRevision: frame.coreRevision,
      commitGeneration: _commitGeneration,
    );
  }

  void _retainBoundedReadyHotsetIntent() {
    final template = _committedTemplate;
    if (_disposed || template == null || _boundedReadyHotsetIntent != null) {
      return;
    }
    _boundedReadyHotsetIntent = _newBoundedReadyHotsetIntent(template);
    _logRetainedHotsetIntent(reason: 'requested');
  }

  bool _hasCurrentBoundedReadyHotsetIntent(DashboardVisibleFrame template) {
    final intent = _boundedReadyHotsetIntent;
    if (intent == null) return false;
    if (intent.matches(frame: template, generation: _commitGeneration)) {
      return true;
    }
    _boundedReadyHotsetIntent = null;
    _lastRetainedHotsetReason = null;
    return false;
  }

  int? _boundedReadyHotsetTarget(DashboardVisibleFrame template) {
    if (_nextCursor == null) return null;
    final lastPossibleOrdinal = template.count.entryCount == 0
        ? 0
        : (template.count.entryCount - 1) ~/ pageSize;
    final target = (_nextPageOrdinal + 1)
        .clamp(_nextPageOrdinal, lastPossibleOrdinal)
        .toInt();
    return target < _nextPageOrdinal ? null : target;
  }

  void _logRetainedHotsetIntent({required String reason}) {
    final template = _committedTemplate;
    final intent = _boundedReadyHotsetIntent;
    if (template == null ||
        intent == null ||
        _lastRetainedHotsetReason == reason) {
      return;
    }
    _lastRetainedHotsetReason = reason;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_HOTSET_PREWARM_INTENT_RETAINED',
        queryKey: intent.queryKey.value,
        coreRevision: intent.coreRevision,
        message:
            'reason=$reason generation=${intent.commitGeneration} '
            'targetReadyOrdinal=${_boundedReadyHotsetTarget(template) ?? -1}',
      ),
    );
  }

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
    if (record == null) return;
    record.state = state;
  }

  void _markRequestFailed(String identity) {
    final record = _forwardRequestStates[identity];
    if (record == null) return;
    record.state = CommittedVerticalPageRequestState.failed;
    record.demandEpoch = _forwardDemandEpoch;
  }

  void _deferForwardDemand() {
    motionPageSuppressCount += 1;
    if (_forwardDemandDeferred) return;
    _forwardDemandDeferred = true;
    _logForwardDemand(
      'VERTICAL_FORWARD_DEMAND_DEFERRED',
      desiredOrdinal: _desiredForwardOrdinal,
      drainActive: _forwardDemandDrain != null,
      reason: 'motionActive',
    );
  }

  void _logForwardDemand(
    String stage, {
    required int desiredOrdinal,
    required bool drainActive,
    String? reason,
  }) {
    final template = _committedTemplate;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: stage,
        queryKey: template?.queryKey.value,
        coreRevision: template?.coreRevision,
        message:
            'desiredOrdinal=$desiredOrdinal nextOrdinal=$_nextPageOrdinal '
            'demandEpoch=$_forwardDemandEpoch '
            'motionActive=${isMotionActive?.call() ?? false} '
            'drainActive=$drainActive'
            '${reason == null ? '' : ' reason=$reason'}',
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
    _backgroundPrewarmTargetOrdinal = 0;
    _backgroundPrewarmGeneration += 1;
    _boundedReadyHotsetIntent = null;
    _lastRetainedHotsetReason = null;
    _forwardDemandDeferred = false;
    _pendingPresentation = null;
    _pageRequestInFlight = false;
    _presentationPreparing = false;
    _forwardRequestStates.clear();
  }
}
