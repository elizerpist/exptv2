import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_retention_stability_projection.dart';
import '../../application/dashboard_mode_spec.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// One-dimensional, non-time-series distribution view of the immutable
/// complete-month cashflow stability sample.
class BalanceCashflowStabilityCard extends StatefulWidget {
  const BalanceCashflowStabilityCard({super.key, required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  State<BalanceCashflowStabilityCard> createState() =>
      _BalanceCashflowStabilityCardState();
}

final class _BalanceCashflowStabilityCardState
    extends State<BalanceCashflowStabilityCard> {
  String? _inspectedObservationId;

  @override
  void didUpdateWidget(covariant BalanceCashflowStabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.presentationId !=
        widget.presentation.presentationId) {
      _inspectedObservationId = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 168 || constraints.maxHeight < 132) {
        return const Center(
          key: ValueKey<String>('balance-stability-compact-surface'),
          child: Text('Cashflow stabilitás'),
        );
      }
      if (!widget.presentation.isAvailable) {
        return const KeyedSubtree(
          key: ValueKey<String>('balance-linked-detail-stability'),
          child: Center(child: Text('Nincs elég adat')),
        );
      }
      final palette = DashboardModePaletteResolver.resolve(
        DashboardModeSpec.balance,
      );
      final inspected = widget.presentation.observations
          .where((observation) => observation.id == _inspectedObservationId)
          .firstOrNull;
      return KeyedSubtree(
        key: const ValueKey<String>('balance-linked-detail-stability'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Cashflow stabilitás',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: FluviVisualTokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatBalanceStabilityDeviation(
                  widget.presentation.typicalDeviationTimesTwo!,
                ),
                key: const ValueKey<String>('balance-stability-hero'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Semantics(
                  label: 'Cashflow stabilitás eloszlási sáv, nulla referencia',
                  child: LayoutBuilder(
                    builder: (context, chartConstraints) => GestureDetector(
                      key: const ValueKey<String>(
                        'balance-stability-distribution',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final observation = balanceStabilityObservationAt(
                          localX: details.localPosition.dx,
                          width: chartConstraints.maxWidth,
                          presentation: widget.presentation,
                        );
                        setState(
                          () => _inspectedObservationId = observation.id,
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          CustomPaint(
                            painter: _StabilityPainter(
                              presentation: widget.presentation,
                              pointColor: palette.incomeGradient.colors.first,
                            ),
                            child: const SizedBox.expand(),
                          ),
                          Positioned(
                            left: math.max(
                              0,
                              balanceStabilityDistributionGeometryFor(
                                    size: Size(
                                      chartConstraints.maxWidth,
                                      chartConstraints.maxHeight,
                                    ),
                                    presentation: widget.presentation,
                                  ).zeroX -
                                  10,
                            ),
                            bottom: 1,
                            child: ExcludeSemantics(
                              child: Text(
                                '0 Ft',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: FluviVisualTokens.textSecondary,
                                      fontSize: 8,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _StabilityMetrics(presentation: widget.presentation),
              if (inspected != null)
                _StabilityInspection(observation: inspected),
            ],
          ),
        ),
      );
    },
  );
}

final class _StabilityPainter extends CustomPainter {
  const _StabilityPainter({
    required this.presentation,
    required this.pointColor,
  });

  final DashboardBalanceStabilityPresentation presentation;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = balanceStabilityDistributionGeometryFor(
      size: size,
      presentation: presentation,
    );
    final axisPaint = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .42)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(geometry.zeroX, 0),
      Offset(geometry.zeroX, size.height),
      axisPaint,
    );
    canvas.drawRect(
      geometry.band,
      Paint()..color = pointColor.withValues(alpha: .18),
    );
    canvas.drawLine(
      Offset(geometry.medianX, size.height * .18),
      Offset(geometry.medianX, size.height * .82),
      Paint()
        ..color = pointColor
        ..strokeWidth = 2,
    );
    for (final mark in geometry.observationMarks) {
      canvas.drawCircle(mark, 3, Paint()..color = pointColor);
    }
  }

  @override
  bool shouldRepaint(covariant _StabilityPainter oldDelegate) =>
      oldDelegate.presentation.presentationId != presentation.presentationId ||
      oldDelegate.pointColor != pointColor;
}

@visibleForTesting
final class BalanceStabilityDistributionGeometry {
  const BalanceStabilityDistributionGeometry({
    required this.zeroX,
    required this.medianX,
    required this.band,
    required this.observationMarks,
  });

  final double zeroX;
  final double medianX;
  final Rect band;
  final List<Offset> observationMarks;
}

/// Pure layout geometry. The axis includes zero, median/band endpoints and
/// each immutable observation; duplicate values stack deterministically.
@visibleForTesting
BalanceStabilityDistributionGeometry balanceStabilityDistributionGeometryFor({
  required Size size,
  required DashboardBalanceStabilityPresentation presentation,
}) {
  final values = <int>[
    0,
    ...presentation.observations.map((observation) => observation.netMinor * 2),
    presentation.medianNetTimesTwo!,
    presentation.typicalBandLowerTimesTwo!,
    presentation.typicalBandUpperTimesTwo!,
  ];
  final minimum = values.reduce(math.min);
  final maximum = values.reduce(math.max);
  final extent = maximum == minimum ? 1 : maximum - minimum;
  double xFor(int value) => (value - minimum) / extent * size.width;
  final occurrences = <int, int>{};
  final marks = <Offset>[
    for (final observation in presentation.observations)
      () {
        final value = observation.netMinor * 2;
        final stack = occurrences.update(
          value,
          (count) => count + 1,
          ifAbsent: () => 0,
        );
        return Offset(xFor(value), size.height * (.50 + (stack % 3 - 1) * .12));
      }(),
  ];
  final low = xFor(presentation.typicalBandLowerTimesTwo!);
  final high = xFor(presentation.typicalBandUpperTimesTwo!);
  return BalanceStabilityDistributionGeometry(
    zeroX: xFor(0),
    medianX: xFor(presentation.medianNetTimesTwo!),
    band: Rect.fromLTRB(
      math.min(low, high),
      size.height * .32,
      math.max(low, high),
      size.height * .68,
    ),
    observationMarks: List<Offset>.unmodifiable(marks),
  );
}

DashboardBalanceMonthlyNetObservation balanceStabilityObservationAt({
  required double localX,
  required double width,
  required DashboardBalanceStabilityPresentation presentation,
}) {
  final geometry = balanceStabilityDistributionGeometryFor(
    size: Size(width, 100),
    presentation: presentation,
  );
  var nearest = presentation.observations.first;
  var distance = double.infinity;
  for (var index = 0; index < presentation.observations.length; index += 1) {
    final candidate = (geometry.observationMarks[index].dx - localX).abs();
    if (candidate < distance) {
      nearest = presentation.observations[index];
      distance = candidate;
    }
  }
  return nearest;
}

final class _StabilityMetrics extends StatelessWidget {
  const _StabilityMetrics({required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _metric(context, 'Medián nettó', presentation.medianNetTimesTwo!),
      const SizedBox(width: 8),
      _rangeMetric(
        context,
        presentation.typicalBandLowerTimesTwo!,
        presentation.typicalBandUpperTimesTwo!,
      ),
    ],
  );

  Widget _metric(BuildContext context, String label, int valueTimesTwo) =>
      Expanded(
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
              formatBalanceStabilityMinorTimesTwo(valueTimesTwo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: FluviVisualTokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _rangeMetric(
    BuildContext context,
    int lowerTimesTwo,
    int upperTimesTwo,
  ) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Tipikus sáv',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: FluviVisualTokens.textSecondary,
          ),
        ),
        Text(
          '${formatBalanceStabilityMinorTimesTwo(lowerTimesTwo)} – ${formatBalanceStabilityMinorTimesTwo(upperTimesTwo)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

final class _StabilityInspection extends StatelessWidget {
  const _StabilityInspection({required this.observation});

  final DashboardBalanceMonthlyNetObservation observation;

  @override
  Widget build(BuildContext context) => Text(
    '${observation.label} · Nettó ${DashboardPreparedFormatter.amountMinor(observation.netMinor)}',
    key: const ValueKey<String>('balance-stability-inspection'),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: FluviVisualTokens.textSecondary),
  );
}

String formatBalanceStabilityDeviation(int deviationTimesTwo) =>
    '±${formatBalanceStabilityMinorTimesTwo(deviationTimesTwo)}/hó';

String formatBalanceStabilityMinorTimesTwo(int valueTimesTwo) {
  final sign = valueTimesTwo < 0 ? -1 : 1;
  final absolute = valueTimesTwo.abs();
  final roundedMinor = (absolute + 1) ~/ 2;
  return DashboardPreparedFormatter.amountMinor(sign * roundedMinor);
}
