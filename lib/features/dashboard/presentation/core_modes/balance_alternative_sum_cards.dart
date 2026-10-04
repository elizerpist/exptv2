import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/dashboard_balance_monthly_net_distribution_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_alternative_extended_sheet_cards.dart';
import 'balance_alternative_visual_tokens.dart';

/// The approved SUM sheet's adaptive monthly-net distribution card.
///
/// Its painter receives a complete immutable domain model: it performs no
/// ledger aggregation, bin selection, median calculation or color ownership.
final class BalanceAlternativeSumHistogramCard extends StatelessWidget {
  const BalanceAlternativeSumHistogramCard({
    super.key,
    required this.presentation,
  });

  final DashboardBalanceMonthlyNetHistogramPresentation presentation;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.extendedSheetPrimaryCardMinimumSize,
    child: Padding(
      padding: BalanceAlternativeHtmlTokens.sumHistogramPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: BalanceAlternativeHtmlTokens.sumHistogramHeadingHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Havi eredmények eloszlása',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sumText(
                    BalanceAlternativeHtmlTokens.sumHistogramTitleSize,
                    BalanceAlternativeHtmlTokens.textPrimary,
                    FontWeight.w800,
                    letterSpacing: -.04,
                  ),
                ),
                SizedBox(height: BalanceAlternativeHtmlTokens.logical(8)),
                Text(
                  'Minden lezárt hónap nettó eredménye',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sumText(
                    BalanceAlternativeHtmlTokens.sumHistogramSubtitleSize,
                    BalanceAlternativeHtmlTokens.textSecondary,
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.sumHistogramGap),
          Expanded(child: _HistogramPlot(presentation: presentation)),
          SizedBox(height: BalanceAlternativeHtmlTokens.sumHistogramGap),
          SizedBox(
            height: BalanceAlternativeHtmlTokens.sumHistogramInsightHeight,
            child: _HistogramInsight(presentation: presentation),
          ),
        ],
      ),
    ),
  );
}

final class _HistogramPlot extends StatelessWidget {
  const _HistogramPlot({required this.presentation});

  final DashboardBalanceMonthlyNetHistogramPresentation presentation;

  @override
  Widget build(BuildContext context) {
    if (presentation.sampleCount == 0) {
      return const Center(child: Text('Még nincs lezárt hónap'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final calloutWidth = math.min(
          BalanceAlternativeHtmlTokens.sumHistogramMedianCalloutWidth,
          constraints.maxWidth * .42,
        );
        final medianFraction = presentation.xFractionForValue(
          presentation.medianMinor,
        );
        final medianX = medianFraction * constraints.maxWidth;
        final calloutLeft =
            (medianX +
                            BalanceAlternativeHtmlTokens.logical(12) +
                            calloutWidth <=
                        constraints.maxWidth
                    ? medianX + BalanceAlternativeHtmlTokens.logical(12)
                    : medianX -
                          BalanceAlternativeHtmlTokens.logical(12) -
                          calloutWidth)
                .clamp(0.0, math.max(0, constraints.maxWidth - calloutWidth))
                .toDouble();
        return Semantics(
          label:
              '${presentation.sampleCount} lezárt hónap havi nettó eloszlása. Medián ${_formatCompactMinor(presentation.medianMinor)}.',
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: const ValueKey<String>(
                      'balance-alternative-sum-histogram-plot',
                    ),
                    painter: _HistogramPainter(presentation),
                  ),
                ),
              ),
              Positioned(
                top: BalanceAlternativeHtmlTokens.logical(53),
                left: calloutLeft,
                width: calloutWidth,
                height: BalanceAlternativeHtmlTokens
                    .sumHistogramMedianCalloutHeight,
                child: _HistogramMedianCallout(
                  value: _formatCompactMinor(presentation.medianMinor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _HistogramMedianCallout extends StatelessWidget {
  const _HistogramMedianCallout({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF8D64E8), Color(0xFFA06CE7)],
      ),
      borderRadius: BorderRadius.circular(
        BalanceAlternativeHtmlTokens.logical(13),
      ),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Medián',
            style: _sumText(
              BalanceAlternativeHtmlTokens.logical(14),
              Colors.white,
              FontWeight.w700,
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(2)),
          Text(
            value,
            style: _sumText(
              BalanceAlternativeHtmlTokens.logical(18),
              Colors.white,
              FontWeight.w800,
              letterSpacing: -.03,
            ),
          ),
        ],
      ),
    ),
  );
}

final class _HistogramInsight extends StatelessWidget {
  const _HistogramInsight({required this.presentation});

  final DashboardBalanceMonthlyNetHistogramPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final title = switch ((
      presentation.positiveObservationCount,
      presentation.negativeObservationCount,
    )) {
      (final positive, final negative) when positive > negative =>
        'A legtöbb hónap 0 Ft felett zár.',
      (final positive, final negative) when negative > positive =>
        'A legtöbb hónap 0 Ft alatt zár.',
      _ => 'A lezárt hónapok eredménye kiegyensúlyozott.',
    };
    final lower = presentation.typicalLowerMinor;
    final upper = presentation.typicalUpperMinor;
    final copy = lower == null || upper == null
        ? 'A tipikus tartományhoz még legalább 3 lezárt hónap szükséges.'
        : 'Az eredményeid jellemzően a ${_formatCompactMinor(lower)} – ${_formatCompactMinor(upper)} tartományban mozognak.';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            BalanceAlternativeHtmlTokens.sumInsightStart,
            BalanceAlternativeHtmlTokens.sumInsightEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(
          BalanceAlternativeHtmlTokens.logical(17),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: BalanceAlternativeHtmlTokens.logical(14),
          vertical: BalanceAlternativeHtmlTokens.logical(8),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.lightbulb_outline_rounded,
              size: BalanceAlternativeHtmlTokens.logical(31),
              color: BalanceAlternativeHtmlTokens.sumPurple,
            ),
            SizedBox(width: BalanceAlternativeHtmlTokens.logical(12)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sumText(
                      BalanceAlternativeHtmlTokens.sumHistogramInsightTitleSize,
                      const Color(0xFF4F28BE),
                      FontWeight.w800,
                      letterSpacing: -.03,
                    ),
                  ),
                  SizedBox(height: BalanceAlternativeHtmlTokens.logical(5)),
                  Text(
                    copy,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _sumText(
                      BalanceAlternativeHtmlTokens.sumHistogramInsightBodySize,
                      BalanceAlternativeHtmlTokens.textSecondary,
                      FontWeight.w600,
                      letterSpacing: -.02,
                      height: 1.16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The approved SUM side-card showing the longest strictly positive run.
final class BalanceAlternativePositiveStreakCard extends StatelessWidget {
  const BalanceAlternativePositiveStreakCard({
    super.key,
    required this.presentation,
  });

  final DashboardBalancePositiveStreakPresentation presentation;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.sumSideCardMinimumContentSize,
    child: Padding(
      padding: BalanceAlternativeHtmlTokens.sumStreakPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: BalanceAlternativeHtmlTokens.sumStreakHeadingHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFFEDF0FF), Color(0xFFE7FCF5)],
                    ),
                    borderRadius: BorderRadius.circular(
                      BalanceAlternativeHtmlTokens.logical(11),
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: BalanceAlternativeHtmlTokens.logical(31),
                    child: Icon(
                      Icons.trending_up_rounded,
                      size: BalanceAlternativeHtmlTokens.logical(21),
                      color: const Color(0xFF5F49D6),
                    ),
                  ),
                ),
                SizedBox(width: BalanceAlternativeHtmlTokens.logical(9)),
                Expanded(
                  child: Text(
                    'Leghosszabb pozitív széria',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _sumText(
                      BalanceAlternativeHtmlTokens.sumStreakTitleSize,
                      BalanceAlternativeHtmlTokens.textPrimary,
                      FontWeight.w800,
                      letterSpacing: -.035,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.sumStreakGap),
          SizedBox(
            height: BalanceAlternativeHtmlTokens.sumStreakValueHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${presentation.length}',
                  style: _sumText(
                    BalanceAlternativeHtmlTokens.sumStreakValueSize,
                    BalanceAlternativeHtmlTokens.positive,
                    FontWeight.w800,
                    letterSpacing: -.065,
                    height: .9,
                  ),
                ),
                SizedBox(width: BalanceAlternativeHtmlTokens.logical(6)),
                Text(
                  'hónap',
                  style: _sumText(
                    BalanceAlternativeHtmlTokens.logical(15),
                    const Color(0xFF52658A),
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.sumStreakGap),
          SizedBox(
            height: BalanceAlternativeHtmlTokens.sumStreakCopyHeight,
            child: Text(
              presentation.length == 0
                  ? 'Még nincs pozitív zárási széria'
                  : 'Egymást követő pozitív zárások',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _sumText(
                BalanceAlternativeHtmlTokens.sumStreakBodySize,
                BalanceAlternativeHtmlTokens.textSecondary,
                FontWeight.w600,
                letterSpacing: -.015,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.sumStreakGap),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFF0EEFF), Color(0xFFEBFAF5)],
                ),
                borderRadius: BorderRadius.circular(
                  BalanceAlternativeHtmlTokens.logical(13),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: BalanceAlternativeHtmlTokens.logical(8),
                  vertical: BalanceAlternativeHtmlTokens.logical(5),
                ),
                child: RepaintBoundary(
                  child: CustomPaint(
                    key: const ValueKey<String>(
                      'balance-alternative-sum-streak-plot',
                    ),
                    painter: _PositiveStreakPainter(presentation),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The lower SUM distribution interpretation card. It consumes the existing
/// median/MAD presentation through its immutable band model and never emits a
/// subjective stable/unstable score.
final class BalanceAlternativeCashflowStabilityBandCard
    extends StatelessWidget {
  const BalanceAlternativeCashflowStabilityBandCard({
    super.key,
    required this.presentation,
  });

  final DashboardBalanceCashflowStabilityBandPresentation presentation;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.sumCombinedCardMinimumContentSize,
    child: Padding(
      padding: BalanceAlternativeHtmlTokens.sumStabilityPadding,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: BalanceAlternativeHtmlTokens.sumStabilityHeadingHeight,
            child: _StabilityHeading(presentation: presentation),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.sumStabilityGap),
          Flexible(
            flex: 2,
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey<String>(
                  'balance-alternative-sum-stability-band',
                ),
                painter: _CashflowStabilityBandPainter(presentation),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.sumStabilityGap),
          const Flexible(flex: 3, child: _StabilityLegend()),
        ],
      ),
    ),
  );
}

final class _StabilityHeading extends StatelessWidget {
  const _StabilityHeading({required this.presentation});

