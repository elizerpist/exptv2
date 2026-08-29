import 'package:flutter/material.dart';

import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_rounded_box.dart';
import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
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
    this.motionDiagnostics,
  });

  final DashboardBounds bounds;
  final DashboardMotionKernel motion;
  final void Function(int oldLogicalIndex, int newLogicalIndex)?
  onPreviewLogicalIndexChanged;
  final ValueChanged<int>? onMotionBaselineEstablished;
  final ValueChanged<CenteredCarouselMotionOrigin>? onMotionStarted;
  final DashboardPerformanceCounters? performanceCounters;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;

  @override
  State<TimeRefinementRail> createState() => _TimeRefinementRailState();
}

final class _TimeRefinementRailState extends State<TimeRefinementRail> {
  int? _lastMotionLogicalIndex;
  int? _lastSemanticReconciliationEpoch;
  int? _lastSettledDiagnosticMotionEpoch;
  int? _lastSettledDiagnosticLogicalIndex;
  DashboardSemanticCatalog? _catalogIdentity;
  Object? _controllerIdentity;
  Object? _physicsIdentity;
  Object? _scrollPositionIdentity;

  @override
  void initState() {
    super.initState();
    widget.motion.addListener(_onMotionChanged);
  }

  @override
  void didUpdateWidget(covariant TimeRefinementRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.motion, widget.motion)) {
      oldWidget.motion.removeListener(_onMotionChanged);
      widget.motion.addListener(_onMotionChanged);
      _lastMotionLogicalIndex = null;
      _lastSemanticReconciliationEpoch = null;
      _lastSettledDiagnosticMotionEpoch = null;
      _lastSettledDiagnosticLogicalIndex = null;
      _catalogIdentity = null;
    }
  }

  @override
  void dispose() {
    widget.motion.removeListener(_onMotionChanged);
    super.dispose();
  }

  void _onMotionChanged() {
    // Normal drag/ballistic samples belong exclusively to CenteredCarousel.
    // Only a structural reconcile needs this adapter to re-establish its local
    // crossing baseline when the catalog object itself has not changed.
    if (!mounted ||
        widget.motion.semanticReconciliationEpoch ==
            _lastSemanticReconciliationEpoch) {
      return;
    }
    setState(() {});
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
          onSelectionSettled: _settled,
          onMotionStarted: _motionStarted,
          motionDiagnostics: widget.motionDiagnostics,
          itemBuilder: (context, entry, metrics) {
            widget.performanceCounters?.increment(
              DashboardPerformanceMetric.railItemBuild,
            );
            return SizedBox(
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
            );
          },
        ),
      ),
    );
  }

  void _semanticCrossed(int logicalIndex) {
    final previous = _lastMotionLogicalIndex;
    _lastMotionLogicalIndex = logicalIndex;
    if (previous != null && previous != logicalIndex) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'TM|FLING_SEMANTIC_CROSSING',
          scope:
              'fromLogicalIndex=$previous toLogicalIndex=$logicalIndex '
              'motionActivity=${widget.motion.state.activity.name} '
              'motionEpoch=${widget.motion.state.motionEpoch}',
        ),
      );
      widget.onPreviewLogicalIndexChanged?.call(previous, logicalIndex);
    }
    widget.motion.semanticCrossed(logicalIndex);
  }

  void _motionStarted(CenteredCarouselMotionOrigin origin) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'TM|FLING_STARTED',
        scope:
            'origin=${origin.name} '
            'logicalIndex=${widget.motion.state.semanticIndex} '
            'motionEpoch=${widget.motion.state.motionEpoch}',
      ),
    );
    widget.onMotionStarted?.call(origin);
  }

  void _settled(int logicalIndex) {
    // CenteredCarousel owns physical settling. Record the semantic boundary
    // immediately after the kernel accepts it so a bounded on-screen capture
    // can distinguish a smooth flight from a stalled or duplicate commit.
    widget.motion.settled(logicalIndex);
    final state = widget.motion.state;
    if (_lastSettledDiagnosticMotionEpoch == state.motionEpoch &&
        _lastSettledDiagnosticLogicalIndex == logicalIndex) {
      return;
    }
    _lastSettledDiagnosticMotionEpoch = state.motionEpoch;
    _lastSettledDiagnosticLogicalIndex = logicalIndex;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'TM|FLING_SETTLED',
        scope:
            'logicalIndex=$logicalIndex '
            'semanticIndex=${state.semanticIndex} '
            'motionActivity=${state.activity.name} '
            'motionEpoch=${state.motionEpoch}',
      ),
    );
  }

  void _synchronizeBaseline(DashboardSemanticCatalog catalog) {
    final reconciliationEpoch = widget.motion.semanticReconciliationEpoch;
    if (identical(catalog, _catalogIdentity) &&
        reconciliationEpoch == _lastSemanticReconciliationEpoch) {
      return;
    }
    _catalogIdentity = catalog;
    _lastSemanticReconciliationEpoch = reconciliationEpoch;
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
