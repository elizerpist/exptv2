import 'package:flutter/foundation.dart';

import 'dashboard_mode_spec.dart';

enum DashboardCoreModeDirection { forward, backward }

enum DashboardCoreModeTransitionPhase {
  idle,
  dragging,
  settlingCommitted,
  settlingCancelled,
}

enum DashboardCoreModeTransitionEventKind { started, committed, cancelled }

@immutable
class DashboardCoreModeTransition {
  const DashboardCoreModeTransition._({
    required this.phase,
    this.targetMode,
    this.direction,
  });

  const DashboardCoreModeTransition.idle()
    : this._(phase: DashboardCoreModeTransitionPhase.idle);

  final DashboardCoreModeTransitionPhase phase;
  final DashboardModeSpec? targetMode;
  final DashboardCoreModeDirection? direction;

  bool get isActive => phase != DashboardCoreModeTransitionPhase.idle;
}

@immutable
class DashboardCoreModeTransitionEvent {
  const DashboardCoreModeTransitionEvent({
    required this.kind,
    required this.fromMode,
    required this.targetMode,
    required this.direction,
  });

  final DashboardCoreModeTransitionEventKind kind;
  final DashboardModeSpec fromMode;
  final DashboardModeSpec targetMode;
  final DashboardCoreModeDirection direction;
}

typedef DashboardCoreModeTransitionObserver =
    void Function(DashboardCoreModeTransitionEvent event);

/// Headless owner of the semantic dashboard-core mode ring.
///
/// It intentionally has no repository, Query, LogBox, rendering, gesture or
/// ticker dependency. Presentation owns drag progress and asks this controller
/// only to start, commit, cancel and complete one already-chosen neighbour.
final class DashboardCoreModeController extends ChangeNotifier {
  DashboardCoreModeController({
    required DashboardModeSpec initialMode,
    this.onTransitionEvent,
  }) : _committedMode = _canonicalMode(initialMode);

  final DashboardCoreModeTransitionObserver? onTransitionEvent;
  DashboardModeSpec _committedMode;
  DashboardCoreModeTransition _transition =
      const DashboardCoreModeTransition.idle();

  DashboardModeSpec get committedMode => _committedMode;
  DashboardCoreModeTransition get transition => _transition;

  bool beginTransition(DashboardCoreModeDirection direction) {
    if (_transition.isActive) return false;
    final target = _neighbourOf(_committedMode, direction);
    _transition = DashboardCoreModeTransition._(
      phase: DashboardCoreModeTransitionPhase.dragging,
      targetMode: target,
      direction: direction,
    );
    _publish(
      DashboardCoreModeTransitionEventKind.started,
      fromMode: _committedMode,
      targetMode: target,
      direction: direction,
    );
    notifyListeners();
    return true;
  }

  bool commitTransition() {
    if (_transition.phase != DashboardCoreModeTransitionPhase.dragging) {
      return false;
    }
    final target = _transition.targetMode!;
    final direction = _transition.direction!;
    final source = _committedMode;
    _committedMode = target;
    _transition = DashboardCoreModeTransition._(
      phase: DashboardCoreModeTransitionPhase.settlingCommitted,
      targetMode: target,
      direction: direction,
    );
    _publish(
      DashboardCoreModeTransitionEventKind.committed,
      fromMode: source,
      targetMode: target,
      direction: direction,
    );
    notifyListeners();
    return true;
  }

  bool cancelTransition() {
    if (_transition.phase != DashboardCoreModeTransitionPhase.dragging) {
      return false;
    }
    final target = _transition.targetMode!;
    final direction = _transition.direction!;
    _transition = DashboardCoreModeTransition._(
      phase: DashboardCoreModeTransitionPhase.settlingCancelled,
      targetMode: target,
      direction: direction,
    );
    _publish(
      DashboardCoreModeTransitionEventKind.cancelled,
      fromMode: _committedMode,
      targetMode: target,
      direction: direction,
    );
    notifyListeners();
    return true;
  }

  bool completeTransition() {
    switch (_transition.phase) {
      case DashboardCoreModeTransitionPhase.settlingCommitted:
      case DashboardCoreModeTransitionPhase.settlingCancelled:
        _transition = const DashboardCoreModeTransition.idle();
        notifyListeners();
        return true;
      case DashboardCoreModeTransitionPhase.idle:
      case DashboardCoreModeTransitionPhase.dragging:
        return false;
    }
  }

  /// Applies an external shell configuration only while no pointer transition
  /// owns an in-flight source/target pair.
  bool setProgrammaticMode(DashboardModeSpec mode) {
    if (_transition.isActive) return false;
    final next = _canonicalMode(mode);
    if (identical(next, _committedMode)) return false;
    _committedMode = next;
    notifyListeners();
    return true;
  }

  void _publish(
    DashboardCoreModeTransitionEventKind kind, {
    required DashboardModeSpec fromMode,
    required DashboardModeSpec targetMode,
    required DashboardCoreModeDirection direction,
  }) {
    onTransitionEvent?.call(
      DashboardCoreModeTransitionEvent(
        kind: kind,
        fromMode: fromMode,
        targetMode: targetMode,
        direction: direction,
      ),
    );
  }

  static DashboardModeSpec _canonicalMode(DashboardModeSpec mode) {
    for (final candidate in DashboardModeSpec.values) {
      if (candidate.mode == mode.mode) return candidate;
    }
    throw ArgumentError.value(mode, 'mode', 'must be a DashboardModeSpec');
  }

  static DashboardModeSpec _neighbourOf(
    DashboardModeSpec source,
    DashboardCoreModeDirection direction,
  ) {
    return switch (direction) {
      DashboardCoreModeDirection.forward => _nextOf(source),
      DashboardCoreModeDirection.backward => _previousOf(source),
    };
  }

  static DashboardModeSpec _nextOf(DashboardModeSpec source) {
    var returnNext = false;
    for (final candidate in DashboardModeSpec.values) {
      if (returnNext) return candidate;
      if (candidate.mode == source.mode) returnNext = true;
    }
    return DashboardModeSpec.values.first;
  }

  static DashboardModeSpec _previousOf(DashboardModeSpec source) {
    DashboardModeSpec? previous;
    for (final candidate in DashboardModeSpec.values) {
      if (candidate.mode == source.mode) {
        return previous ?? DashboardModeSpec.values.last;
      }
      previous = candidate;
    }
    throw ArgumentError.value(source, 'source', 'must be a DashboardModeSpec');
  }
}
