import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import '../data/dashboard_data_runtime_repository.dart';
import '../domain/prepared_dashboard_index.dart';

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
  bool _pageInFlight = false;
  bool _disposed = false;

  int pageReadCount = 0;
  int stalePageRejectCount = 0;
  int duplicatePageSuppressCount = 0;
  int motionPageSuppressCount = 0;

  LedgerQueryKey? get committedQueryKey => _committedTemplate?.queryKey;
  int? get committedRevision => _committedTemplate?.coreRevision;
  int get commitGeneration => _commitGeneration;
  CommittedLogViewportCache get committedViewport => _committedViewport;

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

  Future<bool> loadNextPage() async {
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
    request.reason.requirePageRead();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PAGE_REQUESTED',
        queryKey: request.scope.key.value,
        coreRevision: request.coreRevision,
        message: 'ordinal=${request.pageOrdinal}',
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
    try {
      final page = await _repository.readCommittedPage(request);
      if (!_accepts(page, request: request)) {
        stalePageRejectCount += 1;
        return false;
      }
      // A low-priority vertical response may finish after rail motion has
      // begun. Its page preparation would allocate paragraph resources on the
      // UI isolate, so discard it rather than letting it perturb the frozen
      // rail path; the next explicit vertical demand can re-read the keyset
      // cursor when the rail is idle.
      if (isMotionActive?.call() ?? false) {
        motionPageSuppressCount += 1;
        return false;
      }
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'VERTICAL_PAGE_READY',
          queryKey: page.queryKey.value,
          coreRevision: page.coreRevision,
          entryCount: page.rowCount,
          message: 'ordinal=${page.ordinal}',
        ),
      );
      if (!_committedViewport.commit(page)) {
        stalePageRejectCount += 1;
        return false;
      }
      if (advancesForward) {
        _previousStartCursor = request.startCursor;
        _nextCursor = page.nextCursor;
        _nextPageOrdinal = request.pageOrdinal + 1;
      }
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

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _commitGeneration += 1;
    _nextCursor = null;
    _previousStartCursor = null;
    _committedTemplate = null;
  }
}
