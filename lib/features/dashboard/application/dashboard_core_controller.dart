import 'dart:async';

import '../../../core/design/dashboard_layout_metrics.dart';
import '../../../shared/motion/centered_carousel/centered_carousel_controller.dart';
import '../motion/dashboard_display_frame_coalescer.dart';
import '../motion/dashboard_motion_kernel.dart';
import '../motion/dashboard_motion_state.dart';
import '../motion/dashboard_semantic_catalog.dart';
import '../query/domain/ledger_direction.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../runtime/application/dashboard_data_runtime.dart';
import '../runtime/application/dashboard_presentation_controller.dart';
import '../runtime/application/explicit_committed_paging_controller.dart';
import '../runtime/data/dashboard_data_runtime_repository.dart';
import '../runtime/data/empty_dashboard_data_runtime_repository.dart';
import '../runtime/domain/prepared_dashboard_index.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../visible/application/dashboard_visible_frame_store.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_interaction_diagnostics.dart';
import 'dashboard_performance_counters.dart';
import 'transaction_direction_controller.dart';

enum DashboardMotionLane { rail, visualHost, summaryShell, summaryText, amount }

/// Dashboard composition root.
///
/// Data acquisition is owned exclusively by [DashboardDataRuntime]. Every
/// navigation method below delegates to the synchronous RAM-only
/// [DashboardPresentationController]. Settle only commits metadata to the
/// explicit vertical paging owner and never starts acquisition.
final class DashboardCoreController {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardDataRuntimeRepository? dataRepository,
    DashboardDisplayFrameScheduler? displayFrameScheduler,
    DashboardStableFrameScheduler? stableFrameScheduler,
    DateTime? initialDate,
    bool seedReady = true,
    int? initialCoreRevision,
    this.pageSize = 24,
    int yearWindowRadius = 12,
    DashboardPerformanceCounters? performanceCounters,
    DashboardInteractionDiagnostics? interactionDiagnostics,
  }) : expansion = DashboardExpansionController(metrics: metrics),
       transactionDirection = TransactionDirectionController(),
       _seedReady = seedReady,
       _initialCoreRevision = initialCoreRevision {
    this.performanceCounters =
        interactionDiagnostics?.counters ??
        performanceCounters ??
        DashboardPerformanceCounters();
    diagnostics =
        interactionDiagnostics ??
        DashboardInteractionDiagnostics(counters: this.performanceCounters);
    final repository =
        dataRepository ?? const EmptyDashboardDataRuntimeRepository();

    late final DashboardDataRuntime runtimeOwner;
    late final ExplicitCommittedPagingController pagingOwner;
    presentation = DashboardPresentationController(
      initialDate: initialDate,
      displayFrameScheduler: displayFrameScheduler,
      onMotionActiveChanged: (active) {
        _setMotionLaneActive(DashboardMotionLane.rail, active);
      },
      onCommittedFrame: (frame) {
        pagingOwner.commitMetadata(frame);
      },
      onSemanticCrossed: _onSemanticCrossed,
      onSettled: _onSettled,
      onBallisticStarted: _onBallisticStarted,
    );
    pagingOwner = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: presentation.visibleFrames,
      pageSize: pageSize,
      isMotionActive: () => diagnostics.isMotionActive,
      onPageRequested: (request) {
        diagnostics.record(
          DashboardInteractionEvent.verticalPageRequested,
          context: _diagnosticContext(
            queryKey: request.scope.key,
            revision: request.coreRevision,
            acquisitionReason: request.reason,
          ),
          source: 'committedNearEnd',
        );
      },
    );
    paging = pagingOwner;
    final requestTemplate = DashboardIndexRequestTemplate(
      filterScope: presentation.navigation.state.parentQueryScope,
      pageSize: pageSize,
      initialYear: presentation.navigation.state.retainedChildYear,
      yearWindowRadius: yearWindowRadius,
    );
    runtimeOwner = DashboardDataRuntime(
      revisionObserver: GlobalCoreRevisionObserver(repository: repository),
      indexBuilder: PreparedDashboardIndexBuilder(repository: repository),
      requestTemplate: requestTemplate,
      onGlobalRevisionWatchSubscribed: () {
        diagnostics.record(
          DashboardInteractionEvent.globalRevisionWatchSubscribed,
          context: _diagnosticContext(),
          source: 'dashboardSession',
        );
      },
      onGlobalRevisionChanged: (revision) {
        diagnostics.record(
          DashboardInteractionEvent.globalRevisionChanged,
          context: _diagnosticContext(revision: revision),
          source: 'roomCoreRevision',
        );
      },
      onIndexBuildStarted: (request, generation) {
        diagnostics.record(
          DashboardInteractionEvent.indexBuildStarted,
          context: _diagnosticContext(
            revision: request.key.coreRevision,
            dataGeneration: generation,
            acquisitionReason: request.reason,
          ),
          source: request.reason.name,
        );
      },
      onIndexBuildReady: (index, reason, duration) {
        diagnostics.record(
          DashboardInteractionEvent.indexBuildReady,
          context: _diagnosticContext(
            revision: index.coreRevision,
            dataGeneration: index.generation,
            acquisitionReason: reason,
          ),
          source: reason.name,
          duration: duration,
        );
      },
      onIndexBuildDiscarded: (request, generation) {
        diagnostics.record(
          DashboardInteractionEvent.staleCallbackRejected,
          context: _diagnosticContext(
            revision: request.key.coreRevision,
            dataGeneration: generation,
            acquisitionReason: request.reason,
          ),
          source: 'indexGeneration',
        );
      },
      onIndexPublished: (index) {
        // DashboardDataRuntime publishes only at bootstrap or on the first
        // stable idle frame. Install the index and its complete visible frame
        // as one atomic revision boundary; a second coalescer frame here would
        // temporarily mix the new index with the previous visible revision.
        presentation.installIndex(index, publishImmediately: true);
        diagnostics.record(
          DashboardInteractionEvent.indexPublished,
          context: _diagnosticContext(),
          source: 'dataRuntime',
        );
      },
      stableFrameScheduler: stableFrameScheduler,
    );
    dataRuntime = runtimeOwner;
    presentation.visibleFrames.addListener(_onVisibleFramePublished);
  }

  final DashboardLayoutMetrics metrics;
  final int pageSize;
  final DashboardExpansionController expansion;
  final TransactionDirectionController transactionDirection;
  late final DashboardPerformanceCounters performanceCounters;
  late final DashboardInteractionDiagnostics diagnostics;
  late final DashboardPresentationController presentation;
  late final DashboardDataRuntime dataRuntime;
  late final ExplicitCommittedPagingController paging;

  late bool _seedReady;
  final int? _initialCoreRevision;
  Completer<void>? _seedReadyCompleter;
  bool _bootstrapped = false;
  bool _disposed = false;
  final Set<DashboardMotionLane> _activeMotionLanes = <DashboardMotionLane>{};

  DashboardNavigationController get navigation => presentation.navigation;
  DashboardMotionKernel get motion => presentation.motion;
  DashboardVisibleFrameStore get visibleFrames => presentation.visibleFrames;
  DashboardDisplayFrameCoalescer get frameCoalescer =>
      presentation.frameCoalescer;
  PreparedDashboardIndex? get preparedIndex => dataRuntime.currentIndex;
  int? get coreRevision => dataRuntime.currentIndex?.coreRevision;
  bool get isBootstrapped => _bootstrapped;

  Future<DashboardVisibleFrame> bootstrap({int? coreRevision}) async {
    if (_disposed) throw StateError('Dashboard core has been disposed.');
    if (!_seedReady) {
      _seedReadyCompleter ??= Completer<void>();
      await _seedReadyCompleter!.future;
    }
    final index = await dataRuntime.bootstrap(
      initialCoreRevision: coreRevision ?? _initialCoreRevision,
    );
    final frame = visibleFrames.value;
    if (frame == null || frame.coreRevision != index.coreRevision) {
      throw StateError('Bootstrap did not publish one complete visible frame.');
    }
    _bootstrapped = true;
    return frame;
  }

  void markSeedCommitted({int? coreRevision}) {
    if (_disposed) return;
    _seedReady = true;
    if (coreRevision != null && coreRevision <= 0) {
      throw ArgumentError.value(coreRevision, 'coreRevision');
    }
    _seedReadyCompleter?.complete();
    _seedReadyCompleter = null;
  }

  void beginRailMotion(CenteredCarouselMotionOrigin origin) {
    presentation.beginRailMotion(origin);
    if (origin == CenteredCarouselMotionOrigin.userDrag) {
      diagnostics.record(
        DashboardInteractionEvent.motionGestureStarted,
        context: _diagnosticContext(),
        source: 'railGesture',
      );
    }
  }

  void semanticCrossed(int logicalIndex) => diagnostics.runMotionHotPath(
    () => presentation.semanticCrossed(logicalIndex),
  );

  void settleRail(int logicalIndex) => presentation.settleRail(logicalIndex);

  void toggleRail() => setRailOpen(!navigation.state.isRailOpen);

  void setRailOpen(bool open) {
    presentation.setRailOpen(open);
    _recordNavigationSelection(open ? 'railOpened' : 'railClosed');
  }

  void navigateParent(DashboardTimeNavigationChangeDirection direction) {
    presentation.navigateParent(direction);
    _recordNavigationSelection('parentCommitted');
  }

  void commitParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) => navigateParent(direction);

  DashboardNavigationState? previewParent(
    DashboardTimeNavigationChangeDirection direction,
  ) => presentation.parentCandidate(direction);

  void navigatePlane({required bool finer}) {
    presentation.navigatePlane(finer: finer);
    _recordNavigationSelection('planeCommitted');
  }

  void selectDirection(TransactionDirection direction) {
    transactionDirection.select(direction);
    presentation.selectDirection(
      direction == TransactionDirection.income
          ? LedgerDirection.income
          : LedgerDirection.expense,
    );
    _recordNavigationSelection('directionChanged');
  }

  Future<bool> loadNextPage() => paging.loadNextPage();

  void setMotionLaneActive(DashboardMotionLane lane, bool active) {
    if (_disposed || lane == DashboardMotionLane.rail) return;
    _setMotionLaneActive(lane, active);
  }

  void _setMotionLaneActive(DashboardMotionLane lane, bool active) {
    final changed = active
        ? _activeMotionLanes.add(lane)
        : _activeMotionLanes.remove(lane);
    if (!changed) return;
    final anyActive = _activeMotionLanes.isNotEmpty;
    diagnostics.setMotionActive(anyActive);
    dataRuntime.setMotionActive(anyActive);
  }

  void _onSemanticCrossed(
    DashboardSemanticEntry entry,
    DashboardMotionContext context,
  ) {
    if (!diagnostics.recordsSemanticCrossings) return;
    diagnostics.record(
      DashboardInteractionEvent.railChildCrossed,
      context: _diagnosticContext(
        queryKey: entry.queryKey,
        semanticIndex: context.semanticIndex,
      ),
      source: 'preparedIndex',
    );
    diagnostics.record(
      DashboardInteractionEvent.motionFrameTargetSelected,
      context: _diagnosticContext(
        queryKey: entry.queryKey,
        semanticIndex: context.semanticIndex,
      ),
      source: 'ramLookup',
    );
  }

  void _onSettled(
    DashboardSemanticEntry entry,
    DashboardMotionContext context,
  ) {
    diagnostics.record(
      DashboardInteractionEvent.motionSettled,
      context: _diagnosticContext(
        queryKey: entry.queryKey,
        semanticIndex: context.semanticIndex,
      ),
      source: 'metadataOnly',
    );
    diagnostics.record(
      DashboardInteractionEvent.settleMetadataCommitted,
      context: _diagnosticContext(
        queryKey: entry.queryKey,
        semanticIndex: context.semanticIndex,
      ),
      source: 'metadataOnly',
    );
  }

  void _recordNavigationSelection(String source) {
    diagnostics.record(
      DashboardInteractionEvent.navPresentationSelected,
      context: _diagnosticContext(
        queryKey: presentation.expectedVisibleQueryKey,
      ),
      source: source,
    );
  }

  void _onBallisticStarted(double _, DashboardMotionContext context) {
    diagnostics.record(
      DashboardInteractionEvent.motionBallisticStarted,
      context: _diagnosticContext(semanticIndex: context.semanticIndex),
      source: 'railPhysics',
    );
  }

  void _onVisibleFramePublished() {
    final frame = visibleFrames.value;
    if (frame == null) return;
    diagnostics.record(
      DashboardInteractionEvent.visibleFramePublished,
      context: _diagnosticContext(frame: frame),
      source: frame.mode.name,
    );
  }

  DashboardDiagnosticContext _diagnosticContext({
    DashboardVisibleFrame? frame,
    LedgerQueryKey? queryKey,
    int? semanticIndex,
    int? revision,
    int? dataGeneration,
    DataAcquisitionReason? acquisitionReason,
  }) {
    final motionState = presentation.motion.state;
    final navigationState = presentation.navigation.state;
    final visible = frame ?? presentation.visibleFrames.value;
    return DashboardDiagnosticContext(
      gestureId: motionState.gestureId,
      motionEpoch: motionState.motionEpoch,
      navigationEpoch:
          visible?.navigationEpoch ?? navigationState.navigationEpoch,
      presentationEpoch: visible?.presentationEpoch ?? 0,
      queryKey: queryKey ?? visible?.queryKey,
      parentQueryKey: visible?.parentQueryKey ?? navigationState.parentQueryKey,
      coreRevision: revision ?? visible?.coreRevision ?? coreRevision ?? 0,
      semanticIndex:
          semanticIndex ??
          visible?.semanticChildIndex ??
          motionState.semanticIndex,
      frameNumber: presentation.frameCoalescer.currentFrameNumber,
      presentationGeneration: visible?.frameGeneration ?? 0,
      dataGeneration: dataGeneration ?? preparedIndex?.generation ?? 0,
      presentationMode: visible?.mode == DashboardVisibleMode.preview
          ? DashboardPresentationMode.preview
          : DashboardPresentationMode.committed,
      dataOrigin: visible == null || preparedIndex == null
          ? DashboardDataOrigin.preparedIndex
          : preparedIndex!.originFor(visible.queryKey),
      motionState: motionState.activity,
      acquisitionReason: acquisitionReason,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeMotionLanes.clear();
    visibleFrames.removeListener(_onVisibleFramePublished);
    dataRuntime.dispose();
    paging.dispose();
    presentation.dispose();
    transactionDirection.dispose();
    expansion.dispose();
  }
}
