import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/gesture_direction_arbiter.dart';
import '../../application/dashboard_core_mode_controller.dart';
import '../../application/dashboard_mode_spec.dart';
import 'balance_dashboard_core_surface.dart';
import 'budget_dashboard_core_surface.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_transition_motion.dart';
import 'mind_dashboard_core_surface.dart';

typedef DashboardCoreModePresentationLookup =
    DashboardCoreModePresentation Function(DashboardModeSpec mode);

/// Bounded presentation domain for the active dashboard core mode.
///
/// It never mounts all three mode roots. The header is the exclusive global
/// mode-navigation hit region; card roots remain free for future local input.
class DashboardCoreModeHost extends StatefulWidget {
  const DashboardCoreModeHost({
    super.key,
    required this.controller,
    required this.motion,
    required this.presentationFor,
    required this.onVerticalExpansionStart,
    required this.onVerticalExpansionDragBy,
    required this.onVerticalExpansionEnd,
  });

  final DashboardCoreModeController controller;
  final DashboardCoreModeTransitionMotion motion;
  final DashboardCoreModePresentationLookup presentationFor;
  final VoidCallback onVerticalExpansionStart;
  final ValueChanged<double> onVerticalExpansionDragBy;
  final VoidCallback onVerticalExpansionEnd;

  @override
  State<DashboardCoreModeHost> createState() => _DashboardCoreModeHostState();
}

