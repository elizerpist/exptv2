import 'package:exptv2/features/transactions/data/calendar_render_builder.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/calendar_menu_mode.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_canvas.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar mode selector renders four tappable mode buttons', (
    tester,
  ) async {
    var selected = CalendarMenuMode.normal;
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

    expect(find.byKey(const ValueKey('calendar-mode-selector')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-normal')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-heatmap')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-category')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-mode-heatmap')));
    expect(selected, CalendarMenuMode.heatmap);
  });

  testWidgets('threshold slider panel shows editable Hungarian threshold label', (
    tester,
  ) async {
    var changed = 1000.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarValueSliderPanel.threshold(
            value: 1000,
            min: 0,
            max: 2000,
            onChanged: (value) => changed = value,
            onMinChanged: (_) {},
            onMaxChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Küszöbérték: 1 000 Ft'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('calendar-threshold-slider')),
      const Offset(80, 0),
    );
    expect(changed, isNot(1000));
  });

  testWidgets('heatmap slider panel shows editable current coloring label', (
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

    expect(find.text('Aktuális színezés: 10 000 Ft'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsOneWidget);
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

  testWidgets('calendar menu overlay switches modes and controls', (
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

    expect(find.text('Küszöbérték nézet'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-threshold-slider')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-mode-heatmap')));
    await tester.pumpAndSettle();
    expect(find.text('Hőtérkép'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-mode-category')));
    await tester.pumpAndSettle();
    expect(find.text('Domináns kategória'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsNothing);
  });

  testWidgets('home calendar button opens calendar overlay', (tester) async {
    final store = TransactionStore(CalendarHomeRepository());
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

    await tester.tap(find.byKey(const ValueKey('header-calendar-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar-menu-overlay')), findsOneWidget);
    expect(find.text('Küszöbérték nézet'), findsOneWidget);
  });
}

class CalendarHomeRepository implements TransactionRepositoryContract {
  @override
  Future<TransactionBootstrap> loadBootstrap() async => const TransactionBootstrap(
    categories: [],
    transactions: [],
    limits: [],
  );

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
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) async {
    throw UnimplementedError();
  }
}
