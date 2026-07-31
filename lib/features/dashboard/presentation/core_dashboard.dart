import 'package:flutter/material.dart';

import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/motion/dashboard_motion_host.dart';
import '../application/dashboard_core_controller.dart';
import '../application/dashboard_mode_spec.dart';
import '../application/transaction_direction_controller.dart';
import 'widgets/dashboard_collapse_handle.dart';
import 'widgets/dashboard_placeholder_card.dart';
import 'widgets/dashboard_search_filter.dart';
import 'widgets/dashboard_summary_pill.dart';
import 'widgets/fluvi_brand_lockup.dart';
import 'widgets/time_refinement_rail.dart';
import 'widgets/transaction_direction_toggle.dart';

/// One bounds-driven dashboard renderer shared by every dashboard mode.
class CoreDashboard extends StatelessWidget {
  const CoreDashboard({
    super.key,
    required this.mode,
    required this.controller,
  });

  final DashboardModeSpec mode;
  final DashboardCoreController controller;

  @override
  Widget build(BuildContext context) {
    return DashboardMotionHost(
      controller: controller,
      mode: mode,
      builder: (context, frame) {
        final geometry = frame.geometry;
        return ColoredBox(
          key: const ValueKey('core-dashboard'),
          color: frame.palette.pageBackground,
          child: SizedBox.expand(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _FramePosition(
                  bounds: geometry.brandLockupBounds,
                  child: FluviBrandLockup(bounds: geometry.brandLockupBounds),
                ),
                _FramePosition(
                  bounds: geometry.headerBounds,
                  child: DashboardPlaceholderCard(
                    bounds: geometry.headerBounds,
                    semanticKey: const ValueKey('dashboard-header-card'),
                    surfaceColor: frame.palette.upcomingHeaderTone,
                  ),
                ),
                if (geometry.mode.subheaderComposition ==
                    DashboardSubheaderComposition.split) ...[
                  _FrameOpacityPosition(
                    bounds: geometry.subheaderOneBounds,
                    opacity: geometry.subheaderOneOpacity,
                    child: DashboardPlaceholderCard(
                      bounds: geometry.subheaderOneBounds,
                      semanticKey: const ValueKey(
                        'dashboard-split-subheader-one',
                      ),
                    ),
                  ),
                  _FrameOpacityPosition(
                    bounds: geometry.zone2Bounds,
                    opacity: geometry.zone2Opacity,
                    child: DashboardPlaceholderCard(
                      bounds: geometry.zone2Bounds,
                      semanticKey: const ValueKey('dashboard-split-zone2'),
                    ),
                  ),
                ] else
                  _FrameOpacityPosition(
                    bounds: geometry.unifiedSubheaderBounds!,
                    opacity: geometry.zone2Opacity,
                    child: DashboardPlaceholderCard(
                      bounds: geometry.unifiedSubheaderBounds!,
                      semanticKey: const ValueKey(
                        'dashboard-unified-subheader',
                      ),
                    ),
                  ),
                _FrameOpacityPosition(
                  bounds: geometry.zone2IndicatorBounds,
                  opacity: geometry.zone2Opacity,
                  child: DashboardPlaceholderDots(
                    bounds: geometry.zone2IndicatorBounds,
                  ),
                ),
                _HeaderGestureRegion(
                  bounds: geometry.headerGestureBounds,
                  onDragStart: controller.expansion.beginDrag,
                  onDragUpdate: (viewportDelta) => controller.expansion.dragBy(
                    geometry.mapViewportVerticalDragToController(viewportDelta),
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
                  child: DashboardSummaryPill(
                    bounds: geometry.summaryBounds,
                    isRailVisible: geometry.isRailExpanded,
                    onChevronTap: controller.rail.toggle,
                  ),
                ),
                _FramePosition(
                  bounds: geometry.searchBounds,
                  child: DashboardSearchFilter(bounds: geometry.searchBounds),
                ),
                _FramePosition(
                  bounds: geometry.railBounds,
                  child: Opacity(
                    opacity: frame.railReveal,
                    child: IgnorePointer(
                      ignoring: !geometry.isRailExpanded,
                      child: TimeRefinementRail(bounds: geometry.railBounds),
                    ),
                  ),
                ),
                _FramePosition(
                  bounds: geometry.collapseHandleBounds,
                  child: DashboardCollapseHandle(
                    bounds: geometry.collapseHandleBounds,
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
        );
      },
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

class _FrameOpacityPosition extends StatelessWidget {
  const _FrameOpacityPosition({
    required this.bounds,
    required this.opacity,
    required this.child,
  });

  final DashboardBounds bounds;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _FramePosition(
      bounds: bounds,
      child: Opacity(opacity: opacity, child: child),
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
