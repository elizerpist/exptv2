import 'package:exptv2/features/transactions/data/limit_manager.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/header_card/category_budget_stage.dart';
import 'package:exptv2/features/transactions/widgets/header_card/category_limit_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category budget stage shows and swipes category bars', (
    tester,
  ) async {
    CategoryBudgetBarData? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              bars: [
                barFixture(6, 'Food', 100, 150),
                barFixture(7, 'Travel', 40, 0),
              ],
              onBarTap: (bar) => tapped = bar,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('100 Ft / 150 Ft'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-budget-progress-text')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-budget-dot-0')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('category-budget-bar')),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('40 Ft'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    expect(tapped?.title, 'Travel');
  });

  testWidgets(
    'stage summary outline uses equal partition units before limits are set',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 260,
              child: CategoryBudgetStage(
                bars: [
                  barFixture(6, 'Food', 100, 0),
                  barFixture(7, 'Travel', 40, 0),
                  barFixture(8, 'Bills', 20, 0),
                ],
                onBarTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('category-summary-outline-bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-summary-segment-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-summary-segment-1')),
        findsOneWidget,
      );

      final outlineWidth = tester
          .getSize(find.byKey(const ValueKey('category-summary-outline-bar')))
          .width;
      final activeBarWidth = tester
          .getSize(find.byKey(const ValueKey('category-budget-bar')))
          .width;
      final firstSegmentWidth = tester
          .getSize(find.byKey(const ValueKey('category-summary-segment-0')))
          .width;
      final secondSegmentWidth = tester
          .getSize(find.byKey(const ValueKey('category-summary-segment-1')))
          .width;

      expect(activeBarWidth, lessThan(outlineWidth));
      expect(
        firstSegmentWidth,
        moreOrLessEquals(secondSegmentWidth, epsilon: 1),
      );
    },
  );

  testWidgets('category limit editor saves input and reset clears limit', (
    tester,
  ) async {
    double? savedAmount;
    bool? savedAlert;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryLimitEditorSheet(
            bar: barFixture(6, 'Food', 100, 150),
            onCancel: () {},
            onSave: ({required limitAmount, required alertActive}) async {
              savedAmount = limitAmount;
              savedAlert = alertActive;
            },
          ),
        ),
      ),
    );

    expect(find.text('Food limit'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '250',
    );
    await tester.tap(find.byKey(const ValueKey('limit-alert-toggle')));
    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    expect(savedAmount, 250);
    expect(savedAlert, isFalse);

    await tester.tap(find.byKey(const ValueKey('limit-reset-button')));
    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();
    expect(savedAmount, 0);
  });

  testWidgets('category limit editor slider updates the limit amount', (
    tester,
  ) async {
    double? savedAmount;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryLimitEditorSheet(
            bar: barFixture(6, 'Food', 100, 0),
            onCancel: () {},
            onSave: ({required limitAmount, required alertActive}) async {
              savedAmount = limitAmount;
            },
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-limit-slider')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('category-limit-slider')),
      const Offset(220, 0),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    expect(savedAmount, isNotNull);
    expect(savedAmount!, greaterThan(0));
  });

  testWidgets('progress bar uses limit manager threshold color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryBudgetStage(
            bars: [barFixture(6, 'Food', 90, 100)],
            onBarTap: (_) {},
          ),
        ),
      ),
    );

    final fill = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('category-progress-fill')),
    );
    final decoration = fill.decoration as BoxDecoration;
    expect(decoration.color, LimitManager.warningColor);
  });
}

CategoryBudgetBarData barFixture(
  int id,
  String title,
  double spent,
  double limit,
) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#0ea5e9',
    'hasLimit': limit > 0,
    'limitAmount': limit,
    'alertActive': true,
    'isCustomIcon': true,
  });
  return CategoryBudgetBarData(
    key: 'category-$id',
    targetType: LimitTargetType.category,
    targetId: id,
    transactionType: TransactionType.expense,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    title: title,
    spent: spent,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: true,
    color: category.slotColor,
    iconSlot: category.iconSlot,
    category: category,
    sourceLimit: null,
  );
}
