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
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 112),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerMove: _handlePointerMove,
              onPointerUp: (_) => _finishJoystick(),
              onPointerCancel: (_) => _finishJoystick(),
              child: GestureDetector(
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
                    child: Icon(Icons.tune, color: AppColors.white, size: 18),
                  ),
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
    _dragOffsetY = activationGlobalY == null
        ? details.offsetFromOrigin.dy
        : details.globalPosition.dy - activationGlobalY;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final activationGlobalY = _activationGlobalY;
    if (!_active || activationGlobalY == null) return;
    _dragOffsetY = event.position.dy - activationGlobalY;
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
    final range = _range;
    final direction = _dragOffsetY < 0 ? 1 : -1;
    final speed = _speedForOffset(_dragOffsetY.abs());
    final next = range.snap(_currentValue + direction * range.step * speed);
    if (next == _currentValue) {
      _handleBoundaryHaptic(next);
      return;
    }
    setState(() => _currentValue = next);
    widget.onChanged(next);
    _handleTickHaptic(next);
    _handleBoundaryHaptic(next);
  }

  int _speedForOffset(double distance) {
    if (distance >= 140) return 5;
    if (distance >= 90) return 3;
    return 1;
  }

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

enum _JoystickBoundary { min, max }
