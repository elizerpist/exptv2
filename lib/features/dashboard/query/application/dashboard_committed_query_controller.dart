import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../prepared/data/dashboard_prepared_deck_repository.dart';
import '../../prepared/domain/dashboard_prepared_deck.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';

typedef DashboardLiveLeaseStarted =
    void Function(DashboardCommittedFrameRequest request);
typedef DashboardCommittedPageReadStarted =
    void Function(DashboardCommittedFrameRequest request);
typedef DashboardLiveFrameObserved =
    void Function(
      DashboardPreparedFrame frame,
      DashboardCommittedFrameRequest request,
    );

@immutable
final class DashboardCommittedState {
  const DashboardCommittedState({
    required this.committedScope,
    required this.committedQueryKey,
    required this.committedRevision,
    required this.committedEpoch,
    required this.liveLeaseGeneration,
  });

  final CurrentLedgerQueryScope? committedScope;
  final LedgerQueryKey? committedQueryKey;
  final int? committedRevision;
  final int committedEpoch;
  final int liveLeaseGeneration;

  bool get hasCommit => committedScope != null;
}

/// Sole owner of the one live dashboard lease.
///
/// Motion preview never calls this controller. A settle promotes the already
/// visible frame, then this owner immediately invalidates the previous lease,
/// cancels it and starts one exact committed stream with latest-wins guards.
final class DashboardCommittedQueryController extends ChangeNotifier {
  DashboardCommittedQueryController({
    required DashboardVisibleFrameStore visibleFrames,
    DashboardPreparedLiveRepository? repository,
    this.pageSize = 24,
    this.onLiveLeaseStarted,
    this.onPageReadStarted,
    this.onLiveFrameAccepted,
    this.onStaleCallbackRejected,
  }) : _visibleFrames = visibleFrames,
       _repository = repository;

  final DashboardVisibleFrameStore _visibleFrames;
  final DashboardPreparedLiveRepository? _repository;
  final int pageSize;
  final DashboardLiveLeaseStarted? onLiveLeaseStarted;
  final DashboardCommittedPageReadStarted? onPageReadStarted;
  final DashboardLiveFrameObserved? onLiveFrameAccepted;
  final DashboardLiveFrameObserved? onStaleCallbackRejected;

  DashboardCommittedState _state = const DashboardCommittedState(
    committedScope: null,
    committedQueryKey: null,
    committedRevision: null,
    committedEpoch: 0,
    liveLeaseGeneration: 0,
  );
  StreamSubscription<DashboardPreparedFrame>? _subscription;
  DashboardVisibleFrame? _committedTemplate;
  bool _disposed = false;
  int _nextFrameGeneration = 0;

  int liveLeaseStartCount = 0;
  int liveFrameAcceptedCount = 0;
  int staleCallbackRejectedCount = 0;
  int pageReadCount = 0;

  DashboardCommittedState get state => _state;

