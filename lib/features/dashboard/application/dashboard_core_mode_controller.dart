import 'package:flutter/foundation.dart';

import 'dashboard_mode_spec.dart';

enum DashboardCoreModeDirection { forward, backward }

@immutable
class DashboardCoreModeSwitchEvent {
  const DashboardCoreModeSwitchEvent({
    required this.fromMode,
    required this.toMode,
    required this.direction,
  });

  final DashboardModeSpec fromMode;
  final DashboardModeSpec toMode;
  final DashboardCoreModeDirection direction;
}

typedef DashboardCoreModeSwitchObserver =
    void Function(DashboardCoreModeSwitchEvent event);

/// Headless owner of the semantic dashboard-core mode ring.
///
/// It intentionally has no repository, Query, LogBox, rendering, gesture or
/// ticker dependency. A header gesture supplies one direction, and this owner
/// atomically publishes exactly one replacement mode.
final class DashboardCoreModeController extends ChangeNotifier {
  DashboardCoreModeController({
    required DashboardModeSpec initialMode,
    this.onModeSwitched,
  }) : _committedMode = _canonicalMode(initialMode);

  final DashboardCoreModeSwitchObserver? onModeSwitched;
  DashboardModeSpec _committedMode;

  DashboardModeSpec get committedMode => _committedMode;

  /// Immediately advances to one adjacent logical mode in the fixed ring.
  bool switchMode(DashboardCoreModeDirection direction) {
    final source = _committedMode;
    final target = _neighbourOf(source, direction);
    _committedMode = target;
    onModeSwitched?.call(
      DashboardCoreModeSwitchEvent(
        fromMode: source,
        toMode: target,
        direction: direction,
      ),
    );
    notifyListeners();
    return true;
  }

  /// Applies an external shell configuration as one immediate semantic write.
  bool setProgrammaticMode(DashboardModeSpec mode) {
    final next = _canonicalMode(mode);
    if (identical(next, _committedMode)) return false;
    _committedMode = next;
    notifyListeners();
    return true;
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
