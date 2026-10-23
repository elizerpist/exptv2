import 'package:flutter/material.dart';

import 'balance_day_performance_index_presentation.dart';
import 'budget_clay_semicircle_gauge.dart';

/// A single, enlarged canonical Budget scene. No financial or paint logic.
final class BalanceDayPerformanceIndexView extends StatelessWidget {
  const BalanceDayPerformanceIndexView({super.key, required this.presentation});
  final BalanceDayPerformanceIndexPresentation presentation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final compact = bounds.maxHeight < 240;
      final color = !presentation.isAvailable
          ? const Color(0xff7784aa)
          : presentation.isImproving
          ? const Color(0xff00a882)
          : presentation.isWorsening
          ? const Color(0xffef429b)
          : const Color(0xff8b78b5);
      return Column(
        children: [
          Text(
            '30 napos teljesítmény',
            style: TextStyle(
              fontSize: compact ? 13 : 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xff111d52),
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 320,
                  height: 190,
                  child: BudgetSemicircleGauge(
                    key: const ValueKey('balance-day-performance-index-gauge'),
                    presentation: BudgetSemicircleMaterialPresentation.forScale(
                      scale: presentation.scale,
                      activeColor: color,
                      semanticColor: color,
                    ),
                    primaryLabel: presentation.primaryLabel,
                    primaryColor: color,
                    primaryFontSize: presentation.isAvailable ? 34 : 20,
                    secondaryLabel: presentation.hasVisualOverflow
                        ? 'Skálán túl'
                        : '',
                    showMarker: presentation.isAvailable,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Előző 30 nap = 100%',
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              color: const Color(0xff52618c),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: compact ? 30 : 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                presentation.interpretation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 11 : 14,
                  color: const Color(0xff52618c),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
