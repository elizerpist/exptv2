import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

import '../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/header_cascade_motion.dart';
import '../../../core/motion/dashboard_motion_host.dart';
import '../application/dashboard_core_controller.dart';
import '../application/dashboard_mode_spec.dart';
import '../application/dashboard_performance_counters.dart';
import 'widgets/dashboard_logbox_render_surface.dart';
import '../application/transaction_direction_controller.dart';
import 'summary_navigation_motion_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/presentation/summary_navigation_presentation.dart';
import 'widgets/dashboard_collapse_handle.dart';
import 'widgets/dashboard_logbox_viewport.dart';
import 'widgets/dashboard_placeholder_card.dart';
import 'widgets/dashboard_render_phase_probe.dart';
import 'widgets/dashboard_summary_pill.dart';
import 'widgets/fluvi_brand_lockup.dart';
import 'widgets/summary_pill_text_transition.dart';
import 'widgets/transaction_direction_toggle.dart';

/// One bounds-driven dashboard renderer shared by every dashboard mode.
class CoreDashboard extends StatefulWidget {
  const CoreDashboard({
    super.key,
    required this.mode,
    required this.controller,
    this.preparedLogBoxRasters,
    this.onLogBoxWarmupSurfaceAttached,
    this.onLogBoxWarmupSurfaceLaidOut,
    this.onLogBoxWarmupTextLayoutsPrepared,
    this.onLogBoxWarmupError,
  });

  final DashboardModeSpec mode;
  final DashboardCoreController controller;
  final PreparedLogBoxRasterSet? preparedLogBoxRasters;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupSurfaceAttached;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupSurfaceLaidOut;
  final DashboardLogBoxWarmupTaskCallback? onLogBoxWarmupTextLayoutsPrepared;
  final DashboardLogBoxWarmupErrorCallback? onLogBoxWarmupError;

  @override
  State<CoreDashboard> createState() => _CoreDashboardState();
}

class _CoreDashboardState extends State<CoreDashboard> {
  late final SummaryNavigationMotionController _summaryMotionController;

