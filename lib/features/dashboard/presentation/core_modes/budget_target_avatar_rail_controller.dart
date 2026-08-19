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
  BudgetTargetAvatarRailCommandDelegate? _delegate;
  BudgetTargetAvatarRailRequest? _lastRequest;

  BudgetTargetAvatarRailRequest? get lastRequest => _lastRequest;

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
    await delegate.animateToLogicalIndex(currentLogical + delta);
  }

  static int _modulo(int value, int divisor) =>
      ((value % divisor) + divisor) % divisor;
}
