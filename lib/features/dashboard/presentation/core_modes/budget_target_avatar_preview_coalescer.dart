import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Latest-value-wins bridge from carousel semantic crossings to the lightweight
/// Budget visual preview. It deliberately uses a display-frame callback: a
/// fling may cross several obsolete targets before the next frame, while the
/// Header only needs the one actually visible target.
final class BudgetTargetAvatarPreviewCoalescer {
  BudgetTargetAvatarPreviewCoalescer({
    required this.onPublish,
    FrameCallbackScheduler? scheduleFrame,
  }) : _scheduleFrame = scheduleFrame ?? _scheduleProductionFrame;

  final ValueChanged<int> onPublish;
  final FrameCallbackScheduler _scheduleFrame;
  int? _latestTargetHandle;
  bool _scheduled = false;
  bool _disposed = false;
  int _semanticCrossings = 0;
  int _previewPublications = 0;

  int get semanticCrossings => _semanticCrossings;
  int get previewPublications => _previewPublications;

  void submit(int targetHandle) {
    if (_disposed) return;
    _semanticCrossings += 1;
    _latestTargetHandle = targetHandle;
    if (_scheduled) return;
    _scheduled = true;
    _scheduleFrame(_publishLatest);
  }

  /// Settlement must never leave the final selected target waiting behind a
  /// frame callback. This is a flush of the same latest transient value, not a
  /// second semantic publication.
  void flushNow() {
    if (_disposed || _latestTargetHandle == null) return;
    _publishLatest(Duration.zero);
  }

  void _publishLatest(Duration _) {
    _scheduled = false;
    if (_disposed) return;
    final targetHandle = _latestTargetHandle;
    _latestTargetHandle = null;
    if (targetHandle == null) return;
    _previewPublications += 1;
    onPublish(targetHandle);
  }

  void dispose() {
    _disposed = true;
    _latestTargetHandle = null;
  }

  static void _scheduleProductionFrame(FrameCallback callback) =>
      SchedulerBinding.instance.scheduleFrameCallback(callback);
}

typedef FrameCallbackScheduler = void Function(FrameCallback callback);
