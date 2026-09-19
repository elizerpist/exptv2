import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dashboard_upper_vertical_gesture_coordinator.dart';

/// Passively forwards only a visual pager page's unconsumed vertical boundary
/// drag to the existing Dashboard expansion coordinator.
///
/// A [PageView] can prevent a nested vertical [Scrollable] from publishing the
/// usual overscroll notification. This widget deliberately owns no gesture
/// recognizer: the active page's scrollable remains the owner for every
/// in-bounds sequence, while this listener observes raw movement only after
/// it clears slop and is outward from that scrollable's current boundary.
final class DashboardPagedVerticalBoundaryHandoff extends StatefulWidget {
  const DashboardPagedVerticalBoundaryHandoff({
    super.key,
    required this.child,
    required this.activePageScrollController,
    this.upperVerticalGestures,
  });

  final Widget child;
  final ScrollController? Function() activePageScrollController;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<DashboardPagedVerticalBoundaryHandoff> createState() =>
      _DashboardPagedVerticalBoundaryHandoffState();
}

final class _DashboardPagedVerticalBoundaryHandoffState
    extends State<DashboardPagedVerticalBoundaryHandoff> {
  int? _pointer;
  Offset? _origin;
  Offset? _previousPosition;
  var _isBoundaryHandoff = false;

  bool _activePageCanHandOff(double viewportDeltaY) {
    final controller = widget.activePageScrollController();
    if (controller == null || !controller.hasClients) return false;
    final position = controller.position;
    if (position.maxScrollExtent == 0) return true;
    if (viewportDeltaY < 0) {
      return position.pixels >= position.maxScrollExtent;
    }
    if (viewportDeltaY > 0) {
      return position.pixels <= position.minScrollExtent;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointer = event.pointer;
    _origin = event.position;
    _previousPosition = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final origin = _origin;
    final previous = _previousPosition;
    _previousPosition = event.position;
    if (origin == null || previous == null) return;
    final travel = event.position - origin;
    if (!_isBoundaryHandoff) {
      if (travel.distance < kTouchSlop ||
          travel.dy.abs() <= travel.dx.abs() ||
          !_activePageCanHandOff(travel.dy)) {
        return;
      }
      _isBoundaryHandoff = true;
      widget.upperVerticalGestures?.begin();
    }
    widget.upperVerticalGestures?.dragByViewport(
      event.position.dy - previous.dy,
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _end(cancelled: false);
    _clearPointer();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _end(cancelled: true);
    _clearPointer();
  }

  void _clearPointer() {
    _pointer = null;
    _origin = null;
    _previousPosition = null;
  }

  void _end({required bool cancelled}) {
    if (!_isBoundaryHandoff) return;
    _isBoundaryHandoff = false;
    if (cancelled) {
      widget.upperVerticalGestures?.cancel();
    } else {
      widget.upperVerticalGestures?.end();
    }
  }

  @override
  void dispose() {
    _end(cancelled: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: _onPointerDown,
    onPointerMove: _onPointerMove,
    onPointerUp: _onPointerUp,
    onPointerCancel: _onPointerCancel,
    child: widget.child,
  );
}
