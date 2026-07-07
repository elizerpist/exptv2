import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/features/stats/widgets/stats_category_scope_sheet.dart';
import 'package:exptv2/features/stats/widgets/stats_fast_info_graph.dart';
import 'package:exptv2/features/stats/widgets/stats_year_calendar.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stats annual calendar renders 12 month hit targets', (
    tester,
  ) async {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.categoryScope,
      thresholdValue: 5000,
      transactions: const [],
      categories: const [],
      selectedCategoryIds: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: StatsYearCalendar(data: data, onMonthSelected: (_) {}),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('stats-year-calendar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stats-year-calendar-paint')),
      findsOneWidget,
    );
    for (var month = 1; month <= 12; month += 1) {
      expect(find.byKey(ValueKey('stats-month-hit-$month')), findsOneWidget);
    }
  });

  testWidgets('stats FastInfo graph is a graph-only surface', (tester) async {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.heatmap,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 328,
            child: StatsFastInfoGraph(data: data),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('stats-fastinfo-graph')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-fastinfo-card')), findsNothing);
    expect(find.byKey(const ValueKey('stats-fastinfo-pill')), findsNothing);
  });

  testWidgets('stats scope sheet toggles multiple active-type categories', (
    tester,
  ) async {
    Set<int>? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatsCategoryScopeSheet(
            activeType: TransactionType.expense,
            categories: [
              category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
              category(id: 2, name: 'Ruha', type: TransactionType.expense),
              category(id: 3, name: 'Fizetés', type: TransactionType.income),
            ],
            selectedCategoryIds: const {},
            accentColor: const Color(0xFF06B6D4),
            onApply: (ids) => applied = ids,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('stats-scope-sheet')), findsOneWidget);
    expect(find.text('Gyorskaja'), findsOneWidget);
    expect(find.text('Ruha'), findsOneWidget);
    expect(find.text('Fizetés'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('stats-scope-category-1')));
    await tester.tap(find.byKey(const ValueKey('stats-scope-category-2')));
    await tester.pump();
    expect(find.byKey(const ValueKey('stats-scope-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stats-scope-apply')));
    expect(applied, {1, 2});
  });

  testWidgets('stats page renders the redesigned annual main menu', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-menu-overlay')), findsNothing);
    expect(find.byType(CalendarMenuOverlay), findsNothing);
    expect(
      find.byKey(const ValueKey('transaction-header-card')),
      findsOneWidget,
    );
    expect(find.text('SCOPE TREND'), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-pill')), findsOneWidget);
    expect(find.text('Éves · 2026 · Kiadás'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-year-calendar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-threshold-joystick-trigger')),
      findsOneWidget,
    );
  });

  testWidgets('stats joystick tap opens render mode selector', (tester) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('calendar-threshold-joystick-trigger')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stats-render-mode-selector')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('stats-render-mode-heatmap')));
    await tester.pumpAndSettle();

    expect(find.text('HEATMAP'), findsOneWidget);
  });

  testWidgets('stats header category button opens scope sheet', (tester) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
          category(id: 2, name: 'Ruha', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-scope-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stats-scope-category-1')));
    await tester.tap(find.byKey(const ValueKey('stats-scope-apply')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gyorskaja'), findsAtLeastNWidgets(1));
  });

  testWidgets('stats header pull reveals graph-only FastInfo', (tester) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('transaction-header-card'))),
    );
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();

    expect(find.byKey(const ValueKey('stats-fastinfo-graph')), findsOneWidget);
    await gesture.up();
  });
}

TransactionRecord record({
  required int id,
  required String date,
  required double amount,
  required int categoryId,
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '10:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Teszt',
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
  );
}

TransactionCategory category({
  required int id,
  required String name,
  required TransactionType type,
}) {
  return TransactionCategory(
    transactionCategoryID: id,
    name: name,
    type: type.hungarianValue,
    colorSlot: id,
    iconSlot: null,
    backgroundColor: null,
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
}

class StatsRepository extends TransactionRepositoryContract {
  StatsRepository({required this.categories, required this.transactions});

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categories,
    transactions: transactions,
    limits: const [],
  );

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    return TransactionPage(
      transactions: transactions,
      totalCount: transactions.length,
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
  }) async => const [];

  @override
  Future<Map<int, int>> categoryCounts() async => {
    for (final category in categories) category.transactionCategoryID: 0,
  };

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
