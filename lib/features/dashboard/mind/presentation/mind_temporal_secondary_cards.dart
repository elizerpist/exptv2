import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_year_heatmap_palette_resolver.dart';

/// Presentation-only Month secondary card. It renders the immutable daily
/// range-preview points carried by [MindMonthHeatmapFrame]; neither a widget
/// build nor a slider preview reaches Query, a repository, or ledger rows.
final class MindMonthDailyRhythmCard extends StatelessWidget {
  const MindMonthDailyRhythmCard({
    super.key,
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final MindMonthHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  Widget build(BuildContext context) {
    final points = frame.dailyRhythmPoints;
    final fullPoints = frame.fullDailyRhythmPoints;
    final strongest = points.fold<MindAggregateLinePoint>(
      points.first,
      (current, point) => point.total > current.total ? point : current,
    );
    final average = points.isEmpty ? 0.0 : frame.total / points.length;
    final barColor = MindYearHeatmapPaletteResolver.resolveTile(
      style: paletteStyle,
      isEmpty: false,
      intensity: 1,
      paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
      scaleResolution: scaleResolution,
    ).background;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Napi költési ritmus',
            style: TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${frame.year}. ${DashboardTimeLabelFormatter.monthName(frame.month)} · ${frame.activeDayCount} aktív nap',
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = math.max(62.0, constraints.maxHeight - 48);
                return Column(
                  children: <Widget>[
                    SizedBox(
                      height: chartHeight,
                      child: _MindMonthRhythmPlot(
                        points: points,
                        fullPoints: fullPoints,
                        average: average,
                        barColor: barColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _MindTemporalStats(
                      values: <_MindTemporalStatValue>[
                        _MindTemporalStatValue(
                          keyName: 'mind-month-rhythm-stat-total',
                          label: 'Teljes hónap',
                          value: QueryMenuFormatters.money(
                            fullPoints.fold<int>(
                              0,
                              (total, point) => total + point.total,
                            ),
                          ),
                        ),
                        _MindTemporalStatValue(
                          keyName: 'mind-month-rhythm-stat-active',
                          label: 'Aktív nap',
                          value: '${frame.activeDayCount} nap',
                        ),
                        _MindTemporalStatValue(
                          keyName: 'mind-month-rhythm-stat-average',
                          label: 'Napi átlag',
                          value: QueryMenuFormatters.money(average.round()),
                        ),
                        _MindTemporalStatValue(
                          keyName: 'mind-month-rhythm-stat-strongest',
                          label: 'Legerősebb nap',
                          value: strongest.total == 0
                              ? '—'
                              : '${strongest.ordinal}. · ${QueryMenuFormatters.money(strongest.total)}',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _MindMonthRhythmPlot extends StatelessWidget {
  const _MindMonthRhythmPlot({
    required this.points,
    required this.fullPoints,
    required this.average,
    required this.barColor,
  });

  final List<MindAggregateLinePoint> points;
  final List<MindAggregateLinePoint> fullPoints;
  final double average;
  final Color barColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const left = 25.0;
      const right = 3.0;
      const top = 5.0;
      const bottom = 15.0;
      final plotWidth = math.max(0.0, constraints.maxWidth - left - right);
      final plotHeight = math.max(0.0, constraints.maxHeight - top - bottom);
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            key: const ValueKey<String>('mind-month-rhythm-chart'),
            painter: _MindMonthRhythmPainter(
              points: points,
              fullPoints: fullPoints,
              average: average,
              barColor: barColor,
            ),
          ),
          Positioned(
            key: const ValueKey<String>('mind-month-rhythm-average'),
            left: left + 2,
            top: math.max(0, top + plotHeight * .12 - 8),
            child: const Text(
              'napi átlag',
              style: TextStyle(
                color: Color(0xff4f86c6),
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (var index = 0; index < points.length; index += 1)
            Positioned(
              key: ValueKey<String>(
                'mind-month-rhythm-bar-${points[index].ordinal.toString().padLeft(2, '0')}',
              ),
              left: left + plotWidth * index / math.max(1, points.length),
              top: top,
              width: math.max(1, plotWidth / math.max(1, points.length)),
              height: plotHeight,
              child: const IgnorePointer(),
            ),
        ],
      );
    },
  );
}

final class _MindMonthRhythmPainter extends CustomPainter {
  _MindMonthRhythmPainter({
    required this.points,
    required this.fullPoints,
    required this.average,
    required this.barColor,
  });

  final List<MindAggregateLinePoint> points;
  final List<MindAggregateLinePoint> fullPoints;
  final double average;
  final Color barColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 25.0;
    const right = 3.0;
    const top = 5.0;
    const bottom = 15.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    final maximum = math.max(
      1,
      fullPoints.fold<int>(
        0,
        (current, point) => math.max(current, point.total),
      ),
    );
    final grid = Paint()
      ..color = FluviVisualTokens.surfaceMuted
      ..strokeWidth = .75;
    for (var level = 0; level < 4; level += 1) {
      final y = plot.top + plot.height * level / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    if (points.isEmpty || plot.width <= 0 || plot.height <= 0) return;
    final unit = plot.width / points.length;
    final barWidth = math.max(1.0, unit * .58);
    final fullBar = Paint()..color = FluviVisualTokens.surfaceMuted;
    final bar = Paint()..color = barColor;
    for (var index = 0; index < points.length; index += 1) {
      final point = points[index];
      final fullPoint = fullPoints[index];
      final fullHeight = plot.height * fullPoint.total / maximum;
      final fullRect = Rect.fromLTWH(
        plot.left + index * unit + (unit - barWidth) / 2,
        plot.bottom - fullHeight,
        barWidth,
        fullHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fullRect, const Radius.circular(2)),
        fullBar,
      );
      final height = plot.height * point.total / maximum;
      final rect = Rect.fromLTWH(
        plot.left + index * unit + (unit - barWidth) / 2,
        plot.bottom - height,
        barWidth,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        bar,
      );
    }
    final averageY = plot.bottom - plot.height * average / maximum;
    final averagePaint = Paint()
      ..color = const Color(0xff4f86c6)
      ..strokeWidth = 1;
    for (var x = plot.left; x < plot.right; x += 4) {
      canvas.drawLine(
        Offset(x, averageY),
        Offset(math.min(x + 2, plot.right), averageY),
        averagePaint,
      );
    }
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final day in <int>[1, 8, 15, 22, points.length]) {
      if (day <= 0 || day > points.length) continue;
      labelPainter.text = TextSpan(
        text: '$day',
        style: const TextStyle(
          color: FluviVisualTokens.textSecondary,
          fontSize: 7,
        ),
      );
      labelPainter.layout();
      final x = plot.left + (day - .5) * unit - labelPainter.width / 2;
      labelPainter.paint(
        canvas,
        Offset(x.clamp(plot.left, plot.right), plot.bottom + 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MindMonthRhythmPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.fullPoints != fullPoints ||
      oldDelegate.average != average ||
      oldDelegate.barColor != barColor;
}

/// Presentation-only Day secondary card. It plots the exact local time and
/// amount of current resident prepared events, not synthetic hourly values.
final class MindDayTransactionTimelineCard extends StatelessWidget {
  const MindDayTransactionTimelineCard({
    super.key,
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final MindDayHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  Widget build(BuildContext context) {
    final markerColor = MindYearHeatmapPaletteResolver.resolveTile(
      style: paletteStyle,
      isEmpty: false,
      intensity: 1,
      paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
      scaleResolution: scaleResolution,
    ).background;
    final strongest = frame.timelineEvents.fold<MindDayTimelineEvent?>(
      null,
      (current, event) =>
          current == null || event.total > current.total ? event : current,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Napi tranzakciók idővonala',
            style: TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${frame.date.year}. ${DashboardTimeLabelFormatter.monthName(frame.date.month)} ${frame.date.day}.',
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = math.max(62.0, constraints.maxHeight - 52);
                return Column(
                  children: <Widget>[
                    SizedBox(
                      height: chartHeight,
                      child: _MindDayTimelinePlot(
                        events: frame.timelineEvents,
                        fullEvents: frame.fullTimelineEvents,
                        markerColor: markerColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _MindTimelineLegendDot(color: Color(0xffc9ccd2)),
                        Text(
                          ' Összes tranzakció (nap)',
                          style: TextStyle(fontSize: 7),
                        ),
                        SizedBox(width: 7),
                        _MindTimelineLegendDot(color: Color(0xff7657c5)),
                        Text(
                          ' Aktuális szűrőben',
                          style: TextStyle(fontSize: 7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _MindTemporalStats(
                      values: <_MindTemporalStatValue>[
                        _MindTemporalStatValue(
                          keyName: 'mind-day-timeline-stat-total',
                          label: 'Teljes nap',
                          value:
                              '${QueryMenuFormatters.money(frame.fullTimelineTotal)} · ${frame.fullTimelineEvents.length} db',
                        ),
                        _MindTemporalStatValue(
                          keyName: 'mind-day-timeline-stat-range',
                          label: 'Aktuális sáv',
                          value: QueryMenuFormatters.money(frame.total),
                        ),
                        _MindTemporalStatValue(
                          keyName: 'mind-day-timeline-stat-hours',
                          label: 'Aktív idősáv',
                          value: '${frame.activeHourCount} óra',
                        ),
                        _MindTemporalStatValue(
                          keyName: 'mind-day-timeline-stat-strongest',
                          label: 'Legnagyobb tétel',
                          value: strongest == null
                              ? '—'
                              : '${_timeLabel(strongest.timeMinutes)} · ${QueryMenuFormatters.money(strongest.total)}',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _timeLabel(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

final class _MindDayTimelinePlot extends StatelessWidget {
  const _MindDayTimelinePlot({
    required this.events,
    required this.fullEvents,
    required this.markerColor,
  });

  final List<MindDayTimelineEvent> events;
  final List<MindDayTimelineEvent> fullEvents;
  final Color markerColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const left = 8.0;
      const right = 8.0;
      const top = 8.0;
      const bottom = 16.0;
      final plotWidth = math.max(0.0, constraints.maxWidth - left - right);
      final plotHeight = math.max(0.0, constraints.maxHeight - top - bottom);
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            key: const ValueKey<String>('mind-day-timeline-chart'),
            painter: _MindDayTimelinePainter(
              events: events,
              fullEvents: fullEvents,
              markerColor: markerColor,
            ),
          ),
          for (final event in events)
            Positioned(
              key: ValueKey<String>(
                'mind-day-timeline-marker-${event.ordinal}',
              ),
              left: left + plotWidth * event.timeMinutes / (24 * 60) - 5,
              top: top,
              width: 10,
              height: plotHeight,
              child: const IgnorePointer(),
            ),
        ],
      );
    },
  );
}

final class _MindDayTimelinePainter extends CustomPainter {
  _MindDayTimelinePainter({
    required this.events,
    required this.fullEvents,
    required this.markerColor,
  });

  final List<MindDayTimelineEvent> events;
  final List<MindDayTimelineEvent> fullEvents;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 16.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    final axisY = plot.top + plot.height * .64;
    final axis = Paint()
      ..color = FluviVisualTokens.surfaceMuted
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(plot.left, axisY), Offset(plot.right, axisY), axis);
    final label = TextPainter(textDirection: TextDirection.ltr);
    for (final hour in <int>[0, 6, 12, 18, 24]) {
      final x = plot.left + plot.width * hour / 24;
      canvas.drawLine(Offset(x, axisY - 3), Offset(x, axisY + 3), axis);
      label.text = TextSpan(
        text: hour == 24 ? '24' : hour.toString().padLeft(2, '0'),
        style: const TextStyle(
          color: FluviVisualTokens.textSecondary,
          fontSize: 7,
        ),
      );
      label.layout();
      label.paint(canvas, Offset(x - label.width / 2, axisY + 5));
    }
    final maximum = math.max(
      1,
      fullEvents.fold<int>(
        0,
        (current, event) => math.max(current, event.total),
      ),
    );
    final fullMarker = Paint()
      ..color = FluviVisualTokens.surfaceMuted
      ..strokeWidth = 1.2;
    final marker = Paint()
      ..color = markerColor
      ..strokeWidth = 1.5;
    void drawMarker(
      MindDayTimelineEvent event,
      Paint paint, {
      required bool selected,
    }) {
      final x = plot.left + plot.width * event.timeMinutes / (24 * 60);
      final stem = plot.height * (.16 + .44 * event.total / maximum);
      final y = axisY - stem;
      canvas.drawLine(Offset(x, axisY), Offset(x, y), paint);
      canvas.drawCircle(Offset(x, y), selected ? 3.5 : 2.6, paint);
      if (!selected) return;
      label.text = TextSpan(
        text: _timeLabel(event.timeMinutes),
        style: TextStyle(
          color: markerColor,
          fontSize: 7,
          fontWeight: FontWeight.w800,
        ),
      );
      label.layout(maxWidth: 45);
      label.paint(
        canvas,
        Offset(
          (x - label.width / 2).clamp(plot.left, plot.right - label.width),
          math.max(plot.top, y - 18),
        ),
      );
    }

    for (final event in fullEvents) {
      drawMarker(event, fullMarker, selected: false);
    }
    for (final event in events) {
      drawMarker(event, marker, selected: true);
    }
  }

  @override
  bool shouldRepaint(covariant _MindDayTimelinePainter oldDelegate) =>
      oldDelegate.events != events ||
      oldDelegate.fullEvents != fullEvents ||
      oldDelegate.markerColor != markerColor;
}

final class _MindTimelineLegendDot extends StatelessWidget {
  const _MindTimelineLegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const SizedBox(width: 5, height: 5),
  );
}

final class _MindTemporalStatValue {
  const _MindTemporalStatValue({
    required this.keyName,
    required this.label,
    required this.value,
  });
  final String keyName;
  final String label;
  final String value;
}

final class _MindTemporalStats extends StatelessWidget {
  const _MindTemporalStats({required this.values});
  final List<_MindTemporalStatValue> values;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: values
        .map(
          (item) => DecoratedBox(
            key: ValueKey<String>(item.keyName),
            decoration: BoxDecoration(
              color: FluviVisualTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(7),
            ),
            child: SizedBox(
              width: 78,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}