  final DashboardBalanceCashflowStabilityBandPresentation presentation;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFEEE8FF), Color(0xFFFAF8FF)],
          ),
          borderRadius: BorderRadius.circular(
            BalanceAlternativeHtmlTokens.logical(14),
          ),
        ),
        child: SizedBox.square(
          dimension: BalanceAlternativeHtmlTokens.logical(42),
          child: Icon(
            Icons.bar_chart_rounded,
            color: BalanceAlternativeHtmlTokens.sumPurple,
            size: BalanceAlternativeHtmlTokens.logical(26),
          ),
        ),
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(12)),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Cashflow stabilitás',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _sumText(
                BalanceAlternativeHtmlTokens.sumStabilityTitleSize,
                BalanceAlternativeHtmlTokens.textPrimary,
                FontWeight.w800,
                letterSpacing: -.035,
              ),
            ),
            SizedBox(height: BalanceAlternativeHtmlTokens.logical(6)),
            Text(
              'Összes lezárt hónap alapján',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _sumText(
                BalanceAlternativeHtmlTokens.sumStabilitySubtitleSize,
                BalanceAlternativeHtmlTokens.textSecondary,
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(8)),
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(
            BalanceAlternativeHtmlTokens.logical(14),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: BalanceAlternativeHtmlTokens.logical(11),
            vertical: BalanceAlternativeHtmlTokens.logical(9),
          ),
          child: Text(
            '${presentation.sampleCount} lezárt hónap',
            style: _sumText(
              BalanceAlternativeHtmlTokens.sumStabilityChipSize,
              BalanceAlternativeHtmlTokens.sumPurple,
              FontWeight.w800,
            ),
          ),
        ),
      ),
    ],
  );
}

