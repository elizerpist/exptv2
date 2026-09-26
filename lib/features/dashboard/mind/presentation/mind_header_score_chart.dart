import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../presentation/widgets/dashboard_header_trend_visual_kernel.dart';
import '../domain/mind_behavioral_score_projection.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';

/// Explicit visual context for a chart series. Day is a Month-plane child,
/// rather than another TimePlane, so it must be supplied by the existing
/// navigation/body presentation boundary instead of inferred from span length.
enum MindHeaderScoreChartTemporalContext { sum, year, month, day }

/// The one temporal X authority for the Mind Header. It is deliberately pure:
/// the immutable score series remains the source of both points and dates,
/// while the chart owns only their visual projection.
@immutable
final class MindHeaderScoreChartTemporalProjection {
  const MindHeaderScoreChartTemporalProjection({
    required this.startInclusiveEpochDay,
    required this.endInclusiveEpochDay,
  }) : assert(startInclusiveEpochDay <= endInclusiveEpochDay);

  final int startInclusiveEpochDay;
  final int endInclusiveEpochDay;

  double normalizedEpochDay(num epochDay) {
    final span = endInclusiveEpochDay - startInclusiveEpochDay;
    if (span == 0) return .5;
    return ((epochDay - startInclusiveEpochDay) / span)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double plotXForEpochDay(num epochDay, double plotWidth) =>
      normalizedEpochDay(epochDay) * plotWidth;

  double epochDayForPlotX(double plotX, double plotWidth) {
    if (plotWidth <= 0) return startInclusiveEpochDay.toDouble();
    final fraction = (plotX / plotWidth).clamp(0.0, 1.0).toDouble();
    return startInclusiveEpochDay +
        (endInclusiveEpochDay - startInclusiveEpochDay) * fraction;
  }

  MindBehavioralScorePoint nearestPointForPlotX(
    List<MindBehavioralScorePoint> points,
    double plotX,
    double plotWidth,
  ) {
    if (points.isEmpty) {
      throw StateError('Cannot inspect an empty Mind Header score series.');
    }
    final targetEpochDay = epochDayForPlotX(plotX, plotWidth);
    return points.reduce((closest, candidate) {
      final closestDistance = (closest.epochDay - targetEpochDay).abs();
      final candidateDistance = (candidate.epochDay - targetEpochDay).abs();
      if (candidateDistance < closestDistance ||
          (candidateDistance == closestDistance &&
              candidate.epochDay < closest.epochDay)) {
        return candidate;
      }
      return closest;
    });
  }
}

/// A one-chart passive pointer relay. The Header's existing pan recognizer is
/// physically above the chart in the real dashboard; this relay lets that
/// owner observe the same raw sequence without moving, replacing or competing
/// with its vertical gesture arena. It carries no selected state or data.
final class MindHeaderScoreChartPointerObserver {
  void Function(PointerDownEvent event)? _onPointerDown;
  void Function(PointerMoveEvent event)? _onPointerMove;
  void Function(PointerUpEvent event)? _onPointerUp;
  void Function(PointerCancelEvent event)? _onPointerCancel;

  void attach({
    required void Function(PointerDownEvent event) onPointerDown,
    required void Function(PointerMoveEvent event) onPointerMove,
    required void Function(PointerUpEvent event) onPointerUp,
    required void Function(PointerCancelEvent event) onPointerCancel,
  }) {
    _onPointerDown = onPointerDown;
    _onPointerMove = onPointerMove;
    _onPointerUp = onPointerUp;
    _onPointerCancel = onPointerCancel;
  }

  void detach() {
    _onPointerDown = null;
    _onPointerMove = null;
    _onPointerUp = null;
    _onPointerCancel = null;
  }

