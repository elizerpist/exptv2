import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';

/// Resolves the dense prepared-Budget slice for a visible global time scope.
///
/// This is intentionally not a persisted financial-limit identity. The only
/// persisted limit scopes are base-month and concrete month override; DAY,
/// YEAR and SUM use the appropriate prepared analytical slice and derive their
/// denominator through the monthly-limit resolver.
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
