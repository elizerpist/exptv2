import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_dashboard_mode.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_test_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const balanceProductionViewport = Size(412, 892);
const balanceProductionPageColor = Color(0xFFF1F5F9);

/// Creates the same store used by [pumpBalanceProductionHost] so a test can
/// commit an initial query state before the production route first mounts.
TransactionStore createBalanceProductionStore({
  List<TransactionRecord>? transactions,
  List<TransactionCategory>? categories,
  List<CategoryLimit>? limits,
}) => TransactionStore(
  _BalanceProductionRepository(
    transactions: transactions,
    categories: categories,
    limits: limits,
  ),
  clock: _clock,
);

/// Mounts the actual Balance route:
/// [TransactionHomePage] → [SpendeeTestDashboard] →
/// [SpendeeBalanceDashboard].
Future<TransactionStore> pumpBalanceProductionHost(
  WidgetTester tester, {
  bool expanded = true,
  BalanceFrameInput? input,
  TransactionStore? store,
  List<TransactionRecord>? transactions,
  bool allTime = false,
  bool settle = true,
  bool recoverKnownDetailCardOverflows = false,
  SpendeeDashboardMode dashboardMode = SpendeeDashboardMode.balance,
}) async {
  tester.view
    ..physicalSize = balanceProductionViewport
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final activeStore =
      store ?? createBalanceProductionStore(transactions: transactions);
  // ignore: avoid_print
  print('[RailPerfDiag] host.store_start');
  await activeStore.start();
  // ignore: avoid_print
  print('[RailPerfDiag] host.store_complete');
  // The store publishes the all-time query synchronously before beginning its
  // unrelated recurring-ghost projection. The production host needs that
  // rendered query state, not to await background ghost work.
  if (allTime) activeStore.setSummaryAllTime();
  if (input != null &&
      !input.sameRevisionAs(BalanceFrameInput.fromStore(activeStore))) {
    throw ArgumentError.value(
      input,
      'input',
      'must match the supplied production TransactionStore',
    );
  }

  final settings = AppThemeSettings.defaults().copyWith(
    dashboardDesignMode: DashboardDesignMode.spendeeTest,
  );
  // ignore: avoid_print
  print('[RailPerfDiag] host.pumpWidget_start');
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Material(
        color: Colors.transparent,
        child: ListenableBuilder(
          listenable: activeStore,
          builder: (context, _) => TransactionHomePage(
            store: activeStore,
            expenseTheme: ExpenseTheme.fromSettings(settings),
            dashboardMode: dashboardMode,
            onEditTransaction: (_) {},
            onDeleteTransactionRequested: (_) async => true,
            onVendorSheetRequested: () {},
            logBottomPadding: 0,
          ),
        ),
      ),
    ),
  );
  // ignore: avoid_print
  print('[RailPerfDiag] host.pumpWidget_complete');
  if (recoverKnownDetailCardOverflows) {
    // Task 5 owns D1–D5. Until those card layouts are corrected, the real
    // host reports known RenderFlex overflows on its first frame. This opt-in
    // recovery is only for Task 2's independent material/semantics checks;
    // the production contract keeps a host-clean assertion for Task 5.
    _recoverKnownDetailCardOverflows(tester);
  } else if (settle) {
    await tester.pumpAndSettle();
  }

  expect(find.byType(TransactionHomePage), findsOneWidget);
  expect(find.byType(SpendeeTestDashboard), findsOneWidget);
  expect(find.byType(SpendeeBalanceDashboard), findsOneWidget);

  if (!expanded) {
    await tester.drag(
      find.byKey(const ValueKey('spendee-balance-collapse-handle')),
      const Offset(0, -180),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }
  return activeStore;
}

