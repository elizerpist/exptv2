import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/fast_info_metrics_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 6, 3, 12);

  test('resolves day month limit and trend cards from transactions', () {
    final metrics = FastInfoMetricsResolver.resolve(
      transactions: _transactions,
      categories: _categories,
      limits: _limits,
      now: today,
    );

    expect(metrics['mai_koltes']?.pillValue, '7k');
    expect(metrics['mai_koltes']?.boxValue, '7 000 Ft');
    expect(metrics['mai_koltes']?.boxSubtitle, '2 tranzakció ma');

    expect(metrics['havi_koltes']?.pillValue, '27k');
    expect(metrics['havi_koltes']?.boxValue, '27k / 100k');
    expect(metrics['havi_koltes']?.boxSubtitle, 'A havi keret 27%-a');
    expect(metrics['havi_koltes']?.progress, closeTo(0.27, 0.001));

    expect(metrics['havi_limit_allapot']?.pillValue, '27%');
    expect(metrics['havi_limit_allapot']?.boxSubtitle, '73k maradt');

    expect(metrics['koltesi_trend']?.pillValue, '-10%');
    expect(metrics['koltesi_trend']?.boxValue, '-10%');
    expect(metrics['koltesi_trend']?.boxSubtitle, 'Az előző időszakhoz képest');
  });

  test('box metrics expose richer chart data for the same card', () {
    final metrics = FastInfoMetricsResolver.resolve(
      transactions: _transactions,
      categories: _categories,
      limits: _limits,
      now: today,
    );

    final metric = metrics['atlagos_napi_koltes'];

    expect(metric?.pillValue, '9k');
    expect(metric?.boxValue, '9 000 Ft');
    expect(metric?.boxSubtitle, '3 aktív nap alapján');
    expect(metric?.series, hasLength(7));
    expect(metric?.series.last, 7000);
  });

  test('all catalog cards receive live metric output', () {
    final metrics = FastInfoMetricsResolver.resolve(
      transactions: _transactions,
      categories: _categories,
      limits: _limits,
      now: today,
    );

    expect(
      metrics.keys.toSet(),
      fastInfoCardCatalog.map((card) => card.id).toSet(),
    );
    expect(metrics.values.every((metric) => metric.pillValue.isNotEmpty), true);
    expect(metrics.values.every((metric) => metric.boxValue.isNotEmpty), true);
  });
}

const _categories = <TransactionCategory>[
  TransactionCategory(
    transactionCategoryID: 1,
    name: 'Etel',
    type: 'expense',
    colorSlot: 0,
    iconSlot: 0,
    backgroundColor: null,
    icon: 'restaurant',
    notification: null,
    hasLimit: true,
    limitAmount: 60000,
    alertActive: true,
    isCustomIcon: false,
    originalIcon: null,
  ),
  TransactionCategory(
    transactionCategoryID: 2,
    name: 'Fizetes',
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

const _limits = <CategoryLimit>[
  CategoryLimit(
    id: 1,
    targetType: LimitTargetType.overview,
    targetId: 0,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-06',
    hasLimit: true,
    limitAmount: 100000,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  ),
  CategoryLimit(
    id: 2,
    targetType: LimitTargetType.category,
    targetId: 1,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-06',
    hasLimit: true,
    limitAmount: 60000,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  ),
];

const _transactions = <TransactionRecord>[
  TransactionRecord(
    id: 1,
    date: '2026.06.03',
    time: '09:10',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Pekseg',
    amount: -3000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 2,
    date: '2026.06.03',
    time: '11:30',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Ebed',
    amount: -4000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 3,
    date: '2026.06.02',
    time: '17:30',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Bolt',
    amount: -12000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 4,
    date: '2026.06.01',
    time: '18:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Piac',
    amount: -8000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 5,
    date: '2026.05.15',
    time: '10:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Elozo honap',
    amount: -30000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 6,
    date: '2026.06.01',
    time: '08:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Fizetes',
    amount: 150000,
    userAssignedName: null,
    transactionCategoryID: 2,
  ),
];
