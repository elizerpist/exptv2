import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/widgets/experimental/fluvi_logo.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_test_dashboard.dart';
import 'package:exptv2/features/transactions/widgets/glossy_category_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stage 1 keeps C2 avatar-only glossy layout and core progress', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(
      find.byKey(const ValueKey('spendee-test-header-core-partition')),
      findsOneWidget,
    );
    expect(find.textContaining('Elköltve'), findsNothing);
    expect(find.textContaining('Maradt'), findsNothing);

    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final glossy = find.byKey(
      const ValueKey('spendee-test-budget-stage1-glossy'),
    );
    expect(glossy, findsOneWidget);
    expect(tester.getRect(glossy), const Rect.fromLTWH(36, 200, 340, 130));
    expect(
      find.descendant(
        of: glossy,
        matching: find.byKey(const ValueKey('spendee-test-context-carousel')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: glossy,
        matching: find.byKey(const ValueKey('spendee-test-partition-bar')),
      ),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey('spendee-test-partition-segment-used-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-partition-segment-remaining-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-partition-segment-free')),
      findsOneWidget,
    );

    final outerAvatar = tester.widget<GlossyCategoryAvatar>(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-test-category-avatar-4')),
        matching: find.byType(GlossyCategoryAvatar),
      ),
    );
    expect(outerAvatar.iconSize, 17);
  });

  testWidgets('live carousel ticks pulse the new center and cancel recenters', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final carousel = find.byKey(
      const ValueKey('spendee-test-context-carousel-gesture'),
    );
    final gesture = await tester.startGesture(tester.getCenter(carousel));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump(const Duration(milliseconds: 20));

    final selected = tester.widget<GlossyCategoryAvatar>(
      find.descendant(
        of: find.byKey(
          const ValueKey('spendee-test-category-avatar-2-selected'),
        ),
        matching: find.byType(GlossyCategoryAvatar),
      ),
    );
    expect(selected.pulsing, isTrue);

    await gesture.cancel();
    await tester.pumpAndSettle();
    final translated = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('spendee-test-context-carousel')),
    );
    expect(translated.transform?.storage[12] ?? 0, 0);
  });

  testWidgets(
    'stage 2 category rows select donut highlight and avatar target',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();
      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('spendee-test-budget-pie-row-3'));
      await tester.ensureVisible(row);
      await tester.pump();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('spendee-test-budget-pie-focus-title')),
            )
            .data,
        'Lakás',
      );
      expect(
        find.byKey(const ValueKey('spendee-test-category-avatar-3-selected')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'D1A logo tap opens slide-up editor with palette and custom slots',
    (tester) async {
      await _pumpDashboard(tester);

      expect(
        tester.getRect(find.byKey(const ValueKey('spendee-test-brand-lockup'))),
        const Rect.fromLTWH(0, 33.3, 412, 118),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('spendee-test-brand-logo'))),
        const Rect.fromLTWH(30, 39.3, 47.88, 47.88),
      );

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-brand-logo-tap')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-logo-editor-sheet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-editor-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-slot-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-slot-20')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-selected-D1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-app-gray900')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-custom-slot-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-custom-slot-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-component-top')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-component-bottom')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-component-path2')),
        findsNothing,
      );
    },
  );

  testWidgets('logo editor sends custom endpoint and boundary to an arc SVG', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await tester.tap(find.byKey(const ValueKey('spendee-test-brand-logo-tap')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-palette-slot-7')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-custom-left-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-palette-slot-20')),
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-custom-right-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-custom-swatch-1')),
    );
    final slider = find.byKey(
      const ValueKey('spendee-test-logo-custom-boundary-1'),
    );
    await tester.drag(slider, const Offset(-70, 0));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-component-top')),
    );
    await tester.pump();

    final preview = tester.widget<FluviLogo>(
      find.byKey(const ValueKey('spendee-test-fluvi-logo-preview')),
    );
    final fill = preview.fills[FluviLogoArc.top]!;
    expect(fill.left, const Color(0xFF35C76E));
    expect(fill.right, const Color(0xFFFB56A8));
    expect(fill.boundary, isNot(50));

    final svg = FluviLogoSvg.document(preview.fills);
    expect(svg, contains('id="fluvi-arc-top"'));
    expect(svg, contains('id="fluvi-arc-bottom"'));
    expect(svg, contains('offset="${_svgPercent(fill.boundary)}%"'));
    expect(RegExp(r'<path id="fluvi-arc-').allMatches(svg), hasLength(2));
  });
}

