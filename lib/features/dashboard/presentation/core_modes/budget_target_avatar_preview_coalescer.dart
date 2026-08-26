import 'package:flutter/foundation.dart';

/// Synchronous prepared-data bridge from one carousel crossing to the Budget
/// preview. Each accepted discrete target owns one amount/preview publication;
/// it must never wait for a display frame or fling settlement. The Core still
/// defers only the geometry-heavy LogBox scene publication behind this lane.
final class BudgetTargetAvatarPreviewPublisher {
  BudgetTargetAvatarPreviewPublisher({required this.onPublish});

  final ValueChanged<int> onPublish;
  bool _disposed = false;
  int _semanticCrossings = 0;
  int _previewPublications = 0;

  int get semanticCrossings => _semanticCrossings;
  int get previewPublications => _previewPublications;

  void submit(int targetHandle) {
    if (_disposed) return;
    _semanticCrossings += 1;
    _previewPublications += 1;
    onPublish(targetHandle);
  }

  void dispose() {
    _disposed = true;
  }
}
