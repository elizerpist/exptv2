import 'dart:async';

import 'package:flutter/services.dart';

import '../../application/dashboard_budget_limit_edit_controller.dart';

/// Narrow timer seam for deterministic quick-edit mechanics. The production
/// scheduler is a normal one-shot [Timer]; no frame scheduler or tick loop is
/// used for persistence or carousel movement.
abstract interface class BudgetLimitEditTimer {
  void cancel();
}

abstract interface class BudgetLimitEditTimerScheduler {
  BudgetLimitEditTimer schedule(Duration duration, void Function() callback);
}

final class _RealBudgetLimitEditTimer implements BudgetLimitEditTimer {
  _RealBudgetLimitEditTimer(Duration duration, void Function() callback)
    : _timer = Timer(duration, callback);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

final class _RealBudgetLimitEditTimerScheduler
    implements BudgetLimitEditTimerScheduler {
  const _RealBudgetLimitEditTimerScheduler();

  @override
  BudgetLimitEditTimer schedule(Duration duration, void Function() callback) =>
      _RealBudgetLimitEditTimer(duration, callback);
}

enum BudgetLimitEditHaptic { medium, heavy, selection }

typedef BudgetLimitEditHapticCallback = void Function(BudgetLimitEditHaptic);

/// Immutable result of the exact reference drag accumulator drain.
final class BudgetLimitQuickEditBatch {
  const BudgetLimitQuickEditBatch({
    required this.direction,
    required this.tickCount,
    required this.amountStepScaled100,
    required this.remainingAccumulator,
  });

  final int direction;
  final int tickCount;
  final int amountStepScaled100;
  final double remainingAccumulator;

  @override
  bool operator ==(Object other) =>
      other is BudgetLimitQuickEditBatch &&
      other.direction == direction &&
      other.tickCount == tickCount &&
      other.amountStepScaled100 == amountStepScaled100 &&
      other.remainingAccumulator == remainingAccumulator;

  @override
  int get hashCode => Object.hash(
    BudgetLimitQuickEditBatch,
    direction,
    tickCount,
    amountStepScaled100,
    remainingAccumulator,
  );
}

/// Immutable next auto-repeat command. This deliberately carries semantic
/// money units, not a continuous velocity projection.
final class BudgetLimitQuickEditAutoTick {
  const BudgetLimitQuickEditAutoTick({
    required this.direction,
    required this.amountStepScaled100,
    required this.interval,
  });

  final int direction;
  final int amountStepScaled100;
  final Duration interval;

  @override
  bool operator ==(Object other) =>
      other is BudgetLimitQuickEditAutoTick &&
      other.direction == direction &&
      other.amountStepScaled100 == amountStepScaled100 &&
      other.interval == interval;

  @override
  int get hashCode => Object.hash(
    BudgetLimitQuickEditAutoTick,
    direction,
    amountStepScaled100,
    interval,
  );
}

/// Frozen semantic constants from the approved Budget interaction reference.
abstract final class BudgetLimitQuickEditRules {
  static const veryLongDelay = Duration(milliseconds: 720);
  static const veryLongMovementCancelDistance = 5.0;
  static const autoRepeatMinimumDistance = 14.0;
  static const largeStepDistance = 50.0;
  static const smallTickDistance = 12.0;
  static const largeTickDistance = 18.0;
  static const smallStepScaled100 = 100000; // 1,000 HUF
  static const largeStepScaled100 = 1000000; // 10,000 HUF

  static BudgetLimitQuickEditBatch? dragBatch({
    required double accumulator,
    required double totalDistance,
  }) {
    final largeStep = totalDistance >= largeStepDistance;
    final tickDistance = largeStep ? largeTickDistance : smallTickDistance;
    final tickCount = (accumulator.abs() / tickDistance).floor();
    if (tickCount < 1) return null;
    final direction = accumulator > 0 ? 1 : -1;
    return BudgetLimitQuickEditBatch(
      direction: direction,
      tickCount: tickCount,
      amountStepScaled100: largeStep ? largeStepScaled100 : smallStepScaled100,
      remainingAccumulator: accumulator - direction * tickDistance * tickCount,
    );
  }

  static BudgetLimitQuickEditAutoTick? autoTickFor(double lastDy) {
    final distance = lastDy.abs();
    if (distance < autoRepeatMinimumDistance) return null;
    final intervalMs = (440 - distance * 5.2).clamp(80, 440).round();
    return BudgetLimitQuickEditAutoTick(
      direction: lastDy < 0 ? 1 : -1,
      amountStepScaled100: distance >= largeStepDistance
          ? largeStepScaled100
          : smallStepScaled100,
      interval: Duration(milliseconds: intervalMs),
    );
  }
}

/// Presentation/input state machine for the exact Budget quick-limit gesture.
/// It owns raw distance/timers/haptics only; all optimistic money and I/O
/// sequencing remain in [DashboardBudgetLimitEditController].
final class BudgetLimitQuickEditGestureController {
  BudgetLimitQuickEditGestureController({
    required DashboardBudgetLimitEditController edits,
    required DashboardBudgetLimitEditContext Function()
    contextForCurrentSelection,
    BudgetLimitEditTimerScheduler? scheduler,
    BudgetLimitEditHapticCallback? haptic,
  }) : _edits = edits,
       _contextForCurrentSelection = contextForCurrentSelection,
       _scheduler = scheduler ?? const _RealBudgetLimitEditTimerScheduler(),
       _haptic = haptic ?? _platformHaptic;

