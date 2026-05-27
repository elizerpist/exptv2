import 'package:exptv2/features/transactions/data/transaction_repository.dart';
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
    expect(find.text('Q'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('category-card-6')));
    expect(selected?.name, 'Q');

    await tester.longPress(find.byKey(const ValueKey('category-icon-6')));
    expect(modified?.name, 'Q');

    await tester.tap(find.byKey(const ValueKey('category-delete-6')));
    expect(deleted, isNull);

    await tester.tap(find.byKey(const ValueKey('category-add-button')));
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
    await tester.tap(find.byKey(const ValueKey('category-card-6')));
    await tester.pumpAndSettle();

    expect(store.activeCategory?.name, 'Q');
    expect(find.text('Test Store'), findsOneWidget);
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

class FakeTransactionRepository implements TransactionRepositoryContract {
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
  );

  @override
  Future<TransactionRecord> addTransaction(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

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
  Future<Map<int, int>> categoryCounts() async => const {6: 1};
}
