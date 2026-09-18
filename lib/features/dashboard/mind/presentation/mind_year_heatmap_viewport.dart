import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_key_digest.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import '../../presentation/dashboard_vertical_scroll_boundary_handoff.dart';
import '../domain/mind_year_heatmap_calendar_geometry.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_year_heatmap_palette_resolver.dart';

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
  var _activeDirectionIsIncome = false;
  late MindYearHeatmapPresentationSettings _presentationSettings;
  MindYearHeatmapIdentity? _lastVisibleIdentity;
  int? _lastLoggedGeometryYear;

  @override
  void initState() {
    super.initState();
    _hasFrame = widget.frameListenable.value != null;
    _geometryYear = widget.frameListenable.value?.identity.year;
    _acceptStaticFrame(widget.frameListenable.value);
    _presentationSettings =
        widget.presentationSettings?.value ??
        const MindYearHeatmapPresentationSettings.defaults();
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
      _hasFrame = widget.frameListenable.value != null;
      _geometryYear = widget.frameListenable.value?.identity.year;
      _acceptStaticFrame(widget.frameListenable.value);
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
    widget.frameListenable.removeListener(_onFrameChanged);
    widget.presentationSettings?.removeListener(_onPresentationSettingsChanged);
    super.dispose();
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
      final controller = widget.scrollController;
      if (controller == null || !controller.hasClients) return;
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
    setState(() {
      _hasFrame = hasFrame;
      _geometryYear = geometryYear;
      _acceptStaticFrame(frame);
    });
  }

  void _acceptStaticFrame(MindYearHeatmapFrame? frame) {
    _staticFrameIdentity = frame?.identity;
    _monthlyAggregates = frame?.monthlyAggregates;
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
          return KeyedSubtree(
            key: const ValueKey('mind-year-heatmap-scroll'),
            child: DashboardVerticalScrollBoundaryHandoff(
              upperVerticalGestures: widget.upperVerticalGestures,
              handoffOnDirectVerticalDrag: true,
              child: SingleChildScrollView(
                key: const ValueKey('mind-year-heatmap-fit-scroll'),
                controller: widget.scrollController,
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
                                    surfaceStyle: _presentationSettings
                                        .annualSurfaceStyle,
                                    showMonthlyNetClose: _presentationSettings
                                        .showMonthlyNetClose,
                                    showMonthlyDirectionTotal:
                                        _presentationSettings
                                            .showMonthlyDirectionTotal,
                                    monthlyAggregates: _monthlyAggregates,
                                    activeDirectionIsIncome:
                                        _activeDirectionIsIncome,
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
            ),
          );
        }
        return KeyedSubtree(
          key: const ValueKey('mind-year-heatmap-scroll'),
          child: DashboardVerticalScrollBoundaryHandoff(
            upperVerticalGestures: widget.upperVerticalGestures,
            child: ListView.separated(
              key: const ValueKey('mind-year-heatmap-grid'),
              controller: widget.scrollController,
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
                          surfaceStyle:
                              _presentationSettings.annualSurfaceStyle,
                          showMonthlyNetClose:
                              _presentationSettings.showMonthlyNetClose,
                          showMonthlyDirectionTotal:
                              _presentationSettings.showMonthlyDirectionTotal,
                          monthlyAggregates: _monthlyAggregates,
                          activeDirectionIsIncome: _activeDirectionIsIncome,
                        ),
                      );
                    }, growable: false),
                  ),
                );
              },
            ),
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

/// A constrained 4 × 3 annual arrangement. It does not change the heatmap
/// data frame: it solves a shared square day-cell extent from the actual
/// viewport height and the four-card row widths, then projects the existing
/// MonthCards into three non-scrolling annual rows.
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
    this.surfaceStyle = MindYearHeatmapAnnualSurfaceStyle.monthCards,
    this.showMonthlyNetClose = false,
    this.showMonthlyDirectionTotal = false,
    this.monthlyAggregates,
    this.activeDirectionIsIncome = false,
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
  final MindYearHeatmapAnnualSurfaceStyle surfaceStyle;
  final bool showMonthlyNetClose;
  final bool showMonthlyDirectionTotal;
  final MindYearHeatmapMonthlyAggregates? monthlyAggregates;
  final bool activeDirectionIsIncome;

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
    final content = Padding(
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
            child: RepaintBoundary(
              child: Semantics(
                label:
                    'Mind heatmap ${DashboardTimeLabelFormatter.monthName(month)}',
                readOnly: true,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: ValueKey('mind-year-heatmap-month-cells-$month'),
                    painter: MindYearHeatmapMonthPainter(
                      month: month,
                      geometry: geometry,
                      frameListenable: frameListenable,
                      paletteStyle: paletteStyle,
                      cellExtent: cellExtent,
                    ),
                    isComplex: false,
                    willChange: true,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
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
    return SizedBox(
      width: width,
      height: heightFor(
        width: width,
        calendarRowCount: displayCalendarRowCount,
        footerRowCount: _footerRowCount,
        cellExtent: cellExtent,
      ),
      child: switch (surfaceStyle) {
        MindYearHeatmapAnnualSurfaceStyle.monthCards => DecoratedBox(
          key: ValueKey('mind-year-heatmap-month-$month'),
          decoration: const BoxDecoration(
            color: FluviVisualTokens.surfaceMuted,
            borderRadius: FluviVisualTokens.smallRadius,
          ),
          child: content,
        ),
        MindYearHeatmapAnnualSurfaceStyle.directCells => KeyedSubtree(
          key: ValueKey('mind-year-heatmap-month-direct-$month'),
          child: content,
        ),
      },
    );
  }
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
    this.cellExtent,
  }) : super(repaint: frameListenable);

  static const columnCount = 7;
  static const gap = 2.0;
  static const _cornerRadius = Radius.circular(2);

  final int month;
  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
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
