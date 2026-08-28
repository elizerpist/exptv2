import 'package:flutter/foundation.dart';

import '../application/dashboard_expansion_controller.dart';

/// One pointer-sequence coordinator for expanding/collapsing the Header from
/// any eligible upper-dashboard surface. It owns no expansion value itself:
/// [DashboardExpansionController] remains the single geometry/state owner.
final class DashboardUpperVerticalGestureCoordinator {
  DashboardUpperVerticalGestureCoordinator({
    required DashboardExpansionController expansion,
    required double Function(double viewportDelta) mapViewportDelta,
    this.onForegroundInteraction,
  }) : _expansion = expansion,
       _mapViewportDelta = mapViewportDelta;

  final DashboardExpansionController _expansion;
  double Function(double viewportDelta) _mapViewportDelta;
  final VoidCallback? onForegroundInteraction;
  bool _isHandlingPointer = false;

  bool get isHandlingPointer => _isHandlingPointer;

  void updateViewportMapper(double Function(double viewportDelta) mapper) {
    _mapViewportDelta = mapper;
  }

  void begin() {
    onForegroundInteraction?.call();
    if (_isHandlingPointer) return;
    _isHandlingPointer = true;
    _expansion.beginDrag();
  }

  void dragByViewport(double viewportDelta) {
    begin();
    _expansion.dragBy(_mapViewportDelta(viewportDelta));
  }

  /// Flutter reports overscroll in scroll-offset coordinates, the inverse of
  /// the pointer's drag delta. Passing its negation preserves the existing
  /// Header drag sign convention while retaining the child's controller.
  void consumeBoundaryOverscroll(double overscroll) {
    if (overscroll == 0) return;
    dragByViewport(-overscroll);
  }

  void end() {
    if (!_isHandlingPointer) return;
    _isHandlingPointer = false;
    _expansion.endDrag();
  }

  void cancel() {
    if (!_isHandlingPointer) return;
    _isHandlingPointer = false;
    _expansion.cancelDrag();
  }
}
