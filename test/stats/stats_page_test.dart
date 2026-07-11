import 'dart:async';

import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/stats/data/stats_snapshot.dart';
import 'package:exptv2/features/stats/data/stats_render_frame.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/features/stats/widgets/stats_fast_info_graph.dart';
import 'package:exptv2/features/stats/widgets/stats_year_calendar.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_menu_panel.dart';
import 'package:exptv2/features/transactions/widgets/header_card/magnet_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStatsSnapshotRepository snapshotRepository;

  setUp(() {
    snapshotRepository = InMemoryStatsSnapshotRepository();
  });

  testWidgets('stats annual calendar renders 12 month hit targets', (
    tester,
  ) async {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
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

  testWidgets('stats annual calendar accepts themed month card background', (
    tester,
  ) async {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
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
            child: StatsYearCalendar(
              data: data,
              monthCardColor: AppColors.gray200,
              onMonthSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final calendar = tester.widget<StatsYearCalendar>(
      find.byType(StatsYearCalendar),
    );
    expect(calendar.monthCardColor, AppColors.gray200);
  });

  testWidgets('stats FastInfo graph is a graph-only surface', (tester) async {
    StatsYearData data(StatsRenderMode mode) {
      return StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: mode,
        thresholdValue: 5000,
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-02-01', amount: -9000, categoryId: 1),
        ],
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
        ],
        selectedCategoryIds: const {},
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 328,
            child: StatsFastInfoGraph(data: data(StatsRenderMode.common)),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('stats-fastinfo-graph')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-fastinfo-common')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-fastinfo-card')), findsNothing);
    expect(find.byKey(const ValueKey('stats-fastinfo-pill')), findsNothing);
  });

  test(
    'stats FastInfo layout starts below the status bar and keeps bottom',
    () {
      final layout = StatsFastInfoGraph.layoutForTesting(const Size(390, 328));

      expect(layout.topTitleTop, greaterThanOrEqualTo(42));
      expect(layout.topChart.top, greaterThanOrEqualTo(62));
      expect(layout.bottomChart.bottom, moreOrLessEquals(302, epsilon: 0.01));
      expect(layout.bottomChart.height, greaterThanOrEqualTo(52));
    },
  );

  test('category scope FastInfo layout matches accepted HTML geometry', () {
    final expense = StatsFastInfoGraph.layoutForTesting(
      const Size(412, 328),
      categoryActiveType: TransactionType.expense,
    );
    final income = StatsFastInfoGraph.layoutForTesting(
      const Size(412, 328),
      categoryActiveType: TransactionType.income,
    );

    expect(expense.categoryPanel, const Rect.fromLTWH(14, 42, 384, 268));
    expect(expense.categoryTitleOffset, const Offset(47, 64));
    expect(expense.categoryLegendY, 81);
    expect(
      expense.categoryControlChart,
      const Rect.fromLTWH(47, 104, 337, 126),
    );
    expect(
      expense.categorySecondaryChart,
      const Rect.fromLTWH(47, 264, 337, 26),
    );

    expect(income.categoryPanel, const Rect.fromLTWH(14, 42, 384, 268));
    expect(income.categoryTitleOffset, const Offset(47, 57));
    expect(income.categoryLegendY, 69);
    expect(income.categoryControlChart, const Rect.fromLTWH(47, 92, 337, 118));
    expect(
      income.categorySecondaryChart,
      const Rect.fromLTWH(47, 248, 337, 42),
    );
  });

  test(
    'category scope FastInfo visual style matches the unified chart brief',
    () {
      final style = StatsFastInfoGraph.visualStyleForTesting();

      expect(style.legendFontSize, moreOrLessEquals(12.4, epsilon: 0.01));
      expect(style.legendMarkerWidth, moreOrLessEquals(10.5, epsilon: 0.01));
      expect(style.legendMarkerHeight, moreOrLessEquals(5.2, epsilon: 0.01));
      expect(style.secondaryLineSmoothingEnabled, isTrue);
      expect(style.secondaryLineDashed, isFalse);
      expect(style.controlVisualSensitivity, moreOrLessEquals(1.0));
      expect(
        StatsFastInfoGraph.visualControlValueForTesting(60),
        moreOrLessEquals(60),
      );
      expect(style.categoryYAxisValueLabelCount, greaterThanOrEqualTo(2));
    },
  );

  test('stats FastInfo chart metadata defines legends and axes per mode', () {
    for (final mode in StatsRenderMode.values) {
      final spec = StatsFastInfoGraph.specForTesting(mode);

      expect(spec.charts, isNotEmpty, reason: mode.name);
      for (final chart in spec.charts) {
        expect(chart.legendLabels, isNotEmpty, reason: chart.title);
        expect(chart.xAxisLabel, isNotEmpty, reason: chart.title);
        expect(chart.yAxisLabel, isNotEmpty, reason: chart.title);
      }
    }
  });

  test('category scope FastInfo metadata exposes the unified chart', () {
    final spec = StatsFastInfoGraph.specForTesting(StatsRenderMode.common);

    expect(spec.charts, hasLength(2));
    expect(spec.charts[0].title, '1. Szűrés pontszám');
    expect(spec.charts[0].yAxisLabel, 'pontszám');
    expect(spec.charts[0].xAxisLabel, 'hónapok');
    expect(spec.charts[0].legendLabels, ['rossz', 'semleges 50', 'jó']);
    expect(spec.charts[1].title, '2. Küszöb feletti többlet');
    expect(spec.charts[1].legendLabels, ['küszöb']);
  });

  testWidgets('stats scope sheet toggles multiple active-type categories', (
    tester,
  ) async {
    Set<int>? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            key: const ValueKey('stats-scope-sheet'),
            activeType: TransactionType.expense,
            categories: [
              category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
              category(id: 2, name: 'Ruha', type: TransactionType.expense),
              category(id: 4, name: 'Bolt', type: TransactionType.expense),
              category(id: 3, name: 'Fizetés', type: TransactionType.income),
            ],
            categoryTransactionCounts: const {},
            activeCategory: null,
            selectedCategoryIds: const {},
            onSelect: (_) {},
            onApply: (ids) => applied = ids,
            onModify: (_) {},
            onDelete: (_) {},
            onAdd: () {},
            onClose: () {},
            accentColor: const Color(0xFF06B6D4),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('stats-scope-sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-menu-all-card')),
      findsOneWidget,
    );
    expect(find.text('Minden kategória'), findsOneWidget);
    expect(find.text('Gyorskaja'), findsOneWidget);
    expect(find.text('Ruha'), findsOneWidget);
    expect(find.text('Bolt'), findsOneWidget);
    expect(find.text('Fizetés'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('category-card-1')));
    await tester.tap(find.byKey(const ValueKey('category-card-2')));
    await tester.pump();
    expect(find.byKey(const ValueKey('stats-scope-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('category-menu-apply-button')));
    expect(applied, {1, 2});
  });

  testWidgets('stats scope sheet normalizes all selected categories to ALL', (
    tester,
  ) async {
    Set<int>? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            key: const ValueKey('stats-scope-sheet'),
            activeType: TransactionType.expense,
            categories: [
              category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
              category(id: 2, name: 'Ruha', type: TransactionType.expense),
            ],
            categoryTransactionCounts: const {},
            activeCategory: null,
            selectedCategoryIds: const {},
            onSelect: (_) {},
            onApply: (ids) => applied = ids,
            onModify: (_) {},
            onDelete: (_) {},
            onAdd: () {},
            onClose: () {},
            accentColor: const Color(0xFF06B6D4),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('category-card-1')));
    await tester.tap(find.byKey(const ValueKey('category-card-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('category-menu-apply-button')));

    expect(applied, isEmpty);
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
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-page')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-menu-overlay')), findsNothing);
    expect(find.byType(CalendarMenuOverlay), findsNothing);
    expect(
      find.byKey(const ValueKey('transaction-header-card')),
      findsOneWidget,
    );
    expect(find.text('SZŰRÉS PONTSZÁM'), findsOneWidget);
    expect(find.text('MIND'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-magnet-common')), findsOneWidget);
    expect(find.byKey(const ValueKey('summary-pill')), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-year-calendar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-threshold-joystick-trigger')),
      findsNothing,
    );
  });

  testWidgets('stats page follows and updates the shared summary period', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2025-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-01', amount: -7000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryAllTime());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              snapshotRepository: snapshotRepository,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    expect(find.text('Sum'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-sum-year-cards')), findsOneWidget);

    expect(find.byKey(const ValueKey('stats-year-card-2025')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('stats-year-card-2025')),
    );
    await pumpStatsPage(tester);
    final yearCard = tester.getRect(
      find.byKey(const ValueKey('stats-year-card-2025')),
    );
    await tester.tapAt(yearCard.topLeft + const Offset(20, 20));
    await pumpStatsPage(tester);

    expect(store.summaryWindow, SummaryWindow.yearly);
    expect(store.summaryReferenceDate.year, 2025);
    expect(find.text('2025'), findsOneWidget);
  });

  testWidgets('stats period label exactly mirrors the main menu period label', (
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
    unawaited(store.setSummaryAllTime());

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
    await pumpStatsPage(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-pill')),
        matching: find.text('Sum'),
      ),
      findsOneWidget,
    );

    unawaited(store.setSummaryYear(2026));
    await pumpStatsPage(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-pill')),
        matching: find.text('2026'),
      ),
      findsOneWidget,
    );
    expect(find.text('Éves · 2026 · Kiadás'), findsNothing);

    unawaited(store.setSummaryMonth(2026, 1));
    await pumpStatsPage(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-pill')),
        matching: find.text('Január 2026'),
      ),
      findsOneWidget,
    );
    expect(find.text('Január 2026 · Kiadás'), findsNothing);
  });

  testWidgets('all year-card regions open year then a month card opens month', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2025-01-12', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-12', amount: -7000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryAllTime());

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
    await pumpStatsPage(tester);

    await tester.tap(
      find.byKey(const ValueKey('stats-year-month-cell-2025-1')),
    );
    await pumpStatsPage(tester);

    expect(store.activePeriodLabel, '2025');
    expect(find.byKey(const ValueKey('stats-year-calendar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-focus-month-view')),
      findsNothing,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('stats-month-hit-1')));
    await pumpStatsPage(tester);
    await tester.tap(find.byKey(const ValueKey('stats-month-hit-1')));
    await pumpStatsPage(tester);

    expect(store.activePeriodLabel, 'Január 2025');
    expect(
      find.byKey(const ValueKey('calendar-focus-month-view')),
      findsOneWidget,
    );
  });

  testWidgets('stats floating header matches main menu count geometry', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-02', amount: -9000, categoryId: 1),
          record(id: 3, date: '2026-01-03', amount: -1000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    final header = find.byKey(const ValueKey('stats-page-header'));
    final count = find.byKey(const ValueKey('stats-page-header-count'));
    expect(tester.getSize(header), const Size(390, 28));
    expect(find.text('2 tranzakció'), findsOneWidget);
    final countText = tester.widget<Text>(count);
    expect(countText.style?.fontSize, 12);
    expect(countText.style?.fontWeight, FontWeight.w700);
    expect(countText.style?.color, AppColors.gray500);
    expect(
      tester.getTopLeft(count).dy,
      moreOrLessEquals(tester.getTopLeft(header).dy + 4, epsilon: 1),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('stats-content-switcher')))
          .dy,
      tester.getBottomLeft(header).dy,
    );
  });

  testWidgets('content swipe recalls snapshot but never opens Page 2', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
          category(id: 2, name: 'Fizetés', type: TransactionType.income),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-02', amount: 300000, categoryId: 2),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));
    final now = DateTime(2026, 7, 11);
    final repository = InMemoryStatsSnapshotRepository([
      StatsSnapshot(
        id: 'income-page-two',
        name: 'Bevétel snapshot',
        createdAt: now,
        updatedAt: now,
        includeCategoryScope: false,
        includeVendorScope: false,
        includeActiveType: true,
        includeThreshold: false,
        includeLayoutMode: false,
        includePageIndex: true,
        activeType: TransactionType.income,
        pageIndex: 1,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(store: store, snapshotRepository: repository),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    await tester.drag(
      find.byKey(const ValueKey('stats-content-gesture-surface')),
      const Offset(-260, 0),
    );
    await pumpStatsPage(tester);

    expect(find.text('Bevétel'), findsNWidgets(1));
    expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-page-2')), findsNothing);
  });

  testWidgets('empty snapshot swipe is a safe page-one no-op', (tester) async {
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
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    await tester.drag(
      find.byKey(const ValueKey('stats-content-gesture-surface')),
      const Offset(-260, 0),
    );
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-page-2')), findsNothing);
  });

  testWidgets('right-edge chevron opens and closes Page 2 with bounded slide', (
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
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    final switcherRect = tester.getRect(
      find.byKey(const ValueKey('stats-content-switcher')),
    );
    final chevronRect = tester.getRect(
      find.byKey(const ValueKey('stats-page-chevron')),
    );
    expect(chevronRect.right, switcherRect.right);
    expect(
      chevronRect.center.dy,
      moreOrLessEquals(switcherRect.center.dy, epsilon: 1),
    );

    await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final pageTwoMidX = tester
        .getTopLeft(find.byKey(const ValueKey('stats-page-2-boundary')))
        .dx;
    expect(pageTwoMidX, greaterThan(0));
    expect(pageTwoMidX, lessThan(390));
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('stats-page-2-boundary'))).dx,
      moreOrLessEquals(0, epsilon: 0.1),
    );

    await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final pageTwoCloseMidX = tester
        .getTopLeft(find.byKey(const ValueKey('stats-page-2-boundary')))
        .dx;
    expect(pageTwoCloseMidX, greaterThan(0));
    expect(pageTwoCloseMidX, lessThan(390));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-page-2')), findsNothing);
  });

  testWidgets(
    'stats page puts SearchPill and header above the Page 1 Page 2 switcher',
    (tester) async {
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
      unawaited(store.setSummaryYear(2026));

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
      await pumpStatsPage(tester);

      expect(
        find.byKey(const ValueKey('search-pill-container')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('stats-content-switcher')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('stats-page-2')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
      await pumpStatsPage(tester);

      expect(find.byKey(const ValueKey('stats-page-2')), findsOneWidget);
    },
  );

  testWidgets('stats page reuses one frame for page change and FAB sheet', (
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
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();
    final cache = TrackingStatsRenderFrameCache();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              controller: controller,
              snapshotRepository: snapshotRepository,
              renderFrameCache: cache,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
    expect(cache.builderCalls, 1);
    final initialFrame = cache.resolvedFrames.first;

    await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
    await pumpStatsPage(tester);
    expect(find.byKey(const ValueKey('stats-page-2')), findsOneWidget);

    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    expect(find.byKey(const ValueKey('stats-threshold-sheet')), findsOneWidget);
    expect(cache.builderCalls, 1);
    expect(cache.resolvedFrames, isNotEmpty);
    expect(cache.resolvedFrames, everyElement(same(initialFrame)));
  });

  testWidgets('stats SearchPill vendor button delegates to shell callback', (
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
    unawaited(store.setSummaryYear(2026));
    TransactionType? openedForType;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              onVendorSheetRequested: (type) => openedForType = type,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pump();

    expect(openedForType, TransactionType.expense);

    await tester.tap(find.text('Bevétel').first);
    await pumpStatsPage(tester);
    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pump();
    expect(openedForType, TransactionType.income);
  });

  testWidgets('stats Page 2 renders category ranking and Top 5 vendors', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-02', amount: -9000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
    await pumpStatsPage(tester);

    expect(find.text('Kategória rangsor'), findsOneWidget);
    expect(find.text('Top 5 kereskedő · 1 / 1'), findsOneWidget);
    expect(find.text('Gyorskaja'), findsAtLeastNWidgets(1));
    expect(find.text('Teszt'), findsAtLeastNWidgets(2));
  });

  testWidgets('stats sum mode renders year cards and year tap focuses year', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2024-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2025-01-01', amount: -7000, categoryId: 1),
          record(id: 3, date: '2026-01-01', amount: -8000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, -90),
    );
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-sum-year-cards')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('stats-sum-year-cards')),
      const Offset(0, -120),
    );
    await pumpStatsPage(tester);
    expect(find.byKey(const ValueKey('stats-year-card-2025')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('stats-year-card-2025')),
    );
    await pumpStatsPage(tester);
    final yearCard = tester.getRect(
      find.byKey(const ValueKey('stats-year-card-2025')),
    );
    await tester.tapAt(yearCard.topLeft + const Offset(20, 20));
    await pumpStatsPage(tester);

    expect(find.text('2025'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-year-calendar')), findsOneWidget);
  });

  testWidgets('stats header uses main menu chip color and line magnet marker', (
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
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    final strip = tester.widget<MagnetStrip>(find.byType(MagnetStrip));
    expect(strip.customMarkerStyle, MagnetMarkerStyle.line);
    expect(strip.customMarkerPosition, moreOrLessEquals(0));

    final chip = tester.widget<Container>(
      find.byKey(const ValueKey('header-scope-chip')),
    );
    final decoration = chip.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFBBF24));
  });

  testWidgets('stats income header follows endpoint income health score', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Fizetés', type: TransactionType.income),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: 300000, categoryId: 1),
          record(id: 2, date: '2026-02-01', amount: 75000, categoryId: 1),
          record(id: 3, date: '2026-02-02', amount: 75000, categoryId: 1),
          record(id: 4, date: '2026-02-03', amount: 75000, categoryId: 1),
          record(id: 5, date: '2026-02-04', amount: 75000, categoryId: 1),
          record(id: 6, date: '2026-03-01', amount: 400000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    await tester.tap(find.text('Bevétel').first);
    await pumpStatsPage(tester);

    expect(find.text('SZŰRÉS PONTSZÁM'), findsOneWidget);
    expect(find.text('62/100'), findsOneWidget);

    final strip = tester.widget<MagnetStrip>(find.byType(MagnetStrip));
    expect(strip.customMarkerStyle, MagnetMarkerStyle.line);
    expect(strip.customMarkerPosition, moreOrLessEquals(0.6167, epsilon: 0.01));
  });

  testWidgets('stats custom magnet is not overridden by ambulance theme', (
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
    unawaited(store.setSummaryYear(2026));

    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        magnetType: MagnetType.ambulanceSkin,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-magnet-common')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('magnet-strip-ambulanceSkin')),
      findsNothing,
    );
  });

  testWidgets('stats page passes theme month card color into annual calendar', (
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
    unawaited(store.setSummaryYear(2026));

    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        statsMonthCardColor: AppBoxColor.darkgray,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    final calendar = tester.widget<StatsYearCalendar>(
      find.byType(StatsYearCalendar),
    );
    expect(calendar.monthCardColor, AppColors.gray200);
  });

  testWidgets('stats threshold sheet has no render mode selector', (
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
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              controller: controller,
              snapshotRepository: snapshotRepository,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    controller.openThresholdSheet();
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-threshold-sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stats-render-mode-selector')),
      findsNothing,
    );
    expect(find.text('Kategória scope'), findsNothing);
    expect(find.text('Hózárás'), findsNothing);
    expect(find.text('Hőtérkép'), findsNothing);
    expect(
      find.byKey(const ValueKey('stats-threshold-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stats-threshold-amount-input')),
      findsOneWidget,
    );
    expect(find.text('5 000 Ft'), findsAtLeastNWidgets(1));

    await tester.enterText(
      find.byKey(const ValueKey('stats-threshold-amount-input')),
      '12000',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpStatsPage(tester);
    expect(find.byKey(const ValueKey('stats-threshold-sheet')), findsOneWidget);
    expect(find.text('10 000 Ft'), findsAtLeastNWidgets(1));
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('stats-threshold-amount-input')),
          )
          .controller!
          .text,
      '10000',
    );
  });

  testWidgets('stats threshold clamps to the active type daily range', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
          category(id: 2, name: 'Fizetés', type: TransactionType.income),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -150000, categoryId: 1),
          record(id: 2, date: '2026-01-01', amount: 20000, categoryId: 2),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              controller: controller,
              snapshotRepository: snapshotRepository,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    await tester.enterText(
      find.byKey(const ValueKey('stats-threshold-amount-input')),
      '120000',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpStatsPage(tester);
    await tester.tapAt(const Offset(20, 20));
    await pumpStatsPage(tester);

    await tester.tap(find.text('Bevétel').first);
    await pumpStatsPage(tester);
    controller.openThresholdSheet();
    await pumpStatsPage(tester);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('stats-threshold-slider')),
    );
    expect(slider.max, 50000);
    expect(slider.value, 50000);
  });

  testWidgets('stats controller applies accelerated joystick threshold steps', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -150000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              controller: controller,
              snapshotRepository: snapshotRepository,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    controller.stepThreshold(6);
    await pumpStatsPage(tester);
    controller.openThresholdSheet();
    await pumpStatsPage(tester);

    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('stats-threshold-slider')))
          .value,
      35000,
    );
  });

  testWidgets('stats threshold sheet includes snapshot add dialog', (
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
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              controller: controller,
              snapshotRepository: snapshotRepository,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    controller.openThresholdSheet();
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-snapshot-row')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stats-snapshot-add-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('stats-snapshot-add-card')));
    await pumpStatsPage(tester);

    expect(find.byKey(const ValueKey('stats-snapshot-dialog')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stats-snapshot-name-input')),
      findsOneWidget,
    );
    expect(find.text('Kategória szűrés'), findsOneWidget);
    expect(find.text('Kereskedő szűrés'), findsOneWidget);
    expect(find.text('Nézet mód'), findsOneWidget);
  });

  testWidgets('stats snapshot save creates a recallable card', (tester) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
          category(id: 2, name: 'Fizetés', type: TransactionType.income),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-01', amount: 300000, categoryId: 2),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: StatsPage(
              store: store,
              controller: controller,
              snapshotRepository: snapshotRepository,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);

    await tester.tap(find.text('Bevétel').first);
    await pumpStatsPage(tester);
    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    await tester.enterText(
      find.byKey(const ValueKey('stats-threshold-amount-input')),
      '20000',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpStatsPage(tester);
    await tester.tap(find.byKey(const ValueKey('stats-snapshot-add-card')));
    await pumpStatsPage(tester);
    await tester.enterText(
      find.byKey(const ValueKey('stats-snapshot-name-input')),
      'Bevétel mentés',
    );
    await tester.tap(find.byKey(const ValueKey('stats-snapshot-save-button')));
    await pumpStatsPage(tester);

    expect(find.text('Bevétel mentés'), findsOneWidget);
    expect(await snapshotRepository.load(), hasLength(1));

    await tester.tapAt(const Offset(20, 20));
    await pumpStatsPage(tester);
    await tester.tap(find.text('Kiadás').first);
    await pumpStatsPage(tester);
    expect(find.text('2026'), findsOneWidget);

    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    await tester.enterText(
      find.byKey(const ValueKey('stats-threshold-amount-input')),
      '5000',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpStatsPage(tester);
    await tester.tap(find.text('Bevétel mentés'));
    await pumpStatsPage(tester);

    expect(find.text('2026'), findsOneWidget);
    expect(find.text('20 000 Ft'), findsAtLeastNWidgets(1));
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('stats-threshold-amount-input')),
          )
          .controller!
          .text,
      '20000',
    );
  });

  testWidgets(
    'active-type-only snapshot preserves the target type category scope',
    (tester) async {
      final store = TransactionStore(
        StatsRepository(
          categories: [
            category(id: 1, name: 'Bolt', type: TransactionType.expense),
            category(id: 2, name: 'Fizetés', type: TransactionType.income),
            category(id: 3, name: 'Bónusz', type: TransactionType.income),
          ],
          transactions: [
            record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
            record(id: 2, date: '2026-01-01', amount: 300000, categoryId: 2),
            record(id: 3, date: '2026-01-02', amount: 50000, categoryId: 3),
          ],
        ),
        clock: () => DateTime(2026, 7, 7),
      );
      await store.start();
      unawaited(store.setSummaryYear(2026));
      final controller = StatsPageController();
      final now = DateTime(2026, 7, 11, 12);
      final repository = InMemoryStatsSnapshotRepository([
        StatsSnapshot(
          id: 'income-only',
          name: 'Bevétel oldal',
          createdAt: now,
          updatedAt: now,
          includeCategoryScope: false,
          includeVendorScope: false,
          includeActiveType: true,
          includeThreshold: false,
          includeLayoutMode: false,
          includePageIndex: false,
          activeType: TransactionType.income,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: StatsPage(
                store: store,
                controller: controller,
                snapshotRepository: repository,
              ),
            ),
          ),
        ),
      );
      await pumpStatsPage(tester);

      await tester.tap(find.text('Bevétel').first);
      await pumpStatsPage(tester);
      await tester.tap(find.byKey(const ValueKey('header-category-button')));
      await pumpStatsPage(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('category-card-2')));
      await pumpStatsPage(tester);
      await tester.tap(find.byKey(const ValueKey('category-card-2')));
      await tester.tap(
        find.byKey(const ValueKey('category-menu-apply-button')),
      );
      await pumpStatsPage(tester);
      expect(
        find.byKey(const ValueKey('search-pill-capsule-category-2')),
        findsOneWidget,
      );

      await tester.tap(find.text('Kiadás').first);
      await pumpStatsPage(tester);
      controller.openThresholdSheet();
      await pumpStatsPage(tester);
      await tester.tap(find.text('Bevétel oldal'));
      await pumpStatsPage(tester);

      expect(find.text('2026'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('search-pill-capsule-category-2')),
        findsOneWidget,
      );
    },
  );

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
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await pumpStatsPage(tester);
    expect(find.byKey(const ValueKey('stats-scope-sheet')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('category-card-1')));
    await pumpStatsPage(tester);
    await tester.tap(find.byKey(const ValueKey('category-card-1')));
    await tester.tap(find.byKey(const ValueKey('category-menu-apply-button')));
    await pumpStatsPage(tester);

    expect(find.textContaining('Gyorskaja'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('search-pill-capsule-category-1')),
      findsOneWidget,
    );
    expect(find.text('SZŰRÉS PONTSZÁM'), findsOneWidget);
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
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('transaction-header-card'))),
    );
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();

    expect(find.byKey(const ValueKey('stats-fastinfo-graph')), findsOneWidget);
    await gesture.up();
  });

  testWidgets(
    'stats month card tap opens focused month view and back returns',
    (tester) async {
      tester.view.physicalSize = const Size(390, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TransactionStore(
        StatsRepository(
          categories: [
            category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
          ],
          transactions: [
            record(id: 1, date: '2026-01-12', amount: -6000, categoryId: 1),
          ],
        ),
        clock: () => DateTime(2026, 7, 7),
      );
      await store.start();
      unawaited(store.setSummaryYear(2026));

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
      await pumpStatsPage(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey('stats-month-hit-1')),
      );
      await pumpStatsPage(tester);
      await tester.tap(find.byKey(const ValueKey('stats-month-hit-1')));
      await pumpStatsPage(tester);

      expect(
        find.byKey(const ValueKey('calendar-focus-month-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('calendar-focus-month-canvas')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('calendar-focus-back')), findsOneWidget);
      expect(find.byKey(const ValueKey('stats-year-calendar')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('calendar-focus-back')));
      await pumpStatsPage(tester);

      expect(
        find.byKey(const ValueKey('calendar-focus-month-view')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('stats-year-calendar')), findsOneWidget);
    },
  );

  testWidgets('stats header pull keeps FastInfo graph stable between frames', (
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
    unawaited(store.setSummaryYear(2026));

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
    await pumpStatsPage(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('transaction-header-card'))),
    );
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    final firstGraph = tester.widget<StatsFastInfoGraph>(
      find.byType(StatsFastInfoGraph),
    );

    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    final secondGraph = tester.widget<StatsFastInfoGraph>(
      find.byType(StatsFastInfoGraph),
    );

    expect(identical(firstGraph, secondGraph), isTrue);
    await gesture.up();
  });
}

Future<void> pumpStatsPage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 240));
  await tester.pump(const Duration(milliseconds: 240));
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

class TrackingStatsRenderFrameCache extends StatsRenderFrameCache {
  int builderCalls = 0;
  final resolvedFrames = <StatsRenderFrame>[];

  @override
  StatsRenderFrame resolve(
    StatsRenderFrameKey key,
    StatsRenderFrame Function() builder,
  ) {
    final frame = super.resolve(key, () {
      builderCalls += 1;
      return builder();
    });
    resolvedFrames.add(frame);
    return frame;
  }
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
