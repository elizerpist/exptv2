import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';

/// Attribution only. The existing rail remains the sole semantic crossing,
/// haptic, ScrollController and physics owner.
enum BudgetTargetNavigationSource { pieSlice, pieCenter, categoryList }

abstract interface class BudgetTargetAvatarRailCommandDelegate {
  int get logicalIndex;
  int get targetCount;

  Future<void> animateToLogicalIndex(int logicalIndex);
}

@immutable
final class BudgetTargetAvatarRailRequest {
  const BudgetTargetAvatarRailRequest({
    required this.source,
    required this.fromHandle,
    required this.targetHandle,
    required this.nearestStepCount,
  });

  final BudgetTargetNavigationSource source;
  final int fromHandle;
  final int targetHandle;
  final int nearestStepCount;
}

/// A CoreDashboard-lifetime command seam for surfaces such as the distribution
/// card. It forwards to the one existing avatar rail; it cannot own motion or
/// mutate Budget semantic selection itself.
final class BudgetTargetAvatarRailController extends ChangeNotifier {
  BudgetTargetAvatarRailController({this.onExplicitTargetIntent});

  BudgetTargetAvatarRailCommandDelegate? _delegate;
  BudgetTargetAvatarRailRequest? _lastRequest;
  int _explicitTargetIntentInFlightCount = 0;

  /// A pie/list command can be meaningful even when its target is already
  /// centred, so it is distinct from a carousel settle callback.
  final ValueChanged<BudgetTargetAvatarRailRequest>? onExplicitTargetIntent;

  BudgetTargetAvatarRailRequest? get lastRequest => _lastRequest;

  /// The rail uses this only to avoid committing the same LogBox focus twice:
  /// an explicit pie/list command already commits at this controller's
  /// command seam after its carousel animation completes. A direct avatar tap
  /// is not an explicit command and therefore remains settle-committed.
  bool get isExplicitTargetIntentInFlight =>
      _explicitTargetIntentInFlightCount > 0;

  void attach(BudgetTargetAvatarRailCommandDelegate delegate) {
    _delegate = delegate;
  }

  void detach(BudgetTargetAvatarRailCommandDelegate delegate) {
    if (identical(_delegate, delegate)) _delegate = null;
  }

  Future<void> animateToTargetHandle(
    int targetHandle, {
    required BudgetTargetNavigationSource source,
  }) async {
    final delegate = _delegate;
    if (delegate == null ||
        delegate.targetCount <= 0 ||
        targetHandle < 0 ||
        targetHandle >= delegate.targetCount) {
      return;
    }
    final currentLogical = delegate.logicalIndex;
    final count = delegate.targetCount;
    final fromHandle = _modulo(currentLogical, count);
    final forward = _modulo(targetHandle - fromHandle, count);
    final backward = forward - count;
    // Ties choose forward to remain deterministic. With an odd-length Budget
    // domain there is no tie, but the command seam is intentionally general.
    final delta = forward.abs() <= backward.abs() ? forward : backward;
    final request = BudgetTargetAvatarRailRequest(
      source: source,
      fromHandle: fromHandle,
      targetHandle: targetHandle,
      nearestStepCount: delta.abs(),
    );
    _lastRequest = request;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_DISTRIBUTION_TARGET_REQUESTED',
        scope:
            'source=${source.name} fromHandle=$fromHandle '
            'targetHandle=$targetHandle nearestStepCount=${delta.abs()}',
      ),
    );
    _explicitTargetIntentInFlightCount += 1;
    try {
      await delegate.animateToLogicalIndex(currentLogical + delta);
    } finally {
      _explicitTargetIntentInFlightCount -= 1;
    }
    if (_modulo(delegate.logicalIndex, count) == targetHandle) {
      onExplicitTargetIntent?.call(request);
    }
  }

  static int _modulo(int value, int divisor) =>
      ((value % divisor) + divisor) % divisor;
}