String _svgPercent(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\\.?0+$'), '');
}

Future<void> _pumpDashboard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final store = TransactionStore(
    _DashboardTestRepository(),
    clock: () => DateTime(2026, 7, 17),
  );
  await store.start();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SpendeeTestDashboard(
          store: store,
          expenseTheme: ExpenseTheme.fromSettings(AppThemeSettings.defaults()),
          onPickSummaryMonth: () {},
          onEditTransaction: (_) {},
          onDeleteTransactionRequested: (_) async => true,
          onVendorSheetRequested: () {},
          logBottomPadding: 0,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _dragHeaderBy(WidgetTester tester, double dy) async {
  final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await gesture.moveBy(Offset(0, dy));
  await tester.pump();
  await gesture.up();
}

class _DashboardTestRepository implements TransactionRepositoryContract {
  final categories = <TransactionCategory>[
    _category(1, 'Élelmiszer', 7, 0),
    _category(2, 'Közlekedés', 3, 1),
    _category(3, 'Lakás', 19, 2),
    _category(4, 'Gyorsétterem', 1, 3),
    _category(5, 'Rezsi', 18, 4),
  ];

  late final transactions = <TransactionRecord>[
    _record(1, 1, -63240, 'Élelmiszer bolt'),
    _record(2, 2, -31700, 'Busz'),
    _record(3, 3, -54000, 'Albérlet'),
    _record(4, 4, -28400, 'Burger'),
    _record(5, 5, -22600, 'Villany'),
  ];

  late final limits = <CategoryLimit>[
    _limit(1, LimitTargetType.overview, 0, 200000),
    _limit(2, LimitTargetType.category, 1, 80000),
    _limit(3, LimitTargetType.category, 2, 40000),
    _limit(4, LimitTargetType.category, 3, 30000),
    _limit(5, LimitTargetType.category, 4, 10000),
    _limit(6, LimitTargetType.category, 5, 10000),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    return TransactionBootstrap(
      categories: categories,
      transactions: transactions,
      limits: limits,
    );
  }

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    final rows = transactions.where((transaction) {
      if (query.type != null && transaction.type != query.type) return false;
      if (query.categoryId != null &&
          transaction.transactionCategoryID != query.categoryId) {
        return false;
      }
      return true;
    }).toList();
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
  ) async {
    return const <TransactionRecord>[];
  }

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) async => true;

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async {
    return 0;
  }

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async =>
      0;

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async {
    return const <RecurringGhostRecord>[];
  }

  @override
  Future<List<RecurringRule>> listRecurringRules() async {
    return const <RecurringRule>[];
  }

  @override
  Future<RecurringRule> addRecurringRule(RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> updateRecurringRule(int id, RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> toggleRecurringRule(int id, bool isActive) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteRecurringRule(int id) async => false;

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteCategory(int id) async => true;

  @override
  Future<Map<int, int>> categoryCounts() async {
    return {
      for (final category in categories) category.transactionCategoryID: 1,
    };
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async {
    return limits;
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) {
    throw UnimplementedError();
  }
}

CategoryLimit _limit(
  int id,
  LimitTargetType targetType,
  int targetId,
  double amount,
) {
  return CategoryLimit(
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
}

TransactionCategory _category(
  int id,
  String name,
  int colorSlot,
  int iconSlot,
) {
  return TransactionCategory.fromMap({
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
}

TransactionRecord _record(
  int id,
  int categoryId,
  double amount,
  String merchant,
) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': '2026.07.17',
    'time': '10:00',
    'merchant': merchant,
    'amount': amount,
    'userAssignedName': null,
    'transactionCategoryID': categoryId,
  });
}
