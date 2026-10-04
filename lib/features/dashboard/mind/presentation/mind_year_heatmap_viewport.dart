import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/categories/catalog/category_visual_resolver.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
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
import '../domain/mind_monthly_overlay_series.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_year_heatmap_palette_resolver.dart';
import 'mind_heatmap_palette_scope.dart';
import 'mind_heatmap_day_number_overlay.dart';
import 'mind_aggregate_line_chart.dart';
import 'mind_monthly_overlay_bar_chart.dart';
import 'mind_sum_year_band_header.dart';
import 'mind_temporal_content_header.dart';

/// Immutable paint input for the Year comparison page. Full values intentionally
/// come from the unfiltered directional month authority; filtered values come
/// from the current range-preview frame days, so no second Query path exists.
@visibleForTesting
final class MindYearHeatmapPartialBarSeries {
  MindYearHeatmapPartialBarSeries._(this._shared);

  factory MindYearHeatmapPartialBarSeries.fromFrame(
    MindYearHeatmapFrame frame,
  ) {
    final isIncome = frame.identity.upstreamScopeKey.startsWith('income|');
    final fullAmounts = List<int>.generate(12, (index) {
      final month = index + 1;
      return isIncome
          ? frame.monthlyAggregates.incomeForMonth(month)
          : frame.monthlyAggregates.expenseForMonth(month);
    }, growable: false);
    final filteredAmounts = List<int>.generate(12, (index) {
      final month = index + 1;
      final filtered = frame
          .month(month)
          .fold<int>(0, (sum, day) => sum + (day.total ?? 0));
      return filtered;
    }, growable: false);
    return MindYearHeatmapPartialBarSeries._(
      MindMonthlyOverlaySeries.fromAmounts(
        fullAmounts: fullAmounts,
        filteredAmounts: filteredAmounts,
      ),
    );
  }

  final MindMonthlyOverlaySeries _shared;

  List<MindMonthlyOverlayValue> get values => _shared.values;
  MindMonthlyOverlayScale get scale => _shared.scale;
  MindMonthlyOverlaySeries get shared => _shared;
}

@visibleForTesting
typedef MindYearHeatmapPartialBarValue = MindMonthlyOverlayValue;

