import 'package:flutter/material.dart';

import '../../application/dashboard_budget_rhythm_controller.dart';

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
                    index: index,
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
    required this.index,
    required this.bar,
    required this.gradient,
  });

  static const _trackWidth = 11.0;
  static const _pillRadius = 999.0;

  final int index;
  final DashboardBudgetRhythmBar bar;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fillHeight =
                constraints.maxHeight * bar.visualFraction.clamp(0.0, 1.0);
            return Center(
              child: SizedBox(
                key: ValueKey('budget-rhythm-track-$index'),
                width: _trackWidth,
                height: constraints.maxHeight,
                child: DecoratedBox(
                  key: ValueKey('budget-rhythm-track-decoration-$index'),
                  decoration: BoxDecoration(
                    color: const Color(0x1651617f),
                    borderRadius: BorderRadius.circular(_pillRadius),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      key: ValueKey('budget-rhythm-fill-$index'),
                      width: _trackWidth,
                      height: fillHeight,
                      child: DecoratedBox(
                        key: ValueKey('budget-rhythm-fill-decoration-$index'),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(_pillRadius),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
  );
}
