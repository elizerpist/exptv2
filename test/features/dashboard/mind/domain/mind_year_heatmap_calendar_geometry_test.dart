import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_calendar_geometry.dart';

void main() {
  group('MindYearHeatmapCalendarGeometry', () {
    test(
      'RED MYHR-05: maps Monday, Wednesday and Sunday starts to Monday-first slots',
      () {
        final monday = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2021,
          month: 2,
        );
        final wednesday = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: 1,
        );
        final sunday = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: 6,
        );

        expect(monday.leadingSlotCount, 0);
        expect(monday.slotIndexForDay(1), 0);
        expect(wednesday.leadingSlotCount, 2);
        expect(wednesday.slotIndexForDay(1), 2);
        expect(wednesday.columnForDay(1), 2);
        expect(sunday.leadingSlotCount, 6);
        expect(sunday.slotIndexForDay(1), 6);
        expect(sunday.columnForDay(1), 6);
        expect(monday.weekdayColumnCount, 7);
      },
    );

    test(
      'RED MYHR-05: 2025 regression months retain their real leading space',
      () {
        final expectedLeadingSlots = <int, int>{
          1: 2,
          2: 5,
          3: 5,
          4: 1,
          5: 3,
          6: 6,
        };

        for (final entry in expectedLeadingSlots.entries) {
          final geometry = MindYearHeatmapCalendarGeometry.forMonth(
            year: 2025,
            month: entry.key,
          );
          expect(
            geometry.leadingSlotCount,
            entry.value,
            reason: 'month=${entry.key}',
          );
          expect(
            geometry.slotIndexForDay(1),
            entry.value,
            reason: 'month=${entry.key}',
          );
        }
      },
    );

    test(
      'RED MYHR-05: month lengths, final-day slots and four/five/six rows are exact',
      () {
        final fourRows = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2021,
          month: 2,
        );
        final february28 = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: 2,
        );
        final leapFebruary = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2024,
          month: 2,
        );
        final thirtyDayMonth = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: 4,
        );
        final thirtyOneDayMonth = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: 1,
        );
        final sixRows = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: 3,
        );

        expect(fourRows.dayCount, 28);
        expect(fourRows.rowCount, 4);
        expect(february28.dayCount, 28);
        expect(february28.slotIndexForDay(28), 32);
        expect(february28.rowForDay(28), 4);
        expect(leapFebruary.dayCount, 29);
        expect(leapFebruary.slotIndexForDay(29), 31);
        expect(thirtyDayMonth.dayCount, 30);
        expect(thirtyDayMonth.slotIndexForDay(30), 30);
        expect(thirtyOneDayMonth.dayCount, 31);
        expect(thirtyOneDayMonth.slotIndexForDay(31), 32);
        expect(sixRows.rowCount, 6);
        expect(sixRows.trailingSlotCount, 6);
      },
    );

    test(
      'RED MYHR-05: non-existent leading and trailing slots have no real day',
      () {
        final geometry = MindYearHeatmapCalendarGeometry.forMonth(
          year: 2025,
          month: 1,
        );

        expect(geometry.dayAtSlot(0), isNull);
        expect(geometry.dayAtSlot(1), isNull);
        expect(geometry.dayAtSlot(2), 1);
        expect(geometry.dayAtSlot(32), 31);
        expect(geometry.dayAtSlot(33), isNull);
        expect(geometry.dayAtSlot(geometry.slotCount - 1), isNull);
      },
    );
  });
}
