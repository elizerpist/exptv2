import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/fluvi_year_clay_capsule_painter.dart';
import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'budget_clay_semicircle_gauge.dart';
import 'balance_day_visual_presentation.dart';

const _ink = Color(0xff111d52);
const _green = Color(0xff00a882);
const _pink = Color(0xffef429b);
String _money(int v) => DashboardPreparedFormatter.amountMinor(v);
String _percent(double? v) => v == null
    ? '—'
    : '${v > 0 ? '+' : ''}${v.toStringAsFixed(1).replaceAll('.', ',')}%';
double? _change(int current, int previous) =>
    previous == 0 ? null : (current - previous) / previous * 100;
Text _text(
  String s, {
  double size = 12,
  Color color = _ink,
  FontWeight weight = FontWeight.w600,
  int lines = 2,
}) => Text(
  s,
  textAlign: TextAlign.center,
  maxLines: lines,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(fontSize: size, color: color, fontWeight: weight),
);

Widget _referenceIcon(IconData icon) => Container(
  width: 30,
  height: 30,
  decoration: BoxDecoration(
    color: const Color(0xfff1eaff),
    borderRadius: BorderRadius.circular(11),
  ),
  child: Icon(icon, size: 21, color: const Color(0xff9258ef)),
);
String _momentumDetail(DashboardBalanceDailyMomentumPoint p) {
  String change(int value, String noun) => value > 0
      ? 'Növekvő $noun'
      : value < 0
      ? 'Csökkenő $noun'
      : 'Változatlan $noun';
  return '${change(p.incomeChangeMinor, 'bevétel')}, ${change(p.expenseChangeMinor, 'kiadás').toLowerCase()}';
}

