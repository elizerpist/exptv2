import 'dart:async';
import 'dart:typed_data';

import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/stats/data/stats_snapshot.dart';
import 'package:exptv2/features/stats/data/stats_render_frame.dart';
import 'package:exptv2/features/stats/data/stats_render_frame_worker.dart';
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
import 'package:exptv2/features/transactions/widgets/search_pill.dart';
import 'package:exptv2/features/transactions/widgets/transaction_type_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryStatsSnapshotRepository snapshotRepository;

  setUp(() {
    snapshotRepository = InMemoryStatsSnapshotRepository();
    StatsPage.debugRenderFrameWorkerOverride =
        const ImmediateStatsFrameWorker();
  });

  tearDown(() => StatsPage.debugRenderFrameWorkerOverride = null);

  test('clamp-aware frame preserves score parity at the same threshold', () {
    final categories = [
      category(id: 1, name: 'Expense', type: TransactionType.expense),
    ];
    final transactions = [
      record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
      record(id: 2, date: '2026-01-02', amount: -9000, categoryId: 1),
    ];
    final normal = StatsRenderFrame.build(
      year: 2026,
      activeType: TransactionType.expense,
      thresholdValue: 5000,
      transactions: transactions,
      categories: categories,
      selectedCategoryIds: const {},
    );
    final clampAware = StatsRenderFrame.build(
      year: 2026,
      activeType: TransactionType.expense,
      thresholdValue: 100000,
      transactions: transactions,
      categories: categories,
      selectedCategoryIds: const {},
      thresholdResolver: (_, _) => normal.yearData.thresholdValue,
    );

    expect(clampAware.yearData.thresholdValue, normal.yearData.thresholdValue);
    expect(clampAware.yearData.summaryTotal, normal.yearData.summaryTotal);
    expect(
      clampAware.yearData.scorePeriodAmounts,
      normal.yearData.scorePeriodAmounts,
    );
    expect(
      clampAware.categoryScopeSeries.kontrollScore,
      normal.categoryScopeSeries.kontrollScore,
    );
    expect(
      clampAware.filteredTransactionCount,
      normal.filteredTransactionCount,
    );
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
      expect(style.surfaceShadowOffset, const Offset(0, 2));
      expect(style.surfaceShadowBlurRadius, 4);
      expect(style.surfaceShadowColor.r, 0);
      expect(style.surfaceShadowColor.g, 0);
      expect(style.surfaceShadowColor.b, 0);
      expect(
        style.surfaceShadowColor.a,
        moreOrLessEquals(0.08, epsilon: 0.001),
      );
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

  testWidgets(
    'left and right content swipes cycle snapshots without page navigation',
    (tester) async {
      final store = TransactionStore(
        StatsRepository(
          categories: [
            category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
            category(id: 2, name: 'Fizetés', type: TransactionType.income),
          ],
          transactions: [
            record(id: 0, date: '2025-01-01', amount: -5000, categoryId: 1),
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
          id: 'year-page-two',
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
        StatsSnapshot(
          id: 'month-page-two',
          name: 'Kiadás snapshot',
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now.add(const Duration(seconds: 1)),
          includeCategoryScope: false,
          includeVendorScope: false,
          includeActiveType: true,
          includeThreshold: false,
          includeLayoutMode: false,
          includePageIndex: true,
          activeType: TransactionType.expense,
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

      await tester.fling(
        find.byKey(const ValueKey('stats-content-gesture-surface')),
        const Offset(-260, 0),
        1200,
      );
      await pumpStatsPage(tester);

      expect(
        tester
            .widget<StatsYearCalendar>(find.byType(StatsYearCalendar))
            .data
            .activeType,
        TransactionType.income,
      );
      expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('stats-page-2')), findsNothing);

      await tester.fling(
        find.byKey(const ValueKey('stats-content-gesture-surface')),
        const Offset(260, 0),
        1200,
      );
      await pumpStatsPage(tester);

      expect(
        tester
            .widget<StatsYearCalendar>(find.byType(StatsYearCalendar))
            .data
            .activeType,
        TransactionType.expense,
      );
      expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('stats-page-2')), findsNothing);
    },
  );

  testWidgets('snapshot sheet card cannot navigate to its stored Page 2', (
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
    final now = DateTime(2026, 7, 11);
    final repository = InMemoryStatsSnapshotRepository([
      StatsSnapshot(
        id: 'stored-page-two',
        name: 'Második oldal',
        createdAt: now,
        updatedAt: now,
        includeCategoryScope: false,
        includeVendorScope: false,
        includeActiveType: false,
        includeThreshold: false,
        includeLayoutMode: false,
        includePageIndex: true,
        pageIndex: 1,
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

    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    await tester.tap(
      find.byKey(const ValueKey('stats-snapshot-card-stored-page-two')),
    );
    await pumpStatsPage(tester);

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

  testWidgets(
    'high-volume type switch schedules one internally consistent final frame',
    (tester) async {
      final categories = [
        category(id: 1, name: 'Expense', type: TransactionType.expense),
        category(id: 2, name: 'Income', type: TransactionType.income),
      ];
      final transactions = List<TransactionRecord>.generate(6000, (index) {
        final income = index.isEven;
        final month = (index % 12) + 1;
        final day = (index % 28) + 1;
        return record(
          id: 100000 + index,
          date:
              '2026-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          amount: income ? 1000 + index.toDouble() : -(1000 + index.toDouble()),
          categoryId: income ? 2 : 1,
        );
      });
      final store = TransactionStore(
        StatsRepository(categories: categories, transactions: transactions),
        clock: () => DateTime(2026, 7, 7),
      );
      await store.start();
      unawaited(store.setSummaryYear(2026));
      await tester.pump(const Duration(milliseconds: 1));
      final cache = TrackingStatsRenderFrameCache();
      final worker = ControlledStatsFrameWorker();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: StatsPage(
                store: store,
                snapshotRepository: snapshotRepository,
                renderFrameCache: cache,
                renderFrameWorker: worker,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(worker.requests, hasLength(1));
      worker.complete(0);
      await tester.pump();
      await tester.pump();
      final buildsBeforeTap = cache.builderCalls;
      final incomePill = find.byKey(
        const ValueKey('transaction-type-pill-income-surface'),
      );
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: incomePill, matching: find.byType(InkWell)),
      );

      inkWell.onTap!();

      expect(cache.builderCalls, buildsBeforeTap);
      await tester.pump();
      expect(cache.builderCalls, buildsBeforeTap);
      expect(
        tester
            .widget<TransactionTypePills>(find.byType(TransactionTypePills))
            .activeType,
        TransactionType.income,
      );
      expect(
        find.byKey(const ValueKey('stats-type-switch-pending')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('stats-content-switcher')),
        findsNothing,
      );
      expect(worker.requests, hasLength(2));
      worker.complete(1);
      await tester.pump();
      expect(cache.builderCalls, buildsBeforeTap + 1);
      await tester.pump();
      expect(cache.builderCalls, buildsBeforeTap + 1);
      expect(
        find.byKey(const ValueKey('stats-type-switch-pending')),
        findsNothing,
      );
      expect(cache.resolvedKeys.last.activeType, TransactionType.income);
      expect(
        cache.resolvedFrames.last.yearData.activeType,
        TransactionType.income,
      );
      expect(cache.resolvedFrames.last.filteredTransactionCount, 1000);
    },
  );

  testWidgets(
    'retained Stats listener performs no frame build in Home type callback',
    (tester) async {
      final categories = [
        category(id: 1, name: 'Expense', type: TransactionType.expense),
        category(id: 2, name: 'Income', type: TransactionType.income),
      ];
      final transactions = List<TransactionRecord>.generate(6000, (index) {
        final income = index.isEven;
        return TransactionRecord(
          id: 200000 + index,
          date: '2026-07-${((index % 28) + 1).toString().padLeft(2, '0')}',
          time: '10:00',
          latitude: null,
          longitude: null,
          address: null,
          merchant: 'Merchant ${index % 40}',
          amount: income ? 1000 + index.toDouble() : -(1000 + index.toDouble()),
          userAssignedName: null,
          transactionCategoryID: income ? 2 : 1,
        );
      });
      final store = TransactionStore(
        StatsRepository(categories: categories, transactions: transactions),
        clock: () => DateTime(2026, 7, 7),
      );
      await store.start();
      final cache = TrackingStatsRenderFrameCache();
      Widget statsHost({required bool active}) {
        return MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: active,
              child: SizedBox(
                width: 390,
                height: 780,
                child: StatsPage(
                  store: store,
                  snapshotRepository: snapshotRepository,
                  renderFrameCache: cache,
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(statsHost(active: true));
      await pumpStatsPage(tester);
      store.setMerchantFilter('Merchant 0');
      await pumpStatsPage(tester);
      await tester.pumpWidget(statsHost(active: false));
      await tester.pump();
      final buildsBeforeHomeSwitch = cache.builderCalls;

      store.setActiveType(TransactionType.income);

      expect(cache.builderCalls, buildsBeforeHomeSwitch);
      await tester.pump();
      expect(cache.builderCalls, buildsBeforeHomeSwitch);

      await tester.pumpWidget(statsHost(active: true));
      await tester.pump();
      expect(cache.builderCalls, buildsBeforeHomeSwitch + 1);
    },
  );

  testWidgets(
    '10k worker keeps feedback light and publishes only latest search frame',
    (tester) async {
      final categories = [
        category(id: 1, name: 'Expense', type: TransactionType.expense),
      ];
      final transactions = List<TransactionRecord>.generate(10000, (index) {
        return TransactionRecord(
          id: 300000 + index,
          date: '2026-07-${((index % 28) + 1).toString().padLeft(2, '0')}',
          time: '10:00',
          latitude: null,
          longitude: null,
          address: null,
          merchant: 'Teszt ${index % 40}',
          amount: -(5000 + index.toDouble()),
          userAssignedName: null,
          transactionCategoryID: 1,
        );
      }, growable: false);
      final store = TransactionStore(
        StatsRepository(categories: categories, transactions: transactions),
        clock: () => DateTime(2026, 7, 7),
      );
      await store.start();
      final cache = TrackingStatsRenderFrameCache();
      final worker = ControlledStatsFrameWorker();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: StatsPage(
                store: store,
                snapshotRepository: snapshotRepository,
                renderFrameCache: cache,
                renderFrameWorker: worker,
              ),
            ),
          ),
        ),
      );

      expect(worker.requests, hasLength(1));
      expect(cache.builderCalls, 0);
      expect(find.byKey(const ValueKey('stats-frame-pending')), findsOneWidget);

      worker.complete(0);
      await tester.pump();
      await tester.pump();
      expect(cache.builderCalls, 1);
      final search = tester.widget<SearchPill>(find.byType(SearchPill));

      search.onQueryChanged('tes');
      await tester.pump();
      expect(worker.requests, hasLength(2));
      expect(cache.builderCalls, 1);
      expect(find.byKey(const ValueKey('stats-frame-pending')), findsOneWidget);

      search.onQueryChanged('teszt');
      await tester.pump();
      expect(worker.requests, hasLength(3));
      worker.complete(1);
      await tester.pump();
      expect(cache.builderCalls, 1);
      expect(find.byKey(const ValueKey('stats-frame-pending')), findsOneWidget);

      worker.complete(2);
      await tester.pump();
      await tester.pump();
      expect(cache.builderCalls, 2);
      expect(cache.resolvedKeys.last.query, 'teszt');
      expect(find.byKey(const ValueKey('stats-frame-pending')), findsNothing);

      final workerCalls = worker.requests.length;
      await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
      await tester.pump();
      expect(worker.requests, hasLength(workerCalls));
      expect(cache.builderCalls, 2);
    },
  );

  testWidgets(
    'FAB open uses the last rendered frame before its first route frame',
    (tester) async {
      final store = TransactionStore(
        StatsRepository(
          categories: [
            category(id: 1, name: 'Bolt', type: TransactionType.expense),
          ],
          transactions: [
            record(id: 1, date: '2026-01-01', amount: -80000, categoryId: 1),
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
      expect(cache.builderCalls, 1);

      controller.stepThreshold(1);
      controller.openThresholdSheet();

      expect(cache.builderCalls, 1);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('stats-threshold-sheet')),
        findsOneWidget,
      );
    },
  );

  testWidgets('slider drag publishes at most one trailing frame aggregation', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -80000, categoryId: 1),
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
    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    final beforeDrag = cache.builderCalls;
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('stats-threshold-slider')),
    );

    slider.onChanged!(11000);
    slider.onChanged!(16000);
    slider.onChanged!(24000);

    expect(cache.builderCalls, beforeDrag);
    await tester.pump();
    expect(cache.builderCalls, beforeDrag + 1);
    expect(find.text('25 000 Ft'), findsAtLeastNWidgets(1));
    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('stats-threshold-slider')))
          .value,
      25000,
    );
  });

  testWidgets('threshold slider retains exact 5000 steps above five million', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -10000000, categoryId: 1),
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

    var slider = tester.widget<Slider>(
      find.byKey(const ValueKey('stats-threshold-slider')),
    );
    expect(slider.max, 10000000);
    expect(slider.divisions, 2000);

    slider.onChanged!(5000000);
    await tester.pump();
    slider = tester.widget<Slider>(
      find.byKey(const ValueKey('stats-threshold-slider')),
    );
    slider.onChanged!(5005000);
    await tester.pump();

    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('stats-threshold-slider')))
          .value,
      5005000,
    );
    expect(find.text('5 005 000 Ft'), findsAtLeastNWidgets(1));
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

  testWidgets(
    'stats joystick coalesces exact threshold steps into one frame publication',
    (tester) async {
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
      final beforeSteps = cache.builderCalls;

      controller.stepThreshold(1);
      controller.stepThreshold(2);
      controller.stepThreshold(6);

      expect(cache.builderCalls, beforeSteps);
      await tester.pump();
      expect(cache.builderCalls, beforeSteps);
      await tester.pump();
      expect(cache.builderCalls, beforeSteps + 1);

      controller.openThresholdSheet();
      await pumpStatsPage(tester);
      expect(
        tester
            .widget<Slider>(
              find.byKey(const ValueKey('stats-threshold-slider')),
            )
            .value,
        50000,
      );
    },
  );

  testWidgets('stats discards a queued joystick target after a scope change', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2025-01-01', amount: -20000, categoryId: 1),
          record(id: 2, date: '2026-01-01', amount: -150000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryAllTime());
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

    controller.stepThreshold(6);
    controller.stepThreshold(6);
    final yearCard = tester.getRect(
      find.byKey(const ValueKey('stats-year-card-2025')),
    );
    await tester.tapAt(yearCard.topLeft + const Offset(20, 20));
    controller.stepThreshold(6);
    controller.stepThreshold(6);
    await tester.pump();

    expect(cache.resolvedKeys.last.summaryScope, StatsSummaryScope.yearly);
    expect(cache.resolvedKeys.last.year, 2025);
    expect(cache.resolvedKeys.last.threshold, 5000);

    await tester.pump();
    await tester.pump();
    expect(cache.resolvedKeys.last.threshold, 50000);
    controller.openThresholdSheet();
    await pumpStatsPage(tester);

    expect(
      tester
          .widget<Slider>(find.byKey(const ValueKey('stats-threshold-slider')))
          .value,
      50000,
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

  testWidgets('snapshot tap recalls while long press edits the same row', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -80000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();
    final createdAt = DateTime(2026, 7, 11, 10);
    final repository = InMemoryStatsSnapshotRepository([
      StatsSnapshot(
        id: 'editable',
        name: 'Eredeti',
        createdAt: createdAt,
        updatedAt: createdAt,
        includeCategoryScope: false,
        includeVendorScope: false,
        includeActiveType: false,
        includeThreshold: true,
        includeLayoutMode: false,
        includePageIndex: false,
        threshold: 25000,
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
    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    final card = find.byKey(const ValueKey('stats-snapshot-card-editable'));

    await tester.tap(card);
    await pumpStatsPage(tester);
    expect(find.text('25 000 Ft'), findsAtLeastNWidgets(1));
    expect(find.byKey(const ValueKey('stats-snapshot-dialog')), findsNothing);

    await tester.longPress(card);
    await pumpStatsPage(tester);
    expect(find.byKey(const ValueKey('stats-snapshot-dialog')), findsOneWidget);
    final nameField = tester.widget<TextField>(
      find.byKey(const ValueKey('stats-snapshot-name-input')),
    );
    expect(nameField.controller!.text, 'Eredeti');
    await tester.enterText(
      find.byKey(const ValueKey('stats-snapshot-name-input')),
      'Szerkesztett',
    );
    await tester.tap(find.byKey(const ValueKey('stats-snapshot-save-button')));
    await pumpStatsPage(tester);

    final rows = await repository.load();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'editable');
    expect(rows.single.createdAt, createdAt);
    expect(rows.single.name, 'Szerkesztett');
    expect(find.text('Szerkesztett'), findsOneWidget);
  });

  testWidgets('snapshot recall publishes one final frame and keeps Page 2', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
          category(id: 2, name: 'Fizetes', type: TransactionType.income),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -80000, categoryId: 1),
          record(id: 2, date: '2026-01-01', amount: 90000, categoryId: 2),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    unawaited(store.setSummaryYear(2026));
    final controller = StatsPageController();
    final cache = TrackingStatsRenderFrameCache();
    final now = DateTime(2026, 7, 11);
    final repository = InMemoryStatsSnapshotRepository([
      StatsSnapshot(
        id: 'one-publish',
        name: 'One publish',
        createdAt: now,
        updatedAt: now,
        includeCategoryScope: false,
        includeVendorScope: true,
        includeActiveType: true,
        includeThreshold: true,
        includeLayoutMode: true,
        includePageIndex: true,
        vendorScopeNames: const {'Teszt'},
        activeType: TransactionType.income,
        threshold: 25000,
        layoutMode: StatsLayoutMode.month,
        activeYear: 2026,
        activeMonth: 1,
        pageIndex: 0,
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
              renderFrameCache: cache,
            ),
          ),
        ),
      ),
    );
    await pumpStatsPage(tester);
    await tester.tap(find.byKey(const ValueKey('stats-page-chevron')));
    await pumpStatsPage(tester);
    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    final beforeRecall = cache.builderCalls;

    await tester.tap(
      find.byKey(const ValueKey('stats-snapshot-card-one-publish')),
    );
    await pumpStatsPage(tester);

    expect(cache.builderCalls, beforeRecall + 1);
    expect(find.byKey(const ValueKey('stats-page-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-page-1')), findsNothing);
    expect(find.text('25 000 Ft'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'narrow out-of-range recall builds only the final clamped frame',
    (tester) async {
      final store = TransactionStore(
        StatsRepository(
          categories: [
            category(id: 1, name: 'Nagy', type: TransactionType.expense),
            category(id: 2, name: 'Szűk', type: TransactionType.expense),
          ],
          transactions: [
            record(id: 1, date: '2026-01-01', amount: -200000, categoryId: 1),
            record(id: 2, date: '2026-01-02', amount: -20000, categoryId: 2),
          ],
        ),
        clock: () => DateTime(2026, 7, 7),
      );
      await store.start();
      unawaited(store.setSummaryYear(2026));
      final controller = StatsPageController();
      final cache = TrackingStatsRenderFrameCache();
      final now = DateTime(2026, 7, 11);
      final repository = InMemoryStatsSnapshotRepository([
        StatsSnapshot(
          id: 'narrow-clamp',
          name: 'Szűk clamp',
          createdAt: now,
          updatedAt: now,
          includeCategoryScope: true,
          includeVendorScope: false,
          includeActiveType: false,
          includeThreshold: true,
          includeLayoutMode: false,
          includePageIndex: false,
          categoryScopeIds: const {2},
          threshold: 200000,
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
                renderFrameCache: cache,
              ),
            ),
          ),
        ),
      );
      await pumpStatsPage(tester);
      controller.openThresholdSheet();
      await pumpStatsPage(tester);
      final beforeRecall = cache.builderCalls;

      await tester.tap(
        find.byKey(const ValueKey('stats-snapshot-card-narrow-clamp')),
      );
      await pumpStatsPage(tester);

      expect(cache.builderCalls, beforeRecall + 1);
      expect(find.text('50 000 Ft'), findsAtLeastNWidgets(1));
      expect(
        tester
            .widget<Slider>(
              find.byKey(const ValueKey('stats-threshold-slider')),
            )
            .value,
        50000,
      );
    },
  );

  testWidgets(
    'out-of-order recall commits only latest target in one store publication',
    (tester) async {
      final store = DelayedSnapshotTransactionStore(
        StatsRepository(
          categories: [
            category(id: 1, name: 'Bolt', type: TransactionType.expense),
            category(id: 2, name: 'Fizetes', type: TransactionType.income),
          ],
          transactions: [
            record(id: 1, date: '2026-01-01', amount: -80000, categoryId: 1),
            record(id: 2, date: '2026-01-01', amount: 90000, categoryId: 2),
          ],
        ),
        clock: () => DateTime(2026, 7, 7),
      );
      await store.start();
      unawaited(store.setSummaryYear(2026));
      var storePublications = 0;
      store.addListener(() => storePublications += 1);
      final controller = StatsPageController();
      final cache = TrackingStatsRenderFrameCache();
      final now = DateTime(2026, 7, 11);
      final repository = InMemoryStatsSnapshotRepository([
        StatsSnapshot(
          id: 'stale-a',
          name: 'Stale A',
          createdAt: now,
          updatedAt: now,
          includeCategoryScope: false,
          includeVendorScope: true,
          includeActiveType: true,
          includeThreshold: true,
          includeLayoutMode: true,
          includePageIndex: false,
          vendorScopeNames: const {'A vendor'},
          activeType: TransactionType.income,
          threshold: 10000,
          layoutMode: StatsLayoutMode.month,
          activeYear: 2025,
          activeMonth: 3,
        ),
        StatsSnapshot(
          id: 'latest-b',
          name: 'Latest B',
          createdAt: now.add(const Duration(seconds: 1)),
          updatedAt: now.add(const Duration(seconds: 1)),
          includeCategoryScope: false,
          includeVendorScope: false,
          includeActiveType: true,
          includeThreshold: true,
          includeLayoutMode: false,
          includePageIndex: true,
          activeType: TransactionType.expense,
          threshold: 25000,
          pageIndex: 1,
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
                renderFrameCache: cache,
              ),
            ),
          ),
        ),
      );
      await pumpStatsPage(tester);
      controller.openThresholdSheet();
      await pumpStatsPage(tester);
      final frameBuildsBeforeRecall = cache.builderCalls;

      await tester.tap(
        find.byKey(const ValueKey('stats-snapshot-card-stale-a')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('stats-snapshot-card-latest-b')),
      );
      await tester.pump();

      expect(store.pendingPreparations, 2);
      expect(store.snapshotCommitCount, 0);
      expect(storePublications, 0);
      expect(cache.builderCalls, frameBuildsBeforeRecall);

      store.completePreparation(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      await tester.pump(const Duration(milliseconds: 240));

      expect(store.snapshotCommitCount, 1);
      expect(storePublications, 1);
      expect(store.summaryWindow, SummaryWindow.yearly);
      expect(store.summaryReferenceDate.year, 2026);
      expect(store.activeMerchantFilters, isEmpty);
      expect(cache.builderCalls, frameBuildsBeforeRecall + 1);
      expect(find.text('25 000 Ft'), findsAtLeastNWidgets(1));
      expect(
        tester
            .widget<StatsYearCalendar>(find.byType(StatsYearCalendar))
            .data
            .activeType,
        TransactionType.expense,
      );
      expect(find.byKey(const ValueKey('stats-page-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('stats-page-2')), findsNothing);

      store.completePreparation(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));
      await tester.pump(const Duration(milliseconds: 240));

      expect(store.snapshotCommitCount, 1);
      expect(storePublications, 1);
      expect(store.summaryWindow, SummaryWindow.yearly);
      expect(store.activeMerchantFilters, isEmpty);
      expect(cache.builderCalls, frameBuildsBeforeRecall + 1);
      expect(find.text('25 000 Ft'), findsAtLeastNWidgets(1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      store.dispose();
    },
  );

  testWidgets('worst-case snapshot card keeps every field in 112x74', (
    tester,
  ) async {
    final now = DateTime(2026, 7, 11);
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
          category(id: 2, name: 'Étterem', type: TransactionType.expense),
          category(id: 3, name: 'Utazás', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -80000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    final controller = StatsPageController();
    final snapshot = StatsSnapshot(
      id: 'all-fields',
      name: 'Minden szuro hosszu neve',
      createdAt: now,
      updatedAt: now,
      includeCategoryScope: true,
      includeVendorScope: true,
      includeActiveType: true,
      includeThreshold: true,
      includeLayoutMode: true,
      includePageIndex: true,
      categoryScopeIds: const {1, 2, 3},
      vendorScopeNames: const {'Aldi', 'Spar', 'Tesco'},
      activeType: TransactionType.expense,
      threshold: 125000,
      layoutMode: StatsLayoutMode.month,
      activeYear: 2025,
      activeMonth: 12,
      pageIndex: 1,
    );
    final repository = InMemoryStatsSnapshotRepository([snapshot]);
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
    controller.openThresholdSheet();
    await pumpStatsPage(tester);
    final renderedCard = tester.widget<GestureDetector>(
      find.byKey(const ValueKey('stats-snapshot-card-all-fields')),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    for (final scale in const [1.0, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: Center(child: renderedCard)),
          ),
        ),
      );
      await tester.pump();
      final card = find.byKey(const ValueKey('stats-snapshot-card-all-fields'));

      expect(tester.getSize(card), const Size(112, 74));
      expect(
        MediaQuery.textScalerOf(tester.element(card)).scale(10),
        10 * scale,
      );
      for (final field in const [
        'type',
        'layout',
        'page',
        'threshold',
        'categories',
        'vendors',
      ]) {
        expect(
          find.byKey(ValueKey('stats-snapshot-token-$field-all-fields')),
          findsOneWidget,
        );
      }
      final texts = tester.widgetList<Text>(
        find.descendant(of: card, matching: find.byType(Text)),
      );
      expect(
        texts,
        everyElement(
          predicate<Text>((text) => text.overflow != TextOverflow.ellipsis),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('snapshot info exposes full scopes and long press still edits', (
    tester,
  ) async {
    final store = TransactionStore(
      StatsRepository(
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
          category(id: 2, name: 'Étterem', type: TransactionType.expense),
          category(id: 3, name: 'Utazás', type: TransactionType.expense),
        ],
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -80000, categoryId: 1),
        ],
      ),
      clock: () => DateTime(2026, 7, 7),
    );
    await store.start();
    final controller = StatsPageController();
    final now = DateTime(2026, 7, 11);
    final repository = InMemoryStatsSnapshotRepository([
      StatsSnapshot(
        id: 'details',
        name: 'Reszletes',
        createdAt: now,
        updatedAt: now,
        includeCategoryScope: true,
        includeVendorScope: true,
        includeActiveType: true,
        includeThreshold: true,
        includeLayoutMode: true,
        includePageIndex: true,
        categoryScopeIds: const {1, 2, 3},
        vendorScopeNames: const {'Aldi', 'Spar', 'Tesco'},
        activeType: TransactionType.expense,
        threshold: 125000,
        layoutMode: StatsLayoutMode.month,
        activeYear: 2025,
        activeMonth: 12,
        pageIndex: 1,
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
    controller.openThresholdSheet();
    await pumpStatsPage(tester);

    await tester.tap(find.byKey(const ValueKey('stats-snapshot-info-details')));
    await pumpStatsPage(tester);

    expect(
      find.byKey(const ValueKey('stats-snapshot-details-dialog')),
      findsOneWidget,
    );
    expect(
      find.text('Kategória szűrés: Bolt, Étterem, Utazás'),
      findsOneWidget,
    );
    expect(find.text('Kereskedő szűrés: Aldi, Spar, Tesco'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('stats-snapshot-details-close')),
    );
    await pumpStatsPage(tester);

    await tester.longPress(
      find.byKey(const ValueKey('stats-snapshot-card-details')),
    );
    await pumpStatsPage(tester);
    expect(find.byKey(const ValueKey('stats-snapshot-dialog')), findsOneWidget);
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
      final cache = TrackingStatsRenderFrameCache();
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
                renderFrameCache: cache,
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
      final beforeRecall = cache.builderCalls;
      await tester.tap(find.text('Bevétel oldal'));
      await pumpStatsPage(tester);

      expect(cache.builderCalls, beforeRecall + 1);
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
    'focused month fits target viewports without scaling scrolling or duplicate header',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
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
      for (final viewport in const [
        Size(360, 800),
        Size(390, 780),
        Size(412, 915),
      ]) {
        tester.view.physicalSize = viewport;
        unawaited(store.setSummaryYear(2026));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: viewport.width,
                height: viewport.height,
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

        final focus = find.byKey(const ValueKey('calendar-focus-month-view'));
        final canvas = find.byKey(
          const ValueKey('calendar-focus-month-canvas'),
        );
        final card = find.byKey(const ValueKey('stats-focused-month-card'));
        final boundary = find.byKey(const ValueKey('stats-page-1-boundary'));
        expect(focus, findsOneWidget, reason: '$viewport');
        expect(canvas, findsOneWidget, reason: '$viewport');
        expect(card, findsOneWidget, reason: '$viewport');
        expect(
          find.descendant(
            of: focus,
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
          reason: '$viewport',
        );
        expect(
          find.descendant(of: focus, matching: find.byType(FittedBox)),
          findsNothing,
          reason: '$viewport',
        );
        expect(
          find.byKey(const ValueKey('calendar-focus-back')),
          findsNothing,
          reason: '$viewport',
        );
        expect(find.text('Január 2026'), findsOneWidget, reason: '$viewport');
        expect(
          tester.getRect(boundary).bottom - tester.getRect(canvas).bottom,
          moreOrLessEquals(24, epsilon: 0.01),
          reason: '$viewport',
        );
        expect(
          tester.getRect(canvas).width / tester.getRect(canvas).height,
          moreOrLessEquals(0.875, epsilon: 0.001),
          reason: '$viewport',
        );
        expect(
          tester.getRect(canvas).left,
          greaterThanOrEqualTo(tester.getRect(focus).left),
          reason: '$viewport',
        );
        expect(
          tester.getRect(canvas).right,
          lessThanOrEqualTo(tester.getRect(focus).right),
          reason: '$viewport',
        );

        final monthLabel = tester.widget<Text>(
          find.descendant(of: card, matching: find.text('Január')),
        );
        final dayLabel = tester.widget<Text>(
          find.descendant(of: card, matching: find.text('1')),
        );
        expect(monthLabel.style?.fontSize, 12, reason: '$viewport');
        expect(monthLabel.style?.fontWeight, FontWeight.w700);
        expect(dayLabel.style?.fontSize, 10, reason: '$viewport');
        final cardInk = tester.widget<Ink>(
          find.descendant(of: card, matching: find.byType(Ink)),
        );
        final cardDecoration = cardInk.decoration as BoxDecoration;
        expect((cardDecoration.border! as Border).top.width, 1);
        expect(tester.takeException(), isNull, reason: '$viewport');
        await expectGoldenWithPixelTolerance(
          find.byKey(const ValueKey('stats-page')),
          'goldens/stats_focused_month_${viewport.width.round()}x${viewport.height.round()}.png',
          maxDiffPixels: 1,
        );
      }
    },
  );

  testWidgets('annual Page 1 exposes a 24px bottom inset after scrolling', (
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

    final scroll = find.byKey(const ValueKey('stats-year-calendar-scroll'));
    await tester.fling(scroll, const Offset(0, -2400), 3000);
    await tester.pumpAndSettle();

    expect(
      tester
              .getRect(find.byKey(const ValueKey('stats-page-1-boundary')))
              .bottom -
          tester
              .getRect(find.byKey(const ValueKey('stats-month-card-12')))
              .bottom,
      moreOrLessEquals(24, epsilon: 0.01),
    );
  });

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

Future<void> expectGoldenWithPixelTolerance(
  Finder finder,
  String goldenPath, {
  required int maxDiffPixels,
}) async {
  final previousComparator = goldenFileComparator;
  goldenFileComparator = _PixelToleranceGoldenComparator(
    Uri.parse('test/stats/stats_page_test.dart'),
    maxDiffPixels: maxDiffPixels,
  );
  try {
    await expectLater(finder, matchesGoldenFile(goldenPath));
  } finally {
    goldenFileComparator = previousComparator;
  }
}

class _PixelToleranceGoldenComparator extends LocalFileComparator {
  _PixelToleranceGoldenComparator(super.testFile, {required this.maxDiffPixels})
    : assert(maxDiffPixels >= 0);

  final int maxDiffPixels;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final diffPixels = _diffPixels(result);
    if (result.passed || (diffPixels != null && diffPixels <= maxDiffPixels)) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }

  int? _diffPixels(ComparisonResult result) {
    final error = result.error;
    if (error == null) return null;
    final match = RegExp(r'(\d+)px diff detected').firstMatch(error);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}

class ImmediateStatsFrameWorker implements StatsRenderFrameWorker {
  const ImmediateStatsFrameWorker();

  @override
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request) {
    return Future<StatsRenderFrame>.value(request.buildSynchronously());
  }
}

class ControlledStatsFrameWorker implements StatsRenderFrameWorker {
  final requests = <StatsRenderFrameRequest>[];
  final _completers = <Completer<StatsRenderFrame>>[];

  @override
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request) {
    requests.add(request);
    final completer = Completer<StatsRenderFrame>();
    _completers.add(completer);
    return completer.future;
  }

  void complete(int index) {
    _completers[index].complete(requests[index].buildSynchronously());
  }
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
  final resolvedKeys = <StatsRenderFrameKey>[];

  @override
  StatsRenderFrame resolve(
    StatsRenderFrameKey key,
    StatsRenderFrame Function() builder,
  ) {
    resolvedKeys.add(key);
    final frame = super.resolve(key, () {
      builderCalls += 1;
      return builder();
    });
    resolvedFrames.add(frame);
    return frame;
  }
}

class DelayedSnapshotTransactionStore extends TransactionStore {
  DelayedSnapshotTransactionStore(super.repository, {required super.clock});

  final _preparationGates = <Completer<void>>[];
  var snapshotCommitCount = 0;

  int get pendingPreparations => _preparationGates.length;

  void completePreparation(int index) {
    _preparationGates[index].complete();
  }

  @override
  Future<StatsViewMutation> prepareStatsViewMutation({
    Set<String>? merchantFilters,
    SummaryWindow? summaryWindow,
    int? year,
    int? month,
  }) async {
    final gate = Completer<void>();
    _preparationGates.add(gate);
    await gate.future;
    return super.prepareStatsViewMutation(
      merchantFilters: merchantFilters,
      summaryWindow: summaryWindow,
      year: year,
      month: month,
    );
  }

  @override
  void commitStatsViewMutation(StatsViewMutation mutation) {
    snapshotCommitCount += 1;
    super.commitStatsViewMutation(mutation);
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
