import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_retention_stability_projection.dart';
import '../../application/dashboard_mode_spec.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// Reference-locked local views of the one Cashflow-stability detail card.
/// This never belongs to the financial projection or Query state.
enum BalanceStabilityView { stabil1, stabil2 }

class BalanceCashflowStabilityCard extends StatefulWidget {
  const BalanceCashflowStabilityCard({super.key, required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  State<BalanceCashflowStabilityCard> createState() =>
      _BalanceCashflowStabilityCardState();
}

final class _BalanceCashflowStabilityCardState
    extends State<BalanceCashflowStabilityCard> {
  BalanceStabilityView _view = BalanceStabilityView.stabil1;

  void _toggle() => setState(() {
    _view = _view == BalanceStabilityView.stabil1
        ? BalanceStabilityView.stabil2
        : BalanceStabilityView.stabil1;
  });

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
        return const SizedBox.expand(
          key: ValueKey<String>('balance-linked-detail-stability'),
          child: Center(child: Text('Nincs elég adat')),
        );
      }
      final reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final viewNumber = _view == BalanceStabilityView.stabil1 ? 1 : 2;
      return SizedBox.expand(
        key: const ValueKey<String>('balance-linked-detail-stability'),
        child: Semantics(
          button: true,
          label:
              'Cashflow stabilitás, nézet $viewNumber a 2-ből. Koppints a másik nézethez.',
          child: GestureDetector(
            key: const ValueKey<String>('balance-stability-toggle-surface'),
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: AnimatedSwitcher(
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: <Widget>[...previous, ?current],
                ),
                child: KeyedSubtree(
                  key: ValueKey<BalanceStabilityView>(_view),
                  child: _view == BalanceStabilityView.stabil1
                      ? _StabilityFirstView(presentation: widget.presentation)
                      : _StabilitySecondView(presentation: widget.presentation),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

final class _StabilityFirstView extends StatelessWidget {
  const _StabilityFirstView({required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardModePaletteResolver.resolve(
      DashboardModeSpec.balance,
    );
    return Column(
      key: const ValueKey<String>('balance-stability-stabil1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _StabilityHeader(
          subtitle: 'Értelmezés fókuszban',
          infoKey: ValueKey<String>('balance-stability-stabil1-info'),
          extendedInfo: true,
        ),
        const SizedBox(height: 4),
        const _DirectionalLegend(),
        const SizedBox(height: 2),
        Expanded(
          flex: 4,
          child: _DistributionChart(
            presentation: presentation,
            pointColor: palette.incomeGradient.colors.first,
          ),
        ),
        const SizedBox(height: 4),
        const _StabilityReferenceLegend(),
        const SizedBox(height: 6),
        _FirstMetrics(presentation: presentation),
      ],
    );
  }
}

final class _StabilitySecondView extends StatelessWidget {
  const _StabilitySecondView({required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('balance-stability-stabil2'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _StabilityHeader(
        subtitle: formatBalanceStabilityDeviation(
          presentation.typicalDeviationTimesTwo!,
        ),
        infoKey: const ValueKey<String>('balance-stability-stabil2-info'),
      ),
      const SizedBox(height: 7),
      SizedBox(height: 112, child: _BandChart(presentation: presentation)),
      const SizedBox(height: 10),
      Expanded(child: _InterpretationPanel(presentation: presentation)),
    ],
  );
}

final class _StabilityHeader extends StatelessWidget {
  const _StabilityHeader({
    required this.subtitle,
    required this.infoKey,
    this.extendedInfo = false,
  });

  final String subtitle;
  final Key infoKey;
  final bool extendedInfo;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Cashflow stabilitás',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF14213A),
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              key: const ValueKey<String>('balance-stability-subtitle'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
      _InfoControl(key: infoKey, extended: extendedInfo),
    ],
  );
}

/// Explicit child GestureDetector wins the gesture arena over the card's tap.
final class _InfoControl extends StatelessWidget {
  const _InfoControl({super.key, required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: extended ? 'Mit nézz?' : 'Információ',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        height: extended ? 30 : 28,
        padding: EdgeInsets.symmetric(horizontal: extended ? 10 : 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: const Text(
                'i',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (extended) ...<Widget>[
              const SizedBox(width: 7),
              const Text(
                'Mit nézz?',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

final class _DirectionalLegend extends StatelessWidget {
  const _DirectionalLegend();

  @override
  Widget build(BuildContext context) => const Row(
    children: <Widget>[
      Icon(Icons.arrow_back_rounded, color: Color(0xFF91A0B6), size: 18),
      SizedBox(width: 5),
      Expanded(
        child: Text(
          'Kisebb kiadás',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ),
      Expanded(
        child: Text(
          'Nagyobb bevétel',
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
      ),
      SizedBox(width: 5),
      Icon(Icons.arrow_forward_rounded, color: Color(0xFF91A0B6), size: 18),
    ],
  );
}

final class _DistributionChart extends StatelessWidget {
  const _DistributionChart({
    required this.presentation,
    required this.pointColor,
  });

  final DashboardBalanceStabilityPresentation presentation;
  final Color pointColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final labels = _AxisLabels.forPresentation(presentation);
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            key: const ValueKey<String>('balance-stability-distribution'),
            painter: _DistributionPainter(
              presentation: presentation,
              pointColor: pointColor,
            ),
          ),
          Positioned(
            left: math.max(0, labels.zeroX(size) - 11),
            bottom: 0,
            child: const Text('0 Ft', style: _zeroLabelStyle),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(labels.lower, style: _axisStyle),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(labels.upper, style: _axisStyle),
          ),
        ],
      );
    },
  );
}

const _axisStyle = TextStyle(color: Color(0xFF64748B), fontSize: 9.5);
const _zeroLabelStyle = TextStyle(
  color: Color(0xFF14213A),
  fontSize: 10,
  fontWeight: FontWeight.w800,
);

final class _StabilityReferenceLegend extends StatelessWidget {
  const _StabilityReferenceLegend();

  @override
  Widget build(BuildContext context) => const Column(
    children: <Widget>[
      _ReferenceLegendRow(
        icon: _LegendIcon.band,
        title: 'Sáv',
        copy:
            'Ez a tipikus havi nettó tartományod. Ha a pontok többsége itt van, a cashflow viszonylag stabil.',
      ),
      SizedBox(height: 3),
      _ReferenceLegendRow(
        icon: _LegendIcon.point,
        title: 'Pontok',
        copy:
            'Minden pont egy hónapot jelöl. A sávon kívüli pontok kiugró hónapok.',
      ),
      SizedBox(height: 3),
      _ReferenceLegendRow(
        icon: _LegendIcon.median,
        title: 'Középvonal',
        copy:
            'A függőleges jel mutatja a megszokott nettó szinted a 0 Ft-hoz képest.',
      ),
    ],
  );
}

enum _LegendIcon { band, point, median }

final class _ReferenceLegendRow extends StatelessWidget {
  const _ReferenceLegendRow({
    required this.icon,
    required this.title,
    required this.copy,
  });

  final _LegendIcon icon;
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _LegendTile(icon: icon),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF14213A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              copy,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                height: 1.14,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _LegendTile extends StatelessWidget {
  const _LegendTile({required this.icon});

  final _LegendIcon icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF3EEFF),
      borderRadius: BorderRadius.circular(10),
    ),
    child: switch (icon) {
      _LegendIcon.band => Container(
        width: 24,
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFB89BFF).withValues(alpha: .55),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      _LegendIcon.point => const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF7C3AED),
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 15, height: 15),
      ),
      _LegendIcon.median => Container(
        width: 2,
        height: 26,
        color: const Color(0xFF7C3AED),
      ),
    },
  );
}

final class _FirstMetrics extends StatelessWidget {
  const _FirstMetrics({required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: _MetricTile(
          label: 'Tipikus sáv',
          value:
              '${formatBalanceStabilityMinorTimesTwo(presentation.typicalBandLowerTimesTwo!)} – ${formatBalanceStabilityMinorTimesTwo(presentation.typicalBandUpperTimesTwo!)}',
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _MetricTile(
          label: 'Medián nettó',
          value: formatBalanceStabilityMinorTimesTwo(
            presentation.medianNetTimesTwo!,
          ),
          accent: true,
        ),
      ),
    ],
  );
}

final class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent ? const Color(0xFF7C3AED) : const Color(0xFF14213A),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

final class _BandChart extends StatelessWidget {
  const _BandChart({required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final geometry = balanceStabilityDistributionGeometryFor(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        presentation: presentation,
      );
      final labels = _AxisLabels.forPresentation(presentation);
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            key: const ValueKey<String>('balance-stability-band-chart'),
            painter: _BandPainter(presentation: presentation),
          ),
          Positioned(
            left: math.max(0, geometry.band.left - 24),
            top: 0,
            child: Text(
              formatBalanceStabilityMinorTimesTwo(
                presentation.typicalBandLowerTimesTwo!,
              ),
              style: _bandLabelStyle,
            ),
          ),
          Positioned(
            left: math.max(0, geometry.band.right - 28),
            top: 0,
            child: Text(
              formatBalanceStabilityMinorTimesTwo(
                presentation.typicalBandUpperTimesTwo!,
              ),
              style: _bandLabelStyle,
            ),
          ),
          Positioned(
            left: math.max(0, geometry.medianX - 25),
            bottom: 0,
            child: Text(
              'Medián\n${formatBalanceStabilityMinorTimesTwo(presentation.medianNetTimesTwo!)}',
              textAlign: TextAlign.center,
              style: _medianLabelStyle,
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Text(labels.lower, style: _axisStyle),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Text(labels.upper, style: _axisStyle),
          ),
        ],
      );
    },
  );
}

const _bandLabelStyle = TextStyle(
  color: Color(0xFF7C3AED),
  fontSize: 11,
  fontWeight: FontWeight.w800,
);
const _medianLabelStyle = TextStyle(
  color: Color(0xFF14213A),
  fontSize: 10.5,
  height: 1.05,
  fontWeight: FontWeight.w800,
);

final class _InterpretationPanel extends StatelessWidget {
  const _InterpretationPanel({required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final interpretation = balanceStabilityInterpretationFor(presentation);
    return Container(
      key: const ValueKey<String>('balance-stability-interpretation'),
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8DFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF7C3AED),
              size: 27,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'ÉRTELMEZÉS FÓKUSZBAN',
                  style: TextStyle(
                    color: Color(0xFF7C729B),
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Mit jelent ez neked?',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  interpretation.title,
                  style: const TextStyle(
                    color: Color(0xFF14213A),
                    fontSize: 19,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  interpretation.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
final class BalanceStabilityInterpretation {
  const BalanceStabilityInterpretation({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

BalanceStabilityInterpretation balanceStabilityInterpretationFor(
  DashboardBalanceStabilityPresentation presentation,
) {
  final lower = presentation.typicalBandLowerTimesTwo!;
  final upper = presentation.typicalBandUpperTimesTwo!;
  final inside = presentation.observations.where((observation) {
    final value = observation.netMinor * 2;
    return value >= lower && value <= upper;
  }).length;
  final ratio = inside / presentation.observations.length;
  if (ratio >= .75) {
    return const BalanceStabilityInterpretation(
      title: 'Stabil cashflow',
      description:
          'A havi eredményeid jellemzően a tipikus tartományon belül maradnak, ezért a cashflow kiszámítható.',
    );
  }
  if (ratio >= .45) {
    return const BalanceStabilityInterpretation(
      title: 'Közepesen stabil',
      description:
          'A havi eredményeid ingadoznak, néha mínuszba is fordulnak, de jellemzően a tipikus tartományon belül vannak, és összességében enyhén pozitívak.',
    );
  }
  return const BalanceStabilityInterpretation(
    title: 'Hullámzó cashflow',
    description:
        'A havi eredményeid gyakran eltérnek a tipikus tartománytól, ezért érdemes nagyobb tartalékot hagyni.',
  );
}

final class _DistributionPainter extends CustomPainter {
  const _DistributionPainter({
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
    final baseline = size.height * .72;
    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        geometry.band.left,
        size.height * .24,
        geometry.band.right,
        size.height * .59,
      ),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFFD9CAFF), Color(0xFFEDE7FF)],
        ).createShader(band.outerRect),
    );
    final axis = Paint()
      ..color = const Color(0xFF91A0B6)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), axis);
    _drawDashedVertical(
      canvas,
      geometry.zeroX,
      size.height * .14,
      baseline,
      Paint()
        ..color = const Color(0xFF91A0B6).withValues(alpha: .65)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(geometry.medianX, size.height * .14),
      Offset(geometry.medianX, baseline),
      Paint()
        ..color = const Color(0xFF7C3AED)
        ..strokeWidth = 2.2,
    );
    for (final mark in geometry.observationMarks) {
      final outside =
          mark.dx < geometry.band.left || mark.dx > geometry.band.right;
      canvas.drawCircle(
        Offset(mark.dx, size.height * .47 + (mark.dy - size.height * .5) * .35),
        4.5,
        Paint()..color = outside ? const Color(0xFFFF7A3D) : pointColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DistributionPainter oldDelegate) =>
      oldDelegate.presentation.presentationId != presentation.presentationId ||
      oldDelegate.pointColor != pointColor;
}

final class _BandPainter extends CustomPainter {
  const _BandPainter({required this.presentation});

  final DashboardBalanceStabilityPresentation presentation;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = balanceStabilityDistributionGeometryFor(
      size: size,
      presentation: presentation,
    );
    final visualBand = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, size.height * .30, size.width, size.height * .72),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      visualBand,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            Color(0xFFFFE6E9),
            Color(0xFFE7D9FF),
            Color(0xFFDCFBE8),
          ],
          stops: <double>[0, .5, 1],
        ).createShader(visualBand.outerRect),
    );
    canvas.drawLine(
      Offset(0, size.height * .51),
      Offset(size.width, size.height * .51),
      Paint()
        ..color = const Color(0xFFA879FF).withValues(alpha: .55)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(geometry.medianX, size.height * .22),
      Offset(geometry.medianX, size.height * .80),
      Paint()
        ..color = const Color(0xFF7C3AED)
        ..strokeWidth = 2,
    );
    for (final x in <double>[geometry.band.left, geometry.band.right]) {
      canvas.drawLine(
        Offset(x, size.height * .22),
        Offset(x, size.height * .79),
        Paint()
          ..color = const Color(0xFF8B5CF6)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BandPainter oldDelegate) =>
      oldDelegate.presentation.presentationId != presentation.presentationId;
}

void _drawDashedVertical(
  Canvas canvas,
  double x,
  double top,
  double bottom,
  Paint paint,
) {
  for (var y = top; y < bottom; y += 7) {
    canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 3, bottom)), paint);
  }
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

final class _AxisLabels {
  const _AxisLabels({
    required this.lower,
    required this.upper,
    required this.minimum,
    required this.extent,
  });

  final String lower;
  final String upper;
  final int minimum;
  final int extent;

  factory _AxisLabels.forPresentation(
    DashboardBalanceStabilityPresentation presentation,
  ) {
    final values = <int>[
      0,
      ...presentation.observations.map((item) => item.netMinor * 2),
      presentation.typicalBandLowerTimesTwo!,
      presentation.typicalBandUpperTimesTwo!,
      presentation.medianNetTimesTwo!,
    ];
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    return _AxisLabels(
      lower: formatBalanceStabilityMinorTimesTwo(minimum),
      upper: formatBalanceStabilityMinorTimesTwo(maximum),
      minimum: minimum,
      extent: math.max(1, maximum - minimum),
    );
  }

  double zeroX(Size size) =>
      (-minimum / extent * size.width).clamp(0, size.width);
}

String formatBalanceStabilityDeviation(int deviationTimesTwo) =>
    '±${formatBalanceStabilityMinorTimesTwo(deviationTimesTwo)}/hó';

String formatBalanceStabilityMinorTimesTwo(int valueTimesTwo) {
  final sign = valueTimesTwo < 0 ? -1 : 1;
  final absolute = valueTimesTwo.abs();
  final roundedMinor = (absolute + 1) ~/ 2;
  return DashboardPreparedFormatter.amountMinor(sign * roundedMinor);
}
