import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'stats year data measures threshold by active type and selected scope',
    () {
      final data = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.categoryScope,
        thresholdValue: 5000,
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-01', amount: -30000, categoryId: 2),
          record(id: 3, date: '2026-01-02', amount: -4000, categoryId: 1),
          record(id: 4, date: '2026-01-03', amount: 9000, categoryId: 3),
        ],
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
          category(id: 2, name: 'Ruha', type: TransactionType.expense),
          category(id: 3, name: 'Fizetés', type: TransactionType.income),
        ],
        selectedCategoryIds: {1},
      );

      final january = data.months.first;
      expect(january.days[0].scopeAmount, 6000);
      expect(january.days[0].meetsThreshold, isTrue);
      expect(january.days[1].scopeAmount, 4000);
      expect(january.days[1].meetsThreshold, isFalse);
      expect(january.days[2].scopeAmount, 0);
      expect(january.thresholdHitDays, 1);
      expect(data.summaryValue, '40 000 Ft');
      expect(data.headerLabel, 'SCOPE TREND');
      expect(data.headerValue, contains('Gyorskaja'));
    },
  );

  test('heatmap feedback counts active-side hot days above threshold', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.income,
      mode: StatsRenderMode.heatmap,
      thresholdValue: 8000,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: 9000, categoryId: 3),
        record(id: 2, date: '2026-01-02', amount: 7000, categoryId: 3),
        record(id: 3, date: '2026-01-03', amount: -50000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Ruha', type: TransactionType.expense),
        category(id: 3, name: 'Fizetés', type: TransactionType.income),
      ],
      selectedCategoryIds: const {},
    );

    expect(data.headerLabel, 'HEATMAP');
    expect(data.headerValue, '1 forró nap 8k felett');
    expect(data.months.first.hotDays, 1);
    expect(data.summaryValue, '16 000 Ft');
  });

  test('closing feedback keeps yearly wording and counts worsening months', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.closing,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: -4000, categoryId: 1),
        record(id: 2, date: '2026-02-01', amount: -7000, categoryId: 1),
        record(id: 3, date: '2026-03-01', amount: -3000, categoryId: 1),
        record(id: 4, date: '2026-04-01', amount: -9000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
    );

    expect(data.headerLabel, 'HÓZÁRÁS');
    expect(data.headerValue, '2 romló hónap idén');
    expect(data.months[1].thresholdHitDays, 1);
    expect(data.months[1].closingAmount, 7000);
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
