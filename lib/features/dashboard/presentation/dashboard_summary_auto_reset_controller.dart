import 'dart:async';

import 'package:flutter/foundation.dart';

import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/time_plane.dart';

/// One semantic selector command in the Summary reset journey.  The command
/// is intentionally a target, rather than a replacement navigation state:
/// the mounted selector owns the actual visible tick/crossing path.
@immutable
final class DashboardSummaryAutoResetStep {
  const DashboardSummaryAutoResetStep._({
    required this.kind,
    this.plane,
    this.isRailOpen,
    this.targetValue,
  });

  const DashboardSummaryAutoResetStep.level(TimePlane plane, bool isRailOpen)
    : this._(
        kind: DashboardSummaryAutoResetStepKind.level,
        plane: plane,
        isRailOpen: isRailOpen,
      );

  const DashboardSummaryAutoResetStep.year(int targetValue)
    : this._(
        kind: DashboardSummaryAutoResetStepKind.year,
        targetValue: targetValue,
      );

  const DashboardSummaryAutoResetStep.month(int targetValue)
    : this._(
        kind: DashboardSummaryAutoResetStepKind.month,
        targetValue: targetValue,
      );

  final DashboardSummaryAutoResetStepKind kind;
  final TimePlane? plane;
  final bool? isRailOpen;
  final int? targetValue;

  @override
  bool operator ==(Object other) =>
      other is DashboardSummaryAutoResetStep &&
      kind == other.kind &&
      plane == other.plane &&
      isRailOpen == other.isRailOpen &&
      targetValue == other.targetValue;

  @override
  int get hashCode => Object.hash(kind, plane, isRailOpen, targetValue);

  @override
  String toString() => switch (kind) {
    DashboardSummaryAutoResetStepKind.level =>
      'SummaryReset.level($plane, rail=$isRailOpen)',
    DashboardSummaryAutoResetStepKind.year => 'SummaryReset.year($targetValue)',
    DashboardSummaryAutoResetStepKind.month =>
      'SummaryReset.month($targetValue)',
  };
}

enum DashboardSummaryAutoResetStepKind { level, year, month }

@immutable
final class DashboardSummaryAutoResetPlan {
  const DashboardSummaryAutoResetPlan._(this.steps);

  /// Resolves only the dimensions that need changing. DAY is represented by
  /// MONTH + rail-open in the canonical navigation model, so reset closes the
  /// rail through the same mode selector before temporal component ticks.
  factory DashboardSummaryAutoResetPlan.resolve({
    required TimePlane plane,
    required bool isRailOpen,
    required int year,
    required int month,
    required LocalDate logicalToday,
  }) {
    final steps = <DashboardSummaryAutoResetStep>[
      if (plane != TimePlane.month || isRailOpen)
        const DashboardSummaryAutoResetStep.level(TimePlane.month, false),
      if (year != logicalToday.year)
        DashboardSummaryAutoResetStep.year(logicalToday.year),
      if (month != logicalToday.month)
        DashboardSummaryAutoResetStep.month(logicalToday.month),
    ];
    return DashboardSummaryAutoResetPlan._(
      List<DashboardSummaryAutoResetStep>.unmodifiable(steps),
    );
  }

  final List<DashboardSummaryAutoResetStep> steps;
  bool get isNoop => steps.isEmpty;
}

enum DashboardSummaryAutoResetPhase {
  idle,
  navigatingMode,
  navigatingYear,
  navigatingMonth,
  completed,
  cancelled,
}

typedef DashboardSummaryAutoResetStepRunner =
    FutureOr<void> Function(DashboardSummaryAutoResetStep step);

typedef DashboardSummaryAutoResetMotionRunner =
    Future<void> Function(DashboardSummaryAutoResetStep step);

/// Registry between the reset state machine and the mounted real selectors.
/// It deliberately stores commands rather than navigation state: a reset is
/// visually performed by the same [CenteredCarousel] instances that publish
/// normal selector crossings.
final class DashboardSummaryAutoResetMotionRegistry {
  final Map<
    DashboardSummaryAutoResetStepKind,
    DashboardSummaryAutoResetMotionRunner
  >
  _runners =
      <
        DashboardSummaryAutoResetStepKind,
        DashboardSummaryAutoResetMotionRunner
      >{};
  final Map<DashboardSummaryAutoResetStepKind, Completer<void>> _waiters =
      <DashboardSummaryAutoResetStepKind, Completer<void>>{};
  final Map<DashboardSummaryAutoResetStepKind, VoidCallback> _cancellers =
      <DashboardSummaryAutoResetStepKind, VoidCallback>{};
  bool _isExecuting = false;
  int _motionGeneration = 0;
  VoidCallback? _activeResetCanceller;

