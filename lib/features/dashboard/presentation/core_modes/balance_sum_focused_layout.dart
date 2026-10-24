import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_monthly_net_distribution_projection.dart';
import 'balance_alternative_scope_presentation.dart';
import 'balance_focused_layout_geometry.dart';
import 'balance_focused_cascade.dart';
import 'balance_presentation_settings.dart';
import 'balance_sum_focused_chart_presentation.dart';
import 'balance_sum_positive_ratio_gauge.dart';

extension BalanceSumPerspectiveContent on BalanceSumFocusedPresentation {
  String get title => switch (this) {
    BalanceSumFocusedPresentation.distribution => 'Eredmények eloszlása',
    BalanceSumFocusedPresentation.positiveRatio => 'Pozitív hónapok aránya',
    BalanceSumFocusedPresentation.stability => 'Pénzügyi stabilitás',
  };
  String get subtitle => switch (this) {
    BalanceSumFocusedPresentation.distribution =>
      'Milyen eredményekkel szoktam zárni?',
    BalanceSumFocusedPresentation.positiveRatio =>
      'Milyen gyakran zárok pozitívan?',
    BalanceSumFocusedPresentation.stability =>
      'Mennyire ingadoznak az eredményeim?',
  };
  String get shortLabel => switch (this) {
    BalanceSumFocusedPresentation.distribution => 'Eloszlás',
    BalanceSumFocusedPresentation.positiveRatio => 'Pozitív arány',
    BalanceSumFocusedPresentation.stability => 'Stabilitás',
  };
  IconData get icon => switch (this) {
    BalanceSumFocusedPresentation.distribution => Icons.bar_chart_rounded,
    BalanceSumFocusedPresentation.positiveRatio => Icons.speed_rounded,
    BalanceSumFocusedPresentation.stability => Icons.scatter_plot_rounded,
  };
}

/// One controlled presentation boundary: the Dashboard preference owner keeps
/// selection, while immutable chart preparation is independent of selection.
final class BalanceSumFocusedLayout extends StatefulWidget {
  const BalanceSumFocusedLayout({
    super.key,
    required this.presentation,
    required this.perspective,
    required this.showSupplementaryStats,
    this.onPerspectiveChanged,
  });
  final BalanceAlternativeSumPresentation presentation;
  final BalanceSumFocusedPresentation perspective;
  final bool showSupplementaryStats;
  final ValueChanged<BalanceSumFocusedPresentation>? onPerspectiveChanged;
  @override
  State<BalanceSumFocusedLayout> createState() =>
      _BalanceSumFocusedLayoutState();
}

