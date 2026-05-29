import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'expanded home stage saves first item as overview expense budget',
    (tester) async {
      final repository = FakeHomeLimitRepository();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );

      await pumpExpandedMonthlyHome(tester, store);

      expect(
        find.byKey(const ValueKey('category-budget-stage')),
        findsOneWidget,
      );
      expect(find.text('Budget'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();
      expect(find.text('Budget limit'), findsWidgets);
      await tester.enterText(
        find.byKey(const ValueKey('limit-amount-input')),
        '300000',
      );
      await tester.tap(find.byKey(const ValueKey('limit-save-button')));
      await tester.pumpAndSettle();

      expect(repository.savedLimits.single['targetType'], 'overview');
      expect(repository.savedLimits.single['targetId'], 0);
      expect(repository.savedLimits.single['transactionType'], 'expense');
      expect(repository.savedLimits.single['window'], 'monthly');
      expect(repository.savedLimits.single['periodKey'], '2026-05');
      expect(repository.savedLimits.single['limitAmount'], 300000);
    },
  );

  testWidgets(
    'expanded home stage opens category limit after swiping past budget item',
    (tester) async {
      final repository = FakeHomeLimitRepository();
      repository.limits = [
        CategoryLimit.fromMap({
          'id': 9,
          'targetType': 'overview',
          'targetId': 0,
          'transactionType': 'expense',
          'window': 'monthly',
          'periodKey': '2026-05',
          'hasLimit': true,
          'limitAmount': 1000,
          'alertActive': false,
          'createdAt': 0,
          'updatedAt': 1,
        }),
      ];
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );

      await pumpExpandedMonthlyHome(tester, store);
      await tester.drag(
        find.byKey(const ValueKey('category-budget-bar')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Food'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();
      expect(find.text('Food limit'), findsOneWidget);
      expect(find.byKey(const ValueKey('category-limit-slider')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('limit-amount-input')),
        '250',
      );
      await tester.tap(find.byKey(const ValueKey('limit-save-button')));
      await tester.pumpAndSettle();

      expect(repository.savedLimits.single['targetType'], 'category');
      expect(repository.savedLimits.single['targetId'], 6);
      expect(repository.savedLimits.single['transactionType'], 'expense');
      expect(repository.savedLimits.single['limitAmount'], 250);
    },
  );
}

Future<void> pumpExpandedMonthlyHome(
  WidgetTester tester,
  TransactionStore store,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 780,
          child: TransactionHomePage(store: store),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.drag(
    find.byKey(const ValueKey('summary-pill')),
    const Offset(90, 0),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
}

class FakeHomeLimitRepository implements TransactionRepositoryContract {
  final savedLimits = <Map<String, Object?>>[];
  var limits = <CategoryLimit>[];

  final categories = <TransactionCategory>[
    TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Food',
      'type': 'kiadás',
      'colorSlot': 7,
      'iconSlot': 2,
      'backgroundColor': '#0ea5e9',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
  ];

  final transactions = <TransactionRecord>[
    TransactionRecord.fromMap({
      'id': 1,
      'date': '2026.05.04',
      'time': '12:00',
      'merchant': 'Shop',
      'amount': -100,
      'userAssignedName': null,
      'transactionCategoryID': 6,
    }),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categories,
    transactions: transactions,
    limits: limits,
  );

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    savedLimits.add(payload);
    final limit = CategoryLimit.fromMap({
      'id': 1,
      ...payload,
      'hasLimit': payload['hasLimit'],
      'createdAt': 0,
      'updatedAt': 1,
    });
    limits = [limit];
    return limit;
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => limits;

  @override
  Future<TransactionRecord> addTransaction(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    throw UnimplementedError();
  }

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
  }) async => const [];

  @override
  Future<Map<int, int>> categoryCounts() async => const {6: 1};
}
