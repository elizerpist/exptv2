import 'package:exptv2/features/stats/data/stats_page2_metrics.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'year mode page 2 metrics use the selected year day and month counts',
    () {
      final data = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.common,
        thresholdValue: 0,
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-02', amount: -14000, categoryId: 1),
          record(id: 3, date: '2026-02-01', amount: -10000, categoryId: 1),
          record(id: 4, date: '2025-01-01', amount: -99000, categoryId: 1),
        ],
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
        ],
        selectedCategoryIds: const {},
        summaryScope: StatsSummaryScope.yearly,
        today: DateTime(2026, 7, 11),
      );

      final metrics = StatsPage2Metrics.fromYearData(data);

      expect(metrics.total, 30000);
      expect(metrics.monthCount, 12);
      expect(metrics.dayCount, 365);
      expect(metrics.monthlyAverage, 2500);
      expect(metrics.largestAmount, 14000);
      expect(metrics.topMonthLabel, 'Január');
      expect(metrics.topMonthAmount, 20000);
      expect(metrics.dailyAverageTransactionCount, closeTo(3 / 365, 0.00001));
      expect(metrics.dailyAverageAmount, closeTo(30000 / 365, 0.00001));
      expect(metrics.zeroActivityDays, 362);
      expect(metrics.averageEventAmount, 10000);
    },
  );

  test('sum mode page 2 metrics derive the multi-year active range', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.income,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        record(id: 1, date: '2024-01-01', amount: 100000, categoryId: 2),
        record(id: 2, date: '2025-03-01', amount: 200000, categoryId: 2),
        record(id: 3, date: '2026-06-01', amount: 300000, categoryId: 2),
      ],
      categories: [
        category(id: 2, name: 'Fizetés', type: TransactionType.income),
      ],
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.allTime,
      today: DateTime(2026, 7, 11),
    );

    final metrics = StatsPage2Metrics.fromYearData(data);

    expect(metrics.total, 600000);
    expect(metrics.monthCount, 30);
    expect(metrics.dayCount, 883);
    expect(metrics.topMonthLabel, 'Június 2026');
    expect(metrics.topMonthAmount, 300000);
    expect(metrics.averageEventAmount, 200000);
  });
}

TransactionRecord record({
  required int id,
  required String date,
  required double amount,
  required int categoryId,
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '10:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Teszt',
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
  );
}

TransactionCategory category({
  required int id,
  required String name,
  required TransactionType type,
}) {
  return TransactionCategory(
    transactionCategoryID: id,
    name: name,
    type: type.hungarianValue,
    colorSlot: id,
    iconSlot: null,
    backgroundColor: null,
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
}
