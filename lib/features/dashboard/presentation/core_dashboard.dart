import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/header_cascade_motion.dart';
import '../../../core/motion/dashboard_motion_host.dart';
import '../application/dashboard_core_controller.dart';
import '../application/dashboard_mode_spec.dart';
import '../application/transaction_direction_controller.dart';
import 'summary_navigation_motion_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/presentation/summary_pill_presenter.dart';
import '../time_navigation/presentation/summary_navigation_presentation.dart';
import 'widgets/dashboard_collapse_handle.dart';
import 'widgets/dashboard_placeholder_card.dart';
import 'widgets/dashboard_summary_pill.dart';
import 'widgets/fluvi_brand_lockup.dart';
import 'widgets/summary_pill_text_transition.dart';
import 'widgets/transaction_direction_toggle.dart';
import '../logbox/presentation/dashboard_log_area.dart';

/// One bounds-driven dashboard renderer shared by every dashboard mode.
class CoreDashboard extends StatefulWidget {
  const CoreDashboard({
    super.key,
    required this.mode,
    required this.controller,
  });

  final DashboardModeSpec mode;
  final DashboardCoreController controller;

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
  }

  @override
  void dispose() {
    _summaryMotionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        return ColoredBox(
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
                    child: FluviBrandLockup(bounds: geometry.brandLockupBounds),
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
                          frame.selectedDirection == TransactionDirection.income
                          ? 'Bevétel'
                          : 'Kiadás',
                      child: TransactionDirectionToggle(
                        bounds: geometry.actionBounds,
                        palette: frame.palette,
                        selectedDirection: frame.selectedDirection,
                        incomeIconScale: frame.incomeIconScale,
                        expenseIconScale: frame.expenseIconScale,
                        onSelected: controller.transactionDirection.select,
                      ),
                    ),
                  ),
                  _FramePosition(
                    bounds: geometry.summaryBounds,
                    child: _DashboardSummaryRegion(
                      bounds: geometry.summaryBounds,
                      controller: controller,
                      motionController: _summaryMotionController,
                    ),
                  ),
                  _FramePosition(
                    bounds: geometry.railBounds,
                    child: Opacity(
                      opacity: frame.railReveal,
                      child: IgnorePointer(
                        ignoring: !geometry.isRailExpanded,
                        child: TimeRefinementRail(
                          bounds: geometry.railBounds,
                          controller: controller.rail,
                          onPreviewLogicalIndexChanged: (oldIndex, newIndex) =>
                              _summaryMotionController.triggerRailTick(
                                oldLogicalIndex: oldIndex,
                                newLogicalIndex: newIndex,
                              ),
                          onMotionBaselineEstablished:
                              _summaryMotionController.resetRailTickBaseline,
                          onMotionTargetLogicalIndexResolved:
                              controller.prefetchLogForRailTarget,
                        ),
                      ),
                    ),
                  ),
                  _FramePosition(
                    bounds: DashboardBounds(
                      left: geometry.logBoxHeaderBounds.left,
                      top: geometry.logBoxHeaderBounds.top,
                      width: geometry.logBoxHeaderBounds.width,
                      height: (layoutMetrics.canvasHeight -
                              geometry.logBoxHeaderBounds.top)
                          .clamp(0.0, layoutMetrics.canvasHeight)
                          .toDouble(),
                    ),
                    child: _DashboardLogBoxRegion(controller: controller),
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
                      onVerticalDragEnd: (_) => controller.expansion.endDrag(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Rebuild boundary for only the committed, vertically lazy LogBox area.
/// Child-rail preview state never reaches this subtree.
class _DashboardLogBoxRegion extends StatelessWidget {
  const _DashboardLogBoxRegion({required this.controller});

  final DashboardCoreController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.logBox,
      builder: (context, _) => DashboardLogArea(
        state: controller.logBox.state,
        onLoadNextPage: controller.logBox.loadNextPage,
        onRetry: controller.logBox.retry,
        // Entry routing is intentionally outside the read/presentation path;
        // the current dashboard has no entry-details destination yet.
        onEntryTap: (_) {},
      ),
    );
  }
}

/// Keeps child-rail preview rebuilds scoped to the navigation text. The
/// aggregate motion host observes only committed dashboard changes, so the
/// shared carousel can keep its own scroll/render lifecycle during a fling.
class _DashboardSummaryRegion extends StatelessWidget {
  const _DashboardSummaryRegion({
    required this.bounds,
    required this.controller,
    required this.motionController,
  });

  final DashboardBounds bounds;
  final DashboardCoreController controller;
  final SummaryNavigationMotionController motionController;

  @override
  Widget build(BuildContext context) {
    return DashboardSummaryPill(
      bounds: bounds,
      navigationPresentation: _navigationPresentation(),
      navigationListenable: controller.rail,
      navigationPresentationBuilder: _navigationPresentation,
      navigationMotionController: motionController,
      horizontalCandidateBuilder: _horizontalCandidate,
      metricsListenable: controller.summaryMetrics,
      metricsPresentationBuilder: () => controller.summaryMetrics.presentation,
      onToggleRail: controller.rail.toggle,
      onMoveFiner: controller.rail.moveToFinerPlane,
      onMoveBroader: controller.rail.moveToBroaderPlane,
      onMovePrevious: controller.rail.moveParentPrevious,
      onMoveNext: controller.rail.moveParentNext,
    );
  }

  SummaryNavigationPresentation _navigationPresentation() =>
      SummaryPillPresenter.presentNavigation(navigation: controller.rail.state);

  SummaryTextContent? _horizontalCandidate(
    SummaryTransitionDirection direction,
  ) {
    final preview = controller.rail.parentPreview(
      direction == SummaryTransitionDirection.forward
          ? DashboardTimeNavigationChangeDirection.forward
          : DashboardTimeNavigationChangeDirection.backward,
    );
    if (preview == null) return null;
    final presentation = SummaryPillPresenter.presentNavigation(
      navigation: preview,
    );
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
