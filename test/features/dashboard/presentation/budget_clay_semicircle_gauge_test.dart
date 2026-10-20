import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';

void main() {
  const accent = <Color>[
    Color(0xFF22D3EE),
    Color(0xFF2BC4F3),
    Color(0xFF39B8F4),
  ];

  test('expense overshoot keeps warning and danger zones distinct', () {
    final presentation = BudgetClayGaugePresentation.resolve(
      rawRatio: 1.15,
      direction: LedgerDirection.expense,
      activeGradient: accent,
    );

    expect(presentation.rawRatio, 1.15);
    expect(presentation.visualProgress, closeTo(1.15 / 1.20, .0001));
    expect(presentation.health, BudgetClayGaugeHealth.expenseDanger);
    expect(presentation.overshootZones, hasLength(2));
    expect(
      presentation.overshootZones.last.colors.last,
      const Color(0xFFDC2626),
    );
  });

  test('income over target is a positive zone, never expense danger', () {
    final presentation = BudgetClayGaugePresentation.resolve(
      rawRatio: 1.16,
      direction: LedgerDirection.income,
      activeGradient: accent,
    );

    expect(presentation.health, BudgetClayGaugeHealth.incomeExceededTarget);
    expect(presentation.overshootZones, hasLength(1));
    expect(
      presentation.overshootZones.single.colors,
      isNot(contains(const Color(0xFFDC2626))),
    );
    expect(presentation.hasVisualOverflow, isFalse);
  });

  test('visual progress clamps at 120 percent without losing raw value', () {
    final presentation = BudgetClayGaugePresentation.resolve(
      rawRatio: 1.53,
      direction: LedgerDirection.expense,
      activeGradient: accent,
    );

    expect(presentation.rawRatio, 1.53);
    expect(presentation.visualProgress, 1);
    expect(presentation.hasVisualOverflow, isTrue);
  });
}
