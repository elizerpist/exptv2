import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../settings/models/app_theme_settings.dart';

class ExptFab extends StatefulWidget {
  const ExptFab({
    super.key,
    required this.onPressed,
    this.primaryColor = AppColors.primary,
    this.backgroundGradient,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.onLongPress,
    this.onHorizontalDragStep,
    this.onVerticalDragStep,
    this.icon = Icons.add,
    this.size = AppDimensions.fabSize,
    this.borderRadius = 18,
    this.semanticLabel = 'Tranzakció hozzáadása',
  });

  final VoidCallback onPressed;
  final Color primaryColor;
  final Gradient? backgroundGradient;
  final ExpenseSurfaceInteraction surfaceStyle;
  final VoidCallback? onLongPress;
  final ValueChanged<int>? onHorizontalDragStep;
  final ValueChanged<int>? onVerticalDragStep;
  final IconData icon;
  final double size;
  final double borderRadius;
  final String semanticLabel;

  @override
  State<ExptFab> createState() => _ExptFabState();
}

class _ExptFabState extends State<ExptFab> {
  static const _dragStepDistance = 32.0;
  static const _horizontalDeadZone = 0.0;
  static const _verticalDeadZone = 10.0;
  static const _verticalTickInterval = Duration(milliseconds: 90);

  double _dragDx = 0;
  double _horizontalOffsetX = 0;
  double _verticalOffsetY = 0;
  double? _pointerDownX;
  double? _pointerDownY;
  Timer? _verticalTickTimer;
  int _verticalTickCount = 0;
  bool _verticalActive = false;
  bool _dragStepped = false;

