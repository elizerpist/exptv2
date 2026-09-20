import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import '../../presentation/dashboard_vertical_scroll_boundary_handoff.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../domain/mind_detailed_sum_chart_model.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import 'mind_anchored_info_card.dart';

const _detailMinutesPerDay = 24 * 60;

/// The preserved third Sum card. It owns only its local time-window gesture
/// state and renders the immutable range-preview day series supplied by the
/// admitted Sum frame. It has no Core, Query or repository write path.
final class MindDetailedSumChart extends StatefulWidget {
  const MindDetailedSumChart({
    super.key,
    required this.frame,
    required this.lineColor,
    required this.scrollController,
    this.upperVerticalGestures,
  });

  static const _minimumTwoYearBandHeight = 118.0;

  final MindSumHeatmapFrame frame;
  final Color lineColor;
  final ScrollController scrollController;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<MindDetailedSumChart> createState() => _MindDetailedSumChartState();
}

final class _MindDetailedSumChartState extends State<MindDetailedSumChart> {
  final _activePointers = <int>{};
  late final ValueNotifier<bool> _pinchActive;

  @override
  void initState() {
    super.initState();
    _pinchActive = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _pinchActive.dispose();
    super.dispose();
  }

  void _trackPointerDown(PointerDownEvent event) {
    if (!_activePointers.add(event.pointer)) return;
    _syncPointerMode();
  }

  void _trackPointerEnd(PointerEvent event) {
    if (!_activePointers.remove(event.pointer)) return;
    _syncPointerMode();
  }

