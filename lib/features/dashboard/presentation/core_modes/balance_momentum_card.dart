import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_closings_momentum_projection.dart';
import '../../application/dashboard_mode_spec.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// Four-quadrant renderer for the immutable Balance Momentum read model.
class BalanceMomentumCard extends StatelessWidget {
  const BalanceMomentumCard({super.key, required this.presentation});

  final DashboardBalanceMomentumPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 168 || constraints.maxHeight < 132) {
          return const Center(
            key: ValueKey<String>('balance-momentum-compact-surface'),
            child: Text('Balance momentum'),
          );
        }
        if (!presentation.isAvailable) {
          return const KeyedSubtree(
            key: ValueKey<String>('balance-linked-detail-momentum'),
            child: Center(child: Text('Nincs elég összehasonlítható adat')),
          );
        }
        final palette = DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        );
        final state = balanceMomentumStateLabel(presentation.state);
        return KeyedSubtree(
          key: const ValueKey<String>('balance-linked-detail-momentum'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Balance momentum',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: FluviVisualTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  state,
                  key: const ValueKey<String>('balance-momentum-state'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Semantics(
                    label: 'Balance momentum térkép: $state',
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CustomPaint(
                          key: const ValueKey<String>('balance-momentum-map'),
                          painter: _MomentumMapPainter(
                            currentPace: presentation.currentNetPace,
                            previousPace: presentation.previousNetPace,
                            momentum: presentation.momentum,
                            pointColor: palette.incomeGradient.colors.first,
                          ),
                        ),
                        const Positioned(
                          left: 2,
                          top: 2,
                          child: _QuadrantLabel('Kilábalás'),
                        ),
                        const Positioned(
                          right: 2,
                          top: 2,
                          child: _QuadrantLabel('Erősödő többlet'),
                        ),
                        const Positioned(
                          left: 2,
                          bottom: 2,
                          child: _QuadrantLabel('Mélyülő deficit'),
                        ),
                        const Positioned(
                          right: 2,
                          bottom: 2,
                          child: _QuadrantLabel('Gyengülő többlet'),
                        ),
                      ],
                    ),
                  ),
                ),
                _MomentumMetrics(presentation: presentation),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _QuadrantLabel extends StatelessWidget {
  const _QuadrantLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: FluviVisualTokens.textSecondary.withValues(alpha: .78),
        fontSize: 8,
      ),
    ),
  );
}

final class _MomentumMetrics extends StatelessWidget {
  const _MomentumMetrics({required this.presentation});

  final DashboardBalanceMomentumPresentation presentation;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _metric(context, 'Korábbi tempó', presentation.previousNetPace),
      const SizedBox(width: 8),
      _metric(context, 'Mostani tempó', presentation.currentNetPace),
      const SizedBox(width: 8),
      _metric(context, 'Momentum', presentation.momentum),
    ],
  );

  Widget _metric(BuildContext context, String label, double value) => Expanded(
    child: Semantics(
      label: '$label ${formatBalanceMomentumRate(value, presentation.unit)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
          Text(
            formatBalanceMomentumRate(value, presentation.unit),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FluviVisualTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _MomentumMapPainter extends CustomPainter {
  const _MomentumMapPainter({
    required this.currentPace,
    required this.previousPace,
    required this.momentum,
    required this.pointColor,
  });

  final double currentPace;
  final double previousPace;
  final double momentum;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final axis = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .42)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axis);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axis);
    final point = balanceMomentumMapPointFor(
      size: size,
      currentPace: currentPace,
      previousPace: previousPace,
      momentum: momentum,
    );
    canvas.drawCircle(point, 5, Paint()..color = pointColor);
  }

  @override
  bool shouldRepaint(covariant _MomentumMapPainter oldDelegate) =>
      oldDelegate.currentPace != currentPace ||
      oldDelegate.previousPace != previousPace ||
      oldDelegate.momentum != momentum ||
      oldDelegate.pointColor != pointColor;
}

/// Pure map geometry for the bounded, already-calculated Momentum DTO.
@visibleForTesting
double balanceMomentumAxisExtent({
  required double currentPace,
  required double previousPace,
  required double momentum,
}) => math.max(
  1,
  math.max(currentPace.abs(), math.max(previousPace.abs(), momentum.abs())),
);

@visibleForTesting
Offset balanceMomentumMapPointFor({
  required Size size,
  required double currentPace,
  required double previousPace,
  required double momentum,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final extent = balanceMomentumAxisExtent(
    currentPace: currentPace,
    previousPace: previousPace,
    momentum: momentum,
  );
  return Offset(
    center.dx + currentPace / extent * size.width * .42,
    center.dy - momentum / extent * size.height * .42,
  );
}

String balanceMomentumStateLabel(DashboardBalanceMomentumState state) =>
    switch (state) {
      DashboardBalanceMomentumState.recovery => 'Kilábalás',
      DashboardBalanceMomentumState.strengtheningSurplus => 'Erősödő többlet',
      DashboardBalanceMomentumState.deepeningDeficit => 'Mélyülő deficit',
      DashboardBalanceMomentumState.weakeningSurplus => 'Gyengülő többlet',
      DashboardBalanceMomentumState.stableSurplus => 'Stabil többlet',
      DashboardBalanceMomentumState.stableDeficit => 'Stabil deficit',
      DashboardBalanceMomentumState.improvingBreakEven => 'Javuló break-even',
      DashboardBalanceMomentumState.worseningBreakEven => 'Romló break-even',
      DashboardBalanceMomentumState.stableBreakEven => 'Stabil break-even',
      DashboardBalanceMomentumState.unavailable =>
        'Nincs elég összehasonlítható adat',
    };

String formatBalanceMomentumRate(
  double value,
  DashboardBalanceMomentumUnit unit,
) {
  final unitLabel = unit == DashboardBalanceMomentumUnit.perHour
      ? 'óra'
      : 'nap';
  final rounded = value.round();
  final prefix = rounded > 0
      ? '+'
      : rounded < 0
      ? '−'
      : '';
  return '$prefix${DashboardPreparedFormatter.amountMinor(rounded.abs())}/$unitLabel';
}