class _DashboardCoreModeHostState extends State<DashboardCoreModeHost> {
  DashboardModeSpec? _sourceMode;
  DashboardModeSpec? _targetMode;
  DashboardCoreModeDirection? _transitionDirection;
  GestureDirectionIntent? _pointerAxis;
  Offset? _pointerOrigin;
  double _appliedVerticalDisplacement = 0;
  bool _verticalExpansionStarted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onModeStateChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardCoreModeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_onModeStateChanged);
      widget.controller.addListener(_onModeStateChanged);
      _syncModeState();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onModeStateChanged);
    super.dispose();
  }

  void _onModeStateChanged() {
    _syncModeState();
    if (mounted) setState(() {});
  }

  void _syncModeState() {
    final transition = widget.controller.transition;
    switch (transition.phase) {
      case DashboardCoreModeTransitionPhase.dragging:
        _sourceMode ??= widget.controller.committedMode;
        _targetMode = transition.targetMode;
        _transitionDirection = transition.direction;
        return;
      case DashboardCoreModeTransitionPhase.settlingCommitted:
      case DashboardCoreModeTransitionPhase.settlingCancelled:
        // Keep the source/target pair mounted until the local settle ticker
        // finishes, even though a committed semantic mode has already changed.
        return;
      case DashboardCoreModeTransitionPhase.idle:
        _sourceMode = null;
        _targetMode = null;
        _transitionDirection = null;
        widget.motion.setDragProgress(0);
        return;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _pointerAxis = null;
    _pointerOrigin = details.globalPosition;
    _appliedVerticalDisplacement = 0;
    _verticalExpansionStarted = false;
  }

  void _onPanUpdate(DragUpdateDetails details, double viewportWidth) {
    final origin = _pointerOrigin;
    if (origin == null) return;
    final displacement = details.globalPosition - origin;
    final axis =
        _pointerAxis ??
        GestureDirectionArbiter.resolve(
          dx: displacement.dx,
          dy: displacement.dy,
          touchSlop: kTouchSlop,
        );
    if (axis == null) return;
    _pointerAxis ??= axis;

    switch (_pointerAxis!) {
      case GestureDirectionIntent.vertical:
        _applyVerticalDisplacement(displacement.dy);
        return;
      case GestureDirectionIntent.horizontal:
        _applyHorizontalDisplacement(displacement.dx, viewportWidth);
        return;
    }
  }

  void _applyVerticalDisplacement(double displacement) {
    if (!_verticalExpansionStarted) {
      _verticalExpansionStarted = true;
      widget.onVerticalExpansionStart();
    }
    final delta = displacement - _appliedVerticalDisplacement;
    _appliedVerticalDisplacement = displacement;
    widget.onVerticalExpansionDragBy(delta);
  }

  void _applyHorizontalDisplacement(double displacement, double viewportWidth) {
    final existingDirection = _transitionDirection;
    if (existingDirection == null) {
      final direction = displacement < 0
          ? DashboardCoreModeDirection.forward
          : DashboardCoreModeDirection.backward;
      if (!widget.controller.beginTransition(direction)) return;
    }
    final direction = _transitionDirection;
    if (direction == null || viewportWidth <= 0) return;
    final progress = switch (direction) {
      DashboardCoreModeDirection.forward => -displacement / viewportWidth,
      DashboardCoreModeDirection.backward => displacement / viewportWidth,
    };
    widget.motion.setDragProgress(progress);
  }

  void _onPanEnd(DragEndDetails _) => _finishPointerSequence(cancelled: false);

  void _onPanCancel() => _finishPointerSequence(cancelled: true);

  void _finishPointerSequence({required bool cancelled}) {
    final axis = _pointerAxis;
    _pointerAxis = null;
    _pointerOrigin = null;
    if (axis == GestureDirectionIntent.vertical) {
      if (_verticalExpansionStarted) widget.onVerticalExpansionEnd();
      _verticalExpansionStarted = false;
      return;
    }
    if (axis != GestureDirectionIntent.horizontal || _targetMode == null) {
      return;
    }

    final commits =
        !cancelled &&
        DashboardCoreModeTransitionPolicy.commitsAt(widget.motion.value);
    final changed = commits
        ? widget.controller.commitTransition()
        : widget.controller.cancelTransition();
    if (!changed) return;
    final expectedPhase = commits
        ? DashboardCoreModeTransitionPhase.settlingCommitted
        : DashboardCoreModeTransitionPhase.settlingCancelled;
    unawaited(_settleAndComplete(commits ? 1 : 0, expectedPhase));
  }

  Future<void> _settleAndComplete(
    double target,
    DashboardCoreModeTransitionPhase expectedPhase,
  ) async {
    await widget.motion.settleTo(target);
    if (!mounted || widget.controller.transition.phase != expectedPhase) return;
    widget.controller.completeTransition();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final source = _sourceMode ?? widget.controller.committedMode;
        final target = _targetMode;
        final direction = _transitionDirection;
        final sourcePresentation = widget.presentationFor(source);
        return AnimatedBuilder(
          animation: widget.motion,
          builder: (context, _) {
            final progress = target == null ? 0.0 : widget.motion.value;
            final directionSign =
                direction == DashboardCoreModeDirection.forward ? -1.0 : 1.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (target != null)
                  Transform.translate(
                    offset: Offset(
                      -directionSign * viewportWidth * (1 - progress),
                      0,
                    ),
                    child: _buildModeSurface(target),
                  ),
                Transform.translate(
                  offset: Offset(directionSign * viewportWidth * progress, 0),
                  child: _buildModeSurface(source),
                ),
                Positioned(
                  left: sourcePresentation.geometry.headerBounds.left,
                  top: sourcePresentation.geometry.headerBounds.top,
                  width: sourcePresentation.geometry.headerBounds.width,
                  height: sourcePresentation.geometry.headerBounds.height,
                  child: GestureDetector(
                    key: const ValueKey(
                      'dashboard-core-mode-header-gesture-region',
                    ),
                    behavior: HitTestBehavior.translucent,
                    dragStartBehavior: DragStartBehavior.down,
                    onPanStart: _onPanStart,
                    onPanUpdate: (details) =>
                        _onPanUpdate(details, viewportWidth),
                    onPanEnd: _onPanEnd,
                    onPanCancel: _onPanCancel,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModeSurface(DashboardModeSpec mode) {
    final presentation = widget.presentationFor(mode);
    return switch (mode.mode) {
      DashboardMode.balance => BalanceDashboardCoreSurface(
        presentation: presentation,
      ),
      DashboardMode.budget => BudgetDashboardCoreSurface(
        presentation: presentation,
      ),
      DashboardMode.mind => MindDashboardCoreSurface(
        presentation: presentation,
      ),
    };
  }
}