  DashboardModeSpec get mode => widget.mode;
  DashboardCoreController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _summaryMotionController = SummaryNavigationMotionController();
    _summaryMotionController.addListener(_onSummaryTextMotionChanged);
  }

  void _onSummaryTextMotionChanged() {
    controller.setMotionLaneActive(
      DashboardMotionLane.summaryText,
      _summaryMotionController.stagedText.isAxisMotionActive,
    );
  }

  @override
  void dispose() {
    controller.setMotionLaneActive(DashboardMotionLane.summaryShell, false);
    controller.setMotionLaneActive(DashboardMotionLane.summaryText, false);
    _summaryMotionController.removeListener(_onSummaryTextMotionChanged);
    _summaryMotionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      mode: mode,
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
                    if (geometry.mode.subheaderComposition ==
                        DashboardSubheaderComposition.split) ...[
                      _CascadeCardPosition(
                        bounds: geometry.zone2Bounds,
                        motion: geometry.lowerCardMotion!,
                        child: DashboardPlaceholderCard(
                          bounds: geometry.zone2Bounds,
                          fillParent: true,
                          semanticKey: const ValueKey('dashboard-split-zone2'),
                        ),
                      ),
                      _CascadeCardPosition(
                        bounds: geometry.subheaderOneBounds,
                        motion: geometry.upperCardMotion!,
                        child: DashboardPlaceholderCard(
                          bounds: geometry.subheaderOneBounds,
                          fillParent: true,
                          semanticKey: const ValueKey(
                            'dashboard-split-subheader-one',
                          ),
                        ),
                      ),
                      _FramePosition(
                        bounds: geometry.headerBounds,
                        child: DashboardPlaceholderCard(
                          bounds: geometry.headerBounds,
                          semanticKey: const ValueKey('dashboard-header-card'),
                          surfaceColor: frame.palette.upcomingHeaderTone,
                        ),
                      ),
                    ] else ...[
                      _FramePosition(
                        bounds: geometry.headerBounds,
                        child: DashboardPlaceholderCard(
                          bounds: geometry.headerBounds,
                          semanticKey: const ValueKey('dashboard-header-card'),
                          surfaceColor: frame.palette.upcomingHeaderTone,
                        ),
                      ),
                      _FrameOpacityPosition(
                        bounds: geometry.unifiedSubheaderBounds!,
                        opacity: geometry.zone2Opacity,
                        offset: Offset(0, geometry.zone2Shift),
                        scale: geometry.zone2Scale,
                        child: DashboardPlaceholderCard(
                          bounds: geometry.unifiedSubheaderBounds!,
                          semanticKey: const ValueKey(
                            'dashboard-unified-subheader',
                          ),
                        ),
                      ),
                    ],
                    _FrameOpacityPosition(
                      bounds: geometry.zone2IndicatorBounds,
                      opacity: geometry.zone2Opacity,
                      offset: Offset(0, geometry.zone2Shift),
                      child: DashboardPlaceholderDots(
                        bounds: geometry.zone2IndicatorBounds,
                      ),
                    ),
                    _HeaderGestureRegion(
                      bounds: geometry.headerGestureBounds,
                      onDragStart: controller.expansion.beginDrag,
                      onDragUpdate: (viewportDelta) =>
                          controller.expansion.dragBy(
                            geometry.mapViewportVerticalDragToController(
                              viewportDelta,
                            ),
                          ),
                      onDragEnd: controller.expansion.endDrag,
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
                          renderCriticalPayloads:
                              controller.renderCriticalLogBoxPayloads,
                          onLoadNextPage: () {
                            unawaited(controller.loadNextPage());
                          },
                          performanceCounters: controller.performanceCounters,
                          renderDiagnostics:
                              controller.renderReadinessDiagnostics,
                          renderDiagnosticContextProvider: () =>
                              controller.renderDiagnosticContext,
                          onWarmupSurfaceAttached:
                              widget.onLogBoxWarmupSurfaceAttached,
                          onWarmupSurfaceLaidOut:
                              widget.onLogBoxWarmupSurfaceLaidOut,
                          onWarmupTextLayoutsPrepared:
                              widget.onLogBoxWarmupTextLayoutsPrepared,
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
        controller.navigateParent(
          DashboardTimeNavigationChangeDirection.backward,
        );
      },
      onMoveNext: () {
        controller.navigateParent(
          DashboardTimeNavigationChangeDirection.forward,
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

class _CascadeCardPosition extends StatelessWidget {
  const _CascadeCardPosition({
    required this.bounds,
    required this.motion,
    required this.child,
  });

  final DashboardBounds bounds;
  final CascadedCardMotion motion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: motion.left,
      right: motion.right,
      top: motion.top,
      height: bounds.height,
      child: IgnorePointer(
        ignoring: motion.progress < .98,
        child: Opacity(
          opacity: motion.opacity,
          child: Transform.scale(
            scale: motion.scale,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _FrameOpacityPosition extends StatelessWidget {
  const _FrameOpacityPosition({
    required this.bounds,
    required this.opacity,
    required this.child,
    this.offset = Offset.zero,
    this.scale = 1,
  });

  final DashboardBounds bounds;
  final double opacity;
  final Widget child;
  final Offset offset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return _FramePosition(
      bounds: bounds,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _HeaderGestureRegion extends StatelessWidget {
  const _HeaderGestureRegion({
    required this.bounds,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final DashboardBounds bounds;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: GestureDetector(
        key: const ValueKey('dashboard-header-gesture-region'),
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) => onDragStart(),
        onVerticalDragUpdate: (details) => onDragUpdate(details.delta.dy),
        onVerticalDragEnd: (_) => onDragEnd(),
      ),
    );
  }
}
