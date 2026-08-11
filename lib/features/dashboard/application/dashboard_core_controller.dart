import 'dart:async';

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
import 'dashboard_interaction_diagnostics.dart';
import 'dashboard_performance_counters.dart';
import 'dashboard_rail_flight_recorder.dart';
import 'dashboard_render_readiness_diagnostics.dart';
import 'transaction_direction_controller.dart';

enum DashboardMotionLane { rail, visualHost, summaryShell, summaryText, amount }

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
    required this.window,
    required this.payloadKey,
    required this.reason,
    required this.settledQueryKey,
  });

  final int generation;
  final DashboardLogBoxSceneWindow window;
  final String payloadKey;
  final String reason;
  final LedgerQueryKey settledQueryKey;

  DashboardLogBoxSceneCoverageIdentity get coverage => window.coverageIdentity!;
}

/// A discrete structural transition that is intentionally held behind the
/// exact scene bank required to render its first visible frame. This is
/// controller-owned state: presentation only receives the commit once its
/// immutable payloads are already active.
@immutable
final class _PendingSceneCoveredNavigation {
  const _PendingSceneCoveredNavigation({
    required this.generation,
    required this.payloadKey,
    required this.window,
    required this.commit,
  });

  final int generation;
  final String payloadKey;
  final DashboardLogBoxSceneWindow window;
  final VoidCallback commit;
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
  }) : _yearWindowRadius = yearWindowRadius,
       expansion = DashboardExpansionController(metrics: metrics),
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
    committedLogViewport = CommittedLogViewportCache(
      pageSize: pageSize,
      maximumRetainedPages: 5,
    );
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
            queryKey: request.filterScope.key.value,
            coreRevision: request.key.coreRevision,
            flowId: 'generation:$generation',
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
            queryKey: presentation.navigation.state.parentQueryKey.value,
            coreRevision: index.coreRevision,
            entryCount: index.buildMetrics.uniquePreviewRowCount,
            durationMs: duration.inMilliseconds,
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
  final int _yearWindowRadius;
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
  DashboardLogBoxSceneWindowActivator? _sceneWindowActivator;
  DashboardLogBoxSceneWindowPreparationCanceller?
  _sceneWindowPreparationCanceller;
  DashboardLogBoxSceneWindowRebaseScheduler? _sceneWindowRebaseScheduler;
  DashboardLogBoxSceneWindowReporter? _sceneWindowReporter;
  DashboardPreparedRevisionBundle? _activePreparedRevisionBundle;
  DashboardRailCriticalSceneBankIdentity? _activeRailCriticalBankIdentity;
  Set<String> _activeSceneWindowQueryKeys = const <String>{};
  int _backgroundSceneWarmupGeneration = 0;
  bool _backgroundSceneWarmupInFlight = false;
  final ValueNotifier<bool> _sceneWindowPreparing = ValueNotifier<bool>(false);
  _QueuedPreparedIndex? _queuedPreparedIndex;
  int _queryApplyGeneration = 0;
  Future<bool>? _queryApplyInFlight;
  QueryComposerApplyIdentity? _activeComposerApplyIdentity;
  DashboardLogBoxSceneCoverageIdentity? _activeSceneCoverage;
  DashboardLogBoxSceneCoverageIdentity? _desiredSceneCoverage;
  _RequiredSceneCoverageDemand? _requiredSceneCoverageDemand;
  int _requiredSceneCoverageGeneration = 0;
  _PendingSceneCoveredNavigation? _pendingSceneCoveredNavigation;
  int _pendingSceneCoveredNavigationGeneration = 0;
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

  /// Registers the sole presentation capability that owns Flutter paragraph
  /// preparation. Navigation remains coordinated here; the render surface only
  /// creates immutable scene resources requested by this controller.
  void attachLogBoxSceneWindowCoordinator({
    required DashboardLogBoxSceneWindowPreparer prepare,
    required DashboardLogBoxSceneWindowActivator activate,
    DashboardLogBoxSceneWindowPreparationCanceller? cancel,
    DashboardLogBoxSceneWindowRebaseScheduler? scheduleRebase,
    DashboardLogBoxSceneWindowReporter? report,
  }) {
    if (_disposed) throw StateError('Dashboard core has been disposed.');
    _sceneWindowPreparer = prepare;
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
    _sceneWindowActivator = null;
    _sceneWindowPreparationCanceller = null;
    _sceneWindowRebaseScheduler = null;
    _sceneWindowReporter = null;
  }

  /// Records the normal readiness activation of the complete rail bank. The
  /// visible index is already mounted behind the startup gate, but it only
  /// becomes an interactive revision bundle once this exact bank is active.
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
    _activeSceneCoverage = window.coverageIdentity;
    _activeSceneWindowQueryKeys = _sceneWindowQueryKeys(window);
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
    // A candidate from an older immutable index may never commit after this
    // revision begins its own publication boundary.
    _pendingSceneCoveredNavigation = null;
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
    final nextBundle = DashboardPreparedRevisionBundle.forIndex(
      index,
      publicationState: publicationState,
    );
    final targetWindow = nextBundle.railCriticalSceneWindow.withCoverage(
      _coverageFor(publicationState ?? navigation.state, indexOverride: index),
    );
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
    if (template == currentQuery.scope) {
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
        _applyQuery(
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

  Future<bool> _applyQuery(
    CurrentLedgerQueryScope draft, {
    QueryMenuData? facetPresentation,
    QueryComposerApplyIdentity? composerApplyIdentity,
  }) async {
    if (_disposed || !_bootstrapped) return false;
    final generation = ++_queryApplyGeneration;
    final template = draft;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_STARTED',
        flowId: 'generation:$generation',
        queryKey: template.key.value,
        direction: template.direction.name,
        scope:
            'temporalFilter=${template.temporalFilter.canonicalKey} '
            'categories=${template.categoryIds.length} '
            'partners=${template.partnerIds.length}',
      ),
    );
    final availability = DashboardTemporalAvailability.fromTemporalFilter(
      template.temporalFilter,
    );
    final publicationState = navigation.appliedQueryCandidate(
      template,
      availability: availability,
      coreRevision: null,
    );
    final requestTemplate = DashboardIndexRequestTemplate(
      filterScope: template,
      pageSize: pageSize,
      initialYear: navigation.temporalAnchor.visibleYear,
      yearWindowRadius: _yearWindowRadius,
    );
    late final PreparedDashboardIndex index;
    final prepareTimer = Stopwatch()..start();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_INDEX_PREPARE_STARTED',
        flowId: 'generation:$generation',
        queryKey: template.key.value,
        direction: template.direction.name,
      ),
    );
    try {
      index = await dataRuntime.prepareQuery(requestTemplate);
    } on DashboardIndexPreparationDiscarded catch (error) {
      prepareTimer.stop();
      _recordQueryApplyPrepareFailure(
        generation: generation,
        scope: template,
        error: error,
        duration: prepareTimer.elapsed,
      );
      _recordQueryApplyCompleted(
        generation: generation,
        scope: template,
        published: false,
      );
      return false;
    } on Object catch (error) {
      prepareTimer.stop();
      _recordQueryApplyPrepareFailure(
        generation: generation,
        scope: template,
        error: error,
        duration: prepareTimer.elapsed,
      );
      _recordQueryApplyCompleted(
        generation: generation,
        scope: template,
        published: false,
      );
      return false;
    }
    prepareTimer.stop();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_INDEX_PREPARE_READY',
        flowId: 'generation:$generation',
        queryKey: template.key.value,
        direction: template.direction.name,
        coreRevision: index.coreRevision,
        entryCount: index.buildMetrics.uniquePreviewRowCount,
        durationMs: prepareTimer.elapsed.inMilliseconds,
      ),
    );
    if (!_isCurrentQueryApply(
      generation: generation,
      composerApplyIdentity: composerApplyIdentity,
    )) {
      return false;
    }
    var published = false;
    try {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_APPLY_CRITICAL_PRESENTATION_PREPARE_STARTED',
          flowId: 'generation:$generation',
          queryKey: template.key.value,
          direction: template.direction.name,
          coreRevision: index.coreRevision,
        ),
      );
      final installed = await installPreparedIndex(
        index,
        publicationState: publicationState,
        shouldPublish: () => _isCurrentQueryApply(
          generation: generation,
          composerApplyIdentity: composerApplyIdentity,
        ),
        beforePublish: () {
          if (!_isCurrentQueryApply(
            generation: generation,
            composerApplyIdentity: composerApplyIdentity,
          )) {
            return;
          }
          FluviDiagnosticLogger.log(
            FluviDiagnosticEvent(
              stage: 'QUERY_APPLY_PUBLICATION_STARTED',
              flowId: 'generation:$generation',
              queryKey: template.key.value,
              direction: template.direction.name,
              coreRevision: index.coreRevision,
            ),
          );
          presentation.navigation.replaceAppliedQuery(
            template,
            availability: availability,
            coreRevision: index.coreRevision,
          );
        },
        afterPublish: () {
          if (!_isCurrentQueryApply(
            generation: generation,
            composerApplyIdentity: composerApplyIdentity,
          )) {
            return;
          }
          dataRuntime.commitPreparedQuery(index, requestTemplate);
          currentQuery.apply(template, facetPresentation: facetPresentation);
          if (_activeComposerApplyIdentity == composerApplyIdentity) {
            _activeComposerApplyIdentity = null;
          }
          published = composerApplyIdentity == null
              ? true
              : queryComposer.completeApplied(
                  expectedIdentity: composerApplyIdentity,
                );
        },
      );
      if (installed && published) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_APPLY_CRITICAL_PRESENTATION_PREPARE_READY',
            flowId: 'generation:$generation',
            queryKey: template.key.value,
            direction: template.direction.name,
            coreRevision: index.coreRevision,
          ),
        );
        _startBackgroundSceneWarmup(index);
      }
      if (!installed || !published) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_APPLY_PUBLICATION_FAILED',
            flowId: 'generation:$generation',
            queryKey: template.key.value,
            direction: template.direction.name,
            coreRevision: index.coreRevision,
            error: 'preparedIndexNotPublished',
          ),
        );
      } else {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_APPLY_PUBLICATION_COMPLETED',
            flowId: 'generation:$generation',
            queryKey: currentQuery.scope.key.value,
            direction: currentQuery.scope.direction.name,
            coreRevision: index.coreRevision,
          ),
        );
      }
      _recordQueryApplyCompleted(
        generation: generation,
        scope: template,
        published: installed && published,
      );
      return installed && published;
    } on Object catch (error) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_APPLY_PUBLICATION_FAILED',
          flowId: 'generation:$generation',
          queryKey: template.key.value,
          direction: template.direction.name,
          coreRevision: index.coreRevision,
          error: '$error',
        ),
      );
      _recordQueryApplyCompleted(
        generation: generation,
        scope: template,
        published: false,
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
    final identity = _activeComposerApplyIdentity;
    if (identity == null || queryComposer.isCurrentApplyIdentity(identity)) {
      return;
    }
    final reason = switch (queryComposer.lastStateChange) {
      QueryComposerStateChange.draftChanged => 'draftChanged',
      QueryComposerStateChange.closed => 'sheetClosed',
      QueryComposerStateChange.opened => 'sheetReopened',
      QueryComposerStateChange.applied => 'applied',
    };
    _cancelActiveComposerApply(reason: reason);
  }

  void _cancelActiveComposerApply({required String reason}) {
    final identity = _activeComposerApplyIdentity;
    if (identity == null) return;
    _activeComposerApplyIdentity = null;
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

  void _recordQueryApplyPrepareFailure({
    required int generation,
    required CurrentLedgerQueryScope scope,
    required Object error,
    required Duration duration,
  }) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_APPLY_INDEX_PREPARE_FAILED',
        flowId: 'generation:$generation',
        queryKey: scope.key.value,
        direction: scope.direction.name,
        durationMs: duration.inMilliseconds,
        error: '$error',
      ),
    );
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
        queryKey: published ? currentQuery.scope.key.value : scope.key.value,
        direction: published
            ? currentQuery.scope.direction.name
            : scope.direction.name,
        scope: 'published=$published',
      ),
    );
  }

  /// Dashboard chip intent: produce one new immutable applied scope, then use
  /// the same prepared-index publication boundary as Query Menu Apply.
  void removeAppliedQueryCategory(String categoryId) {
    final scope = currentQuery.scope;
    final categories = <String>{...scope.categoryIds}..remove(categoryId);
    unawaited(
      applyQuery(
        scope.copyWith(categoryIds: categories),
        facetPresentation: currentQuery.facetPresentation,
      ),
    );
  }

  void removeAppliedQueryPartner(String partnerId) {
    final scope = currentQuery.scope;
    final partners = <String>{...scope.partnerIds}..remove(partnerId);
    unawaited(
      applyQuery(
        scope.copyWith(partnerIds: partners),
        facetPresentation: currentQuery.facetPresentation,
      ),
    );
  }

  void clearAppliedQuery() {
    final scope = currentQuery.scope;
    unawaited(
      applyQuery(
        CurrentLedgerQueryScope(
          direction: scope.direction,
          timeScope: const AllTimeScope(),
        ),
      ),
    );
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

  void toggleRail() => setRailOpen(!navigation.state.isRailOpen);

  void setRailOpen(bool open) {
    presentation.setRailOpen(open);
    _recordNavigationSelection(open ? 'railOpened' : 'railClosed');
    unawaited(
      _reconcileSceneCoverageAfterNavigation(
        reason: open ? 'railOpened' : 'structuralRailExit',
      ),
    );
  }

  Future<void> navigateParent(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    final candidate = presentation.parentCandidate(direction);
    if (candidate == null) return Future<void>.value();
    return _commitNavigationWithSceneCoverage(
      candidate: candidate,
      reason: 'parentNavigation',
      settledQueryKey: candidate.parentQueryKey,
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
    final candidate = presentation.planeCandidate(finer: finer);
    unawaited(
      _commitNavigationWithSceneCoverage(
        candidate: candidate,
        reason: finer ? 'planeFiner' : 'planeCoarser',
        settledQueryKey: candidate.parentQueryKey,
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
    final ledgerDirection = direction == TransactionDirection.income
        ? LedgerDirection.income
        : LedgerDirection.expense;
    final candidate = presentation.directionCandidate(ledgerDirection);
    unawaited(
      _commitNavigationWithSceneCoverage(
        candidate: candidate,
        reason: 'directionChanged',
        settledQueryKey: candidate.parentQueryKey,
        commit: () {
          transactionDirection.select(direction);
          presentation.commitDirectionCandidate(candidate);
          // DashboardCoreController is the sole composition boundary that
          // changes direction. Keep the single applied Query owner coherent
          // with presentation; a Query draft later copies this applied scope.
          if (currentQuery.scope.direction != ledgerDirection) {
            currentQuery.apply(
              currentQuery.scope.copyWith(direction: ledgerDirection),
            );
          }
          _recordNavigationSelection('directionChanged');
        },
      ),
    );
  }

  Future<bool> loadNextPage() => paging.loadNextPage();

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
    _cancelSceneWindowMaintenanceForInput();
    paging.beginForwardDemandEpoch();
  }

  /// Resume only the current latest scene target after a real vertical scroll
  /// has gone idle. This keeps a pointer-down cancellation from discarding
  /// maintenance forever, without scheduling cache work during the drag or
  /// ballistic phase.
  void resumeSceneWindowMaintenanceAfterVerticalInput() {
    if (_disposed) return;
    if (_requiredSceneCoverageDemand != null) {
      _drainRequiredSceneCoverageDemand();
      return;
    }
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
      'renderedRowCount': payload?.logBox.flatItems.length ?? 0,
      'renderedContentExtent': 0.0,
      'previewPayloadRows': payload?.logBox.flatItems.length ?? 0,
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

  /// Complete bounded preview universe for the renderer-visible rail bank.
  ///
  /// Every frame is pre-projected by [PreparedDashboardIndex]. This is not a
  /// temporal-locality cache: every SUM/year/month rail child in both
  /// directions is available before interaction begins.
  List<DashboardLogViewportState> renderCriticalLogBoxPayloads() =>
      railCriticalSceneWindow().payloads;

  DashboardLogBoxSceneWindow renderCriticalLogBoxSceneWindow() =>
      railCriticalSceneWindow();

  DashboardLogBoxSceneWindow railCriticalSceneWindow() {
    final activeBundle = _activePreparedRevisionBundle;
    if (activeBundle != null) return activeBundle.railCriticalSceneWindow;
    final index = presentation.index;
    if (index == null) {
      return DashboardLogBoxSceneWindow(
        identity:
            'rail-critical:unprepared:${navigation.state.navigationEpoch}',
        payloads: const <DashboardLogViewportState>[],
      );
    }
    return railCriticalSceneWindowForIndex(index, state: navigation.state);
  }

  /// Derives the immutable rail-preview universe from the index itself, not
  /// from the currently visible temporal anchor. Each index frame is already
  /// capped to its canonical preview payload; committed vertical pages are not
  /// present here.
  DashboardLogBoxSceneWindow railCriticalSceneWindowForIndex(
    PreparedDashboardIndex index, {
    DashboardNavigationState? state,
  }) {
    final activeBundle = _activePreparedRevisionBundle;
    final canReuseCompleteActiveBundle =
        state == null &&
        identical(activeBundle?.index, index) &&
        activeBundle!.railCriticalSceneWindow.sceneCount == index.frames.length;
    final bundle = canReuseCompleteActiveBundle
        ? activeBundle
        : DashboardPreparedRevisionBundle.forIndex(
            index,
            publicationState: state,
          );
    final coverage = state == null
        ? null
        : _coverageFor(state, indexOverride: index);
    return bundle.railCriticalSceneWindow.withCoverage(coverage);
  }

  /// Compatibility entry point retained for controller callers. Rail
  /// correctness intentionally no longer narrows to an anchor-local cache.
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
    return railCriticalSceneWindowForIndex(index, state: state);
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

  /// Starts the non-blocking completion of the exact immutable index bank
  /// only after the small, publication-critical target has already committed.
  /// It reuses the sole scene-cache preparation capability; a new gesture,
  /// structural target or Query Apply invalidates this work through the same
  /// cancellation owner before it can activate stale scenes.
  void _startBackgroundSceneWarmup(PreparedDashboardIndex index) {
    final prepare = _sceneWindowPreparer;
    final activate = _sceneWindowActivator;
    final activeBundle = _activePreparedRevisionBundle;
    if (_disposed ||
        prepare == null ||
        activate == null ||
        !identical(activeBundle?.index, index)) {
      return;
    }
    final fullBundle = DashboardPreparedRevisionBundle.forIndex(index);
    final fullWindow = fullBundle.railCriticalSceneWindow;
    if (activeBundle!.railCriticalSceneWindow.sceneCount >=
        fullWindow.sceneCount) {
      return;
    }
    _cancelBackgroundSceneWarmup();
    final generation = ++_backgroundSceneWarmupGeneration;
    _backgroundSceneWarmupInFlight = true;

    void start() => unawaited(
      _runBackgroundSceneWarmup(
        generation: generation,
        index: index,
        bundle: fullBundle,
        window: fullWindow,
        prepare: prepare,
        activate: activate,
      ),
    );

    // The render owner schedules this on its next frame. The microtask
    // fallback is only for deterministic controller tests with no widget host.
    final scheduler = _sceneWindowRebaseScheduler;
    if (scheduler != null) {
      scheduler(start);
    } else {
      scheduleMicrotask(start);
    }
  }

  Future<void> _runBackgroundSceneWarmup({
    required int generation,
    required PreparedDashboardIndex index,
    required DashboardPreparedRevisionBundle bundle,
    required DashboardLogBoxSceneWindow window,
    required DashboardLogBoxSceneWindowPreparer prepare,
    required DashboardLogBoxSceneWindowActivator activate,
  }) async {
    final startedAt = Stopwatch()..start();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_BACKGROUND_SCENE_WARMUP_STARTED',
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
          !identical(presentation.index, index)) {
        return;
      }
      _activateSceneWindow(window, activate: activate);
      _activePreparedRevisionBundle = bundle;
      _activeRailCriticalBankIdentity = bundle.railCriticalSceneBankIdentity;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_BACKGROUND_SCENE_WARMUP_COMPLETED',
          flowId: 'generation:$generation',
          queryKey: window.identity,
          coreRevision: index.coreRevision,
          entryCount: window.previewRowCount,
          durationMs: startedAt.elapsedMilliseconds,
        ),
      );
    } on DashboardLogBoxScenePreparationCancelled {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_BACKGROUND_SCENE_WARMUP_CANCELLED',
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
          message: 'QUERY_BACKGROUND_SCENE_WARMUP_FAILED',
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

  /// Returns whether this call invalidated a live background warmup. The
  /// caller then knows not to invoke the same one-owner cache cancellation a
  /// second time for the same supersession event.
  bool _cancelBackgroundSceneWarmup() {
    if (!_backgroundSceneWarmupInFlight) return false;
    _backgroundSceneWarmupGeneration += 1;
    _backgroundSceneWarmupInFlight = false;
    _sceneWindowPreparationCanceller?.call();
    return true;
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
  }) {
    final existing = _requiredSceneCoverageDemand;
    if (existing != null && existing.payloadKey == payloadKey) {
      return existing;
    }
    final demand = _RequiredSceneCoverageDemand(
      generation: ++_requiredSceneCoverageGeneration,
      window: window,
      payloadKey: payloadKey,
      reason: reason,
      settledQueryKey: settledQueryKey,
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
    required VoidCallback commit,
  }) {
    if (_disposed) return Future<void>.value();
    // Controller-only consumers have no render owner and therefore no scene
    // lifecycle to guard. Preserve the established synchronous RAM-only
    // navigation contract for that boundary; production attaches the sole
    // coordinator before a dashboard becomes interactive.
    if (_sceneWindowPreparer == null || _sceneWindowActivator == null) {
      _pendingSceneCoveredNavigation = null;
      commit();
      return Future<void>.value();
    }
    final targetWindow = renderCriticalLogBoxSceneWindowFor(candidate);
    final targetCoverage = targetWindow.coverageIdentity;
    if (targetCoverage == null) {
      commit();
      return Future<void>.value();
    }
    final payloadKey = _sceneWindowPayloadKey(targetWindow);
    if (_activeSceneWindowCovers(targetWindow)) {
      _pendingSceneCoveredNavigation = null;
      _activeSceneCoverage = targetCoverage;
      _desiredSceneCoverage = targetCoverage;
      commit();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_COVERAGE_HIT',
          message: 'reason=$reason target=${targetCoverage.value}',
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
    );
    _pendingSceneCoveredNavigation = _PendingSceneCoveredNavigation(
      generation: ++_pendingSceneCoveredNavigationGeneration,
      payloadKey: payloadKey,
      window: targetWindow,
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
    if (diagnostics.isMotionActive) return Future<void>.value();
    return _requestSceneWindowMaintenance(demand: demand);
  }

  void _commitPendingSceneCoveredNavigation() {
    final pending = _pendingSceneCoveredNavigation;
    if (pending == null || !_activeSceneWindowCovers(pending.window)) {
      return;
    }
    _pendingSceneCoveredNavigation = null;
    pending.commit();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_NAVIGATION_TRANSITION_COMMITTED',
        message: 'generation=${pending.generation}',
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
    final targetWindow = renderCriticalLogBoxSceneWindowFor(navigation.state);
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
  }) {
    if (_disposed) return Future<void>.value();
    if (_requiredSceneCoverageDemand?.generation != demand.generation) {
      return Future<void>.value();
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
    _scheduleSceneRebaseDrain();
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
    if (!_cancelBackgroundSceneWarmup()) {
      _sceneWindowPreparationCanceller?.call();
    }
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
      final stale =
          requestGeneration != _sceneRebaseGeneration ||
          _requiredSceneCoverageDemand?.generation != demand.generation ||
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
    if (!anyActive) _drainRequiredSceneCoverageDemand();
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