  void observePointerDown(PointerDownEvent event) =>
      _onPointerDown?.call(event);
  void observePointerMove(PointerMoveEvent event) =>
      _onPointerMove?.call(event);
  void observePointerUp(PointerUpEvent event) => _onPointerUp?.call(event);
  void observePointerCancel(PointerCancelEvent event) =>
      _onPointerCancel?.call(event);
}

/// The reference-derived composition for the expanded Mind Header chart.
/// These are Header-local layout measures, not an alternate dashboard layout
/// or a second physical card.
abstract final class MindHeaderScoreChartStyle {
  static const plotLeft = DashboardHeaderTrendChartStyle.plotLeft;
  static const plotTop = DashboardHeaderTrendChartStyle.plotTop;
  static const plotWidth = DashboardHeaderTrendChartStyle.plotWidth;
  static const plotHeight = DashboardHeaderTrendChartStyle.plotHeight;
  static const lineColor = DashboardHeaderTrendChartStyle.lineColor;
  static const lineWidth = DashboardHeaderTrendChartStyle.lineWidth;
  static const endpointRadius = DashboardHeaderTrendChartStyle.endpointRadius;
  static const endpointStrokeWidth =
      DashboardHeaderTrendChartStyle.endpointStrokeWidth;
  static const verticalPadding = DashboardHeaderTrendChartStyle.verticalPadding;
  static const guideRelativeY = DashboardHeaderTrendChartStyle.guideRelativeY;
  static const guideDash = DashboardHeaderTrendChartStyle.guideDash;
  static const guideGap = DashboardHeaderTrendChartStyle.guideGap;
  static const guideOpacity = DashboardHeaderTrendChartStyle.guideOpacity;
  static const areaFadeStartOpacity =
      DashboardHeaderTrendChartStyle.areaFadeStartOpacity;
  static const areaFadeEndOpacity =
      DashboardHeaderTrendChartStyle.areaFadeEndOpacity;
  static const timeLabelTop = DashboardHeaderTrendChartStyle.timeLabelTop;
  static const timeLabelHeight = DashboardHeaderTrendChartStyle.timeLabelHeight;
  static const timeLabelRevealExtent =
      DashboardHeaderTrendChartStyle.timeLabelRevealExtent;
  static const timeLabelTextStyle =
      DashboardHeaderTrendChartStyle.timeLabelTextStyle;
}

/// A paint-only chart reveal physically clipped by the dashboard-owned Header
/// expansion. It has no animation or financial state; callers provide one
/// immutable score series from the live Mind score publication.
final class MindHeaderScoreChart extends StatefulWidget {
  const MindHeaderScoreChart({
    super.key,
    required this.series,
    required this.expansionProgress,
    this.showTimeLabels = false,
    this.temporalContext = MindHeaderScoreChartTemporalContext.year,
    this.pointerObserver,
    this.lineColor = MindHeaderScoreChartStyle.lineColor,
    this.areaFadeColor,
    this.showsAreaFade = true,
    this.layout = const DashboardHeaderTrendChartLayout.normal(),
  });

  final MindBehavioralScoreChartSeries series;
  final double expansionProgress;
  final bool showTimeLabels;
  final MindHeaderScoreChartTemporalContext temporalContext;
  final MindHeaderScoreChartPointerObserver? pointerObserver;
  final Color lineColor;
  final Color? areaFadeColor;
  final bool showsAreaFade;
  final DashboardHeaderTrendChartLayout layout;

  /// Five semantic quarter positions over the immutable score-series time
  /// domain. These are dates first and pixels second, so scope/range/history
  /// changes cannot leave a stale artificial axis behind.
  @visibleForTesting
  static List<int> projectedTimeLabelEpochDays(
    MindBehavioralScoreChartSeries series,
  ) {
    final span = series.endInclusiveEpochDay - series.startInclusiveEpochDay;
    return List<int>.generate(
      5,
      (index) => series.startInclusiveEpochDay + (span * index / 4).round(),
      growable: false,
    );
  }

  @override
  State<MindHeaderScoreChart> createState() => _MindHeaderScoreChartState();

  /// Formats only an already-published point; this never asks the behavioral
  /// score projection to calculate a tap-specific value.
  @visibleForTesting
  static String selectedTemporalLabel(
    MindBehavioralScorePoint point,
    MindHeaderScoreChartTemporalContext temporalContext,
  ) {
    final date = DateTime.utc(1970).add(Duration(days: point.epochDay));
    final shortMonth = DashboardTimeLabelFormatter.shortMonthName(date.month);
    return switch (temporalContext) {
      MindHeaderScoreChartTemporalContext.sum => '${date.year}. $shortMonth',
      MindHeaderScoreChartTemporalContext.month => '${date.day}',
      MindHeaderScoreChartTemporalContext.year ||
      MindHeaderScoreChartTemporalContext.day => '$shortMonth ${date.day}',
    };
  }
}

final class _MindHeaderScoreChartState extends State<MindHeaderScoreChart> {
  final GlobalKey _plotKey = GlobalKey(debugLabel: 'mind-header-score-plot');
  Offset? _pointerDownPosition;
  var _pointerExceededTapSlop = false;
  int? _selectedEpochDay;

  @override
  void initState() {
    super.initState();
    _attachPointerObserver(widget.pointerObserver);
  }

