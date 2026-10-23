import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_visual_presentation.dart';

DashboardBalanceDailyMomentumPoint point(List<int> values) =>
    DashboardBalanceDailyMomentumPoint(
      epochDay: 1,
      referenceIncomeMinor: values[0],
      currentIncomeMinor: values[1],
      referenceExpenseMinor: values[2],
      currentExpenseMinor: values[3],
      isCurrentHalf: true,
      incomeAxis: -.1,
      expenseAxis: .1,
      magnitude: .2,
    );

void main() {
  test(
    'all four existing totals share one scale and preserve exact amounts',
    () {
      final source = point([72100000, 70700000, 65104500, 75699900]);
      final scale = BalanceDayComparisonBarScale.fromPoint(source);
      expect(scale.source, same(source));
      expect(scale.maximumMinor, 75699900);
      expect(scale.fractions[3], 1);
      expect(scale.fractions[3], greaterThan(scale.fractions[0]));
      expect(scale.fractions[0], greaterThan(scale.fractions[2]));
      expect(scale.fractions[2], greaterThan(scale.fractions[1]));
      expect(scale.fractions[1], closeTo(651045 / 756999, 1e-12));
      expect(() => scale.fractions[0] = 0, throwsUnsupportedError);
      expect(() => scale.amountsMinor[0] = 0, throwsUnsupportedError);
    },
  );
  test('period identity, integer nets and delta preserve accepted source', () {
    final source = point([72100000, 70700000, 65104500, 75699900]);
    final comparison = BalanceDayPeriodComparisonPresentation.fromPoint(source);
    expect(comparison.source, same(source));
    expect(comparison.previous.incomeMinor, 72100000);
    expect(comparison.previous.expenseMinor, 65104500);
    expect(comparison.previous.netMinor, 6995500);
    expect(comparison.current.incomeMinor, 70700000);
    expect(comparison.current.expenseMinor, 75699900);
    expect(comparison.current.netMinor, -4999900);
    expect(comparison.netDeltaMinor, -11995400);
    expect(
      BalanceDayPeriodComparisonPresentation.signedAmountLabel(
        comparison.previous.netMinor,
      ),
      '+69955 Ft',
    );
    expect(
      BalanceDayPeriodComparisonPresentation.signedAmountLabel(
        comparison.current.netMinor,
      ),
      '-49999 Ft',
    );
    final scale = BalanceDayComparisonBarScale.fromComparison(comparison);
    expect(scale.amountsMinor, [72100000, 65104500, 70700000, 75699900]);
    expect(scale.bars.map((bar) => bar.period), [
      BalanceDayComparisonPeriod.previous,
      BalanceDayComparisonPeriod.previous,
      BalanceDayComparisonPeriod.current,
      BalanceDayComparisonPeriod.current,
    ]);
    expect(scale.bars.map((bar) => bar.flow), [
      BalanceDayComparisonFlow.income,
      BalanceDayComparisonFlow.expense,
      BalanceDayComparisonFlow.income,
      BalanceDayComparisonFlow.expense,
    ]);
    for (final amounts in [
      [100, 300, 200, 100],
      [200, 100, 100, 200],
      [200, 200, 100, 100],
      [0, 0, 0, 0],
    ]) {
      final adapted = BalanceDayPeriodComparisonPresentation.fromPoint(
        point(amounts),
      );
      expect(
        adapted.netDeltaMinor,
        (amounts[1] - amounts[3]) - (amounts[0] - amounts[2]),
      );
    }
    expect(BalanceDayPeriodComparisonPresentation.signedAmountLabel(0), '0 Ft');
  });
  test('empty and zero flows never produce a false positive bar', () {
    final empty = BalanceDayComparisonBarScale.fromPoint(point([0, 0, 0, 0]));
    expect(empty.maximumMinor, 0);
    expect(empty.fractions, [0.0, 0.0, 0.0, 0.0]);
    final single = BalanceDayComparisonBarScale.fromPoint(
      point([0, 100, 0, 0]),
    );
    expect(single.fractions, [0.0, 0.0, 1.0, 0.0]);
  });
  test(
    'seven-day copy preserves source amounts and existing average rounding',
    () {
      const source = DashboardBalanceDailyImpactPresentation(
        available: true,
        previousSevenExpenseMinor: 4919500,
        currentSevenExpenseMinor: 6602400,
        valuePercent: -34.21079377985568,
        scaleExtentPercent: 100,
        markerFraction: .3289460311007216,
        overflow: false,
        todayNetMinor: 0,
        referenceAverageNetMinor: 0,
      );
      final copy = BalanceDaySevenDayComparisonPresentation.fromImpact(source);
      expect(copy.source, same(source));
      expect(copy.previousTotalLabel, '49195 Ft');
      expect(copy.currentTotalLabel, '66024 Ft');
      expect(copy.previousDailyAverageMinor, (4919500 / 7).round());
      expect(copy.currentDailyAverageMinor, (6602400 / 7).round());
      expect(copy.previousDailyAverageLabel, '7027 Ft/nap');
      expect(copy.currentDailyAverageLabel, '9432 Ft/nap');
      expect(source.markerFraction, .3289460311007216);
    },
  );
}
