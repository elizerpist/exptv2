import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_record.dart';
import 'calendar_joystick_range.dart';

enum CalendarSliderKind { threshold, heatmap }

class CalendarValueSliderPanel extends StatefulWidget {
  const CalendarValueSliderPanel.threshold({
    super.key,
    required this.value,
    required this.observedMax,
    required this.fallbackMax,
    required this.onChanged,
  }) : kind = CalendarSliderKind.threshold;

  const CalendarValueSliderPanel.heatmap({
    super.key,
    required this.value,
    required this.observedMax,
    required this.fallbackMax,
    required this.onChanged,
  }) : kind = CalendarSliderKind.heatmap;

  final CalendarSliderKind kind;
  final double value;
  final double observedMax;
  final double fallbackMax;
  final ValueChanged<double> onChanged;

  @override
  State<CalendarValueSliderPanel> createState() =>
      _CalendarValueSliderPanelState();
}

class _CalendarValueSliderPanelState extends State<CalendarValueSliderPanel> {
  static const _deadZone = 10.0;
  static const _tickInterval = Duration(milliseconds: 90);
  static const _fadeDelay = Duration(milliseconds: 600);
  static const _minimumHapticGap = Duration(milliseconds: 100);

  Timer? _tickTimer;
  Timer? _fadeTimer;
  var _active = false;
  var _showValueCard = false;
  var _dragOffsetY = 0.0;
  var _currentValue = 0.0;
  var _tickCount = 0;
  double? _activationGlobalY;
  double? _lastTickHapticValue;
  _JoystickBoundary? _lastBoundaryHaptic;
  DateTime? _lastSelectionHapticAt;

