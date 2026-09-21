import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../application/dashboard_balance_presentation.dart';
import '../../application/dashboard_balance_history_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';

/// Balance-local passive relay for the existing Header gesture layer. It has
/// no gesture-arena or financial-data ownership; the chart only observes the
/// real Header pointer sequence that is already accepted by the host.
final class BalanceHeaderHistoryChartPointerObserver {
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

/// Balance's typed adapter around the shared Header trend visual kernel.
/// Financial minor-unit values remain financial values end-to-end; only the
/// painter receives their truthful local Y extent for geometry.
final class BalanceHeaderHistoryChart extends StatefulWidget {
  const BalanceHeaderHistoryChart({
    super.key,
    required this.series,
    required this.expansionProgress,
    this.chartMode = BalanceHeaderChartMode.allTime,
    this.showTimeLabels = true,
    this.adaptiveScope = const AllTimeScope(),
    this.pointerObserver,
  });

  final DashboardBalanceHistorySeries series;
  final double expansionProgress;
  final BalanceHeaderChartMode chartMode;
  final bool showTimeLabels;
  final LedgerTimeScope adaptiveScope;
  final BalanceHeaderHistoryChartPointerObserver? pointerObserver;

  @visibleForTesting
  static List<int> projectedTimeLabelEpochMinutes(
    DashboardBalanceHistorySeries series,
  ) {
    final span =
        series.endInclusiveEpochMinute - series.startInclusiveEpochMinute;
    return List<int>.generate(
      5,
      (index) => series.startInclusiveEpochMinute + (span * index / 4).round(),
      growable: false,
    );
  }

