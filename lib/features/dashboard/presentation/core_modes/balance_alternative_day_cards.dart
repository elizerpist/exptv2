import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_alternative_extended_sheet_cards.dart';
import 'balance_alternative_visual_tokens.dart';

/// The Napi 4 primary coordinate visual. All ledger calculation was completed
/// by [DashboardBalanceDailyInsightsProjection] before this render boundary.
final class BalanceAlternativeDailyMomentumCoordinateCard
    extends StatelessWidget {
  const BalanceAlternativeDailyMomentumCoordinateCard({
    super.key,
    required this.presentation,
  });

  final DashboardBalanceDailyMomentumPresentation presentation;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        BalanceAlternativeHtmlTokens.logical(24),
        BalanceAlternativeHtmlTokens.logical(22),
        BalanceAlternativeHtmlTokens.logical(24),
        BalanceAlternativeHtmlTokens.logical(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  'Pénzügyi koordinátarendszer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _dayText(
                    25,
                    BalanceAlternativeHtmlTokens.textPrimary,
                    FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: BalanceAlternativeHtmlTokens.logical(7)),
              Icon(
                Icons.info_outline_rounded,
                size: BalanceAlternativeHtmlTokens.logical(23),
                color: BalanceAlternativeHtmlTokens.dailyMomentumAxis,
              ),
            ],
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(7)),
          Text(
            'Hol állok most?',
            style: _dayText(
              17,
              BalanceAlternativeHtmlTokens.textSecondary,
              FontWeight.w600,
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(13)),
          Expanded(
            child: presentation.available
                ? RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey<String>(
                        'balance-napi4-coordinate-map',
                      ),
                      painter: _DailyCoordinatePainter(presentation.selected),
                      child: const SizedBox.expand(),
                    ),
                  )
                : const _DayUnavailable(
                    copy: 'Még nincs 60 összehasonlítható nap',
                  ),
          ),
        ],
      ),
    ),
  );
}

/// The Napi 4 merged right-side Napi hatás card. Its percentage and scale are
/// a real expense-only presentation; the two bottom net figures are context.
final class BalanceAlternativeDailyImpactCard extends StatelessWidget {
  const BalanceAlternativeDailyImpactCard({
    super.key,
    required this.presentation,
  });

  final DashboardBalanceDailyImpactPresentation presentation;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.napi4ImpactCardMinimumContentSize,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        BalanceAlternativeHtmlTokens.logical(17),
        BalanceAlternativeHtmlTokens.logical(19),
        BalanceAlternativeHtmlTokens.logical(17),
        BalanceAlternativeHtmlTokens.logical(17),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < BalanceAlternativeHtmlTokens.logical(220);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Napi hatás',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _dayText(
                        28,
                        BalanceAlternativeHtmlTokens.textPrimary,
                        FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.info_outline_rounded,
                    size: BalanceAlternativeHtmlTokens.logical(23),
                    color: BalanceAlternativeHtmlTokens.dailyMomentumAxis,
                  ),
                ],
              ),
              SizedBox(height: BalanceAlternativeHtmlTokens.logical(8)),
              Text(
                'Mai nap hatása az elmúlt\nidőszakra',
                maxLines: 2,
                style: _dayText(
                  16,
                  BalanceAlternativeHtmlTokens.textSecondary,
                  FontWeight.w600,
                  height: 1.25,
                ),
              ),
              SizedBox(height: BalanceAlternativeHtmlTokens.logical(14)),
              if (presentation.available) ...<Widget>[
                Align(
                  alignment: Alignment.center,
                  child: _ImpactPill(presentation: presentation),
                ),
                SizedBox(height: BalanceAlternativeHtmlTokens.logical(12)),
                Expanded(
                  child: _ImpactTube(
                    presentation: presentation,
                    compact: compact,
                  ),
                ),
                SizedBox(height: BalanceAlternativeHtmlTokens.logical(7)),
                Text(
                  presentation.isWorsening
                      ? 'Rontja a 7 napos átlagot'
                      : presentation.isImproving
                      ? 'Javítja a 7 napos átlagot'
                      : 'Nem változtatja a 7 napos átlagot',
                  maxLines: 2,
                  style: _dayText(
                    17,
                    presentation.isWorsening
                        ? BalanceAlternativeHtmlTokens.dailyMomentumCoral
                        : BalanceAlternativeHtmlTokens.textPrimary,
                    FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ] else
                const Expanded(
                  child: _DayUnavailable(
                    copy: 'Nincs összehasonlítható előző 7 nap',
                  ),
                ),
              SizedBox(height: BalanceAlternativeHtmlTokens.logical(10)),
              const Divider(height: 1, color: Color(0xFFDCE5F0)),
              SizedBox(height: BalanceAlternativeHtmlTokens.logical(12)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ImpactContextValue(
                      label: 'Mai nettó',
                      value: presentation.todayNetMinor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: BalanceAlternativeHtmlTokens.logical(55),
                    color: const Color(0xFFD6E0EC),
                  ),
                  Expanded(
                    child: _ImpactContextValue(
                      label: 'Ref. átlag',
                      value: presentation.referenceAverageNetMinor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: BalanceAlternativeHtmlTokens.logical(13)),
              _ImpactCallToAction(presentation: presentation),
            ],
          );
        },
      ),
    ),
  );
}