@visibleForTesting
typedef MindYearHeatmapPartialBarScale = MindMonthlyOverlayScale;

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
  final _heatmapCardKey = GlobalKey();
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
  late MindYearHeatmapGridLayout _directGridLayout;
  late final PageController _pageController;
  late final ScrollController _ownedAnnualScrollController;
  late final ScrollController _barPageScrollController;
  late final ScrollController _linePageScrollController;
  var _isMonthlyAmountOverlayOpen = false;

  @override
  void initState() {
    super.initState();
    _hasFrame = widget.frameListenable.value != null;
    _geometryYear = widget.frameListenable.value?.identity.year;
    _acceptStaticFrame(widget.frameListenable.value);
    _presentationSettings =
        widget.presentationSettings?.value ??
        const MindYearHeatmapPresentationSettings.defaults();
    _directGridLayout = _presentationSettings.yearGridLayout;
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
      _directGridLayout = _presentationSettings.yearGridLayout;
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
    setState(() {
      _presentationSettings = next;
      _directGridLayout = next.yearGridLayout;
      if (!_usesMonthlyAmountOverlay(next.yearMonthlyAmountPresentation)) {
        _isMonthlyAmountOverlayOpen = false;
      }
    });
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
    final geometryYearChanged = geometryYear != _geometryYear;
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
    setState(() {
      _hasFrame = hasFrame;
      _geometryYear = geometryYear;
      _acceptStaticFrame(frame);
      if (geometryYearChanged) _isMonthlyAmountOverlayOpen = false;
    });
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
        const horizontalPadding = 14.0;
        const rowGap = 4.0;
        const headerHeight = mindTemporalContentHeaderHeight;
        final columns = switch (_directGridLayout) {
          MindYearHeatmapGridLayout.fourByThree => 4,
          MindYearHeatmapGridLayout.threeByFour => 3,
          MindYearHeatmapGridLayout.twoBySix => 2,
        };
        final footerRowCount = switch (_directGridLayout) {
          MindYearHeatmapGridLayout.fourByThree => 0,
          // Monthly amounts now use the one shared mini-header or global veil.
          // No layout retains a second footer value or a hidden envelope.
          MindYearHeatmapGridLayout.threeByFour => 0,
          MindYearHeatmapGridLayout.twoBySix => 0,
        };
        final amountPresentation =
            _presentationSettings.yearMonthlyAmountPresentation;
        final showsInlineAmounts =
            amountPresentation == MindYearMonthlyAmountPresentation.inline;
        final usesMonthlyAmountOverlay = _usesMonthlyAmountOverlay(
          amountPresentation,
        );
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
        if (_directGridLayout == MindYearHeatmapGridLayout.fourByThree) {
          final fit = MindYearHeatmapFourColumnFit.resolve(
            viewportHeight: math.max(
              0,
              constraints.maxHeight - headerHeight - 25,
            ),
            cardWidth: monthCardWidth,
            geometries: geometries,
            footerRowCount: footerRowCount,
            viewportTopPadding: 5,
            viewportBottomPadding: 0,
            rowGap: rowGap,
            compactChrome: true,
            style: _presentationSettings.fourColumnCellStyle,
          );
          heatmapPage = KeyedSubtree(
            key: const ValueKey('mind-year-heatmap-scroll'),
            child: SingleChildScrollView(
              key: const ValueKey('mind-year-heatmap-fit-scroll'),
              controller: _annualScrollController,
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
              child: KeyedSubtree(
                key: const ValueKey('mind-year-heatmap-grid'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ...List<Widget>.generate(3, (annualRow) {
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
                                  child: MindYearHeatmapMonthGroup(
                                    month: month,
                                    width: monthCardWidth,
                                    cellExtent: fit.cellWidth,
                                    cellHeight: fit.cellHeight,
                                    geometry: geometries[month - 1],
                                    frameListenable: widget.frameListenable,
                                    compactChrome: true,
                                    paletteStyle:
                                        _presentationSettings.paletteStyle,
                                    scaleResolution:
                                        _presentationSettings.scaleResolution,
                                    showMonthlyClosing: false,
                                    showScopeAmount: false,
                                    showHeaderScopeAmount: showsInlineAmounts,
                                    showMonthCard: false,
                                    monthlyAggregates: _monthlyAggregates,
                                    scopedMonthlyAggregates:
                                        _scopedMonthlyAggregates,
                                    inspectionScope: _inspectionScope,
                                    activeDirectionIsIncome:
                                        _activeDirectionIsIncome,
                                    onTap: usesMonthlyAmountOverlay
                                        ? () => setState(
                                            () => _isMonthlyAmountOverlayOpen =
                                                true,
                                          )
                                        : null,
                                  ),
                                );
                              },
                              growable: false,
                            ),
                          ),
                        ),
                      );
                    }, growable: false),
                  ],
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
              // Six-row direct month groups reserve a stable geometry. Keep
              // the same bounded 12-month annual
              // field warm so a layout switch never exposes a sparse edge.
              cacheExtent: 500,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
              itemCount: (12 + columns - 1) ~/ columns,
              separatorBuilder: (_, _) => const SizedBox(height: rowGap),
              itemBuilder: (context, annualRow) {
                final offset = annualRow * columns;
                final rowEnd = math.min(offset + columns, geometries.length);
                final rowGeometries = geometries.sublist(offset, rowEnd);
                final rowHeight = MindYearHeatmapMonthGroup.heightFor(
                  width: monthCardWidth,
                  calendarRowCount:
                      MindYearHeatmapMonthGroup.displayCalendarRowCount,
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
                        child: MindYearHeatmapMonthGroup(
                          month: month,
                          width: monthCardWidth,
                          geometry: geometries[month - 1],
                          frameListenable: widget.frameListenable,
                          paletteStyle: _presentationSettings.paletteStyle,
                          scaleResolution:
                              _presentationSettings.scaleResolution,
                          showMonthlyClosing: false,
                          showScopeAmount: false,
                          showHeaderScopeAmount: showsInlineAmounts,
                          showMonthCard: true,
                          showDayNumbers:
                              _directGridLayout ==
                              MindYearHeatmapGridLayout.twoBySix,
                          monthCardBorderEnabled:
                              _presentationSettings.yearMonthCardBorderEnabled,
                          profitabilityTintEnabled: _presentationSettings
                              .yearMonthCardProfitabilityTintEnabled,
                          profitabilityTintOpacity: _presentationSettings
                              .yearMonthCardProfitabilityTintOpacity,
                          monthlyAggregates: _monthlyAggregates,
                          scopedMonthlyAggregates: _scopedMonthlyAggregates,
                          inspectionScope: _inspectionScope,
                          activeDirectionIsIncome: _activeDirectionIsIncome,
                          onTap: usesMonthlyAmountOverlay
                              ? () => setState(
                                  () => _isMonthlyAmountOverlayOpen = true,
                                )
                              : null,
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
                  key: _heatmapCardKey,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                          child: ValueListenableBuilder<MindYearHeatmapFrame?>(
                            valueListenable: widget.frameListenable,
                            builder: (context, frame, _) =>
                                MindTemporalContentHeader(
                                  title: 'Éves aktivitás',
                                  subtitle: '$year · 12 hónap',
                                  titleKey: const ValueKey<String>(
                                    'mind-year-direct-title',
                                  ),
                                  trailing: MindNoSpendDaysHeaderMetric(
                                    noSpendDayCount:
                                        frame?.noSpendDayCount ?? 0,
                                    keyPrefix: 'mind-year-no-spend-days',
                                  ),
                                ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              heatmapPage,
                              if (usesMonthlyAmountOverlay &&
                                  _isMonthlyAmountOverlayOpen)
                                _MindYearMonthlyAmountOverlay(
                                  frameListenable: widget.frameListenable,
                                  columns: columns,
                                  presentation: amountPresentation,
                                  onDismiss: () => setState(
                                    () => _isMonthlyAmountOverlayOpen = false,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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

  static bool _usesMonthlyAmountOverlay(
    MindYearMonthlyAmountPresentation presentation,
  ) =>
      presentation == MindYearMonthlyAmountPresentation.veil ||
      presentation == MindYearMonthlyAmountPresentation.whiteMotherCard;

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

/// A single annual information veil. It deliberately receives the same live
/// resident frame as the heatmap and contains no per-month popup state.
final class _MindYearMonthlyAmountOverlay extends StatelessWidget {
  const _MindYearMonthlyAmountOverlay({
    required this.frameListenable,
    required this.columns,
    required this.presentation,
    required this.onDismiss,
  });

  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final int columns;
  final MindYearMonthlyAmountPresentation presentation;
  final VoidCallback onDismiss;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<MindYearHeatmapFrame?>(
    valueListenable: frameListenable,
    builder: (context, frame, _) {
      final isWhiteMotherCard =
          presentation == MindYearMonthlyAmountPresentation.whiteMotherCard;
      final keyPrefix = isWhiteMotherCard
          ? 'mind-year-monthly-amount-white-mother-card'
          : 'mind-year-monthly-amount-veil';
      final foreground = isWhiteMotherCard
          ? FluviVisualTokens.textSecondary
          : Colors.white;
      return Semantics(
        label: 'Éves havi összegek',
        button: true,
        child: GestureDetector(
          key: ValueKey<String>(keyPrefix),
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isWhiteMotherCard ? Colors.white : const Color(0xB56B7280),
            ),
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const padding = EdgeInsets.fromLTRB(10, 5, 10, 4);
                  final rows = (12 + columns - 1) ~/ columns;
                  final usableWidth =
                      (constraints.maxWidth - padding.horizontal)
                          .clamp(0.0, double.infinity)
                          .toDouble();
                  final usableHeight =
                      (constraints.maxHeight - padding.vertical)
                          .clamp(0.0, double.infinity)
                          .toDouble();
                  // The veil is one annual field: solve its month cells from
                  // its actual body bounds, rather than letting a 2×6 grid
                  // become taller than the Year surface and clip months.
                  final cellWidth = usableWidth / columns;
                  final cellHeight = usableHeight / rows;
                  final childAspectRatio = cellHeight == 0
                      ? 1.0
                      : cellWidth / cellHeight;
                  return GridView.count(
                    key: ValueKey<String>('$keyPrefix-grid'),
                    crossAxisCount: columns,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: padding,
                    childAspectRatio: childAspectRatio,
                    children: List<Widget>.generate(12, (index) {
                      final month = index + 1;
                      final amount =
                          (frame?.month(month) ?? const <MindYearHeatmapDay>[])
                              .fold<int>(
                                0,
                                (sum, day) => sum + (day.total ?? 0),
                              );
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              DashboardTimeLabelFormatter.monthName(month),
                              key: ValueKey<String>('$keyPrefix-name-$month'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              QueryMenuFormatters.money(amount),
                              key: ValueKey<String>('$keyPrefix-total-$month'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }, growable: false),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
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
  Widget build(BuildContext context) {
    final dynamicScale = MindHeatmapPaletteScope.maybeOf(context);
    return ValueListenableBuilder<MindYearHeatmapFrame?>(
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
          dynamicScale: dynamicScale,
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
}

@visibleForTesting
final class MindYearHeatmapPartialBarPainter
    extends MindMonthlyOverlayBarPainter {
  MindYearHeatmapPartialBarPainter({
    required MindYearHeatmapPartialBarSeries series,
    required this.foreground,
  }) : yearSeries = series,
       super(
         series: series.shared,
         foregroundForValue: (_) => foreground,
         paintIdentity: foreground,
       );

  final MindYearHeatmapPartialBarSeries yearSeries;
  final Color foreground;
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

@visibleForTesting
final class MindYearHeatmapFourColumnFit {
  const MindYearHeatmapFourColumnFit._({
    required this.annualViewportHeight,
    required this.staticHeight,
    required this.cellWidth,
    required this.cellHeight,
    required this.squareConsumedHeight,
    required this.verticalSurplus,
    required this.extraHeightPerCell,
    required this.rowHeights,
    required this.resolvedContentHeight,
    required this.gridConsumedHeight,
    required this.freeHeight,
  });

  final double annualViewportHeight;
  final double staticHeight;
  final double cellWidth;
  final double cellHeight;
  final double squareConsumedHeight;
  final double verticalSurplus;
  final double extraHeightPerCell;
  final List<double> rowHeights;
  final double resolvedContentHeight;
  final double gridConsumedHeight;
  final double freeHeight;

  static MindYearHeatmapFourColumnFit resolve({
    required double viewportHeight,
    required double cardWidth,
    required List<MindYearHeatmapCalendarGeometry> geometries,
    required int footerRowCount,
    required double viewportTopPadding,
    required double viewportBottomPadding,
    required double rowGap,
    required bool compactChrome,
    MindYearFourColumnCellStyle style = MindYearFourColumnCellStyle.fillHeight,
  }) {
    const annualRows = 3;
    // The physical MonthCard envelope is deliberately independent of a
    // month's real calendar extent. The painter still receives each exact
    // geometry and leaves unused sixth-row slots empty.
    final calendarRows = List<int>.filled(
      annualRows,
      MindYearHeatmapMonthGroup.displayCalendarRowCount,
      growable: false,
    );
    final staticCardChrome = MindYearHeatmapMonthGroup.fixedChromeHeightFor(
      footerRowCount: footerRowCount,
      compactChrome: compactChrome,
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
    final cellWidth = MindYearHeatmapMonthGroup.cellExtentFor(cardWidth);
    final cellByHeight = viewportHeight.isFinite && totalCalendarRows > 0
        ? ((viewportHeight - staticHeight) / totalCalendarRows)
              .clamp(0.0, double.infinity)
              .toDouble()
        : cellWidth;
    // Fill-height preserves the accepted direct 4×3 repair. Square is a
    // deliberate alternative that leaves a calculated lower selector region.
    final cellHeight = style == MindYearFourColumnCellStyle.fillHeight
        ? cellByHeight
        : cellWidth;
    final squareConsumedHeight = staticHeight + totalCalendarRows * cellWidth;
    final verticalSurplus = math
        .max(0.0, viewportHeight - squareConsumedHeight)
        .toDouble();
    final extraHeightPerCell = totalCalendarRows == 0
        ? 0.0
        : verticalSurplus / totalCalendarRows;
    final rowHeights = calendarRows
        .map(
          (rows) => MindYearHeatmapMonthGroup.heightFor(
            width: cardWidth,
            cellExtent: cellWidth,
            cellHeight: cellHeight,
            calendarRowCount: rows,
            footerRowCount: footerRowCount,
            compactChrome: compactChrome,
          ),
        )
        .toList(growable: false);
    final resolvedContentHeight =
        viewportTopPadding +
        viewportBottomPadding +
        rowGap * (annualRows - 1) +
        rowHeights.fold<double>(0, (total, height) => total + height);
    final gridConsumedHeight = staticHeight + totalCalendarRows * cellHeight;
    final freeHeight = math.max(0.0, viewportHeight - gridConsumedHeight);
    return MindYearHeatmapFourColumnFit._(
      annualViewportHeight: viewportHeight,
      staticHeight: staticHeight,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      squareConsumedHeight: squareConsumedHeight,
      verticalSurplus: verticalSurplus,
      extraHeightPerCell: extraHeightPerCell,
      rowHeights: rowHeights,
      resolvedContentHeight: resolvedContentHeight,
      gridConsumedHeight: gridConsumedHeight,
      freeHeight: freeHeight,
    );
  }
}

/// Resolves only a card-based Year MonthCard surface paint. Monthly closing
/// semantics stay in [MindYearHeatmapMonthlyAggregates]; this function
/// intentionally does not feed the heatmap painter, text, border, shadow or
/// any value.
@visibleForTesting
Color mindYearMonthCardBackground({
  required int? monthlyNetMinor,
  required bool profitabilityTintEnabled,
  required double tintOpacity,
}) {
  const neutral = FluviVisualTokens.surface;
  if (!profitabilityTintEnabled ||
      monthlyNetMinor == null ||
      monthlyNetMinor == 0) {
    return neutral;
  }
  final tint = monthlyNetMinor > 0
      ? FluviVisualTokens.mindYearProfitabilityPositive
      : FluviVisualTokens.mindYearProfitabilityNegative;
  return Color.alphaBlend(
    tint.withValues(alpha: tintOpacity.clamp(0.0, 1.0).toDouble()),
    neutral,
  );
}

@Deprecated('Use mindYearMonthCardBackground.')
@visibleForTesting
Color mindYearThreeColumnMonthCardBackground({
  required int? monthlyNetMinor,
  required bool profitabilityTintEnabled,
  required double tintOpacity,
}) => mindYearMonthCardBackground(
  monthlyNetMinor: monthlyNetMinor,
  profitabilityTintEnabled: profitabilityTintEnabled,
  tintOpacity: tintOpacity,
);

/// A direct annual month group. Its title is static across amount-only
/// previews; only the bounded day-tile field listens to the live frame.
final class MindYearHeatmapMonthGroup extends StatelessWidget {
  const MindYearHeatmapMonthGroup({
    super.key,
    required this.month,
    required this.width,
    required this.geometry,
    required this.frameListenable,
    this.cellExtent,
    this.cellHeight,
    this.compactChrome = false,
    this.paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
    this.scaleResolution = MindHeatmapScaleResolution.ten,
    this.showMonthlyClosing = false,
    this.showScopeAmount = false,
    this.showHeaderScopeAmount = false,
    this.showMonthCard = false,
    this.showDayNumbers = false,
    this.monthCardBorderEnabled = true,
    this.profitabilityTintEnabled = false,
    this.profitabilityTintOpacity = .16,
    this.monthlyAggregates,
    this.scopedMonthlyAggregates,
    this.inspectionScope = const MindYearHeatmapInspectionScope(),
    this.activeDirectionIsIncome = false,
    this.isInspected = false,
    this.inspectionProgress,
    this.onTap,
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

  /// Width of a direct heatmap cell.  The legacy name is retained because
  /// card-based layouts intentionally remain square.
  final double? cellExtent;

  /// Optional independent vertical extent used only by direct 4×3.
  final double? cellHeight;
  final bool compactChrome;
  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final bool showMonthlyClosing;
  final bool showScopeAmount;

  /// The direct 4×3 variant can render current range metadata in the existing
  /// mini-header. This does not reserve a footer row or alter day geometry.
  final bool showHeaderScopeAmount;
  final bool showMonthCard;
  final bool showDayNumbers;
  final bool monthCardBorderEnabled;
  final bool profitabilityTintEnabled;
  final double profitabilityTintOpacity;
  final MindYearHeatmapMonthlyAggregates? monthlyAggregates;
  final MindYearHeatmapScopedMonthlyAggregates? scopedMonthlyAggregates;
  final MindYearHeatmapInspectionScope inspectionScope;
  final bool activeDirectionIsIncome;
  final bool isInspected;
  final Animation<double>? inspectionProgress;
  final VoidCallback? onTap;

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

  static double fixedChromeHeightFor({
    int footerRowCount = 0,
    bool compactChrome = false,
  }) =>
      _verticalPaddingFor(compactChrome) * 2 +
      _titleHeightFor(compactChrome) +
      _titleBottomGapFor(compactChrome) +
      (footerRowCount == 0
          ? 0
          : _footerTopGap + _footerRowHeight * footerRowCount);

  static double gridHeightFor({
    required double width,
    required int calendarRowCount,
    double? cellExtent,
    double? cellHeight,
  }) {
    final resolvedCellWidth = cellExtent ?? cellExtentFor(width);
    final resolvedCellHeight = cellHeight ?? resolvedCellWidth;
    return resolvedCellHeight * calendarRowCount +
        MindYearHeatmapMonthPainter.gap * (calendarRowCount - 1);
  }

  static double heightFor({
    required double width,
    required int calendarRowCount,
    int footerRowCount = 0,
    double? cellExtent,
    double? cellHeight,
    bool compactChrome = false,
  }) =>
      fixedChromeHeightFor(
        footerRowCount: footerRowCount,
        compactChrome: compactChrome,
      ) +
      gridHeightFor(
        width: width,
        calendarRowCount: calendarRowCount,
        cellExtent: cellExtent,
        cellHeight: cellHeight,
      );

  int get _footerRowCount =>
      (showMonthlyClosing ? 1 : 0) + (showScopeAmount ? 1 : 0);

  static double _verticalPaddingFor(bool compactChrome) =>
      compactChrome ? 2 : _padding;

  static double _titleHeightFor(bool compactChrome) =>
      compactChrome ? 10 : _titleHeight;

  static double _titleBottomGapFor(bool compactChrome) =>
      compactChrome ? 1 : _titleBottomGap;

  @override
  Widget build(BuildContext context) {
    final dynamicScale = MindHeatmapPaletteScope.maybeOf(context);
    final gridHeight = gridHeightFor(
      width: width,
      calendarRowCount: displayCalendarRowCount,
      cellExtent: cellExtent,
      cellHeight: cellHeight,
    );
    final verticalPadding = _verticalPaddingFor(compactChrome);
    final titleHeight = _titleHeightFor(compactChrome);
    final titleBottomGap = _titleBottomGapFor(compactChrome);
    final heatmapContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _padding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: titleHeight,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DashboardTimeLabelFormatter.monthName(month),
                        key: ValueKey<String>('mind-year-month-name-$month'),
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
                if (showHeaderScopeAmount) const SizedBox(width: 2),
                if (showHeaderScopeAmount)
                  Flexible(
                    child: ValueListenableBuilder<MindYearHeatmapFrame?>(
                      valueListenable: frameListenable,
                      builder: (context, frame, _) {
                        final amount =
                            (frame?.month(month) ??
                                    const <MindYearHeatmapDay>[])
                                .fold<int>(
                                  0,
                                  (sum, day) => sum + (day.total ?? 0),
                                );
                        return Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              formatMindCompactForints(
                                amount ~/ 100,
                                includeCurrencySuffix: false,
                              ),
                              key: ValueKey<String>(
                                'mind-year-month-scope-total-$month',
                              ),
                              maxLines: 1,
                              style: const TextStyle(
                                color: FluviVisualTokens.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: titleBottomGap),
          SizedBox(
            height: gridHeight,
            child: ValueListenableBuilder<MindYearHeatmapFrame?>(
              valueListenable: frameListenable,
              builder: (context, frame, _) {
                final days =
                    frame?.month(month) ?? const <MindYearHeatmapDay>[];
                final cellWidth = cellExtent ?? cellExtentFor(width);
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
                              dynamicScale: dynamicScale,
                              cellExtent: cellExtent,
                              cellHeight: cellHeight,
                            ),
                            isComplex: false,
                            willChange: true,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    if (showDayNumbers)
                      MindHeatmapDayNumberOverlay(
                        geometry: geometry,
                        cellExtent: cellWidth,
                        gap: MindYearHeatmapMonthPainter.gap,
                        keyPrefix: 'mind-year-heatmap-day-number',
                        dayNumbers: days
                            .map(
                              (day) => MindHeatmapDayNumber(
                                date: day.date,
                                foreground:
                                    MindYearHeatmapPaletteResolver.resolve(
                                      style: paletteStyle,
                                      day: day,
                                      scaleResolution: scaleResolution,
                                      dynamicScale: dynamicScale,
                                    ).foreground,
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_footerRowCount > 0) ...<Widget>[
            const SizedBox(height: _footerTopGap),
            if (showMonthlyClosing)
              _MindYearHeatmapMonthFooter(
                label: 'Zárás',
                amount: monthlyAggregates?.netForMonth(month) ?? 0,
                semanticKind: _MindYearHeatmapFooterKind.net,
              ),
            if (showScopeAmount)
              ValueListenableBuilder<MindYearHeatmapFrame?>(
                valueListenable: frameListenable,
                builder: (context, frame, _) => _MindYearHeatmapMonthFooter(
                  label: 'Scope',
                  amount: (frame?.month(month) ?? const <MindYearHeatmapDay>[])
                      .fold<int>(0, (sum, day) => sum + (day.total ?? 0)),
                  semanticKind: activeDirectionIsIncome
                      ? _MindYearHeatmapFooterKind.income
                      : _MindYearHeatmapFooterKind.expense,
                ),
              ),
          ],
        ],
      ),
    );
    final surface = showMonthCard
        ? DecoratedBox(
            key: ValueKey<String>('mind-year-month-card-surface-$month'),
            decoration: BoxDecoration(
              color: mindYearMonthCardBackground(
                monthlyNetMinor: monthlyAggregates?.netForMonth(month),
                profitabilityTintEnabled: profitabilityTintEnabled,
                tintOpacity: profitabilityTintOpacity,
              ),
              borderRadius: BorderRadius.circular(10),
              border: monthCardBorderEnabled
                  ? Border.all(color: FluviVisualTokens.border)
                  : null,
            ),
            child: heatmapContent,
          )
        : heatmapContent;
    return SizedBox(
      key: ValueKey<String>('mind-year-direct-month-$month'),
      width: width,
      height: heightFor(
        width: width,
        calendarRowCount: displayCalendarRowCount,
        footerRowCount: _footerRowCount,
        cellExtent: cellExtent,
        cellHeight: cellHeight,
        compactChrome: compactChrome,
      ),
      child: Semantics(
        readOnly: true,
        label:
            '${DashboardTimeLabelFormatter.monthName(month)} ${geometry.year}',
        child: onTap == null
            ? _contentFor(surface)
            : GestureDetector(
                key: ValueKey<String>('mind-year-heatmap-month-tap-$month'),
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: _contentFor(surface),
              ),
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
      padding: const EdgeInsets.all(MindYearHeatmapMonthGroup._padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: MindYearHeatmapMonthGroup._titleHeight,
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
            profile: CategoryAvatarColorProfileScope.profileOf(context),
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
                            profile: CategoryAvatarColorProfileScope.profileOf(
                              context,
                            ),
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
    this.dynamicScale,
    this.cellExtent,
    this.cellHeight,
  }) : super(repaint: frameListenable);

  static const columnCount = 7;
  static const gap = 2.0;
  static const _cornerRadius = Radius.circular(2);

  final int month;
  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;
  final double? cellExtent;
  final double? cellHeight;

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
        dynamicScale: dynamicScale,
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

  @visibleForTesting
  Rect cellRectForSlot(int slot, Size size) {
    final cellWidth =
        cellExtent ?? (size.width - (columnCount - 1) * gap) / columnCount;
    final resolvedCellHeight = cellHeight ?? cellWidth;
    final row = slot ~/ columnCount;
    final column = slot % columnCount;
    return Rect.fromLTWH(
      column * (cellWidth + gap),
      row * (resolvedCellHeight + gap),
      cellWidth,
      resolvedCellHeight,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final days = frameListenable.value?.month(month);
    if (days == null || days.isEmpty || size.width <= 0) return;
    final resolvedCellWidth =
        cellExtent ?? (size.width - (columnCount - 1) * gap) / columnCount;
    final resolvedCellHeight = cellHeight ?? resolvedCellWidth;
    if (resolvedCellWidth <= 0 || resolvedCellHeight <= 0) return;
    final paint = Paint();
    for (final day in days) {
      final slotIndex = geometry.slotIndexForDay(day.date.day);
      paint.color = colorFor(day);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          cellRectForSlot(slotIndex, size),
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
      dynamicScale != oldDelegate.dynamicScale ||
      cellExtent != oldDelegate.cellExtent ||
      cellHeight != oldDelegate.cellHeight;
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
    height: MindYearHeatmapMonthGroup._footerRowHeight,
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
