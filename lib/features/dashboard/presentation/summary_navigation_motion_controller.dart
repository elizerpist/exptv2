import 'package:flutter/foundation.dart';

import '../time_navigation/application/summary_timing_debug.dart';
import '../time_navigation/presentation/summary_navigation_presentation.dart';

/// Presentation-only intents shared by the rail adapter and SummaryPill text.
///
/// This controller intentionally has no ticker, navigation, query, amount or
/// haptic dependency.  The motion region owns animation lifecycles; callers
/// only publish semantic visual intents.
class SummaryNavigationMotionController extends ChangeNotifier {
  SummaryRailTick? _railTick;
  int? _lastRailTickLogicalIndex;
  SummaryHorizontalMotion _horizontalMotion =
      const SummaryHorizontalMotion.idle();

  SummaryRailTick? get railTick => _railTick;
  SummaryHorizontalMotion get horizontalMotion => _horizontalMotion;

  /// Returns true only for a new visible rail center. The TimeRail establishes
  /// its initial/reconfigure baseline before calling this method.
  bool triggerRailTick({
    required int oldLogicalIndex,
    required int newLogicalIndex,
  }) {
    if (oldLogicalIndex == newLogicalIndex ||
        _lastRailTickLogicalIndex == newLogicalIndex) {
      return false;
    }
    _lastRailTickLogicalIndex = newLogicalIndex;
    _railTick = SummaryRailTick(oldLogicalIndex, newLogicalIndex);
    DashboardSummaryTimingDebug.mark(
      'S-TICK',
      value:
          'oldLogicalIndex=$oldLogicalIndex newLogicalIndex=$newLogicalIndex '
          'reason=railPreviewTick impulseTriggered=true queryStarted=false',
    );
    notifyListeners();
    return true;
  }

  /// Re-establishes a non-animated visual baseline after initial layout,
  /// recenter, rebase or data-source reconfiguration.
  void resetRailTickBaseline(int logicalIndex) {
    _lastRailTickLogicalIndex = logicalIndex;
  }

  void beginHorizontalDrag({
    required SummaryTransitionDirection direction,
    required bool canNavigate,
  }) {
    _horizontalMotion = SummaryHorizontalMotion(
      phase: canNavigate
          ? SummaryHorizontalMotionPhase.dragging
          : SummaryHorizontalMotionPhase.resisting,
      direction: direction,
      progress: 0,
      canNavigate: canNavigate,
      generation: _horizontalMotion.generation + 1,
    );
    notifyListeners();
  }

  void updateHorizontalDragProgress(double progress) {
    final current = _horizontalMotion;
    if (!current.isInteractive) return;
    final clamped = progress.abs().clamp(0.0, 1.0).toDouble();
    if (clamped == current.progress) return;
    _horizontalMotion = current.copyWith(progress: clamped);
    notifyListeners();
  }

  /// Returns false for the SUM resistance path, which has no parent commit.
  bool commitHorizontalDrag() {
    final current = _horizontalMotion;
    if (current.phase != SummaryHorizontalMotionPhase.dragging) return false;
    _horizontalMotion = current.copyWith(
      phase: SummaryHorizontalMotionPhase.committed,
    );
    notifyListeners();
    return true;
  }

  void cancelHorizontalDrag() {
    final current = _horizontalMotion;
    if (!current.isInteractive) return;
    _horizontalMotion = current.copyWith(
      phase: SummaryHorizontalMotionPhase.cancelled,
    );
    notifyListeners();
  }

  /// Called only by the presentation region when its local return/commit
  /// animation is finished. It cannot affect navigation or query state.
  void clearHorizontalMotion({int? generation}) {
    if (_horizontalMotion.phase == SummaryHorizontalMotionPhase.idle) return;
    if (generation != null && generation != _horizontalMotion.generation) {
      return;
    }
    _horizontalMotion = const SummaryHorizontalMotion.idle();
    notifyListeners();
  }
}

@immutable
class SummaryRailTick {
  const SummaryRailTick(this.oldLogicalIndex, this.newLogicalIndex);

  final int oldLogicalIndex;
  final int newLogicalIndex;

  @override
  bool operator ==(Object other) =>
      other is SummaryRailTick &&
      other.oldLogicalIndex == oldLogicalIndex &&
      other.newLogicalIndex == newLogicalIndex;

  @override
  int get hashCode => Object.hash(oldLogicalIndex, newLogicalIndex);
}

enum SummaryHorizontalMotionPhase {
  idle,
  dragging,
  resisting,
  committed,
  cancelled,
}

@immutable
class SummaryHorizontalMotion {
  const SummaryHorizontalMotion({
    required this.phase,
    required this.direction,
    required this.progress,
    required this.canNavigate,
    required this.generation,
  });

  const SummaryHorizontalMotion.idle()
    : phase = SummaryHorizontalMotionPhase.idle,
      direction = SummaryTransitionDirection.forward,
      progress = 0,
      canNavigate = false,
      generation = 0;

  final SummaryHorizontalMotionPhase phase;
  final SummaryTransitionDirection direction;
  final double progress;
  final bool canNavigate;

  /// Identifies one interactive gesture so a stale local completion cannot
  /// clear a later drag or commit.
  final int generation;

  bool get isInteractive =>
      phase == SummaryHorizontalMotionPhase.dragging ||
      phase == SummaryHorizontalMotionPhase.resisting;

  SummaryHorizontalMotion copyWith({
    SummaryHorizontalMotionPhase? phase,
    SummaryTransitionDirection? direction,
    double? progress,
    bool? canNavigate,
    int? generation,
  }) => SummaryHorizontalMotion(
    phase: phase ?? this.phase,
    direction: direction ?? this.direction,
    progress: progress ?? this.progress,
    canNavigate: canNavigate ?? this.canNavigate,
    generation: generation ?? this.generation,
  );
}
