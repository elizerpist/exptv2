import 'package:flutter/foundation.dart';

import '../domain/prepared_presentation_frame.dart';
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
    this.pageSize = 24,
    this.isMotionActive,
    this.onPageRequested,
  }) : _repository = repository,
       _visibleFrames = visibleFrames;

  final DashboardCommittedPageRepository _repository;
  final DashboardVisibleFrameStore _visibleFrames;
  final int pageSize;
  final bool Function()? isMotionActive;
  final ValueChanged<DashboardCommittedPageRequest>? onPageRequested;

  DashboardVisibleFrame? _committedTemplate;
  int _commitGeneration = 0;
  bool _pageInFlight = false;
  bool _disposed = false;

  int pageReadCount = 0;
  int stalePageRejectCount = 0;
  int duplicatePageSuppressCount = 0;
  int motionPageSuppressCount = 0;

  LedgerQueryKey? get committedQueryKey => _committedTemplate?.queryKey;
  int? get committedRevision => _committedTemplate?.coreRevision;
  int get commitGeneration => _commitGeneration;

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
    if (!sameCommit) _commitGeneration += 1;
  }

  Future<bool> loadNextPage() async {
    final template = _committedTemplate;
    final after = template?.logBox.nextCursor;
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
      reason: DataAcquisitionReason.explicitCommittedVerticalPaging,
    );
    request.reason.requirePageRead();
    onPageRequested?.call(request);
    _pageInFlight = true;
    pageReadCount += 1;
    try {
      final prepared = await _repository.readCommittedPage(
        request,
        after: after,
        currentFrame: template.preparedFrame,
      );
      if (!_accepts(prepared, request: request)) {
        stalePageRejectCount += 1;
        return false;
      }
      final currentTemplate = _committedTemplate!;
      final next = DashboardVisibleFrame.fromPrepared(
        prepared,
        parentQueryKey: currentTemplate.parentQueryKey,
        plane: currentTemplate.plane,
        railOpen: currentTemplate.railOpen,
        semanticIndex: currentTemplate.semanticChildIndex,
        childLabel: currentTemplate.childLabel,
        navigationEpoch: currentTemplate.navigationEpoch,
        presentationEpoch: currentTemplate.presentationEpoch,
        frameGeneration: _visibleFrames.nextFrameGeneration(),
        mode: DashboardVisibleMode.committed,
      );
      _committedTemplate = next;
      return _visibleFrames.publish(next);
    } finally {
      _pageInFlight = false;
    }
  }

  bool _accepts(
    DashboardPreparedFrame prepared, {
    required DashboardCommittedPageRequest request,
  }) {
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
        visible.coreRevision == current.coreRevision &&
        prepared.queryKey == request.scope.key &&
        prepared.coreRevision == request.coreRevision &&
        prepared.scope == request.scope;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _commitGeneration += 1;
    _committedTemplate = null;
  }
}
