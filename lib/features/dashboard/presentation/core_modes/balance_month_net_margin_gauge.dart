import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'balance_month_net_margin_presentation.dart';
import 'budget_clay_semicircle_gauge.dart';

/// Semantic month adapter to the existing Budget scene, marker and motion.
final class BalanceMonthNetMarginGauge extends StatelessWidget {
  const BalanceMonthNetMarginGauge({super.key, required this.presentation});
  final BalanceMonthNetMarginPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final color = presentation.isPositive
        ? const Color(0xff00a882)
        : presentation.isNegative
        ? const Color(0xffef429b)
        : const Color(0xff8b78b5);
    final gauge = BudgetSemicircleGauge(
      key: const ValueKey('balance-month-net-margin-gauge'),
      presentation: BudgetSemicircleMaterialPresentation.forScale(
        scale: presentation.scale,
        activeColor: color,
        semanticColor: color,
      ),
      primaryLabel: presentation.primaryLabel,
      primaryFontSize: presentation.isAvailable ? 24 : 12,
      primaryColor: color,
      secondaryLabel: presentation.hasVisualOverflow
          ? 'Skálán túl'
          : '0% — Nullszaldó',
      showMarker: presentation.isAvailable,
    );
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, scene) {
                final size = scene.biggest;
                if (!size.isFinite ||
                    (size.width >= 220 && size.height >= 125)) {
                  return gauge;
                }
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              presentation.interpretation,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xff52618c)),
            ),
          ),
        ],
      ),
    );
  }
}
