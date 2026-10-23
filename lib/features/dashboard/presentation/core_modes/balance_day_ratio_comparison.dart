import 'package:flutter/material.dart';

import 'balance_day_ratio_presentation.dart';
import 'balance_day_visual_presentation.dart';
import 'budget_clay_semicircle_gauge.dart';

/// Two scene adapters to the canonical Budget gauge; no chart is painted here.
final class BalanceDayRatioComparisonView extends StatelessWidget {
  const BalanceDayRatioComparisonView({super.key, required this.presentation});
  final BalanceDayRatioComparisonPresentation presentation;

  @override
  Widget build(BuildContext context) {
    if (!presentation.hasComparableHistory) {
      return const Center(
        child: Text(
          'Nincs elegendő összehasonlítható adat',
          textAlign: TextAlign.center,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxHeight < 240;
        final delta = presentation.percentagePointDelta;
        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final period in [
                    presentation.previous,
                    presentation.current,
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            period.totals.period ==
                                    BalanceDayComparisonPeriod.previous
                                ? 'Előző 30 nap'
                                : 'Utolsó 30 nap',
                            style: TextStyle(
                              fontSize: compact ? 10 : 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  period.totals.period ==
                                      BalanceDayComparisonPeriod.previous
                                  ? const Color(0xffa076d6)
                                  : const Color(0xff00a882),
                            ),
                          ),
                          Expanded(
                            child: _PeriodGauge(
                              period: period,
                              formulaLabel: presentation.formulaLabel,
                            ),
                          ),
                          SizedBox(
                            height: compact ? 18 : 24,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Nettó ${BalanceDayPeriodComparisonPresentation.signedAmountLabel(period.netMinor)}',
                                style: TextStyle(
                                  fontSize: compact ? 11 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: _resultColor(
                                    period.netMinor.toDouble(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              presentation.deltaTitle,
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                color: const Color(0xff52618c),
              ),
            ),
            SizedBox(
              height: compact ? 22 : 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  presentation.deltaLabel,
                  style: TextStyle(
                    fontSize: compact ? 15 : 20,
                    fontWeight: FontWeight.w800,
                    color: _resultColor(delta),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _PeriodGauge extends StatelessWidget {
  const _PeriodGauge({required this.period, required this.formulaLabel});
  final BalanceDayRatioPeriodPresentation period;
  final String formulaLabel;
  @override
  Widget build(BuildContext context) {
    final previous =
        period.totals.period == BalanceDayComparisonPeriod.previous;
    final color = period.isAvailable
        ? _resultColor(period.netMinor.toDouble())
        : const Color(0xff7784aa);
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 220,
        height: 150,
        child: BudgetSemicircleGauge(
          key: ValueKey(
            previous
                ? 'balance-day-ratio-previous'
                : 'balance-day-ratio-current',
          ),
          presentation: BudgetSemicircleMaterialPresentation.forScale(
            scale: period.scale,
            activeColor: previous
                ? const Color(0xffa076d6)
                : const Color(0xff20bca8),
            semanticColor: color,
          ),
          primaryLabel: period.primaryLabel,
          secondaryLabel: period.hasVisualOverflow
              ? 'Skálán túl'
              : formulaLabel,
          primaryColor: color,
          primaryFontSize: period.isAvailable ? 24 : 16,
          showMarker: period.isAvailable,
        ),
      ),
    );
  }
}

Color _resultColor(double? value) => value == null || value == 0
    ? const Color(0xff111d52)
    : value > 0
    ? const Color(0xff00a882)
    : const Color(0xffef429b);