  @override
  void didUpdateWidget(covariant MindHeaderScoreChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pointerObserver, widget.pointerObserver)) {
      oldWidget.pointerObserver?.detach();
      _attachPointerObserver(widget.pointerObserver);
    }
    // This is intentionally synchronous: a newly published immutable series
    // cannot expose a crosshair or date inherited from another scope/domain.
    if (oldWidget.series != widget.series) _selectedEpochDay = null;
  }

  @override
  void dispose() {
    widget.pointerObserver?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reveal = widget.expansionProgress.clamp(0.0, 1.0).toDouble();
    final series = widget.series;
    if (reveal <= 0 || series.points.isEmpty) return const SizedBox.shrink();
    final selected = _selectedPoint(series);
    final projection = MindHeaderScoreChartTemporalProjection(
      startInclusiveEpochDay: series.startInclusiveEpochDay,
      endInclusiveEpochDay: series.endInclusiveEpochDay,
    );
    return Positioned.fill(
      key: const ValueKey<String>('mind-header-score-chart'),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: <Widget>[
            Positioned(
              left: MindHeaderScoreChartStyle.plotLeft,
              top: widget.layout.plotTop,
              width: MindHeaderScoreChartStyle.plotWidth,
              height: widget.layout.plotHeight,
              child: Listener(
                key: _plotKey,
                behavior: HitTestBehavior.translucent,
                onPointerDown: _observePointerDown,
                onPointerMove: _observePointerMove,
                onPointerUp: (event) => _onPointerUp(event, projection),
                onPointerCancel: _observePointerCancel,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    key: const ValueKey<String>(
                      'mind-header-score-chart-reveal',
                    ),
                    width: MindHeaderScoreChartStyle.plotWidth,
                    height: widget.layout.plotHeight * reveal,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: MindHeaderScoreChartStyle.plotWidth,
                          height: widget.layout.plotHeight,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              key: const ValueKey<String>(
                                'mind-header-score-chart-paint',
                              ),
                              painter: MindHeaderScoreChartPainter(
                                series: series,
                                selectedEpochDay: selected?.epochDay,
                                lineColor: widget.lineColor,
                                areaFadeColor:
                                    widget.areaFadeColor ?? widget.lineColor,
                                showsAreaFade: widget.showsAreaFade,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showTimeLabels)
              _MindHeaderScoreChartTimeLabels(
                series: series,
                expansionProgress: reveal,
                layout: widget.layout,
              ),
            if (selected != null)
              _MindHeaderScoreChartSelectedLabels(
                point: selected,
                projection: projection,
                temporalContext: widget.temporalContext,
                availableWidth: constraints.maxWidth,
                layout: widget.layout,
              ),
          ],
        ),
      ),
    );
  }

  MindBehavioralScorePoint? _selectedPoint(
    MindBehavioralScoreChartSeries series,
  ) {
    final selectedEpochDay = _selectedEpochDay;
    if (selectedEpochDay == null) return null;
    for (final point in series.points) {
      if (point.epochDay == selectedEpochDay) return point;
    }
    return null;
  }

  void _attachPointerObserver(MindHeaderScoreChartPointerObserver? observer) {
    observer?.attach(
      onPointerDown: _observePointerDown,
      onPointerMove: _observePointerMove,
      onPointerUp: _observePointerUp,
      onPointerCancel: _observePointerCancel,
    );
  }

  void _observePointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _pointerExceededTapSlop = false;
  }

  void _observePointerMove(PointerMoveEvent event) {
    final origin = _pointerDownPosition;
    if (origin == null || _pointerExceededTapSlop) return;
    if ((event.position - origin).distance > kTouchSlop) {
      _pointerExceededTapSlop = true;
    }
  }

  void _observePointerUp(PointerUpEvent event) {
    final series = widget.series;
    _onPointerUp(
      event,
      MindHeaderScoreChartTemporalProjection(
        startInclusiveEpochDay: series.startInclusiveEpochDay,
        endInclusiveEpochDay: series.endInclusiveEpochDay,
      ),
    );
  }

  void _observePointerCancel(PointerCancelEvent _) => _resetPointer();

  void _onPointerUp(
    PointerUpEvent event,
    MindHeaderScoreChartTemporalProjection projection,
  ) {
    final origin = _pointerDownPosition;
    final shouldInspect =
        origin != null &&
        !_pointerExceededTapSlop &&
        (event.position - origin).distance <= kTouchSlop;
    _resetPointer();
    if (!shouldInspect) return;
    final box = _plotKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final localPosition = box.globalToLocal(event.position);
    if (!(Offset.zero & box.size).contains(localPosition)) return;
    final point = projection.nearestPointForPlotX(
      widget.series.points,
      localPosition.dx,
      box.size.width,
    );
    setState(() {
      _selectedEpochDay = _selectedEpochDay == point.epochDay
          ? null
          : point.epochDay;
    });
  }

  void _resetPointer() {
    _pointerDownPosition = null;
    _pointerExceededTapSlop = false;
  }
}