  bool get isExecuting => _isExecuting;

  void attach({
    required DashboardSummaryAutoResetStepKind kind,
    required DashboardSummaryAutoResetMotionRunner runner,
    required VoidCallback cancelMotion,
  }) {
    _runners[kind] = runner;
    _cancellers[kind] = cancelMotion;
    _waiters.remove(kind)?.complete();
  }

  void detach({
    required DashboardSummaryAutoResetStepKind kind,
    required DashboardSummaryAutoResetMotionRunner runner,
    required VoidCallback cancelMotion,
  }) {
    if (identical(_runners[kind], runner)) _runners.remove(kind);
    if (identical(_cancellers[kind], cancelMotion)) {
      _cancellers.remove(kind);
    }
    if (identical(_activeResetCanceller, cancelMotion)) {
      _activeResetCanceller = null;
    }
  }

  Future<void> run(DashboardSummaryAutoResetStep step) async {
    final motionGeneration = _motionGeneration;
    _isExecuting = true;
    try {
      var runner = _runners[step.kind];
      if (runner == null) {
        final waiter = _waiters.putIfAbsent(step.kind, Completer<void>.new);
        await waiter.future;
        runner = _runners[step.kind];
      }
      // A background reset can be cancelled while a selector is temporarily
      // absent during a mode transition. Never deliver that old command to a
      // later-mounted selector.
      if (runner == null || motionGeneration != _motionGeneration) return;
      // The selector being run below is the only physical motion this reset
      // command owns. A foreground pointer may cancel this exact animation,
      // but must never broadcast a jump to unrelated or user-owned rails.
      final cancelMotion = _cancellers[step.kind];
      _activeResetCanceller = cancelMotion;
      try {
        await runner(step);
      } finally {
        if (motionGeneration == _motionGeneration) {
          _activeResetCanceller = null;
        }
      }
    } finally {
      _isExecuting = false;
    }
  }

  /// Invalidates a reset command and, only when it is currently running,
  /// interrupts the one programmatic selector animation that command owns.
  ///
  /// This is deliberately not a mounted-selector broadcast. A direct user
  /// pointer is allowed to start on one of those selectors and therefore must
  /// never cancel its own newly acquired ScrollActivity.
  void cancelActiveResetMotion() {
    _motionGeneration += 1;
    final cancel = _activeResetCanceller;
    _activeResetCanceller = null;
    cancel?.call();
  }
}

/// Bounded, generation-guarded reset sequencer. It knows no query state and
/// cannot publish navigation itself; each command is delegated to the normal
/// mounted Summary selector, which is the existing prepared tick pipeline.
final class DashboardSummaryAutoResetController extends ChangeNotifier {
  DashboardSummaryAutoResetPhase _phase = DashboardSummaryAutoResetPhase.idle;
  int _generation = 0;

  DashboardSummaryAutoResetPhase get phase => _phase;
  bool get isRunning => switch (_phase) {
    DashboardSummaryAutoResetPhase.navigatingMode ||
    DashboardSummaryAutoResetPhase.navigatingYear ||
    DashboardSummaryAutoResetPhase.navigatingMonth => true,
    DashboardSummaryAutoResetPhase.idle ||
    DashboardSummaryAutoResetPhase.completed ||
    DashboardSummaryAutoResetPhase.cancelled => false,
  };

  Future<void> start({
    required DashboardSummaryAutoResetPlan plan,
    required DashboardSummaryAutoResetStepRunner runStep,
  }) async {
    cancel(notify: false);
    if (plan.isNoop) {
      _setPhase(DashboardSummaryAutoResetPhase.completed);
      return;
    }
    final generation = ++_generation;
    for (final step in plan.steps) {
      if (generation != _generation) return;
      _setPhase(switch (step.kind) {
        DashboardSummaryAutoResetStepKind.level =>
          DashboardSummaryAutoResetPhase.navigatingMode,
        DashboardSummaryAutoResetStepKind.year =>
          DashboardSummaryAutoResetPhase.navigatingYear,
        DashboardSummaryAutoResetStepKind.month =>
          DashboardSummaryAutoResetPhase.navigatingMonth,
      });
      await runStep(step);
      if (generation != _generation) return;
    }
    if (generation == _generation) {
      _setPhase(DashboardSummaryAutoResetPhase.completed);
    }
  }

  void cancel({bool notify = true}) {
    _generation += 1;
    if (!isRunning) return;
    _phase = DashboardSummaryAutoResetPhase.cancelled;
    if (notify) notifyListeners();
  }

  void _setPhase(DashboardSummaryAutoResetPhase value) {
    if (_phase == value) return;
    _phase = value;
    notifyListeners();
  }
}
