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
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.onLongPress,
    this.onHorizontalDragStep,
    this.onVerticalDragStep,
    this.icon = Icons.add,
    this.size = AppDimensions.fabSize,
  });

  final VoidCallback onPressed;
  final Color primaryColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final VoidCallback? onLongPress;
  final ValueChanged<int>? onHorizontalDragStep;
  final ValueChanged<int>? onVerticalDragStep;
  final IconData icon;
  final double size;

  @override
  State<ExptFab> createState() => _ExptFabState();
}

class _ExptFabState extends State<ExptFab> {
  static const _dragStepDistance = 32.0;
  static const _verticalDeadZone = 10.0;
  static const _verticalTickInterval = Duration(milliseconds: 90);

  double _dragDx = 0;
  double _verticalOffsetY = 0;
  double? _pointerDownY;
  Timer? _verticalTickTimer;
  int _verticalTickCount = 0;
  bool _verticalActive = false;
  bool _dragStepped = false;

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
    return ExpensePressable(
      enabled: widget.surfaceStyle.hasPressEffect,
      builder: (context, pressed) {
        final borderRadius = BorderRadius.circular(18);
        final shapeBorder = RoundedRectangleBorder(borderRadius: borderRadius);
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
          child: ExpenseSurfaceContainer(
            surfaceKey: const ValueKey('expt-fab'),
            style: widget.surfaceStyle,
            color: widget.primaryColor,
            borderRadius: borderRadius,
            pressed: pressed,
            primary: true,
            primaryColor: widget.primaryColor,
            width: widget.size,
            height: widget.size,
            neutralShadow: const [
              BoxShadow(
                color: AppColors.fabShadow,
                offset: Offset(0, 5),
                blurRadius: 12,
              ),
            ],
            child: Material(
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
                    widget.onLongPress == null &&
                        widget.onVerticalDragStep == null
                    ? null
                    : _handleLongPress,
                child: Icon(
                  widget.icon,
                  color: AppColors.white,
                  size: widget.size * AppDimensions.fabIconScale,
                ),
              ),
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
      _verticalActive = true;
      _verticalOffsetY = 0;
      _verticalTickCount = 0;
      _dragStepped = true;
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
    _verticalOffsetY = 0;
    _pointerDownY = event.position.dy;
    _verticalActive = false;
    _verticalTickCount = 0;
    _dragStepped = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_verticalActive) {
      final pointerDownY = _pointerDownY;
      if (pointerDownY != null) {
        _verticalOffsetY = event.position.dy - pointerDownY;
      }
      return;
    }
    if (widget.onHorizontalDragStep == null) return;
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
    _verticalOffsetY = 0;
    _pointerDownY = null;
    _verticalActive = false;
    _verticalTickTimer?.cancel();
    _verticalTickTimer = null;
  }

  void _applyVerticalTick() {
    if (!_verticalActive || _verticalOffsetY.abs() <= _verticalDeadZone) {
      return;
    }
    final distance = _verticalOffsetY.abs();
    final multiplier = distance >= 150
        ? 6
        : distance >= 88
        ? 2
        : 1;
    final stride = distance < 88 ? 3 : 1;
    _verticalTickCount += 1;
    if (_verticalTickCount % stride != 0) return;
    final direction = _verticalOffsetY < 0 ? 1 : -1;
    final step = direction * multiplier;
    widget.onVerticalDragStep?.call(step);
    HapticFeedback.selectionClick();
    DebugConsole.log('[FAB] vertical threshold step multiplier=$step');
  }
}