final class _StabilityLegend extends StatelessWidget {
  const _StabilityLegend();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _legendRow(
        size: BalanceAlternativeHtmlTokens.logical(24),
        color: const Color(0xFFB69AFF),
        copy: 'A havi eredményeid jellemzően ebben a sávban mozognak.',
      ),
      SizedBox(height: BalanceAlternativeHtmlTokens.logical(10)),
      _legendRow(
        size: BalanceAlternativeHtmlTokens.logical(15),
        color: const Color(0xFFE5DCFF),
        copy: 'Minden pont egy lezárt hónapot jelöl.',
      ),
    ],
  );

  Widget _legendRow({
    required double size,
    required Color color,
    required String copy,
  }) => Row(
    children: <Widget>[
      SizedBox(
        width: BalanceAlternativeHtmlTokens.logical(24),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: SizedBox.square(dimension: size),
          ),
        ),
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(13)),
      Expanded(
        child: Text(
          copy,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _sumText(
            BalanceAlternativeHtmlTokens.sumStabilityLegendSize,
            BalanceAlternativeHtmlTokens.textSecondary,
            FontWeight.w600,
            letterSpacing: -.02,
            height: 1.15,
          ),
        ),
      ),
    ],
  );
}

final class _HistogramPainter extends CustomPainter {
  const _HistogramPainter(this.presentation);

