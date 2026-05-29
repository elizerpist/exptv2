import 'package:exptv2/features/transactions/data/limit_allocation_manager.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allocation splits used remaining and free overview budget', () {
    final food = barFixture(6, 'Food', spent: 25, limit: 50);
    final travel = barFixture(7, 'Travel', spent: 10, limit: 20);

    final data = LimitAllocationManager.build(
      overviewLimit: 100,
      bars: [food, travel],
    );

    expect(data.overviewLimit, 100);
    expect(data.allocatedAmount, 70);
    expect(data.freeAmount, 30);
    expect(
      data.segments.map((segment) => segment.amount),
      [25, 25, 10, 10, 30],
    );
    expect(data.segments.map((segment) => segment.kind.name), [
      'used',
      'remaining',
      'used',
      'remaining',
      'free',
    ]);
    expect(data.segments.first.targetId, 6);
    expect(data.segments.last.targetId, isNull);
  });

  test('available category max includes active category current allocation', () {
    final food = barFixture(6, 'Food', spent: 25, limit: 50);
    final travel = barFixture(7, 'Travel', spent: 10, limit: 50);

    expect(
      LimitAllocationManager.categorySliderMax(
        overviewLimit: 100,
        bars: [food, travel],
        activeBar: food,
      ),
      50,
    );
  });

  test('new category slider disables when overview allocation is full', () {
    final food = barFixture(6, 'Food', spent: 25, limit: 100);
    final travel = barFixture(7, 'Travel', spent: 0, limit: 0);

    expect(
      LimitAllocationManager.categorySliderEnabled(
        overviewLimit: 100,
        bars: [food, travel],
        activeBar: travel,
      ),
      isFalse,
    );
  });

  test('slider snapping uses 1000 HUF steps without changing manual values', () {
    expect(LimitAllocationManager.snapSliderAmount(1499), 1000);
    expect(LimitAllocationManager.snapSliderAmount(1500), 2000);
    expect(LimitAllocationManager.sliderDivisions(12500), 13);
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
    color: colorFor(id),
    iconSlot: category.iconSlot,
    category: category,
    sourceLimit: null,
  );
}

Color colorFor(int id) => switch (id) {
  6 => const Color(0xfffacc15),
  7 => const Color(0xff38bdf8),
  _ => const Color(0xff94a3b8),
};
