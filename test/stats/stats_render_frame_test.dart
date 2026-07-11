import 'package:exptv2/features/stats/data/stats_render_frame.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'one combined category OR and vendor AND frame drives every consumer',
    () {
      final categories = [
        category(id: 1, name: 'Food', type: TransactionType.expense),
        category(id: 2, name: 'Travel', type: TransactionType.expense),
        category(id: 3, name: 'Other', type: TransactionType.expense),
        category(id: 4, name: 'Salary', type: TransactionType.income),
      ];
      final transactions = [
        record(id: 1, date: '2026-01-01', amount: -3000, categoryId: 1),
        record(id: 2, date: '2026-01-01', amount: -3000, categoryId: 2),
        record(id: 3, date: '2026-01-02', amount: -6000, categoryId: 1),
        record(id: 4, date: '2026-01-03', amount: -9000, categoryId: 2),
        record(id: 5, date: '2026-01-04', amount: -20000, categoryId: 3),
        record(
          id: 6,
          date: '2026-01-05',
          amount: -25000,
          categoryId: 1,
          merchant: 'A',
        ),
        record(id: 7, date: '2026-01-06', amount: -4000, categoryId: 1),
        record(id: 8, date: '2026-01-07', amount: 50000, categoryId: 4),
      ];

      for (final scope in StatsSummaryScope.values) {
        final frame = StatsRenderFrame.build(
          year: 2026,
          month: 1,
          activeType: TransactionType.expense,
          thresholdValue: 5000,
          transactions: transactions,
          categories: categories,
          selectedCategoryIds: const {1, 2},
          vendorFilters: const {'B'},
          summaryScope: scope,
          today: DateTime(2026, 1, 10),
        );
        final january = frame.yearData.months.first;

        expect(frame.yearData.summaryTotal, 15000, reason: scope.name);
        expect(january.days[0].meetsThreshold, isFalse, reason: scope.name);
        expect(january.days[1].scopeAmount, 6000, reason: scope.name);
        expect(january.days[1].heatmapIntensity, closeTo(2 / 3, 0.0001));
        expect(january.days[2].scopeAmount, 9000, reason: scope.name);
        expect(january.days[2].heatmapIntensity, 1);
        expect(frame.yearData.categoryTotals, {1: 6000, 2: 9000});
        expect(frame.yearData.vendorSummaries.single.name, 'B');
        expect(frame.yearData.vendorSummaries.single.total, 15000);
        expect(frame.page2Metrics.total, 15000);
        expect(frame.page2Metrics.recordCount, 2);
        expect(frame.filteredTransactionCount, 2);
        expect(frame.largestVisibleVendor, 'B');
        expect(frame.observedMaximum, 9000);
        expect(
          frame.categoryScopeSeries.helperBars.map((bar) => bar.rawValue),
          [6000, 6000, 9000],
          reason:
              'same-day sub-threshold records aggregate before score threshold',
        );
        expect(
          frame.categoryScopeSeries.scoreLine.map((point) => point.value),
          [closeTo(100 / 3, 0.0001), closeTo(100 / 3, 0.0001), 0],
        );
        expect(
          january.closingAmount,
          5000,
          reason: 'closing remains category and threshold independent',
        );
        expect(frame.sumYearSummaries.single.scopeTotal, 15000);
        expect(frame.sumYearSummaries.single.monthTotals, {1: 15000});
        expect(frame.sumYearSummaries.single.closingAmount, 5000);
      }
    },
  );

  test(
    'cache reuses one 10000-record frame until the canonical key changes',
    () {
      final categories = [
        category(id: 1, name: 'Food', type: TransactionType.expense),
        category(id: 2, name: 'Travel', type: TransactionType.expense),
      ];
      final dates = <String>[
        for (var year = 2020; year <= 2025; year += 1)
          for (var month = 1; month <= 12; month += 1)
            for (var day = 1; day <= DateTime(year, month + 1, 0).day; day += 1)
              '$year-${month.toString().padLeft(2, '0')}-'
                  '${day.toString().padLeft(2, '0')}',
      ];
      final transactions = List<TransactionRecord>.generate(10000, (index) {
        return record(
          id: index + 1,
          date: dates[index % dates.length],
          amount: -(5000.0 + index % 20000),
          categoryId: index.isEven ? 1 : 2,
        );
      }, growable: false);
      final dataRevision = (transactions: transactions, categories: categories);
      final key = StatsRenderFrameKey(
        dataRevision: dataRevision,
        activeType: TransactionType.expense,
        summaryScope: StatsSummaryScope.allTime,
        year: 2026,
        month: 1,
        categoryIds: const {1, 2},
        vendorNames: const {'B'},
        query: '  B ',
        threshold: 5000,
      );
      final equivalentKey = StatsRenderFrameKey(
        dataRevision: dataRevision,
        activeType: TransactionType.expense,
        summaryScope: StatsSummaryScope.allTime,
        year: 2026,
        month: 1,
        categoryIds: const {2, 1},
        vendorNames: const {'B'},
        query: 'b',
        threshold: 5000,
      );
      final cache = StatsRenderFrameCache();
      var buildCount = 0;

      StatsRenderFrame buildFrame() {
        buildCount += 1;
        return StatsRenderFrame.build(
          year: 2026,
          month: 1,
          activeType: TransactionType.expense,
          thresholdValue: 5000,
          transactions: transactions,
          categories: categories,
          selectedCategoryIds: const {1, 2},
          vendorFilters: const {'B'},
          summaryScope: StatsSummaryScope.allTime,
          query: 'b',
          today: DateTime(2026, 1, 10),
        );
      }

      final page1Frame = cache.resolve(key, buildFrame);
      final page2Frame = cache.resolve(equivalentKey, buildFrame);
      final fabFrame = cache.resolve(key, buildFrame);

      expect(page2Frame, same(page1Frame));
      expect(fabFrame, same(page1Frame));
      expect(buildCount, 1);

      final thresholdChanged = StatsRenderFrameKey(
        dataRevision: dataRevision,
        activeType: TransactionType.expense,
        summaryScope: StatsSummaryScope.allTime,
        year: 2026,
        month: 1,
        categoryIds: const {1, 2},
        vendorNames: const {'B'},
        query: 'b',
        threshold: 10000,
      );
      final rebuilt = cache.resolve(thresholdChanged, buildFrame);

      expect(rebuilt, isNot(same(page1Frame)));
      expect(buildCount, 2);
    },
  );

  test('cache rebuilds when only data revision changes', () {
    final categories = [
      category(id: 1, name: 'Food', type: TransactionType.expense),
    ];
    final transactions = [
      record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
    ];
    final firstRevision = Object();
    final secondRevision = Object();
    final cache = StatsRenderFrameCache();
    var buildCount = 0;

    StatsRenderFrame buildFrame() {
      buildCount += 1;
      return StatsRenderFrame.build(
        year: 2026,
        month: 1,
        activeType: TransactionType.expense,
        thresholdValue: 5000,
        transactions: transactions,
        categories: categories,
        selectedCategoryIds: const {},
        today: DateTime(2026, 1, 10),
      );
    }

    StatsRenderFrameKey key(Object revision) => StatsRenderFrameKey(
      dataRevision: revision,
      activeType: TransactionType.expense,
      summaryScope: StatsSummaryScope.yearly,
      year: 2026,
      month: 1,
      categoryIds: const {},
      vendorNames: const {},
      query: '',
      threshold: 5000,
    );

    final first = cache.resolve(key(firstRevision), buildFrame);
    final reused = cache.resolve(key(firstRevision), buildFrame);
    final rebuilt = cache.resolve(key(secondRevision), buildFrame);

    expect(reused, same(first));
    expect(rebuilt, isNot(same(first)));
    expect(buildCount, 2);
  });

  test(
    'all-time display folds same month day but score keeps original days',
    () {
      final frame = StatsRenderFrame.build(
        year: 2026,
        activeType: TransactionType.expense,
        thresholdValue: 5000,
        transactions: [
          record(id: 1, date: '2024-01-05', amount: -6000, categoryId: 1),
          record(id: 2, date: '2025-01-05', amount: -9000, categoryId: 1),
        ],
        categories: [
          category(id: 1, name: 'Food', type: TransactionType.expense),
        ],
        selectedCategoryIds: const {},
        summaryScope: StatsSummaryScope.allTime,
        today: DateTime(2026, 1, 10),
      );

      expect(frame.yearData.months.first.days[4].scopeAmount, 15000);
      expect(frame.yearData.months.first.days[4].scoreScopeAmount, 15000);
      expect(frame.categoryScopeSeries.helperBars.map((bar) => bar.rawValue), [
        6000,
        9000,
      ]);
    },
  );

  test('all-time leap day clamps display without merging score dates', () {
    final frame = StatsRenderFrame.build(
      year: 2026,
      activeType: TransactionType.expense,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2024-02-29', amount: -6000, categoryId: 1),
        record(id: 2, date: '2025-02-28', amount: -7000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Food', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.allTime,
      today: DateTime(2026, 1, 10),
    );

    final february = frame.yearData.months[1];
    expect(february.days, hasLength(28));
    expect(february.days.last.scopeAmount, 13000);
    expect(february.days.last.scoreScopeAmount, 13000);
    expect(frame.categoryScopeSeries.helperBars.map((bar) => bar.rawValue), [
      6000,
      7000,
    ]);
    expect(frame.sumYearSummaries.map((summary) => summary.year), [2025, 2024]);
  });
}

TransactionRecord record({
  required int id,
  required String date,
  required double amount,
  required int categoryId,
  String merchant = 'B',
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '10:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: merchant,
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