  @override
  State<BalanceHeaderHistoryChart> createState() =>
      _BalanceHeaderHistoryChartState();
}

final class _BalanceHeaderHistoryChartState
    extends State<BalanceHeaderHistoryChart> {
  final GlobalKey _plotKey = GlobalKey(
    debugLabel: 'balance-header-history-plot',
  );
  Offset? _pointerDownPosition;
  var _pointerExceededTapSlop = false;
  int? _selectedEpochMinute;
  DashboardBalanceHistorySeries? _cachedSource;
  BalanceHeaderChartMode? _cachedMode;
  LedgerTimeScope? _cachedAdaptiveScope;
  DashboardBalanceHistorySeries? _cachedProjection;
  var _hasCachedProjection = false;

  @override
  void initState() {
    super.initState();
    _attachPointerObserver(widget.pointerObserver);
  }

  @override
  void didUpdateWidget(covariant BalanceHeaderHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pointerObserver, widget.pointerObserver)) {
      oldWidget.pointerObserver?.detach();
      _attachPointerObserver(widget.pointerObserver);
    }
    if (oldWidget.series != widget.series ||
        oldWidget.chartMode != widget.chartMode ||
        oldWidget.adaptiveScope != widget.adaptiveScope) {
      _selectedEpochMinute = null;
    }
  }

  @override
  void dispose() {
    widget.pointerObserver?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reveal = widget.expansionProgress.clamp(0.0, 1.0).toDouble();
    final source = _projectedSeries();
    if (source == null) return const SizedBox.shrink();
    if (reveal <= 0 || source.points.isEmpty) return const SizedBox.shrink();
    final trend = DashboardHeaderTrendSeries(
      startInclusiveTemporalCoordinate: source.startInclusiveEpochMinute,
      endInclusiveTemporalCoordinate: source.endInclusiveEpochMinute,
      points: <DashboardHeaderTrendPoint>[
        for (final point in source.points)
          DashboardHeaderTrendPoint(
            temporalCoordinate: point.epochMinute,
            value: point.balanceMinor.toDouble(),
          ),
      ],
    );
    final values = source.points
        .map((point) => point.balanceMinor.toDouble())
        .toList(growable: false);
    final selected = _selectedPoint(source);
    final projection = DashboardHeaderTrendTemporalProjection(
      startInclusiveTemporalCoordinate: source.startInclusiveEpochMinute,
      endInclusiveTemporalCoordinate: source.endInclusiveEpochMinute,
    );
    return Positioned.fill(
      key: const ValueKey<String>('balance-header-history-chart'),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: <Widget>[
            Positioned(
              left: DashboardHeaderTrendChartStyle.plotLeft,
              top: DashboardHeaderTrendChartStyle.plotTop,
              width: DashboardHeaderTrendChartStyle.plotWidth,
              height: DashboardHeaderTrendChartStyle.plotHeight,
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
                      'balance-header-history-chart-reveal',
                    ),
                    width: DashboardHeaderTrendChartStyle.plotWidth,
                    height: DashboardHeaderTrendChartStyle.plotHeight * reveal,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: DashboardHeaderTrendChartStyle.plotWidth,
                          height: DashboardHeaderTrendChartStyle.plotHeight,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              key: const ValueKey<String>(
                                'balance-header-history-chart-paint',
                              ),
                              painter: DashboardHeaderTrendPainter(
                                series: trend,
                                minimumValue: values.reduce(math.min),
                                maximumValue: values.reduce(math.max),
                                selectedTemporalCoordinate:
                                    selected?.epochMinute,
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
              _BalanceHeaderHistoryTimeLabels(
                series: source,
                expansionProgress: reveal,
              ),
            if (selected != null)
              _BalanceHeaderHistorySelectedLabels(
                point: selected,
                projection: projection,
                availableWidth: constraints.maxWidth,
              ),
          ],
        ),
      ),
    );
  }

  DashboardBalanceHistoryPoint? _selectedPoint(
    DashboardBalanceHistorySeries series,
  ) {
    final selected = _selectedEpochMinute;
    if (selected == null) return null;
    for (final point in series.points) {
      if (point.epochMinute == selected) return point;
    }
    return null;
  }

  DashboardBalanceHistorySeries? _projectedSeries() {
    final source = widget.series;
    if (_hasCachedProjection &&
        identical(_cachedSource, source) &&
        _cachedMode == widget.chartMode &&
        _cachedAdaptiveScope == widget.adaptiveScope) {
      return _cachedProjection;
    }
    _cachedSource = source;
    _cachedMode = widget.chartMode;
    _cachedAdaptiveScope = widget.adaptiveScope;
    _cachedProjection = DashboardBalanceHistoryViewProjection.project(
      source: source,
      mode: widget.chartMode,
      adaptiveScope: widget.adaptiveScope,
    );
    _hasCachedProjection = true;
    return _cachedProjection;
  }

  void _attachPointerObserver(
    BalanceHeaderHistoryChartPointerObserver? observer,
  ) {
    observer?.attach(
      onPointerDown: _observePointerDown,
      onPointerMove: _observePointerMove,
      onPointerUp: (event) {
        final source = _projectedSeries();
        if (source == null) return;
        _onPointerUp(
          event,
          DashboardHeaderTrendTemporalProjection(
            startInclusiveTemporalCoordinate: source.startInclusiveEpochMinute,
            endInclusiveTemporalCoordinate: source.endInclusiveEpochMinute,
          ),
        );
      },
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

  void _observePointerCancel(PointerCancelEvent _) => _resetPointer();

  void _onPointerUp(
    PointerUpEvent event,
    DashboardHeaderTrendTemporalProjection projection,
  ) {
    final origin = _pointerDownPosition;
    final shouldInspect =
        origin != null &&
        !_pointerExceededTapSlop &&
        (event.position - origin).distance <= kTouchSlop;
    _resetPointer();
    if (!shouldInspect) return;
    final source = _projectedSeries();
    if (source == null) return;
    final box = _plotKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final localPosition = box.globalToLocal(event.position);
    if (!(Offset.zero & box.size).contains(localPosition)) return;
    final trendPoints = <DashboardHeaderTrendPoint>[
      for (final point in source.points)
        DashboardHeaderTrendPoint(
          temporalCoordinate: point.epochMinute,
          value: point.balanceMinor.toDouble(),
        ),
    ];
    final index = projection.nearestPointIndexForPlotX(
      trendPoints,
      localPosition.dx,
      box.size.width,
    );
    final selected = trendPoints[index].temporalCoordinate;
    setState(() {
      _selectedEpochMinute = _selectedEpochMinute == selected ? null : selected;
    });
  }

  void _resetPointer() {
    _pointerDownPosition = null;
    _pointerExceededTapSlop = false;
  }
}

final class _BalanceHeaderHistorySelectedLabels extends StatelessWidget {
  const _BalanceHeaderHistorySelectedLabels({
    required this.point,
    required this.projection,
    required this.availableWidth,
  });

  static const _amountWidth = 74.0;
  static const _temporalWidth = 68.0;

  final DashboardBalanceHistoryPoint point;
  final DashboardHeaderTrendTemporalProjection projection;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final x =
        DashboardHeaderTrendChartStyle.plotLeft +
        projection.plotXForCoordinate(
          point.epochMinute,
          DashboardHeaderTrendChartStyle.plotWidth,
        );
    return Stack(
      children: <Widget>[
        _label(
          key: const ValueKey<String>(
            'balance-header-history-chart-selected-amount',
          ),
          text: DashboardPreparedFormatter.amountMinor(point.balanceMinor),
          left: _clampedLeft(x, _amountWidth),
          top: DashboardHeaderTrendChartStyle.plotTop + 1,
          width: _amountWidth,
        ),
        _label(
          key: const ValueKey<String>(
            'balance-header-history-chart-selected-temporal-label',
          ),
          text: _formatEpochDay(point.epochDay),
          left: _clampedLeft(x, _temporalWidth),
          top:
              DashboardHeaderTrendChartStyle.plotTop +
              DashboardHeaderTrendChartStyle.plotHeight -
              DashboardHeaderTrendChartStyle.timeLabelHeight,
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
    height: DashboardHeaderTrendChartStyle.timeLabelHeight,
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
          style: DashboardHeaderTrendChartStyle.timeLabelTextStyle,
        ),
      ),
    ),
  );
}

