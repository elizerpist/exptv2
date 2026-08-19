import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';

/// Resolves the persisted financial-limit identity for a visible scope.
///
/// This is deliberately *not* the Budget analytics/chart identity: a
/// [DayScope] uses its exact daily prepared actuals/distributions, while its
/// persisted limit denominator remains the containing month.
abstract final class DashboardBudgetPeriodResolver {
  static BudgetLimitPeriod fromTimeScope(LedgerTimeScope scope) =>
      switch (scope) {
        AllTimeScope() => const BudgetLimitPeriod.sum(),
        YearScope(:final year) => BudgetLimitPeriod.year(year),
        MonthScope(:final value) => BudgetLimitPeriod.month(
          value.year,
          value.month,
        ),
        DayScope(:final date) => BudgetLimitPeriod.month(date.year, date.month),
      };
}
