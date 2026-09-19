import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../domain/mind_temporal_heatmap_projection.dart';

/// Shared, presentation-local aggregate chart. Its points are immutable
/// aggregates supplied by Mind frames; it has no Query or repository path.
final class MindAggregateLineChart extends StatefulWidget {
  const MindAggregateLineChart({
    super.key,
    required this.points,
    required this.title,
    required this.subtitle,
    required this.lineColor,
    this.monthDomain = false,
  });

  final List<MindAggregateLinePoint> points;
  final String title;
  final String subtitle;
  final Color lineColor;
  final bool monthDomain;

  @override
  State<MindAggregateLineChart> createState() => _MindAggregateLineChartState();
}

final class _MindAggregateLineChartState extends State<MindAggregateLineChart> {
  static const _yearSlotWidth = 64.0;
  static const _monthSlotWidth = 48.0;
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant MindAggregateLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points)) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final slotWidth = widget.monthDomain ? _monthSlotWidth : _yearSlotWidth;
      final plotWidth = math.max(
        constraints.maxWidth - 34,
        widget.points.length * slotWidth,
      );
      final chartHeight = constraints.maxHeight.isFinite
          ? (constraints.maxHeight - 38).clamp(92.0, 156.0).toDouble()
          : 156.0;
      final selected = _selectedIndex == null
          ? null
          : widget.points[_selectedIndex!];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.title,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            widget.subtitle,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: chartHeight,
            child: SingleChildScrollView(
              key: const ValueKey('mind-aggregate-line-scroll'),
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: plotWidth + 34,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      width: 30,
                      top: 22,
                      bottom: 24,
                      child: _MindAggregateYAxis(points: widget.points),
                    ),
                    Positioned(
                      left: 34,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) {
                          if (widget.points.isEmpty) {
                            return;
                          }
                          final fraction =
                              (details.localPosition.dx / plotWidth).clamp(
                                0.0,
                                1.0,
                              );
                          final index =
                              (fraction * math.max(0, widget.points.length - 1))
                                  .round();
                          setState(
                            () => _selectedIndex = _selectedIndex == index
                                ? null
                                : index,
                          );
                        },
                        child: CustomPaint(
                          key: const ValueKey('mind-aggregate-line-plot'),
                          painter: _MindAggregateLinePainter(
                            points: widget.points,
                            lineColor: widget.lineColor,
                            selectedIndex: _selectedIndex,
                          ),
                        ),
                      ),
                    ),
                    if (selected != null)
                      Positioned(
                        top: 2,
                        left: math.min(
                          plotWidth - 112,
                          math.max(
                            34,
                            34 +
                                plotWidth *
                                    (_selectedIndex! /
                                        math.max(1, widget.points.length - 1)) -
                                56,
                          ),
                        ),
                        child: _MindAggregateInfoCard(
                          point: selected,
                          previous: _selectedIndex! == 0
                              ? null
                              : widget.points[_selectedIndex! - 1],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

final class _MindAggregateYAxis extends StatelessWidget {
  const _MindAggregateYAxis({required this.points});

  final List<MindAggregateLinePoint> points;

  @override
  Widget build(BuildContext context) {
    final maximum = points.fold<int>(
      0,
      (value, point) => math.max(value, point.total),
    );
    String label(double factor) {
      final forints = maximum * factor / 100;
      if (forints >= 1000000) {
        return '${(forints / 1000000).toStringAsFixed(0)} M';
      }
      if (forints >= 1000) {
        return '${(forints / 1000).toStringAsFixed(0)} k';
      }
      return forints.toStringAsFixed(0);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (final factor in <double>[1, 2 / 3, 1 / 3, 0])
          Text(
            label(factor),
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 7,
            ),
          ),
      ],
    );
  }
}

final class _MindAggregateInfoCard extends StatelessWidget {
  const _MindAggregateInfoCard({required this.point, required this.previous});
  final MindAggregateLinePoint point;
  final MindAggregateLinePoint? previous;
  @override
  Widget build(BuildContext context) {
    final delta = previous == null ? null : point.total - previous!.total;
    final percent = previous == null || previous!.total == 0
        ? null
        : delta! / previous!.total * 100;
    return DecoratedBox(
      key: const ValueKey('mind-aggregate-line-infocard'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 12),
        ],
      ),
      child: SizedBox(
        width: 112,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                point.label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${(point.total / 100).toStringAsFixed(0)} Ft',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (delta != null)
                Text(
                  '${delta >= 0 ? '+' : ''}${(delta / 100).toStringAsFixed(0)} Ft${percent == null ? '' : ' · ${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(0)}%'}',
                  style: TextStyle(
                    fontSize: 8,
                    color: delta >= 0 ? const Color(0xff00a84f) : Colors.red,
                  ),
                ),
              if (delta != null)
                const Text(
                  'az előzőhöz képest',
                  style: TextStyle(
                    fontSize: 7,
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MindAggregateLinePainter extends CustomPainter {
  _MindAggregateLinePainter({
    required this.points,
    required this.lineColor,
    required this.selectedIndex,
  });
  final List<MindAggregateLinePoint> points;
  final Color lineColor;
  final int? selectedIndex;
  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(0, 22, size.width, size.height - 46);
    final guide = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .16)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(0, plot.top + plot.height * i / 3),
        Offset(plot.right, plot.top + plot.height * i / 3),
        guide,
      );
    }
    if (points.isEmpty) {
      return;
    }
    final maximum = math.max(
      1,
      points.fold<int>(0, (v, p) => math.max(v, p.total)),
    );
    Offset at(int i) => Offset(
      size.width * (points.length == 1 ? .5 : i / (points.length - 1)),
      plot.bottom - plot.height * (points[i].total / maximum),
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(path)
      ..lineTo(at(points.length - 1).dx, plot.bottom)
      ..lineTo(at(0).dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            lineColor.withValues(alpha: .32),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < points.length; i++) {
      final guidePaint = Paint()
        ..color = FluviVisualTokens.textSecondary.withValues(alpha: .10)
        ..strokeWidth = .75;
      canvas.drawLine(
        Offset(at(i).dx, plot.top),
        Offset(at(i).dx, plot.bottom),
        guidePaint,
      );
      canvas.drawCircle(
        at(i),
        i == selectedIndex ? 6 : 4,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill,
      );
      if (i == selectedIndex) {
        canvas.drawCircle(at(i), 3, Paint()..color = Colors.white);
      }
      final label = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: const TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      label.paint(
        canvas,
        Offset(
          (at(i).dx - label.width / 2).clamp(0.0, size.width - label.width),
          plot.bottom + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MindAggregateLinePainter old) =>
      old.points != points ||
      old.lineColor != lineColor ||
      old.selectedIndex != selectedIndex;
}
