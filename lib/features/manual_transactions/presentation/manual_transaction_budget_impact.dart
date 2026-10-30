import 'package:flutter/foundation.dart';

/// Maps the exact, already-resolved Budget amounts to a drawable bar.
///
/// Amounts remain scaled by 100 throughout this class. Only the final segment
/// ratios use doubles, which keeps the editor preview aligned with the Budget
/// calculation while making zero limits and overrun states safe to paint.
@immutable
final class ManualTransactionBudgetImpactPresentation {
  const ManualTransactionBudgetImpactPresentation._({
    required this.limitScaled100,
    required this.spentScaled100,
    required this.draftScaled100,
    required this.totalScaled100,
    required this.remainingScaled100,
    required this.overrunScaled100,
    required this.spentFraction,
    required this.draftFraction,
    required this.remainingFraction,
    required this.limitFraction,
    required this.isOverrun,
  });

  factory ManualTransactionBudgetImpactPresentation.calculate({
    required int limitScaled100,
    required int spentScaled100,
    required int draftScaled100,
  }) {
    // Repository values are non-negative monetary magnitudes. Keep drawing
    // defensive in case a partial or legacy record violates that contract.
    final limit = limitScaled100 < 0 ? 0 : limitScaled100;
    final spent = spentScaled100 < 0 ? 0 : spentScaled100;
    final draft = draftScaled100 < 0 ? 0 : draftScaled100;
    final total = spent + draft;
    final remaining = limit - total;
    final isOverrun = total > limit;
    final overrun = isOverrun ? total - limit : 0;

    if (isOverrun) {
      // In an overrun the full painted length represents the actual post-save
      // spend, so the Budget boundary remains meaningful inside the bar.
      final scale = total;
      return ManualTransactionBudgetImpactPresentation._(
        limitScaled100: limit,
        spentScaled100: spent,
        draftScaled100: draft,
        totalScaled100: total,
        remainingScaled100: remaining,
        overrunScaled100: overrun,
        spentFraction: spent / scale,
        draftFraction: draft / scale,
        remainingFraction: 0,
        limitFraction: limit / scale,
        isOverrun: true,
      );
    }

    // A zero total against a zero limit is drawable without any divide-by-zero
    // ratio. The editor does not request this for an invalid/empty draft, but
    // handling it here keeps the presentation object total.
    if (limit == 0) {
      return ManualTransactionBudgetImpactPresentation._(
        limitScaled100: limit,
        spentScaled100: spent,
        draftScaled100: draft,
        totalScaled100: total,
        remainingScaled100: remaining,
        overrunScaled100: 0,
        spentFraction: 0,
        draftFraction: 0,
        remainingFraction: 0,
        limitFraction: 0,
        isOverrun: false,
      );
    }

    return ManualTransactionBudgetImpactPresentation._(
      limitScaled100: limit,
      spentScaled100: spent,
      draftScaled100: draft,
      totalScaled100: total,
      remainingScaled100: remaining,
      overrunScaled100: 0,
      spentFraction: spent / limit,
      draftFraction: draft / limit,
      remainingFraction: remaining / limit,
      limitFraction: 1,
      isOverrun: false,
    );
  }

  final int limitScaled100;
  final int spentScaled100;
  final int draftScaled100;
  final int totalScaled100;
  final int remainingScaled100;
  final int overrunScaled100;

  final double spentFraction;
  final double draftFraction;
  final double remainingFraction;

  /// The Budget boundary within the painted scale. It is only rendered for an
  /// overrun, where it is strictly below one (or zero for a zero budget).
  final double limitFraction;
  final bool isOverrun;

  bool get isExhausted => !isOverrun && remainingScaled100 == 0;
}
