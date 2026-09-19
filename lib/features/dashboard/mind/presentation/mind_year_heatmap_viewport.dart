import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/categories/catalog/category_visual_resolver.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_key_digest.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import '../../presentation/dashboard_paged_vertical_boundary_handoff.dart';
import '../domain/mind_year_heatmap_calendar_geometry.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_year_heatmap_palette_resolver.dart';
import 'mind_aggregate_line_chart.dart';
import 'mind_anchored_info_card.dart';

/// Immutable paint input for the Year comparison page. Full values intentionally
/// come from the unfiltered directional month authority; filtered values come
/// from the current range-preview frame days, so no second Query path exists.
@visibleForTesting
final class MindYearHeatmapPartialBarSeries {
  MindYearHeatmapPartialBarSeries._({
    required List<MindYearHeatmapPartialBarValue> values,
    required this.scale,
  }) : values = List<MindYearHeatmapPartialBarValue>.unmodifiable(values);

  factory MindYearHeatmapPartialBarSeries.fromFrame(
    MindYearHeatmapFrame frame,
  ) {
    final isIncome = frame.identity.upstreamScopeKey.startsWith('income|');
    final values = List<MindYearHeatmapPartialBarValue>.generate(12, (index) {
      final month = index + 1;
      final full = isIncome
          ? frame.monthlyAggregates.incomeForMonth(month)
          : frame.monthlyAggregates.expenseForMonth(month);
      final filtered = frame
          .month(month)
          .fold<int>(0, (sum, day) => sum + (day.total ?? 0));
      assert(() {
        if (filtered > full) {
          debugPrint(
            'Mind Year partial bar filtered amount exceeds its full '
            'directional aggregate for month $month; paint is clamped.',
          );
        }
        return true;
      }());
      return MindYearHeatmapPartialBarValue(
        month: month,
        fullAmount: full,
        filteredAmount: filtered.clamp(0, full).toInt(),
      );
    }, growable: false);
    return MindYearHeatmapPartialBarSeries._(
      values: values,
      scale: MindYearHeatmapPartialBarScale.forMaximum(
        values.fold<int>(
          0,
          (maximum, value) => math.max(maximum, value.fullAmount),
        ),
      ),
    );
  }

  final List<MindYearHeatmapPartialBarValue> values;
  final MindYearHeatmapPartialBarScale scale;
}

@visibleForTesting
final class MindYearHeatmapPartialBarValue {
  const MindYearHeatmapPartialBarValue({
    required this.month,
    required this.fullAmount,
    required this.filteredAmount,
  });

  final int month;
  final int fullAmount;
  final int filteredAmount;
}

@visibleForTesting
final class MindYearHeatmapPartialBarScale {
  MindYearHeatmapPartialBarScale._({
    required this.top,
    required this.step,
    required List<int> levels,
  }) : levels = List<int>.unmodifiable(levels);

  factory MindYearHeatmapPartialBarScale.forMaximum(int maximum) {
    if (maximum <= 0) {
      return MindYearHeatmapPartialBarScale._(
        top: 0,
        step: 1,
        levels: const <int>[0],
      );
    }
    const targetIntervals = 5;
    final rawStep = maximum / targetIntervals;
    final exponent = math.pow(10, (math.log(rawStep) / math.ln10).floor());
    final normalized = rawStep / exponent;
    final factor = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    final step = (factor * exponent).round();
    final top = ((maximum + step - 1) ~/ step) * step;
    return MindYearHeatmapPartialBarScale._(
      top: top,
      step: step,
      levels: List<int>.generate(top ~/ step + 1, (index) => index * step),
    );
  }

  final int top;
  final int step;
  final List<int> levels;
}

/// The one scroll owner for the Mind annual MonthCard region.
///
/// The parent surface decides Year visibility. This viewport owns neither a
/// query nor a slider: it observes one already-published annual read model.
final class MindYearHeatmapViewport extends StatefulWidget {
  const MindYearHeatmapViewport({
    super.key,
    required this.frameListenable,
    this.presentationSettings,
    this.scrollController,
    this.upperVerticalGestures,
  });

  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final ValueListenable<MindYearHeatmapPresentationSettings>?
  presentationSettings;
  final ScrollController? scrollController;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<MindYearHeatmapViewport> createState() =>
      _MindYearHeatmapViewportState();
}