  final DashboardBalanceMonthlyNetHistogramPresentation presentation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || presentation.bins.isEmpty) return;
    final plot = Rect.fromLTRB(
      BalanceAlternativeHtmlTokens.logical(47),
      BalanceAlternativeHtmlTokens.logical(62),
      size.width - BalanceAlternativeHtmlTokens.logical(12),
      size.height - BalanceAlternativeHtmlTokens.logical(36),
    );
    if (plot.width <= 0 || plot.height <= 0) return;
    final maximumCount = presentation.bins.fold<int>(
      1,
      (maximum, bin) => math.max(maximum, bin.count),
    );
    final yMaximum = maximumCount <= 1 ? 1 : (maximumCount / 2).ceil() * 2;
    final paint = Paint()..isAntiAlias = true;
    final labelStyle = _sumText(
      BalanceAlternativeHtmlTokens.logical(14),
      BalanceAlternativeHtmlTokens.textSecondary,
      FontWeight.w600,
    );
    final grid = Paint()
      ..color = BalanceAlternativeHtmlTokens.chartGrid
      ..strokeWidth = BalanceAlternativeHtmlTokens.logical(1.2);
    for (var tick = 0; tick <= 4; tick += 1) {
      final count = yMaximum * tick / 4;
      final y = plot.bottom - count / yMaximum * plot.height;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _paintText(
        canvas,
        '${count.round()}',
        labelStyle,
        Offset(plot.left - BalanceAlternativeHtmlTokens.logical(12), y),
        alignment: TextAlign.right,
      );
    }
    _paintText(canvas, 'Hónapok\nszáma', labelStyle, const Offset(0, 0));

    final gap = BalanceAlternativeHtmlTokens.logical(6);
    final barWidth =
        (plot.width - gap * (presentation.bins.length - 1)) /
        presentation.bins.length;
    final underflowOffset = presentation.underflowBin == null ? 0 : 1;
    final regularLeft = plot.left + underflowOffset * (barWidth + gap);
    final regularRight =
        regularLeft +
        presentation.regularBins.length * barWidth +
        math.max(0, presentation.regularBins.length - 1) * gap;
    double xFor(double value) =>
        plot.left + presentation.xFractionForValue(value) * plot.width;

    final lower = presentation.typicalLowerMinor;
    final upper = presentation.typicalUpperMinor;
    if (lower != null && upper != null) {
      final left = xFor(lower).clamp(regularLeft, regularRight).toDouble();
      final right = xFor(upper).clamp(regularLeft, regularRight).toDouble();
      if (right > left + 2) {
        final band = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            left,
            BalanceAlternativeHtmlTokens.logical(11),
            right,
            plot.bottom,
          ),
          Radius.circular(BalanceAlternativeHtmlTokens.logical(12)),
        );
        canvas.drawRRect(
          band,
          Paint()
            ..color = BalanceAlternativeHtmlTokens.sumPurpleLight.withValues(
              alpha: .68,
            ),
        );
        final center = (left + right) / 2;
        _paintText(
          canvas,
          'Tipikus tartomány',
          _sumText(
            BalanceAlternativeHtmlTokens.logical(15),
            const Color(0xFF7950DC),
            FontWeight.w800,
          ),
          Offset(center, BalanceAlternativeHtmlTokens.logical(20)),
          alignment: TextAlign.center,
        );
        final arrowY = BalanceAlternativeHtmlTokens.logical(38);
        final arrow = Paint()
          ..color = const Color(0xFF9B7BF4)
          ..strokeWidth = BalanceAlternativeHtmlTokens.logical(2.2)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(left + BalanceAlternativeHtmlTokens.logical(10), arrowY),
          Offset(right - BalanceAlternativeHtmlTokens.logical(10), arrowY),
          arrow,
        );
      }
    }

    for (var index = 0; index < presentation.bins.length; index += 1) {
      final bin = presentation.bins[index];
      if (bin.count == 0) continue;
      final x = plot.left + index * (barWidth + gap);
      final y = plot.bottom - bin.count / yMaximum * plot.height;
      final color = BalanceAlternativeHtmlTokens.sumHistogramColorForNet(
        netMinor: bin.representativeMinor,
        regularDomainMinimumMinor: presentation.regularStartMinor,
        regularDomainMaximumMinor: presentation.regularEndMinor,
      );
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, plot.bottom - y),
        Radius.circular(BalanceAlternativeHtmlTokens.logical(4)),
      );
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color.lerp(color, Colors.white, .35)!, color],
      ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);
      paint.shader = null;
      if (bin.kind != DashboardBalanceHistogramBinKind.regular) {
        _dashedRRect(
          canvas,
          rect,
          color: bin.kind == DashboardBalanceHistogramBinKind.underflow
              ? const Color(0xFFF0A1AE)
              : const Color(0xFF75D9B0),
        );
      }
    }
    final zeroX = plot.left + presentation.zeroReferenceFraction * plot.width;
    _dashedLine(
      canvas,
      Offset(zeroX, BalanceAlternativeHtmlTokens.logical(52)),
      Offset(zeroX, plot.bottom + BalanceAlternativeHtmlTokens.logical(8)),
      color: const Color(0xFF7487A9),
      strokeWidth: BalanceAlternativeHtmlTokens.logical(1.8),
    );
    _paintText(
      canvas,
      '0 Ft',
      _sumText(
        BalanceAlternativeHtmlTokens.logical(14),
        const Color(0xFF52658A),
        FontWeight.w700,
      ),
      Offset(
        zeroX - BalanceAlternativeHtmlTokens.logical(8),
        BalanceAlternativeHtmlTokens.logical(52),
      ),
      alignment: TextAlign.right,
    );
    final medianX = xFor(
      presentation.medianMinor,
    ).clamp(regularLeft, regularRight).toDouble();
    canvas.drawLine(
      Offset(medianX, BalanceAlternativeHtmlTokens.logical(95)),
      Offset(medianX, plot.bottom + BalanceAlternativeHtmlTokens.logical(8)),
      Paint()
        ..color = const Color(0xFF7146DB)
        ..strokeWidth = BalanceAlternativeHtmlTokens.logical(3.4),
    );
    final xTicks = presentation.hasZeroRegularBoundary
        ? <double>[
            presentation.regularStartMinor,
            presentation.regularStartMinor / 2,
            0,
            presentation.regularEndMinor / 2,
            presentation.regularEndMinor,
          ]
        : <double>[
            presentation.regularStartMinor,
            (presentation.regularStartMinor + presentation.regularEndMinor) / 2,
            presentation.regularEndMinor,
          ];
    for (final tick in xTicks.toSet()) {
      final x = xFor(tick);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = const Color(0xFFEDF0F5)
          ..strokeWidth = BalanceAlternativeHtmlTokens.logical(1.2),
      );
      _paintText(
        canvas,
        _formatCompactMinor(tick),
        labelStyle,
        Offset(x, plot.bottom + BalanceAlternativeHtmlTokens.logical(12)),
        alignment: TextAlign.center,
      );
    }
    _paintText(
      canvas,
      'Havi nettó eredmény (Ft)',
      labelStyle,
      Offset(
        plot.center.dx,
        size.height - BalanceAlternativeHtmlTokens.logical(3),
      ),
      alignment: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) =>
      oldDelegate.presentation != presentation;
}