  void _syncPointerMode() {
    final next = _activePointers.length >= 2;
    if (_pinchActive.value == next) return;
    _pinchActive.value = next;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final years = widget.frame.years;
      final availableHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : MindDetailedSumChart._minimumTwoYearBandHeight * 2;
      final bandHeight = switch (years.length) {
        0 => MindDetailedSumChart._minimumTwoYearBandHeight,
        1 => math.max(
          MindDetailedSumChart._minimumTwoYearBandHeight,
          availableHeight,
        ),
        2 =>
          availableHeight >=
                  MindDetailedSumChart._minimumTwoYearBandHeight * 2 + 8
              ? math.max(
                  MindDetailedSumChart._minimumTwoYearBandHeight,
                  (availableHeight - 8) / 2,
                )
              : math.max(1.0, (availableHeight - 8) / 2),
        _ => MindDetailedSumChart._minimumTwoYearBandHeight,
      };
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _trackPointerDown,
        onPointerUp: _trackPointerEnd,
        onPointerCancel: _trackPointerEnd,
        child: Semantics(
          key: const ValueKey<String>('mind-sum-detailed-pinch-state'),
          label: _pinchActive.value ? 'active' : 'idle',
          child: DashboardVerticalScrollBoundaryHandoff(
            upperVerticalGestures: widget.upperVerticalGestures,
            suppressHandoff: _pinchActive,
            child: ListView.separated(
              key: const ValueKey<String>('mind-sum-detailed-scroll'),
              controller: widget.scrollController,
              physics: _pinchActive.value
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: years.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final year = years[index];
                return SizedBox(
                  height: bandHeight,
                  child: _MindDetailedSumYearBand(
                    key: ValueKey<String>('mind-sum-detailed-band-$year'),
                    year: year,
                    frame: widget.frame,
                    lineColor: widget.lineColor,
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

final class _MindDetailedSumYearBand extends StatefulWidget {
  const _MindDetailedSumYearBand({
    super.key,
    required this.year,
    required this.frame,
    required this.lineColor,
  });

  final int year;
  final MindSumHeatmapFrame frame;
  final Color lineColor;

  @override
  State<_MindDetailedSumYearBand> createState() =>
      _MindDetailedSumYearBandState();
}

final class _MindDetailedSumYearBandState
    extends State<_MindDetailedSumYearBand> {
  final _cardKey = GlobalKey();
  late MindDetailedSumTimeWindow _window;
  MindDetailedSumTimeWindow? _scaleStartWindow;
  MindSumHeatmapDetailPoint? _selectedPoint;
  Offset? _selectionAnchor;

  @override
  void initState() {
    super.initState();
    _window = MindDetailedSumTimeWindow.fullYear(widget.year);
  }

  @override
  void didUpdateWidget(covariant _MindDetailedSumYearBand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year ||
        oldWidget.frame.identity != widget.frame.identity) {
      _window = MindDetailedSumTimeWindow.fullYear(widget.year);
      _scaleStartWindow = null;
      _selectedPoint = null;
      _selectionAnchor = null;
    }
  }

  bool get _isZoomed => _window.visibleMinuteCount < _window.homeMinuteCount;

  void _onScaleStart(ScaleStartDetails _) => _scaleStartWindow = _window;

  void _onScaleUpdate(
    ScaleUpdateDetails details,
    double plotLeft,
    double plotWidth,
  ) {
    final start = _scaleStartWindow;
    if (details.pointerCount < 2 || start == null || plotWidth <= 0) return;
    final fraction = ((details.localFocalPoint.dx - plotLeft) / plotWidth)
        .clamp(0.0, 1.0)
        .toDouble();
    final focalEpochMinute =
        start.startEpochMinute + (start.visibleMinuteCount - 1) * fraction;
    final next = start.zoomForGesture(
      scaleDelta: details.scale,
      focalEpochMinute: focalEpochMinute.round(),
    );
    if (next == _window) return;
    setState(() => _window = next);
  }

  void _onScaleEnd(ScaleEndDetails _) => _scaleStartWindow = null;

  void _panBy(DragUpdateDetails details, double plotWidth) {
    if (plotWidth <= 0 || !_isZoomed) return;
    final minutes = (-details.delta.dx / plotWidth * _window.visibleMinuteCount)
        .round();
    if (minutes == 0) return;
    setState(() => _window = _window.panByMinutes(minutes));
  }

  void _selectNearestPoint({
    required TapUpDetails details,
    required List<MindSumHeatmapDetailPoint> points,
    required double plotLeft,
    required double plotWidth,
  }) {
    if (points.isEmpty || plotWidth <= 0) return;
    final fraction = ((details.localPosition.dx - plotLeft) / plotWidth)
        .clamp(0.0, 1.0)
        .toDouble();
    MindSumHeatmapDetailPoint? nearest;
    var nearestDistance = double.infinity;
    for (final point in points) {
      final distance =
          (_window.normalizedPositionOfEpochMinute(point.epochMinute) -
                  fraction)
              .abs();
      if (distance < nearestDistance) {
        nearest = point;
        nearestDistance = distance;
      }
    }
    if (nearest == null) return;
    final samePoint =
        _selectedPoint?.epochMinute == nearest.epochMinute &&
        _selectedPoint?.ordinal == nearest.ordinal &&
        _selectedPoint?.total == nearest.total;
    setState(() {
      _selectedPoint = samePoint ? null : nearest;
      _selectionAnchor = samePoint ? null : details.globalPosition;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const headerHeight = 16.0;
      const axisLeft = 34.0;
      const axisBottom = 18.0;
      final plotWidth = math.max(1.0, constraints.maxWidth - axisLeft - 3);
      final source = widget.frame.detailPointsForYear(
        year: widget.year,
        startEpochMinute: _window.startEpochMinute,
        endEpochMinute: _window.endEpochMinute,
      );
      final lod = MindDetailedSumLod.sample(
        points: source,
        window: _window,
        pixelWidth: plotWidth,
      );
      final maximum = math.max(
        1,
        lod.fold<int>(0, (value, point) => math.max(value, point.total)),
      );
      final chart = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _onScaleStart,
        onScaleUpdate: (details) =>
            _onScaleUpdate(details, axisLeft, plotWidth),
        onScaleEnd: _onScaleEnd,
        onTapUp: (details) => _selectNearestPoint(
          details: details,
          points: lod,
          plotLeft: axisLeft,
          plotWidth: plotWidth,
        ),
        child: CustomPaint(
          key: ValueKey<String>('mind-sum-detailed-plot-${widget.year}'),
          painter: _MindDetailedSumPainter(
            points: lod,
            window: _window,
            lineColor: widget.lineColor,
            axisLeft: axisLeft,
            axisBottom: axisBottom,
            maximum: maximum,
            year: widget.year,
          ),
          child: const SizedBox.expand(),
        ),
      );
      return Stack(
        key: _cardKey,
        fit: StackFit.expand,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: headerHeight,
                child: Row(
                  children: <Widget>[
                    Text(
                      '${widget.year}',
                      style: const TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Semantics(
                      key: ValueKey<String>(
                        'mind-sum-detailed-window-${widget.year}',
                      ),
                      label: '${_window.startEpochDay}:${_window.endEpochDay}',
                      child: const SizedBox(width: 0, height: 0),
                    ),
                    Semantics(
                      key: ValueKey<String>(
                        'mind-sum-detailed-anchor-count-${widget.year}',
                      ),
                      label: '${lod.length}',
                      child: const SizedBox(width: 0, height: 0),
                    ),
                    Semantics(
                      key: ValueKey<String>(
                        'mind-sum-detailed-month-separator-count-${widget.year}',
                      ),
                      label:
                          '${_visibleMonthSeparatorCount(widget.year, _window)}',
                      child: const SizedBox(width: 0, height: 0),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: _isZoomed
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (details) =>
                                  _panBy(details, plotWidth),
                              child: chart,
                            )
                          : chart,
                    ),
                    Positioned(
                      left: 0,
                      top: 2,
                      bottom: axisBottom,
                      width: axisLeft - 3,
                      child: _MindDetailedSumYAxis(
                        year: widget.year,
                        maximum: maximum,
                      ),
                    ),
                    Positioned(
                      left: axisLeft,
                      right: 0,
                      bottom: 0,
                      height: axisBottom,
                      child: _MindDetailedSumMonthAxis(
                        year: widget.year,
                        window: _window,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedPoint case final point?)
            MindAnchoredInfoCard(
              globalAnchor: _selectionAnchor ?? Offset.zero,
              cardKey: _cardKey,
              estimatedWidth: 124,
              estimatedHeight: 44,
              ignorePointer: true,
              child: _MindDetailedSumPointInfoCard(
                key: ValueKey<String>(
                  'mind-sum-detailed-infocard-${widget.year}',
                ),
                point: point,
              ),
            ),
        ],
      );
    },
  );
}

final class _MindDetailedSumYAxis extends StatelessWidget {
  const _MindDetailedSumYAxis({required this.year, required this.maximum});

  final int year;
  final int maximum;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      for (var index = 3; index >= 0; index -= 1)
        Text(
          _formatMinor(maximum * index ~/ 3),
          key: ValueKey<String>('mind-sum-detailed-axis-y-$year-$index'),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 7,
          ),
        ),
    ],
  );
}

final class _MindDetailedSumMonthAxis extends StatelessWidget {
  const _MindDetailedSumMonthAxis({required this.year, required this.window});

  final int year;
  final MindDetailedSumTimeWindow window;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final start = window.startEpochDay;
      final span = math.max(1, window.visibleDayCount - 1);
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (var month = 1; month <= 12; month += 1)
            if (_positionFor(month, start, span) case final fraction?)
              Positioned(
                left: (constraints.maxWidth * fraction - 3)
                    .clamp(0.0, math.max(0.0, constraints.maxWidth - 7))
                    .toDouble(),
                top: 2,
                child: Text(
                  _monthInitials[month - 1],
                  key: ValueKey<String>(
                    'mind-sum-detailed-axis-month-$year-$month',
                  ),
                  style: const TextStyle(
                    color: FluviVisualTokens.textSecondary,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        ],
      );
    },
  );

  double? _positionFor(int month, int start, int span) {
    final epoch = LocalDate(year: year, month: month, day: 1).epochDay;
    if (epoch < window.startEpochDay || epoch > window.endEpochDay) return null;
    return ((epoch - start) / span).clamp(0.0, 1.0).toDouble();
  }
}

final class _MindDetailedSumPainter extends CustomPainter {
  const _MindDetailedSumPainter({
    required this.points,
    required this.window,
    required this.lineColor,
    required this.axisLeft,
    required this.axisBottom,
    required this.maximum,
    required this.year,
  });

  final List<MindSumHeatmapDetailPoint> points;
  final MindDetailedSumTimeWindow window;
  final Color lineColor;
  final double axisLeft;
  final double axisBottom;
  final int maximum;
  final int year;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(
      axisLeft,
      3,
      math.max(0, size.width - axisLeft - 3),
      math.max(0, size.height - axisBottom - 4),
    );
    if (plot.width <= 0 || plot.height <= 0) return;
    final guide = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .15)
      ..strokeWidth = .75;
    for (var index = 0; index < 4; index += 1) {
      final y = plot.top + plot.height * index / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), guide);
    }
    final monthSeparator = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .12)
      ..strokeWidth = .65;
    for (var month = 2; month <= 12; month += 1) {
      final boundary =
          LocalDate(year: year, month: month, day: 1).epochDay *
          _detailMinutesPerDay;
      if (boundary < window.startEpochMinute ||
          boundary > window.endEpochMinute) {
        continue;
      }
      final x =
          plot.left +
          plot.width * window.normalizedPositionOfEpochMinute(boundary);
      for (var y = plot.top; y < plot.bottom; y += 5) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 2, plot.bottom)),
          monthSeparator,
        );
      }
    }
    if (points.isEmpty) return;
    Offset pointAt(MindSumHeatmapDetailPoint point) {
      final fraction = window.normalizedPositionOfEpochMinute(
        point.epochMinute,
      );
      final intensity = (point.total / maximum).clamp(0.0, 1.0).toDouble();
      return Offset(
        plot.left + plot.width * fraction,
        plot.bottom - plot.height * intensity,
      );
    }

    final offsets = points.map(pointAt).toList(growable: false);
    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      line.lineTo(offset.dx, offset.dy);
    }
    final fill = Path.from(line)
      ..lineTo(offsets.last.dx, plot.bottom)
      ..lineTo(offsets.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            lineColor.withValues(alpha: .28),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final marker = Paint()..color = lineColor;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 1.5, marker);
    }
  }

  @override
  bool shouldRepaint(covariant _MindDetailedSumPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.window != window ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.maximum != maximum ||
      oldDelegate.year != year;
}

