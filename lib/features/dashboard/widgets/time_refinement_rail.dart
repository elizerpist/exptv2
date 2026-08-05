import 'package:flutter/material.dart';

import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_rounded_box.dart';
import '../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../application/dashboard_performance_counters.dart';
import '../motion/dashboard_motion_kernel.dart';
import '../motion/dashboard_semantic_catalog.dart';

/// Rendering adapter for the data-independent dashboard Motion Kernel.
///
/// The immutable semantic catalog already contains every label, semantic
/// identity and QueryKey. A crossing performs only the kernel's O(1) catalog
/// lookup; this widget never observes a visible/data notifier.
final class TimeRefinementRail extends StatefulWidget {
  const TimeRefinementRail({
    super.key,
    required this.bounds,
    required this.motion,
    this.onPreviewLogicalIndexChanged,
    this.onMotionBaselineEstablished,
    this.onMotionStarted,
    this.performanceCounters,
  });

  final DashboardBounds bounds;
  final DashboardMotionKernel motion;
  final void Function(int oldLogicalIndex, int newLogicalIndex)?
  onPreviewLogicalIndexChanged;
  final ValueChanged<int>? onMotionBaselineEstablished;
  final ValueChanged<CenteredCarouselMotionOrigin>? onMotionStarted;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  State<TimeRefinementRail> createState() => _TimeRefinementRailState();
}

final class _TimeRefinementRailState extends State<TimeRefinementRail> {
  int? _lastMotionLogicalIndex;
  DashboardSemanticCatalog? _catalogIdentity;
  Object? _controllerIdentity;
  Object? _physicsIdentity;
  Object? _scrollPositionIdentity;

  @override
  void didUpdateWidget(covariant TimeRefinementRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.motion, widget.motion)) {
      _lastMotionLogicalIndex = null;
      _catalogIdentity = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.performanceCounters?.increment(
      DashboardPerformanceMetric.railSubtreeBuild,
    );
    final tileWidth = AppSelectorMetrics.compactTileWidthForViewport(
      widget.bounds.width,
    );
    final itemExtent = tileWidth + AppSelectorMetrics.carouselGap;
    final catalog = widget.motion.catalog;
    _synchronizeBaseline(catalog);
    _captureMotionIdentities();

    return RepaintBoundary(
      child: SizedBox(
        width: widget.bounds.width,
        height: widget.bounds.height,
        child: CenteredCarousel<DashboardSemanticEntry>(
          key: const ValueKey('dashboard-time-rail'),
          dataSource: catalog,
          controller: widget.motion.carouselController,
          spec: CenteredCarouselPresets.timeRail(
            itemExtent: itemExtent,
            viewportTrailingGap: AppSelectorMetrics.carouselGap,
            selectorHeight: AppSelectorMetrics.yearTileHeight,
            selectorRadius: AppSelectorMetrics.compactTileRadius,
          ),
          height: widget.bounds.height,
          semanticsLabelBuilder: (entry) => entry.semanticLabel,
          onPreviewChanged: _semanticCrossed,
          onSelectionSettled: widget.motion.settled,
          onMotionStarted: _motionStarted,
          itemBuilder: (context, entry, metrics) => SizedBox(
            width: tileWidth,
            height: AppSelectorMetrics.yearTileHeight,
            child: FluviRoundedBox(
              key: ValueKey(entry.semanticIdentity),
              color: metrics.isSelected ? null : FluviVisualTokens.surface,
              gradient: metrics.isSelected
                  ? FluviVisualTokens.appHighlightGradient
                  : null,
              border: metrics.isSelected
                  ? null
                  : const Border.fromBorderSide(
                      BorderSide(
                        color: FluviVisualTokens.border,
                        width: B3mReferenceMetrics.borderWidth,
                      ),
                    ),
              boxShadow: const [],
              borderRadius: BorderRadius.circular(
                AppSelectorMetrics.compactTileRadius,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: tileWidth - 16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                        style: metrics.isSelected
                            ? FluviVisualTokens.railActiveTextStyle
                            : FluviVisualTokens.railTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _semanticCrossed(int logicalIndex) {
    final previous = _lastMotionLogicalIndex;
    _lastMotionLogicalIndex = logicalIndex;
    if (previous != null && previous != logicalIndex) {
      widget.onPreviewLogicalIndexChanged?.call(previous, logicalIndex);
    }
    widget.motion.semanticCrossed(logicalIndex);
  }

  void _motionStarted(CenteredCarouselMotionOrigin origin) {
    widget.onMotionStarted?.call(origin);
  }

  void _synchronizeBaseline(DashboardSemanticCatalog catalog) {
    if (identical(catalog, _catalogIdentity)) return;
    _catalogIdentity = catalog;
    final logicalIndex = widget.motion.state.semanticIndex;
    _lastMotionLogicalIndex = logicalIndex;
    widget.onMotionBaselineEstablished?.call(logicalIndex);
  }

  void _captureMotionIdentities() {
    final controller = widget.motion.carouselController;
    final previousController = _controllerIdentity;
    if (previousController != null &&
        !identical(previousController, controller)) {
      widget.performanceCounters?.increment(
        DashboardPerformanceMetric.controllerRecreation,
      );
    }
    _controllerIdentity = controller;

    final physics = widget.motion.dashboardPhysics;
    final previousPhysics = _physicsIdentity;
    if (previousPhysics != null && !identical(previousPhysics, physics)) {
      widget.performanceCounters?.increment(
        DashboardPerformanceMetric.physicsRecreation,
      );
    }
    _physicsIdentity = physics;

    if (!controller.scrollController.hasClients) return;
    final position = controller.scrollController.position;
    final previousPosition = _scrollPositionIdentity;
    if (previousPosition != null && !identical(previousPosition, position)) {
      widget.performanceCounters?.increment(
        DashboardPerformanceMetric.scrollPositionRecreation,
      );
    }
    _scrollPositionIdentity = position;
  }
}
