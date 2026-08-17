import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

import '../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/motion/dashboard_motion_host.dart';
import '../application/dashboard_core_controller.dart';
import '../application/dashboard_core_mode_controller.dart';
import '../application/dashboard_ephemeral_focus_controller.dart';
import '../application/dashboard_performance_counters.dart';
import 'core_modes/dashboard_core_mode_host.dart';
import 'widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'widgets/dashboard_logbox_partner_swipe.dart';
import 'widgets/dashboard_logbox_render_surface.dart';
import '../application/transaction_direction_controller.dart';
import 'summary_navigation_motion_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/presentation/summary_navigation_presentation.dart';
import 'widgets/dashboard_collapse_handle.dart';
import 'widgets/dashboard_logbox_viewport.dart';
import 'widgets/dashboard_render_phase_probe.dart';
import 'widgets/dashboard_summary_pill.dart';
import 'widgets/fluvi_brand_lockup.dart';
import 'widgets/summary_pill_text_transition.dart';
import 'widgets/transaction_direction_toggle.dart';

/// Shared dashboard composition with one bounded, separately-owned mode domain.
class CoreDashboard extends StatefulWidget {
  const CoreDashboard({
    super.key,
    required this.controller,
    required this.modeController,
    this.preparedLogBoxRasters,
    this.onLogBoxWarmupSurfaceAttached,
    this.onLogBoxWarmupSurfaceLaidOut,
    this.onLogBoxWarmupTextLayoutsPrepared,
    this.onLogBoxWarmupError,
  });

  final DashboardCoreController controller;
  final DashboardCoreModeController modeController;
  final PreparedLogBoxRasterSet? preparedLogBoxRasters;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupSurfaceAttached;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupSurfaceLaidOut;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupTextLayoutsPrepared;
  final DashboardLogBoxWarmupErrorCallback? onLogBoxWarmupError;

  @override
  State<CoreDashboard> createState() => _CoreDashboardState();
}