final class BalanceDayFinancialCompass extends StatelessWidget {
  const BalanceDayFinancialCompass({super.key, required this.momentum});
  final DashboardBalanceDailyMomentumPresentation momentum;
  @override
  Widget build(BuildContext context) {
    if (!momentum.available) {
      return const Center(child: Text('Még nincs összehasonlítható előzmény'));
    }
    final p = momentum.selected;
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxHeight < 220;
        return Column(
          children: [
            Row(
              children: [
                _referenceIcon(Icons.my_location_rounded),
                Expanded(
                  child: Column(
                    children: [
                      _text(
                        p.quadrant.label,
                        size: compact ? 15 : 19,
                        weight: FontWeight.w800,
                      ),
                      SizedBox(height: compact ? 1 : 3),
                      _text(
                        _momentumDetail(p),
                        size: compact ? 9 : 11,
                        color: const Color(0xff52618c),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
              ],
            ),
            SizedBox(height: compact ? 3 : 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final d = math.min(c.maxWidth * .76, c.maxHeight);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: const Alignment(-1, -.72),
                        child: _changePanel(
                          'Bevétel\nváltozása',
                          _change(p.currentIncomeMinor, p.referenceIncomeMinor),
                          true,
                        ),
                      ),
                      Align(
                        alignment: const Alignment(1, -.72),
                        child: _changePanel(
                          'Kiadás\nváltozása',
                          _change(
                            p.currentExpenseMinor,
                            p.referenceExpenseMinor,
                          ),
                          false,
                        ),
                      ),
                      SizedBox(
                        key: const ValueKey('balance-day-compass-circle'),
                        width: d,
                        height: d,
                        child: CustomPaint(painter: _CompassPainter(p)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _changePanel(String label, double? change, bool income) =>
      LayoutBuilder(
        builder: (context, bounds) => Container(
          width: 85,
          padding: EdgeInsets.symmetric(
            vertical: bounds.maxHeight < 85 ? 6 : 10,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: (income ? _green : _pink).withValues(alpha: .035),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _text(
                _percent(change),
                size: 20,
                color: income ? _green : _pink,
                weight: FontWeight.w800,
              ),
              const SizedBox(height: 4),
              _text(label, size: 10),
            ],
          ),
        ),
      );
}

final class BalanceDayFinancialComparison extends StatelessWidget {
  const BalanceDayFinancialComparison({super.key, required this.momentum});
  final DashboardBalanceDailyMomentumPresentation momentum;
  @override
  Widget build(BuildContext context) {
    if (!momentum.available) {
      return const Center(child: Text('Még nincs összehasonlítható előzmény'));
    }
    final comparison = BalanceDayPeriodComparisonPresentation.fromPoint(
      momentum.selected,
    );
    final scale = BalanceDayComparisonBarScale.fromComparison(comparison);
    Color resultColor(int amount) => amount > 0
        ? _green
        : amount < 0
        ? _pink
        : _ink;
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxHeight < 240;
        return Column(
          children: [
            Row(
              children: [
                for (final period in [comparison.previous, comparison.current])
                  Expanded(
                    child: Column(
                      key: ValueKey(
                        'balance-day-comparison-period-${period.period.name}',
                      ),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _text(
                          period.period == BalanceDayComparisonPeriod.previous
                              ? 'Előző 30 nap'
                              : 'Utolsó 30 nap',
                          size: compact ? 9 : 13,
                          color:
                              period.period ==
                                  BalanceDayComparisonPeriod.previous
                              ? const Color(0xffa076d6)
                              : _green,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _text(
                            BalanceDayPeriodComparisonPresentation.signedAmountLabel(
                              period.netMinor,
                            ),
                            size: compact ? 18 : 27,
                            color: resultColor(period.netMinor),
                            weight: FontWeight.w800,
                            lines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Expanded(
              child: CustomPaint(
                key: const ValueKey('balance-day-comparison-chart'),
                size: Size.infinite,
                painter: BalanceDayComparisonPainter(scale),
              ),
            ),
            Row(
              children: [
                for (var group = 0; group < 2; group++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: bounds.maxWidth * .05,
                      ),
                      child: Row(
                        children: [
                          for (
                            var withinGroup = 0;
                            withinGroup < 2;
                            withinGroup++
                          )
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _text(
                                    withinGroup == 0 ? 'Bevétel' : 'Kiadás',
                                    size: compact ? 7 : 10,
                                    color: withinGroup == 0 ? _green : _pink,
                                    lines: 1,
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _text(
                                      _money(
                                        scale.amountsMinor[group * 2 +
                                            withinGroup],
                                      ),
                                      size: compact ? 8 : 12,
                                      weight: FontWeight.w700,
                                      lines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            _text(
              'Mérlegváltozás',
              size: compact ? 8 : 11,
              color: const Color(0xff52618c),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: _text(
                BalanceDayPeriodComparisonPresentation.signedAmountLabel(
                  comparison.netDeltaMinor,
                ),
                size: compact ? 16 : 23,
                color: resultColor(comparison.netDeltaMinor),
                weight: FontWeight.w800,
                lines: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}

final class BalanceDayImpactFocus extends StatelessWidget {
  const BalanceDayImpactFocus({super.key, required this.impact});
  final DashboardBalanceDailyImpactPresentation impact;
  @override
  Widget build(BuildContext context) {
    final comparison = BalanceDaySevenDayComparisonPresentation.fromImpact(
      impact,
    );
    final title = !impact.available
        ? 'Nincs elegendő adat'
        : impact.isImproving
        ? 'Javulás'
        : impact.isWorsening
        ? 'Romlás'
        : 'Nincs változás';
    final detail = !impact.available
        ? 'Az összehasonlításhoz további kiadási előzmények szükségesek.'
        : impact.isImproving
        ? 'Az aktuális nap csökkentette a 7 napos kiadási szintet.'
        : impact.isWorsening
        ? 'Az aktuális nap növelte a 7 napos kiadási szintet.'
        : 'A két 7 napos időszak kiadási szintje megegyezik.';
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxHeight < 240;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: const Color(0xff9258ef),
                  size: compact ? 22 : 31,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _text(
                    title,
                    size: compact ? 19 : 29,
                    weight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            _text(
              _percent(impact.available ? impact.valuePercent : null),
              size: compact ? 27 : 40,
              weight: FontWeight.w800,
              color: impact.isWorsening
                  ? _pink
                  : impact.isImproving
                  ? _green
                  : const Color(0xff7784aa),
              lines: 1,
            ),
            _text(
              detail,
              size: compact ? 8 : 11,
              color: const Color(0xff52618c),
            ),
            Expanded(child: _ImpactTube(impact: impact)),
            Container(
              key: const ValueKey('balance-day-seven-day-comparison'),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 14,
                vertical: compact ? 5 : 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xfff5f7ff), Color(0xffeceffc)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: .85)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: const Color(0xff929ac0),
                    size: compact ? 18 : 26,
                  ),
                  Expanded(
                    child: _SevenDayColumn(
                      total: comparison.previousTotalLabel,
                      title: 'Előző 7 nap',
                      average: comparison.previousDailyAverageLabel,
                      compact: compact,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: const Color(0xff929ac0),
                    size: compact ? 18 : 26,
                  ),
                  Expanded(
                    child: _SevenDayColumn(
                      total: comparison.currentTotalLabel,
                      title: 'Aktuális 7 nap',
                      average: comparison.currentDailyAverageLabel,
                      compact: compact,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _SevenDayColumn extends StatelessWidget {
  const _SevenDayColumn({
    required this.total,
    required this.title,
    required this.average,
    required this.compact,
  });
  final String total, title, average;
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: _text(
          total,
          size: compact ? 12 : 19,
          weight: FontWeight.w800,
          lines: 1,
        ),
      ),
      _text(
        title,
        size: compact ? 7 : 10,
        color: const Color(0xff52618c),
        lines: 1,
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: _text(
          average,
          size: compact ? 6 : 9,
          color: const Color(0xff7784aa),
          lines: 1,
        ),
      ),
    ],
  );
}

final class BalanceDayCompactImpact extends StatelessWidget {
  const BalanceDayCompactImpact({super.key, required this.impact});
  final DashboardBalanceDailyImpactPresentation impact;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ImpactHeading(impact: impact, compact: true),
      Expanded(child: _ImpactTube(impact: impact, compact: true)),
    ],
  );
}

final class _ImpactHeading extends StatelessWidget {
  const _ImpactHeading({required this.impact, this.compact = false});
  final DashboardBalanceDailyImpactPresentation impact;
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        Icons.bar_chart_rounded,
        color: const Color(0xff9258ef),
        size: compact ? 24 : 31,
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              'Napi hatás',
              size: compact ? 15 : 20,
              weight: FontWeight.w800,
            ),
            _text(
              'Hatása a 7 napos kiadási szintre',
              size: 8,
              color: const Color(0xff52618c),
            ),
          ],
        ),
      ),
      Flexible(
        flex: 2,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _text(
            _percent(impact.available ? impact.valuePercent : null),
            size: compact ? 25 : 34,
            color: impact.isWorsening ? _pink : _green,
            weight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

final class _CompassPainter extends CustomPainter {
  const _CompassPainter(this.point);
  final DashboardBalanceDailyMomentumPoint point;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        r = math.min(size.width, size.height) / 2 - 7;
    if (r <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center.translate(0, 5),
      r,
      Paint()
        ..color = const Color(0xff6675ad).withValues(alpha: .12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    const colors = [
      Color(0xffc4f4ea),
      Color(0xffe8e0ff),
      Color(0xffe9f0fb),
      Color(0xfffbdcf1),
    ];
    for (var i = 0; i < 4; i++) {
      final q = Rect.fromLTWH(
        i.isEven ? rect.left : center.dx,
        i < 2 ? rect.top : center.dy,
        r,
        r,
      );
      canvas.drawRect(
        q,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(i.isEven ? 1 : -1, i < 2 ? 1 : -1),
            colors: [colors[i], Color.lerp(colors[i], Colors.white, .65)!],
          ).createShader(q),
      );
    }
    canvas.drawLine(
      Offset(center.dx, rect.top),
      Offset(center.dx, rect.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: .9)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(rect.left, center.dy),
      Offset(rect.right, center.dy),
      Paint()
        ..color = Colors.white.withValues(alpha: .9)
        ..strokeWidth = 1.5,
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withValues(alpha: .48),
    );
    _sphere(canvas, center, r * .075, const Color(0xfff9fbff));
    final offset = Offset(
      point.expenseAxis.clamp(-1.0, 1.0) * r * .75,
      -point.incomeAxis.clamp(-1.0, 1.0) * r * .75,
    );
    final distance = offset.distance;
    final safe = distance > r * .76 ? offset * (r * .76 / distance) : offset;
    _sphere(
      canvas,
      center + safe,
      math.max(9, r * .16),
      const Color(0xff9253ed),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.point != point;
}

void _sphere(Canvas canvas, Offset center, double r, Color base) {
  canvas.drawOval(
    Rect.fromCenter(
      center: center.translate(r * .13, r * .65),
      width: r * 1.8,
      height: r * .8,
    ),
    Paint()
      ..color = base.withValues(alpha: .28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .22),
  );
  final rect = Rect.fromCircle(center: center, radius: r);
  canvas.drawCircle(
    center,
    r,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.45, -.55),
        radius: 1.15,
        colors: [
          Color.lerp(base, Colors.white, .7)!,
          base,
          Color.lerp(base, const Color(0xff183b67), .27)!,
        ],
        stops: const [0, .47, 1],
      ).createShader(rect),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: center.translate(-r * .3, -r * .38),
      width: r * .52,
      height: r * .4,
    ),
    Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .07),
  );
}

/// Four flow volumes share one prepared financial scale and the Budget material.
final class BalanceDayComparisonPainter extends CustomPainter {
  const BalanceDayComparisonPainter(this.scale);
  final BalanceDayComparisonBarScale scale;
  static Color colorFor(BalanceDayComparisonFlow flow) =>
      flow == BalanceDayComparisonFlow.income ? const Color(0xff18bba3) : _pink;
  List<Rect> barRects(Size size) {
    final slot = size.width / 4;
    final width = math.min(42.0, slot * .45);
    final usableHeight = math.max(0.0, size.height - width * .3 - 4);
    return [
      for (var i = 0; i < 4; i++)
        Rect.fromLTWH(
          size.width * const [.15, .35, .65, .85][i] - width / 2,
          usableHeight * (1 - scale.fractions[i]),
          width,
          usableHeight * scale.fractions[i],
        ),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rects = barRects(size);
    canvas.drawLine(
      Offset(size.width / 2, 4),
      Offset(size.width / 2, size.height - 4),
      Paint()
        ..color = const Color(0xffeef0f7)
        ..strokeWidth = 1,
    );
    for (var i = 0; i < rects.length; i++) {
      final rect = rects[i];
      final color = colorFor(scale.bars[i].flow);
      if (rect.height <= 0) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.bottom + 2),
          width: rect.width * 1.2,
          height: 4,
        ),
        Paint()
          ..color = color.withValues(alpha: .12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      final material = BudgetClayActiveMaterial.forSemanticBase(color);
      FluviYearClayCapsulePainter.paint(
        canvas,
        rect: rect,
        colors: material.colors,
        depthColors: material.depthColors,
        stops: material.stops,
        showDecorativeStrip: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BalanceDayComparisonPainter old) =>
      old.scale.source != scale.source;
}

final class _ImpactTube extends StatelessWidget {
  const _ImpactTube({required this.impact, this.compact = false});
  final DashboardBalanceDailyImpactPresentation impact;
  final bool compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => CustomPaint(
      painter: _ImpactPainter(
        impact,
        compact,
        Theme.of(context).textTheme.bodySmall?.fontFamily,
      ),
      size: Size(c.maxWidth, c.maxHeight),
    ),
  );
}

final class _ImpactPainter extends CustomPainter {
  const _ImpactPainter(this.impact, this.compact, this.fontFamily);
  final String? fontFamily;
  final DashboardBalanceDailyImpactPresentation impact;
  final bool compact;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 20 || size.height < 12) return;
    final h = compact
        ? math.min(18.0, size.height * .44)
        : math.min(50.0, size.height * .34);
    final rect = Rect.fromLTWH(
      8,
      size.height * .45 - h / 2,
      size.width - 16,
      h,
    );
    final round = RRect.fromRectAndRadius(rect, Radius.circular(h / 2));
    canvas.drawRRect(
      round.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0xff7987ae).withValues(alpha: .12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(compact ? 3 : 9),
        Radius.circular(h),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffeef2ff), Color(0xfff5e7f4)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      round,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xffc3defd),
            Color(0xffa5eddc),
            Color(0xfff6eff9),
            Color(0xffffb4dd),
          ],
          stops: [0, .36, .54, 1],
        ).createShader(rect),
    );
    canvas.drawRRect(
      round,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .7),
            Colors.white.withValues(alpha: 0),
            const Color(0xffb58db9).withValues(alpha: .1),
          ],
          stops: const [0, .45, 1],
        ).createShader(rect),
    );
    final zero = Offset(rect.center.dx, rect.center.dy);
    canvas.drawLine(
      Offset(zero.dx, rect.top - (compact ? 5 : 22)),
      Offset(zero.dx, rect.bottom + (compact ? 5 : 22)),
      Paint()
        ..color = const Color(0xffd9dcea)
        ..strokeWidth = 1,
    );
    if (impact.available) {
      final fraction = impact.markerFraction.clamp(0.0, 1.0);
      _sphere(
        canvas,
        Offset(rect.left + fraction * rect.width, rect.center.dy),
        h * .56,
        impact.isWorsening ? _pink : _green,
      );
    }
    for (var i = 0; i < 3; i++) {
      final label = i == 1
          ? '0%'
          : '${i == 0 ? '−' : '+'}${impact.scaleExtentPercent}%';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: compact ? 8 : 10,
            fontFamily: fontFamily,
            color: const Color(0xff607399),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = rect.left + rect.width * i / 2;
      text.paint(
        canvas,
        Offset(
          (x - text.width / 2).clamp(0.0, math.max(0, size.width - text.width)),
          math.min(size.height - text.height, rect.bottom + (compact ? 6 : 27)),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactPainter old) =>
      old.impact != impact ||
      old.compact != compact ||
      old.fontFamily != fontFamily;
}
