import 'package:flutter/material.dart';

import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_rounded_box.dart';
import '../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
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

  @override
  State<TimeRefinementRail> createState() => _TimeRefinementRailState();
}

class _TimeRefinementRailState extends State<TimeRefinementRail> {
  bool _acceptsMotionCallbacks = false;
  bool _hasAcceptedUserMotion = false;
  int? _lastMotionLogicalIndex;
  _RailMotionSource? _motionSource;

  @override
  void didUpdateWidget(covariant TimeRefinementRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _acceptsMotionCallbacks = false;
      _hasAcceptedUserMotion = false;
      _lastMotionLogicalIndex = null;
      _motionSource = null;
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

    // A closed rail must not mount the physical carousel viewport. Mounting
    // it is enough for the shared motor to establish its initial/rebased
    // position, even though the dashboard has neither shown nor accepted a
    // child selection. Keep that lifecycle boundary in this adapter instead
    // of changing the shared motion engine.
    if (!state.isRailOpen) {
      return SizedBox(width: widget.bounds.width, height: widget.bounds.height);
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _markUserPointerInteraction,
      child: NotificationListener<ScrollStartNotification>(
        onNotification: _acceptUserDrag,
        child: SizedBox(
          width: widget.bounds.width,
          height: widget.bounds.height,
          child: RepaintBoundary(
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
              itemBuilder: (context, label, metrics) {
                return SizedBox(
                  width: tileWidth,
                  height: AppSelectorMetrics.yearTileHeight,
                  child: FluviRoundedBox(
                    key: const ValueKey('fluvi-time-box'),
                    color: metrics.isSelected
                        ? null
                        : FluviVisualTokens.surface,
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
          ),
        ),
      ),
    );
  }

  void _queuePreview(int logicalIndex) {
    if (!_canForwardMotionCallback) {
      return;
    }
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
    if (!_canForwardMotionCallback) {
      return;
    }
    widget.controller.settleChildLogicalIndex(logicalIndex);
  }

  bool get _canForwardMotionCallback =>
      _acceptsMotionCallbacks &&
      _hasAcceptedUserMotion &&
      widget.controller.state.isRailOpen;

  bool _acceptUserDrag(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      _hasAcceptedUserMotion = true;
    }
    return false;
  }

  void _markUserPointerInteraction(PointerDownEvent _) {
    // Pointer-down alone does not select or settle anything. It only lets a
    // following native scroll update use the already-mounted preview path;
    // there is no manual target or controller motion here.
    _hasAcceptedUserMotion = true;
  }

  /// Input state is reset at a logical rail source change. The initial
  /// physical offset is configured by the shared controller before attach, so
  /// this method performs no scroll command or post-frame work.
  void _syncMotionBaseline(DashboardTimeNavigationState state) {
    final source = _RailMotionSource(
      plane: state.plane,
      parentScope: state.parentScope,
      isRailOpen: state.isRailOpen,
    );
    if (source == _motionSource) return;
    _motionSource = source;
    final logicalIndex = widget.controller.selectedChildLogicalIndex;
    _lastMotionLogicalIndex = logicalIndex;
    widget.onMotionBaselineEstablished?.call(logicalIndex);
    _acceptsMotionCallbacks = state.isRailOpen;
    _hasAcceptedUserMotion = false;
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
