import 'package:exptv2/features/transactions/data/limit_allocation_manager.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pie chart renders allocation and taps category slice', (
    tester,
  ) async {
    int? tappedTarget;
    final bars = [barFixture(6, 'Food', spent: 25, limit: 50)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LimitAllocationPieChart(
            allocation: LimitAllocationManager.build(
              overviewLimit: 100,
              bars: bars,
            ),
            onSliceTap: (targetId) => tappedTarget = targetId,
            onSliceAmountChanged: (_, __) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('limit-allocation-pie-chart')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('limit-allocation-pie-chart')));
    expect(tappedTarget, 6);
  });

  testWidgets('pie chart horizontal drag reports snapped category amount', (
    tester,
  ) async {
    final changes = <double>[];
    final bars = [barFixture(6, 'Food', spent: 25, limit: 50)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LimitAllocationPieChart(
            allocation: LimitAllocationManager.build(
              overviewLimit: 100000,
              bars: bars,
            ),
            onSliceTap: (_) {},
            onSliceAmountChanged: (_, amount) => changes.add(amount),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('limit-allocation-pie-chart')),
      const Offset(45, 0),
    );
    await tester.pump();
    expect(changes, isNotEmpty);
    expect(changes.last % 1000, 0);
  });
}

CategoryBudgetBarData barFixture(
  int id,
  String title, {
  required double spent,
  required double limit,
}) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#0ea5e9',
    'hasLimit': limit > 0,
    'limitAmount': limit,
    'alertActive': false,
    'isCustomIcon': true,
  });
  return CategoryBudgetBarData(
    key: 'category-$id',
    targetType: LimitTargetType.category,
    targetId: id,
    transactionType: category.normalizedType,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    title: title,
    spent: spent,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: false,
    color: const Color(0xfffacc15),
    iconSlot: category.iconSlot,
    category: category,
    sourceLimit: null,
  );
}
