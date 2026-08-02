import 'package:flutter/foundation.dart';

import '../time_navigation/application/summary_timing_debug.dart';
import '../time_navigation/presentation/summary_navigation_presentation.dart';
import 'summary_text_content.dart';

/// Presentation-only intents shared by the rail adapter and SummaryPill text.
///
/// This controller intentionally has no ticker, navigation, query, amount or
/// haptic dependency.  The motion region owns animation lifecycles; callers
/// only publish semantic visual intents.
class SummaryNavigationMotionController extends ChangeNotifier {
  SummaryRailTick? _railTick;
  int? _lastRailTickLogicalIndex;
  SummaryStagedTextTransition _stagedText =
      const SummaryStagedTextTransition.idle();
  int _stagedTextGeneration = 0;
  SummaryHorizontalMotion _horizontalMotion =
      const SummaryHorizontalMotion.idle();

  SummaryRailTick? get railTick => _railTick;
  SummaryStagedTextTransition get stagedText => _stagedText;

  /// Legacy interactive text state retained only until its two current
  /// consumers migrate to [stagedText]. It does not participate in the staged
  /// shell-to-text flow.
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

  /// Captures the currently visible navigation text while the local pill shell
  /// returns to its resting paint transform. This is presentation-only.
  int holdTextForShellReturn({
    required SummaryTextContent outgoing,
    required SummaryTransitionAxis axis,
    required SummaryTransitionDirection direction,
  }) {
    final generation = ++_stagedTextGeneration;
    _stagedText = SummaryStagedTextTransition(
      phase: SummaryStagedTextPhase.holding,
      outgoing: outgoing,
      incoming: null,
      axis: axis,
      direction: direction,
      generation: generation,
    );
    notifyListeners();
    return generation;
  }

  /// Binds the new canonical navigation text after navigation has committed.
  /// A stale shell callback cannot replace a newer snapshot.
  void bindShellReturnIncoming({
    required int generation,
    required SummaryTextContent incoming,
  }) {
    final current = _stagedText;
    if (current.generation != generation ||
        current.phase != SummaryStagedTextPhase.holding) {
      return;
    }
    _stagedText = current.copyWith(incoming: incoming);
    notifyListeners();
  }

  /// Activates the common X/Y text transition only after the matching shell
  /// return reaches Offset.zero.
  void completeShellReturn({required int generation}) {
    final current = _stagedText;
    if (current.generation != generation ||
        current.phase != SummaryStagedTextPhase.holding ||
        current.incoming == null) {
      return;
    }
    _stagedText = current.copyWith(phase: SummaryStagedTextPhase.transitioning);
    notifyListeners();
  }

  /// Clears only the matching completed presentation transition.
  void completeTextTransition({required int generation}) {
    final current = _stagedText;
    if (current.generation != generation ||
        current.phase != SummaryStagedTextPhase.transitioning) {
      return;
    }
    _stagedText = SummaryStagedTextTransition.idle(generation: generation);
    notifyListeners();
  }

  /// Invalidates any local presentation callback without writing navigation or
  /// query state. A fresh token protects the next gesture from stale work.
  void cancelStagedTextMotion() {
    _stagedText = SummaryStagedTextTransition.idle(
      generation: ++_stagedTextGeneration,
    );
    notifyListeners();
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

enum SummaryStagedTextPhase { idle, holding, transitioning }

@immutable
class SummaryStagedTextTransition {
  const SummaryStagedTextTransition.idle({this.generation = 0})
    : phase = SummaryStagedTextPhase.idle,
      outgoing = null,
      incoming = null,
      axis = SummaryTransitionAxis.none,
      direction = SummaryTransitionDirection.forward;

  const SummaryStagedTextTransition({
    required this.phase,
    required this.outgoing,
    required this.incoming,
    required this.axis,
    required this.direction,
    required this.generation,
  });

  final SummaryStagedTextPhase phase;
  final SummaryTextContent? outgoing;
  final SummaryTextContent? incoming;
  final SummaryTransitionAxis axis;
  final SummaryTransitionDirection direction;
  final int generation;

  bool get isAxisMotionActive => phase != SummaryStagedTextPhase.idle;

  SummaryStagedTextTransition copyWith({
    SummaryStagedTextPhase? phase,
    SummaryTextContent? outgoing,
    SummaryTextContent? incoming,
    SummaryTransitionAxis? axis,
    SummaryTransitionDirection? direction,
    int? generation,
  }) => SummaryStagedTextTransition(
    phase: phase ?? this.phase,
    outgoing: outgoing ?? this.outgoing,
    incoming: incoming ?? this.incoming,
    axis: axis ?? this.axis,
    direction: direction ?? this.direction,
    generation: generation ?? this.generation,
  );
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