final class _MindHeaderScoreChartSelectedLabels extends StatelessWidget {
  const _MindHeaderScoreChartSelectedLabels({
    required this.point,
    required this.projection,
    required this.temporalContext,
    required this.availableWidth,
    required this.layout,
  });

  static const _scoreWidth = 46.0;
  static const _temporalWidth = 64.0;

  final MindBehavioralScorePoint point;
  final MindHeaderScoreChartTemporalProjection projection;
  final MindHeaderScoreChartTemporalContext temporalContext;
  final double availableWidth;
  final DashboardHeaderTrendChartLayout layout;

  @override
  Widget build(BuildContext context) {
    final x =
        MindHeaderScoreChartStyle.plotLeft +
        projection.plotXForEpochDay(
          point.epochDay,
          MindHeaderScoreChartStyle.plotWidth,
        );
    return Stack(
      children: <Widget>[
        _label(
          key: const ValueKey<String>('mind-header-score-chart-selected-score'),
          text: '${point.roundedScore}/100',
          left: _clampedLeft(x, _scoreWidth),
          top: layout.plotTop + 1,
          width: _scoreWidth,
        ),
        _label(
          key: const ValueKey<String>(
            'mind-header-score-chart-selected-temporal-label',
          ),
          text: MindHeaderScoreChart.selectedTemporalLabel(
            point,
            temporalContext,
          ),
          left: _clampedLeft(x, _temporalWidth),
          top:
              layout.plotTop +
              layout.plotHeight -
              MindHeaderScoreChartStyle.timeLabelHeight,
          width: _temporalWidth,
        ),
      ],
    );
  }

  double _clampedLeft(double centerX, double width) {
    final maximum = (availableWidth - width).clamp(0.0, double.infinity);
    return (centerX - width / 2).clamp(0.0, maximum).toDouble();
  }

  Widget _label({
    required Key key,
    required String text,
    required double left,
    required double top,
    required double width,
  }) => Positioned(
    key: key,
    left: left,
    top: top,
    width: width,
    height: MindHeaderScoreChartStyle.timeLabelHeight,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textAlign: TextAlign.center,
          style: MindHeaderScoreChartStyle.timeLabelTextStyle,
        ),
      ),
    ),
  );
}

/// A five-label, no-axis projection under the accepted plot. Its clipping is
/// derived from the same Header expansion scalar as the line itself; it has no
/// ticker, entrance animation or independent time model.
final class _MindHeaderScoreChartTimeLabels extends StatelessWidget {
  const _MindHeaderScoreChartTimeLabels({
    required this.series,
    required this.expansionProgress,
    required this.layout,
  });

  final MindBehavioralScoreChartSeries series;
  final double expansionProgress;
  final DashboardHeaderTrendChartLayout layout;

