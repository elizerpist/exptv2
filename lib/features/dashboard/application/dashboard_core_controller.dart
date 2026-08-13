import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../core/design/dashboard_layout_metrics.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../shared/motion/centered_carousel/centered_carousel_controller.dart';
import '../logbox/application/committed_log_viewport_cache.dart';
import '../logbox/application/dashboard_logbox_render_domain.dart';
import '../logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import '../logbox/application/dashboard_log_viewport_state.dart';
import '../logbox/application/dashboard_logbox_scene_window.dart';
import '../motion/dashboard_display_frame_coalescer.dart';
import '../motion/dashboard_motion_kernel.dart';
import '../motion/dashboard_motion_state.dart';
import '../motion/dashboard_semantic_catalog.dart';
import '../query/domain/ledger_direction.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/dashboard_directional_query_set.dart';
import '../query/application/current_query_controller.dart';
import '../query/application/query_composer_controller.dart';
import '../query/domain/query_menu_data.dart';
import '../runtime/application/dashboard_data_runtime.dart';
import '../runtime/application/dashboard_presentation_controller.dart';
import '../runtime/application/explicit_committed_paging_controller.dart';
import '../runtime/data/dashboard_data_runtime_repository.dart';
import '../runtime/data/empty_dashboard_data_runtime_repository.dart';
import '../runtime/domain/dashboard_prepared_revision_bundle.dart';
import '../runtime/domain/prepared_dashboard_index.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/dashboard_temporal_availability.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/time_plane.dart';
import '../time_navigation/presentation/summary_navigation_presentation.dart';
import '../visible/application/dashboard_visible_frame_store.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_vertical_background_work_snapshot.dart';
import 'dashboard_interaction_diagnostics.dart';
import 'dashboard_performance_counters.dart';
import 'prepared_query_candidate.dart';
import 'dashboard_rail_flight_recorder.dart';
import 'dashboard_render_readiness_diagnostics.dart';
import 'transaction_direction_controller.dart';

enum DashboardMotionLane { rail, visualHost, summaryShell, summaryText, amount }

/// A pending structural navigation establishes the renderability needed before
/// it may publish. Maintenance derived from the already-committed state has a
/// lower authority and may never replace that pending user intent.
enum _SceneCoverageDemandKind { pendingNavigation, committedMaintenance }

/// The scene scope an interaction must have before it may publish.
///
/// A structural Summary Pill transition needs only its first drawable frame.
/// Explicitly opening a rail (and a parent transition that keeps it open)
/// needs the complete immediate sibling domain before it accepts a fling.
/// Keeping that decision typed prevents the `isRailOpen` presentation flag
/// from silently turning every plane transition into a full-bank barrier.
enum _DashboardNavigationSceneRequirement {
  structuralPublication,
  railInteraction,
}

/// The intent that owns a scene-covered navigation candidate.
///
/// Visibility is derived from the latest desired value, while plane, parent,
/// and direction navigation own structural selection. Keeping that distinction
/// typed avoids treating diagnostic reason strings as state ownership.
enum _SceneCoveredNavigationOwner { structural, railVisibility }

final class _QueuedPreparedIndex {
  _QueuedPreparedIndex({
    required this.index,
    this.beforePublish,
    this.afterPublish,
    this.publicationState,
    this.shouldPublish,
  }) : completion = Completer<bool>();

  final PreparedDashboardIndex index;
  final VoidCallback? beforePublish;
  final VoidCallback? afterPublish;
  final DashboardNavigationState? publicationState;
  final bool Function()? shouldPublish;
  final Completer<bool> completion;

  int get coreRevision => index.coreRevision;
}

/// The latest renderability requirement derived from committed navigation.
///
/// Preparation is deliberately cancellable for pointer responsiveness; the
/// requirement itself is not. It remains owned here until its exact canonical
/// window is active, a newer demand supersedes it, or this controller dies.
@immutable
final class _RequiredSceneCoverageDemand {
  const _RequiredSceneCoverageDemand({
    required this.generation,
    required this.requestedAt,
    required this.window,
    required this.payloadKey,
    required this.reason,
    required this.settledQueryKey,
    required this.kind,
  });

  final int generation;
  final DateTime requestedAt;
  final DashboardLogBoxSceneWindow window;
  final String payloadKey;
  final String reason;
  final LedgerQueryKey settledQueryKey;
  final _SceneCoverageDemandKind kind;

  DashboardLogBoxSceneCoverageIdentity get coverage => window.coverageIdentity!;
}

/// A discrete structural transition that is intentionally held behind the
/// exact scene bank required to render its first visible frame. This is
/// controller-owned state: presentation only receives the commit once its
/// immutable payloads are already active.
@immutable
final class _PendingSceneCoveredNavigation {
  _PendingSceneCoveredNavigation({
    required this.generation,
    required this.acceptedAt,
    required this.payloadKey,
    required this.window,
    required this.reason,
    required this.owner,
    required this.commit,
  }) : completion = Completer<void>();

  final int generation;
  final DateTime acceptedAt;
  final String payloadKey;
  final DashboardLogBoxSceneWindow window;
  final String reason;
  final _SceneCoveredNavigationOwner owner;
  final VoidCallback commit;
  final Completer<void> completion;

  Future<void> get future => completion.future;
}

/// A draft-session failure is terminal only for that exact, still-open editor
/// identity.  Retrying it implicitly from Apply would turn one user tap into a
/// duplicate native build.  Closing/reopening (or editing to a new key) gets a
/// new identity and may start fresh work.
@immutable
final class _FailedPreparedQueryCandidate {
  const _FailedPreparedQueryCandidate({
    required this.cacheKey,
    required this.composerIdentity,
  });

  final String cacheKey;
  final QueryComposerApplyIdentity? composerIdentity;
}

