import 'dart:async';

import 'dashboard_background_work_coordinator.dart';

/// Semantic facade for adjacent-parent jobs on the shared dashboard queue.
///
/// Scheduling, dedupe, priority and motion gating live exclusively in
/// [DashboardBackgroundWorkCoordinator]; this adapter only supplies the
/// adjacent-parent job identity and compatibility counters.
class DashboardAdjacentParentPrewarmCoordinator {
  DashboardAdjacentParentPrewarmCoordinator({
    DashboardBackgroundWorkCoordinator? backgroundWork,
    bool ownsBackgroundWork = true,
  }) : _backgroundWork = backgroundWork ?? DashboardBackgroundWorkCoordinator(),
       _ownsBackgroundWork = ownsBackgroundWork;

  final DashboardBackgroundWorkCoordinator _backgroundWork;
  final bool _ownsBackgroundWork;
  int _generation = 0;
  int _prewarmStartedCount = 0;
  int _nextLocalInteractionEpoch = 0;
  int? _activeInteractionEpoch;
  int? _activeTaskGeneration;
  DashboardBackgroundWorkToken? _activeToken;
  bool _disposed = false;

  bool get isMotionActive => _backgroundWork.isInteractionActive;
  int get prewarmStartedCount => _prewarmStartedCount;

  void beginMotion({int? interactionEpoch}) {
    if (_disposed) return;
    final epoch = interactionEpoch ?? ++_nextLocalInteractionEpoch;
    _activeInteractionEpoch = epoch;
    _backgroundWork.beginInteraction(epoch);
  }

  void endMotion({int? interactionEpoch}) {
    if (_disposed) return;
    final epoch = interactionEpoch ?? _activeInteractionEpoch;
    if (epoch == null) return;
    _backgroundWork.endInteraction(epoch);
    if (_activeInteractionEpoch == epoch) _activeInteractionEpoch = null;
  }

  void schedule(
    Future<void> Function(int generation) task, {
    String semanticKey = 'adjacentParent',
  }) {
    if (_disposed) return;
    final generation = ++_generation;
    unawaited(
      _backgroundWork.schedule(
        key: DashboardBackgroundJobKey(
          type: DashboardBackgroundJobType.adjacentParentPrewarm,
          semanticKey: semanticKey,
        ),
        priority: DashboardBackgroundPriority.low,
        supersedeGroup: 'adjacentParentPrewarm',
        task: (token) async {
          _prewarmStartedCount += 1;
          _activeTaskGeneration = generation;
          _activeToken = token;
          if (!token.canContinue) return false;
          await task(generation);
          return token.canContinue;
        },
      ),
    );
  }

  bool isGenerationCurrent(int generation) =>
      !_disposed &&
      _activeTaskGeneration == generation &&
      (_activeToken?.canContinue ?? false);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeToken = null;
    _activeTaskGeneration = null;
    if (_ownsBackgroundWork) _backgroundWork.dispose();
  }
}
