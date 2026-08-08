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
    this.onPageRequested,
    this.onPageCompleted,
  }) : _repository = repository,
       _visibleFrames = visibleFrames,
       _committedViewport = committedViewport;

  final DashboardCommittedPageRepository _repository;
  final DashboardVisibleFrameStore _visibleFrames;
  final CommittedLogViewportCache _committedViewport;
  final int pageSize;
  final bool Function()? isMotionActive;
  final ValueChanged<DashboardCommittedPageRequest>? onPageRequested;
  final ValueChanged<DashboardCommittedPageRequest>? onPageCompleted;

  DashboardVisibleFrame? _committedTemplate;
  int _commitGeneration = 0;
  Map<String, Object?>? _nextCursor;
  Map<String, Object?>? _previousStartCursor;
  int _nextPageOrdinal = 1;
  int _desiredForwardOrdinal = 0;
  int _forwardDemandEpoch = 0;
  Future<bool>? _forwardDemandDrain;
  bool _pageInFlight = false;
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
  CommittedLogViewportCache get committedViewport => _committedViewport;

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
      _forwardDemandEpoch = 0;
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
    if (active != null) {
      if (desiredLastReadyOrdinal <= previousDesired) {
        duplicatePageSuppressCount += 1;
      }
      return active;
    }
    late final Future<bool> operation;
    operation = _drainForwardDemand().whenComplete(() {
      if (identical(_forwardDemandDrain, operation)) {
        _forwardDemandDrain = null;
      }
    });
    _forwardDemandDrain = operation;
    return operation;
  }

  Future<bool> _drainForwardDemand() async {
    var committedAny = false;
    while (!_disposed &&
        _nextCursor != null &&
        _nextPageOrdinal <= _desiredForwardOrdinal) {
      if (isMotionActive?.call() ?? false) {
        motionPageSuppressCount += 1;
        return committedAny;
      }
      final didCommit = await _loadOneNextPage();
      if (!didCommit) return committedAny;
      committedAny = true;
    }
    return committedAny;
  }

  Future<bool> _loadOneNextPage() async {
    final template = _committedTemplate;
    final after = _nextCursor;
    if (_disposed ||
        template == null ||
        template.mode != DashboardVisibleMode.committed ||
        after == null) {
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
    final generation = _commitGeneration;
    final request = DashboardCommittedPageRequest(
      scope: template.scope,
      parentQueryKey: template.parentQueryKey,
      coreRevision: template.coreRevision,
      presentationEpoch: template.presentationEpoch,
      commitGeneration: generation,
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
    return _readAndCommit(request, advancesForward: true);
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
  }) async {
    _pageInFlight = true;
    pageReadCount += 1;
    final startedAt = Stopwatch()..start();
    final identity = _requestIdentity(request);
    try {
      final page = await _repository.readCommittedPage(request);
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
          message: 'ordinal=${page.ordinal}',
        ),
      );
      // A low-priority vertical response may finish after rail motion has
      // begun. Its page preparation would allocate paragraph resources on the
      // UI isolate, so discard it rather than letting it perturb the frozen
      // rail path; the next explicit vertical demand can re-read the keyset
      // cursor when the rail is idle.
      if (isMotionActive?.call() ?? false) {
        motionPageSuppressCount += 1;
        _markRequestFailed(identity);
        _logControllerReject(request, reason: 'motionPreempted');
        return false;
      }
      _setRequestState(
        identity,
        CommittedVerticalPageRequestState.presentationPreparing,
      );
      if (!_committedViewport.commit(page)) {
        stalePageRejectCount += 1;
        _markRequestFailed(identity);
        return false;
      }
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
      _pageInFlight = false;
    }
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
    _forwardRequestStates.clear();
  }
}
