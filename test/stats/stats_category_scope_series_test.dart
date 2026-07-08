import 'package:exptv2/features/stats/data/stats_category_scope_series.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense control bars use dynamic EMA around a neutral 50 baseline', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: [
        ...List<double>.filled(18, 1000),
        ...List<double>.filled(13, 18000),
      ],
    );

    expect(series.dynamicEmaPeriod, 8);
    expect(series.controlBars, hasLength(31));
    expect(series.controlBars.any((bar) => bar.colorHex == '#EF4444'), isTrue);
    expect(series.controlBars.any((bar) => bar.colorHex == '#22C55E'), isTrue);
    expect(
      series.controlBars.map((bar) => bar.value).toSet().length,
      greaterThan(2),
      reason: 'dynamic EMA should smooth sparse daily samples',
    );
  });

  test('threshold zero labels the orange line as Ft per active day', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 0,
      dailyScopeAmounts: const [2000, 0, 3000],
    );

    expect(series.secondaryMetricLabel, 'Ft/aktiv nap');
    expect(series.secondaryLine, hasLength(3));
  });

  test('expense orange line smooths rolling Ft per threshold hit', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 2000, 14000],
    );

    expect(series.secondaryMetricLabel, 'Ft/kiugras');
    expect(series.dynamicEmaPeriod, 18);
    _expectCloseValues(series.secondaryLine.map((point) => point.value), const [
      6000,
      6000,
      6421.0526315789475,
    ]);
  });

  test('threshold zero orange line smooths rolling Ft per active day', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 0,
      dailyScopeAmounts: const [2000, 0, 6000],
    );

    expect(series.secondaryMetricLabel, 'Ft/aktiv nap');
    expect(series.dynamicEmaPeriod, 18);
    _expectCloseValues(series.secondaryLine.map((point) => point.value), const [
      2000,
      2000,
      2210.5263157894738,
    ]);
  });

  test(
    'income scope uses monthly buckets and keeps orange Ft per active day',
    () {
      final data = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.income,
        mode: StatsRenderMode.categoryScope,
        thresholdValue: 50,
        transactions: [
          record(id: 1, date: '2026-01-01', amount: 300000, categoryId: 1),
          record(id: 2, date: '2026-02-01', amount: 75000, categoryId: 1),
          record(id: 3, date: '2026-02-02', amount: 75000, categoryId: 1),
          record(id: 4, date: '2026-02-03', amount: 75000, categoryId: 1),
          record(id: 5, date: '2026-02-04', amount: 75000, categoryId: 1),
          record(id: 6, date: '2026-03-01', amount: 400000, categoryId: 1),
        ],
        categories: [
          category(id: 1, name: 'Fizetes', type: TransactionType.income),
        ],
        selectedCategoryIds: const {},
      );

      final series = StatsCategoryScopeSeries.fromYearData(data);

      expect(series.monthLabels, ['Jan', 'Feb', 'Mar']);
      expect(series.secondaryMetricLabel, 'Ft/aktiv nap');
      expect(series.secondaryReferenceAmount, closeTo(166666.67, 0.01));
      expect(series.secondaryLine.map((point) => point.value), [
        300000,
        75000,
        400000,
      ]);
      expect(series.controlBars.map((bar) => bar.value), [
        closeTo(45, 0.01),
        closeTo(45, 0.01),
        closeTo(60, 0.01),
      ]);
      expect(series.controlBars.map((bar) => bar.colorHex), [
        '#EF4444',
        '#EF4444',
        '#22C55E',
      ]);
    },
  );

  test('month labels expose every active month on a full-year graph', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.categoryScope,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
        record(id: 2, date: '2026-12-01', amount: -7000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(series.monthLabels, [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ]);
  });

  test('occurrence can fall while value index rises', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 6000, 0, 0, 30000],
      window: 2,
    );

    expect(
      series.occurrence.last.value,
      lessThan(series.occurrence.first.value),
    );
    expect(
      series.valueIndex.last.value,
      greaterThan(series.valueIndex.first.value),
    );
  });

  test('occurrence-only improvement does not create a false high score', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 6000, 6000, 0, 0, 50000],
      window: 3,
    );

    expect(
      series.occurrence.last.value,
      lessThan(series.occurrence.first.value),
    );
    expect(
      series.valueIndex.last.value,
      greaterThan(series.valueIndex.first.value),
    );
    expect(series.kontrollScore, lessThan(65));
  });

  test(
    'risk segments distinguish improvement, divergence, worsening and flat',
    () {
      final segments = StatsCategoryScopeSeries.classifyRiskSegments(
        occurrenceValues: const [80, 60, 50, 70, 70],
        valueIndexValues: const [80, 60, 80, 90, 90],
        noiseThreshold: 0.5,
      );

      expect(segments[0].colorHex, '#10B981');
      expect(segments[1].colorHex, '#F97316');
      expect(segments[2].colorHex, '#EF4444');
      expect(segments[3].colorHex, isNull);
    },
  );

  test('macd maps worsening pressure to red and improvement to green', () {
    final worsening = StatsCategoryScopeSeries.fromPressureValues(
      const [10, 12, 16, 22, 31, 43, 58],
      shortWindow: 2,
      longWindow: 4,
      signalWindow: 2,
    );
    final improving = StatsCategoryScopeSeries.fromPressureValues(
      const [58, 43, 31, 22, 16, 12, 10],
      shortWindow: 2,
      longWindow: 4,
      signalWindow: 2,
    );

    expect(worsening.macd.last.value, greaterThan(0));
    expect(worsening.macd.last.colorHex, '#EF4444');
    expect(improving.macd.last.value, lessThan(0));
    expect(improving.macd.last.colorHex, '#22C55E');
  });

  test(
    'monthly bars keep top three categories and group every other category',
    () {
      final series = StatsCategoryScopeSeries.fromMonthlyCategoryTotals(
        monthlyCategoryTotals: const [
          {1: 10000.0, 2: 9000.0, 3: 8000.0, 4: 7000.0, 5: 6000.0},
        ],
        monthlyThresholdHitDays: const [4],
        categoryNames: const {
          1: 'Gyorskaja',
          2: 'Ruha',
          3: 'Bolt',
          4: 'Taxi',
          5: 'Mozi',
        },
      );

      final bar = series.monthlyBars.single;
      expect(bar.totalAmount, 40000);
      expect(bar.segments.map((segment) => segment.label), [
        'Gyorskaja',
        'Ruha',
        'Bolt',
        'Egyéb',
      ]);
      expect(bar.segments.last.amount, 13000);
      expect(bar.segments.last.colorHex, '#CBD5E1');
      expect(bar.impactValue, 10000);
      expect(series.latestImpactLabel, '10.0k');
    },
  );
}

void _expectCloseValues(Iterable<double> actual, List<double> expected) {
  final actualList = actual.toList(growable: false);
  expect(actualList, hasLength(expected.length));
  for (var i = 0; i < expected.length; i += 1) {
    expect(actualList[i], closeTo(expected[i], 0.0001), reason: 'index $i');
  }
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
