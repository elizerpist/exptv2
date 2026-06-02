import 'dart:async';

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_icon_badge.dart';
import 'package:exptv2/features/transactions/widgets/search_pill.dart';
import 'package:exptv2/features/transactions/widgets/summary_pill.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_box.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_list.dart';
import 'package:exptv2/features/transactions/widgets/transaction_type_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('search pill shows merchant filter capsule', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          merchantFilter: 'Rrr',
          filteredCount: 2,
          onClearMerchant: () {},
        ),
      ),
    );

    expect(find.text('2 tranzakció találva'), findsOneWidget);
    expect(find.text('Rrr'), findsOneWidget);
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
          filteredCount: 2,
          onClearMerchant: () {},
          onClearCategory: () {},
        ),
      ),
    );

    final merchantCapsule = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-capsule-merchant')),
    );
    final categoryCapsule = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-capsule-category')),
    );

    expect(find.text('2 tranzakció találva'), findsOneWidget);
    expect(find.text('Rrr'), findsOneWidget);
    expect(find.text('Q'), findsOneWidget);
    expect((merchantCapsule.decoration! as BoxDecoration).color, merchantColor);
    expect((categoryCapsule.decoration! as BoxDecoration).color, categoryColor);

    final categoryRight = tester
        .getRect(find.byKey(const ValueKey('search-pill-capsule-category')))
        .right;
    final inputLeft = tester.getRect(find.byType(TextField)).left;
    expect(categoryRight, lessThan(inputLeft));
  });

  testWidgets('search pill highlights only the outer border when focused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(query: '', onQueryChanged: (_) {}, filteredCount: 0),
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

  testWidgets('search pill logs focus performance', (tester) async {
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(query: '', onQueryChanged: (_) {}, filteredCount: 0),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('search-pill-container')));
    await tester.pump();
    await tester.pump();

    final logs = DebugConsole.allText;
    expect(logs, contains('[Perf] SearchPill focus request'));
    expect(logs, contains('[Perf] SearchPill focus active=true'));
    expect(logs, contains('[Perf] SearchPill focus frame'));
  });

  testWidgets('search pill focuses from the whole pill and unfocuses outside', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SearchPill(query: '', onQueryChanged: (_) {}, filteredCount: 0),
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

    await tester.tap(find.byKey(const ValueKey('search-pill-container')));
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
    expect(cardTransform.transform.getTranslation().x, greaterThan(0));
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

  testWidgets(
    'logbox name tap opens name editor without opening transaction editor',
    (tester) async {
      var editOpened = false;
      String? renamedMerchant;
      await tester.pumpWidget(
        MaterialApp(
          home: TransactionLogBox(
            record: sampleExpenseRecord(),
            category: sampleExpenseCategory(),
            onTap: (_) => editOpened = true,
            onRenameMerchant: (record, value) async {
              renamedMerchant = '${record.merchant}:$value';
            },
            onResetMerchantName: (_) {},
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('transaction-logbox-name-250909')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('transaction-name-editor-field')),
        'Test Market Custom',
      );
      await tester.tap(
        find.byKey(const ValueKey('transaction-name-editor-save')),
      );
      await tester.pumpAndSettle();

      expect(editOpened, isFalse);
      expect(renamedMerchant, 'Test Store:Test Market Custom');
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
