import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Input-only shell around one Budget rail target. It deliberately leaves tap
/// centering to the outer [CenteredCarousel] recognizer while raw pointer-down
/// feedback and long-press editing stay local to the avatar.
final class BudgetTargetAvatarInteraction extends StatefulWidget {
  const BudgetTargetAvatarInteraction({
    required this.child,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onLongPressCancel,
    super.key,
  });

  final Widget child;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;
  final GestureLongPressCancelCallback? onLongPressCancel;

  @override
  State<BudgetTargetAvatarInteraction> createState() =>
      _BudgetTargetAvatarInteractionState();
}

final class _BudgetTargetAvatarInteractionState
    extends State<BudgetTargetAvatarInteraction> {
  bool _pointerPressed = false;

  void _setPointerPressed(bool value) {
    if (!mounted || _pointerPressed == value) return;
    setState(() => _pointerPressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _setPointerPressed(true),
    onPointerUp: (_) => _setPointerPressed(false),
    onPointerCancel: (_) => _setPointerPressed(false),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: widget.onLongPressStart,
      onLongPressMoveUpdate: widget.onLongPressMoveUpdate,
      onLongPressEnd: (details) {
        _setPointerPressed(false);
        widget.onLongPressEnd?.call(details);
      },
      onLongPressCancel: () {
        _setPointerPressed(false);
        widget.onLongPressCancel?.call();
      },
      child: AnimatedScale(
        key: const ValueKey('budget-target-avatar-press-scale'),
        scale: _pointerPressed ? .8 : 1,
        duration: const Duration(milliseconds: 115),
        curve: Curves.easeOutQuad,
        child: widget.child,
      ),
    ),
  );
}
