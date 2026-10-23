import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'balance_daily_month_impact_presentation.dart';

/// One compact reference-card composition, never the four example cards at once.
final class BalanceDailyMonthImpactView extends StatefulWidget {
  const BalanceDailyMonthImpactView({super.key, required this.presentation});
  final BalanceDailyMonthImpactPresentation presentation;
  @override
  State<BalanceDailyMonthImpactView> createState() => _ImpactViewState();
}

class _ImpactViewState extends State<BalanceDailyMonthImpactView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late final Animation<double> _curve;
  late BalanceDailyMonthRibbonFrame _from, _to;
  BalanceDailyMonthRibbonFrame get _visible =>
      BalanceDailyMonthRibbonFrame.lerp(_from, _to, _curve.value);
  @override
  void initState() {
    super.initState();
    _from = _to = BalanceDailyMonthRibbonFrame.fromPresentation(
      widget.presentation,
    );
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1;
    _curve = CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant BalanceDailyMonthImpactView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = BalanceDailyMonthRibbonFrame.fromPresentation(
      widget.presentation,
    );
    if (next == _to) return;
    _from = _visible;
    _to = next;
    _motion.forward(from: 0);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _info() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 240),
      reverseDuration: Duration(milliseconds: 200),
    ),
    builder: (_) => const Padding(
      padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Napi hatás a havi nettóarányra',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12),
          Text(
            'A mutató megmutatja, hány százalékponttal változtatta meg a kiválasztott nap a hónap addigi nettóarányát. A nettóarány a bevétel és a kiadás különbségének bevételhez viszonyított százaléka.',
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final p = widget.presentation;
      final h = bounds.maxHeight;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            SizedBox(
              height: h * .11,
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Napi hatás a havi nettóarányra',
                        style: TextStyle(
                          fontSize: (h * .055).clamp(10, 17),
                          color: BalanceDailyMonthImpactColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: IconButton(
                      key: const ValueKey('balance-day-month-impact-info'),
                      padding: EdgeInsets.zero,
                      tooltip: 'A mutatóról',
                      onPressed: _info,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xff8e91c4),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: h * .20,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(p.valueColor, Colors.white, .20)!,
                        p.valueColor,
                      ],
                    ).createShader(rect),
                    child: Text(
                      p.deltaLabel,
                      key: const ValueKey('balance-day-month-impact-delta'),
                      style: TextStyle(
                        fontSize: (h * .20).clamp(22, 54),
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: h * .14,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    p.explanation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (h * .045).clamp(9, 16),
                      height: 1.25,
                      color: BalanceDailyMonthImpactColors.copy,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => CustomPaint(
                    key: const ValueKey('balance-day-month-impact-ribbon'),
                    size: Size.infinite,
                    painter: BalanceDailyMonthImpactRibbonPainter(
                      presentation: p,
                      frame: _visible,
                      fontFamily: Theme.of(
                        context,
                      ).textTheme.bodySmall?.fontFamily,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: h * .16,
              child: Padding(
                padding: EdgeInsets.fromLTRB(5, h * .015, 5, h * .008),
                child: Container(
                  key: const ValueKey('balance-day-month-impact-status'),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(h * .075),
                    gradient: LinearGradient(
                      colors: [
                        p.statusColor.withValues(alpha: .75),
                        p.statusColor,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        p.statusLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (h * .045).clamp(9, 15),
                          height: 1.15,
                          color:
                              p.state ==
                                  BalanceDailyMonthImpactState
                                      .increasedStillNegative
                              ? const Color(0xff2923a4)
                              : Color.lerp(p.valueColor, Colors.black, .40),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

@immutable
final class BalanceDailyMonthRibbonFrame {
  const BalanceDailyMonthRibbonFrame(this.direction, this.left, this.right);
  factory BalanceDailyMonthRibbonFrame.fromPresentation(
    BalanceDailyMonthImpactPresentation p,
  ) => BalanceDailyMonthRibbonFrame(p.direction, p.leftColor, p.rightColor);
  final double direction;
  final Color left, right;
  static BalanceDailyMonthRibbonFrame lerp(
    BalanceDailyMonthRibbonFrame a,
    BalanceDailyMonthRibbonFrame b,
    double t,
  ) => BalanceDailyMonthRibbonFrame(
    ui.lerpDouble(a.direction, b.direction, t)!,
    Color.lerp(a.left, b.left, t)!,
    Color.lerp(a.right, b.right, t)!,
  );
  @override
  bool operator ==(Object other) =>
      other is BalanceDailyMonthRibbonFrame &&
      other.direction == direction &&
      other.left == left &&
      other.right == right;
  @override
  int get hashCode => Object.hash(direction, left, right);
}

/// Closed upper/lower Bézier boundaries form a surface, not a stroked line.
/// The PNG's top gloss, darker lower face, cast shadow and spheres are distinct passes.
final class BalanceDailyMonthImpactRibbonPainter extends CustomPainter {
  const BalanceDailyMonthImpactRibbonPainter({
    required this.presentation,
    required this.frame,
    this.fontFamily,
  });
  final BalanceDailyMonthImpactPresentation presentation;
  final BalanceDailyMonthRibbonFrame frame;
  final String? fontFamily;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width, h = size.height;
    final d = frame.direction;
    final left = Offset(w * .12, h * (.29 + d * .12));
    final right = Offset(w * .88, h * (.29 - d * .12));
    final radius = math.min(w * .06, h * .20);
    final thick = h * .19;
    if (presentation.available) {
      final c1 = Offset(w * .43, left.dy + d * h * .12);
      final c2 = Offset(w * .57, right.dy - d * h * .10);
      final bounds = Rect.fromLTRB(
        left.dx,
        math.min(left.dy, right.dy) - thick,
        right.dx,
        math.max(left.dy, right.dy) + thick * 2,
      );
      final guide = Path()
        ..moveTo(w * .01, left.dy - h * .06)
        ..lineTo(left.dx, left.dy - h * .06)
        ..cubicTo(
          c1.dx,
          left.dy - h * .18,
          c2.dx,
          right.dy - h * .22,
          right.dx,
          right.dy - h * .06,
        )
        ..lineTo(w * .99, right.dy - h * .06);
      _dash(
        canvas,
        guide,
        Paint()
          ..color = Color.lerp(
            frame.left,
            frame.right,
            .5,
          )!.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      Path surface(double shift) => Path()
        ..moveTo(left.dx, left.dy - thick / 2 + shift)
        ..cubicTo(
          c1.dx,
          c1.dy - thick / 2 + shift,
          c2.dx,
          c2.dy - thick / 2 + shift,
          right.dx,
          right.dy - thick / 2 + shift,
        )
        ..lineTo(right.dx, right.dy + thick / 2 + shift)
        ..cubicTo(
          c2.dx,
          c2.dy + thick / 2 + shift,
          c1.dx,
          c1.dy + thick / 2 + shift,
          left.dx,
          left.dy + thick / 2 + shift,
        )
        ..close();
      final shadow = surface(h * .12);
      canvas.drawPath(
        shadow,
        Paint()
          ..shader = LinearGradient(
            colors: [
              frame.left.withValues(alpha: .22),
              frame.right.withValues(alpha: .28),
            ],
          ).createShader(bounds)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .10),
      );
      canvas.drawPath(
        surface(thick * .13),
        Paint()
          ..shader = LinearGradient(
            colors: [_shade(frame.left, .72), _shade(frame.right, .73)],
          ).createShader(bounds),
      );
      final front = surface(0);
      canvas.drawPath(
        front,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(frame.left, Colors.white, .16)!,
              Color.lerp(frame.left, frame.right, .5)!,
              frame.right,
            ],
          ).createShader(bounds),
      );
      canvas.save();
      canvas.clipPath(front);
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: .75),
              Colors.white.withValues(alpha: .02),
              Colors.black.withValues(alpha: .13),
            ],
            stops: const [0, .42, 1],
          ).createShader(bounds),
      );
      canvas.restore();
      // A separate curved upper bevel follows the ribbon, rather than a
      // viewport gradient flattening its changing height into a single stroke.
      final bevel = Path()
        ..moveTo(left.dx, left.dy - thick * .44)
        ..cubicTo(
          c1.dx,
          c1.dy - thick * .44,
          c2.dx,
          c2.dy - thick * .44,
          right.dx,
          right.dy - thick * .44,
        )
        ..lineTo(right.dx, right.dy - thick * .12)
        ..cubicTo(
          c2.dx,
          c2.dy - thick * .12,
          c1.dx,
          c1.dy - thick * .12,
          left.dx,
          left.dy - thick * .12,
        )
        ..close();
      canvas.drawPath(
        bevel,
        Paint()
          ..color = Colors.white.withValues(alpha: .22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, thick * .06),
      );
      final gloss = Path()
        ..moveTo(left.dx, left.dy - thick * .43)
        ..cubicTo(
          c1.dx,
          c1.dy - thick * .43,
          c2.dx,
          c2.dy - thick * .43,
          right.dx,
          right.dy - thick * .43,
        );
      canvas.drawPath(
        gloss,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, thick * .10)
          ..color = Colors.white.withValues(alpha: .65),
      );
      final lower = Path()
        ..moveTo(left.dx, left.dy + thick * .48)
        ..cubicTo(
          c1.dx,
          c1.dy + thick * .48,
          c2.dx,
          c2.dy + thick * .48,
          right.dx,
          right.dy + thick * .48,
        );
      canvas.drawPath(
        lower,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7
          ..color = Colors.white.withValues(alpha: .4),
      );
      _sphere(canvas, left, radius, frame.left);
      _sphere(canvas, right, radius, frame.right);
      final badge = Offset(w * .50, h * .23);
      final color = presentation.valueColor;
      canvas.drawCircle(
        badge,
        radius * .84,
        Paint()..color = presentation.statusColor,
      );
      canvas.drawCircle(
        badge,
        radius * .84,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65
          ..color = Colors.white,
      );
      final arrow = Path();
      final ar = radius * .34;
      if (d.abs() < .1) {
        arrow
          ..moveTo(badge.dx - ar, badge.dy)
          ..lineTo(badge.dx + ar, badge.dy);
      } else {
        final sign = d > 0 ? -1.0 : 1.0;
        arrow
          ..moveTo(badge.dx, badge.dy - sign * ar)
          ..lineTo(badge.dx, badge.dy + sign * ar)
          ..moveTo(badge.dx - ar * .65, badge.dy + sign * ar * .35)
          ..lineTo(badge.dx, badge.dy + sign * ar)
          ..lineTo(badge.dx + ar * .65, badge.dy + sign * ar * .35);
      }
      canvas.drawPath(
        arrow,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, radius * .13)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    } else if (presentation.afterPercent != null) {
      _sphere(canvas, right, radius, frame.right);
    }
    _label(
      canvas,
      presentation.beforeLabel,
      'ELŐTTE',
      Offset(left.dx, left.dy + radius + h * .11),
      w * .27,
      h,
    );
    _label(
      canvas,
      presentation.afterLabel,
      'UTÁNA',
      Offset(right.dx, right.dy + radius + h * .11),
      w * .27,
      h,
    );
  }

  void _label(
    Canvas c,
    String value,
    String label,
    Offset at,
    double maxWidth,
    double h,
  ) {
    final font = (h * .17).clamp(11.0, 25.0);
    final text = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$value\n',
            style: TextStyle(
              fontSize: font,
              fontWeight: FontWeight.w800,
              color: BalanceDailyMonthImpactColors.ink,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: font * .61,
              fontWeight: FontWeight.w500,
              color: BalanceDailyMonthImpactColors.copy,
              height: 1.4,
            ),
          ),
        ],
        style: TextStyle(fontFamily: fontFamily),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final x = (at.dx - text.width / 2).clamp(
      0.0,
      math.max(0.0, maxWidth / .27 - text.width),
    );
    text.paint(c, Offset(x.toDouble(), math.min(at.dy, h - text.height)));
  }

  static Color _shade(Color color, double factor) => Color.from(
    alpha: 1,
    red: color.r * factor,
    green: color.g * factor,
    blue: color.b * factor,
  );
  static void _sphere(Canvas c, Offset center, double r, Color base) {
    final rect = Rect.fromCircle(center: center, radius: r);
    c.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r * .92),
        width: r * 2.1,
        height: r * .62,
      ),
      Paint()
        ..color = base.withValues(alpha: .30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .40),
    );
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.42, -.55),
          radius: 1.17,
          colors: [
            Color.lerp(base, Colors.white, .78)!,
            Color.lerp(base, Colors.white, .26)!,
            base,
            _shade(base, .67),
          ],
          stops: const [0, .28, .65, 1],
        ).createShader(rect),
    );
    c.drawCircle(
      center,
      r * .98,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65
        ..color = Colors.white.withValues(alpha: .65),
    );
    c.drawOval(
      Rect.fromCenter(
        center: center - Offset(r * .35, r * .38),
        width: r * .42,
        height: r * .52,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: .62)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .06),
    );
    c.drawArc(
      rect.deflate(r * .09),
      math.pi * .05,
      math.pi * .75,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .10
        ..color = base.withValues(alpha: .5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .06),
    );
  }

  static void _dash(Canvas c, Path p, Paint paint) {
    for (final metric in p.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 10) {
        c.drawPath(
          metric.extractPath(start, math.min(start + 5, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BalanceDailyMonthImpactRibbonPainter old) =>
      old.presentation != presentation ||
      old.frame != frame ||
      old.fontFamily != fontFamily;
}
