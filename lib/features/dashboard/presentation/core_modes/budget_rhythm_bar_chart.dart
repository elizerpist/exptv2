import 'package:flutter/material.dart';

import '../../application/dashboard_budget_rhythm_controller.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// Compact widget-only Budget rhythm projection. Its input is already an
/// immutable RAM state, so painting bars performs no money aggregation, SVG
/// work or target/catalog lookup.
class BudgetRhythmBarChart extends StatelessWidget {
  const BudgetRhythmBarChart({super.key, required this.state});

  final DashboardBudgetRhythmState state;

  @override
  Widget build(BuildContext context) {
    final bars = state.projection.bars;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(state.startColorArgb),
        Color(state.middleColorArgb),
        Color(state.endColorArgb),
      ],
    );
    return Column(
      key: ValueKey('budget-rhythm-${state.projection.plane.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          state.projection.title,
          key: const ValueKey('budget-rhythm-title'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff66738d),
            fontSize: 7.2,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (var index = 0; index < bars.length; index += 1)
                Expanded(
                  child: _BudgetRhythmBar(
                    key: ValueKey('budget-rhythm-bar-$index'),
                    bar: bars[index],
                    gradient: gradient,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetRhythmBar extends StatelessWidget {
  const _BudgetRhythmBar({
    super.key,
    required this.bar,
    required this.gradient,
  });

  final DashboardBudgetRhythmBar bar;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.maxHeight;
      final barHeight = height * bar.visualFraction;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 9,
              child: bar.actualScaled100 == 0
                  ? const SizedBox.shrink()
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        DashboardPreparedFormatter.amountMinor(
                          bar.actualScaled100,
                        ),
                        style: const TextStyle(
                          color: Color(0xff51617f),
                          fontSize: 6.4,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x1651617f),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: barHeight.clamp(0, height - 9).toDouble(),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bar.label,
              style: const TextStyle(
                color: Color(0xff66738d),
                fontSize: 6.4,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    },
  );
}
