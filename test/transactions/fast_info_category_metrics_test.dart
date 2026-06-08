import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric_snapshot.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/fast_info_metrics_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves transaction category merchant and limit metrics', () {
    final metrics = FastInfoMetricsResolver.resolve(
      FastInfoMetricSnapshot(
        now: DateTime(2026, 6, 3, 18),
        balance: 200000,
        transactions: _transactions,
        categories: _categories,
        limits: _limits,
      ),
    );

    expect(metrics['legutobbi_tranzakcio']?.primaryValue, '-2 000 Ft');
    expect(metrics['legutobbi_tranzakcio']?.avatar, isNotNull);
    expect(metrics['leggyakoribb_kereskedo']?.primaryValue, 'Kávézó');
    expect(
      metrics['leggyakoribb_kereskedo']?.secondaryValues,
      contains('legtöbb tranzakció'),
    );
    expect(
      metrics['leggyakoribb_kereskedo']?.secondaryValues,
      contains('4 alkalom'),
    );
    expect(metrics['leggyakoribb_kereskedo']?.avatar, isNotNull);
    expect(metrics['top_kategoria_ma'], isNull);
    expect(metrics['top_kategoria_heten']?.primaryValue, 'Étel');
    expect(
      metrics['top_kategoria_heten']?.secondaryValues,
      contains(startsWith('Hét:')),
    );
    expect(metrics['legnagyobb_novekedo_kategoria']?.trend?.text, '+50%');
    expect(
      metrics['leggyorsabban_fogyo_kategorialimit']?.progress,
      closeTo(1.1, .001),
    );
    expect(
      metrics['leggyorsabban_fogyo_kategorialimit']?.semantic,
      FastInfoSemantic.bad,
    );
  });

  test('shows new instead of infinity for a newly used category', () {
    final metrics = FastInfoMetricsResolver.resolve(
      FastInfoMetricSnapshot(
        now: DateTime(2026, 6, 3, 18),
        balance: 0,
        transactions: <TransactionRecord>[
          _expense(30, '2026.06.03', 'Új bolt', 4000, 2),
        ],
        categories: _categories,
      ),
    );

    expect(metrics['legnagyobb_novekedo_kategoria']?.trend?.text, 'Új');
  });
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
    name: 'Szabadidő',
    type: 'expense',
    colorSlot: 1,
    iconSlot: 1,
    backgroundColor: null,
    icon: 'movie',
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  ),
];

const _limits = <CategoryLimit>[
  CategoryLimit(
    id: 1,
    targetType: LimitTargetType.category,
    targetId: 1,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-06',
    hasLimit: true,
    limitAmount: 10000,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  ),
];

final _transactions = <TransactionRecord>[
  _expense(1, '2026.06.03', 'Kávézó', 2000, 1, time: '14:00'),
  _expense(2, '2026.06.03', 'Piac', 4000, 1),
  _expense(3, '2026.06.02', 'Kávézó', 3000, 1),
  _expense(4, '2026.06.01', 'Kávézó', 2000, 1),
  _expense(5, '2026.05.28', 'Kávézó', 1000, 1),
  _expense(6, '2026.05.10', 'Régi étel', 10000, 1),
  _expense(7, '2026.04.20', 'Régebbi étel', 14666.67, 1),
  _expense(8, '2026.06.01', 'Mozi', 5000, 2),
  _expense(9, '2026.05.01', 'Régi mozi', 5000, 2),
];

TransactionRecord _expense(
  int id,
  String date,
  String merchant,
  double amount,
  int categoryId, {
  String time = '12:00',
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: time,
    merchant: merchant,
    amount: -amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
  );
}