class _CoreDashboardState extends State<CoreDashboard>
    with TickerProviderStateMixin {
  late final SummaryNavigationMotionController _summaryMotionController;
  late final DashboardLogBoxPreparedSceneCache _preparedSceneCache;
  late final DashboardLogBoxPartnerSwipeController _partnerSwipe;
  double _devicePixelRatio = 1;

  DashboardCoreController get controller => widget.controller;
  DashboardCoreModeController get modeController => widget.modeController;

  @override
  void initState() {
    super.initState();
    _summaryMotionController = SummaryNavigationMotionController();
    _summaryMotionController.addListener(_onSummaryTextMotionChanged);
    _preparedSceneCache = DashboardLogBoxPreparedSceneCache();
    _preparedSceneCache.addListener(_recordSceneCacheMetrics);
    _partnerSwipe = DashboardLogBoxPartnerSwipeController(vsync: this);
    controller.attachLogBoxSceneWindowCoordinator(
      prepare: (window, {required retainViewportId}) =>
          _preparedSceneCache.prepareWindow(
            window: window,
            retainViewportId: retainViewportId,
            devicePixelRatio: _devicePixelRatio,
            maxContiguousUiSliceMicros: 3000,
            yieldToBackground: _yieldScenePreparationToScheduler,
          ),
      prepareCandidate:
          (window, {required candidateKey, required retainViewportId}) =>
              _preparedSceneCache.prepareCandidateWindow(
                candidateKey: candidateKey,
                window: window,
                retainViewportId: retainViewportId,
                devicePixelRatio: _devicePixelRatio,
                maxContiguousUiSliceMicros: 3000,
                yieldToBackground: _yieldScenePreparationToScheduler,
              ),
      discardCandidate: _preparedSceneCache.discardCandidateWindow,
      hasCandidate: (window, {required candidateKey}) => _preparedSceneCache
          .hasCandidateWindow(window, candidateKey: candidateKey),
      setCandidateHotset: _preparedSceneCache.setProtectedCandidateKeys,
      planCandidateHotset: _preparedSceneCache.admitCandidateHotset,
      planRetainedSceneWindow: _preparedSceneCache.admitRetainedWindow,
      prepareRetained:
          (window, {required retainedKey, required retainViewportId}) =>
              _preparedSceneCache.prepareRetainedWindow(
                retainedKey: retainedKey,
                window: window,
                retainViewportId: retainViewportId,
                devicePixelRatio: _devicePixelRatio,
                maxContiguousUiSliceMicros: 3000,
                yieldToBackground: _yieldScenePreparationToScheduler,
              ),
      hasRetained: _preparedSceneCache.hasRetainedWindow,
      retainActive: (window, {required retainedKey}) => _preparedSceneCache
          .retainActiveWindow(retainedKey: retainedKey, window: window),
      discardRetainedFocus: _preparedSceneCache.discardRetainedFocusBaseWindow,
      activate: _preparedSceneCache.activateWindow,
      cancel: _preparedSceneCache.cancelInFlightPreparation,
      scheduleRebase: _scheduleSceneRebaseOnNextFrame,
      report: _preparedSceneCache.report,
    );
  }

  void _scheduleSceneRebaseOnNextFrame(void Function() task) {
    WidgetsBinding.instance.scheduleFrameCallback((_) => task());
  }

  /// Cooperatively yields a bounded scene-layout slice without turning every
  /// checkpoint into an `endOfFrame` wait. Flutter runs higher priority input
  /// tasks before this animation-priority task, while preparation may continue
  /// in the same wall-clock frame when the scheduler has budget.
  Future<void> _yieldScenePreparationToScheduler() {
    // The automated binding owns a fake event loop. Leaving an animation task
    // queued while a test disposes the widget is reported as a leaked timer,
    // even though production would run it before the next input turn. Cache
    // unit/widget tests need deterministic completion, while the actual app
    // keeps the higher-priority scheduler path below.
    if (WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      return Future<void>.microtask(() {});
    }
    return SchedulerBinding.instance.scheduleTask<void>(
      () {},
      Priority.animation,
      debugLabel: 'CoreDashboard.scenePreparationYield',
    );
  }

  void _onSummaryTextMotionChanged() {
    controller.setMotionLaneActive(
      DashboardMotionLane.summaryText,
      _summaryMotionController.stagedText.isAxisMotionActive,
    );
  }

  void _recordSceneCacheMetrics() {
    controller.recordLogBoxTextLayoutCache(
      preparedRowCount: _preparedSceneCache.preparedRowCount,
      preparedDayHeaderCount: _preparedSceneCache.preparedDayHeaderCount,
      estimatedBytes: _preparedSceneCache.estimatedBytes,
    );
  }

  @override
  void dispose() {
    controller.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
    controller.setMotionLaneActive(DashboardMotionLane.summaryText, false);
    controller.detachLogBoxSceneWindowCoordinator();
    _summaryMotionController.removeListener(_onSummaryTextMotionChanged);
    _summaryMotionController.dispose();
    _preparedSceneCache.removeListener(_recordSceneCacheMetrics);
    _preparedSceneCache.dispose();
    _partnerSwipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _devicePixelRatio = View.of(context).devicePixelRatio;
    final logBoxRasters =
        widget.preparedLogBoxRasters ??
        PreparedVectorAssetAtlas.instance.logBoxRastersFor(
          View.of(context).devicePixelRatio,
        );
    final layoutMetrics = kIsWeb
        ? controller.metrics.forWebContentOrigin
        : controller.metrics;
    final contentTopPadding = kIsWeb ? 20.0 : 0.0;

    return DashboardMotionHost(
      controller: controller,
      modeController: modeController,
      layoutMetrics: layoutMetrics,
      builder: (context, frame) {
        final geometry = frame.geometry;
        Widget profileRenderProbe({
          required Widget child,
          required DashboardPerformanceMetric layoutMetric,
          required DashboardPerformanceMetric paintMetric,
          required DashboardPerformanceMetric layoutDurationMetric,
          required DashboardPerformanceMetric paintDurationMetric,
        }) {
          if (controller.railFlightRecorder?.isEnabled != true) return child;
          return DashboardRenderPhaseProbe(
            counters: controller.performanceCounters,
            layoutMetric: layoutMetric,
            paintMetric: paintMetric,
            layoutDurationMetric: layoutDurationMetric,
            paintDurationMetric: paintDurationMetric,
            child: child,
          );
        }

        return DashboardRenderPhaseProbe(
          counters: controller.performanceCounters,
          child: ColoredBox(
            key: const ValueKey('core-dashboard'),
            color: frame.palette.pageBackground,
            child: Padding(
              key: const ValueKey('dashboard-content-inset'),
              padding: EdgeInsets.only(top: contentTopPadding),
              child: SizedBox.expand(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _FramePosition(
                      bounds: geometry.brandLockupBounds,
                      child: FluviBrandLockup(
                        bounds: geometry.brandLockupBounds,
                      ),
                    ),
                    DashboardCoreModeHost(
                      controller: modeController,
                      motion: frame.modeTransitionMotion,
                      presentationFor: frame.presentationFor,
                      onVerticalExpansionStart: controller.expansion.beginDrag,
                      onVerticalExpansionDragBy: (viewportDelta) =>
                          controller.expansion.dragBy(
                            geometry.mapViewportVerticalDragToController(
                              viewportDelta,
                            ),
                          ),
                      onVerticalExpansionEnd: controller.expansion.endDrag,
                    ),
                    _FramePosition(
                      bounds: geometry.actionBounds,
                      child: Semantics(
                        key: const ValueKey('dashboard-action-row'),
                        label:
                            frame.selectedDirection ==
                                TransactionDirection.income
                            ? 'Bevétel'
                            : 'Kiadás',
                        child: TransactionDirectionToggle(
                          bounds: geometry.actionBounds,
                          palette: frame.palette,
                          selectedDirection: frame.selectedDirection,
                          incomeIconScale: frame.incomeIconScale,
                          expenseIconScale: frame.expenseIconScale,
                          selectedIconScaleAnimation: frame.directionPulseScale,
                          performanceCounters: controller.performanceCounters,
                          onSelected: (direction) {
                            controller.selectDirection(direction);
                          },
                        ),
                      ),
                    ),
                    _FramePosition(
                      bounds: geometry.summaryBounds,
                      child: _DashboardSummaryRegion(
                        bounds: geometry.summaryBounds,
                        controller: controller,
                        motionController: _summaryMotionController,
                        onMotionActiveChanged: (active) =>
                            controller.setMotionLaneActive(
                              DashboardMotionLane.summaryShell,
                              active,
                            ),
                        onAmountMotionActiveChanged: (active) =>
                            controller.setMotionLaneActive(
                              DashboardMotionLane.amount,
                              active,
                            ),
                      ),
                    ),
                    _FramePosition(
                      bounds: geometry.railBounds,
                      child: Opacity(
                        opacity: frame.railReveal,
                        child: IgnorePointer(
                          ignoring: !geometry.isRailExpanded,
                          child: profileRenderProbe(
                            layoutMetric: DashboardPerformanceMetric.railLayout,
                            paintMetric: DashboardPerformanceMetric.railPaint,
                            layoutDurationMetric:
                                DashboardPerformanceMetric.railLayoutMicros,
                            paintDurationMetric:
                                DashboardPerformanceMetric.railPaintMicros,
                            child: TimeRefinementRail(
                              bounds: geometry.railBounds,
                              motion: controller.motion,
                              onPreviewLogicalIndexChanged:
                                  (oldIndex, newIndex) =>
                                      _summaryMotionController.triggerRailTick(
                                        oldLogicalIndex: oldIndex,
                                        newLogicalIndex: newIndex,
                                      ),
                              onMotionBaselineEstablished:
                                  _summaryMotionController
                                      .resetRailTickBaseline,
                              onMotionStarted: controller.beginRailMotion,
                              performanceCounters:
                                  controller.performanceCounters,
                              motionDiagnostics: controller.railFlightRecorder,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: geometry.logBoxHeaderBounds.left,
                      top: geometry.logBoxHeaderBounds.top,
                      width: geometry.logBoxHeaderBounds.width,
                      bottom: 0,
                      child: profileRenderProbe(
                        layoutMetric: DashboardPerformanceMetric.logLayout,
                        paintMetric: DashboardPerformanceMetric.logPaint,
                        layoutDurationMetric:
                            DashboardPerformanceMetric.logLayoutMicros,
                        paintDurationMetric:
                            DashboardPerformanceMetric.logPaintMicros,
                        child: DashboardLogBoxViewport(
                          bounds: geometry.logBoxHeaderBounds,
                          visibleFrames: controller.visibleFrames,
                          preparedRasters: logBoxRasters,
                          committedViewport: controller.committedLogViewport,
                          renderCriticalPayloads:
                              controller.renderCriticalLogBoxPayloads,
                          sceneWindowProvider:
                              controller.renderCriticalLogBoxSceneWindow,
                          preparedSceneCache: _preparedSceneCache,
                          onLoadNextPage: (desiredLastReadyOrdinal) {
                            unawaited(
                              controller.requestForwardPageDemand(
                                desiredLastReadyOrdinal,
                              ),
                            );
                          },
                          onLoadPreviousPage: () {
                            unawaited(controller.loadPreviousPage());
                          },
                          onVerticalPointerDown:
                              controller.noteVerticalPointerDown,
                          onVerticalPointerIntentStarted:
                              controller.noteVerticalPointerIntentStarted,
                          onVerticalPointerIntentEnded:
                              controller.noteVerticalPointerIntentEnded,
                          onVerticalScrollStarted:
                              controller.beginVerticalInteraction,
                          onVerticalScrollEnded: controller
                              .resumeSceneWindowMaintenanceAfterVerticalInput,
                          verticalBackgroundWork: () =>
                              controller.verticalBackgroundWork,
                          performanceCounters: controller.performanceCounters,
                          renderDiagnostics:
                              controller.renderReadinessDiagnostics,
                          renderDiagnosticContextProvider: () =>
                              controller.renderDiagnosticContext,
                          onExtentPublished:
                              controller.recordLogBoxRenderExtent,
                          onCommittedScopeReset:
                              controller.recordVerticalCommittedScopeReset,
                          currentQuery: controller.currentQuery,
                          onRemoveQueryCategory:
                              controller.removeAppliedQueryCategory,
                          onRemoveQueryPartner:
                              controller.removeAppliedQueryPartner,
                          onClearQuery: controller.clearAppliedQuery,
                          focus: controller.focus,
                          onClearFocusCategory: () {
                            unawaited(controller.clearCategoryFocus());
                          },
                          onClearFocusPartner: () {
                            unawaited(controller.clearPartnerFocus());
                          },
                          onClearFocus: () {
                            unawaited(controller.clearAllEphemeralFocus());
                          },
                          onAvatarTap: (row) {
                            if (row.categoryId.isEmpty) return;
                            unawaited(
                              controller.requestCategoryFocus(
                                DashboardFocusFacet(
                                  id: row.categoryId,
                                  displayName: row.categoryDisplayName,
                                  colorId: row.categoryColorId,
                                  iconId: row.categoryIconId,
                                ),
                              ),
                            );
                          },
                          partnerSwipe: _partnerSwipe,
                          onPartnerFocus: (row) {
                            if (row.partnerId.isEmpty) {
                              return Future<bool>.value(false);
                            }
                            return controller.requestPartnerFocus(
                              DashboardFocusFacet(
                                id: row.partnerId,
                                displayName: row.partnerDisplayName,
                                colorId: row.categoryColorId,
                                iconId: row.categoryIconId,
                              ),
                            );
                          },
                          onWarmupSurfaceAttached:
                              widget.onLogBoxWarmupSurfaceAttached,
                          onWarmupSurfaceLaidOut:
                              widget.onLogBoxWarmupSurfaceLaidOut,
                          onWarmupTextLayoutsPrepared: (viewportId) {
                            controller.recordInitialSceneWindowActivation(
                              controller.renderCriticalLogBoxSceneWindow(),
                            );
                            widget.onLogBoxWarmupTextLayoutsPrepared?.call(
                              viewportId,
                            );
                          },
                          onWarmupError: widget.onLogBoxWarmupError,
                          onTextLayoutsPrepared:
                              controller.recordLogBoxTextLayoutCache,
                        ),
                      ),
                    ),
                    _FramePosition(
                      bounds: geometry.collapseHandleBounds,
                      child: DashboardCollapseHandle(
                        bounds: geometry.collapseHandleBounds,
                        isDragging: frame.isExpansionDragging,
                        onTap: controller.expansion.toggle,
                        onVerticalDragStart: (_) =>
                            controller.expansion.beginDrag(),
                        onVerticalDragUpdate: (details) =>
                            controller.expansion.dragBy(
                              geometry.mapViewportVerticalDragToController(
                                details.delta.dy,
                              ),
                            ),
                        onVerticalDragEnd: (_) =>
                            controller.expansion.endDrag(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardSummaryRegion extends StatelessWidget {
  const _DashboardSummaryRegion({
    required this.bounds,
    required this.controller,
    required this.motionController,
    required this.onMotionActiveChanged,
    required this.onAmountMotionActiveChanged,
  });

  final DashboardBounds bounds;
  final DashboardCoreController controller;
  final SummaryNavigationMotionController motionController;
  final ValueChanged<bool> onMotionActiveChanged;
  final ValueChanged<bool> onAmountMotionActiveChanged;

  @override
  Widget build(BuildContext context) {
    return DashboardSummaryPill(
      bounds: bounds,
      navigation: controller.navigation,
      visibleFrames: controller.visibleFrames,
      navigationMotionController: motionController,
      onMotionActiveChanged: onMotionActiveChanged,
      onAmountMotionActiveChanged: onAmountMotionActiveChanged,
      horizontalCandidateBuilder: _horizontalCandidate,
      performanceCounters: controller.performanceCounters,
      onToggleRail: controller.toggleRail,
      onMoveFiner: () {
        controller.navigatePlane(finer: true);
      },
      onMoveBroader: () {
        controller.navigatePlane(finer: false);
      },
      onMovePrevious: () {
        unawaited(
          controller.navigateParent(
            DashboardTimeNavigationChangeDirection.backward,
          ),
        );
      },
      onMoveNext: () {
        unawaited(
          controller.navigateParent(
            DashboardTimeNavigationChangeDirection.forward,
          ),
        );
      },
    );
  }

  SummaryTextContent? _horizontalCandidate(
    SummaryTransitionDirection direction,
  ) {
    final preview = controller.previewParent(
      direction == SummaryTransitionDirection.forward
          ? DashboardTimeNavigationChangeDirection.forward
          : DashboardTimeNavigationChangeDirection.backward,
    );
    if (preview == null) return null;
    final presentation = SummaryNavigationProjector.project(preview);
    return SummaryTextContent(
      title: presentation.planeTitle,
      subtitle: presentation.subtitle,
    );
  }
}

class _FramePosition extends StatelessWidget {
  const _FramePosition({required this.bounds, required this.child});

  final DashboardBounds bounds;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: child,
    );
  }
}
