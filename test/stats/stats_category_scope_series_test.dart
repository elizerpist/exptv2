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
      'Már',
      'Ápr',
      'Máj',
      'Jún',
      'Júl',
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

      expect(series.monthTicks.map((tick) => tick.label), ['Jan', 'Már']);
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

    expect(series.secondaryMetricLabel, 'minimum alapú eltérés');
    expect(series.helperBars.map((bar) => bar.rawValue), [2000, 3000]);
    expect(series.helperBars.map((bar) => bar.value), [0, 100]);
  });

  test('expense helper bars use threshold excess from real samples only', () {
    final series = StatsCategoryScopeSeries.fromDailySamples(
      threshold: 5000,
      dailyScopeAmounts: const [6000, 2000, 14000],
    );

    expect(series.secondaryMetricLabel, 'küszöb feletti többlet');
    expect(series.helperBars, hasLength(2));
    expect(series.helperBars.map((bar) => bar.rawValue), [6000, 14000]);
    _expectCloseValues(series.helperBars.map((bar) => bar.value), const [
      11.11111111111111,
      100,
    ]);
  });

  test(
    'income keeps monthly pattern score but helpers use threshold-hit days',
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

      expect(series.monthLabels, ['Jan', 'Feb', 'Már']);
      expect(series.secondaryMetricLabel, 'küszöb feletti többlet');
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
      expect(series.helperBars.map((bar) => bar.rawValue), [
        300000,
        75000,
        75000,
        75000,
        75000,
        400000,
      ]);
      _expectCloseValues(series.helperBars.map((bar) => bar.value), const [
        71.42857142857143,
        7.142857142857143,
        7.142857142857143,
        7.142857142857143,
        7.142857142857143,
        100,
      ]);
      expect(
        series.helperBars.map((bar) => bar.colorHex),
        everyElement('#22C55E'),
      );
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
      'Már',
      'Ápr',
      'Máj',
      'Jún',
      'Júl',
      'Aug',
      'Szep',
      'Okt',
      'Nov',
      'Dec',
    ]);
  });

  test('month mode axis keeps day samples and thins day labels', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        for (var day = 1; day <= 31; day += 1)
          record(
            id: day,
            date: '2026-01-${day.toString().padLeft(2, '0')}',
            amount: -1000.0 * day,
            categoryId: 1,
          ),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.monthly,
      month: 1,
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(series.helperBars, hasLength(31));
    expect(series.monthTicks.map((tick) => tick.label), [
      '1',
      '5',
      '10',
      '15',
      '20',
      '25',
      '30',
      '31',
    ]);
  });

  test('expense score thresholds the aggregated raw daily scope', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: -3000, categoryId: 1),
        record(id: 2, date: '2026-01-01', amount: -3000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(series.helperBars.map((bar) => bar.rawValue), [6000]);
    expect(series.scoreLine.single.value, 0);
  });

  test('sum expense score keeps the canonical daily pipeline across years', () {
    final start = DateTime(2024, 12, 25);
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: [
        for (var index = 0; index < 13; index += 1)
          record(
            id: index + 1,
            date: dateString(start.add(Duration(days: index))),
            amount: -6000,
            categoryId: 1,
          ),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.allTime,
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(data.periodLabels, ['2024', '2025']);
    expect(series.scoreLine, hasLength(13));
    expect(series.dynamicEmaPeriod, 16);
  });

  test(
    'expense score has parity for equivalent sum year and month domains',
    () {
      final transactions = [
        record(id: 1, date: '2026-01-01', amount: -3000, categoryId: 1),
        record(id: 2, date: '2026-01-01', amount: -3000, categoryId: 2),
        record(id: 3, date: '2026-01-03', amount: -9000, categoryId: 1),
      ];
      final categories = [
        category(id: 1, name: 'Food', type: TransactionType.expense),
        category(id: 2, name: 'Travel', type: TransactionType.expense),
      ];
      final series = <StatsCategoryScopeSeries>[];
      for (final scope in StatsSummaryScope.values) {
        final data = StatsYearData.build(
          year: 2026,
          activeType: TransactionType.expense,
          mode: StatsRenderMode.common,
          thresholdValue: 5000,
          transactions: transactions,
          categories: categories,
          selectedCategoryIds: const {1, 2},
          summaryScope: scope,
          month: 1,
        );
        series.add(StatsCategoryScopeSeries.fromYearData(data));
      }

      for (final value in series) {
        expect(value.helperBars.map((bar) => bar.rawValue), [6000, 9000]);
        expect(value.scoreLine.map((point) => point.value), [
          closeTo(100 / 3, 0.0001),
          0,
        ]);
        expect(value.kontrollScore, 0);
      }
    },
  );

  test('income exposes coverage, shortfall and break-even centerline bars', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.income,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: 12000, categoryId: 1),
        record(id: 2, date: '2026-01-02', amount: -8000, categoryId: 2),
        record(id: 3, date: '2026-02-01', amount: 5000, categoryId: 1),
        record(id: 4, date: '2026-02-02', amount: -10000, categoryId: 2),
        record(id: 5, date: '2026-03-01', amount: 7000, categoryId: 1),
        record(id: 6, date: '2026-03-02', amount: -7000, categoryId: 2),
      ],
      categories: [
        category(id: 1, name: 'Fizetés', type: TransactionType.income),
        category(id: 2, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {1},
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(series.incomeComparisonBars.map((bar) => bar.signedValue), [
      4000,
      -5000,
      0,
    ]);
    expect(series.incomeComparisonBars.map((bar) => bar.colorHex), [
      '#22C55E',
      '#EF4444',
      '#FBBF24',
    ]);
    expect(series.kontrollScore, closeTo(43.8235, 0.001));
  });

  test('income month mode keeps all calendar days as centerline inputs', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.income,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        record(id: 1, date: '2026-01-15', amount: 12000, categoryId: 1),
        record(id: 2, date: '2026-01-15', amount: -8000, categoryId: 2),
      ],
      categories: [
        category(id: 1, name: 'Fizetés', type: TransactionType.income),
        category(id: 2, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {1},
      summaryScope: StatsSummaryScope.monthly,
      month: 1,
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(series.incomeComparisonBars, hasLength(31));
    expect(
      series.incomeComparisonBars.first.position,
      closeTo(0.5 / 31, 0.0001),
    );
    expect(
      series.incomeComparisonBars.last.position,
      closeTo(30.5 / 31, 0.0001),
    );
    expect(series.monthTicks.map((tick) => tick.label), [
      '1',
      '5',
      '10',
      '15',
      '20',
      '25',
      '30',
      '31',
    ]);
  });

  test('sum mode axis keeps yearly samples and thins year labels', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.income,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        for (var year = 2006; year <= 2025; year += 1)
          record(
            id: year,
            date: '$year-01-01',
            amount: 100000.0 + year,
            categoryId: 1,
          ),
      ],
      categories: [
        category(id: 1, name: 'Fizetés', type: TransactionType.income),
      ],
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.allTime,
    );

    final series = StatsCategoryScopeSeries.fromYearData(data);

    expect(series.helperBars, hasLength(20));
    expect(series.monthTicks.map((tick) => tick.label), [
      '2006',
      '2010',
      '2015',
      '2020',
      '2025',
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

String dateString(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
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
