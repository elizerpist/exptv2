import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_key_digest.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../../time_navigation/domain/local_date.dart';
import '../domain/mind_year_heatmap_calendar_geometry.dart';
import '../domain/mind_year_heatmap_projection.dart';

/// The one scroll owner for the Mind annual MonthCard region.
///
/// The parent surface decides Year visibility. This viewport owns neither a
/// query nor a slider: it observes one already-published annual read model.
final class MindYearHeatmapViewport extends StatefulWidget {
  const MindYearHeatmapViewport({
    super.key,
    required this.frameListenable,
    this.scrollController,
  });

  final ValueListenable<MindYearHeatmapFrame?> frameListenable;
  final ScrollController? scrollController;

  @override
  State<MindYearHeatmapViewport> createState() =>
      _MindYearHeatmapViewportState();
}

final class _MindYearHeatmapViewportState
    extends State<MindYearHeatmapViewport> {
  late bool _hasFrame;
  int? _geometryYear;
  MindYearHeatmapIdentity? _lastVisibleIdentity;
  int? _lastLoggedGeometryYear;

  @override
  void initState() {
    super.initState();
    _hasFrame = widget.frameListenable.value != null;
    _geometryYear = widget.frameListenable.value?.identity.year;
    widget.frameListenable.addListener(_onFrameChanged);
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
      widget.frameListenable.addListener(_onFrameChanged);
    }
  }

  @override
  void dispose() {
    widget.frameListenable.removeListener(_onFrameChanged);
    super.dispose();
  }

  void _onFrameChanged() {
    final frame = widget.frameListenable.value;
    if (frame != null) _scheduleVisiblePaintDiagnostics(frame);
    final hasFrame = frame != null;
    final geometryYear = frame?.identity.year;
    if ((hasFrame == _hasFrame && geometryYear == _geometryYear) || !mounted) {
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
    });
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
        final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
            .clamp(0.0, double.infinity)
            .toDouble();
        final monthCardWidth = ((contentWidth - rowGap * 2) / 3)
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
        return KeyedSubtree(
          key: const ValueKey('mind-year-heatmap-scroll'),
          child: ListView.separated(
            key: const ValueKey('mind-year-heatmap-grid'),
            controller: widget.scrollController,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: rowGap),
            itemBuilder: (context, annualRow) {
              final offset = annualRow * 3;
              final rowGeometries = geometries.sublist(offset, offset + 3);
              final maximumCalendarRows = rowGeometries.fold<int>(
                0,
                (maximum, geometry) =>
                    geometry.rowCount > maximum ? geometry.rowCount : maximum,
              );
              final rowHeight = MindYearHeatmapMonthCard.heightFor(
                width: monthCardWidth,
                calendarRowCount: maximumCalendarRows,
              );
              return SizedBox(
                key: ValueKey('mind-year-heatmap-annual-row-$annualRow'),
                height: rowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.generate(3, (column) {
                    final month = offset + column + 1;
                    return Padding(
                      padding: EdgeInsets.only(right: column == 2 ? 0 : rowGap),
                      child: MindYearHeatmapMonthCard(
                        month: month,
                        width: monthCardWidth,
                        geometry: geometries[month - 1],
                        frameListenable: widget.frameListenable,
                      ),
                    );
                  }, growable: false),
                ),
              );
            },
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

/// Stable MonthCard shell. Its title is static across amount-only previews;
/// only the bounded day-tile field listens to the live frame.
final class MindYearHeatmapMonthCard extends StatelessWidget {
  const MindYearHeatmapMonthCard({
    super.key,
    required this.month,
    required this.width,
    required this.geometry,
    required this.frameListenable,
  });

  static const _padding = 6.0;
  static const _titleHeight = 12.0;
  static const _titleBottomGap = 4.0;

  final int month;
  final double width;
  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;

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

  static double gridHeightFor({
    required double width,
    required int calendarRowCount,
  }) {
    final cellExtent = cellExtentFor(width);
    return cellExtent * calendarRowCount +
        MindYearHeatmapMonthPainter.gap * (calendarRowCount - 1);
  }

  static double heightFor({
    required double width,
    required int calendarRowCount,
  }) =>
      _padding * 2 +
      _titleHeight +
      _titleBottomGap +
      gridHeightFor(width: width, calendarRowCount: calendarRowCount);

  @override
  Widget build(BuildContext context) {
    final gridHeight = gridHeightFor(
      width: width,
      calendarRowCount: geometry.rowCount,
    );
    return SizedBox(
      width: width,
      height: heightFor(width: width, calendarRowCount: geometry.rowCount),
      child: DecoratedBox(
        key: ValueKey('mind-year-heatmap-month-$month'),
        decoration: const BoxDecoration(
          color: FluviVisualTokens.surfaceMuted,
          borderRadius: FluviVisualTokens.smallRadius,
        ),
        child: Padding(
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
                        ),
                        isComplex: false,
                        willChange: true,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
  }) : super(repaint: frameListenable);

  static const columnCount = 7;
  static const gap = 2.0;
  static const _cornerRadius = Radius.circular(2);

  final int month;
  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindYearHeatmapFrame?> frameListenable;

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
  Color colorFor(MindYearHeatmapDay day) => switch (day.paletteIntensity) {
    MindYearHeatmapPaletteIntensity.empty => FluviVisualTokens.mindHeatmapEmpty,
    MindYearHeatmapPaletteIntensity.minimum =>
      FluviVisualTokens.mindHeatmapMinimum,
    MindYearHeatmapPaletteIntensity.interpolated =>
      FluviVisualTokens.mindHeatmapInterpolated(day.intensity),
    MindYearHeatmapPaletteIntensity.maximum =>
      FluviVisualTokens.mindHeatmapMaximum,
    MindYearHeatmapPaletteIntensity.equalRange =>
      FluviVisualTokens.mindHeatmapEqualRange,
  };

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
    final cellExtent = (size.width - (columnCount - 1) * gap) / columnCount;
    if (cellExtent <= 0) return;
    final paint = Paint();
    for (final day in days) {
      final slotIndex = geometry.slotIndexForDay(day.date.day);
      final row = slotIndex ~/ columnCount;
      final column = slotIndex % columnCount;
      final offset = Offset(
        column * (cellExtent + gap),
        row * (cellExtent + gap),
      );
      paint.color = colorFor(day);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx, offset.dy, cellExtent, cellExtent),
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
      !identical(frameListenable, oldDelegate.frameListenable);
}
