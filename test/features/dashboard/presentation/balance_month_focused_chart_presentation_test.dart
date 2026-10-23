import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_focused_chart_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'full leap calendar starts zero carries empty days and preserves final net',
    () {
      final primary = DashboardBalancePrimaryPresentation(
        identity: const DashboardBalancePrimaryIdentity(
          upstreamScopeKey: 'test',
          indexGeneration: 1,
          coreRevision: 1,
        ),
        timeScope: const MonthScope(YearMonth(year: 2024, month: 2)),
        mode: DashboardBalancePrimaryMode.month,
        incomeTotalMinor: 100,
        expenseTotalMinor: 30,
        periodPairs: [],
        dailyPoints: const [
          DashboardBalancePrimaryDayPoint(
            day: 2,
            incomeMinor: 100,
            expenseMinor: 0,
          ),
          DashboardBalancePrimaryDayPoint(
            day: 4,
            incomeMinor: 100,
            expenseMinor: 30,
          ),
        ],
      );
      final model = BalanceMonthFocusedChartPresentation.fromPrimary(primary);
      expect(model.trend.length, 30);
      expect(model.trend.first.day, 0);
      expect(model.trend.first.netMinor, 0);
      expect(model.trend[3].netMinor, 100);
      expect(model.trend.last.netMinor, 70);
      expect(model.netTotalMinor, 70);
      expect(model.minimumNetMinor, 0);
      expect(model.maximumNetMinor, 100);
      expect(model.swings.map((point) => point.day), [2, 4]);
      expect(() => model.trend.clear(), throwsUnsupportedError);
    },
  );
  test(
    'top seven nonzero swings sorted by absolute amount ties earliest then displayed chronological',
    () {
      var income = 0, expense = 0;
      final points = <DashboardBalancePrimaryDayPoint>[];
      for (var day = 1; day <= 10; day++) {
        if (day.isEven) {
          expense += 10;
        } else {
          income += 10;
        }
        points.add(
          DashboardBalancePrimaryDayPoint(
            day: day,
            incomeMinor: income,
            expenseMinor: expense,
          ),
        );
      }
      final primary = DashboardBalancePrimaryPresentation(
        identity: const DashboardBalancePrimaryIdentity(
          upstreamScopeKey: 'test',
          indexGeneration: 1,
          coreRevision: 1,
        ),
        timeScope: const MonthScope(YearMonth(year: 2026, month: 1)),
        mode: DashboardBalancePrimaryMode.month,
        incomeTotalMinor: income,
        expenseTotalMinor: expense,
        periodPairs: [],
        dailyPoints: points,
      );
      final model = BalanceMonthFocusedChartPresentation.fromPrimary(primary);
      expect(model.swings.map((point) => point.day), [1, 2, 3, 4, 5, 6, 7]);
      expect(model.bestDay?.day, 1);
      expect(model.worstDay?.day, 2);
      expect(model.maxAbsSwingMinor, 10);
    },
  );
}