  @override
  Widget build(BuildContext context) {
    final visibleHeight =
        (layout.timeLabelRevealExtent * expansionProgress -
                layout.plotHeight -
                4)
            .clamp(0.0, MindHeaderScoreChartStyle.timeLabelHeight)
            .toDouble();
    if (visibleHeight <= 0) return const SizedBox.shrink();
    final epochDays = MindHeaderScoreChart.projectedTimeLabelEpochDays(series);
    final projection = MindHeaderScoreChartTemporalProjection(
      startInclusiveEpochDay: series.startInclusiveEpochDay,
      endInclusiveEpochDay: series.endInclusiveEpochDay,
    );
    final labels = epochDays
        .map(
          (epochDay) => _formatEpochDay(
            epochDay,
            startInclusiveEpochDay: series.startInclusiveEpochDay,
            endInclusiveEpochDay: series.endInclusiveEpochDay,
          ),
        )
        .toList(growable: false);
    return Positioned(
      left: MindHeaderScoreChartStyle.plotLeft,
      top: layout.timeLabelTop,
      width: MindHeaderScoreChartStyle.plotWidth,
      height: visibleHeight,
      child: ClipRect(
        child: SizedBox(
          height: MindHeaderScoreChartStyle.timeLabelHeight,
          child: ExcludeSemantics(
            child: Stack(
              children: List<Widget>.generate(5, (index) {
                // Alignment maps -1/-.5/0/.5/1 to the actual plot-domain
                // fractions 0/.25/.5/.75/1. A five-way Row would visually
                // place quarter labels at 30% and 70%, which is not the
                // requested temporal projection.
                final fraction = projection.normalizedEpochDay(
                  epochDays[index],
                );
                final label = Text(
                  labels[index],
                  key: ValueKey<String>(
                    'mind-header-score-chart-time-label-$index',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: MindHeaderScoreChartStyle.timeLabelTextStyle,
                );
                if (index == 0) {
                  return Align(alignment: Alignment.centerLeft, child: label);
                }
                if (index == 4) {
                  return Align(alignment: Alignment.centerRight, child: label);
                }
                return Align(
                  alignment: Alignment(-1 + fraction * 2, 0),
                  // A zero-width anchor keeps the text's centre at the
                  // temporal fraction instead of letting its own glyph width
                  // displace the 25/50/75% coordinate.
                  child: SizedBox(
                    width: 0,
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      alignment: Alignment.center,
                      child: label,
                    ),
                  ),
                );
              }, growable: false),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatEpochDay(
    int epochDay, {
    required int startInclusiveEpochDay,
    required int endInclusiveEpochDay,
  }) {
    final date = DateTime.utc(1970).add(Duration(days: epochDay));
    final start = DateTime.utc(
      1970,
    ).add(Duration(days: startInclusiveEpochDay));
    final end = DateTime.utc(1970).add(Duration(days: endInclusiveEpochDay));
    final spanDays = endInclusiveEpochDay - startInclusiveEpochDay;
    if (spanDays <= 40) return '${date.day}.';
    if (start.year == end.year) {
      return DashboardTimeLabelFormatter.shortMonthName(date.month);
    }
    return '${date.year}. ${DashboardTimeLabelFormatter.shortMonthName(date.month)}';
  }
}

/// Draws the one reference-faithful chart: a soft white under-line fade, a
/// minimal white score line and its subtle outlined latest-value marker.
/// It consumes already-calculated score points only.
final class MindHeaderScoreChartPainter extends CustomPainter {
  MindHeaderScoreChartPainter({
    required this.series,
    this.selectedEpochDay,
    this.lineColor = MindHeaderScoreChartStyle.lineColor,
    Color? areaFadeColor,
    this.showsAreaFade = true,
  }) : points = List<MindBehavioralScorePoint>.unmodifiable(series.points),
       areaFadeColor = areaFadeColor ?? lineColor;

  final MindBehavioralScoreChartSeries series;
  final List<MindBehavioralScorePoint> points;
  final int? selectedEpochDay;

  final Color lineColor;
  final Color areaFadeColor;
  final bool showsAreaFade;
  double get lineWidth => MindHeaderScoreChartStyle.lineWidth;
  double get endpointRadius => MindHeaderScoreChartStyle.endpointRadius;
  bool get smoothsBetweenDailySamples => true;
  double get areaFadeStartOpacity =>
      MindHeaderScoreChartStyle.areaFadeStartOpacity;
  double get areaFadeEndOpacity => MindHeaderScoreChartStyle.areaFadeEndOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    DashboardHeaderTrendPainter(
      series: DashboardHeaderTrendSeries(
        startInclusiveTemporalCoordinate: series.startInclusiveEpochDay,
        endInclusiveTemporalCoordinate: series.endInclusiveEpochDay,
        points: <DashboardHeaderTrendPoint>[
          for (final point in points)
            DashboardHeaderTrendPoint(
              temporalCoordinate: point.epochDay,
              value: point.score,
            ),
        ],
      ),
      minimumValue: 0,
      maximumValue: 100,
      selectedTemporalCoordinate: selectedEpochDay,
      lineColor: lineColor,
      areaFadeColor: areaFadeColor,
      showsAreaFade: showsAreaFade,
    ).paint(canvas, size);
  }

  /// Exposed for sparse-domain tests: this exact mapping drives the smooth
  /// path anchors, crosshair and interactive nearest-point choice.
  @visibleForTesting
  Offset pointOffsetAt(
    int index,
    Size size,
    MindHeaderScoreChartTemporalProjection projection,
  ) {
    final point = points[index];
    final score = point.score.clamp(0.0, 100.0).toDouble();
    final drawableHeight =
        size.height - MindHeaderScoreChartStyle.verticalPadding * 2;
    return Offset(
      projection.plotXForEpochDay(point.epochDay, size.width),
      MindHeaderScoreChartStyle.verticalPadding +
          (1 - score / 100) * drawableHeight,
    );
  }

  @override
  bool shouldRepaint(covariant MindHeaderScoreChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.selectedEpochDay != selectedEpochDay ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.areaFadeColor != areaFadeColor ||
      oldDelegate.showsAreaFade != showsAreaFade;
}
