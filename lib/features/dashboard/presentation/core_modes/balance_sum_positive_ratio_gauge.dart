import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../query/domain/ledger_direction.dart';
import 'budget_clay_semicircle_gauge.dart';

/// A semantic adapter to the canonical Budget gauge, not a second renderer.
final class BalanceSumPositiveRatioGauge extends StatelessWidget {
  const BalanceSumPositiveRatioGauge({
    super.key,
    required this.positiveCount,
    required this.sampleCount,
  }) : assert(positiveCount >= 0),
       assert(sampleCount >= 0),
       assert(positiveCount <= sampleCount);

  final int positiveCount;
  final int sampleCount;

  @override
  Widget build(BuildContext context) {
    if (sampleCount == 0) {
      return Center(
        child: Text(
          'Még nincs értékelhető hónap',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final ratio = positiveCount / sampleCount;
    final gauge = BudgetSemicircleGauge(
      presentation: BudgetSemicircleMaterialPresentation.resolve(
        rawRatio: ratio,
        direction: LedgerDirection.income,
        activeGradient: BudgetClayGaugeAccentResolver.resolve(
          context,
          direction: LedgerDirection.income,
        ),
      ),
      primaryLabel: '${(ratio * 100).round()}%',
      secondaryLabel: 'pozitív hónap • $positiveCount / $sampleCount hónap',
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