final class _MindYearHeatmapViewportState
    extends State<MindYearHeatmapViewport> {
  late bool _hasFrame;
  int? _geometryYear;
  MindYearHeatmapIdentity? _staticFrameIdentity;
  MindYearHeatmapMonthlyAggregates? _monthlyAggregates;
  MindYearHeatmapScopedMonthlyAggregates? _scopedMonthlyAggregates;
  MindYearHeatmapInspectionScope _inspectionScope =
      const MindYearHeatmapInspectionScope();
  var _activeDirectionIsIncome = false;
  late MindYearHeatmapPresentationSettings _presentationSettings;
  MindYearHeatmapIdentity? _lastVisibleIdentity;
  int? _lastLoggedGeometryYear;
  late final PageController _pageController;
  late final ScrollController _ownedAnnualScrollController;
  late final ScrollController _barPageScrollController;
  late final ScrollController _linePageScrollController;
  _MindYearDaySelection? _selectedDay;

  @override
  void initState() {
    super.initState();
    _hasFrame = widget.frameListenable.value != null;
    _geometryYear = widget.frameListenable.value?.identity.year;
    _acceptStaticFrame(widget.frameListenable.value);
    _presentationSettings =
        widget.presentationSettings?.value ??
        const MindYearHeatmapPresentationSettings.defaults();
    _pageController = PageController();
    _ownedAnnualScrollController = ScrollController();
    _barPageScrollController = ScrollController();
    _linePageScrollController = ScrollController();
    widget.frameListenable.addListener(_onFrameChanged);
    widget.presentationSettings?.addListener(_onPresentationSettingsChanged);
    if (widget.frameListenable.value case final frame?) {
      _scheduleVisiblePaintDiagnostics(frame);
    }
  }

  @override
  void didUpdateWidget(covariant MindYearHeatmapViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.frameListenable, widget.frameListenable)) {
      oldWidget.frameListenable.removeListener(_onFrameChanged);
      final nextFrame = widget.frameListenable.value;
      _hasFrame = nextFrame != null;
      _geometryYear = nextFrame?.identity.year;
      _invalidateDayInfoFor(nextFrame);
      _acceptStaticFrame(nextFrame);
      widget.frameListenable.addListener(_onFrameChanged);
    }
    if (!identical(
      oldWidget.presentationSettings,
      widget.presentationSettings,
    )) {
      oldWidget.presentationSettings?.removeListener(
        _onPresentationSettingsChanged,
      );
      _presentationSettings =
          widget.presentationSettings?.value ??
          const MindYearHeatmapPresentationSettings.defaults();
      widget.presentationSettings?.addListener(_onPresentationSettingsChanged);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ownedAnnualScrollController.dispose();
    _barPageScrollController.dispose();
    _linePageScrollController.dispose();
    widget.frameListenable.removeListener(_onFrameChanged);
    widget.presentationSettings?.removeListener(_onPresentationSettingsChanged);
    super.dispose();
  }

  ScrollController get _annualScrollController =>
      widget.scrollController ?? _ownedAnnualScrollController;

  ScrollController get _activePageScrollController {
    final page = _pageController.hasClients ? _pageController.page : 0;
    return switch ((page ?? 0).round()) {
      1 => _barPageScrollController,
      2 => _linePageScrollController,
      _ => _annualScrollController,
    };
  }

  void _onPresentationSettingsChanged() {
    final next = widget.presentationSettings?.value;
    if (next == null || next == _presentationSettings || !mounted) return;
    setState(() => _presentationSettings = next);
    // A 2×6 → 3×4 transition shortens the one existing viewport. Preserve
    // its controller/physics and correct only an offset that became outside
    // the newly computed extent.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _annualScrollController;
      if (!controller.hasClients) return;
      final position = controller.position;
      final clamped = position.pixels.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (clamped != position.pixels) controller.jumpTo(clamped);
    });
  }

  void _onFrameChanged() {
    final frame = widget.frameListenable.value;
    if (frame != null) _scheduleVisiblePaintDiagnostics(frame);
    final hasFrame = frame != null;
    final geometryYear = frame?.identity.year;
    final identityChanged = frame?.identity != _staticFrameIdentity;
    if ((hasFrame == _hasFrame &&
            geometryYear == _geometryYear &&
            !identityChanged) ||
        !mounted) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onFrameChanged();
      });
      return;
    }
    _invalidateDayInfoFor(frame);
    setState(() {
      _hasFrame = hasFrame;
      _geometryYear = geometryYear;
      _acceptStaticFrame(frame);
    });
  }

  void _invalidateDayInfoFor(MindYearHeatmapFrame? frame) {
    if (_selectedDay?.day.date.year != frame?.identity.year) {
      _selectedDay = null;
    }
  }

  void _acceptStaticFrame(MindYearHeatmapFrame? frame) {
    _staticFrameIdentity = frame?.identity;
    _monthlyAggregates = frame?.monthlyAggregates;
    _scopedMonthlyAggregates = frame?.scopedMonthlyAggregates;
    _inspectionScope =
        frame?.inspectionScope ?? const MindYearHeatmapInspectionScope();
    _activeDirectionIsIncome =
        frame?.identity.upstreamScopeKey.startsWith('income|') ?? false;
  }

  void _onDayTapped(MindYearHeatmapDay day, Offset anchor) {
    setState(() => _selectedDay = _MindYearDaySelection(day, anchor));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasFrame) {
      return const SizedBox(key: ValueKey('mind-year-heatmap-unavailable'));
    }
    final year = _geometryYear;
    if (year == null) {
      return const SizedBox(key: ValueKey('mind-year-heatmap-unavailable'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 10.0;
        const rowGap = 8.0;
        final columns = _presentationSettings.monthCardLayout.columnCount;
        final footerRowCount =
            (_presentationSettings.showMonthlyNetClose ? 1 : 0) +
            (_presentationSettings.showMonthlyDirectionTotal ? 1 : 0);
        final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
            .clamp(0.0, double.infinity)
            .toDouble();
        final monthCardWidth =
            ((contentWidth - rowGap * (columns - 1)) / columns)
                .clamp(0.0, double.infinity)
                .toDouble();
        final geometries = List<MindYearHeatmapCalendarGeometry>.generate(
          12,
          (index) => MindYearHeatmapCalendarGeometry.forMonth(
            year: year,
            month: index + 1,
          ),
          growable: false,
        );
        _scheduleCalendarGeometryDiagnostics(year, geometries);
        final Widget heatmapPage;
        if (_presentationSettings.monthCardLayout.fitsAnnualViewport) {
          final fit = _MindYearHeatmapFourColumnFit.resolve(
            viewportHeight: constraints.maxHeight,
            cardWidth: monthCardWidth,
            geometries: geometries,
            footerRowCount: footerRowCount,
            viewportTopPadding: 10,
            viewportBottomPadding: 14,
            rowGap: rowGap,
          );
          heatmapPage = KeyedSubtree(
            key: const ValueKey('mind-year-heatmap-scroll'),
            child: SingleChildScrollView(
              key: const ValueKey('mind-year-heatmap-fit-scroll'),
              controller: _annualScrollController,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
              child: KeyedSubtree(
                key: const ValueKey('mind-year-heatmap-grid'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(3, (annualRow) {
                    final offset = annualRow * columns;
                    final rowGeometries = geometries.sublist(
                      offset,
                      offset + columns,
                    );
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: annualRow == 2 ? 0 : rowGap,
                      ),
                      child: SizedBox(
                        key: ValueKey(
                          'mind-year-heatmap-annual-row-$annualRow',
                        ),
                        height: fit.rowHeights[annualRow],
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List<Widget>.generate(
                            rowGeometries.length,
                            (column) {
                              final month = offset + column + 1;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: column == rowGeometries.length - 1
                                      ? 0
                                      : rowGap,
                                ),
                                child: MindYearHeatmapMonthCard(
                                  month: month,
                                  width: monthCardWidth,
                                  cellExtent: fit.cellExtent,
                                  geometry: geometries[month - 1],
                                  frameListenable: widget.frameListenable,
                                  paletteStyle:
                                      _presentationSettings.paletteStyle,
                                  scaleResolution:
                                      _presentationSettings.scaleResolution,
                                  surfaceStyle:
                                      _presentationSettings.annualSurfaceStyle,
                                  showMonthlyNetClose:
                                      _presentationSettings.showMonthlyNetClose,
                                  showMonthlyDirectionTotal:
                                      _presentationSettings
                                          .showMonthlyDirectionTotal,
                                  monthlyAggregates: _monthlyAggregates,
                                  scopedMonthlyAggregates:
                                      _scopedMonthlyAggregates,
                                  inspectionScope: _inspectionScope,
                                  activeDirectionIsIncome:
                                      _activeDirectionIsIncome,
                                  onDayTap: _onDayTapped,
                                ),
                              );
                            },
                            growable: false,
                          ),
                        ),
                      ),
                    );
                  }, growable: false),
                ),
              ),
            ),
          );
        } else {
          heatmapPage = KeyedSubtree(
            key: const ValueKey('mind-year-heatmap-scroll'),
            child: ListView.separated(
              key: const ValueKey('mind-year-heatmap-grid'),
              controller: _annualScrollController,
              // Six-row MonthCard envelopes are intentionally taller than the
              // former variable geometry. Keep the same bounded 12-card annual
              // field warm so a layout switch never exposes a sparse edge.
              cacheExtent: 500,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
              itemCount: (12 + columns - 1) ~/ columns,
              separatorBuilder: (_, _) => const SizedBox(height: rowGap),
              itemBuilder: (context, annualRow) {
                final offset = annualRow * columns;
                final rowEnd = math.min(offset + columns, geometries.length);
                final rowGeometries = geometries.sublist(offset, rowEnd);
                final rowHeight = MindYearHeatmapMonthCard.heightFor(
                  width: monthCardWidth,
                  calendarRowCount:
                      MindYearHeatmapMonthCard.displayCalendarRowCount,
                  footerRowCount: footerRowCount,
                );
                return SizedBox(
                  key: ValueKey('mind-year-heatmap-annual-row-$annualRow'),
                  height: rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List<Widget>.generate(rowGeometries.length, (
                      column,
                    ) {
                      final month = offset + column + 1;
                      return Padding(
                        padding: EdgeInsets.only(
                          right: column == rowGeometries.length - 1
                              ? 0
                              : rowGap,
                        ),
                        child: MindYearHeatmapMonthCard(
                          month: month,
                          width: monthCardWidth,
                          geometry: geometries[month - 1],
                          frameListenable: widget.frameListenable,
                          paletteStyle: _presentationSettings.paletteStyle,
                          scaleResolution:
                              _presentationSettings.scaleResolution,
                          surfaceStyle:
                              _presentationSettings.annualSurfaceStyle,
                          showMonthlyNetClose:
                              _presentationSettings.showMonthlyNetClose,
                          showMonthlyDirectionTotal:
                              _presentationSettings.showMonthlyDirectionTotal,
                          monthlyAggregates: _monthlyAggregates,
                          scopedMonthlyAggregates: _scopedMonthlyAggregates,
                          inspectionScope: _inspectionScope,
                          activeDirectionIsIncome: _activeDirectionIsIncome,
                          onDayTap: _onDayTapped,
                        ),
                      );
                    }, growable: false),
                  ),
                );
              },
            ),
          );
        }
        return DashboardPagedVerticalBoundaryHandoff(
          upperVerticalGestures: widget.upperVerticalGestures,
          activePageScrollController: () => _activePageScrollController,
          child: PageView(
            key: const ValueKey<String>('mind-year-heatmap-pager'),
            controller: _pageController,
            children: <Widget>[
              KeyedSubtree(
                key: const ValueKey<String>('mind-year-heatmap-page-0'),
                child: Stack(
                  children: <Widget>[
                    heatmapPage,
                    if (_selectedDay case final selection?)
                      MindAnchoredInfoCard(
                        globalAnchor: selection.anchor,
                        child: _MindYearDayInfoCard(
                          day: selection.day,
                          onDismiss: () => setState(() => _selectedDay = null),
                        ),
                      ),
                  ],
                ),
              ),
              _MindYearPartialBarPage(
                key: const ValueKey<String>('mind-year-heatmap-page-1'),
                frameListenable: widget.frameListenable,
                scrollController: _barPageScrollController,
                paletteStyle: _presentationSettings.paletteStyle,
                scaleResolution: _presentationSettings.scaleResolution,
              ),
              _MindYearMonthlyLinePage(
                key: const ValueKey<String>('mind-year-heatmap-page-2'),
                frameListenable: widget.frameListenable,
                scrollController: _linePageScrollController,
                paletteStyle: _presentationSettings.paletteStyle,
                scaleResolution: _presentationSettings.scaleResolution,
              ),
            ],
          ),
        );
      },
    );
  }

  void _scheduleVisiblePaintDiagnostics(MindYearHeatmapFrame frame) {
    if (_lastVisibleIdentity == frame.identity) return;
    _lastVisibleIdentity = frame.identity;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.frameListenable.value?.identity != frame.identity) {
        return;
      }
      final direction = _directionName(frame.identity);
      final scope =
          'year=${frame.identity.year} '
          'identity=${FluviDiagnosticKeyDigest.of(frame.identity.upstreamScopeKey)} '
          'temporalGeneration=${frame.identity.navigationEpoch} '
          'nonEmptyRealDays=${frame.days.where((day) => !day.isEmpty).length} '
          'coloredDays=${frame.days.where((day) => !day.isEmpty).length}';
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND_HEATMAP|DIRECTION_VISIBLE',
          direction: direction,
          coreRevision: frame.identity.coreRevision,
          scope: scope,
        ),
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND_HEATMAP|PAINTED',
          direction: direction,
          coreRevision: frame.identity.coreRevision,
          scope: '$scope publishToPaint=nextFrame',
        ),
      );
    });
  }

  void _scheduleCalendarGeometryDiagnostics(
    int year,
    List<MindYearHeatmapCalendarGeometry> geometries,
  ) {
    if (_lastLoggedGeometryYear == year) return;
    _lastLoggedGeometryYear = year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _geometryYear != year) return;
      final leading = geometries
          .map((geometry) => geometry.leadingSlotCount)
          .join(',');
      final rows = geometries.map((geometry) => geometry.rowCount).join(',');
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND_HEATMAP|CALENDAR_GEOMETRY',
          scope:
              'year=$year columns=7 weekdayOrder=monday-sunday '
              'leadingSlots=$leading rowCounts=$rows',
        ),
      );
    });
  }

  static String? _directionName(MindYearHeatmapIdentity identity) =>
      identity.upstreamScopeKey.startsWith('income|')
      ? 'income'
      : identity.upstreamScopeKey.startsWith('expense|')
      ? 'expense'
      : null;
}

