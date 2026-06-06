import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'store projects pending ghosts for monthly windows and hides them from sum',
    () async {
      DebugConsole.clear();
      final repository = GhostRepository();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 10),
      );
      await store.start();

      expect(store.visibleTransactions.single.displayMerchant, 'Real Shop');
      expect(store.visibleGhostTransactions, isEmpty);
      expect(store.visibleLogEntries.length, 1);
      expect(
        store.activeSummary.formattedFor(TransactionType.expense),
        '-100 Ft',
      );

      await store.cycleSummaryWindow();
      expect(repository.ensureTargets.single, DateTime(2026, 5));
      expect(store.visibleGhostTransactions.single.periodKey, '2026-05');
      expect(store.visibleLogEntries.length, 2);
      expect(
        DebugConsole.entries.any(
          (entry) =>
              entry.contains('[Recurring] projected 1 ghosts for 2026-05'),
        ),
        isTrue,
      );

      await store.shiftSummaryPeriod(1);
      expect(repository.ensureTargets.last, DateTime(2026, 6));
      expect(store.visibleGhostTransactions.single.periodKey, '2026-06');

      await store.shiftSummaryPeriod(-2);
      expect(repository.ensureTargets.last, DateTime(2026, 4));
      expect(store.visibleGhostTransactions, isEmpty);
    },
  );

  test('store hides activated ghosts from visible rows', () async {
    final repository = GhostRepository(
      bootstrapGhosts: [ghostFixture(activated: true)],
      projectedGhosts: [ghostFixture(activated: true)],
    );
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 10),
    );
    await store.start();
    await store.cycleSummaryWindow();

    expect(store.visibleGhostTransactions, isEmpty);
  });

  test('recurring income ghosts are loaded for FastInfo', () async {
    final incomeGhost = ghostFixture(
      id: 20,
      recurringId: 90,
      name: 'Salary',
      amount: 300000,
      transactionType: 'income',
      categoryName: 'Income',
      categoryColor: '#16a34a',
      categoryIconSlot: 4,
    );
    final repository = GhostRepository(
      bootstrapGhosts: [ghostFixture(), incomeGhost],
      projectedGhosts: [ghostFixture(id: 5), incomeGhost],
    );
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 10),
    );

    await store.start();

    final loadedIncomeGhost = store.recurringGhostTransactions.singleWhere(
      (ghost) => ghost.type == TransactionType.income,
    );
    expect(loadedIncomeGhost.categoryName, 'Income');
    expect(
      store.fastInfoMetrics['bevetel_ebben_a_honapban']?.primaryValue,
      '0 Ft',
    );
    expect(
      store.fastInfoMetrics['bevetel_ebben_a_honapban']?.secondaryValues,
      contains('várt 300k · ghost 300k'),
    );
    expect(
      store.fastInfoMetrics['havi_fix_koltseg_osszesen']?.primaryValue,
      '500 Ft',
    );

    await store.cycleSummaryWindow();
    store.setActiveType(TransactionType.income);

    expect(store.visibleGhostTransactions.single.name, 'Salary');
    expect(store.visibleGhostTransactions.single.displayAmount, '+300 000 Ft');
    expect(store.activeSummary.formattedFor(TransactionType.income), '+0 Ft');
  });

  testWidgets('log list renders pending recurring ghost logboxes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 320,
          child: TransactionLogList(
            records: const [],
            ghostRecords: [ghostFixture()],
            categories: [categoryFixture()],
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('recurring-ghost-logbox-1')),
      findsOneWidget,
    );
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Ghost'), findsOneWidget);
  });
}

class GhostRepository implements TransactionRepositoryContract {
  GhostRepository({
    List<RecurringGhostRecord>? bootstrapGhosts,
    this.projectedGhosts,
  }) : bootstrapGhosts = bootstrapGhosts ?? [ghostFixture()];

  final List<RecurringGhostRecord> bootstrapGhosts;
  final List<RecurringGhostRecord>? projectedGhosts;
  final ensureTargets = <DateTime>[];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: [categoryFixture()],
    transactions: [
      TransactionRecord.fromMap({
        'id': 1,
        'date': '2026.05.10',
        'time': '10:00',
        'merchant': 'Real Shop',
        'amount': -100,
        'userAssignedName': null,
        'transactionCategoryID': 6,
      }),
    ],
    limits: const [],
    recurringGhostTransactions: bootstrapGhosts,
  );

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    return TransactionPage(
      transactions: const [],
      totalCount: 0,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<TransactionRecord> addTransaction(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<bool> deleteTransaction(int id) async => throw UnimplementedError();

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async =>
      throw UnimplementedError();

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<bool> deleteCategory(int id) async => throw UnimplementedError();

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async => throw UnimplementedError();

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async =>
      throw UnimplementedError();

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async {
    final target = targetDate ?? DateTime(2026, 5);
    final month = DateTime(target.year, target.month);
    ensureTargets.add(month);
    final projected = projectedGhosts;
    if (projected != null) return projected;
    return [
      ghostFixture(year: month.year, month: month.month, id: month.month),
    ];
  }

  @override
  Future<Map<int, int>> categoryCounts() async => const {};

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => const [];

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();
}

RecurringGhostRecord ghostFixture({
  int year = 2026,
  int month = 5,
  int id = 1,
  int recurringId = 9,
  String name = 'Rent',
  double amount = 500,
  String transactionType = 'expense',
  String categoryName = 'Q',
  String categoryColor = '#dc2626',
  int categoryIconSlot = 2,
  bool activated = false,
}) {
  final periodKey =
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  final date =
      '${year.toString().padLeft(4, '0')}.${month.toString().padLeft(2, '0')}.15';
  return RecurringGhostRecord.fromMap({
    'id': id,
    'recurringTransactionId': recurringId,
    'periodKey': periodKey,
    'name': name,
    'amount': amount,
    'transactionType': transactionType,
    'date': date,
    'time': '00:00',
    'categoryId': 6,
    'categoryName': categoryName,
    'categoryColor': categoryColor,
    'categoryIconSlot': categoryIconSlot,
    'triggerMillis': 1778803200000,
    'isActivated': activated,
    'activatedTransactionId': activated ? 120 : null,
    'createdAt': 1778360000000,
    'updatedAt': 1778360000000,
  });
}

TransactionCategory categoryFixture() => TransactionCategory.fromMap({
  'transactionCategoryID': 6,
  'name': 'Q',
  'type': 'kiadás',
  'colorSlot': 7,
  'iconSlot': 2,
  'backgroundColor': '#dc2626',
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': true,
});
