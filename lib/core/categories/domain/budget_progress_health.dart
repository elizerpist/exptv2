/// Scope-independent Budget-health semantics.
///
/// Scope analyses own their numerator/denominator meanings; ring strategies
/// own their geometry. Neither is allowed to recreate these thresholds.
enum BudgetProgressHealth { unavailable, targetAccent, warning, danger }

abstract final class BudgetProgressHealthResolver {
  static BudgetProgressHealth resolve({
    required bool isAvailable,
    required double rawRatio,
  }) {
    if (!isAvailable || !rawRatio.isFinite) {
      return BudgetProgressHealth.unavailable;
    }
    if (rawRatio < .75) return BudgetProgressHealth.targetAccent;
    if (rawRatio <= .90) return BudgetProgressHealth.warning;
    return BudgetProgressHealth.danger;
  }
}
