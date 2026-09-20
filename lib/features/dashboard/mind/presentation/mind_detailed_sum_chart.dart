import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import '../../presentation/dashboard_vertical_scroll_boundary_handoff.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../domain/mind_detailed_sum_chart_model.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import 'mind_anchored_info_card.dart';
import 'mind_sum_year_band_header.dart';

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
    this.visibleChartCount = MindSumVisibleChartCount.two,
    this.interpolationMode = MindSumLineInterpolationMode.linear,
    this.catmullRomTension = .5,
    this.temporalSmoothingEnabled = false,
    this.smoothingWindow = MindSumSmoothingWindow.days3,
    this.zoomAdaptiveSmoothingEnabled = false,
    this.upperVerticalGestures,
  });

  final MindSumHeatmapFrame frame;
  final Color lineColor;
  final ScrollController scrollController;
  final MindSumVisibleChartCount visibleChartCount;
  final MindSumLineInterpolationMode interpolationMode;
  final double catmullRomTension;
  final bool temporalSmoothingEnabled;
  final MindSumSmoothingWindow smoothingWindow;
  final bool zoomAdaptiveSmoothingEnabled;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<MindDetailedSumChart> createState() => _MindDetailedSumChartState();
}

final class _MindDetailedSumChartState extends State<MindDetailedSumChart> {
  final _activePointers = <int>{};
  final _pointerPositions = <int, Offset>{};
  late final ValueNotifier<bool> _pinchActive;
  MindDetailedSumNormalizedViewport _viewport =
      const MindDetailedSumNormalizedViewport.fullYear();
  MindDetailedSumNormalizedViewport? _scaleStartViewport;
  double? _scaleStartDistance;
  double _parentPlotWidth = 1;

  @override
  void initState() {
    super.initState();
    _pinchActive = ValueNotifier<bool>(false);
    _log('DETAIL_SURFACE', 'mode=detailed ${_viewportScope()}');
  }

