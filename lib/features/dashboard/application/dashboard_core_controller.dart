import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../core/design/dashboard_layout_metrics.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../shared/motion/centered_carousel/centered_carousel_controller.dart';
import '../logbox/application/committed_log_viewport_cache.dart';
import '../logbox/application/dashboard_log_viewport_state.dart';
import '../logbox/application/dashboard_logbox_scene_window.dart';
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
import '../time_navigation/domain/time_plane.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../visible/application/dashboard_visible_frame_store.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_interaction_diagnostics.dart';
import 'dashboard_performance_counters.dart';
import 'dashboard_rail_flight_recorder.dart';
import 'dashboard_render_readiness_diagnostics.dart';
import 'transaction_direction_controller.dart';

enum DashboardMotionLane { rail, visualHost, summaryShell, summaryText, amount }

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
  DashboardLogBoxSceneWindowPreparer? _sceneWindowPreparer;
  DashboardLogBoxSceneWindowActivator? _sceneWindowActivator;
  DashboardLogBoxSceneWindowReporter? _sceneWindowReporter;
  final ValueNotifier<bool> _sceneWindowPreparing = ValueNotifier<bool>(false);
  PreparedDashboardIndex? _queuedPreparedIndex;
  String? _lastSceneWindowError;
  final Set<DashboardMotionLane> _activeMotionLanes = <DashboardMotionLane>{};

  DashboardNavigationController get navigation => presentation.navigation;
  DashboardMotionKernel get motion => presentation.motion;
  DashboardVisibleFrameStore get visibleFrames => presentation.visibleFrames;
  DashboardDisplayFrameCoalescer get frameCoalescer =>
      presentation.frameCoalescer;
  PreparedDashboardIndex? get preparedIndex => dataRuntime.currentIndex;
  int? get coreRevision => dataRuntime.currentIndex?.coreRevision;
  bool get isBootstrapped => _bootstrapped;
  ValueListenable<bool> get sceneWindowPreparing => _sceneWindowPreparing;

  /// Registers the sole presentation capability that owns Flutter paragraph
  /// preparation. Navigation remains coordinated here; the render surface only
  /// creates immutable scene resources requested by this controller.
  void attachLogBoxSceneWindowCoordinator({
    required DashboardLogBoxSceneWindowPreparer prepare,
    required DashboardLogBoxSceneWindowActivator activate,
    DashboardLogBoxSceneWindowReporter? report,
  }) {
    if (_disposed) throw StateError('Dashboard core has been disposed.');
    _sceneWindowPreparer = prepare;
    _sceneWindowActivator = activate;
    _sceneWindowReporter = report;
  }

  void detachLogBoxSceneWindowCoordinator() {
    _sceneWindowPreparer = null;
    _sceneWindowActivator = null;
    _sceneWindowReporter = null;
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
      'sceneWindow':
          _sceneWindowReporter?.call() ??
          <String, Object?>{
            'state': 'unattached',
            'preparedScenes': 0,
            'preparedTextRows': _logBoxTextLayoutPreparedRows,
            'sceneCacheBytes': _logBoxTextLayoutEstimatedBytes,
            'textLayoutMisses': 0,
          },
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
    final scene = _sceneWindowReporter?.call() ?? const <String, Object?>{};
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

  /// Installs an idle-time immutable index only after its scene bank is ready.
  ///
  /// Bootstrap reaches this before the dashboard surface attaches, so it keeps
  /// the synchronous publication contract. Later revisions rotate exactly like
  /// a parent navigation: the old complete scene remains visible while input
  /// is gated, then the new index and scene bank commit together.
  Future<void> installPreparedIndex(PreparedDashboardIndex index) async {
    if (_disposed) return;
    final prepare = _sceneWindowPreparer;
    final activate = _sceneWindowActivator;
    if (prepare == null || activate == null) {
      _publishIndex(index);
      return;
    }
    if (_sceneWindowPreparing.value) {
      final queued = _queuedPreparedIndex;
      if (queued == null || index.coreRevision >= queued.coreRevision) {
        _queuedPreparedIndex = index;
      }
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'INDEX_PUBLICATION_QUEUED',
          message: 'sceneRotationInProgress',
          coreRevision: index.coreRevision,
        ),
      );
      return;
    }
    final targetWindow = renderCriticalLogBoxSceneWindowFor(
      navigation.state,
      indexOverride: index,
      includeCurrentVisiblePayload: false,
    );
    _sceneWindowPreparing.value = true;
    _lastSceneWindowError = null;
    try {
      await prepare(
        targetWindow,
        retainViewportId: visibleFrames.value?.logBox.viewportId,
      );
      if (_disposed) return;
      _publishIndex(index);
      activate(targetWindow);
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
  }

  void _finishSceneWindowPreparation() {
    if (_disposed) return;
    _sceneWindowPreparing.value = false;
    final queued = _queuedPreparedIndex;
    _queuedPreparedIndex = null;
    if (queued != null) unawaited(installPreparedIndex(queued));
  }

  void _publishIndex(PreparedDashboardIndex index) {
    // DashboardDataRuntime publishes only at bootstrap or on the first stable
    // idle frame. This installs the index and its complete visible frame as one
    // atomic revision boundary; no coalescer frame may mix revisions.
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
    if (_sceneWindowPreparing.value) return;
    presentation.setRailOpen(open);
    _recordNavigationSelection(open ? 'railOpened' : 'railClosed');
  }

  Future<void> navigateParent(
    DashboardTimeNavigationChangeDirection direction,
  ) async {
    if (_sceneWindowPreparing.value) return;
    final candidate = presentation.parentCandidate(direction);
    if (candidate == null) return;
    final prepare = _sceneWindowPreparer;
    final activate = _sceneWindowActivator;
    if (prepare == null || activate == null) {
      presentation.navigateParent(direction);
      _recordNavigationSelection('parentCommitted');
      return;
    }

    final expectedNavigationEpoch = navigation.state.navigationEpoch;
    final targetWindow = renderCriticalLogBoxSceneWindowFor(candidate);
    _sceneWindowPreparing.value = true;
    _lastSceneWindowError = null;
    try {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_PREPARE_STARTED',
          queryKey: targetWindow.identity,
          coreRevision: coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      await prepare(
        targetWindow,
        retainViewportId: visibleFrames.value?.logBox.viewportId,
      );
      if (_disposed ||
          navigation.state.navigationEpoch != expectedNavigationEpoch) {
        return;
      }
      presentation.navigateParent(direction);
      activate(targetWindow);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_ROTATED',
          queryKey: targetWindow.identity,
          coreRevision: coreRevision,
          entryCount: targetWindow.previewRowCount,
        ),
      );
      _recordNavigationSelection('parentCommitted');
    } on Object catch (error) {
      // A structural cache-rotation failure must preserve the complete active
      // window and make the failure visible to profile diagnostics. It may not
      // degrade into a partial, avatar-only scene or an unhandled async error.
      _lastSceneWindowError = '$error';
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'ERROR',
          message: 'SCENE_WINDOW_PREPARE_FAILED',
          queryKey: targetWindow.identity,
          coreRevision: coreRevision,
          entryCount: targetWindow.previewRowCount,
          error: '$error',
        ),
      );
    } finally {
      _finishSceneWindowPreparation();
    }
  }

  void commitParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) => unawaited(navigateParent(direction));

  DashboardNavigationState? previewParent(
    DashboardTimeNavigationChangeDirection direction,
  ) => presentation.parentCandidate(direction);

  void navigatePlane({required bool finer}) {
    if (_sceneWindowPreparing.value) return;
    presentation.navigatePlane(finer: finer);
    _recordNavigationSelection('planeCommitted');
  }

  void selectDirection(TransactionDirection direction) {
    if (_sceneWindowPreparing.value) return;
    transactionDirection.select(direction);
    presentation.selectDirection(
      direction == TransactionDirection.income
          ? LedgerDirection.income
          : LedgerDirection.expense,
    );
    _recordNavigationSelection('directionChanged');
  }

  Future<bool> loadNextPage() => paging.loadNextPage();

  Future<bool> requestForwardPageDemand(int desiredLastReadyOrdinal) =>
      paging.requestForwardDemand(desiredLastReadyOrdinal);

  void beginVerticalPageDemandEpoch() => paging.beginForwardDemandEpoch();

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

  /// Bounded render-critical payload window prepared before interaction.
  ///
  /// The pin set covers the temporal anchor's SUM/year/month catalogs, their
  /// adjacent parents and both directions. It is derived from the immutable
  /// index only; it performs no data acquisition or view-model projection.
  List<DashboardLogViewportState> renderCriticalLogBoxPayloads() =>
      renderCriticalLogBoxSceneWindow().payloads;

  DashboardLogBoxSceneWindow renderCriticalLogBoxSceneWindow() =>
      renderCriticalLogBoxSceneWindowFor(navigation.state);

  /// Pure prepared-index selection for an active or candidate structural
  /// state. It has no repository, bridge, projection, formatting or rail
  /// dependency, so it is safe to call before a parent commit.
  DashboardLogBoxSceneWindow renderCriticalLogBoxSceneWindowFor(
    DashboardNavigationState state, {
    PreparedDashboardIndex? indexOverride,
    bool includeCurrentVisiblePayload = true,
  }) {
    final index = indexOverride ?? presentation.index ?? preparedIndex;
    if (index == null) {
      return DashboardLogBoxSceneWindow(
        identity: 'unprepared:${state.navigationEpoch}',
        payloads: const <DashboardLogViewportState>[],
      );
    }
    final anchor = state.temporalAnchor;
    final month = anchor.visibleYearMonth;
    final parentScopes = <LedgerTimeScope>{
      const AllTimeScope(),
      if (anchor.visibleYear > index.key.yearWindowStart)
        YearScope(anchor.visibleYear - 1),
      YearScope(anchor.visibleYear),
      if (anchor.visibleYear < index.key.yearWindowEndInclusive)
        YearScope(anchor.visibleYear + 1),
      if (month.year > 1 || month.month > 1) MonthScope(month.previous()),
      MonthScope(month),
      if (month.year < 9999 || month.month < 12) MonthScope(month.next()),
    };
    final payloads = <int, DashboardLogViewportState>{};
    final visible = visibleFrames.value?.logBox;
    if (includeCurrentVisiblePayload && visible != null) {
      payloads[visible.viewportId] = visible;
    }
    for (final direction in LedgerDirection.values) {
      for (final parentScope in parentScopes) {
        final catalog = index.catalogForIdentity(
          direction: direction,
          timeScope: parentScope,
        );
        if (catalog == null) continue;
        final parentFrame = index.frameForKey(catalog.parentScope.key);
        payloads[parentFrame.logBox.viewportId] = parentFrame.logBox;
        for (final entry in catalog.entries) {
          final frame = index.frameForKey(entry.queryKey);
          payloads[frame.logBox.viewportId] = frame.logBox;
        }
      }
    }
    return DashboardLogBoxSceneWindow(
      identity:
          'rev:${index.coreRevision}|anchor:${anchor.visibleYearMonth.isoString}'
          '|year:${anchor.visibleYear}|plane:${state.plane.name}'
          '|direction:${state.parentQueryScope.direction.name}',
      payloads: payloads.values.toList(growable: false),
    );
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
    _disposed = true;
    _sceneWindowPreparing.dispose();
    detachLogBoxSceneWindowCoordinator();
    _activeMotionLanes.clear();
    railFlightRecorder?.dispose();
    visibleFrames.removeListener(_onVisibleFramePublished);
    dataRuntime.dispose();
    paging.dispose();
    committedLogViewport.dispose();
    presentation.dispose();
    transactionDirection.dispose();
    expansion.dispose();
  }
}