BoxDecoration decorationOf(WidgetTester tester, Finder finder) {
  final direct = tester.widget(finder);
  if (direct is Ink && direct.decoration is BoxDecoration) {
    return direct.decoration as BoxDecoration;
  }
  if (direct is Container && direct.decoration is BoxDecoration) {
    return direct.decoration as BoxDecoration;
  }
  final decorated = find.descendant(
    of: finder,
    matching: find.byType(DecoratedBox),
  );
  final target = decorated.evaluate().isNotEmpty ? decorated.first : finder;
  final widget = tester.widget(target);
  if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
    return widget.decoration as BoxDecoration;
  }
  throw StateError('No BoxDecoration for $finder');
}

List<Color> coloredAncestorsOf(WidgetTester tester, Finder finder) {
  final colors = <Color>[];
  tester.element(finder).visitAncestorElements((element) {
    final widget = element.widget;
    final color = switch (widget) {
      ColoredBox(:final color) => color,
      Material(:final color) => color,
      Ink(decoration: final BoxDecoration decoration) => decoration.color,
      DecoratedSliver(decoration: final BoxDecoration decoration) =>
        decoration.color,
      DecoratedBox(decoration: final BoxDecoration decoration) =>
        decoration.color,
      Container(decoration: final BoxDecoration decoration) => decoration.color,
      PhysicalModel(:final color) => color,
      Card(:final color) => color,
      _ => null,
    };
    if (color != null && color.a > 0) colors.add(color);
    return true;
  });
  return colors;
}

InputDecoration effectiveInputDecoration(WidgetTester tester) => tester
    .widget<TextField>(
      find.byKey(const ValueKey('spendee-balance-search-editable')),
    )
    .decoration!;

double centerDelta(WidgetTester tester, Finder first, Finder second) =>
    (tester.getCenter(first).dy - tester.getCenter(second).dy).abs();

void _recoverKnownDetailCardOverflows(WidgetTester tester) {
  while (true) {
    final exception = tester.takeException();
    if (exception == null) return;
    if (_isKnownDetailCardOverflow(exception)) continue;
    Error.throwWithStackTrace(exception, StackTrace.current);
  }
}

bool _isKnownDetailCardOverflow(Object exception) {
  final diagnostic = exception.toString();
  const pageKeys = <String>[
    'spendee-balance-detail-page-variable-budget',
    'spendee-balance-detail-page-top-categories',
    'spendee-balance-detail-page-top-merchants',
    'spendee-balance-detail-page-average-daily',
  ];
  return diagnostic.contains('RenderFlex overflowed') &&
      diagnostic.contains('spendee_balance_cards.dart') &&
      diagnostic.contains('SpendeeBalanceDetailPage') &&
      pageKeys.any(diagnostic.contains);
}

DateTime _clock() => DateTime(2026, 7, 17);

class _BalanceProductionRepository implements TransactionRepositoryContract {
  _BalanceProductionRepository({
    List<TransactionRecord>? transactions,
    List<TransactionCategory>? categories,
    List<CategoryLimit>? limits,
  }) : transactions = List<TransactionRecord>.unmodifiable(
         transactions ?? _defaultTransactions,
       ),
       categories = List<TransactionCategory>.unmodifiable(
         categories ??
             <TransactionCategory>[
               _category(1, 'Élelmiszer', 7, 0),
               _category(2, 'Közlekedés', 3, 1),
             ],
       ),
       limits = List<CategoryLimit>.of(
         limits ??
             <CategoryLimit>[_limit(1, LimitTargetType.overview, 0, 200000)],
       );