  @override
  void didUpdateWidget(covariant ExptFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onVerticalDragStep != null &&
        widget.onVerticalDragStep == null) {
      _verticalTickTimer?.cancel();
      _verticalTickTimer = null;
      _verticalOffsetY = 0;
      _verticalActive = false;
      _verticalTickCount = 0;
    }
    if (oldWidget.onHorizontalDragStep != null &&
        widget.onHorizontalDragStep == null) {
      _horizontalOffsetX = 0;
      _pointerDownX = null;
    }
  }

  @override
  void dispose() {
    _verticalTickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialFeedback = ExpenseSurface.materialFeedbackEnabled(
      widget.surfaceStyle,
    );
    final joystickFeedback = _verticalActive
        ? _FabJoystickFeedback.forOffset(
            _verticalOffsetY,
            deadZone: _verticalDeadZone,
          )
        : null;
    final horizontalFeedback =
        !_verticalActive && widget.onHorizontalDragStep != null
        ? _FabHorizontalFeedback.forOffset(
            _horizontalOffsetX,
            deadZone: _horizontalDeadZone,
          )
        : null;
    return ExpensePressable(
      enabled: widget.surfaceStyle.hasPressEffect,
      builder: (context, pressed) {
        final borderRadius = BorderRadius.circular(widget.borderRadius);
        final shapeBorder = RoundedRectangleBorder(borderRadius: borderRadius);
        final interactionSurface = Material(
          color: Colors.transparent,
          shape: shapeBorder,
          child: InkResponse(
            containedInkWell: true,
            customBorder: shapeBorder,
            overlayColor: materialFeedback
                ? null
                : ExpenseSurface.transparentOverlayColor,
            splashColor: materialFeedback ? null : Colors.transparent,
            highlightColor: materialFeedback
                ? Colors.white30
                : Colors.transparent,
            onTap: _handleTap,
            onLongPress:
                widget.onLongPress == null && widget.onVerticalDragStep == null
                ? null
                : _handleLongPress,
            child: ExcludeSemantics(
              child: widget.backgroundGradient == null
                  ? Icon(
                      widget.icon,
                      color: AppColors.white,
                      size: widget.size * AppDimensions.fabIconScale,
                    )
                  : const Text(
                      '+',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.white,
                        fontFamily: 'Inter',
                        fontSize: 34,
                        height: 1,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
            ),
          ),
        );
        final surfaceChild = widget.backgroundGradient == null
            ? interactionSurface
            : DecoratedBox(
                key: const ValueKey('expt-fab-gradient'),
                decoration: BoxDecoration(
                  gradient: widget.backgroundGradient,
                  borderRadius: borderRadius,
                ),
                child: interactionSurface,
              );
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown:
              widget.onHorizontalDragStep == null &&
                  widget.onVerticalDragStep == null
              ? null
              : _handlePointerDown,
          onPointerMove:
              widget.onHorizontalDragStep == null &&
                  widget.onVerticalDragStep == null
              ? null
              : _handlePointerMove,
          onPointerUp:
              widget.onHorizontalDragStep == null &&
                  widget.onVerticalDragStep == null
              ? null
              : (_) => _finishPointerGesture(),
          onPointerCancel:
              widget.onHorizontalDragStep == null &&
                  widget.onVerticalDragStep == null
              ? null
              : (_) => _finishPointerGesture(),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_verticalActive) ...[
                  Positioned(
                    top: -20,
                    child: IgnorePointer(
                      child: _FabJoystickDirectionIndicator(
                        key: ValueKey(
                          'expt-fab-joystick-increase-'
                          '${joystickFeedback?.direction == _FabJoystickDirection.increase ? 'active' : 'idle'}',
                        ),
                        icon: Icons.add,
                        active:
                            joystickFeedback?.direction ==
                            _FabJoystickDirection.increase,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    child: IgnorePointer(
                      child: _FabJoystickDirectionIndicator(
                        key: ValueKey(
                          'expt-fab-joystick-decrease-'
                          '${joystickFeedback?.direction == _FabJoystickDirection.decrease ? 'active' : 'idle'}',
                        ),
                        icon: Icons.remove,
                        active:
                            joystickFeedback?.direction ==
                            _FabJoystickDirection.decrease,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -18,
                    child: IgnorePointer(
                      child: _FabJoystickStrengthIndicator(
                        strength: joystickFeedback?.strength,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                ],
                if (horizontalFeedback != null) ...[
                  Positioned(
                    left: -20,
                    child: IgnorePointer(
                      child: _FabJoystickDirectionIndicator(
                        key: ValueKey(
                          'expt-fab-joystick-left-'
                          '${horizontalFeedback.direction == _FabHorizontalDirection.left ? 'active' : 'idle'}',
                        ),
                        icon: Icons.chevron_left,
                        active:
                            horizontalFeedback.direction ==
                            _FabHorizontalDirection.left,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    child: IgnorePointer(
                      child: _FabJoystickDirectionIndicator(
                        key: ValueKey(
                          'expt-fab-joystick-right-'
                          '${horizontalFeedback.direction == _FabHorizontalDirection.right ? 'active' : 'idle'}',
                        ),
                        icon: Icons.chevron_right,
                        active:
                            horizontalFeedback.direction ==
                            _FabHorizontalDirection.right,
                        color: widget.primaryColor,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -18,
                    child: IgnorePointer(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: _FabJoystickStrengthIndicator(
                          strength: horizontalFeedback.strength,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
                Transform.translate(
                  offset: Offset(
                    horizontalFeedback?.knobOffsetX ?? 0,
                    joystickFeedback?.knobOffsetY ?? 0,
                  ),
                  child: Semantics(
                    label: widget.semanticLabel,
                    button: true,
                    child: ExpenseSurfaceContainer(
                      surfaceKey: const ValueKey('expt-fab'),
                      style: widget.surfaceStyle,
                      color: widget.backgroundGradient == null
                          ? widget.primaryColor
                          : Colors.transparent,
                      borderRadius: borderRadius,
                      pressed: pressed,
                      primary: widget.backgroundGradient == null,
                      primaryColor: widget.primaryColor,
                      width: widget.size,
                      height: widget.size,
                      neutralShadow: widget.backgroundGradient == null
                          ? const [
                              BoxShadow(
                                color: AppColors.fabShadow,
                                offset: Offset(0, 5),
                                blurRadius: 12,
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Color(0x422563EB),
                                offset: Offset(0, 6),
                                blurRadius: 14,
                              ),
                              BoxShadow(
                                color: Color(0x2414213A),
                                offset: Offset(0, 2),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: Color(0x61FFFFFF),
                                offset: Offset(0, 1),
                                blurRadius: 0,
                                blurStyle: BlurStyle.inner,
                              ),
                            ],
                      child: surfaceChild,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap() {
    if (_dragStepped) {
      DebugConsole.log('[FAB] tap suppressed reason=horizontal-drag-step');
      _dragStepped = false;
      return;
    }
    DebugConsole.log('[FAB] single tap immediate dispatch');
    widget.onPressed();
  }

  void _handleLongPress() {
    if (widget.onVerticalDragStep != null) {
      setState(() {
        _verticalActive = true;
        _verticalOffsetY = 0;
        _verticalTickCount = 0;
        _dragStepped = true;
      });
      _verticalTickTimer?.cancel();
      _verticalTickTimer = Timer.periodic(
        _verticalTickInterval,
        (_) => _applyVerticalTick(),
      );
      HapticFeedback.mediumImpact();
    }
    DebugConsole.log('[FAB] long press dispatch');
    widget.onLongPress?.call();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _dragDx = 0;
    _horizontalOffsetX = 0;
    _verticalOffsetY = 0;
    _pointerDownX = event.position.dx;
    _pointerDownY = event.position.dy;
    _verticalActive = false;
    _verticalTickCount = 0;
    _dragStepped = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_verticalActive) {
      final pointerDownY = _pointerDownY;
      if (pointerDownY != null) {
        final nextOffset = event.position.dy - pointerDownY;
        if (nextOffset != _verticalOffsetY) {
          setState(() => _verticalOffsetY = nextOffset);
        }
      }
      return;
    }
    if (widget.onHorizontalDragStep == null) return;
    final pointerDownX = _pointerDownX;
    if (pointerDownX != null) {
      final nextOffset = event.position.dx - pointerDownX;
      if (nextOffset != _horizontalOffsetX) {
        setState(() => _horizontalOffsetX = nextOffset);
      }
    }
    _dragDx += event.delta.dx;
    if (_dragDx.abs() < _dragStepDistance) return;
    final direction = _dragDx > 0 ? 1 : -1;
    _dragDx = 0;
    _dragStepped = true;
    HapticFeedback.selectionClick();
    DebugConsole.log('[FAB] horizontal snapshot step direction=$direction');
    widget.onHorizontalDragStep?.call(direction);
  }

  void _finishPointerGesture() {
    _dragDx = 0;
    _pointerDownX = null;
    _pointerDownY = null;
    if (_verticalActive) {
      setState(() {
        _verticalOffsetY = 0;
        _verticalActive = false;
      });
    } else {
      _verticalOffsetY = 0;
    }
    if (_horizontalOffsetX != 0) {
      setState(() => _horizontalOffsetX = 0);
    }
    _verticalTickTimer?.cancel();
    _verticalTickTimer = null;
  }

  void _applyVerticalTick() {
    if (!_verticalActive || _verticalOffsetY.abs() <= _verticalDeadZone) {
      return;
    }
    final strength = _FabJoystickStrength.forDistance(_verticalOffsetY.abs());
    _verticalTickCount += 1;
    if (_verticalTickCount % strength.tickStride != 0) return;
    final direction = _verticalOffsetY < 0 ? 1 : -1;
    final step = direction * strength.stepMultiplier;
    widget.onVerticalDragStep?.call(step);
    HapticFeedback.selectionClick();
    DebugConsole.log('[FAB] vertical threshold step multiplier=$step');
  }
}

class _FabJoystickDirectionIndicator extends StatelessWidget {
  const _FabJoystickDirectionIndicator({
    super.key,
    required this.icon,
    required this.active,
    required this.color,
  });

  final IconData icon;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.28,
      duration: const Duration(milliseconds: 100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: active ? 24 : 20,
        height: active ? 24 : 20,
        decoration: BoxDecoration(
          color: active ? color : AppColors.gray200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? AppColors.white : AppColors.gray500,
          size: active ? 16 : 14,
        ),
      ),
    );
  }
}

class _FabJoystickStrengthIndicator extends StatelessWidget {
  const _FabJoystickStrengthIndicator({
    required this.strength,
    required this.color,
  });

  final _FabJoystickStrength? strength;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final activeBars = switch (strength) {
      _FabJoystickStrength.slow => 1,
      _FabJoystickStrength.medium => 2,
      _FabJoystickStrength.fast => 3,
      null => 0,
    };
    return Column(
      key: ValueKey('expt-fab-joystick-speed-${strength?.name ?? 'idle'}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 3; index >= 1; index -= 1)
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: index == 3 ? 10 : 8,
            height: index == 3 ? 12 : 8,
            margin: const EdgeInsets.symmetric(vertical: 1.5),
            decoration: BoxDecoration(
              color: activeBars >= index ? color : AppColors.gray200,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _FabJoystickFeedback {
  const _FabJoystickFeedback({
    required this.direction,
    required this.strength,
    required this.knobOffsetY,
  });

  final _FabJoystickDirection direction;
  final _FabJoystickStrength strength;
  final double knobOffsetY;

  static _FabJoystickFeedback? forOffset(
    double offsetY, {
    required double deadZone,
  }) {
    final distance = offsetY.abs();
    if (distance <= deadZone) return null;
    final direction = offsetY < 0
        ? _FabJoystickDirection.increase
        : _FabJoystickDirection.decrease;
    final strength = _FabJoystickStrength.forDistance(distance);
    return _FabJoystickFeedback(
      direction: direction,
      strength: strength,
      knobOffsetY: direction == _FabJoystickDirection.increase
          ? -strength.knobOffset
          : strength.knobOffset,
    );
  }
}

class _FabHorizontalFeedback {
  const _FabHorizontalFeedback({
    required this.direction,
    required this.strength,
    required this.knobOffsetX,
  });

  final _FabHorizontalDirection direction;
  final _FabJoystickStrength strength;
  final double knobOffsetX;

  static _FabHorizontalFeedback? forOffset(
    double offsetX, {
    required double deadZone,
  }) {
    final distance = offsetX.abs();
    if (distance <= deadZone) return null;
    final direction = offsetX < 0
        ? _FabHorizontalDirection.left
        : _FabHorizontalDirection.right;
    final strength = _FabJoystickStrength.forDistance(distance);
    return _FabHorizontalFeedback(
      direction: direction,
      strength: strength,
      knobOffsetX: direction == _FabHorizontalDirection.left
          ? -strength.knobOffset
          : strength.knobOffset,
    );
  }
}

enum _FabJoystickDirection { increase, decrease }

enum _FabHorizontalDirection { left, right }

enum _FabJoystickStrength {
  slow(stepMultiplier: 1, tickStride: 3, knobOffset: 2),
  medium(stepMultiplier: 2, tickStride: 1, knobOffset: 4),
  fast(stepMultiplier: 6, tickStride: 1, knobOffset: 6);

  const _FabJoystickStrength({
    required this.stepMultiplier,
    required this.tickStride,
    required this.knobOffset,
  });

  final int stepMultiplier;
  final int tickStride;
  final double knobOffset;

  static _FabJoystickStrength forDistance(double distance) {
    if (distance >= 150) return fast;
    if (distance >= 88) return medium;
    return slow;
  }
}
