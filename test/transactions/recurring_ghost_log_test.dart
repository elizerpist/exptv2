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
    'store merges pending ghosts for display and excludes them from summary',
    () async {
      final store = TransactionStore(GhostRepository());
      await store.start();

      expect(store.visibleTransactions.single.displayMerchant, 'Real Shop');
      expect(store.visibleGhostTransactions.single.name, 'Rent');
      expect(store.visibleLogEntries.length, 2);
      expect(
        store.activeSummary.formattedFor(TransactionType.expense),
        '-100 Ft',
      );
    },
  );

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
            onDeleteRequested: (_) {},
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
    recurringGhostTransactions: [ghostFixture()],
  );

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

RecurringGhostRecord ghostFixture() => RecurringGhostRecord.fromMap({
  'id': 1,
  'recurringTransactionId': 9,
  'periodKey': '2026-05',
  'name': 'Rent',
  'amount': 500,
  'transactionType': 'expense',
  'date': '2026.05.15',
  'time': '00:00',
  'categoryId': 6,
  'categoryName': 'Q',
  'categoryColor': '#dc2626',
  'categoryIconSlot': 2,
  'triggerMillis': 1778803200000,
  'isActivated': false,
  'activatedTransactionId': null,
  'createdAt': 1778360000000,
  'updatedAt': 1778360000000,
});

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
