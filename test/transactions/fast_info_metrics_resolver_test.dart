import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric_snapshot.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/fast_info_metrics_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves the approved finance metrics from one snapshot', () {
    final metrics = FastInfoMetricsResolver.resolve(_snapshot());

    expect(metrics, hasLength(17));
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

  test('daily weekly monthly FastInfo metrics use variable pace', () {
    final metrics = FastInfoMetricsResolver.resolve(
      _snapshot(
        now: DateTime(2026, 6, 10, 12),
        transactions: <TransactionRecord>[
          _transaction(1, '2026.06.08', -10000),
          _transaction(2, '2026.06.09', -20000),
          _transaction(3, '2026.06.10', -5000),
          _transaction(4, '2026.06.10', -200000, recurringTransactionId: 77),
          _transaction(5, '2026.05.10', -30000),
        ],
      ),
    );

    final dailyCeiling = (300000 - 30000) / 21;
    expect(metrics['mai_koltes']?.primaryValue, '205 000 Ft elköltve');
    expect(
      metrics['mai_koltes']?.progress,
      closeTo(5000 / dailyCeiling, 0.001),
    );
    expect(
      metrics['mai_koltes']?.secondaryValues.any(
        (value) => value.endsWith('költhető'),
      ),
      isTrue,
    );

    expect(metrics['heti_koltes']?.weeklyBars[2].value, 5000);
    expect(
      metrics['heti_koltes']?.weeklyBars[2].semantic,
      FastInfoSemantic.good,
    );
    expect(
      metrics['heti_koltes']?.secondaryValues.any(
        (value) => value.startsWith('időarányhoz képest'),
      ),
      isTrue,
    );
    expect(metrics['heti_koltes']?.secondaryValues, contains('4 tranzakció'));

    expect(metrics['havi_koltes']?.progress, closeTo(35000 / 300000, 0.001));
    expect(metrics['havi_koltes']?.chartSeries.first.values[9], 5000);
    expect(
      metrics['havi_koltes']?.secondaryValues.any(
        (value) => value.startsWith('előző hónap index:'),
      ),
      isTrue,
    );
  });

  test('approved FastInfo cards expose typed visuals', () {
    final metrics = FastInfoMetricsResolver.resolve(_snapshot());

    expect(
      metrics['mai_koltes']!.visual.kind,
      FastInfoVisualKind.thresholdMarkerBar,
    );
    expect(
      metrics['heti_koltes']!.visual.kind,
      FastInfoVisualKind.deviationMeter,
    );
    expect(
      metrics['top_kategoria_heten']!.visual.kind,
      FastInfoVisualKind.miniAvatarRow,
    );
    expect(
      metrics['kiadas_bevetel_arany']!.visual.kind,
      FastInfoVisualKind.remainingSpentSplit,
    );
  });

  test('remaining FastInfo metrics follow fixed exclusion rules', () {
    final metrics = FastInfoMetricsResolver.resolve(
      _snapshot(
        now: DateTime(2026, 6, 10, 12),
        transactions: <TransactionRecord>[
          _transaction(1, '2026.06.04', -3000, categoryId: 1),
          _transaction(
            2,
            '2026.06.06',
            -200000,
            categoryId: 3,
            recurringTransactionId: 77,
          ),
          _transaction(8, '2026.06.07', -2000, categoryId: 1),
          _transaction(3, '2026.06.08', -4000, categoryId: 1),
          _transaction(
            4,
            '2026.06.09',
            -200000,
            categoryId: 3,
            recurringTransactionId: 77,
          ),
          _transaction(5, '2026.06.10', -15000, categoryId: 4),
          _transaction(6, '2026.05.10', -10000, categoryId: 4),
          _transaction(7, '2026.06.01', 300000, categoryId: 2),
        ],
        categories: _extendedCategories,
        recurringGhosts: <RecurringGhostRecord>[
          _ghost(
            id: 1,
            recurringTransactionId: 77,
            name: 'Lakbér',
            amount: 200000,
            date: '2026.06.06',
            isActivated: true,
          ),
          _ghost(
            id: 2,
            recurringTransactionId: 88,
            name: 'Telefon',
            amount: 12000,
            date: '2026.06.20',
          ),
        ],
      ),
    );

    expect(metrics['no_spend_napok_szama']?.primaryValue, '6 nap');
    expect(metrics['no_spend_napok_szama']?.pillValue, '3 / 7 nap');
    expect(metrics['top_kategoria_heten']?.primaryValue, 'Utazás');
    expect(
      metrics['legnagyobb_novekedo_kategoria']?.secondaryValues.join(' '),
      contains('fix nélkül'),
    );
    expect(
      metrics['havi_fix_koltseg_osszesen']?.secondaryValues.join(' '),
      contains('fixből'),
    );
    expect(metrics['kiadas_bevetel_arany']?.primaryValue, endsWith('%'));
    expect(metrics['kiadas_bevetel_arany']?.pillValue, contains('maradt'));
  });

  test('pending recurring income ghosts feed expected income metrics', () {
    final metrics = FastInfoMetricsResolver.resolve(
      _snapshot(
        now: DateTime(2026, 6, 3, 12),
        transactions: const <TransactionRecord>[],
        recurringGhosts: <RecurringGhostRecord>[
          _ghost(
            id: 9,
            recurringTransactionId: 99,
            name: 'Fizetés',
            amount: 300000,
            date: '2026.06.05',
            transactionType: 'income',
            categoryId: 2,
            categoryName: 'Fizetés',
          ),
        ],
      ),
    );

    expect(metrics['bevetel_ebben_a_honapban']?.primaryValue, '0 Ft');
    expect(
      metrics['bevetel_ebben_a_honapban']?.secondaryValues,
      contains('várt 300k · ghost 300k'),
    );
    expect(
      metrics['megtakaritas']?.secondaryValues,
      contains('várható cél: 600%'),
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
  List<TransactionCategory>? categories,
  List<CategoryLimit>? limits,
  List<RecurringGhostRecord>? recurringGhosts,
  double? savingGoal = 50000,
}) {
  return FastInfoMetricSnapshot(
    now: now ?? DateTime(2026, 6, 3, 12),
    balance: 300000,
    savingGoal: savingGoal,
    transactions: transactions ?? _transactions,
    categories: categories ?? _categories,
    limits: limits ?? <CategoryLimit>[_monthlyLimit(300000)],
    recurringGhosts: recurringGhosts ?? const <RecurringGhostRecord>[],
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
  int? recurringTransactionId,
  int? categoryId,
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
    transactionCategoryID: categoryId ?? (amount > 0 ? 2 : 1),
    recurringTransactionId: recurringTransactionId,
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

final _extendedCategories = <TransactionCategory>[
  ..._categories,
  TransactionCategory(
    transactionCategoryID: 3,
    name: 'Lakbér',
    type: 'expense',
    colorSlot: 2,
    iconSlot: 2,
    backgroundColor: null,
    icon: 'home',
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  ),
  TransactionCategory(
    transactionCategoryID: 4,
    name: 'Utazás',
    type: 'expense',
    colorSlot: 3,
    iconSlot: 3,
    backgroundColor: null,
    icon: 'directions_bus',
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  ),
];

RecurringGhostRecord _ghost({
  required int id,
  required int recurringTransactionId,
  required String name,
  required double amount,
  required String date,
  bool isActivated = false,
  String transactionType = 'expense',
  int categoryId = 3,
  String categoryName = 'Lakbér',
}) {
  return RecurringGhostRecord(
    id: id,
    recurringTransactionId: recurringTransactionId,
    periodKey: '2026-06',
    name: name,
    amount: amount,
    transactionType: transactionType,
    date: date,
    time: '08:00',
    categoryId: categoryId,
    categoryName: categoryName,
    categoryColor: '#64748b',
    categoryIconSlot: 2,
    triggerMillis: 0,
    isActivated: isActivated,
    activatedTransactionId: isActivated ? 1000 + id : null,
    createdAt: 0,
    updatedAt: 0,
  );
}
