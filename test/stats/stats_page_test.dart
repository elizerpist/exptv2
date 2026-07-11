import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/features/stats/widgets/stats_fast_info_graph.dart';
import 'package:exptv2/features/stats/widgets/stats_year_calendar.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_menu_panel.dart';
import 'package:exptv2/features/transactions/widgets/header_card/magnet_strip.dart';
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

  testWidgets('stats annual calendar accepts themed month card background', (
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
            child: StatsFastInfoGraph(data: data(StatsRenderMode.heatmap)),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('stats-fastinfo-graph')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stats-fastinfo-heatmap')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('stats-fastinfo-card')), findsNothing);
    expect(find.byKey(const ValueKey('stats-fastinfo-pill')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 328,
            child: StatsFastInfoGraph(data: data(StatsRenderMode.closing)),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('stats-fastinfo-closing')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 328,
            child: StatsFastInfoGraph(
              data: data(StatsRenderMode.categoryScope),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('stats-fastinfo-categoryScope')),
      findsOneWidget,
    );
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
    final spec = StatsFastInfoGraph.specForTesting(
      StatsRenderMode.categoryScope,
    );

    expect(spec.charts, hasLength(2));
    expect(spec.charts[0].title, '1. Scope score · Soft band');
    expect(spec.charts[0].yAxisLabel, 'score');
    expect(spec.charts[0].xAxisLabel, 'honapok');
    expect(spec.charts[0].legendLabels, ['rossz', 'semleges 50', 'jó']);
    expect(spec.charts[1].title, '2. Threshold excess');
    expect(spec.charts[1].legendLabels, ['threshold']);
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
    expect(find.text('SCOPE SCORE'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stats-magnet-categoryScope')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('summary-pill')), findsOneWidget);
    expect(find.text('Éves · 2026 · Kiadás'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-year-calendar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-threshold-joystick-trigger')),
      findsOneWidget,
    );
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

    await tester.tap(find.text('Bevétel').first);
    await tester.pumpAndSettle();

    expect(find.text('INCOME SCORE'), findsOneWidget);
    expect(find.text('56/100'), findsOneWidget);

    final strip = tester.widget<MagnetStrip>(find.byType(MagnetStrip));
    expect(strip.customMarkerStyle, MagnetMarkerStyle.line);
    expect(strip.customMarkerPosition, moreOrLessEquals(0.5565, epsilon: 0.01));
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
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('stats-magnet-categoryScope')),
      findsOneWidget,
    );
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
    await tester.pumpAndSettle();

    final calendar = tester.widget<StatsYearCalendar>(
      find.byType(StatsYearCalendar),
    );
    expect(calendar.monthCardColor, AppColors.gray200);
  });

  testWidgets('stats joystick tap opens threshold control sheet', (
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

    await tester.tap(
      find.byKey(const ValueKey('calendar-threshold-joystick-trigger')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('stats-threshold-sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('stats-render-mode-selector')),
      findsOneWidget,
    );
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
    await tester.pumpAndSettle();

    expect(find.text('12 000 Ft'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const ValueKey('stats-render-mode-heatmap')));
    await tester.pumpAndSettle();

    expect(find.text('HEATMAP'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-magnet-heatmap')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stats-render-mode-closing')));
    await tester.pumpAndSettle();

    expect(find.text('HÓZÁRÁS'), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-magnet-closing')), findsOneWidget);
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

    await tester.ensureVisible(find.byKey(const ValueKey('category-card-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-card-1')));
    await tester.tap(find.byKey(const ValueKey('category-menu-apply-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gyorskaja'), findsNothing);
    expect(find.text('SCOPE SCORE'), findsOneWidget);
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

  testWidgets(
    'stats month card tap opens focused month view and back returns',
    (tester) async {
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

      await tester.tap(find.byKey(const ValueKey('stats-month-hit-1')));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
