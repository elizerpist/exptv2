import 'dart:async';

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_icon_badge.dart';
import 'package:exptv2/features/transactions/widgets/category_slot_icon.dart';
import 'package:exptv2/features/transactions/widgets/glossy_category_avatar.dart';
import 'package:exptv2/features/transactions/widgets/search_pill.dart';
import 'package:exptv2/features/transactions/widgets/summary_pill.dart';
import 'package:exptv2/features/transactions/widgets/summary_scope_picker_sheet.dart';
import 'package:exptv2/features/transactions/widgets/themed_pill_field.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_box.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_list.dart';
import 'package:exptv2/features/transactions/widgets/transaction_type_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  testWidgets('type pills switch active type', (tester) async {
    var selected = TransactionType.expense;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionTypePills(
          activeType: selected,
          onChanged: (type) => selected = type,
        ),
      ),
    );

    await tester.tap(find.text('Bevétel'));
    expect(selected, TransactionType.income);
  });

  testWidgets('type pill tap writes a received telemetry event', (
    tester,
  ) async {
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionTypePills(
          activeType: TransactionType.expense,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Bevétel'));

    expect(DebugConsole.allText, contains('[Perf] TypePill tap target=income'));
  });

  testWidgets('type pills can disable neutral shadows', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionTypePills(
          activeType: TransactionType.expense,
          onChanged: (_) {},
          shadowEnabled: false,
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('transaction-type-pill-expense-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('summary pill vertical swipe cycles interval', (tester) async {
    var cycles = 0;
    final periods = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Május 2026',
          value: '-66 Ft',
          onIntervalSwipe: () => cycles += 1,
          onPeriodSwipe: periods.add,
          onResetToCurrentMonth: () {},
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();

    expect(cycles, 1);
    expect(periods, isEmpty);
  });

  testWidgets('summary pill horizontal swipe shifts period', (tester) async {
    var cycles = 0;
    final periods = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Május 2026',
          value: '-66 Ft',
          onIntervalSwipe: () => cycles += 1,
          onPeriodSwipe: periods.add,
          onResetToCurrentMonth: () {},
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(-90, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(90, 0),
    );
    await tester.pumpAndSettle();

    expect(cycles, 0);
    expect(periods, [1, -1]);
  });

  testWidgets('summary pill waits for drag release before changing period', (
    tester,
  ) async {
    final periods = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Május 2026',
          value: '-66 Ft',
          onIntervalSwipe: () {},
          onPeriodSwipe: periods.add,
          onResetToCurrentMonth: () {},
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('summary-pill')));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-70, 0));
    await tester.pump();

    expect(periods, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(periods, [1]);
  });

  testWidgets('summary pill double tap resets to current month', (
    tester,
  ) async {
    var resets = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Sum',
          value: '-66 Ft',
          onIntervalSwipe: () {},
          onPeriodSwipe: (_) {},
          onResetToCurrentMonth: () => resets += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('summary-pill')));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byKey(const ValueKey('summary-pill')));
    await tester.pumpAndSettle();

    expect(resets, 1);
  });

  testWidgets('summary pill changes title and value immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Kiadások',
          value: '-66 Ft',
          onIntervalSwipe: () {},
          onPeriodSwipe: (_) {},
          onResetToCurrentMonth: () {},
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-pill')),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Bevételek',
          value: '+555 Ft',
          onIntervalSwipe: () {},
          onPeriodSwipe: (_) {},
          onResetToCurrentMonth: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bevételek'), findsOneWidget);
    expect(find.text('+555 Ft'), findsOneWidget);
    expect(find.text('Kiadások'), findsNothing);
  });

  testWidgets('summary pill drag feedback is transform-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Május 2026',
          value: '-66 Ft',
          onIntervalSwipe: () {},
          onPeriodSwipe: (_) {},
          onResetToCurrentMonth: () {},
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('summary-pill')),
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('summary-pill-transform')),
      findsOneWidget,
    );
  });

  testWidgets('summary pill uses configured surface color and style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Május 2026',
          value: '-66 Ft',
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          onIntervalSwipe: () {},
          onPeriodSwipe: (_) {},
          onResetToCurrentMonth: () {},
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('summary-pill-container')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.gray200);
    expect(decoration.boxShadow, isNotNull);
  });

  testWidgets('summary pill can disable neutral shadow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Május 2026',
          value: '-66 Ft',
          shadowEnabled: false,
          onIntervalSwipe: () {},
          onPeriodSwipe: (_) {},
          onResetToCurrentMonth: () {},
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('summary-pill-container')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('summary scope picker toggles year and month with drag', (
    tester,
  ) async {
    SummaryScopeSelection? applied;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryScopePickerSheet(
            initialSelection: const SummaryScopeSelection(
              yearEnabled: false,
              monthEnabled: false,
              year: 2026,
              month: 5,
            ),
            accentColor: AppColors.primary,
            buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
            onApply: (selection) => applied = selection,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('Hónap-summary-scope-switch')));
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('Év-summary-scope-drag-value')),
      const Offset(0, -80),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('summary-scope-apply-button')));

    expect(applied, isNotNull);
    expect(applied!.yearEnabled, isTrue);
    expect(applied!.monthEnabled, isTrue);
    expect(applied!.year, greaterThan(2026));
    expect(applied!.month, 5);
  });

  testWidgets('summary month row uses category-style selected marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryScopePickerSheet(
            initialSelection: const SummaryScopeSelection(
              yearEnabled: true,
              monthEnabled: true,
              year: 2026,
              month: 5,
            ),
            accentColor: AppColors.primary,
            buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
            onApply: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('summary-scope-month-active-border')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('Év-summary-scope-switch')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('summary-scope-month-active-border')),
      findsNothing,
    );
  });

  testWidgets('search pill shows merchant filter capsule', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          merchantFilter: 'Rrr',
          onClearMerchant: () {},
        ),
      ),
    );

    expect(find.text('2 tranzakció'), findsNothing);
    expect(find.text('Rrr'), findsOneWidget);
  });

  testWidgets('search pill does not render the transaction count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          merchantFilter: 'Rrr',
          onClearMerchant: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('search-pill-filtered-count')),
      findsNothing,
    );
    expect(find.text('2 tranzakció'), findsNothing);
    expect(find.text('Rrr'), findsOneWidget);
  });

  testWidgets('search pill uses configured surface color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.neutralInset,
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-container')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.gray200);
  });

  testWidgets('search pill can disable neutral shadow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          shadowEnabled: false,
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-container')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('search pill text wrapper is transparent for inset profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.insetInset,
        ),
      ),
    );

    final wrapper = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-text-wrapper')),
    );
    final decoration = wrapper.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.filled, isTrue);
    expect(textField.decoration?.fillColor, Colors.transparent);
  });

  testWidgets('focused search pill stays in pressed inset state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.neutralInset,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('search-pill-text-wrapper')));
    await tester.pump(ExpenseSurface.pressDuration);

    BoxDecoration surfaceDecoration() =>
        tester
                .widget<Container>(
                  find.byKey(const ValueKey('search-pill-container')),
                )
                .decoration!
            as BoxDecoration;
    final textField = tester.widget<TextField>(find.byType(TextField));
    var decoration = surfaceDecoration();
    var border = decoration.border! as Border;
    expect(textField.focusNode?.hasFocus, isTrue);
    expect(decoration.color, AppColors.gray200);
    expect(decoration.gradient, isNull);
    expect(decoration.boxShadow, isNull);
    expect(border.top.color, Colors.white.withValues(alpha: 0.62));

    await tester.pump(const Duration(milliseconds: 800));
    decoration = surfaceDecoration();
    border = decoration.border! as Border;
    expect(textField.focusNode?.hasFocus, isTrue);
    expect(decoration.gradient, isNull);
    expect(decoration.boxShadow, isNull);
    expect(border.top.color, Colors.white.withValues(alpha: 0.62));
  });

  testWidgets('search pill shows merchant and category capsules with colors', (
    tester,
  ) async {
    const merchantColor = Color(0xFF0EA5E9);
    const categoryColor = Color(0xFFDC2626);

    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          merchantFilter: 'Rrr',
          merchantFilterColor: merchantColor,
          categoryFilter: 'Q',
          categoryFilterColor: categoryColor,
          onClearMerchant: () {},
          onClearCategory: () {},
        ),
      ),
    );

    final merchantCapsule = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-capsule-merchant-Rrr')),
    );
    final categoryCapsule = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-capsule-category-Q')),
    );

    expect(find.text('2 tranzakció'), findsNothing);
    expect(find.text('Rrr'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    expect(
      (merchantCapsule.decoration! as BoxDecoration).color,
      AppColors.primary,
    );
    expect((categoryCapsule.decoration! as BoxDecoration).color, categoryColor);

    final scrollRight = tester
        .getRect(find.byKey(const ValueKey('search-pill-capsule-scroll')))
        .right;
    final containerRight = tester
        .getRect(find.byKey(const ValueKey('search-pill-container')))
        .right;
    expect(scrollRight, greaterThan(containerRight - 80));
  });

  testWidgets('search pill renders multiple removable filter capsules', (
    tester,
  ) async {
    final cleared = <String>[];
    var vendorPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          child: SearchPill(
            query: '',
            onQueryChanged: (_) {},
            categoryFilters: [
              SearchPillFilter(
                id: '6',
                label: 'Élelmiszer',
                color: AppColors.expense,
                onClear: () => cleared.add('6'),
              ),
              SearchPillFilter(
                id: '7',
                label: 'Közlekedés',
                color: AppColors.primary,
                onClear: () => cleared.add('7'),
              ),
            ],
            onVendorListPressed: () => vendorPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('34560 tranzakció'), findsNothing);
    expect(find.text('Élelmiszer'), findsOneWidget);
    expect(find.text('Közlekedés'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('search-pill-capsule-scroll')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    expect(vendorPressed, isTrue);

    await tester.tap(find.byIcon(Icons.close).first);
    expect(cleared, ['6']);
  });

  testWidgets('vendor list button does not focus the search text field', (
    tester,
  ) async {
    var vendorPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          onVendorListPressed: () => vendorPressed = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pump();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(vendorPressed, isTrue);
    expect(textField.focusNode?.hasFocus, isFalse);

    await tester.tap(find.byKey(const ValueKey('search-pill-text-wrapper')));
    await tester.pump();

    final focusedField = tester.widget<TextField>(find.byType(TextField));
    expect(focusedField.focusNode?.hasFocus, isTrue);
  });

  testWidgets('search pill highlights only the outer border when focused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(query: '', onQueryChanged: (_) {}),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-container')),
    );
    final border = (container.decoration! as BoxDecoration).border! as Border;
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(border.top.color, AppColors.primary);
    expect(field.decoration?.border, InputBorder.none);
    expect(field.decoration?.enabledBorder, InputBorder.none);
    expect(field.decoration?.focusedBorder, InputBorder.none);
  });

  testWidgets('search pill focus does not rebuild the text field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(query: '', onQueryChanged: (_) {}),
      ),
    );

    final fieldBefore = tester.widget<TextField>(find.byType(TextField));

    await tester.tap(find.byKey(const ValueKey('search-pill-text-wrapper')));
    await tester.pump();

    final fieldAfter = tester.widget<TextField>(find.byType(TextField));
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-container')),
    );
    final border = (container.decoration! as BoxDecoration).border! as Border;
    expect(identical(fieldBefore, fieldAfter), isTrue);
    expect(border.top.color, AppColors.primary);
  });

  testWidgets('search pill logs focus performance', (tester) async {
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(query: '', onQueryChanged: (_) {}),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('search-pill-text-wrapper')));
    await tester.pump();
    await tester.pump();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] SearchPill focus request'));
    expect(logs, contains('[Perf] SearchPill focus active=true'));
    expect(logs, contains('[Perf] SearchPill focus frame'));
  });

  testWidgets('search pill skips duplicate focus requests while focused', (
    tester,
  ) async {
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(query: '', onQueryChanged: (_) {}),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    final requestLogs = DebugConsole.allText
        .split('\n')
        .where((line) => line.contains('[Perf] SearchPill focus request'))
        .toList();
    expect(requestLogs, hasLength(1));
  });

  testWidgets('search pill text area focuses and unfocuses outside', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SearchPill(query: '', onQueryChanged: (_) {}),
              const SizedBox(
                key: ValueKey('search-pill-outside-target'),
                height: 120,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('search-pill-text-wrapper')));
    await tester.pump();

    var container = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-container')),
    );
    var border = (container.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, AppColors.primary);

    final outsideTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('search-pill-outside-target')),
    );
    await tester.tapAt(outsideTopLeft + const Offset(12, 12));
    await tester.pump();

    container = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-container')),
    );
    border = (container.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, AppColors.gray200);
  });

  testWidgets('log list groups records by date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 400,
          child: TransactionLogList(
            records: [sampleRecord(), sampleExpenseRecord()],
            categories: [sampleCategory(), sampleExpenseCategory()],
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('2025.09.24'), findsOneWidget);
    expect(find.text('2025.09.25'), findsOneWidget);
  });

  testWidgets('log list accepts custom bottom padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 400,
          child: TransactionLogList(
            records: [sampleRecord()],
            categories: [sampleCategory()],
            bottomPadding: 168,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding! as EdgeInsets;
    expect(padding.bottom, 168);
  });

  testWidgets('log list uses prebuilt entries and category index', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();
    String? filteredCategory;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 400,
          child: TransactionLogList(
            entries: [
              TransactionLogEntry.header(record.date),
              TransactionLogEntry.record(record),
            ],
            categoriesById: {category.transactionCategoryID: category},
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (value) => filteredCategory = value.name,
          ),
        ),
      ),
    );

    expect(find.text('2025.09.24'), findsOneWidget);
    expect(find.text('Gguu'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('transaction-logbox-avatar-250905')),
    );

    expect(filteredCategory, 'Rr');
  });

  testWidgets('transaction log rows avoid scroll-time shadows', (tester) async {
    final record = sampleRecord();
    final category = sampleCategory();

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(record: record, category: category),
      ),
    );

    final rowContainer = tester.widget<Container>(
      find.byKey(ValueKey('transaction-logbox-content-${record.id}')),
    );
    final rowDecoration = rowContainer.decoration! as BoxDecoration;
    expect(rowDecoration.boxShadow, isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: CategoryIconBadge(category: category, showShadow: false),
      ),
    );

    final badgeContainer = tester.widget<Container>(find.byType(Container));
    final badgeDecoration = badgeContainer.decoration! as BoxDecoration;
    expect(badgeDecoration.boxShadow, isNull);
  });

  testWidgets('transaction log rows can opt into neutral shadows', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: record,
          category: category,
          shadowEnabled: true,
        ),
      ),
    );

    final rowContainer = tester.widget<Container>(
      find.byKey(ValueKey('transaction-logbox-content-${record.id}')),
    );
    final rowDecoration = rowContainer.decoration! as BoxDecoration;
    expect(rowDecoration.boxShadow, isNotNull);
  });

  testWidgets('themed pill field renders inset surface in neumorphism', (
    tester,
  ) async {
    final controller = TextEditingController(text: '1200');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ThemedPillField(
          fieldKey: const ValueKey('test-themed-pill-field'),
          debugLabel: 'Test.amount',
          controller: controller,
          label: 'Összeg',
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.insetInset,
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('test-themed-pill-field-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.gray200);
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('transaction log row uses configured surface color and style', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: record,
          category: category,
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.insetInset,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
        ),
      ),
    );

    final rowContainer = tester.widget<Container>(
      find.byKey(ValueKey('transaction-logbox-content-${record.id}')),
    );
    final rowDecoration = rowContainer.decoration! as BoxDecoration;
    expect(rowDecoration.color, AppColors.gray200);
    expect(rowDecoration.gradient, isNull);

    final avatar = tester.widget<GlossyCategoryAvatar>(
      find.byKey(ValueKey('transaction-logbox-avatar-surface-${record.id}')),
    );
    expect(avatar.category, same(category));
    expect(avatar.size, 46);
    expect(avatar.iconSize, 28);
    expect(avatar.iconStrokeWidth, 1.35);
    expect(avatar.debugSource, 'transaction-logbox');
  });

  testWidgets('transaction avatar lets the 3D surface own its background', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: record,
          category: category,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          onCategoryFilter: (_) {},
        ),
      ),
    );

    final badge = tester.widget<CategoryIconBadge>(
      find.byKey(ValueKey('transaction-logbox-avatar-icon-${record.id}')),
    );
    expect(badge.backgroundColor, Colors.transparent);
    expect(badge.showShadow, isFalse);
    expect(badge.iconStrokeWidth, 1.35);
  });

  testWidgets(
    'logbox avatar keeps stable public keys across parent refreshes',
    (tester) async {
      final record = sampleRecord();
      final category = sampleCategory();
      late StateSetter refresh;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return TransactionLogBox(record: record, category: category);
            },
          ),
        ),
      );

      final avatarFinder = find.byKey(
        ValueKey('transaction-logbox-avatar-surface-${record.id}'),
      );
      final iconFinder = find.byKey(
        ValueKey('transaction-logbox-avatar-icon-${record.id}'),
      );
      final beforeAvatar = tester.widget<GlossyCategoryAvatar>(avatarFinder);
      final before = tester.widget<CategoryIconBadge>(iconFinder);
      expect(
        find.descendant(
          of: avatarFinder,
          matching: find.byType(CategoryIconBadge),
        ),
        findsOneWidget,
      );

      refresh(() {});
      await tester.pump();

      final afterAvatar = tester.widget<GlossyCategoryAvatar>(avatarFinder);
      final after = tester.widget<CategoryIconBadge>(iconFinder);
      expect(afterAvatar.key, beforeAvatar.key);
      expect(after.key, before.key);
      expect(after.category, same(category));
      expect(after.iconStrokeWidth, 1.35);
    },
  );

  test('category slot icon rewrites stroke width without changing size', () {
    const svg =
        '<svg width="24" height="24" stroke-width="2"><path d="M0 0"/></svg>';

    final rewritten = rewriteCategoryIconStrokeWidth(svg, 1.35);

    expect(rewritten, contains('width="24"'));
    expect(rewritten, contains('height="24"'));
    expect(rewritten, contains('stroke-width="1.35"'));
  });

  testWidgets('category slot icon does not flash material fallback icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CategorySlotIcon(
          slot: 2,
          color: AppColors.white,
          size: 32,
          strokeWidth: 1.35,
        ),
      ),
    );

    expect(find.byIcon(Icons.category_outlined), findsNothing);
    expect(find.byType(CategorySlotIcon), findsOneWidget);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.byType(SvgPicture), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: KeyedSubtree(
          key: ValueKey('refreshed-icon-root'),
          child: CategorySlotIcon(
            slot: 2,
            color: AppColors.white,
            size: 32,
            strokeWidth: 1.35,
          ),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('log list renders uncategorized transaction question avatar', (
    tester,
  ) async {
    final record = TransactionRecord.fromMap({
      'id': 26060701,
      'date': '2026.06.07',
      'time': '21:10',
      'merchant': 'Tesco',
      'amount': -12345,
      'userAssignedName': null,
      'transactionCategoryID': null,
      'sourceNotificationEventId': 77,
    });
    var categoryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 220,
          child: TransactionLogList(
            entries: [
              TransactionLogEntry.header(record.date),
              TransactionLogEntry.record(record),
            ],
            categories: [sampleExpenseCategory()],
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) => categoryTapped = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.question_mark), findsOneWidget);
    final question = tester.widget<Icon>(find.byIcon(Icons.question_mark));
    expect(question.color, AppColors.white);

    final avatar = tester.widget<GlossyCategoryAvatar>(
      find.byKey(ValueKey('transaction-logbox-avatar-surface-${record.id}')),
    );
    expect(avatar.category, isNull);
    expect(avatar.showQuestionMark, isTrue);
    expect(avatar.size, 46);

    await tester.tap(
      find.byKey(ValueKey('transaction-logbox-avatar-${record.id}')),
    );
    expect(categoryTapped, isFalse);
  });

  testWidgets('avatar press does not press the whole logbox surface', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();
    var bodyTaps = 0;
    var categoryTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: record,
          category: category,
          surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          onTap: (_) => bodyTaps += 1,
          onCategoryFilter: (_) => categoryTaps += 1,
        ),
      ),
    );

    final rowFinder = find.byKey(
      ValueKey('transaction-logbox-content-${record.id}'),
    );
    final avatarSurfaceFinder = find.byKey(
      ValueKey('transaction-logbox-avatar-surface-${record.id}'),
    );
    final releasedRowDecoration =
        tester.widget<Container>(rowFinder).decoration! as BoxDecoration;
    final releasedAvatar = tester.widget<GlossyCategoryAvatar>(
      avatarSurfaceFinder,
    );
    expect(releasedAvatar.selected, isFalse);

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(ValueKey('transaction-logbox-avatar-${record.id}')),
      ),
    );
    await tester.pump();

    final rowDecoration =
        tester.widget<Container>(rowFinder).decoration! as BoxDecoration;
    final pressedAvatar = tester.widget<GlossyCategoryAvatar>(
      avatarSurfaceFinder,
    );
    expect(rowDecoration, releasedRowDecoration);
    expect(pressedAvatar.selected, isTrue);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(categoryTaps, 1);
    expect(bodyTaps, 0);
  });

  testWidgets('logbox body press moves the card and avatar together', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();
    var bodyTaps = 0;
    var categoryTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: record,
          category: category,
          surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          onTap: (_) => bodyTaps += 1,
          onCategoryFilter: (_) => categoryTaps += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardFinder = find.byKey(
      ValueKey('transaction-logbox-content-${record.id}'),
    );
    final avatarFinder = find.byKey(
      ValueKey('transaction-logbox-avatar-surface-${record.id}'),
    );
    final cardRect = tester.getRect(cardFinder);
    final releasedDecoration =
        tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
    final releasedAvatar = tester.widget<GlossyCategoryAvatar>(avatarFinder);
    expect(releasedAvatar.selected, isFalse);

    final gesture = await tester.startGesture(
      Offset(cardRect.right - 12, cardRect.top + 12),
    );
    await tester.pump();

    final pressedDecoration =
        tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
    final pressedAvatar = tester.widget<GlossyCategoryAvatar>(avatarFinder);
    expect(pressedDecoration, isNot(releasedDecoration));
    expect(pressedAvatar.selected, isTrue);

    await gesture.up();
    await tester.pumpAndSettle();

    final finalDecoration =
        tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
    final finalAvatar = tester.widget<GlossyCategoryAvatar>(avatarFinder);
    expect(finalDecoration.boxShadow, isNotNull);
    expect(finalAvatar.selected, isFalse);
    expect(bodyTaps, 1);
    expect(categoryTaps, 0);
  });

  testWidgets(
    'body press drives avatar when only avatar surface is pressable',
    (tester) async {
      final record = sampleRecord();
      final category = sampleCategory();
      var bodyTaps = 0;
      var categoryTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: TransactionLogBox(
            record: record,
            category: category,
            surfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
            avatarSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
            onTap: (_) => bodyTaps += 1,
            onCategoryFilter: (_) => categoryTaps += 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(
        ValueKey('transaction-logbox-content-${record.id}'),
      );
      final avatarFinder = find.byKey(
        ValueKey('transaction-logbox-avatar-surface-${record.id}'),
      );
      final cardRect = tester.getRect(cardFinder);
      final releasedDecoration =
          tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
      final releasedAvatar = tester.widget<GlossyCategoryAvatar>(avatarFinder);
      expect(releasedAvatar.selected, isFalse);

      final gesture = await tester.startGesture(
        Offset(cardRect.right - 12, cardRect.top + 12),
      );
      await tester.pump();

      final pressedDecoration =
          tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
      final pressedAvatar = tester.widget<GlossyCategoryAvatar>(avatarFinder);
      expect(pressedDecoration, isNot(releasedDecoration));
      expect(pressedAvatar.selected, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(bodyTaps, 1);
      expect(categoryTaps, 0);
    },
  );

  testWidgets('transaction log rows do not build swipe overlays while idle', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onFastFilter: (_, _) {},
          onDeleteRequested: (_) => false,
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('transaction-logbox-delete-border-250905')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('transaction-logbox-filter-border-250905')),
      findsNothing,
    );
  });

  testWidgets('log list waits until close to bottom before loading more', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();
    var loadMoreCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 220,
          child: TransactionLogList(
            entries: [
              TransactionLogEntry.header(record.date),
              TransactionLogEntry.record(record),
            ],
            categoriesById: {category.transactionCategoryID: category},
            hasMore: true,
            onLoadMore: () => loadMoreCount += 1,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(ListView));
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1200,
      pixels: 500,
      viewportDimension: 220,
      axisDirection: AxisDirection.down,
      devicePixelRatio: tester.view.devicePixelRatio,
    );

    ScrollUpdateNotification(
      metrics: metrics,
      context: context,
    ).dispatch(context);
    await tester.pump();

    expect(loadMoreCount, 0);
  });

  testWidgets('log list writes scroll telemetry around load more', (
    tester,
  ) async {
    DebugConsole.clear();
    final record = sampleRecord();
    final category = sampleCategory();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 220,
          child: TransactionLogList(
            entries: [
              TransactionLogEntry.header(record.date),
              TransactionLogEntry.record(record),
            ],
            categoriesById: {category.transactionCategoryID: category},
            hasMore: true,
            onLoadMore: () {},
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(ListView));
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1200,
      pixels: 900,
      viewportDimension: 220,
      axisDirection: AxisDirection.down,
      devicePixelRatio: tester.view.devicePixelRatio,
    );

    ScrollStartNotification(
      metrics: metrics,
      context: context,
    ).dispatch(context);
    ScrollUpdateNotification(
      metrics: metrics,
      context: context,
    ).dispatch(context);
    await tester.pump();

    var logs = DebugConsole.allText;
    expect(logs, contains('[Perf] LogList build'));
    expect(logs, contains('[Perf] LogScroll start'));
    expect(logs, contains('[Perf] LogScroll update'));
    expect(logs, contains('[Perf] LogScroll load-more pending'));
    expect(logs, isNot(contains('[Perf] LogScroll load-more fire')));

    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    logs = DebugConsole.allText;
    expect(logs, contains('[Perf] LogScroll load-more fire'));
    expect(logs, contains('reason=scroll-end'));
    expect(logs, contains('[Perf] LogScroll end'));
  });

  testWidgets('log list throttles load more while threshold remains crossed', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();
    var loadMoreCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 220,
          child: TransactionLogList(
            entries: [
              TransactionLogEntry.header(record.date),
              TransactionLogEntry.record(record),
            ],
            categoriesById: {category.transactionCategoryID: category},
            hasMore: true,
            onLoadMore: () => loadMoreCount += 1,
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(ListView));
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1200,
      pixels: 900,
      viewportDimension: 220,
      axisDirection: AxisDirection.down,
      devicePixelRatio: tester.view.devicePixelRatio,
    );

    for (var i = 0; i < 3; i += 1) {
      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
      ).dispatch(context);
    }
    await tester.pump();

    expect(loadMoreCount, 0);

    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(loadMoreCount, 1);

    final listView = tester.widget<ListView>(find.byType(ListView));
    final childDelegate =
        listView.childrenDelegate as SliverChildBuilderDelegate;
    // ignore: deprecated_member_use
    expect(listView.cacheExtent, lessThanOrEqualTo(500));
    // ignore: deprecated_member_use
    expect(listView.cacheExtent, greaterThanOrEqualTo(300));
    expect(childDelegate.addAutomaticKeepAlives, isFalse);
    expect(childDelegate.addSemanticIndexes, isFalse);
  });

  testWidgets('log list declares stable extents for scroll performance', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 260,
          child: TransactionLogList(
            entries: [
              TransactionLogEntry.header(record.date),
              TransactionLogEntry.record(record),
            ],
            categoriesById: {category.transactionCategoryID: category},
            hasMore: true,
            onLoadMore: () {},
            onFastFilter: (_, _) {},
            onRecordTap: (_) {},
            onDeleteRequested: (_) => true,
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    final dimensions = SliverLayoutDimensions(
      scrollOffset: 0,
      precedingScrollExtent: 0,
      viewportMainAxisExtent: 260,
      crossAxisExtent: tester.view.physicalSize.width,
    );

    expect(listView.itemExtentBuilder, isNotNull);
    expect(listView.itemExtentBuilder!(0, dimensions), 34);
    expect(listView.itemExtentBuilder!(1, dimensions), 80);
  });

  testWidgets('logbox left swipe triggers fast filter with category', (
    tester,
  ) async {
    String? merchant;
    String? categoryName;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onFastFilter: (record, category) {
            merchant = record.displayMerchant;
            categoryName = category?.name;
          },
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('transaction-logbox-250905')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(merchant, 'Gguu');
    expect(categoryName, 'Rr');
  });

  testWidgets('logbox tap requests edit and right swipe requests delete', (
    tester,
  ) async {
    int? editedId;
    int? deletedId;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onTap: (record) => editedId = record.id,
          onDeleteRequested: (record) {
            deletedId = record.id;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('+5 555 Ft'));
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('transaction-logbox-content-250905')),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();

    expect(editedId, 250905);
    expect(deletedId, 250905);
  });

  testWidgets('logbox swipe slides the card and colors the border', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onFastFilter: (_, _) {},
          onDeleteRequested: (_) => true,
        ),
      ),
    );

    final cardFinder = find.byKey(
      const ValueKey('transaction-logbox-card-250905'),
    );
    final gesture = await tester.startGesture(tester.getCenter(cardFinder));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(42, 0));
    await tester.pump(const Duration(milliseconds: 80));

    final cardTransform = tester.widget<Transform>(cardFinder);
    final deleteBorder = tester.widget<Opacity>(
      find.byKey(const ValueKey('transaction-logbox-delete-border-250905')),
    );
    expect(cardTransform.transform.getTranslation().x, greaterThan(35));
    expect(deleteBorder.opacity, greaterThan(0));
    expect(
      find.byKey(const ValueKey('transaction-logbox-filter-border-250905')),
      findsNothing,
    );

    await gesture.up();
  });

  testWidgets('logbox right swipe freezes until delete is canceled', (
    tester,
  ) async {
    final deleteDecision = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onDeleteRequested: (_) => deleteDecision.future,
        ),
      ),
    );

    final cardFinder = find.byKey(
      const ValueKey('transaction-logbox-card-250905'),
    );
    await tester.drag(
      find.byKey(const ValueKey('transaction-logbox-content-250905')),
      const Offset(600, 0),
    );
    await tester.pump();

    expect(
      tester.widget<Transform>(cardFinder).transform.getTranslation().x,
      greaterThan(0),
    );

    deleteDecision.complete(false);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Transform>(cardFinder).transform.getTranslation().x,
      0,
    );
  });

  testWidgets('logbox swipe borders match the translated card bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onDeleteRequested: (_) => false,
        ),
      ),
    );

    final rowFinder = find.byKey(const ValueKey('transaction-logbox-250905'));
    final gesture = await tester.startGesture(tester.getCenter(rowFinder));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(42, 0));
    await tester.pump();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('transaction-logbox-content-250905')),
    );
    final borderRect = tester.getRect(
      find.byKey(const ValueKey('transaction-logbox-delete-border-250905')),
    );

    expect(borderRect.width, moreOrLessEquals(cardRect.width, epsilon: 0.1));
    expect(borderRect.height, moreOrLessEquals(cardRect.height, epsilon: 0.1));

    await gesture.up();
  });

  testWidgets('logbox avatar tap requests category filter', (tester) async {
    String? categoryName;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onCategoryFilter: (category) => categoryName = category.name,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('transaction-logbox-avatar-250905')),
    );
    await tester.pump();

    expect(categoryName, 'Rr');
  });

  testWidgets('logbox category avatar hides top semicircle highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
        ),
      ),
    );

    final avatar = tester.widget<GlossyCategoryAvatar>(
      find.byKey(const ValueKey('transaction-logbox-avatar-surface-250905')),
    );

    expect((avatar as dynamic).showTopHighlight, isFalse);
  });

  testWidgets('logbox surfaces do not spam debug logs while released', (
    tester,
  ) async {
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          surfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
          onTap: (_) {},
          onCategoryFilter: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(
      DebugConsole.allText,
      isNot(contains('surface key=transaction-logbox-content-250905')),
    );
    expect(
      DebugConsole.allText,
      isNot(contains('surface key=transaction-logbox-avatar-surface-250905')),
    );

    await tester.tap(
      find.byKey(const ValueKey('transaction-logbox-content-250905')),
    );
    await tester.pump();

    expect(
      DebugConsole.allText,
      contains(
        'surface key=transaction-logbox-content-250905 style=neutralInset',
      ),
    );
    final avatar = tester.widget<GlossyCategoryAvatar>(
      find.byKey(const ValueKey('transaction-logbox-avatar-surface-250905')),
    );
    expect(avatar.selected, isTrue);
  });

  testWidgets(
    'logbox body tap renders neumorph body and avatar press together',
    (tester) async {
      DebugConsole.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: TransactionLogBox(
            record: sampleRecord(),
            category: sampleCategory(),
            surfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
            avatarSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
            onTap: (_) {},
            onCategoryFilter: (_) {},
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('transaction-logbox-content-250905')),
      );
      await tester.pump();

      expect(
        DebugConsole.allText,
        contains(
          'surface key=transaction-logbox-content-250905 style=neutralInset',
        ),
      );
      expect(
        DebugConsole.allText,
        contains(
          'surface key=transaction-logbox-content-250905 style=neutralInset '
          'profile=standard color=#ffffffff primary=false pressed=true '
          'offset=0,2',
        ),
      );
      final avatar = tester.widget<GlossyCategoryAvatar>(
        find.byKey(const ValueKey('transaction-logbox-avatar-surface-250905')),
      );
      expect(avatar.selected, isTrue);

      DebugConsole.clear();
      await tester.tap(
        find.byKey(const ValueKey('transaction-logbox-avatar-250905')),
      );
      await tester.pump();

      expect(
        DebugConsole.allText,
        isNot(
          contains(
            'surface key=transaction-logbox-content-250905 '
            'style=neutralInset profile=standard color=#ffffffff '
            'primary=false pressed=true',
          ),
        ),
      );
    },
  );

  testWidgets(
    'transaction logbox merchant name opens edit transaction not rename dialog',
    (tester) async {
      final record = sampleRecord();
      final category = sampleCategory();
      TransactionRecord? edited;
      var renamed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TransactionLogBox(
            record: record,
            category: category,
            surfaceStyle: ExpenseSurfaceInteraction.insetInset,
            avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            onTap: (value) => edited = value,
            onRenameMerchant: (_, _) async => renamed = true,
            onCategoryFilter: (_) {},
          ),
        ),
      );

      await tester.tap(
        find.byKey(ValueKey('transaction-logbox-name-${record.id}')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(edited?.id, record.id);
      expect(renamed, isFalse);
      expect(
        find.byKey(const ValueKey('transaction-name-editor-field')),
        findsNothing,
      );
    },
  );

  testWidgets('custom transaction name shows reset button and darker style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onResetMerchantName: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('transaction-name-reset-250905')),
      findsOneWidget,
    );
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('transaction-logbox-name-text-250905')),
    );
    expect(text.style?.color, AppColors.gray800);
  });
}

TransactionRecord sampleRecord() => TransactionRecord.fromMap({
  'id': 250905,
  'date': '2025.09.24',
  'time': '21:56',
  'merchant': 'Rrteeaawwq',
  'amount': 5555,
  'userAssignedName': 'Gguu',
  'transactionCategoryID': 5,
});

TransactionCategory sampleCategory() => TransactionCategory.fromMap({
  'transactionCategoryID': 5,
  'name': 'Rr',
  'type': 'bevétel',
  'colorSlot': 2,
  'iconSlot': 0,
  'backgroundColor': '#3b82f6',
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': true,
});

TransactionRecord sampleExpenseRecord() => TransactionRecord.fromMap({
  'id': 250909,
  'date': '2025.09.25',
  'time': '20:30:00',
  'merchant': 'Test Store',
  'amount': -505,
  'userAssignedName': null,
  'transactionCategoryID': 6,
});

TransactionCategory sampleExpenseCategory() => TransactionCategory.fromMap({
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
});
