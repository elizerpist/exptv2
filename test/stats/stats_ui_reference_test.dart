import 'dart:async';

import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/features/stats/widgets/stats_year_calendar.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('year mode uses the accepted 200px two-column month cards', (
    tester,
  ) async {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: [
        _record(id: 1, date: '2026-01-01', amount: -8000, categoryId: 1),
      ],
      categories: [
        _category(1, 'Étel', const Color(0xFFEC4899)),
        _category(2, 'Utazás', AppColors.primary),
      ],
      selectedCategoryIds: const {1},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 650,
            child: StatsYearCalendar(data: data),
          ),
        ),
      ),
    );

    final january = find.byKey(const ValueKey('stats-month-card-1'));
    final february = find.byKey(const ValueKey('stats-month-card-2'));
    expect(january, findsOneWidget);
    expect(tester.getSize(january).height, 200);
    expect(tester.getTopLeft(january).dy, tester.getTopLeft(february).dy);
    expect(
      tester.getTopLeft(february).dx,
      greaterThan(tester.getTopLeft(january).dx),
    );
    expect(find.text('zárás'), findsNWidgets(12));
    expect(find.textContaining('kiadás Étel'), findsNWidgets(12));
  });

  testWidgets(
    'month heat color is common for ALL and scoped for one category',
    (tester) async {
      const scopedColor = Color(0xFFEC4899);
      final categories = [
        _category(1, 'Étel', scopedColor),
        _category(2, 'Utazás', AppColors.income),
      ];
      StatsYearData data(Set<int> selected) => StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.common,
        thresholdValue: 5000,
        transactions: [
          _record(id: 1, date: '2026-01-01', amount: -8000, categoryId: 1),
        ],
        categories: categories,
        selectedCategoryIds: selected,
      );

      Future<Color> pumpColor(StatsYearData value) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 350,
              height: 650,
              child: StatsYearCalendar(data: value),
            ),
          ),
        );
        return tester
            .widget<StatsMonthCard>(
              find.byKey(const ValueKey('stats-month-card-1')),
            )
            .heatColor;
      }

      expect(await pumpColor(data(const {})), AppColors.primary);
      expect(await pumpColor(data(const {1})), scopedColor);
    },
  );

  testWidgets(
    'one floating page indicator animates and stays above scrolling',
    (tester) async {
      final store = await _store(
        categories: [_category(1, 'Étel', AppColors.expense)],
        transactions: [
          _record(id: 1, date: '2026-01-01', amount: -8000, categoryId: 1),
        ],
      );

      await _pumpPage(tester, store);

      final header = find.byKey(const ValueKey('stats-page-header'));
      final indicatorTop = tester
          .getTopLeft(find.byKey(const ValueKey('stats-page-indicator')))
          .dy;
      expect(indicatorTop, greaterThanOrEqualTo(tester.getTopLeft(header).dy));
      expect(indicatorTop, lessThan(tester.getBottomLeft(header).dy));
      expect(
        tester
            .getRect(find.byKey(const ValueKey('stats-page-indicator')))
            .right,
        moreOrLessEquals(tester.getRect(header).right - 24, epsilon: 0.1),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('stats-page-indicator')),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(2),
      );

      final firstDot = find.byKey(const ValueKey('stats-page-indicator-dot-0'));
      final secondDot = find.byKey(
        const ValueKey('stats-page-indicator-dot-1'),
      );
      expect(tester.getSize(firstDot).width, 18);
      expect(tester.getSize(secondDot).width, 6);

      final beforeScrollTop = tester.getTopLeft(header).dy;
      final pageOneScroll = find.byKey(
        const ValueKey('stats-year-calendar-scroll'),
      );
      final pageOnePosition = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: pageOneScroll,
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      await tester.drag(pageOneScroll, const Offset(0, -180));
      await tester.pump(const Duration(milliseconds: 120));
      expect(pageOnePosition.pixels, greaterThan(0));
      expect(tester.getTopLeft(header).dy, beforeScrollTop);

      await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.getSize(firstDot).width, inExclusiveRange(6, 18));
      expect(tester.getSize(secondDot).width, inExclusiveRange(6, 18));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getSize(firstDot).width, 6);
      expect(tester.getSize(secondDot).width, 18);

      final pageTwoScroll = find.byKey(const ValueKey('stats-page-2-scroll'));
      final pageTwoPosition = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: pageTwoScroll,
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      await tester.drag(pageTwoScroll, const Offset(0, -180));
      await tester.pump(const Duration(milliseconds: 120));
      expect(pageTwoPosition.pixels, greaterThan(0));
      expect(tester.getTopLeft(header).dy, beforeScrollTop);
      expect(
        find.byKey(const ValueKey('stats-page-indicator')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('stats-page-2-boundary')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('stats-page-1-boundary')), findsNothing);
    },
  );

  testWidgets(
    'free-text search filters stats and selected scopes are capsules',
    (tester) async {
      final store = await _store(
        categories: [
          _category(1, 'Étel', AppColors.expense),
          _category(2, 'Utazás', AppColors.primary),
        ],
        transactions: [
          _record(
            id: 1,
            date: '2026-01-01',
            amount: -8000,
            categoryId: 1,
            merchant: 'Alma Bolt',
          ),
          _record(
            id: 2,
            date: '2026-01-02',
            amount: -9000,
            categoryId: 2,
            merchant: 'Körte Piac',
          ),
        ],
      );

      await _pumpPage(tester, store);
      await tester.enterText(find.byType(TextField).first, 'Alma');
      await tester.pump();

      expect(find.text('8 000 Ft'), findsAtLeastNWidgets(1));
      expect(find.text('17 000 Ft'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('header-category-button')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('category-card-1')));
      await tester.tap(
        find.byKey(const ValueKey('category-menu-apply-button')),
      );
      await _settle(tester);

      expect(
        find.byKey(const ValueKey('search-pill-capsule-category-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Page 2 places header dots KPI detail and 208px donut in content',
    (tester) async {
      final store = await _store(
        categories: [
          _category(1, 'Étel', AppColors.expense),
          _category(2, 'Utazás', AppColors.primary),
        ],
        transactions: [
          _record(
            id: 1,
            date: '2026-01-01',
            amount: -8000,
            categoryId: 1,
            merchant: 'Alma Bolt',
          ),
          _record(
            id: 2,
            date: '2026-01-02',
            amount: -9000,
            categoryId: 2,
            merchant: 'Körte Piac',
          ),
        ],
      );

      await _pumpPage(tester, store);
      await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
      await _settle(tester);

      expect(find.text('Aktuális szűrés · 2026'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('stats-page-indicator')),
        findsOneWidget,
      );
      expect(find.text('Körte Piac'), findsAtLeastNWidgets(1));
      final donut = find.byKey(const ValueKey('stats-category-donut'));
      expect(donut, findsOneWidget);
      expect(tester.getSize(donut), const Size.square(208));
    },
  );

  testWidgets('Page 2 single category omits donut and 100 percent label', (
    tester,
  ) async {
    final store = await _store(
      categories: [
        _category(1, 'Étel', AppColors.expense),
        _category(2, 'Utazás', AppColors.primary),
      ],
      transactions: [
        _record(id: 1, date: '2026-01-01', amount: -8000, categoryId: 1),
        _record(id: 2, date: '2026-01-02', amount: -9000, categoryId: 2),
      ],
    );
    await _pumpPage(tester, store);
    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('category-card-1')));
    await tester.tap(find.byKey(const ValueKey('category-menu-apply-button')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
    await _settle(tester);

    expect(find.text('Szűrt kategória'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-category-donut')), findsNothing);
    expect(find.textContaining('100%'), findsNothing);
  });

  testWidgets(
    'sum mode uses 154px two-column year cards with 70px month grid',
    (tester) async {
      final store = await _store(
        categories: [_category(1, 'Étel', AppColors.expense)],
        transactions: [
          _record(id: 1, date: '2025-01-01', amount: -8000, categoryId: 1),
          _record(id: 2, date: '2026-01-01', amount: -9000, categoryId: 1),
        ],
      );
      unawaited(store.setSummaryAllTime());

      await _pumpPage(tester, store);

      final card2025 = find.byKey(const ValueKey('stats-year-card-2025'));
      final card2026 = find.byKey(const ValueKey('stats-year-card-2026'));
      expect(tester.getSize(card2025).height, 154);
      expect(tester.getTopLeft(card2025).dy, tester.getTopLeft(card2026).dy);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('stats-year-month-grid-2026')))
            .height,
        70,
      );
      expect(find.text('zárás'), findsNWidgets(2));
      for (final card in [card2025, card2026]) {
        final container = tester.widget<Container>(
          find.descendant(of: card, matching: find.byType(Container)).first,
        );
        expect((container.decoration! as BoxDecoration).color, AppColors.white);
      }
      await expectLater(
        find.byKey(const ValueKey('stats-sum-year-cards')),
        matchesGoldenFile('goldens/stats_sum_year_cards.png'),
      );
    },
  );

  testWidgets('focused month reuses month card and omits extra charts', (
    tester,
  ) async {
    final store = await _store(
      categories: [_category(1, 'Étel', AppColors.expense)],
      transactions: [
        _record(id: 1, date: '2026-01-01', amount: -8000, categoryId: 1),
      ],
    );

    await _pumpPage(tester, store);
    await tester.tap(find.byKey(const ValueKey('stats-month-hit-1')));
    await _settle(tester);

    expect(
      find.byKey(const ValueKey('stats-focused-month-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('month-cashflow-chart')), findsNothing);
    expect(find.text('zárás'), findsOneWidget);
  });

  testWidgets('year Page 1 matches the reviewed visual baseline', (
    tester,
  ) async {
    final store = await _store(
      categories: [
        _category(1, 'Étel', AppColors.expense),
        _category(2, 'Utazás', AppColors.primary),
      ],
      transactions: [
        _record(id: 1, date: '2026-01-01', amount: 420000, categoryId: 1),
        _record(
          id: 2,
          date: '2026-01-02',
          amount: -8000,
          categoryId: 1,
          merchant: 'Alma Bolt',
        ),
        _record(
          id: 3,
          date: '2026-02-05',
          amount: -12000,
          categoryId: 2,
          merchant: 'BKK',
        ),
      ],
    );
    await _pumpPage(tester, store);

    await expectLater(
      find.byKey(const ValueKey('stats-page')),
      matchesGoldenFile('goldens/stats_year_page1.png'),
    );
  });

  testWidgets('Page 2 matches the reviewed visual baseline', (tester) async {
    final store = await _store(
      categories: [
        _category(1, 'Étel', AppColors.expense),
        _category(2, 'Utazás', AppColors.primary),
      ],
      transactions: [
        _record(
          id: 1,
          date: '2026-01-01',
          amount: -8000,
          categoryId: 1,
          merchant: 'Alma Bolt',
        ),
        _record(
          id: 2,
          date: '2026-02-05',
          amount: -12000,
          categoryId: 2,
          merchant: 'BKK',
        ),
      ],
    );
    await _pumpPage(tester, store);
    await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byKey(const ValueKey('stats-page')),
      matchesGoldenFile('goldens/stats_page2.png'),
    );
  });
}

Future<TransactionStore> _store({
  required List<TransactionCategory> categories,
  required List<TransactionRecord> transactions,
}) async {
  final store = TransactionStore(
    _StatsRepository(categories: categories, transactions: transactions),
    clock: () => DateTime(2026, 7, 7),
  );
  await store.start();
  unawaited(store.setSummaryYear(2026));
  return store;
}

Future<void> _pumpPage(WidgetTester tester, TransactionStore store) async {
  tester.view.physicalSize = const Size(390, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 390, height: 780, child: StatsPage(store: store)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

TransactionCategory _category(int id, String name, Color color) {
  return TransactionCategory(
    transactionCategoryID: id,
    name: name,
    type: 'expense',
    colorSlot: null,
    iconSlot: null,
    backgroundColor:
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
}

TransactionRecord _record({
  required int id,
  required String date,
  required double amount,
  required int categoryId,
  String merchant = 'Teszt',
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '12:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: merchant,
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
  );
}

class _StatsRepository extends TransactionRepositoryContract {
  _StatsRepository({required this.categories, required this.transactions});

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
  ) async => TransactionPage(
    transactions: transactions,
    totalCount: transactions.length,
    limit: query.limit,
    offset: query.offset,
  );

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