/// The Napi 4 combined lower card. Its bars use the exact presentation points
/// that also determined the upper coordinate marker; it never re-aggregates.
final class BalanceAlternativeDailyMomentumRhythmCard extends StatelessWidget {
  const BalanceAlternativeDailyMomentumRhythmCard({
    super.key,
    required this.presentation,
  });

  final DashboardBalanceDailyMomentumPresentation presentation;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.napi4RhythmCardMinimumContentSize,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        BalanceAlternativeHtmlTokens.logical(22),
        BalanceAlternativeHtmlTokens.logical(18),
        BalanceAlternativeHtmlTokens.logical(22),
        BalanceAlternativeHtmlTokens.logical(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: BalanceAlternativeHtmlTokens.logical(48),
                height: BalanceAlternativeHtmlTokens.logical(48),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BalanceAlternativeHtmlTokens.dailyMomentumPurple
                      .withValues(alpha: .10),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: BalanceAlternativeHtmlTokens.dailyMomentumPurple,
                  size: BalanceAlternativeHtmlTokens.logical(31),
                ),
              ),
              SizedBox(width: BalanceAlternativeHtmlTokens.logical(13)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Összehasonlító ritmuscsík',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _dayText(
                        25,
                        BalanceAlternativeHtmlTokens.textPrimary,
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: BalanceAlternativeHtmlTokens.logical(5)),
                    Text(
                      'Előző 30 nap vs utolsó 30 nap',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _dayText(
                        16,
                        BalanceAlternativeHtmlTokens.textSecondary,
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: BalanceAlternativeHtmlTokens.logical(12),
                  vertical: BalanceAlternativeHtmlTokens.logical(7),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    BalanceAlternativeHtmlTokens.logical(13),
                  ),
                  border: Border.all(color: const Color(0xFFDDE5F0)),
                ),
                child: Text(
                  'Napi költség⌄',
                  style: _dayText(
                    15,
                    BalanceAlternativeHtmlTokens.supportingText,
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(10)),
          Expanded(
            child: presentation.available
                ? RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey<String>('balance-napi4-rhythm-strip'),
                      painter: _DailyRhythmPainter(presentation.rhythm),
                      child: const SizedBox.expand(),
                    ),
                  )
                : const _DayUnavailable(
                    copy: 'Még nincs 60 összehasonlítható nap',
                  ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(7)),
          if (presentation.available)
            Row(
              children: <Widget>[
                Expanded(
                  child: _RhythmWindowCopy(
                    label: 'Előző 30 nap',
                    value: presentation.selected.referenceExpenseMinor,
                  ),
                ),
                SizedBox(width: BalanceAlternativeHtmlTokens.logical(24)),
                Expanded(
                  child: _RhythmWindowCopy(
                    label: 'Utolsó 30 nap',
                    value: presentation.selected.currentExpenseMinor,
                    current: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

final class _ImpactPill extends StatelessWidget {
  const _ImpactPill({required this.presentation});

  final DashboardBalanceDailyImpactPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final color = presentation.isWorsening
        ? BalanceAlternativeHtmlTokens.dailyMomentumCoral
        : presentation.isImproving
        ? BalanceAlternativeHtmlTokens.dailyMomentumMint
        : BalanceAlternativeHtmlTokens.dailyMomentumPurple;
    return Container(
      key: ValueKey<String>(
        presentation.isWorsening
            ? 'balance-napi4-impact-pill-worsening'
            : 'balance-napi4-impact-pill-nonworsening',
      ),
      padding: EdgeInsets.symmetric(
        horizontal: BalanceAlternativeHtmlTokens.logical(22),
        vertical: BalanceAlternativeHtmlTokens.logical(8),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          BalanceAlternativeHtmlTokens.logical(32),
        ),
        gradient: LinearGradient(
          colors: <Color>[
            color.withValues(alpha: .07),
            color.withValues(alpha: .23),
            color.withValues(alpha: .08),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: .16),
            blurRadius: BalanceAlternativeHtmlTokens.logical(18),
          ),
        ],
      ),
      child: Text(
        _formatPercent(presentation.valuePercent!),
        style: _dayText(52, color, FontWeight.w900),
      ),
    );
  }
}

final class _ImpactTube extends StatelessWidget {
  const _ImpactTube({required this.presentation, required this.compact});

  final DashboardBalanceDailyImpactPresentation presentation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final extent = presentation.scaleExtentPercent;
    final half = (extent / 2).round();
    final markerColor = presentation.isWorsening
        ? BalanceAlternativeHtmlTokens.dailyMomentumCoral
        : presentation.isImproving
        ? BalanceAlternativeHtmlTokens.dailyMomentumMint
        : BalanceAlternativeHtmlTokens.dailyMomentumPurple;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: compact
                  ? constraints.maxWidth * .38
                  : BalanceAlternativeHtmlTokens.logical(64),
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9FD),
                borderRadius: BorderRadius.circular(
                  BalanceAlternativeHtmlTokens.logical(36),
                ),
                border: Border.all(color: const Color(0xFFDDE6F1)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x100D2859),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FractionallySizedBox(
                alignment: Alignment(0, 1 - presentation.markerFraction * 2),
                heightFactor: .49,
                widthFactor: .66,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: markerColor.withValues(alpha: .76),
                    borderRadius: BorderRadius.circular(
                      BalanceAlternativeHtmlTokens.logical(30),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: markerColor.withValues(alpha: .36),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: compact
                ? constraints.maxWidth * .49
                : BalanceAlternativeHtmlTokens.logical(83),
            right: 0,
            top: 0,
            bottom: 0,
            child: _ImpactScaleLabels(extent: extent, half: half),
          ),
        ],
      ),
    );
  }
}

