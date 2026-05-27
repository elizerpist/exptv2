import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/widgets/search_pill.dart';
import 'package:exptv2/features/transactions/widgets/summary_pill.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_box.dart';
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

  testWidgets('search pill shows merchant and category capsules with colors', (tester) async {
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
    expect(
      (merchantCapsule.decoration! as BoxDecoration).color,
      merchantColor,
    );
    expect(
      (categoryCapsule.decoration! as BoxDecoration).color,
      categoryColor,
    );
  });

  testWidgets('search pill highlights outer border when focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          filteredCount: 0,
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final container = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-container')),
    );
    final border = (container.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, AppColors.primary);
  });

  testWidgets('logbox left swipe triggers fast filter', (tester) async {
    String? merchant;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: sampleRecord(),
          category: sampleCategory(),
          onFastFilter: (value) => merchant = value,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('transaction-logbox-250905')),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(merchant, 'Gguu');
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