final class _BalanceHeaderHistoryTimeLabels extends StatelessWidget {
  const _BalanceHeaderHistoryTimeLabels({
    required this.series,
    required this.expansionProgress,
  });

  final DashboardBalanceHistorySeries series;
  final double expansionProgress;

  @override
  Widget build(BuildContext context) {
    final visibleHeight =
        (DashboardHeaderTrendChartStyle.timeLabelRevealExtent *
                    expansionProgress -
                DashboardHeaderTrendChartStyle.plotHeight -
                4)
            .clamp(0.0, DashboardHeaderTrendChartStyle.timeLabelHeight)
            .toDouble();
    if (visibleHeight <= 0) return const SizedBox.shrink();
    final coordinates =
        BalanceHeaderHistoryChart.projectedTimeLabelEpochMinutes(series);
    final projection = DashboardHeaderTrendTemporalProjection(
      startInclusiveTemporalCoordinate: series.startInclusiveEpochMinute,
      endInclusiveTemporalCoordinate: series.endInclusiveEpochMinute,
    );
    return Positioned(
      left: DashboardHeaderTrendChartStyle.plotLeft,
      top: DashboardHeaderTrendChartStyle.timeLabelTop,
      width: DashboardHeaderTrendChartStyle.plotWidth,
      height: visibleHeight,
      child: ClipRect(
        child: SizedBox(
          height: DashboardHeaderTrendChartStyle.timeLabelHeight,
          child: ExcludeSemantics(
            child: Stack(
              children: List<Widget>.generate(5, (index) {
                final coordinate = coordinates[index];
                final fraction = projection.normalizedCoordinate(coordinate);
                final label = Text(
                  _formatEpochMinute(
                    coordinate,
                    start: series.startInclusiveEpochMinute,
                    end: series.endInclusiveEpochMinute,
                  ),
                  key: ValueKey<String>(
                    'balance-header-history-chart-time-label-$index',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: DashboardHeaderTrendChartStyle.timeLabelTextStyle,
                );
                if (index == 0) {
                  return Align(alignment: Alignment.centerLeft, child: label);
                }
                if (index == 4) {
                  return Align(alignment: Alignment.centerRight, child: label);
                }
                return Align(
                  alignment: Alignment(-1 + fraction * 2, 0),
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
}

String _formatEpochMinute(int epochMinute, {int? start, int? end}) {
  final date = DateTime.utc(1970).add(Duration(days: epochMinute ~/ 1440));
  if (start == null || end == null || (end - start) <= 40 * 1440) {
    return '${date.day}.';
  }
  final startDate = DateTime.utc(1970).add(Duration(days: start ~/ 1440));
  final endDate = DateTime.utc(1970).add(Duration(days: end ~/ 1440));
  final month = DashboardTimeLabelFormatter.shortMonthName(date.month);
  return startDate.year == endDate.year ? month : '${date.year}. $month';
}

String _formatEpochDay(int epochDay) {
  final date = DateTime.utc(1970).add(Duration(days: epochDay));
  return '${date.year}. ${DashboardTimeLabelFormatter.shortMonthName(date.month)} ${date.day}.';
}
