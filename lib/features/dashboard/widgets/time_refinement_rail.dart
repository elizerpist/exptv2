import 'package:flutter/material.dart';

import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_rounded_box.dart';
import '../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../query/application/dashboard_motion_trace.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/application/summary_timing_debug.dart';
import '../time_navigation/domain/time_plane.dart';
import '../time_navigation/presentation/time_label_formatter.dart';

/// Dashboard adapter for the generic centered motion engine.
class TimeRefinementRail extends StatefulWidget {
  const TimeRefinementRail({
    super.key,
    required this.bounds,
    required this.controller,
    this.onPreviewLogicalIndexChanged,
    this.onMotionBaselineEstablished,
    this.onMotionStarted,
    this.onMotionIdle,
    this.onMotionSettled,
  });

  final DashboardBounds bounds;
  final DashboardTimeNavigationController controller;

  /// Paint-only observer of a real nearest-index tick. The adapter never
  /// waits for this callback and it has no query or haptic side effects.
  final void Function(int oldLogicalIndex, int newLogicalIndex)?
  onPreviewLogicalIndexChanged;

  /// Establishes the matching presentation-motion baseline when the rail is
  /// silently configured, rebased or recentered. It never represents a tick.
  final ValueChanged<int>? onMotionBaselineEstablished;

  final ValueChanged<CenteredCarouselMotionOrigin>? onMotionStarted;
  final ValueChanged<int>? onMotionIdle;
  final bool Function(int logicalIndex)? onMotionSettled;

  @override
  State<TimeRefinementRail> createState() => _TimeRefinementRailState();
}

class _TimeRefinementRailState extends State<TimeRefinementRail> {
  int? _lastMotionLogicalIndex;
  _RailMotionSource? _motionSource;
  int? _activeMotionDeckEpoch;
  LedgerTimeScope? _activeMotionParentScope;

