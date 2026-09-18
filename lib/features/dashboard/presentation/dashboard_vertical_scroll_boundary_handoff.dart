import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'dashboard_upper_vertical_gesture_coordinator.dart';

/// Lets a viewport keep its normal scroll owner and hands only unconsumed
/// boundary overscroll to the existing Dashboard Header-expansion owner.
///
/// [handoffOnDirectVerticalDrag] is strictly for bounded non-scroll content.
/// It must not wrap a live Scrollable or a RangeSlider.
final class DashboardVerticalScrollBoundaryHandoff extends StatefulWidget {
  const DashboardVerticalScrollBoundaryHandoff({
    super.key,
    required this.child,
    this.upperVerticalGestures,
    this.handoffOnDirectVerticalDrag = false,
  });

  final Widget child;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;
  final bool handoffOnDirectVerticalDrag;

  @override
  State<DashboardVerticalScrollBoundaryHandoff> createState() =>
      _DashboardVerticalScrollBoundaryHandoffState();
}

final class _DashboardVerticalScrollBoundaryHandoffState
    extends State<DashboardVerticalScrollBoundaryHandoff> {
  bool _isBoundaryHandoff = false;
  bool _isDirectHandoff = false;

  @override
  void dispose() {
    if (_isBoundaryHandoff || _isDirectHandoff) {
      widget.upperVerticalGestures?.end();
    }
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final coordinator = widget.upperVerticalGestures;
    if (coordinator == null) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      coordinator.onForegroundInteraction?.call();
      if (_isBoundaryHandoff) {
        coordinator.end();
        _isBoundaryHandoff = false;
      }
    }
    if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      coordinator.consumeBoundaryOverscroll(notification.overscroll);
      _isBoundaryHandoff = true;
    }
    if (notification is ScrollEndNotification && _isBoundaryHandoff) {
      coordinator.end();
      _isBoundaryHandoff = false;
    }
    return false;
  }

  void _onDirectVerticalStart(DragStartDetails _) {
    _isDirectHandoff = true;
    widget.upperVerticalGestures?.begin();
  }

  void _onDirectVerticalUpdate(DragUpdateDetails details) =>
      widget.upperVerticalGestures?.dragByViewport(details.delta.dy);

  void _endDirectHandoff() {
    if (!_isDirectHandoff) return;
    _isDirectHandoff = false;
    widget.upperVerticalGestures?.end();
  }

  void _cancelDirectHandoff() {
    if (!_isDirectHandoff) return;
    _isDirectHandoff = false;
    widget.upperVerticalGestures?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final notificationChild = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.child,
    );
    if (!widget.handoffOnDirectVerticalDrag) return notificationChild;
    return GestureDetector(
      key: const ValueKey<String>('dashboard-vertical-boundary-direct-region'),
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      onVerticalDragStart: _onDirectVerticalStart,
      onVerticalDragUpdate: _onDirectVerticalUpdate,
      onVerticalDragEnd: (_) => _endDirectHandoff(),
      onVerticalDragCancel: _cancelDirectHandoff,
      child: notificationChild,
    );
  }
}