  @override
  void didUpdateWidget(covariant MindDetailedSumChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.identity != widget.frame.identity) {
      _viewport = const MindDetailedSumNormalizedViewport.fullYear();
      _scaleStartViewport = null;
      _log('VIEWPORT_RESET', 'reason=frameIdentity ${_viewportScope()}');
    }
  }

  @override
  void dispose() {
    _pinchActive.dispose();
    super.dispose();
  }

  void _trackPointerDown(PointerDownEvent event) {
    if (!_activePointers.add(event.pointer)) return;
    _pointerPositions[event.pointer] = event.localPosition;
    _syncPointerMode();
    if (_pinchActive.value) _onParentScaleStart();
  }

  void _trackPointerMove(PointerMoveEvent event) {
    if (!_activePointers.contains(event.pointer)) return;
    _pointerPositions[event.pointer] = event.localPosition;
    if (_pinchActive.value) _onParentScaleUpdate();
  }

  void _trackPointerEnd(PointerEvent event) {
    final wasScaling = _pinchActive.value;
    if (wasScaling) _onParentScaleEnd();
    if (!_activePointers.remove(event.pointer)) return;
    _pointerPositions.remove(event.pointer);
    _syncPointerMode();
  }

  void _syncPointerMode() {
    final next = _activePointers.length >= 2;
    if (_pinchActive.value == next) return;
    _pinchActive.value = next;
    _log(
      'PINCH_OWNERSHIP',
      'mode=detailed pointers=${_activePointers.length} '
          'pinchActive=$next competing=verticalBoundarySuppressed '
          '${_viewportScope()}',
    );
    setState(() {});
  }

  void _onParentScaleStart() {
    final pair = _pointerPair;
    if (pair == null) return;
    _scaleStartViewport = _viewport;
    _scaleStartDistance = math.max(1, (pair.$1 - pair.$2).distance);
    _log(
      'SCALE_START',
      'mode=detailed owner=parent pointers=${_activePointers.length} '
          'plotWidth=${_parentPlotWidth.toStringAsFixed(1)} '
          'focal=${_focalFraction(pair).toStringAsFixed(3)} '
          '${_viewportScope(plotWidth: _parentPlotWidth)}',
    );
  }

  void _onParentScaleUpdate() {
    final pair = _pointerPair;
    final start = _scaleStartViewport;
    final startDistance = _scaleStartDistance;
    if (pair == null || start == null || startDistance == null) return;
    final scaleDelta =
        math.max(1, (pair.$1 - pair.$2).distance) / startDistance;
    final focalFraction = _focalFraction(pair);
    final next = start.zoomForGesture(
      scaleDelta: scaleDelta,
      focalFraction: focalFraction,
    );
    if (next == _viewport) return;
    final before = _viewportScope(plotWidth: _parentPlotWidth);
    setState(() => _viewport = next);
    _log(
      'SCALE_UPDATE',
      'mode=detailed owner=parent pointers=${_activePointers.length} '
          'focal=${focalFraction.toStringAsFixed(3)} '
          'scale=${scaleDelta.toStringAsFixed(3)} accepted=true '
          'windowBefore={$before} windowAfter={${_viewportScope(plotWidth: _parentPlotWidth)}} '
          'synced=true competing=verticalBoundarySuppressed',
    );
  }

  void _onParentScaleEnd() {
    if (_scaleStartViewport == null) return;
    _scaleStartViewport = null;
    _scaleStartDistance = null;
    _log(
      'SCALE_END',
      'mode=detailed owner=parent pointers=${_activePointers.length} '
          '${_viewportScope(plotWidth: _parentPlotWidth)}',
    );
    _logBandDiagnostics(reason: 'SCALE_END');
  }

  (Offset, Offset)? get _pointerPair {
    if (_pointerPositions.length < 2) return null;
    final iterator = _pointerPositions.values.iterator;
    iterator.moveNext();
    final first = iterator.current;
    iterator.moveNext();
    return (first, iterator.current);
  }

  double _focalFraction((Offset, Offset) pair) =>
      (((pair.$1.dx + pair.$2.dx) / 2 - 34) / _parentPlotWidth)
          .clamp(0.0, 1.0)
          .toDouble();

  void _panBy(double deltaX, double plotWidth) {
    if (_pinchActive.value || !_viewport.isZoomed || plotWidth <= 0) return;
    final next = _viewport.panByFraction(
      -deltaX / plotWidth * _viewport.visibleFraction,
    );
    if (next == _viewport) return;
    setState(() => _viewport = next);
    _log(
      'PAN',
      'mode=detailed deltaX=${deltaX.toStringAsFixed(1)} ${_viewportScope()}',
    );
  }

  void _logBandDiagnostics({required String reason}) {
    for (final year in widget.frame.years) {
      final window = _viewport.windowForYear(year);
      final source = _detailSourceForWindow(
        frame: widget.frame,
        year: year,
        window: window,
        plotWidth: _parentPlotWidth,
      );
      final selection = MindDetailedSumLod.select(
        points: source,
        window: window,
        pixelWidth: _parentPlotWidth,
      );
      final stableDomain = _stableYearDomain(frame: widget.frame, year: year);
      final visibleSourceCount = source
          .where(
            (point) =>
                point.epochMinute >= window.startEpochMinute &&
                point.epochMinute <= window.endEpochMinute,
          )
          .length;
      final leftNeighbours = source
          .where((point) => point.epochMinute < window.startEpochMinute)
          .length;
      final rightNeighbours = source
          .where((point) => point.epochMinute > window.endEpochMinute)
          .length;
      final maximum = math.max(
        1,
        stableDomain.fold<int>(
          0,
          (value, point) => math.max(value, point.total),
        ),
      );
      final first = selection.inspectablePoints.firstOrNull;
      final last = selection.inspectablePoints.lastOrNull;
      _log(
        'BAND_SNAPSHOT',
        'reason=$reason year=$year '
            'viewportStart=${_viewport.startFraction.toStringAsFixed(5)} '
            'viewportSpan=${_viewport.visibleFraction.toStringAsFixed(5)} '
            'startEpochDay=${window.startEpochDay} endEpochDay=${window.endEpochDay} '
            'sourcePoints=${source.length} visibleSourcePoints=$visibleSourceCount '
            'anchors=${selection.inspectablePoints.length} '
            'paintAnchors=${selection.paintPoints.length} '
            'bucketMinutes=${selection.bucketSpanMinutes} stableYMaximum=$maximum '
            'first=${_pointSummary(first)} last=${_pointSummary(last)} '
            'anchorDigest=${_anchorDigest(selection.inspectablePoints)} '
            'leftNeighbours=$leftNeighbours rightNeighbours=$rightNeighbours '
            'leftPaintContinuation=${selection.hasLeftPaintContinuation} '
            'rightPaintContinuation=${selection.hasRightPaintContinuation}',
      );
    }
  }

  String _pointSummary(MindSumHeatmapDetailPoint? point) => point == null
      ? '-'
      : '${point.epochMinute}/${point.total}/${point.ordinal ?? '-'}';

  String _anchorDigest(Iterable<MindSumHeatmapDetailPoint> points) {
    var digest = 0x811c9dc5;
    for (final point in points) {
      for (final value in <int>[
        point.epochMinute,
        point.total,
        point.ordinal ?? -1,
      ]) {
        digest = ((digest ^ value) * 0x01000193) & 0x7fffffff;
      }
    }
    return digest.toRadixString(16);
  }

  void _onPointSelected(int year, MindSumHeatmapDetailPoint? point) {
    if (point == null) return;
    final day = point.epochMinute ~/ _detailMinutesPerDay;
    _log(
      'TAP_INSPECT',
      'mode=detailed year=$year nearestEpochDay=$day '
          'nearestAmount=${point.total} ${_viewportScope(year: year)}',
    );
  }

  String _viewportScope({int? year, double? plotWidth}) {
    final effectiveYear =
        year ?? (widget.frame.years.isEmpty ? 0 : widget.frame.years.first);
    final window = effectiveYear == 0
        ? null
        : _viewport.windowForYear(effectiveYear);
    final anchors = window == null || plotWidth == null
        ? 0
        : MindDetailedSumLod.sample(
            points: _detailSourceForWindow(
              frame: widget.frame,
              year: effectiveYear,
              window: window,
              plotWidth: plotWidth,
            ),
            window: window,
            pixelWidth: plotWidth,
          ).length;
    return 'visibleYears=${widget.frame.years.length} renderedBands=${widget.frame.years.length} '
        'window=${window?.startEpochDay ?? '-'}:${window?.endEpochDay ?? '-'} '
        'spanDays=${window?.visibleDayCount ?? 0} '
        'homeWindow=fullYear minimumWindow=1m anchors=$anchors '
        'viewportStart=${_viewport.startFraction.toStringAsFixed(3)} '
        'viewportSpan=${_viewport.visibleFraction.toStringAsFixed(3)}';
  }

  void _log(String suffix, String scope) => FluviDiagnosticLogger.log(
    FluviDiagnosticEvent(stage: 'MIND_SUM|$suffix', scope: scope),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _parentPlotWidth = math.max(1.0, constraints.maxWidth - 34 - 3);
      final years = widget.frame.years;
      final availableHeight = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : 236.0;
      final density = MindSumChartDensityGeometry.resolve(
        availableHeight: availableHeight,
        yearCount: years.length,
        preference: widget.visibleChartCount,
      );
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _trackPointerDown,
        onPointerMove: _trackPointerMove,
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
              separatorBuilder: (_, _) =>
                  SizedBox(height: density.interBandGap),
              itemBuilder: (context, index) {
                final year = years[index];
                return SizedBox(
                  height: density.bandHeight,
                  child: _MindDetailedSumYearBand(
                    key: ValueKey<String>('mind-sum-detailed-band-$year'),
                    year: year,
                    frame: widget.frame,
                    lineColor: widget.lineColor,
                    viewport: _viewport,
                    pinchActive: _pinchActive,
                    onPanBy: _panBy,
                    onPanEnd: () => _logBandDiagnostics(reason: 'PAN_END'),
                    onPointSelected: _onPointSelected,
                    interpolationMode: widget.interpolationMode,
                    catmullRomTension: widget.catmullRomTension,
                    temporalSmoothingEnabled: widget.temporalSmoothingEnabled,
                    smoothingWindow: widget.smoothingWindow,
                    zoomAdaptiveSmoothingEnabled:
                        widget.zoomAdaptiveSmoothingEnabled,
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

/// Retrieves only the current LOD window and one stable bucket on either side.
/// The bucket grid itself is year-anchored in [MindDetailedSumLod], so the
/// extra source is sufficient to keep all interior pan anchors immutable.
List<MindSumHeatmapDetailPoint> _detailSourceForWindow({
  required MindSumHeatmapFrame frame,
  required int year,
  required MindDetailedSumTimeWindow window,
  required double plotWidth,
}) {
  final padding = MindDetailedSumLod.sourcePaddingMinutes(
    window: window,
    pixelWidth: plotWidth,
  );
  final rawTransactions =
      window.visibleMinuteCount <= MindSumHeatmapFrame.rawDetailWindowMinutes;
  return frame.detailPointsForYear(
    year: year,
    startEpochMinute: math.max(
      window.homeStartEpochMinute,
      window.startEpochMinute - padding,
    ),
    endEpochMinute: math.min(
      window.homeEndEpochMinute,
      window.endEpochMinute + padding,
    ),
    forceRawTransactions: rawTransactions,
  );
}

/// A per-year, current-frame/range domain. It intentionally excludes only
/// horizontal viewport position: pan is a translation/crop operation, not a
/// financial rescale operation.
List<MindSumHeatmapDetailPoint> _stableYearDomain({
  required MindSumHeatmapFrame frame,
  required int year,
}) {
  final home = MindDetailedSumTimeWindow.fullYear(year);
  return frame.detailPointsForYear(
    year: year,
    startEpochMinute: home.homeStartEpochMinute,
    endEpochMinute: home.homeEndEpochMinute,
  );
}

final class _MindDetailedSumYearBand extends StatefulWidget {
  const _MindDetailedSumYearBand({
    super.key,
    required this.year,
    required this.frame,
    required this.lineColor,
    required this.viewport,
    required this.pinchActive,
    required this.onPanBy,
    required this.onPanEnd,
    required this.onPointSelected,
    required this.interpolationMode,
    required this.catmullRomTension,
    required this.temporalSmoothingEnabled,
    required this.smoothingWindow,
    required this.zoomAdaptiveSmoothingEnabled,
  });

  final int year;
  final MindSumHeatmapFrame frame;
  final Color lineColor;
  final MindDetailedSumNormalizedViewport viewport;
  final ValueListenable<bool> pinchActive;
  final void Function(double deltaX, double plotWidth) onPanBy;
  final VoidCallback onPanEnd;
  final void Function(int year, MindSumHeatmapDetailPoint? point)
  onPointSelected;
  final MindSumLineInterpolationMode interpolationMode;
  final double catmullRomTension;
  final bool temporalSmoothingEnabled;
  final MindSumSmoothingWindow smoothingWindow;
  final bool zoomAdaptiveSmoothingEnabled;

  @override
  State<_MindDetailedSumYearBand> createState() =>
      _MindDetailedSumYearBandState();
}

final class _MindDetailedSumYearBandState
    extends State<_MindDetailedSumYearBand> {
  final _cardKey = GlobalKey();
  MindSumHeatmapDetailPoint? _selectedPoint;
  Offset? _selectionAnchor;

  MindDetailedSumTimeWindow get _window =>
      widget.viewport.windowForYear(widget.year);

  @override
  void didUpdateWidget(covariant _MindDetailedSumYearBand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year ||
        oldWidget.frame.identity != widget.frame.identity) {
      _selectedPoint = null;
      _selectionAnchor = null;
    }
  }

  bool get _isZoomed => widget.viewport.isZoomed;

  void _panBy(DragUpdateDetails details, double plotWidth) {
    if (widget.pinchActive.value || plotWidth <= 0 || !_isZoomed) return;
    widget.onPanBy(details.delta.dx, plotWidth);
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
    widget.onPointSelected(widget.year, samePoint ? null : nearest);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const headerHeight = 18.0;
      const axisLeft = 34.0;
      const axisBottom = 18.0;
      final plotWidth = math.max(1.0, constraints.maxWidth - axisLeft - 3);
      final source = _detailSourceForWindow(
        frame: widget.frame,
        year: widget.year,
        window: _window,
        plotWidth: plotWidth,
      );
      final selection = MindDetailedSumLod.select(
        points: source,
        window: _window,
        pixelWidth: plotWidth,
      );
      final lod = selection.inspectablePoints;
      final maximum = math.max(
        1,
        _stableYearDomain(
          frame: widget.frame,
          year: widget.year,
        ).fold<int>(0, (value, point) => math.max(value, point.total)),
      );
      final smoothingStrength =
          !widget.temporalSmoothingEnabled &&
              !widget.zoomAdaptiveSmoothingEnabled
          ? 0.0
          : widget.zoomAdaptiveSmoothingEnabled
          ? (_window.visibleMinuteCount / _window.homeMinuteCount)
                .clamp(0.0, 1.0)
                .toDouble()
          : 1.0;
      final curvePoints = MindDetailedSumVisualSmoothing.apply(
        points: selection.paintPoints,
        window: widget.smoothingWindow,
        strength: smoothingStrength,
      );
      final chart = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _selectNearestPoint(
          details: details,
          points: lod,
          plotLeft: axisLeft,
          plotWidth: plotWidth,
        ),
        child: CustomPaint(
          key: ValueKey<String>('mind-sum-detailed-plot-${widget.year}'),
          painter: _MindDetailedSumPainter(
            curvePoints: curvePoints,
            markerPoints: selection.paintPoints,
            window: _window,
            lineColor: widget.lineColor,
            axisLeft: axisLeft,
            axisBottom: axisBottom,
            maximum: maximum,
            year: widget.year,
            interpolationMode: widget.interpolationMode,
            catmullRomTension: widget.catmullRomTension,
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
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    MindSumYearBandHeader(
                      frame: widget.frame,
                      year: widget.year,
                      surface: 'detailed',
                    ),
                    Semantics(
                      key: ValueKey<String>(
                        'mind-sum-detailed-presentation-${widget.year}',
                      ),
                      label:
                          '${widget.interpolationMode.name}|${widget.smoothingWindow.name}|${smoothingStrength.toStringAsFixed(3)}|${widget.zoomAdaptiveSmoothingEnabled}',
                      child: const SizedBox(width: 0, height: 0),
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
                        'mind-sum-detailed-paint-anchor-count-${widget.year}',
                      ),
                      label: '${selection.paintPoints.length}',
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
                              onHorizontalDragEnd: (_) => widget.onPanEnd(),
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
    required this.curvePoints,
    required this.markerPoints,
    required this.window,
    required this.lineColor,
    required this.axisLeft,
    required this.axisBottom,
    required this.maximum,
    required this.year,
    required this.interpolationMode,
    required this.catmullRomTension,
  });

  final List<MindSumHeatmapDetailPoint> curvePoints;
  final List<MindSumHeatmapDetailPoint> markerPoints;
  final MindDetailedSumTimeWindow window;
  final Color lineColor;
  final double axisLeft;
  final double axisBottom;
  final int maximum;
  final int year;
  final MindSumLineInterpolationMode interpolationMode;
  final double catmullRomTension;

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
    if (curvePoints.isEmpty) return;
    Offset pointAt(MindSumHeatmapDetailPoint point) {
      final fraction =
          (point.epochMinute - window.startEpochMinute) /
          math.max(1, window.visibleMinuteCount - 1);
      final intensity = (point.total / maximum).clamp(0.0, 1.0).toDouble();
      return Offset(
        plot.left + plot.width * fraction,
        plot.bottom - plot.height * intensity,
      );
    }

    final offsets = curvePoints.map(pointAt).toList(growable: false);
    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final segment in mindDetailedSumCurveSegments(
      points: offsets,
      interpolationMode: interpolationMode,
      catmullRomTension: catmullRomTension,
    )) {
      if (segment.isLinear) {
        line.lineTo(segment.end.dx, segment.end.dy);
      } else {
        line.cubicTo(
          segment.controlOne.dx,
          segment.controlOne.dy,
          segment.controlTwo.dx,
          segment.controlTwo.dy,
          segment.end.dx,
          segment.end.dy,
        );
      }
    }
    final fill = Path.from(line)
      ..lineTo(offsets.last.dx, plot.bottom)
      ..lineTo(offsets.first.dx, plot.bottom)
      ..close();
    canvas.save();
    canvas.clipRect(plot);
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
    for (final point in markerPoints) {
      canvas.drawCircle(pointAt(point), 1.5, marker);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MindDetailedSumPainter oldDelegate) =>
      oldDelegate.curvePoints != curvePoints ||
      oldDelegate.markerPoints != markerPoints ||
      oldDelegate.window != window ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.maximum != maximum ||
      oldDelegate.year != year ||
      oldDelegate.interpolationMode != interpolationMode ||
      oldDelegate.catmullRomTension != catmullRomTension;
}

@immutable
final class MindDetailedSumCurveSegment {
  const MindDetailedSumCurveSegment({
    required this.start,
    required this.controlOne,
    required this.controlTwo,
    required this.end,
    required this.isLinear,
  });

  final Offset start;
  final Offset controlOne;
  final Offset controlTwo;
  final Offset end;
  final bool isLinear;
}

/// Converts already scaled visual anchors into bounded curve controls. Cubic
/// control Y values are clamped to each segment's endpoint range, preventing
/// an interpolation-only financial peak or trough.
@visibleForTesting
List<MindDetailedSumCurveSegment> mindDetailedSumCurveSegments({
  required List<Offset> points,
  required MindSumLineInterpolationMode interpolationMode,
  required double catmullRomTension,
}) {
  if (points.length < 2) return const <MindDetailedSumCurveSegment>[];
  return switch (interpolationMode) {
    MindSumLineInterpolationMode.linear =>
      List<MindDetailedSumCurveSegment>.generate(
        points.length - 1,
        (index) => MindDetailedSumCurveSegment(
          start: points[index],
          controlOne: points[index],
          controlTwo: points[index + 1],
          end: points[index + 1],
          isLinear: true,
        ),
        growable: false,
      ),
    MindSumLineInterpolationMode.monotoneCubic => _monotoneCubicSegments(
      points,
    ),
    MindSumLineInterpolationMode.catmullRom => _catmullRomSegments(
      points,
      catmullRomTension,
    ),
  };
}

List<MindDetailedSumCurveSegment> _monotoneCubicSegments(List<Offset> points) {
  final slopes = List<double>.filled(points.length, 0);
  final segments = List<double>.filled(points.length - 1, 0);
  for (var index = 0; index < segments.length; index += 1) {
    final dx = points[index + 1].dx - points[index].dx;
    segments[index] = dx <= 0
        ? 0
        : (points[index + 1].dy - points[index].dy) / dx;
  }
  slopes[0] = segments.first;
  slopes[slopes.length - 1] = segments.last;
  for (var index = 1; index < slopes.length - 1; index += 1) {
    final previous = segments[index - 1];
    final next = segments[index];
    slopes[index] = previous * next <= 0 ? 0 : (previous + next) / 2;
  }
  return List<MindDetailedSumCurveSegment>.generate(points.length - 1, (index) {
    final start = points[index];
    final end = points[index + 1];
    final dx = end.dx - start.dx;
    if (dx <= 0) {
      return MindDetailedSumCurveSegment(
        start: start,
        controlOne: start,
        controlTwo: end,
        end: end,
        isLinear: true,
      );
    }
    final lower = math.min(start.dy, end.dy);
    final upper = math.max(start.dy, end.dy);
    final controlOneY = (start.dy + slopes[index] * dx / 3)
        .clamp(lower, upper)
        .toDouble();
    final controlTwoY = (end.dy - slopes[index + 1] * dx / 3)
        .clamp(lower, upper)
        .toDouble();
    return MindDetailedSumCurveSegment(
      start: start,
      controlOne: Offset(start.dx + dx / 3, controlOneY),
      controlTwo: Offset(end.dx - dx / 3, controlTwoY),
      end: end,
      isLinear: false,
    );
  }, growable: false);
}

List<MindDetailedSumCurveSegment> _catmullRomSegments(
  List<Offset> points,
  double tension,
) {
  final scale = (1 - tension.clamp(0.0, 1.0).toDouble()) / 2;
  return List<MindDetailedSumCurveSegment>.generate(points.length - 1, (index) {
    final before = points[index == 0 ? index : index - 1];
    final start = points[index];
    final end = points[index + 1];
    final after = points[index + 2 < points.length ? index + 2 : index + 1];
    final lower = math.min(start.dy, end.dy);
    final upper = math.max(start.dy, end.dy);
    final controlOneX = (start.dx + (end.dx - before.dx) * scale / 3)
        .clamp(start.dx, end.dx)
        .toDouble();
    final controlOneY = (start.dy + (end.dy - before.dy) * scale / 3)
        .clamp(lower, upper)
        .toDouble();
    final controlTwoX = (end.dx - (after.dx - start.dx) * scale / 3)
        .clamp(start.dx, end.dx)
        .toDouble();
    final controlTwoY = (end.dy - (after.dy - start.dy) * scale / 3)
        .clamp(lower, upper)
        .toDouble();
    return MindDetailedSumCurveSegment(
      start: start,
      controlOne: Offset(controlOneX, controlOneY),
      controlTwo: Offset(controlTwoX, controlTwoY),
      end: end,
      isLinear: false,
    );
  }, growable: false);
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