final class _PositiveStreakPainter extends CustomPainter {
  const _PositiveStreakPainter(this.presentation);

  final DashboardBalancePositiveStreakPresentation presentation;

  @override
  void paint(Canvas canvas, Size size) {
    final values = presentation.netValuesMinor.take(6).toList(growable: false);
    if (values.isEmpty) {
      _dashedLine(
        canvas,
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        color: const Color(0xFFC9D1DF),
        strokeWidth: BalanceAlternativeHtmlTokens.logical(2.5),
      );
      return;
    }
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final span = math.max(1, maximum - minimum);
    final points = <Offset>[
      for (var index = 0; index < values.length; index += 1)
        Offset(
          values.length == 1
              ? size.width / 2
              : index * size.width / (values.length - 1),
          size.height * .78 -
              (values[index] - minimum) / span * size.height * .55,
        ),
    ];
    final rainbow = BalanceAlternativeHtmlTokens.sumOriginalSoftRainbow;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[rainbow[5], rainbow[8]],
        ).createShader(Rect.fromPoints(points.first, points.last))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = BalanceAlternativeHtmlTokens.logical(3),
    );
    for (var index = 0; index < points.length; index += 1) {
      final amount = points.length == 1 ? .5 : index / (points.length - 1);
      final color = Color.lerp(rainbow[5], rainbow[9], amount)!;
      canvas.drawCircle(
        points[index],
        BalanceAlternativeHtmlTokens.logical(4.6),
        Paint()..color = color,
      );
      canvas.drawCircle(
        points[index],
        BalanceAlternativeHtmlTokens.logical(4.6),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = BalanceAlternativeHtmlTokens.logical(1.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PositiveStreakPainter oldDelegate) =>
      oldDelegate.presentation != presentation;
}

final class _CashflowStabilityBandPainter extends CustomPainter {
  const _CashflowStabilityBandPainter(this.presentation);

  final DashboardBalanceCashflowStabilityBandPresentation presentation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !presentation.isAvailable) {
      _paintText(
        canvas,
        'Még nincs elég lezárt hónap',
        _sumText(
          BalanceAlternativeHtmlTokens.sumStabilitySubtitleSize,
          BalanceAlternativeHtmlTokens.textSecondary,
          FontWeight.w600,
        ),
        Offset(size.width / 2, size.height / 2),
        alignment: TextAlign.center,
      );
      return;
    }
    final surface = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * .44, size.width, size.height * .56),
      Radius.circular(BalanceAlternativeHtmlTokens.logical(19)),
    );
    canvas.drawRRect(
      surface,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            BalanceAlternativeHtmlTokens.sumBandNegative,
            BalanceAlternativeHtmlTokens.sumBandPurpleStart,
            BalanceAlternativeHtmlTokens.sumBandPurpleEnd,
            BalanceAlternativeHtmlTokens.sumBandPositive,
          ],
          stops: <double>[0, .2, .86, 1],
        ).createShader(surface.outerRect),
    );
    final lower = presentation.typicalLowerTimesTwo!;
    final upper = presentation.typicalUpperTimesTwo!;
    final median = presentation.medianNetTimesTwo!;
    final positions = <(int, _BandRuleKind)>[
      (lower, _BandRuleKind.bound),
      (0, _BandRuleKind.zero),
      (median, _BandRuleKind.median),
      (upper, _BandRuleKind.bound),
    ];
    for (final (value, kind) in positions) {
      final x = presentation.xFractionForTimesTwo(value) * size.width;
      final label = kind == _BandRuleKind.median
          ? 'Medián\n${_formatCompactTimesTwo(value)}'
          : _formatCompactTimesTwo(value);
      _paintText(
        canvas,
        label,
        _sumText(
          kind == _BandRuleKind.median
              ? BalanceAlternativeHtmlTokens.logical(14)
              : BalanceAlternativeHtmlTokens.logical(15),
          kind == _BandRuleKind.median
              ? BalanceAlternativeHtmlTokens.sumPurple
              : const Color(0xFF52658A),
          kind == _BandRuleKind.median ? FontWeight.w800 : FontWeight.w700,
          height: 1.15,
        ),
        Offset(x, kind == _BandRuleKind.median ? 0 : size.height * .18),
        alignment: TextAlign.center,
      );
      final rule = Paint()
        ..color = switch (kind) {
          _BandRuleKind.bound => BalanceAlternativeHtmlTokens.sumBandRule,
          _BandRuleKind.zero => BalanceAlternativeHtmlTokens.sumBandZeroRule,
          _BandRuleKind.median => BalanceAlternativeHtmlTokens.sumPurple,
        }
        ..strokeWidth = kind == _BandRuleKind.median
            ? BalanceAlternativeHtmlTokens.logical(3)
            : BalanceAlternativeHtmlTokens.logical(2);
      if (kind == _BandRuleKind.bound) {
        _dashedLine(
          canvas,
          Offset(x, size.height * .36),
          Offset(x, size.height),
          color: rule.color,
          strokeWidth: rule.strokeWidth,
        );
      } else {
        canvas.drawLine(
          Offset(x, size.height * .36),
          Offset(x, size.height),
          rule,
        );
      }
    }
    for (final (index, value) in presentation.observationNetTimesTwo.indexed) {
      final x = presentation.xFractionForTimesTwo(value) * size.width;
      final y = size.height * (.53 + ((index * 17) % 29) / 100);
      final isMedian = value == median;
      final color = value < 0
          ? BalanceAlternativeHtmlTokens.sumBandNegativeDot
          : value > 0
          ? BalanceAlternativeHtmlTokens.sumBandPositiveDot
          : BalanceAlternativeHtmlTokens.sumBandDot;
      canvas.drawCircle(
        Offset(x, y),
        BalanceAlternativeHtmlTokens.logical(isMedian ? 8 : 5.5),
        Paint()
          ..color = isMedian ? BalanceAlternativeHtmlTokens.sumPurple : color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CashflowStabilityBandPainter oldDelegate) =>
      oldDelegate.presentation != presentation;
}

