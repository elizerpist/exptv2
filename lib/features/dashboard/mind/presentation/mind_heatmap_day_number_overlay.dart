import 'package:flutter/material.dart';

import '../../time_navigation/domain/local_date.dart';
import '../domain/mind_year_heatmap_calendar_geometry.dart';

/// One static date label laid over an already-painted heatmap day tile.
/// Keeping this outside the painter lets Month and card-based Year layouts use
/// identical top-left typography without changing the tile paint authority.
@immutable
final class MindHeatmapDayNumber {
  const MindHeatmapDayNumber({required this.date, required this.foreground});

  final LocalDate date;
  final Color foreground;
}

/// Reusable top-left day-number treatment used by the Month heatmap and the
/// 2x6 Year MonthCards. It is intentionally ignored by hit testing.
final class MindHeatmapDayNumberOverlay extends StatelessWidget {
  const MindHeatmapDayNumberOverlay({
    super.key,
    required this.geometry,
    required this.dayNumbers,
    required this.cellExtent,
    required this.gap,
    required this.keyPrefix,
  });

  final MindYearHeatmapCalendarGeometry geometry;
  final List<MindHeatmapDayNumber> dayNumbers;
  final double cellExtent;
  final double gap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[for (final day in dayNumbers) _positionedDayNumber(day)],
  );

  Widget _positionedDayNumber(MindHeatmapDayNumber day) {
    final slot = geometry.slotIndexForDay(day.date.day);
    final row = slot ~/ 7;
    final column = slot % 7;
    return Positioned(
      left: column * (cellExtent + gap),
      top: row * (cellExtent + gap),
      width: cellExtent,
      height: cellExtent,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              '${day.date.day}',
              key: ValueKey<String>(
                '$keyPrefix-${day.date.year}-${day.date.month}-${day.date.day}',
              ),
              style: TextStyle(
                color: day.foreground,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
