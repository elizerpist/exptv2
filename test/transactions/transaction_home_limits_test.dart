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
      expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
      expect(find.byKey(const ValueKey('limit-cancel-button')), findsNothing);
      expect(find.byKey(const ValueKey('limit-alert-toggle')), findsNothing);
      expect(find.byKey(const ValueKey('limit-card-avatar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('limit-reset-inline-button')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('limit-amount-input')),
        '300000',
      );
      await tester.pump(const Duration(milliseconds: 500));
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
      expect(find.text('Food'), findsWidgets);
      expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
      expect(find.byKey(const ValueKey('category-limit-slider')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('limit-amount-input')),
        '250',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repository.savedLimits.single['targetType'], 'category');
      expect(repository.savedLimits.single['targetId'], 6);
      expect(repository.savedLimits.single['transactionType'], 'expense');
      expect(repository.savedLimits.single['limitAmount'], 250);
    },
  );

  testWidgets('budget end button saves period income as overview limit', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('limit-slider-end-button')));
    await tester.pumpAndSettle();

    expect(repository.savedLimits.single['targetType'], 'overview');
    expect(repository.savedLimits.single['limitAmount'], 1000);
  });

  testWidgets('limit editor slider keeps adaptive max after manual high input', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withoutBudgetLimits();
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
    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    final initialSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('category-limit-slider')),
    );
    expect(initialSlider.max, 100000);
    expect(initialSlider.divisions, 100);

    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '250000',
    );
    await tester.pump(const Duration(milliseconds: 500));

    final highSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('category-limit-slider')),
    );
    expect(highSlider.max, 250000);

    await tester.drag(
      find.byKey(const ValueKey('category-limit-slider')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();

    final reducedSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('category-limit-slider')),
    );
    expect(reducedSlider.max, 250000);
  });

  testWidgets('limit editor is inline slide-up panel reaching screen bottom', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHomePage(store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('header-expand-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    final card = tester.getRect(
      find.byKey(const ValueKey('budget-target-editor-card')),
    );
    expect(card.bottom, moreOrLessEquals(844, epsilon: 0.1));
    expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
    expect(find.byKey(const ValueKey('limit-cancel-button')), findsNothing);
  });

  testWidgets(
    'redesigned limit card exposes arrows avatar input slider and partition bar',
    (tester) async {
      final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );
      await pumpExpandedMonthlyHome(tester, store);

      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('limit-card-previous-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('limit-card-next-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('limit-card-avatar')), findsOneWidget);
      expect(find.byKey(const ValueKey('limit-amount-input')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('limit-reset-inline-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-limit-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
        findsOneWidget,
      );
    },
  );

  testWidgets('partition tap selects category and syncs backheader', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('limit-allocation-pie-chart')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('category-limit-partition-segment-0')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('limit-card-title')), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(
      tester.widget<Text>(
        find.byKey(const ValueKey('backheader-active-title')),
      ).data,
      'Food',
    );
  });

  testWidgets('editor arrows sync active backheader bar', (tester) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('limit-card-next-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('backheader-active-title')),
      findsOneWidget,
    );
    expect(find.text('Food'), findsWidgets);
  });

  testWidgets('income side uses income goal and income category allocation', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withIncomeData();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.text('Bevétel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    expect(find.text('Beveteli cel'), findsWidgets);
    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('limit-allocation-pie-chart')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('limit-slider-end-button')));
    await tester.pumpAndSettle();

    expect(repository.savedLimits.last['targetType'], 'overview');
    expect(repository.savedLimits.last['transactionType'], 'income');
  });

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
    const Offset(0, -90),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
}

class FakeHomeLimitRepository implements TransactionRepositoryContract {
  FakeHomeLimitRepository();

  FakeHomeLimitRepository.withoutBudgetLimits();

  FakeHomeLimitRepository.withIncomeData() {
    limits = [
      CategoryLimit.fromMap({
        'id': 20,
        'targetType': 'overview',
        'targetId': 0,
        'transactionType': 'income',
        'window': 'monthly',
        'periodKey': '2026-05',
        'hasLimit': true,
        'limitAmount': 1000,
        'alertActive': false,
        'createdAt': 0,
        'updatedAt': 1,
      }),
    ];
  }

  FakeHomeLimitRepository.withBudgetAndCategoryLimits() {
    categories.add(
      TransactionCategory.fromMap({
        'transactionCategoryID': 7,
        'name': 'Travel',
        'type': 'kiadás',
        'colorSlot': 8,
        'iconSlot': 3,
        'backgroundColor': '#38bdf8',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      }),
    );
    limits = [
      CategoryLimit.fromMap({
        'id': 10,
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
      CategoryLimit.fromMap({
        'id': 11,
        'targetType': 'category',
        'targetId': 6,
        'transactionType': 'expense',
        'window': 'monthly',
        'periodKey': '2026-05',
        'hasLimit': true,
        'limitAmount': 250,
        'alertActive': false,
        'createdAt': 0,
        'updatedAt': 1,
      }),
    ];
  }

  final savedLimits = <Map<String, Object?>>[];
  var limits = <CategoryLimit>[];

  final categories = <TransactionCategory>[
    TransactionCategory.fromMap({
      'transactionCategoryID': 5,
      'name': 'Salary',
      'type': 'bevétel',
      'colorSlot': 2,
      'iconSlot': 0,
      'backgroundColor': '#3b82f6',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
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
    TransactionRecord.fromMap({
      'id': 2,
      'date': '2026.05.01',
      'time': '09:00',
      'merchant': 'Salary',
      'amount': 1000,
      'userAssignedName': null,
      'transactionCategoryID': 5,
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
  Future<Map<int, int>> categoryCounts() async => const {5: 1, 6: 1};
}