  final DashboardBudgetLimitEditController _edits;
  final DashboardBudgetLimitEditContext Function() _contextForCurrentSelection;
  final BudgetLimitEditTimerScheduler _scheduler;
  final BudgetLimitEditHapticCallback _haptic;

  DashboardBudgetLimitEditSession? _session;
  BudgetLimitEditTimer? _veryLongTimer;
  BudgetLimitEditTimer? _autoTimer;
  double? _activationGlobalY;
  double _lastDy = 0;
  double _accumulator = 0;
  bool _clearedByVeryLong = false;
  bool _disposed = false;

  bool get isEditing => _session != null;

  void longPressStarted({required double globalY}) {
    if (_disposed) return;
    _cancelTimers();
    final session = _edits.startEdit(_contextForCurrentSelection());
    if (session == null) return;
    _session = session;
    _activationGlobalY = globalY;
    _lastDy = 0;
    _accumulator = 0;
    _clearedByVeryLong = false;
    _haptic(BudgetLimitEditHaptic.medium);
    _veryLongTimer = _scheduler.schedule(
      BudgetLimitQuickEditRules.veryLongDelay,
      () {
        final active = _session;
        if (_disposed ||
            active == null ||
            _lastDy.abs() >
                BudgetLimitQuickEditRules.veryLongMovementCancelDistance) {
          return;
        }
        _clearedByVeryLong = true;
        _autoTimer?.cancel();
        _autoTimer = null;
        _haptic(BudgetLimitEditHaptic.heavy);
        unawaited(_edits.deleteLimit(active));
      },
    );
  }

  void longPressMoved({required double globalY}) {
    final active = _session;
    final activation = _activationGlobalY;
    if (_disposed ||
        active == null ||
        activation == null ||
        _clearedByVeryLong) {
      return;
    }
    final dy = globalY - activation;
    final delta = dy - _lastDy;
    _lastDy = dy;
    if (dy.abs() > BudgetLimitQuickEditRules.veryLongMovementCancelDistance) {
      _veryLongTimer?.cancel();
      _veryLongTimer = null;
    }
    _accumulator += -delta;
    final batch = BudgetLimitQuickEditRules.dragBatch(
      accumulator: _accumulator,
      totalDistance: dy.abs(),
    );
    if (batch != null) {
      _accumulator = batch.remainingAccumulator;
      _apply(
        active,
        direction: batch.direction,
        amountStepScaled100: batch.amountStepScaled100,
        tickCount: batch.tickCount,
        source: DashboardBudgetLimitEditSource.drag,
      );
    }
    _scheduleAutoTick();
  }

  Future<void> longPressEnded() {
    _veryLongTimer?.cancel();
    _veryLongTimer = null;
    _autoTimer?.cancel();
    _autoTimer = null;
    final active = _session;
    _session = null;
    _activationGlobalY = null;
    _lastDy = 0;
    _accumulator = 0;
    _clearedByVeryLong = false;
    if (active == null) return Future<void>.value();
    return _edits.finishEdit(active);
  }

  void _scheduleAutoTick() {
    _autoTimer?.cancel();
    _autoTimer = null;
    final active = _session;
    if (_disposed || active == null || _clearedByVeryLong) return;
    final auto = BudgetLimitQuickEditRules.autoTickFor(_lastDy);
    if (auto == null) return;
    _autoTimer = _scheduler.schedule(auto.interval, () {
      final current = _session;
      if (_disposed || current == null || _clearedByVeryLong) return;
      _apply(
        current,
        direction: auto.direction,
        amountStepScaled100: auto.amountStepScaled100,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.auto,
      );
      _scheduleAutoTick();
    });
  }

  void _apply(
    DashboardBudgetLimitEditSession session, {
    required int direction,
    required int amountStepScaled100,
    required int tickCount,
    required DashboardBudgetLimitEditSource source,
  }) {
    if (_edits.applySemanticTick(
      session,
      direction: direction,
      amountStepScaled100: amountStepScaled100,
      tickCount: tickCount,
      source: source,
    )) {
      // Exactly one feedback event per coalesced semantic invocation.
      _haptic(BudgetLimitEditHaptic.selection);
    }
  }

  void _cancelTimers() {
    _veryLongTimer?.cancel();
    _veryLongTimer = null;
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimers();
    final active = _session;
    _session = null;
    if (active != null) _edits.abortEdit(active);
  }

  static void _platformHaptic(BudgetLimitEditHaptic value) {
    switch (value) {
      case BudgetLimitEditHaptic.medium:
        HapticFeedback.mediumImpact();
      case BudgetLimitEditHaptic.heavy:
        HapticFeedback.heavyImpact();
      case BudgetLimitEditHaptic.selection:
        HapticFeedback.selectionClick();
    }
  }
}
