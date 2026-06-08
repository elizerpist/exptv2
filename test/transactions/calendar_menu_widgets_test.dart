import 'package:exptv2/features/transactions/data/calendar_render_builder.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/calendar_menu_mode.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/stats/stats_page.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_canvas.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar mode selector renders compact visual mode buttons', (
    tester,
  ) async {
    var selected = CalendarMenuMode.category;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarModeSelector(
            activeMode: selected,
            transitionLocked: false,
            onModeChanged: (mode) => selected = mode,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('calendar-mode-selector')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('calendar-mode-normal')), findsNothing);
    expect(find.byKey(const ValueKey('calendar-mode-category')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-heatmap')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-mode-heatmap')));
    expect(selected, CalendarMenuMode.heatmap);
  });

  testWidgets(
    'threshold slider panel edits collapses and drags as category filter',
    (tester) async {
      var changed = 1000.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: CalendarValueSliderPanel.threshold(
                value: 1000,
                min: 0,
                max: 2000,
                onChanged: (value) => changed = value,
                onMinChanged: (_) {},
                onMaxChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Domináns küszöb: 1 000 Ft'), findsOneWidget);
      final panel = find.byKey(const ValueKey('calendar-threshold-slider-panel'));
      final beforeTop = tester.getTopLeft(panel).dy;
      await tester.drag(
        find.byKey(const ValueKey('calendar-threshold-slider-drag-handle')),
        const Offset(0, -70),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panel).dy, lessThan(beforeTop));

      await tester.drag(
        find.byKey(const ValueKey('calendar-threshold-slider')),
        const Offset(80, 0),
      );
      expect(changed, isNot(1000));

      await tester.tap(find.byKey(const ValueKey('calendar-threshold-slider-collapse')));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(
        find.byKey(const ValueKey('calendar-threshold-slider-mini-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('calendar-threshold-slider-mini-button')),
      );
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);
    },
  );

  testWidgets('heatmap slider panel shows editable and compact controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarValueSliderPanel.heatmap(
            value: 10000,
            min: 0,
            max: 50000,
            onChanged: (_) {},
            onMinChanged: (_) {},
            onMaxChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Hőtérkép skála: 10 000 Ft'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-heatmap-slider-collapse')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsNothing);
    expect(
      find.byKey(const ValueKey('calendar-heatmap-slider-mini-button')),
      findsOneWidget,
    );
  });

  test('calendar canvas layout creates two columns and six rows', () {
    final layout = CalendarCanvasLayout.calculate(
      width: 390,
      mode: CalendarMenuMode.normal,
    );
    expect(layout.monthRects.length, 12);
    expect(layout.monthRects[0].left, 0);
    expect(layout.monthRects[1].left, greaterThan(layout.monthRects[0].right));
    expect(layout.monthRects[2].top, greaterThan(layout.monthRects[0].bottom));
  });

  test(
    'calendar canvas layout keeps month card size consistent in every mode',
    () {
      final summary = CalendarCanvasLayout.calculate(
        width: 390,
        mode: CalendarMenuMode.summary,
      );

      for (final mode in CalendarMenuMode.values) {
        final layout = CalendarCanvasLayout.calculate(width: 390, mode: mode);
        expect(layout.monthRects.first.size, summary.monthRects.first.size);
        expect(layout.size.height, summary.size.height);
      }
    },
  );

  testWidgets('calendar canvas renders annual body as one CustomPaint', (
    tester,
  ) async {
    final renderData = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: const [],
      categories: const [],
      thresholdValue: 1000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 10000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 500,
            child: CalendarCanvas(
              data: renderData,
              mode: CalendarMenuMode.normal,
              thresholdValue: 1000,
              heatmapMinValue: 0,
              heatmapCurrentValue: 10000,
              onMonthSelected: (_, _) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('calendar-canvas')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-canvas-paint')), findsOneWidget);
    expect(find.text('January'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('stats dropdown switches modes and exposes export placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarMenuOverlay(
              transactions: const [],
              categories: const [],
              onClose: () {},
              onMonthSelect: (_, _) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('calendar-mode-selector')), findsNothing);
    expect(find.byKey(const ValueKey('stats-menu-trigger')), findsOneWidget);
    expect(find.text('Domináns kategória'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-threshold-slider')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('stats-menu-trigger')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('stats-menu-mode-normal')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('stats-menu-mode-summary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stats-menu-mode-heatmap')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stats-menu-mode-category')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('stats-menu-export-csv')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-menu-export-pdf')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stats-menu-mode-heatmap')));
    await tester.pumpAndSettle();
    expect(find.text('Hőtérkép'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-heatmap-slider')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('stats-menu-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stats-menu-export-csv')));
    await tester.pumpAndSettle();
    expect(find.text('CSV export később érkezik'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stats-menu-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stats-menu-export-pdf')));
    await tester.pumpAndSettle();
    expect(find.text('PDF export később érkezik'), findsOneWidget);
  });

  testWidgets('calendar menu header shows top-left stats menu trigger', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarMenuOverlay(
              transactions: const [],
              categories: const [],
              onClose: () {},
              onMonthSelect: (_, _) {},
            ),
          ),
        ),
      ),
    );

    final currentYear = DateTime.now().year.toString();
    final menuRect = tester.getRect(
      find.byKey(const ValueKey('stats-menu-trigger')),
    );
    final titleTop = tester.getTopLeft(find.text('Domináns kategória')).dy;
    final yearTop = tester.getTopLeft(find.text(currentYear)).dy;

    expect(menuRect.left, lessThan(24));
    expect(menuRect.top, lessThanOrEqualTo(titleTop));
    expect(titleTop, lessThan(yearTop));
    expect(find.byKey(const ValueKey('calendar-mode-selector')), findsNothing);
  });

  testWidgets(
    'month card tap opens focused month view and back returns annual view',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: CalendarMenuOverlay(
                transactions: const [],
                categories: const [],
                onClose: () {},
                onMonthSelect: (_, _) {},
              ),
            ),
          ),
        ),
      );

      await _tapFirstMonthCard(tester);

      expect(
        find.byKey(const ValueKey('calendar-focus-month-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('calendar-focus-month-canvas')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('calendar-focus-back')), findsOneWidget);
      expect(find.textContaining('January'), findsOneWidget);
      expect(find.byKey(const ValueKey('calendar-canvas')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('calendar-focus-back')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('calendar-focus-month-view')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('calendar-canvas')), findsOneWidget);
    },
  );

  testWidgets('focused month keeps shared view modes from stats dropdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarMenuOverlay(
              transactions: const [],
              categories: const [],
              onClose: () {},
              onMonthSelect: (_, _) {},
            ),
          ),
        ),
      ),
    );

    await _tapFirstMonthCard(tester);
    await tester.tap(find.byKey(const ValueKey('stats-menu-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stats-menu-mode-heatmap')));
    await tester.pumpAndSettle();

    expect(find.text('Hőtérkép'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-focus-month-canvas')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-heatmap-slider')),
      findsOneWidget,
    );
  });

  testWidgets('focused month renders visual monthly stats charts', (
    tester,
  ) async {
    final year = DateTime.now().year;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarMenuOverlay(
              transactions: [
                _record(
                  id: 1,
                  date: '$year-01-03',
                  amount: -12000,
                  categoryId: 1,
                ),
                _record(
                  id: 2,
                  date: '$year-01-08',
                  amount: -7500,
                  categoryId: 2,
                ),
                _record(
                  id: 3,
                  date: '$year-01-18',
                  amount: -22000,
                  categoryId: 1,
                ),
                _record(
                  id: 4,
                  date: '$year-01-20',
                  amount: 180000,
                  categoryId: 9,
                ),
              ],
              categories: const [
                TransactionCategory(
                  transactionCategoryID: 1,
                  name: 'Élelmiszer',
                  type: 'kiadás',
                  colorSlot: 1,
                  iconSlot: null,
                  backgroundColor: null,
                  icon: null,
                  notification: null,
                  hasLimit: false,
                  limitAmount: 0,
                  alertActive: false,
                  isCustomIcon: false,
                  originalIcon: null,
                ),
                TransactionCategory(
                  transactionCategoryID: 2,
                  name: 'Közlekedés',
                  type: 'kiadás',
                  colorSlot: 2,
                  iconSlot: null,
                  backgroundColor: null,
                  icon: null,
                  notification: null,
                  hasLimit: false,
                  limitAmount: 0,
                  alertActive: false,
                  isCustomIcon: false,
                  originalIcon: null,
                ),
              ],
              onClose: () {},
              onMonthSelect: (_, _) {},
            ),
          ),
        ),
      ),
    );

    await _tapFirstMonthCard(tester);

    expect(find.byKey(const ValueKey('month-cashflow-chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('month-daily-sparkline')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('month-category-breakdown')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('month-weekly-bars')), findsOneWidget);
    expect(find.byKey(const ValueKey('month-highlight-tiles')), findsOneWidget);
    expect(find.byKey(const ValueKey('month-deep-stats-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('month-merchant-stats')), findsOneWidget);
    expect(find.text('Cashflow'), findsOneWidget);
    expect(find.text('Napi ritmus'), findsOneWidget);
    expect(find.text('Kategóriák'), findsOneWidget);
    expect(find.text('Heti bontás'), findsOneWidget);
    expect(find.text('Kiemelések'), findsOneWidget);
    expect(find.text('Havi részletek'), findsOneWidget);
    expect(find.text('Kereskedők'), findsOneWidget);
    expect(find.text('Élelmiszer'), findsOneWidget);
    expect(find.text('Teszt'), findsOneWidget);
  });

  testWidgets('stats page renders calendar as a full screen tab', (
    tester,
  ) async {
    final store = TransactionStore(CalendarHomeRepository());
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
    expect(find.byKey(const ValueKey('calendar-menu-overlay')), findsOneWidget);
    expect(find.text('Domináns kategória'), findsOneWidget);
  });
}

Future<void> _tapFirstMonthCard(WidgetTester tester) async {
  final topLeft = tester.getTopLeft(
    find.byKey(const ValueKey('calendar-canvas')),
  );
  await tester.tapAt(topLeft + const Offset(84, 100));
  await tester.pumpAndSettle();
}

TransactionRecord _record({
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

class CalendarHomeRepository extends TransactionRepositoryContract {
  @override
  Future<TransactionBootstrap> loadBootstrap() async =>
      const TransactionBootstrap(categories: [], transactions: [], limits: []);

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
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) async {
    throw UnimplementedError();
  }

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
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteCategory(int id) async {
    throw UnimplementedError();
  }

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
  Future<Map<int, int>> categoryCounts() async => const {};

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async {
    return const [];
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }
}
