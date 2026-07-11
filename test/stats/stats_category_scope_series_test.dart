import 'package:exptv2/features/stats/data/stats_category_scope_series.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense scope uses accepted sparse score and real helper samples', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2026-01-10', amount: -6000, categoryId: 1),
        record(id: 2, date: '2026-07-10', amount: -26030, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Gyorsetterem', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(series.scoreLine, hasLength(2));
    expect(series.scoreLine.first.position, 0);
    expect(series.scoreLine.last.position, 1);
    expect(series.scoreLine.first.value, closeTo(76.949673, 0.0001));
    expect(series.scoreLine.last.value, 0);
    expect(series.kontrollScore, 0);
    expect(series.monthTicks.map((tick) => tick.label), [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
    ]);
    expect(series.helperBars.map((bar) => bar.rawValue), [6000, 26030]);
    _expectCloseValues(series.helperBars.map((bar) => bar.value), const [
      4.75511174512601,
      100,
    ]);
    expect(series.helperBars.every((bar) => bar.colorHex == '#EF4444'), isTrue);
  });

  test(
    'income scope filters months by threshold and exposes endpoint score',
    () {
      final data = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.income,
        mode: StatsRenderMode.common,
        thresholdValue: 100000,
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

      expect(series.monthTicks.map((tick) => tick.label), ['Jan', 'Mar']);
      expect(series.scoreLine, hasLength(2));
      expect(series.scoreLine.first.value, closeTo(50, 0.0001));
      expect(series.scoreLine.last.value, closeTo(60, 0.0001));
      expect(series.kontrollScore, closeTo(60, 0.0001));
      expect(series.helperBars.map((bar) => bar.rawValue), [300000, 400000]);
      _expectCloseValues(series.helperBars.map((bar) => bar.value), const [
        66.66666666666666,
        100,
      ]);
      expect(series.helperBars.map((bar) => bar.colorHex), [
        '#22C55E',
        '#22C55E',
      ]);
    },
  );

  test(
    'expense dense scope uses centered rolling score inside active range',
    () {
      final series = StatsCategoryScopeSeries.fromDailySamples(
        threshold: 5000,
        dailyScopeAmounts: [
          ...List<double>.filled(18, 1000),
          ...List<double>.filled(13, 18000),
        ],
      );

      expect(series.dynamicEmaPeriod, 16);
      expect(series.scoreLine, hasLength(13));
      expect(series.scoreLine.first.position, 0);
      expect(series.scoreLine.last.position, 1);
      expect(series.scoreLine.map((point) => point.value), everyElement(0));
    },
  );

  test('threshold zero uses min-baseline helper bars', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 0,
      dailyScopeAmounts: const [2000, 0, 3000],
    );

    expect(series.secondaryMetricLabel, 'min baseline');
    expect(series.helperBars.map((bar) => bar.rawValue), [2000, 3000]);
    expect(series.helperBars.map((bar) => bar.value), [0, 100]);
  });

  test('expense helper bars use threshold excess from real samples only', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 2000, 14000],
    );

    expect(series.secondaryMetricLabel, 'threshold excess');
    expect(series.helperBars, hasLength(2));
    expect(series.helperBars.map((bar) => bar.rawValue), [6000, 14000]);
    _expectCloseValues(series.helperBars.map((bar) => bar.value), const [
      11.11111111111111,
      100,
    ]);
  });

  test(
    'income scope uses pattern trend score and threshold-excess helper bars',
    () {
      final data = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.income,
        mode: StatsRenderMode.common,
        thresholdValue: 50000,
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
      expect(series.secondaryMetricLabel, 'threshold excess');
      expect(series.secondaryReferenceAmount, 50000);
      expect(series.scoreLine.map((point) => point.value), [
        closeTo(50, 0.01),
        closeTo(50, 0.01),
        closeTo(61.67, 0.01),
      ]);
      expect(series.controlBars.map((bar) => bar.colorHex), [
        '#FBBF24',
        '#FBBF24',
        '#22C55E',
      ]);
      _expectCloseValues(series.helperBars.map((bar) => bar.value), const [
        71.42857142857143,
        71.42857142857143,
        100,
      ]);
      expect(series.helperBars.map((bar) => bar.colorHex), [
        '#22C55E',
        '#22C55E',
        '#22C55E',
      ]);
      expect(series.kontrollScore, closeTo(61.67, 0.01));
    },
  );

  test('month labels expose every active month on a full-year graph', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
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

  test('sparse score can improve while a later amount is lower', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [30000, 0, 0, 0, 6000],
      window: 2,
    );

    expect(
      series.scoreLine.last.value,
      greaterThan(series.scoreLine.first.value),
    );
  });

  test('sparse high late amount keeps endpoint score low', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 6000, 6000, 0, 0, 50000],
      window: 3,
    );

    expect(series.scoreLine.last.value, 0);
    expect(series.kontrollScore, 0);
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