enum _BandRuleKind { bound, zero, median }

TextStyle _sumText(
  double fontSize,
  Color color,
  FontWeight weight, {
  double? letterSpacing,
  double height = 1,
}) => TextStyle(
  fontFamily: 'Inter',
  fontSize: fontSize,
  color: color,
  fontWeight: weight,
  letterSpacing: letterSpacing,
  height: height,
);

String _formatCompactMinor(double valueMinor) {
  final rounded = valueMinor.round();
  final compact = DashboardPreparedFormatter.compactAmountMinor(
    rounded,
  ).replaceFirst(' k Ft', 'k Ft');
  return rounded > 0 ? '+$compact' : compact;
}

String _formatCompactTimesTwo(int valueTimesTwo) =>
    _formatCompactMinor(valueTimesTwo / 2);

void _paintText(
  Canvas canvas,
  String value,
  TextStyle style,
  Offset offset, {
  TextAlign alignment = TextAlign.left,
}) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textAlign: alignment,
    textDirection: TextDirection.ltr,
    maxLines: value.contains('\n') ? 2 : 1,
  )..layout();
  final dx = switch (alignment) {
    TextAlign.center => offset.dx - painter.width / 2,
    TextAlign.right || TextAlign.end => offset.dx - painter.width,
    _ => offset.dx,
  };
  painter.paint(canvas, Offset(dx, offset.dy - painter.height / 2));
}

void _dashedLine(
  Canvas canvas,
  Offset start,
  Offset end, {
  required Color color,
  required double strokeWidth,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;
  final distance = (end - start).distance;
  const dash = 5.0;
  const gap = 4.0;
  final direction = distance == 0 ? Offset.zero : (end - start) / distance;
  for (var travelled = 0.0; travelled < distance; travelled += dash + gap) {
    canvas.drawLine(
      start + direction * travelled,
      start + direction * math.min(travelled + dash, distance),
      paint,
    );
  }
}

void _dashedRRect(Canvas canvas, RRect rect, {required Color color}) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = BalanceAlternativeHtmlTokens.logical(1.2);
  canvas.drawRRect(rect, paint);
}