  @override
  void didUpdateWidget(covariant CalendarValueSliderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active && oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sliderKey = _sliderKey;
    final displayValue = _range.clamp(_currentValueOrWidgetValue);
    final boundaryLabel = _boundaryLabel(displayValue);
    final activeDirection = _active && _dragOffsetY.abs() > _deadZone
        ? (_dragOffsetY < 0
              ? _JoystickDirection.increase
              : _JoystickDirection.decrease)
        : null;
    final speedBand = _active && _dragOffsetY.abs() > _deadZone
        ? _speedBandForOffset(_dragOffsetY.abs())
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_showValueCard)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 76, 120),
              child: AnimatedOpacity(
                key: ValueKey('$sliderKey-joystick-value-card'),
                opacity: _showValueCard ? 1 : 0,
                duration: const Duration(milliseconds: 140),
                child: Material(
                  color: AppColors.white,
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 104),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      boundaryLabel ?? formatHuf(displayValue),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 12, 78),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerMove: _handlePointerMove,
              onPointerUp: (_) => _finishJoystick(),
              onPointerCancel: (_) => _finishJoystick(),
              child: SizedBox(
                width: 62,
                height: 114,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (_active) ...[
                      Positioned(
                        top: 0,
                        child: _JoystickDirectionIndicator(
                          key: ValueKey('$sliderKey-joystick-plus-indicator'),
                          icon: Icons.add,
                          active:
                              activeDirection == _JoystickDirection.increase,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: _JoystickDirectionIndicator(
                          key: ValueKey('$sliderKey-joystick-minus-indicator'),
                          icon: Icons.remove,
                          active:
                              activeDirection == _JoystickDirection.decrease,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: _JoystickSpeedIndicator(
                          sliderKey: sliderKey,
                          speedBand: speedBand,
                        ),
                      ),
                    ],
                    GestureDetector(
                      key: ValueKey('$sliderKey-joystick-trigger'),
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: _handleLongPressStart,
                      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
                      onLongPressEnd: (_) => _finishJoystick(),
                      onLongPressCancel: _finishJoystick,
                      child: Material(
                        color: _active ? AppColors.primary : AppColors.gray800,
                        elevation: 7,
                        shadowColor: Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.tune,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _sliderKey => widget.kind == CalendarSliderKind.threshold
      ? 'calendar-threshold'
      : 'calendar-heatmap';

  CalendarJoystickRange get _range => CalendarJoystickRange.adaptive(
    currentValue: widget.value,
    observedMax: widget.observedMax,
    fallbackMax: widget.fallbackMax,
  );

  double get _currentValueOrWidgetValue =>
      _active ? _currentValue : widget.value;

  void _handleLongPressStart(LongPressStartDetails details) {
    _fadeTimer?.cancel();
    _currentValue = _range.snap(widget.value);
    _dragOffsetY = 0;
    _tickCount = 0;
    _activationGlobalY = details.globalPosition.dy;
    _lastTickHapticValue = _currentValue;
    _lastBoundaryHaptic = null;
    setState(() {
      _active = true;
      _showValueCard = true;
    });
    unawaited(HapticFeedback.mediumImpact());
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(_tickInterval, (_) => _applyJoystickTick());
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final activationGlobalY = _activationGlobalY;
    _updateDragOffset(
      activationGlobalY == null
          ? details.offsetFromOrigin.dy
          : details.globalPosition.dy - activationGlobalY,
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final activationGlobalY = _activationGlobalY;
    if (!_active || activationGlobalY == null) return;
    _updateDragOffset(event.position.dy - activationGlobalY);
  }

  void _updateDragOffset(double value) {
    if (!_active) {
      _dragOffsetY = value;
      return;
    }
    if (_dragOffsetY == value) return;
    setState(() => _dragOffsetY = value);
  }

  void _finishJoystick() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _activationGlobalY = null;
    if (!_active) return;
    setState(() => _active = false);
    _fadeTimer?.cancel();
    _fadeTimer = Timer(_fadeDelay, () {
      if (mounted) setState(() => _showValueCard = false);
    });
  }

  void _applyJoystickTick() {
    if (!_active || _dragOffsetY.abs() <= _deadZone) return;
    final speed = _speedForOffset(_dragOffsetY.abs());
    _tickCount += 1;
    if (_tickCount % speed.tickStride != 0) return;

    final range = _range;
    final direction = _dragOffsetY < 0 ? 1 : -1;
    final next = range.snap(
      _currentValue + direction * range.step * speed.stepMultiplier,
    );
    if (next == _currentValue) {
      _handleBoundaryHaptic(next);
      return;
    }
    setState(() => _currentValue = next);
    widget.onChanged(next);
    _handleTickHaptic(next);
    _handleBoundaryHaptic(next);
  }

  _JoystickSpeed _speedForOffset(double distance) {
    if (distance >= 150) {
      return const _JoystickSpeed(
        band: _JoystickSpeedBand.fast,
        stepMultiplier: 6,
        tickStride: 1,
      );
    }
    if (distance >= 88) {
      return const _JoystickSpeed(
        band: _JoystickSpeedBand.medium,
        stepMultiplier: 2,
        tickStride: 1,
      );
    }
    return const _JoystickSpeed(
      band: _JoystickSpeedBand.slow,
      stepMultiplier: 1,
      tickStride: 3,
    );
  }

  _JoystickSpeedBand _speedBandForOffset(double distance) =>
      _speedForOffset(distance).band;

  String? _boundaryLabel(double value) {
    final range = _range;
    if (value <= range.min) return 'Min ${formatHuf(range.min)}';
    if (value >= range.max) return 'Max ${formatHuf(range.max)}';
    return null;
  }

  void _handleTickHaptic(double value) {
    if (_lastTickHapticValue == value) return;
    final now = DateTime.now();
    final last = _lastSelectionHapticAt;
    if (last != null && now.difference(last) < _minimumHapticGap) return;
    _lastTickHapticValue = value;
    _lastSelectionHapticAt = now;
    unawaited(HapticFeedback.selectionClick());
  }

  void _handleBoundaryHaptic(double value) {
    final range = _range;
    final boundary = value <= range.min
        ? _JoystickBoundary.min
        : value >= range.max
        ? _JoystickBoundary.max
        : null;
    if (boundary == null) {
      _lastBoundaryHaptic = null;
      return;
    }
    if (_lastBoundaryHaptic == boundary) return;
    _lastBoundaryHaptic = boundary;
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }
}

class _JoystickDirectionIndicator extends StatelessWidget {
  const _JoystickDirectionIndicator({
    super.key,
    required this.icon,
    required this.active,
  });

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.28,
      duration: const Duration(milliseconds: 100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: active ? 28 : 24,
        height: active ? 28 : 24,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.gray200,
          shape: BoxShape.circle,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: active ? AppColors.white : AppColors.gray500,
          size: active ? 18 : 16,
        ),
      ),
    );
  }
}

class _JoystickSpeedIndicator extends StatelessWidget {
  const _JoystickSpeedIndicator({
    required this.sliderKey,
    required this.speedBand,
  });

  final String sliderKey;
  final _JoystickSpeedBand? speedBand;

  @override
  Widget build(BuildContext context) {
    final activeBars = switch (speedBand) {
      _JoystickSpeedBand.slow => 1,
      _JoystickSpeedBand.medium => 2,
      _JoystickSpeedBand.fast => 3,
      null => 0,
    };
    final activeKey = speedBand == null
        ? null
        : ValueKey('$sliderKey-joystick-speed-${speedBand!.name}');

    return Column(
      key: activeKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 3; index >= 1; index -= 1)
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: index == 3 ? 12 : 10,
            height: index == 3 ? 14 : 10,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: activeBars >= index
                  ? AppColors.primary
                  : AppColors.gray200,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _JoystickSpeed {
  const _JoystickSpeed({
    required this.band,
    required this.stepMultiplier,
    required this.tickStride,
  });

  final _JoystickSpeedBand band;
  final int stepMultiplier;
  final int tickStride;
}

enum _JoystickSpeedBand { slow, medium, fast }

enum _JoystickDirection { increase, decrease }

enum _JoystickBoundary { min, max }
