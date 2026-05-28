import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/widgets/search_pill.dart';
import 'package:exptv2/features/transactions/widgets/summary_pill.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_box.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_list.dart';
import 'package:exptv2/features/transactions/widgets/transaction_type_pills.dart';
import 'package:flutter/material.dart';
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

  testWidgets('summary pill cycles when dragged horizontally', (tester) async {
    var cycles = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Kiadások',
          value: '-66 Ft',
          onSwipe: () => cycles += 1,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(90, 0),
    );
    await tester.pumpAndSettle();
    expect(cycles, 1);
  });

  testWidgets('summary pill vertical swipe requests period changes', (
    tester,
  ) async {
    final periods = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryPill(
          title: 'Március 2026',
          value: '-66 Ft',
          onSwipe: () {},
          onVerticalSwipe: periods.add,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, 90),
    );
    await tester.pumpAndSettle();

    expect(periods, [1, -1]);
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
            onDeleteRequested: (_) {},
            onCategoryFilter: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('2025.09.24'), findsOneWidget);
    expect(find.text('2025.09.25'), findsOneWidget);
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
          onDeleteRequested: (record) => deletedId = record.id,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('transaction-logbox-250905')));
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('transaction-logbox-250905')),
      const Offset(120, 0),
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
          onDeleteRequested: (_) {},
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
    final filterBorder = tester.widget<Opacity>(
      find.byKey(const ValueKey('transaction-logbox-filter-border-250905')),
    );

    expect(cardTransform.transform.getTranslation().x, greaterThan(0));
    expect(deleteBorder.opacity, greaterThan(0));
    expect(filterBorder.opacity, 0);

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
