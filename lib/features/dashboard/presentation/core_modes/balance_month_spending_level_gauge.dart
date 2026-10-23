import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/dashboard_balance_month_spending_level_projection.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_clay_semicircle_gauge.dart';

/// A semantic adapter to the canonical Budget gauge, not a second renderer.
final class BalanceMonthSpendingLevelGauge extends StatelessWidget {
  const BalanceMonthSpendingLevelGauge({super.key, required this.presentation});

  final DashboardBalanceMonthSpendingLevelPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final ratio = presentation.ratio;
    if (ratio == null) {
      return Center(
        child: Text(
          switch (presentation.status) {
            DashboardBalanceMonthSpendingLevelStatus.future =>
              'A hónap még nem kezdődött el',
            DashboardBalanceMonthSpendingLevelStatus.zeroReference =>
              'A korábbi hónapok kiadási szintje nulla',
            _ => 'Még nincs elegendő összehasonlítható előzmény',
          },
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final gauge = BudgetSemicircleGauge(
      presentation: BudgetSemicircleMaterialPresentation.resolve(
        rawRatio: ratio,
        direction: LedgerDirection.expense,
        activeGradient: BudgetClayGaugeAccentResolver.resolve(
          context,
          direction: LedgerDirection.expense,
        ),
      ),
      primaryLabel: '${(ratio * 100).round()}%',
      secondaryLabel: 'Megszokott kiadási szint',
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.isFinite || (size.width >= 220 && size.height >= 125)) {
          return gauge;
        }
        // Preserve the actual Budget component, scaling its entire scene
        // together only when its fixed typography cannot fit the small slot.
        final scale = math.min(size.width / 220, size.height / 125);
        if (scale <= 0) return const SizedBox.shrink();
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: size.width / scale,
            height: size.height / scale,
            child: gauge,
          ),
        );
      },
    );
  }
}
