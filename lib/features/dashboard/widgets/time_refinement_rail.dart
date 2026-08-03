import 'package:flutter/material.dart';

import '../../../core/design/app_control_metrics.dart';
import '../../../core/design/dashboard_layout_frame.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import '../../../core/design/fluvi_rounded_box.dart';
import '../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
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
    this.onMotionTargetLogicalIndexResolved,
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

  /// One final shared-carousel target for an accepted tap or fling. Unlike a
  /// preview tick, this is eligible for a low-priority data prefetch.
  final ValueChanged<int>? onMotionTargetLogicalIndexResolved;

  @override
  State<TimeRefinementRail> createState() => _TimeRefinementRailState();
}

class _TimeRefinementRailState extends State<TimeRefinementRail> {
  int? _pendingPreviewLogicalIndex;
  bool _previewScheduled = false;
  int _previewEpoch = 0;
  int _baselineEpoch = 0;
  bool _acceptsMotionCallbacks = false;
  bool _hasUserPointerInteraction = false;
  bool _hasAcceptedUserMotion = false;
  int? _lastMotionLogicalIndex;
  _RailMotionSource? _motionSource;

  @override
  void didUpdateWidget(covariant TimeRefinementRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _invalidateQueuedPreview();
      _baselineEpoch += 1;
      _acceptsMotionCallbacks = false;
      _hasUserPointerInteraction = false;
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
      _invalidateQueuedPreview();
      return SizedBox(width: widget.bounds.width, height: widget.bounds.height);
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _markUserPointerInteraction,
      child: NotificationListener<ScrollStartNotification>(
        onNotification: _acceptUserDrag,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (_) {
            DashboardSummaryTimingDebug.mark('R2 SCROLL_ACTIVITY_IDLE');
            return false;
          },
          child: SizedBox(
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
              onMotionTargetResolved: _notifyMotionTargetResolved,
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

  /// The shared carousel's controller paints its selected tile only after its
  /// preview callback returns. Keep dashboard projection work out of that
  /// callback and coalesce it to the end of the same frame; this lets a haptic
  /// tick and the tile's visual center reach the frame together, while the
  /// Summary Pill still receives the latest preview before the next frame.
  void _queuePreview(int logicalIndex) {
    // The shared carousel establishes its physical viewport on mount and may
    // report that initial position as a preview. A closed dashboard rail has
    // no user gesture and no visible child projection, so this adapter must
    // not let that setup callback mutate navigation state. The carousel
    // remains unchanged; only the dashboard intent boundary is gated.
    if (!_canForwardMotionCallback) {
      _invalidateQueuedPreview();
      return;
    }
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
    _pendingPreviewLogicalIndex = logicalIndex;
    if (_previewScheduled) return;
    _previewScheduled = true;
    final epoch = _previewEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _previewEpoch) return;
      _previewScheduled = false;
      final pending = _pendingPreviewLogicalIndex;
      _pendingPreviewLogicalIndex = null;
      if (pending != null && widget.controller.state.isRailOpen) {
        widget.controller.previewChildLogicalIndex(pending);
      }
    });
  }

  void _settleSelection(int logicalIndex) {
    if (!_canForwardMotionCallback) {
      _invalidateQueuedPreview();
      return;
    }
    _invalidateQueuedPreview();
    widget.controller.settleChildLogicalIndex(logicalIndex);
  }

  void _notifyMotionTargetResolved(int logicalIndex) {
    // This callback originates only from the shared carousel's accepted tap
    // or its resolved fling target. It is the tap counterpart of a drag
    // start, so it may unlock callbacks without treating pointer-down alone
    // as a user-owned navigation event.
    if (_hasUserPointerInteraction) {
      _hasAcceptedUserMotion = true;
    }
    if (!_canForwardMotionCallback) {
      return;
    }
    widget.onMotionTargetLogicalIndexResolved?.call(logicalIndex);
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
    _hasUserPointerInteraction = true;
  }

  void _invalidateQueuedPreview() {
    _previewEpoch += 1;
    _pendingPreviewLogicalIndex = null;
    _previewScheduled = false;
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
    _invalidateQueuedPreview();
    final logicalIndex = widget.controller.selectedChildLogicalIndex;
    _lastMotionLogicalIndex = logicalIndex;
    widget.onMotionBaselineEstablished?.call(logicalIndex);
    final baselineEpoch = ++_baselineEpoch;
    _acceptsMotionCallbacks = !state.isRailOpen;
    _hasUserPointerInteraction = false;
    _hasAcceptedUserMotion = false;
    if (!state.isRailOpen) return;

    // `CenteredCarousel` configures its own physical viewport during this
    // build. Wait for that configuration, then establish the semantic child
    // as a suppressed physical recenter. A second post-frame turn lets the
    // shared carousel finish its own initial recenter before genuine user
    // callbacks are forwarded to navigation/query state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || baselineEpoch != _baselineEpoch) return;
      final current = widget.controller.state;
      if (!current.isRailOpen) return;
      widget.controller.timeCarousel.jumpToIndexSilently(logicalIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || baselineEpoch != _baselineEpoch) return;
        if (!widget.controller.state.isRailOpen) return;
        _acceptsMotionCallbacks = true;
      });
    });
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