class _BalanceSumFocusedLayoutState extends State<BalanceSumFocusedLayout> {
  late BalanceSumFocusedChartPresentation _chart;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant BalanceSumFocusedLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.sourcePresentationId !=
            widget.presentation.sourcePresentationId ||
        !identical(
          oldWidget.presentation.distribution,
          widget.presentation.distribution,
        )) {
      _prepare();
    }
  }

  void _prepare() {
    _chart = BalanceSumFocusedChartPresentation.fromScope(widget.presentation);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final p = widget.perspective;
      final height = BalanceFocusedLayoutGeometry.topSectionHeight(
        constraints.maxHeight,
      );
      final stats = switch (p) {
        BalanceSumFocusedPresentation.distribution => _chart.distributionStats,
        BalanceSumFocusedPresentation.positiveRatio =>
          _chart.positiveRatioStats,
        BalanceSumFocusedPresentation.stability => _chart.stabilityStats,
      };
      return Padding(
        key: const ValueKey('balance-sum-focused-layout'),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: BalanceFocusedCascadeColumn(
          horizontalPadding: 14,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('balance-sum-focused-selector-zone'),
              height: height,
              child: _selector(height),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FluviVisualTokens.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${_chart.sampleCount} hónap',
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
            Text(
              p.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                color: FluviVisualTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: RepaintBoundary(
                key: ValueKey('balance-sum-chart-${p.name}'),
                child: p == BalanceSumFocusedPresentation.positiveRatio
                    ? BalanceSumPositiveRatioGauge(
                        positiveCount: _chart.positiveCount,
                        sampleCount: _chart.sampleCount,
                      )
                    : p == BalanceSumFocusedPresentation.distribution &&
                          _chart.sampleCount == 0
                    ? const Center(
                        child: Text(
                          'Még nincs lezárt hónap',
                          style: TextStyle(fontSize: 11),
                        ),
                      )
                    : p == BalanceSumFocusedPresentation.stability &&
                          !_chart.cashflowBand.isAvailable
                    ? const Center(
                        child: Text(
                          'Legalább 3 lezárt hónap szükséges',
                          style: TextStyle(fontSize: 11),
                        ),
                      )
                    : Semantics(
                        label: '${p.title}. ${stats.join('. ')}',
                        child: CustomPaint(
                          key: const ValueKey('balance-sum-focused-plot'),
                          size: Size.infinite,
                          painter: BalanceSumFocusedChartPainter(
                            chart: _chart,
                            histogram: _chart.histogram,
                            band: _chart.cashflowBand,
                            perspective: p,
                            fontFamily: Theme.of(
                              context,
                            ).textTheme.bodySmall?.fontFamily,
                          ),
                        ),
                      ),
              ),
            ),
            if (widget.showSupplementaryStats)
              Padding(
                key: const ValueKey('balance-sum-focused-stats'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final stat in stats)
                      Text(
                        stat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: FluviVisualTokens.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
  Widget _selector(double height) {
    final p = widget.perspective;
    final order = [
      BalanceSumFocusedPresentation.values[(p.index + 2) % 3],
      p,
      BalanceSumFocusedPresentation.values[(p.index + 1) % 3],
    ];
    final diameter = math.min(56.0, math.max(18.0, height - 24));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final item in order)
                Semantics(
                  button: true,
                  selected: item == p,
                  label: item.title,
                  child: GestureDetector(
                    key: ValueKey('balance-sum-perspective-${item.name}'),
                    onTap: widget.onPerspectiveChanged == null
                        ? null
                        : () => widget.onPerspectiveChanged!(item),
                    child: Container(
                      width: item == p ? diameter : diameter * .76,
                      height: item == p ? diameter : diameter * .76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item == p
                              ? const [
                                  Color(0xfff5f0ff),
                                  Color(0xffd9c9f2),
                                  Color(0xffc7b0e6),
                                ]
                              : const [Color(0xfffaf8ff), Color(0xffeee8f7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff75618e,
                            ).withValues(alpha: item == p ? .18 : .09),
                            blurRadius: 7,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        size: diameter * .45,
                        color: item == p
                            ? const Color(0xff6c479f)
                            : const Color(0xffa292ba),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (height >= 42)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 5),
            child: Text(
              p.shortLabel,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

/// Only maps already prepared bins, observations and reference fractions into
/// pixels. No monthly aggregation or statistical calculation happens in paint.
final class BalanceSumFocusedChartPainter extends CustomPainter {
  const BalanceSumFocusedChartPainter({
    required this.chart,
    required this.histogram,
    required this.band,
    required this.perspective,
    this.fontFamily,
  });
  final BalanceSumFocusedChartPresentation chart;
  final DashboardBalanceMonthlyNetHistogramPresentation histogram;
  final DashboardBalanceCashflowStabilityBandPresentation band;
  final BalanceSumFocusedPresentation perspective;
  final String? fontFamily;
  static const _purple = Color(0xff9670d4);
  void _text(
    Canvas canvas,
    String text,
    Offset at, {
    Color color = FluviVisualTokens.textSecondary,
    bool centered = false,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: fontFamily, fontSize: 9, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, Offset(centered ? at.dx - p.width / 2 : at.dx, at.dy));
  }

  void _rightText(Canvas canvas, String text, Offset right) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 9,
          color: FluviVisualTokens.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, Offset(right.dx - p.width, right.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final plot = Rect.fromLTRB(
      12,
      20,
      size.width - 12,
      math.max(21, size.height - 23),
    );
    if (perspective == BalanceSumFocusedPresentation.distribution) {
      final bins = histogram.bins;
      if (bins.isEmpty) return;
      final maxCount = chart.histogramMaximumCount;
      final width = plot.width / bins.length;
      final low = histogram.typicalLowerMinor,
          high = histogram.typicalUpperMinor;
      if (low != null && high != null) {
        canvas.drawRect(
          Rect.fromLTRB(
            plot.left + histogram.xFractionForValue(low) * plot.width,
            plot.top,
            plot.left + histogram.xFractionForValue(high) * plot.width,
            plot.bottom,
          ),
          Paint()..color = _purple.withValues(alpha: .07),
        );
      }
      for (var i = 0; i < bins.length; i++) {
        final b = bins[i];
        if (b.count == 0) continue;
        final rect = Rect.fromLTRB(
          plot.left + i * width + width * .12,
          plot.bottom - b.count / maxCount * plot.height,
          plot.left + (i + 1) * width - width * .12,
          plot.bottom,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: b.representativeMinor < 0
                  ? const [Color(0xffe7b0bc), Color(0xffc97c99)]
                  : const [Color(0xffc4b0e8), Color(0xff9571cc)],
            ).createShader(rect),
        );
      }
      final zero = plot.left + histogram.zeroReferenceFraction * plot.width;
      canvas.drawLine(
        Offset(zero, plot.top),
        Offset(zero, plot.bottom),
        Paint()
          ..color = const Color(0xffaab0bc)
          ..strokeWidth = 1,
      );
      _text(
        canvas,
        chart.histogramMinimumLabel,
        Offset(plot.left, plot.bottom + 6),
      );
      _rightText(
        canvas,
        chart.histogramMaximumLabel,
        Offset(plot.right, plot.bottom + 6),
      );
      if (zero > plot.left + 65 && zero < plot.right - 65) {
        _text(canvas, '0 Ft', Offset(zero, plot.bottom + 6), centered: true);
      }
      final median =
          plot.left +
          histogram.xFractionForValue(histogram.medianMinor) * plot.width;
      canvas.drawLine(
        Offset(median, plot.top),
        Offset(median, plot.bottom),
        Paint()
          ..color = _purple
          ..strokeWidth = 1.5,
      );
      _text(
        canvas,
        'Medián ${chart.medianLabel}',
        Offset(median.clamp(65.0, size.width - 65), 2),
        color: _purple,
        centered: true,
      );
    } else {
      _text(
        canvas,
        chart.stabilityMinimumLabel,
        Offset(plot.left, plot.bottom + 6),
      );
      _rightText(
        canvas,
        chart.stabilityMaximumLabel,
        Offset(plot.right, plot.bottom + 6),
      );
      final center = plot.center.dy;
      final spread = math.max(10.0, plot.height * .2);
      final markerHalfHeight = math.max(15.0, plot.height * .3);
      double x(int v) => plot.left + band.xFractionForTimesTwo(v) * plot.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(plot.left, center - 3, plot.right, center + 3),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xffede8f5),
      );
      final lower = band.typicalLowerTimesTwo,
          upper = band.typicalUpperTimesTwo;
      if (lower != null && upper != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x(lower), center - spread, x(upper), center + spread),
            const Radius.circular(8),
          ),
          Paint()..color = _purple.withValues(alpha: .17),
        );
      }
      for (var i = 0; i < band.observationNetTimesTwo.length; i++) {
        final value = band.observationNetTimesTwo[i];
        canvas.drawCircle(
          Offset(x(value), center + ((i % 5) - 2) * spread * .55),
          3,
          Paint()..color = _purple.withValues(alpha: .65),
        );
      }
      final median = band.medianNetTimesTwo;
      if (median != null) {
        canvas.drawLine(
          Offset(x(median), center - markerHalfHeight),
          Offset(x(median), center + markerHalfHeight),
          Paint()
            ..color = _purple
            ..strokeWidth = 2,
        );
        _text(
          canvas,
          'Medián ${chart.medianLabel}',
          Offset(
            x(median).clamp(65.0, size.width - 65),
            math.max(0, center - markerHalfHeight - 17),
          ),
          centered: true,
          color: _purple,
        );
      }
      final zero = x(0);
      canvas.drawLine(
        Offset(zero, center + 28),
        Offset(zero, center + 34),
        Paint()..color = const Color(0xffaab0bc),
      );
      _text(
        canvas,
        '0 Ft',
        Offset(zero.clamp(14.0, size.width - 16), center + 36),
        centered: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BalanceSumFocusedChartPainter oldDelegate) =>
      oldDelegate.histogram != histogram ||
      oldDelegate.band != band ||
      oldDelegate.perspective != perspective ||
      oldDelegate.fontFamily != fontFamily;
}