  @override
  void didUpdateWidget(covariant TimeRefinementRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _lastMotionLogicalIndex = null;
      _motionSource = null;
      _activeMotionDeckEpoch = null;
      _activeMotionParentScope = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileWidth = AppSelectorMetrics.compactTileWidthForViewport(
      widget.bounds.width,
    );
    final itemExtent = tileWidth + AppSelectorMetrics.carouselGap;
    final state = widget.controller.state;
    final plane = state.plane;
    _syncMotionBaseline(state);

    return SizedBox(
      width: widget.bounds.width,
      height: widget.bounds.height,
      child: CenteredCarousel<int>(
        key: const ValueKey('dashboard-time-rail'),
        dataSource: widget.controller.childDataSource,
        controller: widget.controller.timeCarousel,
        spec: CenteredCarouselPresets.timeRail(
          itemExtent: itemExtent,
          viewportTrailingGap: AppSelectorMetrics.carouselGap,
          selectorHeight: AppSelectorMetrics.yearTileHeight,
          selectorRadius: AppSelectorMetrics.compactTileRadius,
        ),
        height: widget.bounds.height,
        semanticsLabelBuilder: (value) => _semanticsLabel(plane, value),
        onPreviewChanged: _queuePreview,
        onSelectionSettled: _settleSelection,
        onMotionStarted: _startMotion,
        onMotionIdle: widget.onMotionIdle,
        itemBuilder: (context, label, metrics) {
          return SizedBox(
            width: tileWidth,
            height: AppSelectorMetrics.yearTileHeight,
            child: FluviRoundedBox(
              key: const ValueKey('fluvi-time-box'),
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
              // The rail is transparent and its tiles sit directly on the
              // dashboard background. A card shadow here would be clipped by
              // the horizontal carousel viewport and create a false window
              // edge around the rail.
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
                        TimeRailLabelFormatter.labelFor(plane, label),
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
    );
  }

  /// Preview projection is deliberately synchronous and memory-only. The
  /// shared carousel remains the motion owner; this callback only selects the
  /// already prepared child snapshot so amount/count/log presentation can be
  /// correct in the same frame as the centered tile.
  void _queuePreview(int logicalIndex) {
    DashboardMotionTrace.record(
      eventId: DashboardMotionEventId.previewCentered,
      physicalIndex: widget.controller.timeCarousel.selectedPhysicalIndex,
      logicalIndex: logicalIndex,
    );
    DashboardSummaryTimingDebug.mark(
      'R1 TARGET_VISUALLY_CENTERED',
      value: logicalIndex,
    );
    final previousLogicalIndex = _lastMotionLogicalIndex;
    _lastMotionLogicalIndex = logicalIndex;
    if (previousLogicalIndex != null && previousLogicalIndex != logicalIndex) {
      widget.onPreviewLogicalIndexChanged?.call(
        previousLogicalIndex,
        logicalIndex,
      );
    }
    widget.controller.previewChildLogicalIndex(logicalIndex);
  }

  void _settleSelection(int logicalIndex) {
    if (widget.onMotionSettled?.call(logicalIndex) == false) return;
    final deckEpoch = _activeMotionDeckEpoch;
    final parentScope = _activeMotionParentScope;
    if (deckEpoch != null && parentScope != null) {
      final accepted = widget.controller.settleChildLogicalIndexIfCurrent(
        logicalIndex,
        deckEpoch: deckEpoch,
        parentScope: parentScope,
      );
      if (!accepted) return;
    } else {
      widget.controller.settleChildLogicalIndex(logicalIndex);
    }
    DashboardMotionTrace.record(
      eventId: DashboardMotionEventId.semanticSettle,
      physicalIndex: widget.controller.timeCarousel.selectedPhysicalIndex,
      logicalIndex: logicalIndex,
    );
  }

  void _startMotion(CenteredCarouselMotionOrigin origin) {
    final state = widget.controller.state;
    _activeMotionDeckEpoch = state.deckEpoch;
    _activeMotionParentScope = state.parentScope;
    widget.onMotionStarted?.call(origin);
  }

  /// Initial layout, plane/parent reconfiguration and silent carousel
  /// recentering establish a new baseline. None are user-visible rail ticks.
  void _syncMotionBaseline(DashboardTimeNavigationState state) {
    final source = _RailMotionSource(
      plane: state.plane,
      parentScope: state.parentScope,
      isRailOpen: state.isRailOpen,
    );
    if (source == _motionSource) return;
    _motionSource = source;
    if (_activeMotionDeckEpoch == null) {
      _activeMotionDeckEpoch = state.deckEpoch;
      _activeMotionParentScope = state.parentScope;
    }
    final logicalIndex = widget.controller.selectedChildLogicalIndex;
    _lastMotionLogicalIndex = logicalIndex;
    DashboardMotionTrace.record(
      eventId: DashboardMotionEventId.baselineEstablished,
      physicalIndex: widget.controller.timeCarousel.selectedPhysicalIndex,
      logicalIndex: logicalIndex,
    );
    widget.onMotionBaselineEstablished?.call(logicalIndex);
  }
}

@immutable
class _RailMotionSource {
  const _RailMotionSource({
    required this.plane,
    required this.parentScope,
    required this.isRailOpen,
  });

  final TimePlane plane;
  final Object parentScope;
  final bool isRailOpen;

  @override
  bool operator ==(Object other) =>
      other is _RailMotionSource &&
      other.plane == plane &&
      other.parentScope == parentScope &&
      other.isRailOpen == isRailOpen;

  @override
  int get hashCode => Object.hash(plane, parentScope, isRailOpen);
}

abstract final class TimeRailLabelFormatter {
  static String labelFor(TimePlane plane, int value) => switch (plane) {
    TimePlane.sum => value.toString(),
    TimePlane.year => DashboardTimeLabelFormatter.monthName(value),
    TimePlane.month => value.toString(),
  };

  static String monthName(int month) =>
      DashboardTimeLabelFormatter.monthName(month);
}

String _semanticsLabel(TimePlane plane, int value) => switch (plane) {
  TimePlane.sum => 'Év $value',
  TimePlane.year => 'Hónap ${DashboardTimeLabelFormatter.monthName(value)}',
  TimePlane.month => 'Nap $value',
};
