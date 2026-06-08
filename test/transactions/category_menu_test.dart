import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_menu_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category panel filters cards and protects used categories', (
    tester,
  ) async {
    TransactionCategory? selected;
    TransactionCategory? modified;
    TransactionCategory? deleted;
    var addPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            activeType: TransactionType.expense,
            categories: categoryFixtures,
            categoryTransactionCounts: const {6: 3},
            activeCategory: null,
            onSelect: (category) => selected = category,
            onModify: (category) => modified = category,
            onDelete: (category) => deleted = category,
            onAdd: () => addPressed = true,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Válassz kategóriát'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-menu-back-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('category-menu-add-button')), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('category-card-6')),
      warnIfMissed: false,
    );
    expect(selected?.name, 'Q');

    selected = null;
    modified = null;
    await tester.tap(find.byKey(const ValueKey('category-icon-6')));
    expect(selected?.name, 'Q');
    expect(modified, isNull);

    await tester.longPress(
      find.byKey(const ValueKey('category-card-6')),
      warnIfMissed: false,
    );
    expect(modified?.name, 'Q');

    await tester.tap(find.byKey(const ValueKey('category-delete-6')));
    expect(deleted, isNull);

    expect(addPressed, isFalse);
    await tester.tap(find.byKey(const ValueKey('category-menu-add-button')));
    expect(addPressed, isTrue);
  });

  testWidgets('home header category button opens picker and filters logs', (
    tester,
  ) async {
    final store = TransactionStore(FakeTransactionRepository());

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

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    expect(find.text('Válassz kategóriát'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('category-card-6')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(store.activeCategory?.name, 'Q');
    expect(find.text('Test Store'), findsOneWidget);
  });

  testWidgets('category cards use inset body and raised avatar in neumorphism', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            activeType: TransactionType.expense,
            categories: categoryFixtures,
            categoryTransactionCounts: const {6: 3},
            activeCategory: categoryFixtures.last,
            surfaceColor: AppColors.gray200,
            cardSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
            avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            onSelect: (_) {},
            onModify: (_) {},
            onDelete: (_) {},
            onAdd: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('category-card-surface-6')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-icon-surface-6')),
      findsOneWidget,
    );
    final card = tester.widget<Container>(
      find.byKey(const ValueKey('category-card-surface-6')),
    );
    expect((card.decoration! as BoxDecoration).boxShadow, isNull);
  });
}

final categoryFixtures = <TransactionCategory>[
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
    'name': 'Q',
    'type': 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#dc2626',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  }),
];

class FakeTransactionRepository extends TransactionRepositoryContract {
  final transactions = <TransactionRecord>[
    TransactionRecord.fromMap({
      'id': 1,
      'date': '2025.09.25',
      'time': '20:30:00',
      'merchant': 'Test Store',
      'amount': -505,
      'userAssignedName': null,
      'transactionCategoryID': 6,
    }),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categoryFixtures,
    transactions: transactions,
    limits: const [],
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
