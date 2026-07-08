import 'package:exptv2/features/stats/data/stats_closing_series.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closing drift moves right when expense monthly closes improve', () {
    final series = StatsClosingSeries.fromMonthCloses(
      activeType: TransactionType.expense,
      closes: const [30000, 22000, 18000],
      thresholdHitDays: const [3, 2, 1],
    );

    expect(series.driftMarker, greaterThan(0.5));
    expect(series.driftGradientHexes, [
      '#EF4444',
      '#FEE2E2',
      '#FFFFFF',
      '#DCFCE7',
      '#22C55E',
    ]);
  });

  test('closing drift moves left when income monthly closes fall', () {
    final series = StatsClosingSeries.fromMonthCloses(
      activeType: TransactionType.income,
      closes: const [300000, 240000, 210000],
      thresholdHitDays: const [2, 1, 1],
    );

    expect(series.driftMarker, lessThan(0.5));
  });

  test('close pulse maps expense worsening to positive red pressure', () {
    final series = StatsClosingSeries.fromMonthCloses(
      activeType: TransactionType.expense,
      closes: const [10000, 15000, 24000, 32000, 41000],
      thresholdHitDays: const [1, 2, 3, 4, 5],
    );

    expect(series.closePulseBars.last.value, greaterThan(0));
    expect(series.closePulseBars.last.colorHex, '#EF4444');
  });

  test('close pulse maps income recovery to negative green pressure', () {
    final series = StatsClosingSeries.fromMonthCloses(
      activeType: TransactionType.income,
      closes: const [100000, 80000, 90000, 120000, 150000],
      thresholdHitDays: const [1, 1, 2, 2, 3],
    );

    expect(series.closePulseBars.last.value, lessThan(0));
    expect(series.closePulseBars.last.colorHex, '#22C55E');
  });

  test('monthly close bars use active totals and threshold-hit counts', () {
    final series = StatsClosingSeries.fromMonthCloses(
      activeType: TransactionType.expense,
      closes: const [4000, 30000, 12000],
      thresholdHitDays: const [0, 5, 1],
    );

    expect(series.monthlyCloseBars[1].amount, 30000);
    expect(series.monthlyCloseBars[1].thresholdHitDays, 5);
    expect(series.monthlyCloseBars[1].barColorHex, '#EF4444');
    expect(series.monthlyCloseBars[1].secondaryBarColorHex, '#FCA5A5');
    expect(series.monthlyCloseBars[1].thresholdPointColorHex, '#EF4444');
  });
}