const _physicalRailDiagnosticsEnabled = bool.fromEnvironment(
  'FLUVI_PHYSICAL_RAIL_DIAGNOSTICS',
);

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
    TimePlane initialPlane = TimePlane.month,
    bool initialRailOpen = false,
    LedgerDirection initialDirection = LedgerDirection.income,
    bool seedReady = true,
    int? initialCoreRevision,
    this.pageSize = 24,
    int yearWindowRadius = 12,
    DashboardPerformanceCounters? performanceCounters,
    DashboardInteractionDiagnostics? interactionDiagnostics,
    DashboardRailFlightRecorder? railFlightRecorder,
    DashboardRenderReadinessDiagnostics? renderReadinessDiagnostics,
    bool enableRailFlightRecorder =
        const bool.fromEnvironment('FLUVI_RAIL_FLIGHT_RECORDER') ||
        const bool.fromEnvironment('FLUVI_PHYSICAL_RAIL_DIAGNOSTICS'),
  }) : expansion = DashboardExpansionController(metrics: metrics),
       transactionDirection = TransactionDirectionController(
         initialDirection: initialDirection == LedgerDirection.income
             ? TransactionDirection.income
             : TransactionDirection.expense,
       ),
       _seedReady = seedReady,
       _initialCoreRevision = initialCoreRevision {
    this.railFlightRecorder =
        railFlightRecorder ??
        (enableRailFlightRecorder
            ? DashboardRailFlightRecorder(
                enabled: true,
                capacity: _physicalRailDiagnosticsEnabled ? 2048 : 512,
              )
            : null);
    this.renderReadinessDiagnostics =
        renderReadinessDiagnostics ??
        DashboardRenderReadinessDiagnostics(
          enabled: _physicalRailDiagnosticsEnabled,
          capacity: _physicalRailDiagnosticsEnabled ? 2048 : 512,
        );
    this.performanceCounters =
        interactionDiagnostics?.counters ??
        performanceCounters ??
        DashboardPerformanceCounters();
    this.performanceCounters.measuresDurations =
        this.railFlightRecorder?.isEnabled ?? false;
    this.renderReadinessDiagnostics.bindPerformanceCounters(
      this.performanceCounters,
    );
    diagnostics =
        interactionDiagnostics ??
        DashboardInteractionDiagnostics(counters: this.performanceCounters);
    final repository =
        dataRepository ?? const EmptyDashboardDataRuntimeRepository();
    committedLogViewport = CommittedLogViewportCache(pageSize: pageSize);
    final activeRailFlightRecorder = this.railFlightRecorder?.isEnabled == true
        ? this.railFlightRecorder
        : null;

    late final DashboardDataRuntime runtimeOwner;
    late final ExplicitCommittedPagingController pagingOwner;
    presentation = DashboardPresentationController(
      initialDate: initialDate,
      initialPlane: initialPlane,
      initialRailOpen: initialRailOpen,
      initialDirection: initialDirection,
      initialCoreRevision: initialCoreRevision ?? 0,
      displayFrameScheduler: displayFrameScheduler,
      onMotionActiveChanged: (active) {
        _setMotionLaneActive(DashboardMotionLane.rail, active);
      },
      onRailCanonicalCenterMismatch: () {
        this.performanceCounters.increment(
          DashboardPerformanceMetric.railCanonicalCenterMismatch,
        );
      },
      onCommittedFrame: (frame) {
        pagingOwner.commitMetadata(frame);
      },
      onSemanticCrossed: _onSemanticCrossed,
      onSettled: _onSettled,
      onBallisticStarted: _onBallisticStarted,
      onPreparedFrameSelected: activeRailFlightRecorder == null
          ? null
          : (frame, selectorMicros) {
              activeRailFlightRecorder.recordPreparedFrameSelected(
                frame,
                selectorMicros: selectorMicros,
              );
            },
      onPresentationApplyStarted: activeRailFlightRecorder == null
          ? null
          : (frame) {
              activeRailFlightRecorder.recordPresentationApplyStarted(
                frame,
                this.performanceCounters,
              );
            },
      onPresentationApplyCompleted: activeRailFlightRecorder == null
          ? null
          : (frame, applyMicros, metrics) {
              activeRailFlightRecorder.recordPresentationApplyCompleted(
                frame,
                applyMicros: applyMicros,
                equalityMicros: metrics.equalityMicros,
                notifierMicros: metrics.notifierMicros,
                counters: this.performanceCounters,
              );
            },
      onTemporalAnchorChanged:
          activeRailFlightRecorder?.recordTemporalAnchorChanged,
      onPlaneTargetDerived: activeRailFlightRecorder == null
          ? null
          : (derivation) {
              activeRailFlightRecorder.recordPlaneTargetDerived(
                sourcePlane: derivation.sourcePlane,
                targetPlane: derivation.targetPlane,
                temporalAnchor: derivation.temporalAnchor,
                targetParentQueryKey: derivation.targetParentQueryKey,
                targetChildQueryKey: derivation.targetChildQueryKey,
                derivationReason: derivation.derivationReason,
                navigationEpoch: derivation.navigationEpoch,
              );
            },
    );
    pagingOwner = ExplicitCommittedPagingController(
      repository: repository,
      visibleFrames: presentation.visibleFrames,
      committedViewport: committedLogViewport,
      pageSize: pageSize,
      isMotionActive: () => diagnostics.isMotionActive,
      isVerticalInteractionActive: () => _verticalInteractionActive,
      onPageRequested: (request) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'PAGING_STARTED',
            queryKey: request.scope.key.value,
            coreRevision: request.coreRevision,
          ),
        );
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
      onPageCompleted: (request) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'PAGING_COMPLETED',
            queryKey: request.scope.key.value,
            coreRevision: request.coreRevision,
          ),
        );
      },
      onPagePipelineIdle: _resumeSpeculativeWorkAfterCommittedPaging,
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
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'INDEX_BUILD_STARTED',
            queryKey: request.key.diagnosticIdentity,
            coreRevision: request.key.coreRevision,
            flowId: 'generation:$generation',
            scope:
                'acquisitionReason=${request.reason.name} '
                'incomeQueryKey=${request.directionalQueries.income.key.value} '
                'expenseQueryKey=${request.directionalQueries.expense.key.value}',
          ),
        );
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
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'INDEX_BUILD_READY',
            queryKey: index.key.diagnosticIdentity,
            coreRevision: index.coreRevision,
            entryCount: index.buildMetrics.uniquePreviewRowCount,
            durationMs: duration.inMilliseconds,
            flowId: 'generation:${index.generation}',
            scope:
                'acquisitionReason=${reason.name} '
                'builtDirection=${index.builtDirection?.name ?? 'both'} '
                'reusedDirection=${index.reusedDirection?.name ?? 'none'}',
          ),
        );
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
        unawaited(installPreparedIndex(index));
      },
      stableFrameScheduler: stableFrameScheduler,
    );
    dataRuntime = runtimeOwner;
    currentQuery = CurrentQueryController(
      initialScope: presentation.navigation.state.parentQueryScope.copyWith(
        timeScope: const AllTimeScope(),
      ),
    );
    queryComposer = QueryComposerController(appliedQuery: currentQuery);
    queryComposer.addListener(_onQueryComposerChanged);
    this.railFlightRecorder
      ?..bindContextProvider(_railFlightContext)
      ..bindPerformanceCounters(this.performanceCounters)
      ..bindRenderReadinessDiagnostics(this.renderReadinessDiagnostics);
    presentation.visibleFrames.addListener(_onVisibleFramePublished);
  }

  final DashboardLayoutMetrics metrics;
  final int pageSize;
  final DashboardExpansionController expansion;
  final TransactionDirectionController transactionDirection;
  late final DashboardPerformanceCounters performanceCounters;
  late final DashboardInteractionDiagnostics diagnostics;
  late final DashboardRailFlightRecorder? railFlightRecorder;
  late final DashboardRenderReadinessDiagnostics renderReadinessDiagnostics;
  late final DashboardPresentationController presentation;
  late final DashboardDataRuntime dataRuntime;
  late final CurrentQueryController currentQuery;
  late final QueryComposerController queryComposer;
  late final ExplicitCommittedPagingController paging;
  late final CommittedLogViewportCache committedLogViewport;

  late bool _seedReady;
  final int? _initialCoreRevision;
  Completer<void>? _seedReadyCompleter;
  bool _bootstrapped = false;
  bool _disposed = false;
  int _logBoxTextLayoutPreparedRows = 0;
  int _logBoxTextLayoutPreparedDayHeaders = 0;
  int _logBoxTextLayoutEstimatedBytes = 0;
  DashboardLogBoxRenderExtentSnapshot? _lastLogBoxRenderExtent;
  int _verticalScrollExtentMismatchCount = 0;
  int _verticalCommittedScopeResetCount = 0;
  DashboardLogBoxSceneWindowPreparer? _sceneWindowPreparer;
  DashboardLogBoxCandidateSceneWindowPreparer? _candidateSceneWindowPreparer;
  DashboardLogBoxCandidateSceneWindowDiscarder? _candidateSceneWindowDiscarder;
  DashboardLogBoxCandidateSceneWindowLookup? _candidateSceneWindowLookup;
  DashboardLogBoxCandidateSceneWindowHotsetSetter?
  _candidateSceneWindowHotsetSetter;
  DashboardLogBoxRetainedSceneWindowPreparer? _retainedSceneWindowPreparer;
  DashboardLogBoxRetainedSceneWindowLookup? _retainedSceneWindowLookup;
  DashboardLogBoxSceneWindowActivator? _sceneWindowActivator;
  DashboardLogBoxSceneWindowPreparationCanceller?
  _sceneWindowPreparationCanceller;
  DashboardLogBoxSceneWindowRebaseScheduler? _sceneWindowRebaseScheduler;
  DashboardLogBoxSceneWindowReporter? _sceneWindowReporter;
  DashboardPreparedRevisionBundle? _activePreparedRevisionBundle;
  DashboardLogBoxSceneWindow? _activeSceneWindow;
  DashboardRailCriticalSceneBankIdentity? _activeRailCriticalBankIdentity;
  Set<String> _activeSceneWindowQueryKeys = const <String>{};
  int _backgroundSceneWarmupGeneration = 0;
  bool _backgroundSceneWarmupInFlight = false;
  bool _backgroundSceneWarmupScheduled = false;
  int _summaryParentHotsetGeneration = 0;
  bool _summaryParentHotsetInFlight = false;
  final ValueNotifier<bool> _sceneWindowPreparing = ValueNotifier<bool>(false);
  _QueuedPreparedIndex? _queuedPreparedIndex;
  int _queryApplyGeneration = 0;
  Future<bool>? _queryApplyInFlight;
  QueryComposerApplyIdentity? _activeComposerApplyIdentity;
  int _queryDraftPreparationGeneration = 0;
  PreparedQueryCandidatePreparation? _activeQueryCandidatePreparation;
  PreparedQueryCandidate? _stagedQueryCandidate;
  _FailedPreparedQueryCandidate? _failedQueryCandidate;
  final LinkedHashMap<String, PreparedQueryCandidateData>
  _preparedQueryCandidateCache =
      LinkedHashMap<String, PreparedQueryCandidateData>();
  static const int _maximumPreparedQueryCandidates = 6;
  static const int _maximumPreparedQueryCandidateBytes = 64 * 1024 * 1024;
  Set<String> _appliedQueryChipHotset = const <String>{};
  int _queryChipPrewarmGeneration = 0;
  bool _queryChipPrewarmInFlight = false;
  bool _queryChipPrewarmRequested = false;
  bool _queryChipPrewarmAwaitingDismissal = false;
  // This is deliberately separate from [diagnostics.isMotionActive]. Rail and
  // structural motion may defer committed paging; a vertical drag/ballistic
  // must keep essential sequential paging eligible while it suppresses only
  // speculative dashboard work.
  bool _verticalInteractionActive = false;
  DashboardLogBoxSceneCoverageIdentity? _activeSceneCoverage;
  DashboardLogBoxSceneCoverageIdentity? _desiredSceneCoverage;
  _RequiredSceneCoverageDemand? _requiredSceneCoverageDemand;
  int _requiredSceneCoverageGeneration = 0;
  _PendingSceneCoveredNavigation? _pendingSceneCoveredNavigation;
  int _pendingSceneCoveredNavigationGeneration = 0;
  bool? _desiredRailVisibility;
  int _railVisibilityIntentEpoch = 0;
  int? _pendingRailVisibilityIntentEpoch;
  int _sceneRebaseGeneration = 0;
  int? _sceneRebaseInFlightGeneration;
  final Map<int, Completer<void>> _sceneRebaseCompletions =
      <int, Completer<void>>{};
  bool _sceneRebaseRequested = false;
  bool _sceneRebaseDrainScheduled = false;
  String? _lastSceneRebaseReason;
  int? _sceneRebaseDemandGeneration;
  Duration? _lastSceneRebaseDuration;
  int _lastSceneRebaseRequiredScenes = 0;
  int _lastSceneRebaseRequiredRows = 0;
  String? _lastSceneWindowError;
  final Set<DashboardMotionLane> _activeMotionLanes = <DashboardMotionLane>{};

  DashboardNavigationController get navigation => presentation.navigation;
  DashboardMotionKernel get motion => presentation.motion;
  DashboardVisibleFrameStore get visibleFrames => presentation.visibleFrames;
  DashboardDisplayFrameCoalescer get frameCoalescer =>
      presentation.frameCoalescer;
  DashboardPreparedRevisionBundle? get activePreparedRevisionBundle =>
      _activePreparedRevisionBundle;
  PreparedDashboardIndex? get preparedIndex =>
      _activePreparedRevisionBundle?.index ?? presentation.index;
  int? get coreRevision => preparedIndex?.coreRevision;
  bool get isBootstrapped => _bootstrapped;
  ValueListenable<bool> get sceneWindowPreparing => _sceneWindowPreparing;

  /// Complete, invisible candidates for the current applied query's direct
  /// chip-removal neighbours.  The active prepared index has a separate
  /// owner, so it deliberately does not consume this speculative capacity.
  @visibleForTesting
  int get retainedPreparedQueryCandidateCount =>
      _preparedQueryCandidateCache.length;

  @visibleForTesting
  int get appliedQueryChipHotsetCount => _appliedQueryChipHotset.length;

  /// Registers the sole presentation capability that owns Flutter paragraph
  /// preparation. Navigation remains coordinated here; the render surface only
  /// creates immutable scene resources requested by this controller.
  void attachLogBoxSceneWindowCoordinator({
    required DashboardLogBoxSceneWindowPreparer prepare,
    required DashboardLogBoxSceneWindowActivator activate,
    DashboardLogBoxCandidateSceneWindowPreparer? prepareCandidate,
    DashboardLogBoxCandidateSceneWindowDiscarder? discardCandidate,
    DashboardLogBoxCandidateSceneWindowLookup? hasCandidate,
    DashboardLogBoxCandidateSceneWindowHotsetSetter? setCandidateHotset,
    DashboardLogBoxRetainedSceneWindowPreparer? prepareRetained,
    DashboardLogBoxRetainedSceneWindowLookup? hasRetained,
    DashboardLogBoxSceneWindowPreparationCanceller? cancel,
    DashboardLogBoxSceneWindowRebaseScheduler? scheduleRebase,
    DashboardLogBoxSceneWindowReporter? report,
  }) {
    if (_disposed) throw StateError('Dashboard core has been disposed.');
    _sceneWindowPreparer = prepare;
    _candidateSceneWindowPreparer = prepareCandidate;
    _candidateSceneWindowDiscarder = discardCandidate;
    _candidateSceneWindowLookup = hasCandidate;
    _candidateSceneWindowHotsetSetter = setCandidateHotset;
    // The coordinator can attach after an applied query has already
    // established chip-neighbour protection. Synchronize that existing
    // ownership immediately instead of waiting for an unrelated publication
    // or direction change to rewrite the cache's protected-key set.
    setCandidateHotset?.call(_appliedQueryChipHotset);
    _retainedSceneWindowPreparer = prepareRetained;
    _retainedSceneWindowLookup = hasRetained;
    _sceneWindowActivator = activate;
    _sceneWindowPreparationCanceller = cancel;
    _sceneWindowRebaseScheduler = scheduleRebase;
    _sceneWindowReporter = report;
    final activeIdentity = report?.call()['railCriticalBankIdentity'];
    final current = presentation.index;
    if (current != null &&
        activeIdentity ==
            DashboardRailCriticalSceneBankIdentity.forIndex(current).value &&
        _activeSceneWindowQueryKeys.isEmpty) {
      // A rail-bank identity is revision-scoped, not payload-scoped: the same
      // identity is valid for a minimal publication window and for the full
      // index. The cache report cannot prove which query keys are active, so
      // do not manufacture a complete-bank claim here. The only authoritative
      // writers are actual activateWindow/initial-activation callbacks.
      _activePreparedRevisionBundle = null;
      _activeRailCriticalBankIdentity = null;
    }
    _scheduleSceneRebaseDrain();
  }

  void detachLogBoxSceneWindowCoordinator() {
    _sceneWindowPreparer = null;
    _candidateSceneWindowPreparer = null;
    _candidateSceneWindowDiscarder = null;
    _candidateSceneWindowLookup = null;
    _candidateSceneWindowHotsetSetter = null;
    _retainedSceneWindowPreparer = null;
    _retainedSceneWindowLookup = null;
    _sceneWindowActivator = null;
    _sceneWindowPreparationCanceller = null;
    _sceneWindowRebaseScheduler = null;
    _sceneWindowReporter = null;
  }

  /// Records one already activated scene window. Startup is structurally
  /// ready as soon as its first parent frame is drawable; interaction scenes
  /// expand later through the same background coordinator.
  void recordInitialSceneWindowActivation(DashboardLogBoxSceneWindow window) {
    if (_disposed) return;
    final index = presentation.index;
    if (index == null) return;
    // Startup warmup activates the same bounded publication window that a
    // later Query publication uses. Keep the controller's bundle aligned with
    // that exact cache manifest; treating it as the complete index bank would
    // make the first structural transition request every index scene.
    final bundle = DashboardPreparedRevisionBundle.forIndex(
      index,
      publicationState: navigation.state,
    );
    if (window.identity != bundle.railCriticalSceneBankIdentity.value) return;
    _activePreparedRevisionBundle = bundle;
    _activeRailCriticalBankIdentity = bundle.railCriticalSceneBankIdentity;
    _activeSceneWindow = window;
    _activeSceneCoverage = window.coverageIdentity;
    _activeSceneWindowQueryKeys = _sceneWindowQueryKeys(window);
    _startRailInteractionWarmup(index, state: navigation.state);
  }

  DashboardRenderDiagnosticContext get renderDiagnosticContext {
    final motionState = presentation.motion.state;
    return DashboardRenderDiagnosticContext(
      gestureId: motionState.gestureId,
      displayFrameId: presentation.frameCoalescer.currentFrameNumber,
    );
  }

  Map<String, Object?> exportPhysicalRailReport() {
    final report = renderReadinessDiagnostics.exportPhysicalReport(
      motionEvents:
          railFlightRecorder?.snapshot().map((event) => event.toReportMap()) ??
          const <Map<String, Object?>>[],
      motionOverwrittenEventCount:
          railFlightRecorder?.overwrittenEventCount ?? 0,
    );
    return <String, Object?>{
      ...report,
      'visibleFrame': <String, Object?>{
        'mode': visibleFrames.value?.mode.name ?? 'unbound',
        'queryKey': visibleFrames.value?.queryKey.value,
        'revision': visibleFrames.value?.coreRevision,
        'presentationEpoch': visibleFrames.value?.presentationEpoch,
      },
      'renderDomain': resolveDashboardLogBoxRenderDomain(
        payload: visibleFrames.logBoxLane.value?.logBox,
        presentation: visibleFrames.logBoxPresentationLane.value,
        committedViewport: committedLogViewport,
      ).name,
      'summary': _summaryDiagnosticReport(),
      'logBoxPresentation': <String, Object?>{
        ...(_lastLogBoxRenderExtent?.toReportMap() ??
            _fallbackLogBoxPresentationReport()),
        'payloadNotifyCount': visibleFrames.logBoxPayloadNotifyCount,
        'presentationMetaNotifyCount':
            visibleFrames.logBoxPresentationMetaNotifyCount,
        'scrollExtentMismatchCount': _verticalScrollExtentMismatchCount,
        'verticalCommittedScopeResetCount': _verticalCommittedScopeResetCount,
      },
      'sceneWindow': _sceneWindowReport(),
      'committedLogViewport': committedLogViewport.report(),
      'committedVerticalPaging': <String, Object?>{
        'pageReads': paging.pageReadCount,
        'staleRejects': paging.stalePageRejectCount,
        'duplicatesSuppressed': paging.duplicatePageSuppressCount,
        'motionSuppressed': paging.motionPageSuppressCount,
        'nextOrdinal': paging.nextPageOrdinal,
        'desiredOrdinal': paging.desiredForwardOrdinal,
        'demandEpoch': paging.forwardDemandEpoch,
        'requestStates': paging.forwardRequestStates,
      },
      'memoryBudget': <String, Object?>{
        'preparedIndexBytes':
            preparedIndex?.buildMetrics.estimatedIndexBytes ?? 0,
        'logBoxRasterBytes':
            PreparedVectorAssetAtlas.instance.logBoxRasterByteEstimate,
        'logBoxRasterSurfaceCount':
            PreparedVectorAssetAtlas.instance.logBoxRasterSurfaceCount,
        'logBoxTextLayoutEstimatedBytes': _logBoxTextLayoutEstimatedBytes,
        'logBoxTextLayoutPreparedRows': _logBoxTextLayoutPreparedRows,
        'logBoxTextLayoutPreparedDayHeaders':
            _logBoxTextLayoutPreparedDayHeaders,
        'committedLogViewportBytes': committedLogViewport.estimatedBytes,
        'committedLogViewportGeometryBytes': committedLogViewport.geometryBytes,
        'committedLogViewportRetainedRows':
            committedLogViewport.retainedRowCount,
        'motionRingCapacity': railFlightRecorder?.capacity ?? 0,
        'renderRingCapacity': renderReadinessDiagnostics.capacity,
      },
      'performanceCounters': <String, int>{
        for (final entry in performanceCounters.snapshot().entries)
          entry.key.name: entry.value,
      },
    };
  }

  Map<String, Object?> onscreenDiagnosticStatus() {
    final visible = visibleFrames.value;
    final summary = _summaryDiagnosticReport();
    final scene = _sceneWindowReport();
    final vertical = committedLogViewport.report();
    final motionEvents =
        railFlightRecorder?.snapshot() ?? const <DashboardRailFlightEvent>[];
    final latestMotion = motionEvents.isEmpty ? null : motionEvents.last;
    const buildCommit = String.fromEnvironment(
      'FLUVI_BUILD_COMMIT',
      defaultValue: 'unknown',
    );
    return <String, Object?>{
      'build/commit':
          '${kProfileMode ? 'profile' : (kDebugMode ? 'debug' : 'release')}'
          '/${buildCommit.length <= 12 ? buildCommit : buildCommit.substring(0, 12)}',
      'core revision': coreRevision ?? 0,
      'plane/query':
          '${navigation.state.plane.name}/${visible?.queryKey.value ?? 'unbound'}',
      'summary': '${summary['displayedTitle']}/${summary['displayedSubtitle']}',
      'scene window':
          '${scene['state'] ?? 'unattached'}; scenes=${scene['preparedScenes'] ?? 0}; '
          'textRows=${scene['preparedTextRows'] ?? 0}; '
          'bytes=${scene['sceneCacheBytes'] ?? 0}',
      'cache misses':
          'critical=${renderReadinessDiagnostics.railCriticalCacheMissCount}; '
          'railText=${scene['textLayoutMisses'] ?? 0}; '
          'verticalText=${vertical['textLayoutMisses'] ?? 0}',
      'vertical logbox':
          '${vertical['state']}; pages=${vertical['retainedPages']}; '
          'rows=${vertical['retainedRows']}/${vertical['totalRows']}; '
          'textRows=${vertical['preparedTextRows']}; '
          'bytes=${vertical['cacheBytes']}',
      'index bytes': preparedIndex?.buildMetrics.estimatedIndexBytes ?? 0,
      'last fling':
          'delta=${latestMotion == null ? 0 : latestMotion.finalLogicalIndex - latestMotion.startLogicalIndex}; '
          'uiP95=${latestMotion?.uiFrameP95Micros ?? 0}',
      'last error':
          committedLogViewport.lastError ?? _lastSceneWindowError ?? 'none',
    };
  }

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

  /// Installs an idle-time immutable index only after its publication-critical
  /// scene bank is ready.
  ///
  /// Bootstrap reaches this before the dashboard surface attaches, so it keeps
  /// the synchronous publication contract. Later revisions rotate exactly like
  /// a parent navigation: the old complete scene remains visible while the
  /// replacement is prepared, then the new index and scene bank commit
  /// together. Input is never a preparation barrier.
  Future<bool> installPreparedIndex(
    PreparedDashboardIndex index, {
    VoidCallback? beforePublish,
    VoidCallback? afterPublish,
    DashboardNavigationState? publicationState,
    bool Function()? shouldPublish,
  }) async {
    if (_disposed || !(shouldPublish?.call() ?? true)) return false;
    _invalidatePreparedQueryCandidatesForRevision(index.coreRevision);
    final activeIndexBeforeInstall = preparedIndex;
    if (activeIndexBeforeInstall != null &&
        activeIndexBeforeInstall.coreRevision != index.coreRevision) {
      final preparing = _activeQueryCandidatePreparation;
      // The runtime uses one index-builder lane for database revisions and
      // hidden Query candidates.  Do not cancel that lane merely because the
      // completed revision index is now being installed: doing so cancels the
      // revision publication itself.  Only an actually in-flight draft owns
      // cancellable Query work here.
      if (preparing != null) {
        _queryDraftPreparationGeneration += 1;
        _activeQueryCandidatePreparation = null;
        if (!preparing.completion.isCompleted) {
          preparing.completion.complete(null);
        }
        dataRuntime.cancelPreparedQuery();
      }
    }
    // A candidate or demand from an older immutable index may never commit,
    // retry, or keep this higher-authority Query/index publication queued.
    _invalidateSceneCoverageOwnedByReplacedIndex(index);
    _cancelBackgroundSceneWarmup();
    final prepare = _sceneWindowPreparer;
    final activate = _sceneWindowActivator;
    if (prepare == null || activate == null) {
      if (!(shouldPublish?.call() ?? true)) return false;
      beforePublish?.call();
      if (!(shouldPublish?.call() ?? true)) return false;
      _publishIndex(index);
      afterPublish?.call();
      return true;
    }
    if (_sceneWindowPreparing.value) {
      final queued = _queuedPreparedIndex;
      if (queued == null || index.coreRevision >= queued.coreRevision) {
        queued?.completion.complete(false);
        final next = _QueuedPreparedIndex(
          index: index,
          beforePublish: beforePublish,
          afterPublish: afterPublish,
          publicationState: publicationState,
          shouldPublish: shouldPublish,
        );
        _queuedPreparedIndex = next;
        return next.completion.future;
      }
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'INDEX_PUBLICATION_QUEUED',
          message: 'sceneRotationInProgress',
          coreRevision: index.coreRevision,
        ),
      );
      return false;
    }
    final targetState = publicationState ?? navigation.state;
    final nextBundle = DashboardPreparedRevisionBundle.forIndex(
      index,
      publicationState: targetState,
    );
    // A revision replacement is not a Summary Pill structural transition. If
    // the rail is already open, its immediate siblings are synchronously
    // reachable on the first post-publication fling. Publish that bounded
    // interaction domain atomically with the new immutable index instead of
    // exposing a structural-only bank and hoping cancellable warmup wins the
    // first input race. Closed rails retain the O(1) publication barrier.
    final targetWindow =
        (targetState.isRailOpen
                ? nextBundle.railInteractionSceneWindow
                : nextBundle.structuralPublicationSceneWindow)
            .withCoverage(_coverageFor(targetState, indexOverride: index));
    _sceneWindowPreparing.value = true;
    _lastSceneWindowError = null;
    var published = false;
    try {
      await prepare(
        targetWindow,
        retainViewportId: visibleFrames.value?.logBox.viewportId,
      );
      if (_disposed || !(shouldPublish?.call() ?? true)) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_APPLY_STALE_PUBLICATION_REJECTED',
            queryKey: targetWindow.identity,
            coreRevision: index.coreRevision,
            scope: 'preparedIndexPublication=true',
          ),
        );
        return false;
      }
      _activateSceneWindow(targetWindow, activate: activate);
      beforePublish?.call();
      if (!(shouldPublish?.call() ?? true)) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_APPLY_STALE_PUBLICATION_REJECTED',
            queryKey: targetWindow.identity,
            coreRevision: index.coreRevision,
            scope: 'afterSceneActivation=true',
          ),
        );
        return false;
      }
      _publishIndex(index, preparedRevisionBundle: nextBundle);
      afterPublish?.call();
      published = true;
      _startRailInteractionWarmup(index, state: navigation.state);
      _lastSceneRebaseReason = 'indexRevision';
      if (_coverageFor(navigation.state) == targetWindow.coverageIdentity) {
        _sceneRebaseRequested = false;
      }
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_ROTATED',
          message: 'indexPublished',
          queryKey: targetWindow.identity,
          coreRevision: index.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
    } on Object catch (error) {
      _lastSceneWindowError = '$error';
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'ERROR',
          message: 'INDEX_SCENE_WINDOW_PREPARE_FAILED',
          queryKey: targetWindow.identity,
          coreRevision: index.coreRevision,
          entryCount: targetWindow.previewRowCount,
          error: '$error',
        ),
      );
    } finally {
      _finishSceneWindowPreparation();
    }
    return published;
  }

  void _finishSceneWindowPreparation() {
    if (_disposed) return;
    final queued = _queuedPreparedIndex;
    _queuedPreparedIndex = null;
    if (queued != null) {
      // Index installation still serializes structural publication, but it is
      // not an interaction barrier. Clear this activity marker before the
      // queued operation claims the preparation lane.
      _sceneWindowPreparing.value = false;
      unawaited(
        installPreparedIndex(
          queued.index,
          beforePublish: queued.beforePublish,
          afterPublish: queued.afterPublish,
          publicationState: queued.publicationState,
          shouldPublish: queued.shouldPublish,
        ).then((published) {
          if (!queued.completion.isCompleted) {
            queued.completion.complete(published);
          }
        }),
      );
      return;
    }
    _sceneWindowPreparing.value =
        _sceneRebaseRequested || _sceneRebaseInFlightGeneration != null;
    _scheduleSceneRebaseDrain();
  }

  void _publishIndex(
    PreparedDashboardIndex index, {
    DashboardPreparedRevisionBundle? preparedRevisionBundle,
  }) {
    // DashboardDataRuntime publishes only at bootstrap or on the first stable
    // idle frame. This installs the index and its complete visible frame as one
    // atomic revision boundary; no coalescer frame may mix revisions.
    if (preparedRevisionBundle != null) {
      _activePreparedRevisionBundle = preparedRevisionBundle;
      _activeRailCriticalBankIdentity =
          preparedRevisionBundle.railCriticalSceneBankIdentity;
    } else {
      // A controller without an attached render owner is not yet allowed to
      // claim a visual bundle. Keep navigation data truthful and let READY
      // attach the matching complete bank before interaction begins.
      _activePreparedRevisionBundle = null;
      _activeRailCriticalBankIdentity = null;
    }
    presentation.installIndex(index, publishImmediately: true);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'INDEX_PUBLISHED',
        queryKey: presentation.visibleFrames.value?.queryKey.value,
        coreRevision: index.coreRevision,
        entryCount: index.buildMetrics.uniquePreviewRowCount,
      ),
    );
    diagnostics.record(
      DashboardInteractionEvent.indexPublished,
      context: _diagnosticContext(),
      source: 'dataRuntime',
    );
  }

  /// Starts the invisible half of a Query edit.  Facets/counts are owned by
  /// the sheet's data controller; this prepares the separate immutable
  /// dashboard candidate without touching any applied/query/navigation state.
  Future<PreparedQueryCandidate?> prepareQueryDraft(
    CurrentLedgerQueryScope draft, {
    QueryComposerApplyIdentity? composerIdentity,
    QueryMenuData? facetPresentation,
  }) {
    // A visible editor is foreground intent and wins over speculative chip
    // neighbours using the shared native prepared-index lane.
    _supersedeQueryChipPrewarm();
    final template = draft.copyWith(timeScope: const AllTimeScope());
    if (template == currentQuery.scopeFor(template.direction)) {
      if (_activeQueryCandidatePreparation != null ||
          _stagedQueryCandidate != null) {
        discardQueryDraftCandidate(reason: 'draftReturnedToApplied');
      }
      // Opening an unchanged Query Menu is not a new dashboard candidate.
      // Apply will take the established no-op close path, with zero native
      // work and without needlessly cancelling a useful background warmup.
      return Future<PreparedQueryCandidate?>.value(null);
    }
    final effectiveIdentity =
        composerIdentity ??
        (queryComposer.isOpen ? queryComposer.applyIdentity : null);
    if (effectiveIdentity != null &&
        (effectiveIdentity.direction != template.direction ||
            !queryComposer.isCurrentApplyIdentity(effectiveIdentity))) {
      return Future<PreparedQueryCandidate?>.value(null);
    }
    final directionalQueries = currentQuery.queries.replaceDirection(
      template.direction,
      template,
    );
    final physicalWindow = _activePreparedQueryYearWindow();
    if (physicalWindow == null) {
      return Future<PreparedQueryCandidate?>.value(null);
    }
    final cacheKey = _preparedQueryCandidateCacheKey(
      directionalQueries,
      physicalWindow: physicalWindow,
    );
    final inFlight = _activeQueryCandidatePreparation;
    if (inFlight != null &&
        inFlight.cacheKey == cacheKey &&
        inFlight.composerIdentity == effectiveIdentity) {
      return inFlight.future;
    }
    final generation = ++_queryDraftPreparationGeneration;
    final preparation = PreparedQueryCandidatePreparation(
      generation: generation,
      cacheKey: cacheKey,
      composerIdentity: effectiveIdentity,
    );
    _activeQueryCandidatePreparation = preparation;
    _markStagedQueryCandidateUnavailable();
    unawaited(
      _prepareQueryDraftCandidate(
        preparation: preparation,
        draft: template,
        directionalQueries: directionalQueries,
        physicalWindow: physicalWindow,
        facetPresentation: facetPresentation,
      ),
    );
    return preparation.future;
  }

  /// Cancels/discards a non-visible draft candidate.  This intentionally does
  /// not reinstall or rebuild the old applied index: it never left the active
  /// dashboard while the sheet was editing.
  void discardQueryDraftCandidate({
    required String reason,
    bool cancelScenePreparation = true,
  }) {
    _queryDraftPreparationGeneration += 1;
    final preparation = _activeQueryCandidatePreparation;
    _activeQueryCandidatePreparation = null;
    if (preparation != null && !preparation.completion.isCompleted) {
      preparation.completion.complete(null);
    }
    final staged = _stagedQueryCandidate;
    _markStagedQueryCandidateUnavailable();
    _failedQueryCandidate = null;
    if (staged != null) {
      // The session may no longer own an invisible staged bank, but a fully
      // prepared immutable index remains an exact LRU value. Retain its data
      // identity across editor sessions; a later Apply re-stages only the
      // bounded scene window if that session-owned bank was released.
      _putPreparedQueryCandidateData(staged.data);
      _candidateSceneWindowDiscarder?.call(staged.cacheKey);
    }
    dataRuntime.cancelPreparedQuery();
    if (cancelScenePreparation) _sceneWindowPreparationCanceller?.call();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_DRAFT_CANCELLED',
        flowId: 'generation:$_queryDraftPreparationGeneration',
        scope: 'reason=$reason',
      ),
    );
  }

  Future<void> _prepareQueryDraftCandidate({
    required PreparedQueryCandidatePreparation preparation,
    required CurrentLedgerQueryScope draft,
    required DashboardDirectionalQuerySet directionalQueries,
    required DashboardPreparedYearWindow physicalWindow,
    required QueryMenuData? facetPresentation,
  }) async {
    final started = Stopwatch()..start();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_DRAFT_PREPARE_STARTED',
        flowId: 'generation:${preparation.generation}',
        queryKey: draft.key.value,
        direction: draft.direction.name,
        scope:
            'activePhysicalWindow=${physicalWindow.start}-${physicalWindow.endInclusive} '
            'candidateCacheKey=${preparation.cacheKey}',
      ),
    );
    try {
      final cachedData = _preparedQueryCandidateDataFor(preparation.cacheKey);
      final cached = cachedData == null
          ? null
          : _candidateForCachedData(
              data: cachedData,
              draft: draft,
              composerIdentity: preparation.composerIdentity,
              facetPresentation: facetPresentation,
            );
      final candidateCacheHit = cached != null;
      final index =
          cached?.index ??
          await dataRuntime.prepareQuery(
            DashboardIndexRequestTemplate.forPreparedYearWindow(
              directionalQueries: directionalQueries,
              pageSize: pageSize,
              yearWindow: physicalWindow,
            ),
          );
      if (!_isCurrentPreparedQueryCandidate(preparation) ||
          index.coreRevision != preparedIndex?.coreRevision) {
        _completePreparedQueryCandidate(preparation, null);
        return;
      }
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_DRAFT_INDEX_READY',
          flowId: 'generation:${preparation.generation}',
          queryKey: draft.key.value,
          direction: draft.direction.name,
          coreRevision: index.coreRevision,
          message:
              'editedDirection=${draft.direction.name} '
              'reusedDirection=${index.reusedDirection?.name ?? 'none'} '
              'oppositeDirectionReused=${index.reusedDirection != null} '
              'nativeSqlMicros=${index.buildMetrics.nativeSqlDurationMicros} '
              'nativeRowsBuilt=${index.buildMetrics.uniquePreviewRowCount - index.reusedPreparedRowCount} '
              'rowsReused=${index.reusedPreparedRowCount} '
              'serializationMicros=${index.buildMetrics.serializationDurationMicros} '
              'bridgeMicros=${index.buildMetrics.bridgeTransferDurationMicros} '
              'decodeWorkerWallMicros='
              '${index.buildMetrics.decodeWorkerWallDurationMicros} '
              'dartBinaryDecodeMicros=${index.buildMetrics.dartDecodeDurationMicros} '
              'compactIndexAssemblyMicros='
              '${index.buildMetrics.compactIndexAssemblyDurationMicros} '
              'zeroUniverseCatalogMicros='
              '${index.buildMetrics.zeroUniverseCatalogDurationMicros} '
              'zeroUniverseScopeMicros='
              '${index.buildMetrics.zeroUniverseScopeDurationMicros} '
              'zeroFrameMaterializationMicros='
              '${index.buildMetrics.zeroFrameMaterializationDurationMicros} '
              'sparseFrameInstallMicros='
              '${index.buildMetrics.sparseFrameInstallDurationMicros} '
              'zeroScopeCount=${index.buildMetrics.zeroScopeCount} '
              'zeroFrameCount=${index.buildMetrics.zeroFrameCount} '
              'semanticCatalogCount=${index.buildMetrics.semanticCatalogCount} '
              'semanticEntryCount=${index.buildMetrics.semanticEntryCount} '
              'richRowProjectionMicros='
              '${index.buildMetrics.richRowProjectionDurationMicros} '
              'richFrameProjectionMicros='
              '${index.buildMetrics.richFrameProjectionDurationMicros} '
              'projectedUniqueRows='
              '${index.buildMetrics.projectedUniqueRowCount} '
              'projectedFrames=${index.buildMetrics.projectedFrameCount} '
              'reusedProjectedRows='
              '${index.buildMetrics.reusedProjectedRowCount} '
              'reusedProjectedFrames='
              '${index.buildMetrics.reusedProjectedFrameCount} '
              'candidateCacheHit=$candidateCacheHit '
              'physicalYearWindowStart=${index.key.yearWindowStart} '
              'physicalYearWindowEndInclusive=${index.key.yearWindowEndInclusive} '
              'requestIdentity=${index.key.diagnosticIdentity}',
          entryCount: index.buildMetrics.uniquePreviewRowCount,
          durationMs: started.elapsedMilliseconds,
        ),
      );
      final availability = DashboardTemporalAvailability.fromTemporalFilter(
        draft.temporalFilter,
      );
      final publicationState = navigation.appliedQueryCandidate(
        draft,
        availability: availability,
        coreRevision: index.coreRevision,
      );
      final bundle = DashboardPreparedRevisionBundle.forIndex(
        index,
        publicationState: publicationState,
      );
      final structuralWindow = bundle.structuralPublicationSceneWindow
          .withCoverage(_coverageFor(publicationState, indexOverride: index));
      final interactionWindow = bundle.railInteractionSceneWindow.withCoverage(
        _coverageFor(publicationState, indexOverride: index),
      );
      var sceneStaged = false;
      final prepareCandidate = _candidateSceneWindowPreparer;
      final prepare = _sceneWindowPreparer;
      if (prepareCandidate != null || prepare != null) {
        if (prepareCandidate != null) {
          await prepareCandidate(
            interactionWindow,
            candidateKey: preparation.cacheKey,
            retainViewportId: visibleFrames.value?.logBox.viewportId,
          );
        } else {
          await prepare!(
            interactionWindow,
            retainViewportId: visibleFrames.value?.logBox.viewportId,
          );
        }
        if (!_isCurrentPreparedQueryCandidate(preparation)) {
          _completePreparedQueryCandidate(preparation, null);
          return;
        }
        sceneStaged =
            prepareCandidate == null ||
            (_candidateSceneWindowLookup?.call(
                  interactionWindow,
                  candidateKey: preparation.cacheKey,
                ) ??
                true);
        if (!sceneStaged) {
          _reportQueryCandidateSceneRetentionRejected(
            candidateKey: preparation.cacheKey,
            window: interactionWindow,
            reason: 'prepareCompletedWithoutRetainedCandidateBank',
          );
          throw StateError(
            'QUERY_CANDIDATE_SCENE_RETENTION_REJECTED: '
            'candidate scene bank is absent after preparation.',
          );
        }
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_DRAFT_INTERACTION_SCENE_READY',
            flowId: 'generation:${preparation.generation}',
            queryKey: draft.key.value,
            direction: draft.direction.name,
            coreRevision: index.coreRevision,
            entryCount: interactionWindow.previewRowCount,
            scope:
                'requestIdentity=${index.key.diagnosticIdentity} '
                'window=${interactionWindow.identity}',
          ),
        );
      }
      final requestTemplate =
          DashboardIndexRequestTemplate.forPreparedYearWindow(
            directionalQueries: directionalQueries,
            pageSize: pageSize,
            yearWindow: physicalWindow,
          );
      final candidate = PreparedQueryCandidate(
        data: PreparedQueryCandidateData(
          cacheKey: preparation.cacheKey,
          directionalQueries: directionalQueries,
          index: index,
        ),
        composerIdentity: preparation.composerIdentity,
        editedScope: draft,
        facetPresentation: facetPresentation,
        requestTemplate: requestTemplate,
        availability: availability,
        publicationState: publicationState,
        bundle: bundle,
        structuralWindow: structuralWindow,
        currentParentInteractionWindow: interactionWindow,
        sceneStaged: sceneStaged,
      );
      _putPreparedQueryCandidateData(candidate.data);
      _stagedQueryCandidate = candidate;
      if (_failedQueryCandidate?.cacheKey == preparation.cacheKey &&
          _failedQueryCandidate?.composerIdentity ==
              preparation.composerIdentity) {
        _failedQueryCandidate = null;
      }
      _completePreparedQueryCandidate(preparation, candidate);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_DRAFT_PREPARE_READY',
          flowId: 'generation:${preparation.generation}',
          queryKey: draft.key.value,
          direction: draft.direction.name,
          coreRevision: index.coreRevision,
          durationMs: started.elapsedMilliseconds,
          scope: 'requestIdentity=${index.key.diagnosticIdentity}',
        ),
      );
    } on DashboardIndexPreparationDiscarded {
      _completePreparedQueryCandidate(preparation, null);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_DRAFT_PREPARE_SUPERSEDED',
          flowId: 'generation:${preparation.generation}',
          queryKey: draft.key.value,
          direction: draft.direction.name,
        ),
      );
    } on DashboardLogBoxScenePreparationCancelled {
      _completePreparedQueryCandidate(preparation, null);
    } on Object catch (error) {
      if (_isCurrentPreparedQueryCandidate(preparation)) {
        _failedQueryCandidate = _FailedPreparedQueryCandidate(
          cacheKey: preparation.cacheKey,
          composerIdentity: preparation.composerIdentity,
        );
      }
      _completePreparedQueryCandidate(preparation, null);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'ERROR',
          message: 'QUERY_DRAFT_PREPARE_FAILED',
          flowId: 'generation:${preparation.generation}',
          queryKey: draft.key.value,
          direction: draft.direction.name,
          error: '$error',
        ),
      );
    }
  }

  bool _isCurrentPreparedQueryCandidate(
    PreparedQueryCandidatePreparation preparation,
  ) =>
      !_disposed &&
      preparation.generation == _queryDraftPreparationGeneration &&
      identical(_activeQueryCandidatePreparation, preparation) &&
      (preparation.composerIdentity == null ||
          queryComposer.isCurrentApplyIdentity(preparation.composerIdentity!));

  void _completePreparedQueryCandidate(
    PreparedQueryCandidatePreparation preparation,
    PreparedQueryCandidate? candidate,
  ) {
    if (!preparation.completion.isCompleted) {
      preparation.completion.complete(candidate);
    }
    if (identical(_activeQueryCandidatePreparation, preparation)) {
      _activeQueryCandidatePreparation = null;
    }
  }

  void _markStagedQueryCandidateUnavailable() {
    final staged = _stagedQueryCandidate;
    if (staged == null) return;
    // Candidate banks are independently retained by the single scene-cache
    // owner. A newer draft therefore must not invalidate an already-ready
    // chip neighbour or previously visited Query candidate.
    _stagedQueryCandidate = null;
  }

  DashboardPreparedYearWindow? _activePreparedQueryYearWindow() {
    final index = preparedIndex;
    if (index == null) {
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'QUERY_CANDIDATE_WINDOW_UNAVAILABLE',
          message: 'activePreparedIndex=false',
        ),
      );
      return null;
    }
    return DashboardPreparedYearWindow.fromIndex(index);
  }

  String _preparedQueryCandidateCacheKey(
    DashboardDirectionalQuerySet queries, {
    required DashboardPreparedYearWindow physicalWindow,
  }) {
    final revision = preparedIndex?.coreRevision ?? 0;
    return 'rev:$revision|queries:${queries.canonicalKey}|page:$pageSize|'
        '${physicalWindow.cacheIdentity}';
  }

  PreparedQueryCandidate _candidateForCachedData({
    required PreparedQueryCandidateData data,
    required CurrentLedgerQueryScope draft,
    required QueryComposerApplyIdentity? composerIdentity,
    required QueryMenuData? facetPresentation,
  }) {
    final availability = DashboardTemporalAvailability.fromTemporalFilter(
      draft.temporalFilter,
    );
    final publicationState = navigation.appliedQueryCandidate(
      draft,
      availability: availability,
      coreRevision: data.index.coreRevision,
    );
    final bundle = DashboardPreparedRevisionBundle.forIndex(
      data.index,
      publicationState: publicationState,
    );
    final structuralWindow = bundle.structuralPublicationSceneWindow
        .withCoverage(
          _coverageFor(publicationState, indexOverride: data.index),
        );
    final interactionWindow = bundle.railInteractionSceneWindow.withCoverage(
      _coverageFor(publicationState, indexOverride: data.index),
    );
    final sceneStaged =
        _candidateSceneWindowLookup?.call(
          interactionWindow,
          candidateKey: data.cacheKey,
        ) ??
        false;
    return PreparedQueryCandidate(
      data: data,
      composerIdentity: composerIdentity,
      editedScope: draft,
      facetPresentation: facetPresentation,
      requestTemplate: DashboardIndexRequestTemplate.forPreparedYearWindow(
        directionalQueries: data.directionalQueries,
        pageSize: pageSize,
        yearWindow: DashboardPreparedYearWindow.fromIndex(data.index),
      ),
      availability: availability,
      publicationState: publicationState,
      bundle: bundle,
      structuralWindow: structuralWindow,
      currentParentInteractionWindow: interactionWindow,
      sceneStaged: sceneStaged,
    );
  }

  void _putPreparedQueryCandidateData(PreparedQueryCandidateData candidate) {
    _preparedQueryCandidateCache.remove(candidate.cacheKey);
    _preparedQueryCandidateCache[candidate.cacheKey] = candidate;
    var bytes = _preparedQueryCandidateCache.values.fold<int>(
      0,
      (total, entry) => total + entry.index.buildMetrics.estimatedIndexBytes,
    );
    while (_preparedQueryCandidateCache.length >
            _maximumPreparedQueryCandidates ||
        (_preparedQueryCandidateCache.length > 1 &&
            bytes > _maximumPreparedQueryCandidateBytes)) {
      final oldestKey = _evictablePreparedQueryCandidateKey();
      if (oldestKey == null) break;
      final removed = _preparedQueryCandidateCache.remove(oldestKey)!;
      _candidateSceneWindowDiscarder?.call(removed.cacheKey);
      bytes -= removed.index.buildMetrics.estimatedIndexBytes;
    }
  }

  /// The activated index is owned by [presentation]/[dataRuntime], not by the
  /// speculative candidate LRU.  Keeping it here would evict one exact X
  /// neighbour from a five-chip query even though the active index is already
  /// retained elsewhere.
  void _removeActivePreparedQueryCandidateData(String cacheKey) {
    _preparedQueryCandidateCache.remove(cacheKey);
  }

  String? _evictablePreparedQueryCandidateKey() {
    for (final key in _preparedQueryCandidateCache.keys) {
      if (!_appliedQueryChipHotset.contains(key)) return key;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_CHIP_HOTSET_CAPACITY_EXCEEDED',
        message:
            'memberCount=${_appliedQueryChipHotset.length} '
            'retainedDataCandidateCount=${_preparedQueryCandidateCache.length} '
            'maxCandidates=$_maximumPreparedQueryCandidates '
            'maxBytes=$_maximumPreparedQueryCandidateBytes',
      ),
    );
    return null;
  }

  void _replaceAppliedQueryChipHotset() {
    _replaceAppliedQueryChipHotsetForDirection(
      navigation.state.parentQueryScope.direction,
    );
  }

  void _replaceAppliedQueryChipHotsetForDirection(LedgerDirection direction) {
    final physicalWindow = _activePreparedQueryYearWindow();
    if (physicalWindow == null ||
        currentQuery.facetPresentationFor(direction) == null) {
      _appliedQueryChipHotset = const <String>{};
      _candidateSceneWindowHotsetSetter?.call(_appliedQueryChipHotset);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_CHIP_HOTSET_REPLACED_FOR_DIRECTION',
          direction: direction.name,
          coreRevision: preparedIndex?.coreRevision,
          scope:
              'neighborCount=0 '
              'editorOpen=${queryComposer.isOpen} '
              'reason=${physicalWindow == null ? 'activeWindowUnavailable' : 'noFacetPresentation'}',
        ),
      );
      return;
    }
    final applied = currentQuery.scopeFor(direction);
    final targets = _queryChipNeighborsFor(applied);
    _appliedQueryChipHotset = Set<String>.unmodifiable(
      targets.map(
        (target) => _preparedQueryCandidateCacheKey(
          currentQuery.queries.replaceDirection(target.direction, target),
          physicalWindow: physicalWindow,
        ),
      ),
    );
    _candidateSceneWindowHotsetSetter?.call(_appliedQueryChipHotset);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_CHIP_HOTSET_REPLACED_FOR_DIRECTION',
        direction: direction.name,
        coreRevision: preparedIndex?.coreRevision,
        message:
            'neighborCount=${_appliedQueryChipHotset.length} '
            'retainedDataCandidateCount=${_preparedQueryCandidateCache.length} '
            'activePhysicalWindow=${physicalWindow.cacheIdentity} '
            'editorOpen=${queryComposer.isOpen}',
      ),
    );
  }

  void _suspendAppliedQueryChipHotsetForEditor() {
    if (_appliedQueryChipHotset.isEmpty) return;
    final previousDirection = navigation.state.parentQueryScope.direction;
    _appliedQueryChipHotset = const <String>{};
    _candidateSceneWindowHotsetSetter?.call(_appliedQueryChipHotset);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_CHIP_HOTSET_SUSPENDED_FOR_EDITOR',
        direction: previousDirection.name,
        coreRevision: preparedIndex?.coreRevision,
        scope: 'editorOpen=true',
      ),
    );
  }

  PreparedQueryCandidateData? _preparedQueryCandidateDataFor(String cacheKey) {
    final candidate = _preparedQueryCandidateCache.remove(cacheKey);
    if (candidate != null) {
      _preparedQueryCandidateCache[cacheKey] = candidate;
    }
    return candidate;
  }

  void _invalidatePreparedQueryCandidatesForRevision(int coreRevision) {
    _appliedQueryChipHotset = const <String>{};
    _candidateSceneWindowHotsetSetter?.call(_appliedQueryChipHotset);
    final staleKeys = _preparedQueryCandidateCache.entries
        .where((entry) => entry.value.index.coreRevision != coreRevision)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in staleKeys) {
      _preparedQueryCandidateCache.remove(key);
      _candidateSceneWindowDiscarder?.call(key);
    }
    final staged = _stagedQueryCandidate;
    if (staged != null && staged.index.coreRevision != coreRevision) {
      _stagedQueryCandidate = null;
    }
  }

  /// Opens the explicit foreground boundary for speculative chip work.
  ///
  /// The shell calls this only after it has removed the Query sheet. The
  /// controller remains the sole scheduler/owner of the actual native work.
  void notifyQuerySheetDismissed() {
    if (_disposed) return;
    _queryChipPrewarmAwaitingDismissal = false;
    _startQueryChipPrewarm();
  }

  /// Invalidates the one speculative chip-preparation generation. This does
  /// not own the next foreground request; it merely releases the speculative
  /// lane so that request can take priority. A stale task observes its epoch
  /// before cache publication and cannot retain an old neighbour set.
  void _supersedeQueryChipPrewarm() {
    final hadInFlight = _queryChipPrewarmInFlight;
    _queryChipPrewarmGeneration += 1;
    _queryChipPrewarmInFlight = false;
    _queryChipPrewarmRequested = false;
    if (hadInFlight) dataRuntime.cancelPreparedQuery();
  }

  void _startQueryChipPrewarm({bool requireDismissal = false}) {
    if (_disposed || queryComposer.isOpen) return;
    if (requireDismissal) {
      _queryChipPrewarmAwaitingDismissal = true;
      return;
    }
    if (_queryChipPrewarmAwaitingDismissal) return;
    if (_queryChipPrewarmInFlight) return;
    if (diagnostics.isMotionActive || _verticalInteractionActive) {
      _queryChipPrewarmRequested = true;
      return;
    }
    final direction = navigation.state.parentQueryScope.direction;
    final applied = currentQuery.scopeFor(direction);
    // Neighbour candidates are only useful for actually rendered chips. A
    // programmatic scope application without facet presentation must not
    // create speculative native work merely because its filters are nonempty.
    if (currentQuery.facetPresentationFor(direction) == null) return;
    final neighbors = _queryChipNeighborsFor(applied);
    if (neighbors.isEmpty) return;
    _queryChipPrewarmRequested = false;
    final generation = ++_queryChipPrewarmGeneration;
    _queryChipPrewarmInFlight = true;
    // A chip publication has already consumed its exact prepared candidate.
    // Start new speculative neighbours only after that interaction turn, so a
    // human chip tap never synchronously dispatches the next native index
    // build. This is an explicit priority boundary, not a timing delay: newer
    // foreground input invalidates [generation] before this task can acquire
    // the shared prepared-index lane.
    unawaited(
      Future<void>.microtask(() => _runQueryChipPrewarm(generation, neighbors)),
    );
  }

  List<CurrentLedgerQueryScope> _queryChipNeighborsFor(
    CurrentLedgerQueryScope applied,
  ) => <CurrentLedgerQueryScope>[
    for (final categoryId in applied.categoryIds)
      applied.copyWith(
        categoryIds: <String>{...applied.categoryIds}..remove(categoryId),
      ),
    for (final partnerId in applied.partnerIds)
      applied.copyWith(
        partnerIds: <String>{...applied.partnerIds}..remove(partnerId),
      ),
    if (applied.categoryIds.isNotEmpty ||
        applied.partnerIds.isNotEmpty ||
        applied.refinements.isNotEmpty ||
        applied.temporalFilter.isRestrictive)
      CurrentLedgerQueryScope(
        direction: applied.direction,
        timeScope: const AllTimeScope(),
      ),
  ];

  Future<void> _runQueryChipPrewarm(
    int generation,
    List<CurrentLedgerQueryScope> neighbors,
  ) async {
    try {
      final physicalWindow = _activePreparedQueryYearWindow();
      if (physicalWindow == null) return;
      for (final scope in neighbors) {
        if (_disposed ||
            generation != _queryChipPrewarmGeneration ||
            queryComposer.isOpen ||
            diagnostics.isMotionActive ||
            _verticalInteractionActive) {
          if (diagnostics.isMotionActive || _verticalInteractionActive) {
            _queryChipPrewarmRequested = true;
          }
          return;
        }
        final queries = currentQuery.queries.replaceDirection(
          scope.direction,
          scope,
        );
        final cacheKey = _preparedQueryCandidateCacheKey(
          queries,
          physicalWindow: physicalWindow,
        );
        if (_preparedQueryCandidateCache.containsKey(cacheKey)) continue;
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_CHIP_HOTSET_PREPARE_STARTED',
            flowId: 'generation:$generation',
            queryKey: scope.key.value,
            direction: scope.direction.name,
            scope:
                'hotsetMember=${_appliedQueryChipHotset.contains(cacheKey)} '
                'candidateCacheKey=$cacheKey '
                'neighborCount=${_appliedQueryChipHotset.length}',
          ),
        );
        final index = await dataRuntime.prepareQuery(
          DashboardIndexRequestTemplate.forPreparedYearWindow(
            directionalQueries: queries,
            pageSize: pageSize,
            yearWindow: physicalWindow,
          ),
        );
        if (_disposed ||
            generation != _queryChipPrewarmGeneration ||
            queryComposer.isOpen ||
            diagnostics.isMotionActive ||
            _verticalInteractionActive ||
            index.coreRevision != preparedIndex?.coreRevision) {
          if (diagnostics.isMotionActive || _verticalInteractionActive) {
            _queryChipPrewarmRequested = true;
          }
          return;
        }
        final availability = DashboardTemporalAvailability.fromTemporalFilter(
          scope.temporalFilter,
        );
        final state = navigation.appliedQueryCandidate(
          scope,
          availability: availability,
          coreRevision: index.coreRevision,
        );
        final bundle = DashboardPreparedRevisionBundle.forIndex(
          index,
          publicationState: state,
        );
        final interactionWindow = bundle.railInteractionSceneWindow
            .withCoverage(_coverageFor(state, indexOverride: index));
        final prepareCandidate = _candidateSceneWindowPreparer;
        if (prepareCandidate != null) {
          await prepareCandidate(
            interactionWindow,
            candidateKey: cacheKey,
            retainViewportId: visibleFrames.value?.logBox.viewportId,
          );
          if (_disposed ||
              generation != _queryChipPrewarmGeneration ||
              queryComposer.isOpen ||
              diagnostics.isMotionActive ||
              _verticalInteractionActive) {
            if (diagnostics.isMotionActive || _verticalInteractionActive) {
              _queryChipPrewarmRequested = true;
            }
            _candidateSceneWindowDiscarder?.call(cacheKey);
            return;
          }
        }
        _putPreparedQueryCandidateData(
          PreparedQueryCandidateData(
            cacheKey: cacheKey,
            directionalQueries: queries,
            index: index,
          ),
        );
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_CHIP_HOTSET_READY',
            flowId: 'generation:$generation',
            queryKey: scope.key.value,
            direction: scope.direction.name,
            coreRevision: index.coreRevision,
            scope:
                'hotsetMember=${_appliedQueryChipHotset.contains(cacheKey)} '
                'candidateCacheKey=$cacheKey '
                'retainedDataCandidateCount=${_preparedQueryCandidateCache.length}',
          ),
        );
      }
    } on DashboardIndexPreparationDiscarded {
      // New foreground Query/menu work owns the one native preparation lane.
    } on DashboardLogBoxScenePreparationCancelled {
      // A hot-path rail gesture may cancel speculative chip work. The next
      // idle publication can prewarm it again; active rendering is unchanged.
      _queryChipPrewarmRequested = true;
    } finally {
      if (generation == _queryChipPrewarmGeneration) {
        _queryChipPrewarmInFlight = false;
      }
    }
  }

  void _recordQueryChipTransition(CurrentLedgerQueryScope target) {
    final physicalWindow = _activePreparedQueryYearWindow();
    if (physicalWindow == null) return;
    final key = _preparedQueryCandidateCacheKey(
      currentQuery.queries.replaceDirection(target.direction, target),
      physicalWindow: physicalWindow,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: _preparedQueryCandidateCache.containsKey(key)
            ? 'QUERY_CHIP_PREPARED_HIT'
            : 'QUERY_CHIP_PREPARED_MISS',
        queryKey: target.key.value,
        direction: target.direction.name,
        scope:
            'hotsetMember=${_appliedQueryChipHotset.contains(key)} '
            'candidateCacheKey=$key '
            'neighborCount=${_appliedQueryChipHotset.length} '
            'retainedDataCandidateCount=${_preparedQueryCandidateCache.length}',
      ),
    );
  }

  /// Applies a canonical Query Menu scope only after its immutable index and
  /// publication-critical scenes exist. Noncritical bank completion remains
  /// cancellable background maintenance; the callbacks make navigation, index
  /// and applied-query pointer switch at one publication boundary.
  Future<bool> applyQuery(
    CurrentLedgerQueryScope draft, {
    QueryMenuData? facetPresentation,
    QueryComposerApplyIdentity? composerApplyIdentity,
  }) {
    final template = draft.copyWith(timeScope: const AllTimeScope());
    final effectiveComposerIdentity =
        composerApplyIdentity ??
        (queryComposer.isOpen ? queryComposer.applyIdentity : null);
    if (effectiveComposerIdentity != null &&
        !queryComposer.isCurrentApplyIdentity(effectiveComposerIdentity)) {
      return Future<bool>.value(false);
    }
    if (template == currentQuery.scopeFor(template.direction)) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_APPLY_NOOP',
          queryKey: template.key.value,
          direction: template.direction.name,
          scope: 'alreadyApplied=true',
        ),
      );
      final completed = effectiveComposerIdentity == null
          ? true
          : queryComposer.completeApplied(
              expectedIdentity: effectiveComposerIdentity,
            );
      return Future<bool>.value(completed);
    }
    final inFlight = _queryApplyInFlight;
    if (inFlight != null) {
      if (_activeComposerApplyIdentity == effectiveComposerIdentity) {
        return inFlight;
      }
      _cancelActiveComposerApply(reason: 'newerApply');
    }
    late final Future<bool> operation;
    _activeComposerApplyIdentity = effectiveComposerIdentity;
    operation =
        _applyPreparedQuery(
          template,
          facetPresentation: facetPresentation,
          composerApplyIdentity: effectiveComposerIdentity,
        ).whenComplete(() {
          if (identical(_queryApplyInFlight, operation)) {
            _queryApplyInFlight = null;
            _activeComposerApplyIdentity = null;
          }
        });
    _queryApplyInFlight = operation;
    return operation;
  }

  Future<bool> _applyPreparedQuery(
    CurrentLedgerQueryScope draft, {
    required QueryMenuData? facetPresentation,
    required QueryComposerApplyIdentity? composerApplyIdentity,
  }) async {
    final generation = ++_queryApplyGeneration;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_STARTED',
        flowId: 'generation:$generation',
        queryKey: draft.key.value,
        direction: draft.direction.name,
      ),
    );
    final desiredQueries = currentQuery.queries.replaceDirection(
      draft.direction,
      draft,
    );
    final physicalWindow = _activePreparedQueryYearWindow();
    if (physicalWindow == null) {
      _abortAcceptedComposerApply(composerApplyIdentity);
      return false;
    }
    final cacheKey = _preparedQueryCandidateCacheKey(
      desiredQueries,
      physicalWindow: physicalWindow,
    );
    final previousFailure = _failedQueryCandidate;
    if (composerApplyIdentity != null &&
        previousFailure != null &&
        previousFailure.cacheKey == cacheKey &&
        previousFailure.composerIdentity == composerApplyIdentity) {
      _abortAcceptedComposerApply(composerApplyIdentity);
      return false;
    }
    PreparedQueryCandidate? candidate = _stagedQueryCandidate;
    final candidateMatches =
        candidate != null &&
        candidate.cacheKey == cacheKey &&
        candidate.editedScope == draft &&
        candidate.composerIdentity == composerApplyIdentity;
    if (!candidateMatches) {
      final cachedData = _preparedQueryCandidateDataFor(cacheKey);
      if (cachedData != null) {
        candidate = _candidateForCachedData(
          data: cachedData,
          draft: draft,
          composerIdentity: composerApplyIdentity,
          facetPresentation: facetPresentation,
        );
      } else {
        final active = _activeQueryCandidatePreparation;
        if (active != null &&
            active.cacheKey == cacheKey &&
            active.composerIdentity == composerApplyIdentity) {
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'QUERY_APPLY_WAITED_FOR_STAGED_CANDIDATE',
              flowId: 'generation:$generation',
              queryKey: draft.key.value,
              direction: draft.direction.name,
            ),
          );
          candidate = await active.future;
        } else {
          candidate = await prepareQueryDraft(
            draft,
            composerIdentity: composerApplyIdentity,
            facetPresentation: facetPresentation,
          );
        }
      }
    }
    if (candidate == null ||
        !_isCurrentQueryApply(
          generation: generation,
          composerApplyIdentity: composerApplyIdentity,
        )) {
      _abortAcceptedComposerApply(composerApplyIdentity);
      return false;
    }
    final candidateBankStillRetained =
        candidate.sceneStaged &&
        (_candidateSceneWindowLookup?.call(
              candidate.currentParentInteractionWindow,
              candidateKey: candidate.cacheKey,
            ) ??
            true);
    if (!candidateBankStillRetained) {
      // The immutable index cache may have supplied this candidate after a
      // newer draft occupied the one scene-cache staging slot. Re-stage its
      // O(1) first-frame bank; this is never a second native index build.
      final prepareCandidate = _candidateSceneWindowPreparer;
      final prepare = _sceneWindowPreparer;
      if (prepareCandidate != null || prepare != null) {
        try {
          if (prepareCandidate != null) {
            await prepareCandidate(
              candidate.currentParentInteractionWindow,
              candidateKey: candidate.cacheKey,
              retainViewportId: visibleFrames.value?.logBox.viewportId,
            );
          } else {
            await prepare!(
              candidate.currentParentInteractionWindow,
              retainViewportId: visibleFrames.value?.logBox.viewportId,
            );
          }
        } on DashboardLogBoxScenePreparationCancelled {
          return false;
        }
      }
      final exactBankRetained =
          prepareCandidate == null ||
          (_candidateSceneWindowLookup?.call(
                candidate.currentParentInteractionWindow,
                candidateKey: candidate.cacheKey,
              ) ??
              true);
      if (!exactBankRetained) {
        _reportQueryCandidateSceneRetentionRejected(
          candidateKey: candidate.cacheKey,
          window: candidate.currentParentInteractionWindow,
          reason: 'applyRestageCompletedWithoutRetainedCandidateBank',
        );
        _abortAcceptedComposerApply(composerApplyIdentity);
        return false;
      }
      candidate = candidate.copyWith(sceneStaged: true);
      _stagedQueryCandidate = candidate;
    }
    if (!_isCurrentQueryApply(
      generation: generation,
      composerApplyIdentity: composerApplyIdentity,
    )) {
      return false;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_PREPARED_HIT',
        flowId: 'generation:$generation',
        queryKey: draft.key.value,
        direction: draft.direction.name,
        coreRevision: candidate.index.coreRevision,
      ),
    );
    return _publishPreparedQueryCandidate(
      candidate,
      generation: generation,
      facetPresentation: facetPresentation,
      composerApplyIdentity: composerApplyIdentity,
    );
  }

  void _reportQueryCandidateSceneRetentionRejected({
    required String candidateKey,
    required DashboardLogBoxSceneWindow window,
    required String reason,
  }) {
    final report = _sceneWindowReporter?.call() ?? const <String, Object?>{};
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_CANDIDATE_SCENE_RETENTION_REJECTED',
        queryKey: window.identity,
        entryCount: window.previewRowCount,
        coreRevision: window.coverageIdentity?.coreRevision,
        scope:
            'candidateKey=$candidateKey reason=$reason '
            'retainedCandidateBankCount='
            '${report['retainedCandidateBanks'] ?? 'unknown'} '
            'protectedCandidateBankCount='
            '${report['protectedCandidateBanks'] ?? 'unknown'} '
            'retainedUniqueRows='
            '${report['retainedCandidateUniqueRows'] ?? 'unknown'} '
            'retainedEstimatedBytes='
            '${report['retainedCandidateBytes'] ?? 'unknown'}',
      ),
    );
  }

  Future<bool> _publishPreparedQueryCandidate(
    PreparedQueryCandidate candidate, {
    required int generation,
    required QueryMenuData? facetPresentation,
    required QueryComposerApplyIdentity? composerApplyIdentity,
  }) async {
    if (!_isCurrentQueryApply(
      generation: generation,
      composerApplyIdentity: composerApplyIdentity,
    )) {
      return false;
    }
    final activate = _sceneWindowActivator;
    try {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_APPLY_PUBLICATION_STARTED',
          flowId: 'generation:$generation',
          queryKey: candidate.editedScope.key.value,
          direction: candidate.editedScope.direction.name,
          coreRevision: candidate.index.coreRevision,
        ),
      );
      if (activate != null) {
        _activateSceneWindow(
          candidate.currentParentInteractionWindow,
          activate: activate,
        );
      }
      if (!_isCurrentQueryApply(
        generation: generation,
        composerApplyIdentity: composerApplyIdentity,
      )) {
        return false;
      }
      presentation.navigation.replaceAppliedQuery(
        candidate.editedScope,
        availability: candidate.availability,
        coreRevision: candidate.index.coreRevision,
      );
      _publishIndex(candidate.index, preparedRevisionBundle: candidate.bundle);
      dataRuntime.commitPreparedQuery(
        candidate.index,
        candidate.requestTemplate,
      );
      currentQuery.replaceDirection(
        candidate.editedScope.direction,
        candidate.editedScope,
        facetPresentation: facetPresentation ?? candidate.facetPresentation,
      );
      _removeActivePreparedQueryCandidateData(candidate.cacheKey);
      _stagedQueryCandidate = null;
      if (_activeComposerApplyIdentity == composerApplyIdentity) {
        _activeComposerApplyIdentity = null;
      }
      final completed = composerApplyIdentity == null
          ? true
          : queryComposer.completeApplied(
              expectedIdentity: composerApplyIdentity,
            );
      if (!completed) return false;
      _startRailInteractionWarmup(candidate.index, state: navigation.state);
      // Only a composer-backed Apply has a foreground sheet whose removal
      // must outrank speculation. Dashboard-chip publication has no sheet;
      // its own microtask boundary in [_startQueryChipPrewarm] is sufficient
      // to keep the tap synchronous while allowing its new neighbours to be
      // staged afterwards.
      _supersedeQueryChipPrewarm();
      _replaceAppliedQueryChipHotset();
      _startQueryChipPrewarm(requireDismissal: composerApplyIdentity != null);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_APPLY_PUBLICATION_COMPLETED',
          flowId: 'generation:$generation',
          queryKey: candidate.editedScope.key.value,
          direction: candidate.editedScope.direction.name,
          coreRevision: candidate.index.coreRevision,
        ),
      );
      _recordQueryApplyCompleted(
        generation: generation,
        scope: candidate.editedScope,
        published: true,
      );
      return true;
    } on Object catch (error) {
      _abortAcceptedComposerApply(composerApplyIdentity);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_APPLY_PUBLICATION_FAILED',
          flowId: 'generation:$generation',
          queryKey: candidate.editedScope.key.value,
          direction: candidate.editedScope.direction.name,
          coreRevision: candidate.index.coreRevision,
          error: '$error',
        ),
      );
      return false;
    }
  }

  bool _isCurrentQueryApply({
    required int generation,
    required QueryComposerApplyIdentity? composerApplyIdentity,
  }) =>
      !_disposed &&
      generation == _queryApplyGeneration &&
      (composerApplyIdentity == null ||
          queryComposer.isCurrentApplyIdentity(composerApplyIdentity));

  void _onQueryComposerChanged() {
    switch (queryComposer.lastStateChange) {
      case QueryComposerStateChange.opened:
        _suspendAppliedQueryChipHotsetForEditor();
      case QueryComposerStateChange.closed:
      case QueryComposerStateChange.applyAborted:
        _replaceAppliedQueryChipHotsetForDirection(
          navigation.state.parentQueryScope.direction,
        );
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_CHIP_HOTSET_RESTORED_AFTER_CANCEL',
            direction: navigation.state.parentQueryScope.direction.name,
            coreRevision: preparedIndex?.coreRevision,
            scope: 'editorOpen=${queryComposer.isOpen}',
          ),
        );
        // Cancellation leaves the applied dashboard intact. Once its exact
        // chip-neighbour protection is restored, resume only missing
        // speculative neighbours through the existing background scheduler.
        // The scheduler itself refuses to run while a composer remains open.
        _startQueryChipPrewarm();
      case QueryComposerStateChange.draftChanged:
      case QueryComposerStateChange.applyAccepted:
      case QueryComposerStateChange.applied:
        break;
    }
    final candidateIdentity =
        _activeQueryCandidatePreparation?.composerIdentity;
    if (candidateIdentity != null &&
        !queryComposer.isCurrentApplyIdentity(candidateIdentity)) {
      final applyOwnsSameSession =
          _activeComposerApplyIdentity == candidateIdentity;
      if (applyOwnsSameSession) {
        _cancelActiveComposerApply(reason: 'draftCandidateSuperseded');
      }
      discardQueryDraftCandidate(
        reason: switch (queryComposer.lastStateChange) {
          QueryComposerStateChange.draftChanged => 'draftChanged',
          QueryComposerStateChange.closed => 'sheetClosed',
          QueryComposerStateChange.opened => 'sheetReopened',
          QueryComposerStateChange.applyAccepted => 'applyAccepted',
          QueryComposerStateChange.applied => 'applied',
          QueryComposerStateChange.applyAborted => 'applyAborted',
        },
        cancelScenePreparation: !applyOwnsSameSession,
      );
      return;
    }
    final identity = _activeComposerApplyIdentity;
    if (identity == null || queryComposer.isCurrentApplyIdentity(identity)) {
      return;
    }
    final reason = switch (queryComposer.lastStateChange) {
      QueryComposerStateChange.draftChanged => 'draftChanged',
      QueryComposerStateChange.closed => 'sheetClosed',
      QueryComposerStateChange.opened => 'sheetReopened',
      QueryComposerStateChange.applyAccepted => 'applyAccepted',
      QueryComposerStateChange.applied => 'applied',
      QueryComposerStateChange.applyAborted => 'applyAborted',
    };
    _cancelActiveComposerApply(reason: reason);
  }

  void _cancelActiveComposerApply({required String reason}) {
    final identity = _activeComposerApplyIdentity;
    if (identity == null) return;
    _activeComposerApplyIdentity = null;
    _abortAcceptedComposerApply(identity);
    _queryApplyGeneration += 1;
    if (!_cancelBackgroundSceneWarmup()) {
      _sceneWindowPreparationCanceller?.call();
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_CANCELLED',
        flowId: 'session:${identity.sessionId}',
        queryKey: identity.draftKey,
        scope: 'reason=$reason',
      ),
    );
  }

  void _abortAcceptedComposerApply(
    QueryComposerApplyIdentity? composerApplyIdentity,
  ) {
    if (composerApplyIdentity == null) return;
    queryComposer.abortAcceptedApply(identity: composerApplyIdentity);
  }

  void _recordQueryApplyCompleted({
    required int generation,
    required CurrentLedgerQueryScope scope,
    required bool published,
  }) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_COMPLETED',
        flowId: 'generation:$generation',
        queryKey: published
            ? currentQuery.scopeFor(scope.direction).key.value
            : scope.key.value,
        direction: scope.direction.name,
        scope: 'published=$published',
      ),
    );
  }

  /// Dashboard chip intent: produce one new immutable applied scope, then use
  /// the same prepared-index publication boundary as Query Menu Apply.
  void removeAppliedQueryCategory(String categoryId) {
    final direction = navigation.state.parentQueryScope.direction;
    final scope = currentQuery.scopeFor(direction);
    final categories = <String>{...scope.categoryIds}..remove(categoryId);
    final target = scope.copyWith(categoryIds: categories);
    _recordQueryChipTransition(target);
    unawaited(
      applyQuery(
        target,
        facetPresentation: currentQuery.facetPresentationFor(direction),
      ),
    );
  }

  void removeAppliedQueryPartner(String partnerId) {
    final direction = navigation.state.parentQueryScope.direction;
    final scope = currentQuery.scopeFor(direction);
    final partners = <String>{...scope.partnerIds}..remove(partnerId);
    final target = scope.copyWith(partnerIds: partners);
    _recordQueryChipTransition(target);
    unawaited(
      applyQuery(
        target,
        facetPresentation: currentQuery.facetPresentationFor(direction),
      ),
    );
  }

  void clearAppliedQuery() {
    final direction = navigation.state.parentQueryScope.direction;
    final scope = currentQuery.scopeFor(direction);
    final target = CurrentLedgerQueryScope(
      direction: scope.direction,
      timeScope: const AllTimeScope(),
    );
    _recordQueryChipTransition(target);
    unawaited(applyQuery(target));
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
    // A physical rail gesture has absolute priority over speculative text
    // layout. The next settle will enqueue exactly one latest target again.
    if (origin == CenteredCarouselMotionOrigin.userDrag) {
      _cancelSceneWindowMaintenanceForInput();
    }
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

  void toggleRail() => setRailOpen(
    !(_pendingRailVisibilityIntentEpoch == null
        ? navigation.state.isRailOpen
        : _desiredRailVisibility!),
  );

  void setRailOpen(bool open) {
    final effectiveVisibility = _pendingRailVisibilityIntentEpoch == null
        ? navigation.state.isRailOpen
        : _desiredRailVisibility!;
    if (open == effectiveVisibility) return;

    final intentEpoch = ++_railVisibilityIntentEpoch;
    _desiredRailVisibility = open;
    _pendingRailVisibilityIntentEpoch = intentEpoch;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'RAIL_VISIBILITY_INTENT_ACCEPTED',
        message:
            'desiredOpen=$open committedOpen=${navigation.state.isRailOpen} '
            'intentEpoch=$intentEpoch',
        queryKey: navigation.state.parentQueryKey.value,
        coreRevision: coreRevision,
      ),
    );

    _reconcilePendingRailVisibilityIntent();
  }

  bool _hasPendingStructuralNavigationForRailVisibility() {
    final pending = _pendingSceneCoveredNavigation;
    if (pending == null) return false;
    return pending.owner == _SceneCoveredNavigationOwner.structural;
  }

  /// A rail-visibility tap made while a plane, parent, or direction candidate
  /// is held behind scene coverage must be applied to that final structural
  /// state. Deriving its candidate immediately from the old committed state
  /// would replace the user’s structural intent with an obsolete rail target.
  ///
  /// The desired visibility remains a core-owned latest-intent value. Once
  /// the pending structural candidate commits, this method derives the real
  /// visibility candidate from the new committed state and gives an explicit
  /// rail open its complete immediate interaction domain before publication.
  bool _reconcilePendingRailVisibilityIntent() {
    final intentEpoch = _pendingRailVisibilityIntentEpoch;
    final desiredOpen = _desiredRailVisibility;
    if (intentEpoch == null || desiredOpen == null) return false;
    if (_hasPendingStructuralNavigationForRailVisibility()) return false;

    if (desiredOpen == navigation.state.isRailOpen) {
      _pendingRailVisibilityIntentEpoch = null;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'RAIL_VISIBILITY_INTENT_COMMITTED',
          message:
              'desiredOpen=$desiredOpen committedOpen=${navigation.state.isRailOpen} '
              'intentEpoch=$intentEpoch noStateChange=true',
          queryKey: navigation.state.parentQueryKey.value,
          coreRevision: coreRevision,
        ),
      );
      return false;
    }

    final candidate = presentation.railVisibilityCandidate(desiredOpen);
    unawaited(
      _commitNavigationWithSceneCoverage(
        candidate: candidate,
        reason: desiredOpen ? 'railOpened' : 'railClosed',
        settledQueryKey: candidate.parentQueryKey,
        requirement: desiredOpen
            ? _DashboardNavigationSceneRequirement.railInteraction
            : _DashboardNavigationSceneRequirement.structuralPublication,
        owner: _SceneCoveredNavigationOwner.railVisibility,
        commit: () {
          if (_disposed ||
              intentEpoch != _railVisibilityIntentEpoch ||
              _desiredRailVisibility != desiredOpen) {
            FluviDiagnosticLogger.log(
              FluviDiagnosticEvent(
                stage: 'RAIL_VISIBILITY_INTENT_SUPERSEDED',
                message:
                    'desiredOpen=$desiredOpen committedOpen=${navigation.state.isRailOpen} '
                    'intentEpoch=$intentEpoch latestIntentEpoch=$_railVisibilityIntentEpoch',
                queryKey: candidate.parentQueryKey.value,
                coreRevision: coreRevision,
              ),
            );
            return;
          }
          if (!desiredOpen) {
            presentation.retainVisibleRailChildForStructuralExit();
          }
          presentation.commitRailVisibilityCandidate(candidate);
          _pendingRailVisibilityIntentEpoch = null;
          _recordNavigationSelection(desiredOpen ? 'railOpened' : 'railClosed');
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'RAIL_VISIBILITY_INTENT_COMMITTED',
              message:
                  'desiredOpen=$desiredOpen committedOpen=${navigation.state.isRailOpen} '
                  'intentEpoch=$intentEpoch',
              queryKey: navigation.state.parentQueryKey.value,
              coreRevision: coreRevision,
            ),
          );
        },
      ),
    );
    return true;
  }

  Future<void> navigateParent(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    _supersedeAcceptedQueryApplyForDashboardNavigation();
    final candidate = presentation.parentCandidate(direction);
    if (candidate == null) return Future<void>.value();
    final interaction = railInteractionSceneWindowFor(candidate);
    final retainedHit = _retainedSceneWindowLookup?.call(interaction) ?? false;
    // A retained parent hotset is already complete but intentionally invisible.
    // Make that exact immutable bank active before the metadata commit, so the
    // Summary interaction consumes a true O(1) prepared hit rather than merely
    // recognizing it and then scheduling a duplicate foreground preparation.
    if (retainedHit) {
      _activateSceneWindow(interaction);
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: retainedHit
            ? 'SUMMARY_PARENT_PREPARED_HIT'
            : 'SUMMARY_PARENT_PREPARED_MISS',
        queryKey: candidate.parentQueryKey.value,
        coreRevision: interaction.coverageIdentity?.coreRevision,
        entryCount: interaction.previewRowCount,
      ),
    );
    return _commitNavigationWithSceneCoverage(
      candidate: candidate,
      reason: 'parentNavigation',
      settledQueryKey: candidate.parentQueryKey,
      requiredSceneWindow: retainedHit ? interaction : null,
      commit: () {
        presentation.commitParentCandidate(candidate, direction);
        _recordNavigationSelection('parentCommitted');
      },
    );
  }

  void commitParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) => unawaited(navigateParent(direction));

  DashboardNavigationState? previewParent(
    DashboardTimeNavigationChangeDirection direction,
  ) => presentation.parentCandidate(direction);

  void navigatePlane({required bool finer}) {
    _supersedeAcceptedQueryApplyForDashboardNavigation();
    final candidate = presentation.planeCandidate(finer: finer);
    unawaited(
      _commitNavigationWithSceneCoverage(
        candidate: candidate,
        reason: finer ? 'planeFiner' : 'planeCoarser',
        settledQueryKey: candidate.parentQueryKey,
        requirement: _DashboardNavigationSceneRequirement.structuralPublication,
        commit: () {
          presentation.commitPlaneCandidate(candidate, finer: finer);
          _recordNavigationSelection('planeCommitted');
        },
      ),
    );
  }

  void selectDirection(TransactionDirection direction) {
    // The Query sheet is a modal edit session. Dashboard direction is not
    // allowed to change underneath its independent draft, because that would
    // create an ambiguous applied/draft ownership transition.
    if (queryComposer.isOpen) return;
    _supersedeAcceptedQueryApplyForDashboardNavigation();
    final ledgerDirection = direction == TransactionDirection.income
        ? LedgerDirection.income
        : LedgerDirection.expense;
    final targetTemplate = currentQuery.scopeFor(ledgerDirection);
    final targetAvailability = DashboardTemporalAvailability.fromTemporalFilter(
      targetTemplate.temporalFilter,
    );
    final candidate = presentation.directionCandidate(
      ledgerDirection,
      template: targetTemplate,
      availability: targetAvailability,
    );
    final activeIndex = presentation.index;
    final cacheHit =
        activeIndex != null &&
        _activeSceneWindowCovers(
          structuralPublicationSceneWindowFor(
            candidate,
            indexOverride: activeIndex,
          ),
        );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_DIRECTION_SELECTED',
        queryKey: targetTemplate.key.value,
        direction: ledgerDirection.name,
        coreRevision: activeIndex?.coreRevision,
        scope:
            'targetAppliedQueryKey=${targetTemplate.key.value} '
            'cacheHit=$cacheHit',
      ),
    );
    unawaited(
      _commitNavigationWithSceneCoverage(
        candidate: candidate,
        reason: 'directionChanged',
        settledQueryKey: candidate.parentQueryKey,
        commit: () {
          transactionDirection.select(direction);
          presentation.commitDirectionCandidate(
            candidate,
            availability: targetAvailability,
          );
          // Direction selection reads the other half of the single applied
          // directional Query set. It never copies/mutates filters across
          // directions; the pair is already embedded in this one index.
          _recordNavigationSelection('directionChanged');
          _replaceAppliedQueryChipHotsetForDirection(ledgerDirection);
        },
      ),
    );
  }

  void _supersedeAcceptedQueryApplyForDashboardNavigation() {
    if (!queryComposer.hasAcceptedApply) return;
    _cancelActiveComposerApply(reason: 'dashboardNavigation');
  }

  Future<bool> loadNextPage() => paging.loadNextPage();

  bool get verticalInteractionActive => _verticalInteractionActive;

  /// Exact background-work state for one vertical interaction diagnostic.
  /// Paging lives in a separate owner, so its three stages are surfaced
  /// explicitly rather than hidden behind an ambiguous aggregate boolean.
  DashboardVerticalBackgroundWorkSnapshot get verticalBackgroundWork =>
      DashboardVerticalBackgroundWorkSnapshot(
        sceneSpeculationActive:
            _backgroundSceneWarmupInFlight ||
            _backgroundSceneWarmupScheduled ||
            _summaryParentHotsetInFlight,
        querySpeculationActive: _queryChipPrewarmInFlight,
        committedPageRequestInFlight: paging.committedPageRequestInFlight,
        committedPageDataPendingPresentation:
            paging.committedPageDataPendingPresentation,
        committedPagePresentationActive: paging.committedPagePresentationActive,
      );

  /// Compatibility aggregate for existing consumers. New diagnostics must use
  /// [verticalBackgroundWork] so active page presentation cannot be reported
  /// as false background work.
  bool get hasVerticalBackgroundWork => verticalBackgroundWork.anyActive;

  Future<bool> requestForwardPageDemand(int desiredLastReadyOrdinal) =>
      paging.requestForwardDemand(desiredLastReadyOrdinal);

  void beginVerticalPageDemandEpoch() => paging.beginForwardDemandEpoch();

  /// A fresh pointer on the LogBox owns the cross-axis boundary. If the rail
  /// currently exposes an exact preview sibling, promote that same immutable
  /// frame before Flutter delivers this pointer's ScrollStartNotification.
  void noteVerticalPointerDown() {
    _cancelSceneWindowMaintenanceForInput();
    final railActivityBefore = motion.state.activity.name;
    final pointerTimestamp = DateTime.now().toIso8601String();
    if (!presentation.takeOverVisibleRailPreviewForVerticalInput()) return;
    final committed = visibleFrames.value;
    if (committed == null) return;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'VERTICAL_PREVIEW_TAKEOVER_COMMITTED',
        queryKey: committed.queryKey.value,
        coreRevision: committed.coreRevision,
        entryCount: committed.logBox.entryCount,
        message:
            'parentQueryKey=${committed.parentQueryKey.value} '
            'semanticIndex=${committed.semanticChildIndex} '
            'navigationEpoch=${committed.navigationEpoch} '
            'presentationEpoch=${committed.presentationEpoch} '
            'pointerTimestamp=$pointerTimestamp '
            'committedCacheGeneration=${paging.commitGeneration} '
            'railActivityBefore=$railActivityBefore '
            'railActivityAfter=${motion.state.activity.name}',
      ),
    );
    diagnostics.record(
      DashboardInteractionEvent.verticalPreviewTakeoverCommitted,
      context: _diagnosticContext(),
      source: 'verticalPointerDown',
    );
  }

  /// A genuine vertical gesture is never a continuation of the background
  /// scene window. Cancelling only affects speculative cache work; the
  /// vertical session owner remains the sole stale-activity authority.
  void beginVerticalInteraction() {
    if (_disposed || _verticalInteractionActive) return;
    _verticalInteractionActive = true;
    // Retained Summary targets are speculative while the stable vertical
    // ScrollPosition owns input. Invalidate their run, but leave their already
    // retained immutable banks reusable after this interaction.
    _summaryParentHotsetGeneration += 1;
    _summaryParentHotsetInFlight = false;
    _cancelSceneWindowMaintenanceForInput();
    final hadQueryChipSpeculation =
        _queryChipPrewarmInFlight || _queryChipPrewarmRequested;
    _supersedeQueryChipPrewarm();
    _queryChipPrewarmRequested = hadQueryChipSpeculation;
    paging.beginForwardDemandEpoch();
  }

  /// Resume only the current latest scene target after a real vertical scroll
  /// has gone idle. This keeps a pointer-down cancellation from discarding
  /// maintenance forever, without scheduling cache work during the drag or
  /// ballistic phase.
  void resumeSceneWindowMaintenanceAfterVerticalInput() {
    if (_disposed) return;
    if (!_verticalInteractionActive) return;
    _verticalInteractionActive = false;
    // The paging owner resumes its exact private decoded page before any
    // speculative cache warmup can re-enter the UI isolate.
    paging.resumeVerticalInputPresentation();
    if (paging.committedPageDataPendingPresentation ||
        paging.committedPagePresentationActive ||
        paging.forwardDemandDrainActive) {
      return;
    }
    _resumeSpeculativeWorkAfterCommittedPaging();
  }

  /// Committed page presentation is foreground data readiness once a vertical
  /// interaction ends. Do not let Summary/Query warmups re-enter the isolate
  /// until its exact pending page and sequential demand are settled.
  void _resumeSpeculativeWorkAfterCommittedPaging() {
    if (_disposed ||
        _verticalInteractionActive ||
        paging.committedPageDataPendingPresentation ||
        paging.committedPagePresentationActive ||
        paging.forwardDemandDrainActive) {
      return;
    }
    if (_requiredSceneCoverageDemand != null) {
      _drainRequiredSceneCoverageDemand();
      return;
    }
    final index = presentation.index ?? preparedIndex;
    if (index != null) {
      _startRailInteractionWarmup(index, state: navigation.state);
      _startAdjacentSummaryParentHotset(index, state: navigation.state);
    }
    if (_queryChipPrewarmRequested) _startQueryChipPrewarm();
    unawaited(
      _reconcileSceneCoverageAfterNavigation(reason: 'verticalInputIdle'),
    );
  }

  Future<bool> loadPreviousPage() => paging.loadPreviousPage();

  void recordLogBoxTextLayoutCache({
    required int preparedRowCount,
    required int preparedDayHeaderCount,
    required int estimatedBytes,
  }) {
    if (preparedRowCount < 0 ||
        preparedDayHeaderCount < 0 ||
        estimatedBytes < 0) {
      throw ArgumentError('LogBox text-layout cache metrics must be positive.');
    }
    _logBoxTextLayoutPreparedRows = preparedRowCount;
    _logBoxTextLayoutPreparedDayHeaders = preparedDayHeaderCount;
    _logBoxTextLayoutEstimatedBytes = estimatedBytes;
  }

  /// Retains only the latest post-layout extent snapshot for explicit physical
  /// diagnostics. The render surface emits this at state transitions, never
  /// from its paint hot path.
  void recordLogBoxRenderExtent(DashboardLogBoxRenderExtentSnapshot snapshot) {
    _lastLogBoxRenderExtent = snapshot;
    if (snapshot.isMismatch) _verticalScrollExtentMismatchCount += 1;
  }

  /// The stable viewport owns the actual top jump. The core retains only a
  /// transition counter for physical diagnostics; it never controls scroll
  /// position or participates in preview crossings.
  void recordVerticalCommittedScopeReset() {
    _verticalCommittedScopeResetCount += 1;
  }

  Map<String, Object?> _summaryDiagnosticReport() {
    final state = navigation.state;
    final visible = visibleFrames.value;
    final base = SummaryNavigationProjector.project(state);
    final subtitle = switch (visible) {
      final frame?
          when state.isRailOpen &&
              frame.parentQueryKey == state.parentQueryKey &&
              frame.navigationEpoch == state.navigationEpoch =>
        SummaryNavigationProjector.liveRailChildSubtitle(
          plane: frame.plane,
          visibleChildScope: frame.scope.timeScope,
          fallback: frame.childLabel,
        ),
      _ => base.subtitle,
    };
    return <String, Object?>{
      'plane': state.plane.name,
      'railOpen': state.isRailOpen,
      'displayedTitle': base.planeTitle,
      'displayedSubtitle': subtitle,
      'visibleChildScope': visible?.scope.timeScope.canonicalKey,
      'retainedChildSemanticIndex': state.retainedSemanticChild,
    };
  }

  Map<String, Object?> _fallbackLogBoxPresentationReport() {
    final payload = visibleFrames.logBoxLane.value;
    final presentation = visibleFrames.logBoxPresentationLane.value;
    return <String, Object?>{
      'authoritativePresentationMode': presentation?.mode.name ?? 'unbound',
      'payloadLaneMode': payload?.mode.name ?? 'unbound',
      'renderDomain': resolveDashboardLogBoxRenderDomain(
        payload: payload?.logBox,
        presentation: presentation,
        committedViewport: committedLogViewport,
      ).name,
      'payloadViewportId': payload?.logBox.viewportId,
      'authoritativeViewportId': presentation?.viewportId,
      'renderedRowCount': payload?.logBox.previewRowCount ?? 0,
      'renderedContentExtent': 0.0,
      'previewPayloadRows': payload?.logBox.previewRowCount ?? 0,
      'previewSurfaceHeight': 0.0,
      'committedCacheQueryKey': committedLogViewport.queryKey?.value,
      'committedCacheGeneration': committedLogViewport.generation,
      'committedCacheReadyRows': committedLogViewport.contiguousReadyRowCount,
      'committedCacheDrawableExtent': committedLogViewport.drawableExtent,
      'renderSurfaceHeight': 0.0,
      'sliverScrollExtent': 0.0,
      'viewportDimension': 0.0,
      'minScrollExtent': 0.0,
      'maxScrollExtent': 0.0,
      'pixels': 0.0,
      'scrollExtentMismatch': false,
    };
  }

  /// The exact active immutable scene bank. It begins as the small structural
  /// publication window and may later expand to the current rail interaction
  /// window through background warmup.
  List<DashboardLogViewportState> renderCriticalLogBoxPayloads() =>
      railCriticalSceneWindow().payloads;

  DashboardLogBoxSceneWindow renderCriticalLogBoxSceneWindow() =>
      railCriticalSceneWindow();

  DashboardLogBoxSceneWindow railCriticalSceneWindow() {
    final active = _activeSceneWindow;
    if (active != null) return active;
    final index = presentation.index;
    if (index == null) {
      return DashboardLogBoxSceneWindow(
        identity:
            'rail-critical:unprepared:${navigation.state.navigationEpoch}',
        payloads: const <DashboardLogViewportState>[],
      );
    }
    // `initialRailOpen` is an explicitly interactive initial state, not a
    // request to reveal the rail while its siblings are still speculative.
    // The first horizontal drag can synchronously select any immediate child,
    // so startup must prime that bounded rail domain before readiness exposes
    // the dashboard. Closed-rail structural publication remains O(1).
    if (navigation.state.isRailOpen) {
      return railInteractionSceneWindowFor(
        navigation.state,
        indexOverride: index,
      );
    }
    return structuralPublicationSceneWindowFor(
      navigation.state,
      indexOverride: index,
    );
  }

  /// Derives the immutable rail-preview universe from the index itself, not
  /// from the currently visible temporal anchor. Each index frame is already
  /// capped to its canonical preview payload; committed vertical pages are not
  /// present here.
  DashboardLogBoxSceneWindow railCriticalSceneWindowForIndex(
    PreparedDashboardIndex index, {
    DashboardNavigationState? state,
  }) {
    final bundle = DashboardPreparedRevisionBundle.forIndex(
      index,
      publicationState: state,
    );
    final coverage = state == null
        ? null
        : _coverageFor(state, indexOverride: index);
    return bundle.railInteractionSceneWindow.withCoverage(coverage);
  }

  /// Exact O(1) first-frame requirement for a structural navigation candidate.
  DashboardLogBoxSceneWindow renderCriticalLogBoxSceneWindowFor(
    DashboardNavigationState state, {
    PreparedDashboardIndex? indexOverride,
    bool includeCurrentVisiblePayload = true,
  }) {
    final index = indexOverride ?? presentation.index ?? preparedIndex;
    if (index == null) {
      return DashboardLogBoxSceneWindow(
        identity: 'rail-critical:unprepared:${state.navigationEpoch}',
        payloads: const <DashboardLogViewportState>[],
      );
    }
    return structuralPublicationSceneWindowFor(state, indexOverride: index);
  }

  DashboardLogBoxSceneWindow structuralPublicationSceneWindowFor(
    DashboardNavigationState state, {
    PreparedDashboardIndex? indexOverride,
  }) {
    final index = indexOverride ?? presentation.index ?? preparedIndex;
    if (index == null) {
      return DashboardLogBoxSceneWindow(
        identity: 'rail-critical:unprepared:${state.navigationEpoch}',
        payloads: const <DashboardLogViewportState>[],
      );
    }
    final bundle = DashboardPreparedRevisionBundle.forIndex(
      index,
      publicationState: state,
    );
    return bundle.structuralPublicationSceneWindow.withCoverage(
      _coverageFor(state, indexOverride: index),
    );
  }

  DashboardLogBoxSceneWindow railInteractionSceneWindowFor(
    DashboardNavigationState state, {
    PreparedDashboardIndex? indexOverride,
  }) {
    final index = indexOverride ?? presentation.index ?? preparedIndex;
    if (index == null) {
      return DashboardLogBoxSceneWindow(
        identity: 'rail-critical:unprepared:${state.navigationEpoch}',
        payloads: const <DashboardLogViewportState>[],
      );
    }
    final bundle = DashboardPreparedRevisionBundle.forIndex(
      index,
      publicationState: state,
    );
    return bundle.railInteractionSceneWindow.withCoverage(
      _coverageFor(state, indexOverride: index),
    );
  }

  DashboardLogBoxSceneCoverageIdentity? _coverageFor(
    DashboardNavigationState state, {
    PreparedDashboardIndex? indexOverride,
  }) {
    final index = indexOverride ?? presentation.index ?? preparedIndex;
    if (index == null) return null;
    final anchor = state.temporalAnchor;
    return DashboardLogBoxSceneCoverageIdentity(
      coreRevision: index.coreRevision,
      indexGeneration: index.generation,
      visibleYear: anchor.visibleYear,
      visibleMonth: anchor.visibleMonth,
      parentQueryKey: state.parentQueryKey.value,
    );
  }

  void _activateSceneWindow(
    DashboardLogBoxSceneWindow window, {
    DashboardLogBoxSceneWindowActivator? activate,
  }) {
    final callback = activate ?? _sceneWindowActivator;
    if (callback == null) {
      throw StateError('No LogBox scene window activator is attached.');
    }
    callback(window);
    _activeSceneWindow = window;
    _activeSceneCoverage = window.coverageIdentity;
    _activeSceneWindowQueryKeys = _sceneWindowQueryKeys(window);
    final index = presentation.index;
    if (index != null) {
      final identity = DashboardRailCriticalSceneBankIdentity.forIndex(index);
      if (window.identity == identity.value) {
        _activeRailCriticalBankIdentity = identity;
      }
    }
    _satisfyRequiredSceneCoverageDemand(window);
    _commitPendingSceneCoveredNavigation();
  }

  /// A scene-bank identity is revision scoped, whereas an Apply-critical bank
  /// deliberately contains only the current structural target and its
  /// immediate rail domain. Keep the actual immutable payload set in the
  /// maintenance identity so a later rail settle can request a missing local
  /// bank without mistaking a same-revision partial bank for the full one.
  Set<String> _sceneWindowQueryKeys(DashboardLogBoxSceneWindow window) =>
      Set<String>.unmodifiable(
        window.payloads.map((payload) => payload.queryKey.value),
      );

  /// Payload identity is canonical, not insertion-order dependent: a single
  /// direction-twin bank must be identical from either selected direction.
  String _sceneWindowPayloadKey(DashboardLogBoxSceneWindow window) {
    final queryKeys = _sceneWindowQueryKeys(window).toList()..sort();
    return '${window.identity}|${queryKeys.join(',')}';
  }

  bool _activeSceneWindowCovers(DashboardLogBoxSceneWindow target) =>
      _activeRailCriticalBankIdentity?.value == target.identity &&
      target.payloads.every(
        (payload) =>
            _activeSceneWindowQueryKeys.contains(payload.queryKey.value),
      );

  /// Starts the larger immediate rail domain only after the first structural
  /// parent is already drawable. The union also carries both tiny adjacent
  /// Summary Pill publication targets, including when the rail is already
  /// open. Those targets are cache-hot first frames, not rail siblings.
  ///
  /// This is background work: motion may defer or cancel it, whereas the
  /// structural publication requirement stays foreground and authoritative.
  void _startRailInteractionWarmup(
    PreparedDashboardIndex index, {
    required DashboardNavigationState state,
  }) {
    final prepare = _sceneWindowPreparer;
    final activate = _sceneWindowActivator;
    final activeBundle = _activePreparedRevisionBundle;
    if (_disposed ||
        prepare == null ||
        activate == null ||
        !identical(activeBundle?.index, index)) {
      return;
    }
    if (_backgroundSceneWarmupInFlight || _backgroundSceneWarmupScheduled) {
      return;
    }
    if (diagnostics.isMotionActive || _verticalInteractionActive) return;
    final bundle = DashboardPreparedRevisionBundle.forIndex(
      index,
      publicationState: state,
    );
    final interaction = bundle.railInteractionSceneWindow.withCoverage(
      _coverageFor(state, indexOverride: index),
    );
    final adjacentPublicationHotset = _adjacentPlanePublicationSceneHotset(
      index,
      state: state,
    );
    final directionalPublicationHotset = _directionalPublicationSceneHotset(
      index,
    );
    // This describes the *current active cache*, not whether the interaction
    // domain happens to contain the next publication hotset by construction.
    // A previous warmup may have prepared their union, so a later invocation
    // must report a hit only when those exact next-plane first frames are
    // genuinely active and therefore require no foreground preparation.
    final adjacentPublicationAlreadyCovered =
        adjacentPublicationHotset == null ||
        _activeSceneWindowCovers(adjacentPublicationHotset);
    var targetWindow = adjacentPublicationHotset == null
        ? interaction
        : interaction.union(
            adjacentPublicationHotset,
            coverageIdentity: interaction.coverageIdentity,
          );
    if (directionalPublicationHotset != null) {
      targetWindow = targetWindow.union(
        directionalPublicationHotset,
        coverageIdentity: interaction.coverageIdentity,
      );
    }
    if (_activeSceneWindowCovers(targetWindow)) {
      if (adjacentPublicationAlreadyCovered) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'NEXT_PLANE_PUBLICATION_WARMUP_HIT',
            queryKey:
                adjacentPublicationHotset?.coverageIdentity?.parentQueryKey,
            coreRevision: index.coreRevision,
          ),
        );
      }
      _startAdjacentSummaryParentHotset(index, state: state);
      return;
    }
    _cancelBackgroundSceneWarmup();
    final generation = ++_backgroundSceneWarmupGeneration;
    _backgroundSceneWarmupScheduled = true;

    void start() {
      if (_disposed || generation != _backgroundSceneWarmupGeneration) return;
      _backgroundSceneWarmupScheduled = false;
      if (_verticalInteractionActive) return;
      // A structural publication is the foreground owner. A previously
      // queued interaction warmup must never race it for the one scene-cache
      // preparation lane. The pending commit schedules the next background
      // expansion after the exact first frame is active.
      if (_sceneRebaseRequested || _sceneRebaseInFlightGeneration != null) {
        return;
      }
      _backgroundSceneWarmupInFlight = true;
      unawaited(
        _runRailInteractionWarmup(
          generation: generation,
          index: index,
          bundle: bundle,
          window: targetWindow,
          nextPublicationWasAlreadyCovered: adjacentPublicationAlreadyCovered,
          prepare: prepare,
          activate: activate,
        ),
      );
    }

    // The render owner schedules this on its next frame. The microtask
    // fallback is only for deterministic controller tests with no widget host.
    final scheduler = _sceneWindowRebaseScheduler;
    if (scheduler != null) {
      scheduler(start);
    } else {
      scheduleMicrotask(start);
    }
  }

  String _summaryParentHotsetKey(DashboardLogBoxSceneWindow window) =>
      'summary-parent:${_sceneWindowPayloadKey(window)}';

  void _startAdjacentSummaryParentHotset(
    PreparedDashboardIndex index, {
    required DashboardNavigationState state,
  }) {
    final prepare = _retainedSceneWindowPreparer;
    if (_disposed ||
        prepare == null ||
        _summaryParentHotsetInFlight ||
        diagnostics.isMotionActive ||
        _verticalInteractionActive ||
        !identical(presentation.index, index)) {
      return;
    }
    final candidates = <DashboardNavigationState>[];
    for (final direction in <DashboardTimeNavigationChangeDirection>[
      DashboardTimeNavigationChangeDirection.backward,
      DashboardTimeNavigationChangeDirection.forward,
    ]) {
      final candidate = presentation.parentCandidate(direction);
      if (candidate != null) candidates.add(candidate);
    }
    if (candidates.isEmpty) return;
    final generation = ++_summaryParentHotsetGeneration;
    _summaryParentHotsetInFlight = true;
    unawaited(() async {
      try {
        for (final candidate in candidates) {
          if (_disposed ||
              generation != _summaryParentHotsetGeneration ||
              diagnostics.isMotionActive ||
              _verticalInteractionActive ||
              !identical(presentation.index, index)) {
            return;
          }
          final window = railInteractionSceneWindowFor(
            candidate,
            indexOverride: index,
          );
          if (_activeSceneWindowCovers(window) ||
              (_retainedSceneWindowLookup?.call(window) ?? false)) {
            continue;
          }
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'SUMMARY_PARENT_HOTSET_PREPARE_STARTED',
              queryKey: candidate.parentQueryKey.value,
              coreRevision: index.coreRevision,
              entryCount: window.previewRowCount,
            ),
          );
          await prepare(
            window,
            retainedKey: _summaryParentHotsetKey(window),
            retainViewportId: visibleFrames.value?.logBox.viewportId,
          );
          if (_disposed ||
              generation != _summaryParentHotsetGeneration ||
              diagnostics.isMotionActive ||
              _verticalInteractionActive ||
              !identical(presentation.index, index)) {
            return;
          }
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'SUMMARY_PARENT_HOTSET_PREPARE_READY',
              queryKey: candidate.parentQueryKey.value,
              coreRevision: index.coreRevision,
              entryCount: window.previewRowCount,
            ),
          );
        }
      } on DashboardLogBoxScenePreparationCancelled {
        // A different immutable target owns the one staging lane now.
      } finally {
        if (generation == _summaryParentHotsetGeneration) {
          _summaryParentHotsetInFlight = false;
        }
      }
    }());
  }

  Future<void> _runRailInteractionWarmup({
    required int generation,
    required PreparedDashboardIndex index,
    required DashboardPreparedRevisionBundle bundle,
    required DashboardLogBoxSceneWindow window,
    required bool nextPublicationWasAlreadyCovered,
    required DashboardLogBoxSceneWindowPreparer prepare,
    required DashboardLogBoxSceneWindowActivator activate,
  }) async {
    final startedAt = Stopwatch()..start();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'RAIL_INTERACTION_WARMUP_STARTED',
        flowId: 'generation:$generation',
        queryKey: window.identity,
        coreRevision: index.coreRevision,
        entryCount: window.previewRowCount,
      ),
    );
    try {
      await prepare(
        window,
        retainViewportId: visibleFrames.value?.logBox.viewportId,
      );
      if (_disposed ||
          generation != _backgroundSceneWarmupGeneration ||
          _verticalInteractionActive ||
          !identical(presentation.index, index)) {
        return;
      }
      _activateSceneWindow(window, activate: activate);
      _activePreparedRevisionBundle = bundle;
      _activeRailCriticalBankIdentity = bundle.railCriticalSceneBankIdentity;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'RAIL_INTERACTION_WARMUP_COMPLETED',
          flowId: 'generation:$generation',
          queryKey: window.identity,
          coreRevision: index.coreRevision,
          entryCount: window.previewRowCount,
          durationMs: startedAt.elapsedMilliseconds,
        ),
      );
      if (!nextPublicationWasAlreadyCovered) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'NEXT_PLANE_PUBLICATION_WARMUP_READY',
            flowId: 'generation:$generation',
            queryKey: window.identity,
            coreRevision: index.coreRevision,
          ),
        );
      }
      _startAdjacentSummaryParentHotset(index, state: navigation.state);
    } on DashboardLogBoxScenePreparationCancelled {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'RAIL_INTERACTION_WARMUP_CANCELLED',
          flowId: 'generation:$generation',
          queryKey: window.identity,
          coreRevision: index.coreRevision,
        ),
      );
    } on Object catch (error) {
      _lastSceneWindowError = '$error';
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'ERROR',
          message: 'RAIL_INTERACTION_WARMUP_FAILED',
          flowId: 'generation:$generation',
          queryKey: window.identity,
          coreRevision: index.coreRevision,
          error: '$error',
        ),
      );
    } finally {
      if (generation == _backgroundSceneWarmupGeneration) {
        _backgroundSceneWarmupInFlight = false;
      }
    }
  }

  DashboardLogBoxSceneWindow? _adjacentPlanePublicationSceneHotset(
    PreparedDashboardIndex index, {
    required DashboardNavigationState state,
  }) {
    if (!identical(presentation.index, index)) return null;
    DashboardLogBoxSceneWindow? hotset;
    for (final finer in <bool>[true, false]) {
      final candidate = presentation.planeCandidate(finer: finer);
      final publication = structuralPublicationSceneWindowFor(
        candidate,
        indexOverride: index,
      );
      hotset = hotset == null
          ? publication
          : hotset.union(
              publication,
              coverageIdentity: hotset.coverageIdentity,
            );
    }
    return hotset;
  }

  /// The active immutable index contains both independent direction
  /// universes.  Once the dashboard is idle, keep the exact reconciled
  /// first-frame target for each direction in the existing background scene
  /// warmup so the normal income/expense selection stays RAM/cache-only even
  /// when their temporal availability differs.
  DashboardLogBoxSceneWindow? _directionalPublicationSceneHotset(
    PreparedDashboardIndex index,
  ) {
    DashboardLogBoxSceneWindow? hotset;
    for (final direction in LedgerDirection.values) {
      final template = currentQuery.scopeFor(direction);
      final availability = DashboardTemporalAvailability.fromTemporalFilter(
        template.temporalFilter,
      );
      final candidate = navigation.appliedQueryCandidate(
        template,
        availability: availability,
        coreRevision: index.coreRevision,
      );
      final publication = structuralPublicationSceneWindowFor(
        candidate,
        indexOverride: index,
      );
      hotset = hotset == null
          ? publication
          : hotset.union(
              publication,
              coverageIdentity: hotset.coverageIdentity,
            );
    }
    return hotset;
  }

  /// Returns whether this call invalidated a live background warmup. The
  /// caller then knows not to invoke the same one-owner cache cancellation a
  /// second time for the same supersession event.
  bool _cancelBackgroundSceneWarmup() {
    final hadWarmup =
        _backgroundSceneWarmupInFlight || _backgroundSceneWarmupScheduled;
    if (!hadWarmup) return false;
    _backgroundSceneWarmupGeneration += 1;
    _backgroundSceneWarmupScheduled = false;
    _backgroundSceneWarmupInFlight = false;
    if (hadWarmup) _sceneWindowPreparationCanceller?.call();
    return hadWarmup;
  }

  void _requestPostSettleSceneRebase({
    required LedgerQueryKey settledQueryKey,
  }) {
    unawaited(
      _reconcileSceneCoverageAfterNavigation(
        reason: 'railSettledTemporalAnchorChanged',
        settledQueryKey: settledQueryKey,
      ),
    );
  }

  _RequiredSceneCoverageDemand _recordRequiredSceneCoverageDemand({
    required DashboardLogBoxSceneWindow window,
    required String payloadKey,
    required String reason,
    required LedgerQueryKey settledQueryKey,
    required _SceneCoverageDemandKind kind,
    DateTime? requestedAt,
  }) {
    final existing = _requiredSceneCoverageDemand;
    if (existing != null && existing.payloadKey == payloadKey) {
      return existing;
    }
    final demand = _RequiredSceneCoverageDemand(
      generation: ++_requiredSceneCoverageGeneration,
      requestedAt: requestedAt ?? DateTime.now(),
      window: window,
      payloadKey: payloadKey,
      reason: reason,
      settledQueryKey: settledQueryKey,
      kind: kind,
    );
    _requiredSceneCoverageDemand = demand;
    _desiredSceneCoverage = demand.coverage;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: existing == null
            ? 'SCENE_COVERAGE_DEMAND_CREATED'
            : 'SCENE_COVERAGE_SUPERSEDED',
        message:
            'reason=$reason target=${demand.coverage.value} '
            'generation=${demand.generation}',
        queryKey: settledQueryKey.value,
        coreRevision: demand.coverage.coreRevision,
        entryCount: window.previewRowCount,
      ),
    );
    return demand;
  }

  void _invalidateSceneCoverageOwnedByReplacedIndex(
    PreparedDashboardIndex nextIndex,
  ) {
    final pending = _pendingSceneCoveredNavigation;
    final demand = _requiredSceneCoverageDemand;
    final invalidatesPending =
        pending != null && !_windowUsesPreparedIndex(pending.window, nextIndex);
    final invalidatesDemand =
        demand != null && !_windowUsesPreparedIndex(demand.window, nextIndex);
    if (!invalidatesPending && !invalidatesDemand) return;

    final oldCoverage = demand?.coverage ?? pending?.window.coverageIdentity;
    if (invalidatesPending) {
      _pendingSceneCoveredNavigation = null;
      _completePendingSceneCoveredNavigation(pending);
    }
    if (invalidatesDemand) {
      _requiredSceneCoverageDemand = null;
    }
    if (_desiredSceneCoverage != null &&
        (_desiredSceneCoverage!.coreRevision != nextIndex.coreRevision ||
            _desiredSceneCoverage!.indexGeneration != nextIndex.generation)) {
      _desiredSceneCoverage = null;
    }

    _sceneRebaseGeneration += 1;
    _sceneRebaseRequested = false;
    _sceneRebaseDemandGeneration = null;
    for (final completion in _sceneRebaseCompletions.values) {
      if (!completion.isCompleted) completion.complete();
    }
    _sceneRebaseCompletions.clear();
    if (_sceneRebaseInFlightGeneration != null) {
      _sceneWindowPreparationCanceller?.call();
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_NAVIGATION_TRANSITION_INVALIDATED_BY_INDEX',
        message:
            'oldTarget=${oldCoverage?.value ?? 'unprepared'} '
            'newIndex=rev:${nextIndex.coreRevision}|index:${nextIndex.generation}',
        coreRevision: nextIndex.coreRevision,
      ),
    );
  }

  bool _sameImmutableIndex(
    DashboardLogBoxSceneCoverageIdentity first,
    DashboardLogBoxSceneCoverageIdentity second,
  ) =>
      first.coreRevision == second.coreRevision &&
      first.indexGeneration == second.indexGeneration;

  bool _windowUsesPreparedIndex(
    DashboardLogBoxSceneWindow window,
    PreparedDashboardIndex index,
  ) {
    final coverage = window.coverageIdentity;
    return coverage != null &&
        coverage.coreRevision == index.coreRevision &&
        coverage.indexGeneration == index.generation;
  }

  bool _pendingStructuralNavigationIsAuthoritative() {
    final pending = _pendingSceneCoveredNavigation;
    final demand = _requiredSceneCoverageDemand;
    if (pending == null || demand == null) return false;
    return pending.payloadKey == demand.payloadKey &&
        demand.kind == _SceneCoverageDemandKind.pendingNavigation &&
        _sameImmutableIndex(pending.window.coverageIdentity!, demand.coverage);
  }

  void _completePendingSceneCoveredNavigation(
    _PendingSceneCoveredNavigation pending,
  ) {
    if (!pending.completion.isCompleted) pending.completion.complete();
  }

  void _supersedePendingSceneCoveredNavigation({
    required String reason,
    required String nextPayloadKey,
  }) {
    final pending = _pendingSceneCoveredNavigation;
    if (pending == null || pending.payloadKey == nextPayloadKey) return;
    _pendingSceneCoveredNavigation = null;
    _completePendingSceneCoveredNavigation(pending);
    final coverage = pending.window.coverageIdentity;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_NAVIGATION_TRANSITION_SUPERSEDED',
        message:
            'oldGeneration=${pending.generation} reason=$reason '
            'oldTarget=${coverage?.value ?? 'unprepared'}',
        queryKey: pending.window.payloads.isEmpty
            ? null
            : pending.window.payloads.first.queryKey.value,
        coreRevision: coverage?.coreRevision,
        entryCount: pending.window.previewRowCount,
      ),
    );
    if (coverage != null) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_PREPARATION_SUPERSEDED',
          message:
              'oldGeneration=${pending.generation} reason=$reason '
              'oldTarget=${coverage.value}',
          queryKey: pending.window.payloads.isEmpty
              ? null
              : pending.window.payloads.first.queryKey.value,
          coreRevision: coverage.coreRevision,
          entryCount: pending.window.previewRowCount,
        ),
      );
    }
  }

  void _satisfyRequiredSceneCoverageDemand(DashboardLogBoxSceneWindow window) {
    final demand = _requiredSceneCoverageDemand;
    if (demand == null || !_activeSceneWindowCovers(demand.window)) return;
    _requiredSceneCoverageDemand = null;
    _desiredSceneCoverage = demand.coverage;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_COVERAGE_SATISFIED',
        message:
            'target=${demand.coverage.value} generation=${demand.generation}',
        queryKey: demand.settledQueryKey.value,
        coreRevision: demand.coverage.coreRevision,
        entryCount: window.previewRowCount,
      ),
    );
  }

  /// Commits one discrete structural candidate only after its exact canonical
  /// scene window is active. Rail motion continues to use the already-active
  /// immediate domain; this boundary is for direction, plane and parent
  /// changes that would otherwise publish a fail-closed blank LogBox.
  Future<void> _commitNavigationWithSceneCoverage({
    required DashboardNavigationState candidate,
    required String reason,
    required LedgerQueryKey settledQueryKey,
    _DashboardNavigationSceneRequirement requirement =
        _DashboardNavigationSceneRequirement.structuralPublication,
    DashboardLogBoxSceneWindow? requiredSceneWindow,
    _SceneCoveredNavigationOwner owner =
        _SceneCoveredNavigationOwner.structural,
    required VoidCallback commit,
  }) {
    if (_disposed) return Future<void>.value();
    // Derive the exact publication/interaction requirement before the
    // coordinator-only fast path. Controller-only consumers intentionally
    // commit synchronously, but a compact deterministic zero scope must still
    // be materialized at this structural boundary; a later semantic crossing
    // must remain a strict allocation-free lookup.
    final targetWindow =
        requiredSceneWindow ??
        switch (requirement) {
          _DashboardNavigationSceneRequirement.structuralPublication =>
            renderCriticalLogBoxSceneWindowFor(candidate),
          _DashboardNavigationSceneRequirement.railInteraction =>
            railInteractionSceneWindowFor(candidate),
        };
    // Controller-only consumers have no render owner and therefore no scene
    // lifecycle to guard. Preserve the established synchronous RAM-only
    // navigation contract for that boundary; production attaches the sole
    // coordinator before a dashboard becomes interactive.
    if (_sceneWindowPreparer == null || _sceneWindowActivator == null) {
      _pendingSceneCoveredNavigation = null;
      commit();
      return Future<void>.value();
    }
    final targetCoverage = targetWindow.coverageIdentity;
    if (targetCoverage == null) {
      commit();
      return Future<void>.value();
    }
    final acceptedAt = DateTime.now();
    final payloadKey = _sceneWindowPayloadKey(targetWindow);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_NAVIGATION_INPUT_ACCEPTED',
        message:
            'reason=$reason target=${targetCoverage.value} '
            'publicationCriticalScenes=${targetWindow.sceneCount} '
            'publicationCriticalRows=${targetWindow.previewRowCount}',
        queryKey: settledQueryKey.value,
        coreRevision: targetCoverage.coreRevision,
        entryCount: targetWindow.previewRowCount,
      ),
    );
    final existingPending = _pendingSceneCoveredNavigation;
    if (existingPending != null && existingPending.payloadKey == payloadKey) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_NAVIGATION_TRANSITION_COALESCED',
          message:
              'reason=$reason generation=${existingPending.generation} '
              'target=${targetCoverage.value}',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      return existingPending.future;
    }
    _supersedePendingSceneCoveredNavigation(
      reason: reason,
      nextPayloadKey: payloadKey,
    );
    if (_activeSceneWindowCovers(targetWindow)) {
      final existingDemand = _requiredSceneCoverageDemand;
      if (existingDemand != null && existingDemand.payloadKey != payloadKey) {
        _recordRequiredSceneCoverageDemand(
          window: targetWindow,
          payloadKey: payloadKey,
          reason: reason,
          settledQueryKey: settledQueryKey,
          kind: _SceneCoverageDemandKind.pendingNavigation,
        );
      }
      _activeSceneCoverage = targetCoverage;
      _desiredSceneCoverage = targetCoverage;
      _satisfyRequiredSceneCoverageDemand(targetWindow);
      commit();
      _startRailInteractionWarmup(
        presentation.index ?? preparedIndex!,
        state: navigation.state,
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_NAVIGATION_TRANSITION_COMMITTED',
          message:
              'reason=$reason cacheHit=true '
              'inputToCommitMs=${DateTime.now().difference(acceptedAt).inMilliseconds}',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      return Future<void>.value();
    }

    final demand = _recordRequiredSceneCoverageDemand(
      window: targetWindow,
      payloadKey: payloadKey,
      reason: reason,
      settledQueryKey: settledQueryKey,
      kind: _SceneCoverageDemandKind.pendingNavigation,
      requestedAt: acceptedAt,
    );
    _pendingSceneCoveredNavigation = _PendingSceneCoveredNavigation(
      generation: ++_pendingSceneCoveredNavigationGeneration,
      acceptedAt: demand.requestedAt,
      payloadKey: payloadKey,
      window: targetWindow,
      reason: reason,
      owner: owner,
      commit: commit,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_NAVIGATION_TRANSITION_REQUESTED',
        message:
            'reason=$reason target=${targetCoverage.value} '
            'requiredUniqueScenes=${targetWindow.sceneCount} '
            'activeCovered=false',
        queryKey: settledQueryKey.value,
        coreRevision: targetCoverage.coreRevision,
        entryCount: targetWindow.previewRowCount,
      ),
    );
    // Structural preparation yields in bounded cache slices, so it is safe to
    // overlap Summary Pill animation. Only the larger interaction warmup stays
    // motion-deferred.
    return _requestSceneWindowMaintenance(
      demand: demand,
      foregroundStructuralPublication: true,
    );
  }

  void _commitPendingSceneCoveredNavigation() {
    final pending = _pendingSceneCoveredNavigation;
    if (pending == null || !_activeSceneWindowCovers(pending.window)) {
      return;
    }
    _pendingSceneCoveredNavigation = null;
    pending.commit();
    _completePendingSceneCoveredNavigation(pending);
    final railVisibilityScheduled = _reconcilePendingRailVisibilityIntent();
    final index = presentation.index ?? preparedIndex;
    if (!railVisibilityScheduled && index != null) {
      _startRailInteractionWarmup(index, state: navigation.state);
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_NAVIGATION_TRANSITION_COMMITTED',
        message:
            'generation=${pending.generation} '
            'inputToCommitMs=${DateTime.now().difference(pending.acceptedAt).inMilliseconds}',
        queryKey: presentation.expectedVisibleQueryKey?.value,
        coreRevision: preparedIndex?.coreRevision,
      ),
    );
  }

  /// Reconciles the exact renderable LogBox payload set after a committed
  /// navigation change. A minimal Query-publication bank is intentionally not
  /// a complete index bank, so navigation state alone is never proof that the
  /// next visible payload is paintable. This is the sole post-navigation
  /// transition through which demand rebases enter the existing coordinator.
  Future<void> _reconcileSceneCoverageAfterNavigation({
    required String reason,
    LedgerQueryKey? settledQueryKey,
  }) {
    if (_disposed) return Future<void>.value();
    if (_pendingStructuralNavigationIsAuthoritative()) {
      final pending = _pendingSceneCoveredNavigation!;
      final targetCoverage = pending.window.coverageIdentity!;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_MAINTENANCE_DEFERRED_FOR_PENDING_NAVIGATION',
          message:
              'reason=$reason pendingGeneration=${pending.generation} '
              'target=${targetCoverage.value}',
          queryKey: settledQueryKey?.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: pending.window.previewRowCount,
        ),
      );
      return Future<void>.value();
    }
    // Committed maintenance owns the larger immediate rail requirement. It
    // must never broaden the structural foreground publication barrier.
    final targetWindow = railInteractionSceneWindowFor(navigation.state);
    final targetCoverage = targetWindow.coverageIdentity;
    final targetPayloadKey = _sceneWindowPayloadKey(targetWindow);
    final targetQueryKey =
        settledQueryKey ??
        presentation.expectedVisibleQueryKey ??
        navigation.state.parentQueryKey;
    if (targetCoverage == null) return Future<void>.value();
    // A newer committed navigation target supersedes an older missing target
    // even when the new target is already active. Otherwise a cancelled B
    // demand could survive after C committed as a cache hit and later revive.
    final existingDemand = _requiredSceneCoverageDemand;
    if (existingDemand != null &&
        existingDemand.payloadKey != targetPayloadKey) {
      _recordRequiredSceneCoverageDemand(
        window: targetWindow,
        payloadKey: targetPayloadKey,
        reason: reason,
        settledQueryKey: targetQueryKey,
        kind: _SceneCoverageDemandKind.committedMaintenance,
      );
    }
    if (_activeSceneWindowCovers(targetWindow)) {
      _activeSceneCoverage = targetCoverage;
      _desiredSceneCoverage = targetCoverage;
      _satisfyRequiredSceneCoverageDemand(targetWindow);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_COVERAGE_HIT',
          message: 'reason=$reason target=${targetCoverage.value}',
          queryKey: targetQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      return Future<void>.value();
    }
    final demand =
        _requiredSceneCoverageDemand ??
        _recordRequiredSceneCoverageDemand(
          window: targetWindow,
          payloadKey: targetPayloadKey,
          reason: reason,
          settledQueryKey: targetQueryKey,
          kind: _SceneCoverageDemandKind.committedMaintenance,
        );
    // Motion owns the hot path, but it never gets to discard a renderability
    // demand. Keep exactly the newest target and let the existing rebase
    // coordinator consume it as soon as every motion lane is idle.
    if (diagnostics.isMotionActive) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_COVERAGE_DEFERRED',
          message:
              'reason=$reason target=${targetCoverage.value} '
              'generation=${demand.generation}',
          queryKey: targetQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      return Future<void>.value();
    }
    return _requestSceneWindowMaintenance(demand: demand);
  }

  /// Schedules a structural scene cache rotation strictly after metadata has
  /// committed. A newer target invalidates any older work; its completion is
  /// deliberately not part of navigation or input readiness.
  Future<void> _requestSceneWindowMaintenance({
    required _RequiredSceneCoverageDemand demand,
    bool foregroundStructuralPublication = false,
  }) {
    if (_disposed) return Future<void>.value();
    if (_verticalInteractionActive && !foregroundStructuralPublication) {
      return Future<void>.value();
    }
    if (_requiredSceneCoverageDemand?.generation != demand.generation) {
      return Future<void>.value();
    }
    if (_sceneRebaseDemandGeneration == demand.generation &&
        (_sceneRebaseRequested || _sceneRebaseInFlightGeneration != null)) {
      final activeRequest =
          _sceneRebaseInFlightGeneration ?? _sceneRebaseGeneration;
      return _sceneRebaseCompletions[activeRequest]?.future ??
          Future<void>.value();
    }
    _cancelBackgroundSceneWarmup();
    _sceneRebaseGeneration += 1;
    final requestGeneration = _sceneRebaseGeneration;
    for (final entry in _sceneRebaseCompletions.entries.toList()) {
      if (entry.key < requestGeneration && !entry.value.isCompleted) {
        entry.value.complete();
        _sceneRebaseCompletions.remove(entry.key);
      }
    }
    final completion = Completer<void>();
    _sceneRebaseCompletions[requestGeneration] = completion;
    _sceneRebaseRequested = true;
    _sceneRebaseDemandGeneration = demand.generation;
    _sceneWindowPreparing.value = true;
    if (_sceneRebaseInFlightGeneration != null) {
      _sceneWindowPreparationCanceller?.call();
    }
    if (foregroundStructuralPublication) {
      // `prepareWindow` yields before its first paragraph in production. Start
      // this tiny foreground requirement now instead of serializing it behind
      // Summary Pill animation lanes.
      unawaited(_drainSceneRebase());
    } else {
      _scheduleSceneRebaseDrain();
    }
    return completion.future;
  }

  void _scheduleSceneRebaseDrain() {
    if (_disposed ||
        !_sceneRebaseRequested ||
        _sceneRebaseDrainScheduled ||
        _sceneRebaseInFlightGeneration != null) {
      return;
    }
    _sceneRebaseDrainScheduled = true;
    void drain() {
      _sceneRebaseDrainScheduled = false;
      unawaited(_drainSceneRebase());
    }

    // The render owner puts maintenance on the next frame, after the settled
    // event but before its own post-frame cache slice. Pure controller tests
    // retain a deterministic microtask fallback without introducing timers.
    final scheduler = _sceneWindowRebaseScheduler;
    if (scheduler != null) {
      scheduler(drain);
    } else {
      scheduleMicrotask(drain);
    }
  }

  /// Cancels active preparation for input responsiveness without discarding
  /// the latest required renderability target. The next idle boundary retries
  /// that target unless a newer navigation target supersedes it first.
  void _cancelSceneWindowMaintenanceForInput() {
    // Required coverage runs in explicitly bounded UI slices. A pointer may
    // cancel speculative warming, but it must not repeatedly destroy the same
    // still-required scene build and force the user to leave the screen idle
    // for a full fresh preparation.
    final requiredDemand = _requiredSceneCoverageDemand;
    final requiredRebaseInFlight =
        requiredDemand != null && _sceneRebaseInFlightGeneration != null;
    final pendingRequiredRebase =
        requiredDemand != null &&
        _sceneRebaseRequested &&
        _sceneRebaseDemandGeneration == requiredDemand.generation;
    if (requiredRebaseInFlight || pendingRequiredRebase) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_PREPARATION_RESUMED',
          message:
              'inputRetainsRequiredTarget=${requiredDemand.coverage.value} '
              'generation=${requiredDemand.generation}',
          queryKey: requiredDemand.settledQueryKey.value,
          coreRevision: requiredDemand.coverage.coreRevision,
          entryCount: requiredDemand.window.previewRowCount,
        ),
      );
      return;
    }
    final cancelledSpeculation = _cancelBackgroundSceneWarmup();
    if (!cancelledSpeculation) _sceneWindowPreparationCanceller?.call();
    if (!_sceneRebaseRequested && _sceneRebaseInFlightGeneration == null) {
      return;
    }
    final demand = _requiredSceneCoverageDemand;
    _sceneRebaseGeneration += 1;
    _sceneRebaseRequested = false;
    _sceneRebaseDemandGeneration = null;
    for (final completion in _sceneRebaseCompletions.values) {
      if (!completion.isCompleted) completion.complete();
    }
    _sceneRebaseCompletions.clear();
    _sceneWindowPreparing.value = _sceneRebaseInFlightGeneration != null;
    if (demand != null) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_COVERAGE_PREPARATION_CANCELLED',
          message:
              'target=${demand.coverage.value} generation=${demand.generation} '
              'demandRetained=true',
          queryKey: demand.settledQueryKey.value,
          coreRevision: demand.coverage.coreRevision,
          entryCount: demand.window.previewRowCount,
        ),
      );
    }
  }

  Future<void> _drainSceneRebase() async {
    if (_disposed ||
        !_sceneRebaseRequested ||
        _sceneRebaseInFlightGeneration != null) {
      return;
    }
    final prepare = _sceneWindowPreparer;
    final activate = _sceneWindowActivator;
    if (prepare == null || activate == null) {
      _sceneRebaseRequested = false;
      _completeSceneRebase(_sceneRebaseGeneration);
      _finishSceneWindowPreparation();
      return;
    }

    final requestGeneration = _sceneRebaseGeneration;
    final demand = _requiredSceneCoverageDemand;
    if (demand == null || _sceneRebaseDemandGeneration != demand.generation) {
      _sceneRebaseRequested = false;
      _completeSceneRebase(requestGeneration);
      _finishSceneWindowPreparation();
      return;
    }
    final reason = demand.reason;
    final settledQueryKey = demand.settledQueryKey;
    final targetWindow = demand.window;
    final targetCoverage = demand.coverage;
    _desiredSceneCoverage = targetCoverage;
    if (_activeSceneWindowCovers(targetWindow)) {
      _sceneRebaseRequested = false;
      _activeSceneCoverage = targetCoverage;
      _desiredSceneCoverage = targetCoverage;
      _satisfyRequiredSceneCoverageDemand(targetWindow);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_REBASE_SKIPPED',
          message:
              'reason=railCriticalBankCurrent target=${targetWindow.identity}',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      _completeSceneRebase(requestGeneration);
      _finishSceneWindowPreparation();
      return;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_WINDOW_REBASE_REQUESTED',
        message:
            'reason=$reason from=${_activeSceneCoverage?.value ?? 'none'} '
            'target=${targetCoverage.value} generation=$requestGeneration '
            'visibleYear=${targetCoverage.visibleYear} '
            'visibleYearMonth=${targetCoverage.visibleYear}-${targetCoverage.visibleMonth.toString().padLeft(2, '0')}',
        queryKey: settledQueryKey.value,
        coreRevision: targetCoverage.coreRevision,
        entryCount: targetWindow.previewRowCount,
      ),
    );
    _sceneRebaseRequested = false;
    _sceneWindowPreparing.value = true;
    _sceneRebaseInFlightGeneration = requestGeneration;
    _lastSceneWindowError = null;
    final startedAt = DateTime.now();
    if (demand.kind == _SceneCoverageDemandKind.pendingNavigation) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'STRUCTURAL_PUBLICATION_PREPARE_STARTED',
          message:
              'reason=$reason publicationCriticalScenes=${targetWindow.sceneCount} '
              'publicationCriticalRows=${targetWindow.previewRowCount}',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_WINDOW_REBASE_STARTED',
        message:
            'reason=$reason target=${targetCoverage.value} '
            'generation=$requestGeneration requiredScenes=${targetWindow.sceneCount}',
        queryKey: settledQueryKey.value,
        coreRevision: targetCoverage.coreRevision,
        entryCount: targetWindow.previewRowCount,
      ),
    );
    try {
      await prepare(
        targetWindow,
        retainViewportId: visibleFrames.value?.logBox.viewportId,
      );
      if (_disposed) return;
      final queuedIndex = _queuedPreparedIndex;
      final currentIndex = presentation.index ?? preparedIndex;
      final stale =
          requestGeneration != _sceneRebaseGeneration ||
          _requiredSceneCoverageDemand?.generation != demand.generation ||
          currentIndex == null ||
          !_windowUsesPreparedIndex(targetWindow, currentIndex) ||
          (queuedIndex != null &&
              queuedIndex.coreRevision >= targetCoverage.coreRevision);
      if (stale) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'SCENE_WINDOW_REBASE_STALE',
            message:
                'target=${targetCoverage.value} '
                'demandGeneration=${demand.generation} '
                'generation=$requestGeneration',
            queryKey: settledQueryKey.value,
            coreRevision: targetCoverage.coreRevision,
            entryCount: targetWindow.previewRowCount,
          ),
        );
        _completeSceneRebase(requestGeneration);
        return;
      }
      _activateSceneWindow(targetWindow, activate: activate);
      _activeSceneCoverage = targetCoverage;
      _desiredSceneCoverage = targetCoverage;
      _satisfyRequiredSceneCoverageDemand(targetWindow);
      _lastSceneRebaseDuration = DateTime.now().difference(startedAt);
      _lastSceneRebaseReason = reason;
      _lastSceneRebaseRequiredScenes = targetWindow.sceneCount;
      _lastSceneRebaseRequiredRows = targetWindow.previewRowCount;
      if (demand.kind == _SceneCoverageDemandKind.pendingNavigation) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'STRUCTURAL_PUBLICATION_PREPARE_READY',
            message:
                'publicationCriticalScenes=${targetWindow.sceneCount} '
                'publicationCriticalRows=${targetWindow.previewRowCount}',
            queryKey: settledQueryKey.value,
            coreRevision: targetCoverage.coreRevision,
            entryCount: targetWindow.previewRowCount,
            durationMs: _lastSceneRebaseDuration!.inMilliseconds,
          ),
        );
      }
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_REBASE_COMPLETED',
          message:
              'reason=$reason target=${targetCoverage.value} '
              'generation=$requestGeneration requiredScenes=${targetWindow.sceneCount}',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
          durationMs: _lastSceneRebaseDuration!.inMilliseconds,
        ),
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_REBASE_ACTIVATED',
          message:
              'target=${targetCoverage.value} generation=$requestGeneration',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
          durationMs: _lastSceneRebaseDuration!.inMilliseconds,
        ),
      );
      _completeSceneRebase(requestGeneration);
    } on DashboardLogBoxScenePreparationCancelled {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_REBASE_CANCELLED',
          message: 'generation=$requestGeneration reason=$reason',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      _completeSceneRebase(requestGeneration);
    } on Object catch (error) {
      _lastSceneWindowError = '$error';
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'ERROR',
          message: 'SCENE_WINDOW_REBASE_FAILED reason=$reason',
          queryKey: settledQueryKey.value,
          coreRevision: targetCoverage.coreRevision,
          entryCount: targetWindow.previewRowCount,
          error: '$error',
        ),
      );
      _completeSceneRebase(requestGeneration);
    } finally {
      _sceneRebaseInFlightGeneration = null;
      _finishSceneWindowPreparation();
    }
  }

  void _completeSceneRebase(int generation) {
    final completion = _sceneRebaseCompletions.remove(generation);
    if (completion != null && !completion.isCompleted) completion.complete();
  }

  Map<String, Object?> _sceneWindowReport() {
    final cache =
        _sceneWindowReporter?.call() ??
        <String, Object?>{
          'state': 'unattached',
          'preparedScenes': 0,
          'preparedTextRows': _logBoxTextLayoutPreparedRows,
          'sceneCacheBytes': _logBoxTextLayoutEstimatedBytes,
          'textLayoutMisses': 0,
          'readySceneIncomplete': 0,
          'activeWindowPartialPublish': 0,
          'stagingObjectRendered': 0,
          'railCriticalLookupHit': 0,
          'railCriticalLookupMiss': 0,
          'visiblePayloadWithoutDrawable': 0,
          'visiblePayloadWithoutPaint': 0,
        };
    return <String, Object?>{
      ...cache,
      'railCanonicalCenterMismatch':
          presentation.railCanonicalCenterMismatchCount,
      'freshVerticalGestureRejected': performanceCounters.value(
        DashboardPerformanceMetric.freshVerticalGestureRejected,
      ),
      'activeCoverageIdentity': _activeSceneCoverage?.value,
      'activeRailCriticalBankIdentity': _activeRailCriticalBankIdentity?.value,
      'desiredCoverageIdentity': _desiredSceneCoverage?.value,
      'rebaseInFlight': _sceneRebaseInFlightGeneration != null,
      'backgroundWarmupInFlight': _backgroundSceneWarmupInFlight,
      'rebaseGeneration': _sceneRebaseGeneration,
      'queuedRebase': _sceneRebaseRequested || _sceneRebaseDrainScheduled,
      'lastRebaseDurationMs': _lastSceneRebaseDuration?.inMilliseconds ?? 0,
      'lastRebaseReason': _lastSceneRebaseReason,
      'lastRebaseRequiredScenes': _lastSceneRebaseRequiredScenes,
      'lastRebaseRequiredRows': _lastSceneRebaseRequiredRows,
      'criticalCacheMisses':
          renderReadinessDiagnostics.railCriticalCacheMissCount,
    };
  }

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
    if (!anyActive) {
      // A rail/summary lane may have temporarily preempted a still-current
      // committed vertical target. The paging owner retains that target and
      // resumes its sequential cursor drain here, without a second gesture.
      paging.resumeDeferredForwardDemand();
      _drainRequiredSceneCoverageDemand();
      if (_requiredSceneCoverageDemand == null) {
        final index = presentation.index ?? preparedIndex;
        if (index != null) {
          _startRailInteractionWarmup(index, state: navigation.state);
        }
      }
      if (_queryChipPrewarmRequested) _startQueryChipPrewarm();
    }
  }

  void _drainRequiredSceneCoverageDemand() {
    if (_disposed || diagnostics.isMotionActive) return;
    final demand = _requiredSceneCoverageDemand;
    if (demand == null) return;
    if (_activeSceneWindowCovers(demand.window)) {
      _activeSceneCoverage = demand.coverage;
      _satisfyRequiredSceneCoverageDemand(demand.window);
      return;
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_COVERAGE_RETRY_SCHEDULED',
        message:
            'target=${demand.coverage.value} generation=${demand.generation}',
        queryKey: demand.settledQueryKey.value,
        coreRevision: demand.coverage.coreRevision,
        entryCount: demand.window.previewRowCount,
      ),
    );
    unawaited(_requestSceneWindowMaintenance(demand: demand));
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
    // The presentation controller has already committed the temporal anchor.
    // Only queue a later coordinator drain here: text/layout preparation must
    // never execute on the rail settle callback stack.
    _requestPostSettleSceneRebase(settledQueryKey: entry.queryKey);
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

  DashboardRailFlightContext _railFlightContext() {
    final motionState = presentation.motion.state;
    final navigationState = presentation.navigation.state;
    final visible = presentation.visibleFrames.value;
    final queryKey = visible?.queryKey ?? navigationState.parentQueryKey;
    final prepared = visible?.preparedFrame;
    final installed = preparedIndex;
    return DashboardRailFlightContext(
      motionEpoch: motionState.motionEpoch,
      navigationEpoch:
          visible?.navigationEpoch ?? navigationState.navigationEpoch,
      presentationEpoch: visible?.presentationEpoch ?? 0,
      queryKey: queryKey,
      parentQueryKey: visible?.parentQueryKey ?? navigationState.parentQueryKey,
      direction:
          visible?.direction ?? navigationState.parentQueryScope.direction,
      childKind: presentation.motion.catalog.childKind,
      plane: visible?.plane ?? navigationState.plane,
      semanticIndex: visible?.semanticChildIndex ?? motionState.semanticIndex,
      coreRevision: visible?.coreRevision ?? installed?.coreRevision ?? 0,
      presentationGeneration: visible?.frameGeneration ?? 0,
      presentationMode: visible?.mode ?? DashboardVisibleMode.committed,
      dataOrigin: installed == null
          ? DashboardDataOrigin.preparedIndex
          : installed.originFor(queryKey),
      hasData: (prepared?.entryCount ?? 0) > 0,
      entryCount: prepared?.entryCount ?? 0,
      preparedPreviewRowCount: prepared?.stableRowIdentities.length ?? 0,
      frameDigest: visible?.visualDigest ?? 0,
      displayFrameNumber: presentation.frameCoalescer.currentFrameNumber,
      motionState: motionState.activity,
    );
  }

  void dispose() {
    if (_disposed) return;
    _cancelActiveComposerApply(reason: 'disposed');
    _cancelBackgroundSceneWarmup();
    _disposed = true;
    for (final completion in _sceneRebaseCompletions.values) {
      if (!completion.isCompleted) completion.complete();
    }
    _sceneRebaseCompletions.clear();
    _sceneWindowPreparing.dispose();
    detachLogBoxSceneWindowCoordinator();
    _activeMotionLanes.clear();
    railFlightRecorder?.dispose();
    visibleFrames.removeListener(_onVisibleFramePublished);
    queryComposer.removeListener(_onQueryComposerChanged);
    dataRuntime.dispose();
    paging.dispose();
    committedLogViewport.dispose();
    queryComposer.dispose();
    currentQuery.dispose();
    presentation.dispose();
    transactionDirection.dispose();
    expansion.dispose();
  }
}