  final List<TransactionCategory> categories;
  static final _defaultTransactions = <TransactionRecord>[
    _record(1, 1, -63240, 'Élelmiszer bolt'),
    _record(2, 2, -31700, 'Busz'),
  ];
  final List<TransactionRecord> transactions;
  final List<CategoryLimit> limits;

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categories,
    transactions: transactions,
    limits: limits,
  );

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    final rows = transactions
        .where((row) => query.type == null || row.type == query.type)
        .toList();
    return TransactionPage(
      transactions: rows,
      totalCount: rows.length,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<List<TransactionRecord>> transactionsForNotificationEvents(
    Iterable<int> eventIds,
  ) async => const [];

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) =>
      throw UnimplementedError();
  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) => throw UnimplementedError();
  @override
  Future<bool> deleteTransaction(int id) async => true;
  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async => 0;
  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async =>
      0;
  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => const [];
  @override
  Future<List<RecurringRule>> listRecurringRules() async => const [];
  @override
  Future<RecurringRule> addRecurringRule(RecurringRuleDraft draft) =>
      throw UnimplementedError();
  @override
  Future<RecurringRule> updateRecurringRule(int id, RecurringRuleDraft draft) =>
      throw UnimplementedError();
  @override
  Future<RecurringRule> toggleRecurringRule(int id, bool isActive) =>
      throw UnimplementedError();
  @override
  Future<bool> deleteRecurringRule(int id) async => false;
  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) =>
      throw UnimplementedError();
  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) => throw UnimplementedError();
  @override
  Future<bool> deleteCategory(int id) async => true;
  @override
  Future<Map<int, int>> categoryCounts() async => {
    for (final category in categories) category.transactionCategoryID: 1,
  };
  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => limits;
  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    final targetType = LimitTargetTypeX.fromAny(payload['targetType']);
    final targetId = (payload['targetId'] as num).toInt();
    final transactionType = payload['transactionType']!.toString();
    final window = LimitWindowX.fromAny(payload['window']);
    final periodKey = payload['periodKey']!.toString();
    final existingIndex = limits.indexWhere(
      (limit) =>
          limit.targetType == targetType &&
          limit.targetId == targetId &&
          limit.transactionType == transactionType &&
          limit.window == window &&
          limit.periodKey == periodKey,
    );
    final existing = existingIndex < 0 ? null : limits[existingIndex];
    final saved = CategoryLimit(
      id:
          existing?.id ??
          (limits.fold<int>(
                0,
                (largest, limit) => limit.id > largest ? limit.id : largest,
              ) +
              1),
      targetType: targetType,
      targetId: targetId,
      transactionType: transactionType,
      window: window,
      periodKey: periodKey,
      hasLimit: payload['hasLimit'] == true,
      limitAmount: (payload['limitAmount'] as num).toDouble(),
      alertActive: payload['alertActive'] == true,
      createdAt: existing?.createdAt ?? 0,
      updatedAt: existing?.updatedAt ?? 0,
    );
    if (existingIndex < 0) {
      limits.add(saved);
    } else {
      limits[existingIndex] = saved;
    }
    return saved;
  }
}

CategoryLimit _limit(
  int id,
  LimitTargetType targetType,
  int targetId,
  double amount,
) => CategoryLimit(
  id: id,
  targetType: targetType,
  targetId: targetId,
  transactionType: 'expense',
  window: LimitWindow.monthly,
  periodKey: '2026-07',
  hasLimit: true,
  limitAmount: amount,
  alertActive: true,
  createdAt: 0,
  updatedAt: 0,
);

TransactionCategory _category(
  int id,
  String name,
  int colorSlot,
  int iconSlot,
) => TransactionCategory.fromMap({
  'transactionCategoryID': id,
  'name': name,
  'type': 'kiadás',
  'colorSlot': colorSlot,
  'iconSlot': iconSlot,
  'backgroundColor': null,
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': true,
});

TransactionRecord _record(
  int id,
  int categoryId,
  double amount,
  String merchant,
) => balanceProductionRecord(
  id,
  categoryId: categoryId,
  amount: amount,
  merchant: merchant,
);

TransactionRecord balanceProductionRecord(
  int id, {
  int categoryId = 1,
  double amount = -1000,
  String merchant = 'Teszt bolt',
  String date = '2026.07.17',
  String time = '10:00',
}) => TransactionRecord.fromMap({
  'id': id,
  'date': date,
  'time': time,
  'merchant': merchant,
  'amount': amount,
  'userAssignedName': null,
  'transactionCategoryID': categoryId,
});
