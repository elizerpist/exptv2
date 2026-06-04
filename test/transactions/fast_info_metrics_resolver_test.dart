import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric_snapshot.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/fast_info_metrics_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves the approved finance metrics from one snapshot', () {
    final metrics = FastInfoMetricsResolver.resolve(_snapshot());

    expect(metrics, hasLength(18));
    expect(
      metrics.keys.toSet(),
      fastInfoCardCatalog.map((card) => card.id).toSet(),
    );
    expect(metrics['mai_koltes']?.primaryValue, '7 000 Ft elköltve');
    expect(
      metrics['mai_koltes']?.progress,
      closeTo(7000 / ((300000 - 16000) / 28), 0.001),
    );
    expect(metrics['mai_koltes']?.semantic, FastInfoSemantic.good);
    expect(metrics['mai_koltes']?.trend, isNotNull);

    expect(metrics['heti_koltes']?.weeklyBars, hasLength(7));
    expect(metrics['heti_koltes']?.weeklyBars.last.isFuture, isTrue);
    expect(metrics['havi_koltes']?.chartSeries, hasLength(3));
    expect(metrics['havi_koltes']?.chartSeries.first.values, hasLength(3));
    expect(metrics['havi_koltes']?.trend, isNotNull);

    expect(metrics['megtakaritas']?.progress, closeTo(127000 / 50000, 0.001));
    expect(metrics['koltesi_trend']?.trend, isNotNull);
    expect(metrics['koltesi_trend']?.progress, isNull);
    expect(metrics['koltesi_trend']?.chartSeries, isEmpty);
    expect(
      metrics['atlagos_napi_koltes']?.secondaryValues,
      contains('Puffer: 170 nap'),
    );
    expect(
      metrics['kiadas_bevetel_arany']?.progress,
      closeTo(23000 / 150000, 0.001),
    );
  });

  test('omits visuals that have no meaningful denominator', () {
    final noLimit = FastInfoMetricsResolver.resolve(
      _snapshot(limits: const <CategoryLimit>[]),
    );
    final noGoal = FastInfoMetricsResolver.resolve(_snapshot(savingGoal: null));
    final zeroIncome = FastInfoMetricsResolver.resolve(
      _snapshot(
        transactions: _transactions
            .where((record) => record.amount < 0)
            .toList(),
      ),
    );

    expect(noLimit['mai_koltes']?.progress, isNull);
    expect(noLimit['havi_koltes']?.progress, isNull);
    expect(
      noLimit['heti_koltes']?.weeklyBars
          .where((bar) => !bar.isFuture)
          .every((bar) => bar.semantic == FastInfoSemantic.neutral),
      isTrue,
    );
    expect(noGoal['megtakaritas']?.progress, isNull);
    expect(noGoal['megtakaritas']?.secondaryValues, contains('Nincs cél'));
    expect(zeroIncome['kiadas_bevetel_arany']?.progress, isNull);
    expect(zeroIncome['kiadas_bevetel_arany']?.primaryValue, 'Nincs adat');
  });

  test('omits trends when the comparison period is zero', () {
    final metrics = FastInfoMetricsResolver.resolve(
      _snapshot(
        transactions: <TransactionRecord>[_transaction(1, '2026.06.03', -7000)],
      ),
    );

    expect(metrics['koltesi_trend']?.trend, isNull);
    expect(metrics['havi_koltes']?.trend, isNull);
    expect(
      metrics['koltesi_trend']?.secondaryValues,
      contains('Nincs összehasonlítás'),
    );
    expect(
      metrics['havi_koltes']?.secondaryValues,
      contains('Nincs összehasonlítás'),
    );
  });

  test(
    'expense semantics use green below 75, yellow through 100, then red',
    () {
      FastInfoSemantic semanticFor(double expense) {
        final metrics = FastInfoMetricsResolver.resolve(
          _snapshot(
            now: DateTime(2026, 6, 1, 12),
            transactions: <TransactionRecord>[
              _transaction(1, '2026.06.01', -expense),
            ],
            limits: <CategoryLimit>[_monthlyLimit(100)],
          ),
        );
        return metrics['havi_koltes']!.semantic;
      }

      expect(semanticFor(74), FastInfoSemantic.good);
      expect(semanticFor(75), FastInfoSemantic.warning);
      expect(semanticFor(100), FastInfoSemantic.warning);
      expect(semanticFor(101), FastInfoSemantic.bad);
    },
  );
}

FastInfoMetricSnapshot _snapshot({
  DateTime? now,
  List<TransactionRecord>? transactions,
  List<CategoryLimit>? limits,
  double? savingGoal = 50000,
}) {
  return FastInfoMetricSnapshot(
    now: now ?? DateTime(2026, 6, 3, 12),
    balance: 300000,
    savingGoal: savingGoal,
    transactions: transactions ?? _transactions,
    categories: _categories,
    limits: limits ?? <CategoryLimit>[_monthlyLimit(300000)],
  );
}

CategoryLimit _monthlyLimit(double amount) {
  return CategoryLimit(
    id: 1,
    targetType: LimitTargetType.overview,
    targetId: 0,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-06',
    hasLimit: true,
    limitAmount: amount,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  );
}

final _transactions = <TransactionRecord>[
  _transaction(1, '2026.06.03', -3000, time: '09:10'),
  _transaction(2, '2026.06.03', -4000, time: '11:30'),
  _transaction(3, '2026.06.02', -10000),
  _transaction(4, '2026.06.01', -6000),
  _transaction(5, '2026.05.15', -30000),
  _transaction(6, '2026.05.02', -10000),
  _transaction(7, '2026.04.20', -50000),
  _transaction(8, '2026.06.01', 150000),
];

TransactionRecord _transaction(
  int id,
  String date,
  double amount, {
  String time = '12:00',
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: time,
    latitude: null,
    longitude: null,
    address: null,
    merchant: amount > 0 ? 'Fizetés' : 'Bolt $id',
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: amount > 0 ? 2 : 1,
  );
}

const _categories = <TransactionCategory>[
  TransactionCategory(
    transactionCategoryID: 1,
    name: 'Étel',
    type: 'expense',
    colorSlot: 0,
    iconSlot: 0,
    backgroundColor: null,
    icon: 'restaurant',
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  ),
  TransactionCategory(
    transactionCategoryID: 2,
    name: 'Fizetés',
    type: 'income',
    colorSlot: 1,
    iconSlot: 1,
    backgroundColor: null,
    icon: 'payments',
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  ),
];
