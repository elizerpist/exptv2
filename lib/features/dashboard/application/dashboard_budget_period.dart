import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';

/// The one Budget interpretation of the visible time scope. Header limits and
/// distribution projections must address the same prepared dense slice.
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