final class _MindYearDaySelection {
  const _MindYearDaySelection(this.day, this.anchor);

  final MindYearHeatmapDay day;
  final Offset anchor;
}

final class _MindYearDayInfoCard extends StatelessWidget {
  const _MindYearDayInfoCard({required this.day, required this.onDismiss});

  final MindYearHeatmapDay day;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey<String>('mind-year-day-infocard'),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x22000000), blurRadius: 12),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${day.date.year}. ${DashboardTimeLabelFormatter.monthName(day.date.month)} ${day.date.day}.\n${QueryMenuFormatters.money(day.total ?? 0)}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
          IconButton(
            key: const ValueKey<String>('mind-year-day-infocard-dismiss'),
            iconSize: 14,
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}

/// A constrained 4 × 3 annual arrangement. It does not change the heatmap
/// data frame: it solves a shared square day-cell extent from the actual
/// viewport height and the four-card row widths, then projects the existing
/// MonthCards into three non-scrolling annual rows.
final class _MindYearPartialBarPage extends StatelessWidget {
  const _MindYearPartialBarPage({
    super.key,
    required this.frameListenable,
    required this.scrollController,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final ScrollController scrollController;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  static const _monthInitials = <String>[
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

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<MindYearHeatmapFrame?>(
        valueListenable: frameListenable,
        builder: (context, frame, _) {
          if (frame == null) return const SizedBox.shrink();
          final series = MindYearHeatmapPartialBarSeries.fromFrame(frame);
          final foreground = MindYearHeatmapPaletteResolver.resolveTile(
            style: paletteStyle,
            isEmpty: false,
            intensity: 1,
            paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
            scaleResolution: scaleResolution,
          ).background;
          return LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              controller: scrollController,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: SizedBox(
                height: math.max(130, constraints.maxHeight - 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: CustomPaint(
                        key: const ValueKey<String>(
                          'mind-year-partial-bar-chart',
                        ),
                        painter: MindYearHeatmapPartialBarPainter(
                          series: series,
                          foreground: foreground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: _monthInitials
                          .map(
                            (initial) => Expanded(
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: FluviVisualTokens.textSecondary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

@visibleForTesting
final class MindYearHeatmapPartialBarPainter extends CustomPainter {
  MindYearHeatmapPartialBarPainter({
    required this.series,
    required this.foreground,
  });

  final MindYearHeatmapPartialBarSeries series;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const top = 6.0;
    const right = 4.0;
    const bottom = 4.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    final grid = Paint()
      ..color = FluviVisualTokens.surfaceMuted
      ..strokeWidth = .75;
    final labelStyle = const TextStyle(
      color: FluviVisualTokens.textSecondary,
      fontSize: 7,
    );
    for (final level in series.scale.levels) {
      final fraction = series.scale.top == 0 ? 0.0 : level / series.scale.top;
      final y = plot.bottom - plot.height * fraction;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final text = TextPainter(
        text: TextSpan(
          text: QueryMenuFormatters.money(level),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: left - 3);
      text.paint(canvas, Offset(0, y - text.height / 2));
    }
    if (series.scale.top == 0 || plot.width <= 0 || plot.height <= 0) return;
    final unit = plot.width / series.values.length;
    final barWidth = math.min(14, unit * .56).toDouble();
    final background = Paint()..color = const Color(0xFFD4D7DC);
    final foregroundPaint = Paint()..color = foreground;
    for (var index = 0; index < series.values.length; index += 1) {
      final value = series.values[index];
      final x = plot.left + unit * index + (unit - barWidth) / 2;
      final fullHeight = plot.height * value.fullAmount / series.scale.top;
      final filteredHeight =
          plot.height * value.filteredAmount / series.scale.top;
      final fullRect = Rect.fromLTWH(
        x,
        plot.bottom - fullHeight,
        barWidth,
        fullHeight,
      );
      final filteredRect = Rect.fromLTWH(
        x,
        plot.bottom - filteredHeight,
        barWidth,
        filteredHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fullRect, const Radius.circular(2)),
        background,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(filteredRect, const Radius.circular(2)),
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MindYearHeatmapPartialBarPainter oldDelegate) =>
      foreground != oldDelegate.foreground || series != oldDelegate.series;
}

/// The third annual Mind card uses only current immutable month aggregates.
/// It is deliberately distinct from the full-vs-filtered comparison bars.
final class _MindYearMonthlyLinePage extends StatelessWidget {
  const _MindYearMonthlyLinePage({
    super.key,
    required this.frameListenable,
    required this.scrollController,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final ScrollController scrollController;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  static const _monthInitials = <String>[
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

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<MindYearHeatmapFrame?>(
    valueListenable: frameListenable,
    builder: (context, frame, _) {
      if (frame == null) {
        return const SizedBox.shrink();
      }
      final points = List<MindAggregateLinePoint>.generate(12, (index) {
        final month = index + 1;
        final total = frame
            .month(month)
            .fold<int>(0, (sum, day) => sum + (day.total ?? 0));
        return MindAggregateLinePoint(
          ordinal: month,
          label: _monthInitials[index],
          total: total,
        );
      }, growable: false);
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          controller: scrollController,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: math.max(0, constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: MindAggregateLineChart(
                key: const ValueKey<String>('mind-year-monthly-line-chart'),
                points: points,
                title: 'Havi alakulás',
                subtitle: '${frame.identity.year} · 12 hónap',
                lineColor: const Color(0xff7657c5),
                monthDomain: true,
                fitDomainWidth: true,
                infoLabelForPoint: (point) =>
                    '${frame.identity.year}. ${DashboardTimeLabelFormatter.monthName(point.ordinal)}',
                relativeLabel: 'az előző hónaphoz képest',
              ),
            ),
          ),
        ),
      );
    },
  );
}

final class _MindYearHeatmapFourColumnFit {
  const _MindYearHeatmapFourColumnFit._({
    required this.cellExtent,
    required this.rowHeights,
  });

  final double cellExtent;
  final List<double> rowHeights;

  static _MindYearHeatmapFourColumnFit resolve({
    required double viewportHeight,
    required double cardWidth,
    required List<MindYearHeatmapCalendarGeometry> geometries,
    required int footerRowCount,
    required double viewportTopPadding,
    required double viewportBottomPadding,
    required double rowGap,
  }) {
    const annualRows = 3;
    // The physical MonthCard envelope is deliberately independent of a
    // month's real calendar extent. The painter still receives each exact
    // geometry and leaves unused sixth-row slots empty.
    final calendarRows = List<int>.filled(
      annualRows,
      MindYearHeatmapMonthCard.displayCalendarRowCount,
      growable: false,
    );
    final staticCardChrome = MindYearHeatmapMonthCard.fixedChromeHeightFor(
      footerRowCount: footerRowCount,
    );
    final internalDayGaps = calendarRows.fold<double>(
      0,
      (sum, rows) =>
          sum + MindYearHeatmapMonthPainter.gap * math.max(0, rows - 1),
    );
    final staticHeight =
        viewportTopPadding +
        viewportBottomPadding +
        rowGap * (annualRows - 1) +
        staticCardChrome * annualRows +
        internalDayGaps;
    final totalCalendarRows = calendarRows.fold<int>(
      0,
      (sum, rows) => sum + rows,
    );
    final cellByWidth = MindYearHeatmapMonthCard.cellExtentFor(cardWidth);
    final cellByHeight = viewportHeight.isFinite && totalCalendarRows > 0
        ? ((viewportHeight - staticHeight) / totalCalendarRows)
              .clamp(0.0, double.infinity)
              .toDouble()
        : cellByWidth;
    final cellExtent = math.min(cellByWidth, cellByHeight);
    final rowHeights = calendarRows
        .map(
          (rows) => MindYearHeatmapMonthCard.heightFor(
            width: cardWidth,
            cellExtent: cellExtent,
            calendarRowCount: rows,
            footerRowCount: footerRowCount,
          ),
        )
        .toList(growable: false);
    return _MindYearHeatmapFourColumnFit._(
      cellExtent: cellExtent,
      rowHeights: rowHeights,
    );
  }
}

/// Stable MonthCard shell. Its title is static across amount-only previews;
/// only the bounded day-tile field listens to the live frame.
final class MindYearHeatmapMonthCard extends StatelessWidget {
  const MindYearHeatmapMonthCard({
    super.key,
    required this.month,
    required this.width,
    required this.geometry,
    required this.frameListenable,
    this.cellExtent,
    this.paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
    this.scaleResolution = MindHeatmapScaleResolution.ten,
    this.surfaceStyle = MindYearHeatmapAnnualSurfaceStyle.monthCards,
    this.showMonthlyNetClose = false,
    this.showMonthlyDirectionTotal = false,
    this.monthlyAggregates,
    this.scopedMonthlyAggregates,
    this.inspectionScope = const MindYearHeatmapInspectionScope(),
    this.activeDirectionIsIncome = false,
    this.isInspected = false,
    this.inspectionProgress,
    this.onTap,
    this.onDayTap,
  });

  static const _padding = 6.0;
  static const _titleHeight = 12.0;
  static const _titleBottomGap = 4.0;
  static const _footerTopGap = 5.0;
  static const _footerRowHeight = 13.0;

  /// Presentation envelope only. Real calendar geometry remains in
  /// [geometry], so unused slots are never painted as fake days.
  static const displayCalendarRowCount = 6;

  final int month;
  final double width;
  final double? cellExtent;
  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindYearHeatmapAnnualSurfaceStyle surfaceStyle;
  final bool showMonthlyNetClose;
  final bool showMonthlyDirectionTotal;
  final MindYearHeatmapMonthlyAggregates? monthlyAggregates;
  final MindYearHeatmapScopedMonthlyAggregates? scopedMonthlyAggregates;
  final MindYearHeatmapInspectionScope inspectionScope;
  final bool activeDirectionIsIncome;
  final bool isInspected;
  final Animation<double>? inspectionProgress;
  final VoidCallback? onTap;
  final void Function(MindYearHeatmapDay day, Offset anchor)? onDayTap;

  static double cellExtentFor(double width) {
    const totalHorizontalGaps =
        (MindYearHeatmapMonthPainter.columnCount - 1) *
        MindYearHeatmapMonthPainter.gap;
    final gridWidth = width - _padding * 2;
    return ((gridWidth - totalHorizontalGaps) /
            MindYearHeatmapMonthPainter.columnCount)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  static double fixedChromeHeightFor({int footerRowCount = 0}) =>
      _padding * 2 +
      _titleHeight +
      _titleBottomGap +
      (footerRowCount == 0
          ? 0
          : _footerTopGap + _footerRowHeight * footerRowCount);

  static double gridHeightFor({
    required double width,
    required int calendarRowCount,
    double? cellExtent,
  }) {
    final resolvedCellExtent = cellExtent ?? cellExtentFor(width);
    return resolvedCellExtent * calendarRowCount +
        MindYearHeatmapMonthPainter.gap * (calendarRowCount - 1);
  }

  static double heightFor({
    required double width,
    required int calendarRowCount,
    int footerRowCount = 0,
    double? cellExtent,
  }) =>
      fixedChromeHeightFor(footerRowCount: footerRowCount) +
      gridHeightFor(
        width: width,
        calendarRowCount: calendarRowCount,
        cellExtent: cellExtent,
      );

  int get _footerRowCount =>
      (showMonthlyNetClose ? 1 : 0) + (showMonthlyDirectionTotal ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final gridHeight = gridHeightFor(
      width: width,
      calendarRowCount: displayCalendarRowCount,
      cellExtent: cellExtent,
    );
    final heatmapContent = Padding(
      padding: const EdgeInsets.all(_padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: _titleHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  DashboardTimeLabelFormatter.monthName(month),
                  maxLines: 1,
                  style: const TextStyle(
                    color: FluviVisualTokens.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _titleBottomGap),
          SizedBox(
            height: gridHeight,
            child: ValueListenableBuilder<MindYearHeatmapFrame?>(
              valueListenable: frameListenable,
              builder: (context, frame, _) {
                final days =
                    frame?.month(month) ?? const <MindYearHeatmapDay>[];
                final extent = cellExtent ?? cellExtentFor(width);
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    RepaintBoundary(
                      child: Semantics(
                        label:
                            'Mind heatmap ${DashboardTimeLabelFormatter.monthName(month)}',
                        readOnly: true,
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            key: ValueKey(
                              'mind-year-heatmap-month-cells-$month',
                            ),
                            painter: MindYearHeatmapMonthPainter(
                              month: month,
                              geometry: geometry,
                              frameListenable: frameListenable,
                              paletteStyle: paletteStyle,
                              scaleResolution: scaleResolution,
                              cellExtent: cellExtent,
                            ),
                            isComplex: false,
                            willChange: true,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    if (onDayTap != null)
                      for (final day in days.where((day) => !day.isEmpty))
                        _MindYearDayCellTapTarget(
                          key: ValueKey(
                            'mind-year-heatmap-day-tap-${day.date.year}-${day.date.month}-${day.date.day}',
                          ),
                          geometry: geometry,
                          day: day,
                          extent: extent,
                          onTap: onDayTap!,
                        ),
                  ],
                );
              },
            ),
          ),
          if (_footerRowCount > 0) ...<Widget>[
            const SizedBox(height: _footerTopGap),
            if (showMonthlyNetClose)
              _MindYearHeatmapMonthFooter(
                label: 'Zárás',
                amount: monthlyAggregates?.netForMonth(month) ?? 0,
                semanticKind: _MindYearHeatmapFooterKind.net,
              ),
            if (showMonthlyDirectionTotal)
              _MindYearHeatmapMonthFooter(
                label: activeDirectionIsIncome ? 'Bevétel' : 'Kiadás',
                amount: activeDirectionIsIncome
                    ? monthlyAggregates?.incomeForMonth(month) ?? 0
                    : monthlyAggregates?.expenseForMonth(month) ?? 0,
                semanticKind: activeDirectionIsIncome
                    ? _MindYearHeatmapFooterKind.income
                    : _MindYearHeatmapFooterKind.expense,
              ),
          ],
        ],
      ),
    );
    final surface = switch (surfaceStyle) {
      MindYearHeatmapAnnualSurfaceStyle.monthCards => DecoratedBox(
        key: ValueKey('mind-year-heatmap-month-$month'),
        decoration: const BoxDecoration(
          color: FluviVisualTokens.surfaceMuted,
          borderRadius: FluviVisualTokens.smallRadius,
        ),
        child: _contentFor(heatmapContent),
      ),
      MindYearHeatmapAnnualSurfaceStyle.directCells => KeyedSubtree(
        key: ValueKey('mind-year-heatmap-month-direct-$month'),
        child: _contentFor(heatmapContent),
      ),
    };
    return SizedBox(
      width: width,
      height: heightFor(
        width: width,
        calendarRowCount: displayCalendarRowCount,
        footerRowCount: _footerRowCount,
        cellExtent: cellExtent,
      ),
      child: Semantics(
        readOnly: true,
        label:
            '${DashboardTimeLabelFormatter.monthName(month)} ${geometry.year}',
        child: surface,
      ),
    );
  }

  Widget _contentFor(Widget heatmapContent) {
    final progress = inspectionProgress;
    if (!isInspected || progress == null) return heatmapContent;
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final value = Curves.easeInOutCubic.transform(progress.value);
        final information = _MindYearHeatmapMonthInformation(
          key: ValueKey('mind-year-heatmap-month-info-$month'),
          month: month,
          year: geometry.year,
          monthlyAggregates: monthlyAggregates,
          scopedMonthlyAggregates: scopedMonthlyAggregates,
          inspectionScope: inspectionScope,
        );
        if (value >= 1) return information;
        return Stack(
          key: ValueKey('mind-year-heatmap-month-info-morph-$month'),
          fit: StackFit.expand,
          children: <Widget>[
            Opacity(
              opacity: 1 - value,
              child: ExcludeSemantics(child: heatmapContent),
            ),
            Opacity(
              opacity: value,
              child: ExcludeSemantics(child: information),
            ),
          ],
        );
      },
    );
  }
}

/// One colored annual day tile is a presentation-local clean-tap target. It
/// enters no horizontal/vertical drag path: Flutter rejects its tap when the
/// surrounding pager or annual scroll starts moving.
final class _MindYearDayCellTapTarget extends StatelessWidget {
  const _MindYearDayCellTapTarget({
    super.key,
    required this.geometry,
    required this.day,
    required this.extent,
    required this.onTap,
  });

  final MindYearHeatmapCalendarGeometry geometry;
  final MindYearHeatmapDay day;
  final double extent;
  final void Function(MindYearHeatmapDay day, Offset anchor) onTap;

  @override
  Widget build(BuildContext context) {
    final slot = geometry.slotIndexForDay(day.date.day);
    final row = slot ~/ MindYearHeatmapMonthPainter.columnCount;
    final column = slot % MindYearHeatmapMonthPainter.columnCount;
    return Positioned(
      left: column * (extent + MindYearHeatmapMonthPainter.gap),
      top: row * (extent + MindYearHeatmapMonthPainter.gap),
      width: extent,
      height: extent,
      child: Semantics(
        button: true,
        label:
            '${day.date.year}. ${DashboardTimeLabelFormatter.monthName(day.date.month)} ${day.date.day}. ${QueryMenuFormatters.money(day.total ?? 0)}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final box = context.findRenderObject() as RenderBox?;
            final anchor = box == null
                ? Offset.zero
                : box.localToGlobal(box.size.center(Offset.zero));
            onTap(day, anchor);
          },
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// A local MonthCard inspection endpoint. The values are already admitted
/// immutable read models; tapping this card performs no financial work.
final class _MindYearHeatmapMonthInformation extends StatelessWidget {
  const _MindYearHeatmapMonthInformation({
    super.key,
    required this.month,
    required this.year,
    this.monthlyAggregates,
    this.scopedMonthlyAggregates,
    required this.inspectionScope,
  });

  final int month;
  final int year;
  final MindYearHeatmapMonthlyAggregates? monthlyAggregates;
  final MindYearHeatmapScopedMonthlyAggregates? scopedMonthlyAggregates;
  final MindYearHeatmapInspectionScope inspectionScope;

  @override
  Widget build(BuildContext context) {
    final aggregates =
        monthlyAggregates ?? MindYearHeatmapMonthlyAggregates.empty(year: year);
    return Padding(
      padding: const EdgeInsets.all(MindYearHeatmapMonthCard._padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: MindYearHeatmapMonthCard._titleHeight,
            child: Text(
              DashboardTimeLabelFormatter.monthName(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _MindYearHeatmapInformationMetric(
                  label: 'Hó végi maradék',
                  amount: aggregates.netForMonth(month),
                  kind: _MindYearHeatmapFooterKind.net,
                ),
                _MindYearHeatmapInformationMetric(
                  label: 'Összbevétel',
                  amount: aggregates.incomeForMonth(month),
                  kind: _MindYearHeatmapFooterKind.income,
                ),
                _MindYearHeatmapInformationMetric(
                  label: 'Összkiadás',
                  amount: aggregates.expenseForMonth(month),
                  kind: _MindYearHeatmapFooterKind.expense,
                ),
                if (inspectionScope.hasFacet)
                  _MindYearHeatmapScopedInformationMetric(
                    facets: inspectionScope.facets,
                    amount: scopedMonthlyAggregates?.amountForMonth(month) ?? 0,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MindYearHeatmapScopedInformationMetric extends StatelessWidget {
  const _MindYearHeatmapScopedInformationMetric({
    required this.facets,
    required this.amount,
  });

  final List<MindYearHeatmapInspectionFacet> facets;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final amountColor = facets.length == 1
        ? CategoryVisualResolver.resolve(
            colorId: facets.single.colorId,
            iconId: facets.single.iconId,
          ).gradient.middleColor
        : FluviVisualTokens.textSecondary;
    final label = facets.map((facet) => facet.displayName).join(' · ');
    return Semantics(
      label: 'Aktív scope: $label, ${QueryMenuFormatters.money(amount)}',
      child: ExcludeSemantics(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    for (
                      var index = 0;
                      index < facets.length;
                      index += 1
                    ) ...<InlineSpan>[
                      if (index > 0)
                        const TextSpan(
                          text: ' · ',
                          style: TextStyle(
                            color: FluviVisualTokens.textSecondary,
                          ),
                        ),
                      TextSpan(
                        text: facets[index].displayName,
                        style: TextStyle(
                          color: CategoryVisualResolver.resolve(
                            colorId: facets[index].colorId,
                            iconId: facets[index].iconId,
                          ).gradient.middleColor,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
                key: const ValueKey<String>(
                  'mind-year-heatmap-inspection-scope-label',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                QueryMenuFormatters.money(amount),
                style: TextStyle(
                  color: amountColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MindYearHeatmapInformationMetric extends StatelessWidget {
  const _MindYearHeatmapInformationMetric({
    required this.label,
    required this.amount,
    required this.kind,
  });

  final String label;
  final int amount;
  final _MindYearHeatmapFooterKind kind;

  Color get _amountColor => switch (kind) {
    _MindYearHeatmapFooterKind.income => FluviVisualTokens.logBoxIncomeAmount,
    _MindYearHeatmapFooterKind.expense => FluviVisualTokens.logBoxExpenseAmount,
    _MindYearHeatmapFooterKind.net =>
      amount > 0
          ? FluviVisualTokens.logBoxIncomeAmount
          : amount < 0
          ? FluviVisualTokens.logBoxExpenseAmount
          : FluviVisualTokens.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 7,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          QueryMenuFormatters.money(amount),
          style: TextStyle(
            color: _amountColor,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

/// Paints one month's non-interactive local-day cells as a single dynamic
/// field. The existing frame listenable is the repaint authority, so an amount
/// preview does not rebuild per-day widgets, nested viewports, or semantics.
final class MindYearHeatmapMonthPainter extends CustomPainter {
  MindYearHeatmapMonthPainter({
    required this.month,
    required this.geometry,
    required this.frameListenable,
    this.paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
    this.scaleResolution = MindHeatmapScaleResolution.ten,
    this.cellExtent,
  }) : super(repaint: frameListenable);

  static const columnCount = 7;
  static const gap = 2.0;
  static const _cornerRadius = Radius.circular(2);

  final int month;
  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final double? cellExtent;

  @visibleForTesting
  Color colorForDate(LocalDate date) {
    final frame = frameListenable.value;
    if (frame == null) throw StateError('Missing heatmap frame.');
    final day = frame
        .month(month)
        .firstWhere(
          (candidate) => candidate.date == date,
          orElse: () => throw StateError('Missing heatmap day $date.'),
        );
    return colorFor(day);
  }

  @visibleForTesting
  Color colorFor(MindYearHeatmapDay day) =>
      MindYearHeatmapPaletteResolver.resolve(
        style: paletteStyle,
        day: day,
        scaleResolution: scaleResolution,
      ).background;

  @visibleForTesting
  int slotIndexForDate(LocalDate date) {
    if (date.year != geometry.year || date.month != geometry.month) {
      throw ArgumentError.value(date, 'date');
    }
    return geometry.slotIndexForDay(date.day);
  }

  @visibleForTesting
  int? dayAtSlot(int slot) => geometry.dayAtSlot(slot);

  @override
  void paint(Canvas canvas, Size size) {
    final days = frameListenable.value?.month(month);
    if (days == null || days.isEmpty || size.width <= 0) return;
    final resolvedCellExtent =
        cellExtent ?? (size.width - (columnCount - 1) * gap) / columnCount;
    if (resolvedCellExtent <= 0) return;
    final paint = Paint();
    for (final day in days) {
      final slotIndex = geometry.slotIndexForDay(day.date.day);
      final row = slotIndex ~/ columnCount;
      final column = slotIndex % columnCount;
      final offset = Offset(
        column * (resolvedCellExtent + gap),
        row * (resolvedCellExtent + gap),
      );
      paint.color = colorFor(day);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offset.dx,
            offset.dy,
            resolvedCellExtent,
            resolvedCellExtent,
          ),
          _cornerRadius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MindYearHeatmapMonthPainter oldDelegate) =>
      month != oldDelegate.month ||
      geometry.year != oldDelegate.geometry.year ||
      geometry.month != oldDelegate.geometry.month ||
      !identical(frameListenable, oldDelegate.frameListenable) ||
      paletteStyle != oldDelegate.paletteStyle ||
      scaleResolution != oldDelegate.scaleResolution ||
      cellExtent != oldDelegate.cellExtent;
}

enum _MindYearHeatmapFooterKind { net, income, expense }

/// A pure presentation of a bounded, already-admitted calendar-month total.
/// It has no frame listener so range preview repaint stays inside the cell
/// painter rather than rebuilding static footer content.
final class _MindYearHeatmapMonthFooter extends StatelessWidget {
  const _MindYearHeatmapMonthFooter({
    required this.label,
    required this.amount,
    required this.semanticKind,
  });

  final String label;
  final int amount;
  final _MindYearHeatmapFooterKind semanticKind;

  Color get _amountColor => switch (semanticKind) {
    _MindYearHeatmapFooterKind.income => FluviVisualTokens.logBoxIncomeAmount,
    _MindYearHeatmapFooterKind.expense => FluviVisualTokens.logBoxExpenseAmount,
    _MindYearHeatmapFooterKind.net =>
      amount > 0
          ? FluviVisualTokens.logBoxIncomeAmount
          : amount < 0
          ? FluviVisualTokens.logBoxExpenseAmount
          : FluviVisualTokens.textSecondary,
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MindYearHeatmapMonthCard._footerRowHeight,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          QueryMenuFormatters.money(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _amountColor,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