  Future<void> commit(DashboardVisibleFrame frame) async {
    if (_disposed) return;
    if (frame.mode != DashboardVisibleMode.committed) {
      throw ArgumentError.value(
        frame.mode,
        'frame.mode',
        'a live lease requires a committed frame',
      );
    }
    final currentTemplate = _committedTemplate;
    final alreadyOwnsExactLease =
        currentTemplate != null &&
        _state.committedQueryKey == frame.queryKey &&
        _state.committedRevision == frame.coreRevision &&
        _state.committedEpoch == frame.presentationEpoch &&
        currentTemplate.parentQueryKey == frame.parentQueryKey &&
        currentTemplate.navigationEpoch == frame.navigationEpoch &&
        (_repository == null || _subscription != null);
    if (alreadyOwnsExactLease) return;
    final generation = _state.liveLeaseGeneration + 1;
    _state = DashboardCommittedState(
      committedScope: frame.scope,
      committedQueryKey: frame.queryKey,
      committedRevision: frame.coreRevision,
      committedEpoch: frame.presentationEpoch,
      liveLeaseGeneration: generation,
    );
    _committedTemplate = frame.asCommitted();
    _nextFrameGeneration = frame.frameGeneration;
    notifyListeners();

    final old = _subscription;
    _subscription = null;
    if (old != null) await old.cancel();
    if (_disposed || generation != _state.liveLeaseGeneration) return;

    final repository = _repository;
    if (repository == null) return;
    final scope = frame.scope;
    final request = DashboardCommittedFrameRequest(
      scope: scope,
      parentQueryKey: frame.parentQueryKey,
      coreRevision: frame.coreRevision,
      presentationEpoch: frame.presentationEpoch,
      leaseGeneration: generation,
      pageSize: pageSize,
    );
    liveLeaseStartCount += 1;
    onLiveLeaseStarted?.call(request);
    _subscription = repository
        .watchCommittedFrame(request)
        .listen(
          (prepared) => _accept(prepared, request: request),
          onError: (Object _, StackTrace _) {},
        );
  }

  Future<bool> loadNextPage() async {
    final repository = _repository;
    final template = _committedTemplate;
    final state = _state;
    final after = template?.logBox.nextCursor;
    if (repository == null ||
        template == null ||
        template.mode != DashboardVisibleMode.committed ||
        after == null ||
        state.committedScope == null) {
      return false;
    }
    final request = DashboardCommittedFrameRequest(
      scope: state.committedScope!,
      parentQueryKey: template.parentQueryKey,
      coreRevision: state.committedRevision!,
      presentationEpoch: state.committedEpoch,
      leaseGeneration: state.liveLeaseGeneration,
      pageSize: pageSize,
    );
    pageReadCount += 1;
    onPageReadStarted?.call(request);
    final prepared = await repository.readCommittedNextPage(
      request,
      after: after,
      currentFrame: template.preparedFrame,
    );
    return _accept(prepared, request: request);
  }

  bool _accept(
    DashboardPreparedFrame prepared, {
    required DashboardCommittedFrameRequest request,
  }) {
    final state = _state;
    final template = _committedTemplate;
    if (_disposed ||
        template == null ||
        request.leaseGeneration != state.liveLeaseGeneration ||
        request.presentationEpoch != state.committedEpoch ||
        request.coreRevision != state.committedRevision ||
        request.scope.key != state.committedQueryKey ||
        prepared.queryKey != request.scope.key ||
        prepared.parentQueryKey != request.parentQueryKey ||
        prepared.coreRevision != request.coreRevision ||
        prepared.scope != request.scope) {
      staleCallbackRejectedCount += 1;
      onStaleCallbackRejected?.call(prepared, request);
      return false;
    }
    final next = DashboardVisibleFrame.fromPrepared(
      prepared,
      parentQueryKey: template.parentQueryKey,
      plane: template.plane,
      railOpen: template.railOpen,
      semanticIndex: template.semanticChildIndex,
      childLabel: template.childLabel,
      navigationEpoch: template.navigationEpoch,
      presentationEpoch: template.presentationEpoch,
      frameGeneration: ++_nextFrameGeneration,
      mode: DashboardVisibleMode.committed,
    );
    _committedTemplate = next;
    liveFrameAcceptedCount += 1;
    _visibleFrames.publish(next);
    onLiveFrameAccepted?.call(prepared, request);
    return true;
  }

  void invalidate() {
    _state = DashboardCommittedState(
      committedScope: null,
      committedQueryKey: null,
      committedRevision: null,
      committedEpoch: 0,
      liveLeaseGeneration: _state.liveLeaseGeneration + 1,
    );
    _committedTemplate = null;
    final old = _subscription;
    _subscription = null;
    unawaited(old?.cancel());
  }

  @override
  void dispose() {
    _disposed = true;
    invalidate();
    super.dispose();
  }
}