final class _ImpactScaleLabels extends StatelessWidget {
  const _ImpactScaleLabels({required this.extent, required this.half});

  final int extent;
  final int half;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      _ImpactScaleLabel(value: '+$extent%'),
      _ImpactScaleLabel(value: '+$half%'),
      const _ImpactScaleLabel(value: '0%'),
      _ImpactScaleLabel(value: '-$half%'),
      _ImpactScaleLabel(value: '-$extent%'),
    ],
  );
}

final class _ImpactScaleLabel extends StatelessWidget {
  const _ImpactScaleLabel({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Container(
        width: BalanceAlternativeHtmlTokens.logical(29),
        height: BalanceAlternativeHtmlTokens.logical(2),
        color: const Color(0xFFB8C6DA),
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(10)),
      Text(
        value,
        style: _dayText(
          17,
          BalanceAlternativeHtmlTokens.dailyMomentumAxis,
          FontWeight.w700,
        ),
      ),
    ],
  );
}

final class _ImpactContextValue extends StatelessWidget {
  const _ImpactContextValue({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: BalanceAlternativeHtmlTokens.logical(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: _dayText(
            15,
            BalanceAlternativeHtmlTokens.textSecondary,
            FontWeight.w700,
          ),
        ),
        SizedBox(height: BalanceAlternativeHtmlTokens.logical(6)),
        Text(
          DashboardPreparedFormatter.amountMinor(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _dayText(
            22,
            BalanceAlternativeHtmlTokens.textPrimary,
            FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

final class _ImpactCallToAction extends StatelessWidget {
  const _ImpactCallToAction({required this.presentation});
  final DashboardBalanceDailyImpactPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final negative = presentation.isWorsening;
    final color = negative
        ? BalanceAlternativeHtmlTokens.dailyMomentumCoral
        : BalanceAlternativeHtmlTokens.dailyMomentumMint;
    return Container(
      height: BalanceAlternativeHtmlTokens.logical(47),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          BalanceAlternativeHtmlTokens.logical(26),
        ),
        gradient: LinearGradient(
          colors: <Color>[
            color.withValues(alpha: .13),
            color.withValues(alpha: .31),
          ],
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              negative
                  ? Icons.priority_high_rounded
                  : Icons.bar_chart_rounded,
              color: color,
              size: BalanceAlternativeHtmlTokens.logical(29),
            ),
            SizedBox(width: BalanceAlternativeHtmlTokens.logical(9)),
            Text(
              negative ? 'Figyelem' : 'Jó irány',
              style: _dayText(22, color, FontWeight.w800),
            ),
            SizedBox(width: BalanceAlternativeHtmlTokens.logical(7)),
            Icon(
              Icons.chevron_right_rounded,
              color: color,
              size: BalanceAlternativeHtmlTokens.logical(31),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RhythmWindowCopy extends StatelessWidget {
  const _RhythmWindowCopy({
    required this.label,
    required this.value,
    this.current = false,
  });
  final String label;
  final int value;
  final bool current;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: _dayText(
          15,
          BalanceAlternativeHtmlTokens.textSecondary,
          FontWeight.w700,
        ),
      ),
      SizedBox(height: BalanceAlternativeHtmlTokens.logical(4)),
      Row(
        children: <Widget>[
          Flexible(
            child: Text(
              DashboardPreparedFormatter.amountMinor(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _dayText(
                22,
                BalanceAlternativeHtmlTokens.textPrimary,
                FontWeight.w800,
              ),
            ),
          ),
          if (current) ...<Widget>[
            SizedBox(width: BalanceAlternativeHtmlTokens.logical(7)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: BalanceAlternativeHtmlTokens.logical(7),
                vertical: BalanceAlternativeHtmlTokens.logical(3),
              ),
              decoration: BoxDecoration(
                color: BalanceAlternativeHtmlTokens.dailyMomentumCoral
                    .withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'élő',
                style: _dayText(
                  12,
                  BalanceAlternativeHtmlTokens.dailyMomentumCoral,
                  FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

final class _DayUnavailable extends StatelessWidget {
  const _DayUnavailable({required this.copy});
  final String copy;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      copy,
      textAlign: TextAlign.center,
      style: _dayText(
        16,
        BalanceAlternativeHtmlTokens.textSecondary,
        FontWeight.w600,
        height: 1.25,
      ),
    ),
  );
}

final class _DailyCoordinatePainter extends CustomPainter {
  const _DailyCoordinatePainter(this.point);
  final DashboardBalanceDailyMomentumPoint point;

  @override
  void paint(Canvas canvas, Size size) {
    const source = Size(500, 400);
    final scale = math.min(
      size.width / source.width,
      size.height / source.height,
    );
    final offset = Offset(
      (size.width - source.width * scale) / 2,
      (size.height - source.height * scale) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    _paintSource(canvas);
    canvas.restore();
  }

  void _paintSource(Canvas canvas) {
    final outer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 8, 480, 382),
      const Radius.circular(29),
    );
    canvas.drawRRect(outer, Paint()..color = Colors.white);
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFDCE9EF),
    );
    final panel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(17, 15, 466, 368),
      const Radius.circular(25),
    );
    canvas.save();
    canvas.clipRRect(panel);
    canvas.drawRect(
      const Rect.fromLTWH(17, 15, 466, 368),
      Paint()..color = const Color(0xFFF8FCFC),
    );
    _field(
      canvas,
      const Offset(84, 73),
      BalanceAlternativeHtmlTokens.dailyMomentumFieldUpperLeft,
    );
    _field(
      canvas,
      const Offset(418, 75),
      BalanceAlternativeHtmlTokens.dailyMomentumFieldUpperRight,
    );
    _field(
      canvas,
      const Offset(83, 324),
      BalanceAlternativeHtmlTokens.dailyMomentumFieldLowerLeft,
    );
    _field(
      canvas,
      const Offset(420, 328),
      BalanceAlternativeHtmlTokens.dailyMomentumFieldLowerRight,
    );
    final center = const Offset(250, 180);
    canvas.drawCircle(
      center,
      150,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .75),
    );
    canvas.drawCircle(
      center,
      116,
      Paint()..color = BalanceAlternativeHtmlTokens.dailyMomentumRing,
    );
    canvas.drawCircle(
      center,
      105,
      Paint()
        ..color = const Color(0xFFEFF4F3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawCircle(
      center,
      86,
      Paint()..color = BalanceAlternativeHtmlTokens.dailyMomentumWell,
    );
    canvas.drawCircle(center, 80, Paint()..color = const Color(0xFFE6EFEF));
    canvas.drawCircle(
      const Offset(250, 190),
      55,
      Paint()
        ..color = const Color(0x3A8BB5A9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      center,
      55,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[const Color(0xFFEBFFF6), const Color(0xFFC5F2E5)],
        ).createShader(Rect.fromCircle(center: center, radius: 55)),
    );
    canvas.drawCircle(center, 26, Paint()..color = const Color(0xFFFDFEF8));
    _axes(canvas);
    _quadrant(
      canvas,
      const Offset(70, 85),
      Icons.eco_rounded,
      'Stabil\népítkezés',
      'Biztonságos\nalapok',
      BalanceAlternativeHtmlTokens.dailyMomentumMint,
    );
    _quadrant(
      canvas,
      const Offset(430, 85),
      Icons.bar_chart_rounded,
      'Növekedés',
      'Lehetőségek\nés fejlődés',
      BalanceAlternativeHtmlTokens.dailyMomentumTeal,
    );
    _quadrant(
      canvas,
      const Offset(70, 291),
      Icons.shield_outlined,
      'Óvatosság\nszükséges',
      'Megfontolt\nlépések',
      BalanceAlternativeHtmlTokens.dailyMomentumAxis,
    );
    _quadrant(
      canvas,
      const Offset(430, 291),
      Icons.warning_amber_rounded,
      'Figyelem\nszükséges',
      'Optimalizálási\nlehetőség',
      BalanceAlternativeHtmlTokens.dailyMomentumCoral,
    );
    _marker(canvas);
    canvas.restore();
  }

  void _field(Canvas canvas, Offset center, Color color) => canvas.drawCircle(
    center,
    235,
    Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: .85),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 235)),
  );

  void _axes(Canvas canvas) {
    final paint = Paint()
      ..color = BalanceAlternativeHtmlTokens.dailyMomentumAxis
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(48, 180), const Offset(452, 180), paint);
    canvas.drawLine(const Offset(250, 348), const Offset(250, 40), paint);
    _arrow(canvas, const Offset(48, 180), math.pi);
    _arrow(canvas, const Offset(452, 180), 0);
    _arrow(canvas, const Offset(250, 40), -math.pi / 2);
    _arrow(canvas, const Offset(250, 348), math.pi / 2);
    canvas.drawCircle(
      const Offset(250, 180),
      6,
      Paint()..color = BalanceAlternativeHtmlTokens.dailyMomentumAxis,
    );
    _paintDayText(
      canvas,
      'Bevétel',
      const Offset(250, 23),
      14,
      BalanceAlternativeHtmlTokens.textSecondary,
      FontWeight.w700,
      align: TextAlign.center,
    );
    _paintDayText(
      canvas,
      'Kiadás',
      const Offset(442, 171),
      14,
      BalanceAlternativeHtmlTokens.textSecondary,
      FontWeight.w700,
      align: TextAlign.right,
    );
  }

  void _arrow(Canvas canvas, Offset tip, double direction) {
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - 14 * math.cos(direction - .45),
        tip.dy - 14 * math.sin(direction - .45),
      )
      ..lineTo(
        tip.dx - 14 * math.cos(direction + .45),
        tip.dy - 14 * math.sin(direction + .45),
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = BalanceAlternativeHtmlTokens.dailyMomentumAxis,
    );
  }

  void _quadrant(
    Canvas canvas,
    Offset center,
    IconData icon,
    String title,
    String detail,
    Color color,
  ) {
    canvas.drawCircle(
      center,
      28,
      Paint()..color = Colors.white.withValues(alpha: .68),
    );
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: .28),
    );
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 28,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      center - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );
    _paintDayText(
      canvas,
      title,
      Offset(center.dx, center.dy + 40),
      15,
      color == BalanceAlternativeHtmlTokens.dailyMomentumCoral
          ? const Color(0xFF875C62)
          : const Color(0xFF0B6E62),
      FontWeight.w800,
      align: TextAlign.center,
    );
    _paintDayText(
      canvas,
      detail,
      Offset(center.dx, center.dy + 76),
      12,
      BalanceAlternativeHtmlTokens.textSecondary,
      FontWeight.w600,
      align: TextAlign.center,
    );
  }

  void _marker(Canvas canvas) {
    final pointPosition = Offset(
      250 + point.expenseAxis * 65,
      180 - point.incomeAxis * 56,
    );
    canvas.drawCircle(
      pointPosition + const Offset(0, 5),
      17,
      Paint()
        ..color = const Color(0x4020B78D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      pointPosition,
      15,
      Paint()..color = const Color(0xFFBFF4E4),
    );
    canvas.drawCircle(
      pointPosition,
      10,
      Paint()..color = BalanceAlternativeHtmlTokens.dailyMomentumMint,
    );
    canvas.drawCircle(pointPosition, 5, Paint()..color = Colors.white);
    final calloutX = (pointPosition.dx + 32).clamp(318, 365).toDouble();
    final calloutY = (pointPosition.dy - 25).clamp(204, 298).toDouble();
    final callout = RRect.fromRectAndRadius(
      Rect.fromLTWH(calloutX, calloutY, 122, 57),
      const Radius.circular(15),
    );
    final pointer = Path()
      ..moveTo(calloutX, calloutY + 29)
      ..lineTo(pointPosition.dx + 14, pointPosition.dy)
      ..lineTo(calloutX, calloutY + 39)
      ..close();
    canvas.drawPath(pointer, Paint()..color = const Color(0xFFF6FEFB));
    canvas.drawRRect(callout, Paint()..color = const Color(0xFFF6FEFB));
    canvas.drawRRect(
      callout,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = BalanceAlternativeHtmlTokens.dailyMomentumMint.withValues(
          alpha: .35,
        ),
    );
    _paintDayText(
      canvas,
      'Jelenlegi\npozíció',
      Offset(callout.center.dx, calloutY + 16),
      13,
      const Color(0xFF087162),
      FontWeight.w800,
      align: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyCoordinatePainter oldDelegate) =>
      oldDelegate.point != point;
}

final class _DailyRhythmPainter extends CustomPainter {
  const _DailyRhythmPainter(this.points);
  final List<DashboardBalanceDailyMomentumPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chartTop = 8.0;
    final chartBottom = math.max(chartTop + 10, size.height - 2);
    final dividerX = size.width / 2;
    final gap = 3.0;
    final groupWidth = (size.width - 18) / 2;
    final barWidth = math.max(2.0, (groupWidth - gap * 29) / 30);
    for (var index = 0; index < points.length; index += 1) {
      final right = index >= 30;
      final local = index % 30;
      final start = right ? dividerX + 9 : 0.0;
      final x = start + local * (barWidth + gap);
      final height = math
          .max(
            7,
            (chartBottom - chartTop) * (.12 + points[index].magnitude * .88),
          )
          .toDouble();
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartBottom - height, barWidth, height),
        const Radius.circular(4),
      );
      final color = right
          ? BalanceAlternativeHtmlTokens.dailyMomentumTeal
          : BalanceAlternativeHtmlTokens.dailyMomentumPurple;
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[color.withValues(alpha: .55), color],
          ).createShader(rect.outerRect),
      );
    }
    final divider = Paint()
      ..color = BalanceAlternativeHtmlTokens.dailyMomentumPurpleLight
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(dividerX, 0),
      Offset(dividerX, chartBottom),
      divider,
    );
    _paintDayText(
      canvas,
      '30',
      Offset(dividerX, 0),
      13,
      BalanceAlternativeHtmlTokens.dailyMomentumAxis,
      FontWeight.w700,
      align: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyRhythmPainter oldDelegate) =>
      oldDelegate.points != points;
}

TextStyle _dayText(
  double sourceSize,
  Color color,
  FontWeight weight, {
  double height = 1,
}) => TextStyle(
  fontFamily: 'Inter',
  fontSize: BalanceAlternativeHtmlTokens.logical(sourceSize),
  color: color,
  fontWeight: weight,
  height: height,
);

String _formatPercent(double value) {
  final rounded = value.round();
  return '${rounded >= 0 ? '+' : ''}$rounded%';
}

void _paintDayText(
  Canvas canvas,
  String value,
  Offset offset,
  double sourceSize,
  Color color,
  FontWeight weight, {
  TextAlign align = TextAlign.left,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: _dayText(sourceSize, color, weight, height: 1.1),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: value.contains('\n') ? 2 : 1,
  )..layout();
  final dx = switch (align) {
    TextAlign.center => offset.dx - painter.width / 2,
    TextAlign.right || TextAlign.end => offset.dx - painter.width,
    _ => offset.dx,
  };
  painter.paint(canvas, Offset(dx, offset.dy));
}