int _visibleMonthSeparatorCount(int year, MindDetailedSumTimeWindow window) =>
    List<int>.generate(11, (index) => index + 2).where((month) {
      final minute =
          LocalDate(year: year, month: month, day: 1).epochDay *
          _detailMinutesPerDay;
      return minute >= window.startEpochMinute &&
          minute <= window.endEpochMinute;
    }).length;

final class _MindDetailedSumPointInfoCard extends StatelessWidget {
  const _MindDetailedSumPointInfoCard({super.key, required this.point});

  final MindSumHeatmapDetailPoint point;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.utc(
      1970,
    ).add(Duration(days: point.epochMinute ~/ _detailMinutesPerDay));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x25000000), blurRadius: 5),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          '${date.year}. ${DashboardTimeLabelFormatter.monthName(date.month)} ${date.day}.\n${QueryMenuFormatters.money(point.total)}',
          style: const TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _formatMinor(int minor) {
  final forints = minor ~/ 100;
  if (forints >= 1000000) return '${(forints / 1000000).toStringAsFixed(0)} M';
  if (forints >= 1000) return '${(forints / 1000).toStringAsFixed(0)} k';
  return QueryMenuFormatters.money(minor);
}

const _monthInitials = <String>[
  'J',
  'F',
  'M',
  'Á',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
  'N',
  'D',
];
