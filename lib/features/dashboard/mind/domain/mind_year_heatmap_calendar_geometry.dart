import 'package:flutter/foundation.dart';

/// Immutable Monday-first slot geometry for one local-calendar month.
///
/// This owns calendar placement only.  It has no ledger/filter/paint state, so
/// a live amount-range preview can reuse it without recomputing date layout.
@immutable
final class MindYearHeatmapCalendarGeometry {
  const MindYearHeatmapCalendarGeometry._({
    required this.year,
    required this.month,
    required this.dayCount,
    required this.leadingSlotCount,
    required this.rowCount,
  });

  factory MindYearHeatmapCalendarGeometry.forMonth({
    required int year,
    required int month,
  }) {
    if (year < 1 || year > 9999) {
      throw RangeError.range(year, 1, 9999, 'year');
    }
    if (month < DateTime.january || month > DateTime.december) {
      throw RangeError.range(
        month,
        DateTime.january,
        DateTime.december,
        'month',
      );
    }
    final firstLocalDay = DateTime(year, month, 1);
    final leadingSlotCount = firstLocalDay.weekday - DateTime.monday;
    final dayCount = DateTime(year, month + 1, 0).day;
    final rowCount =
        (leadingSlotCount + dayCount + _weekdayColumnCount - 1) ~/
        _weekdayColumnCount;
    return MindYearHeatmapCalendarGeometry._(
      year: year,
      month: month,
      dayCount: dayCount,
      leadingSlotCount: leadingSlotCount,
      rowCount: rowCount,
    );
  }

  static const _weekdayColumnCount = 7;

  final int year;
  final int month;
  final int dayCount;

  /// Empty space before day one.  Zero maps to Monday and six maps to Sunday.
  final int leadingSlotCount;
  final int rowCount;

  int get weekdayColumnCount => _weekdayColumnCount;
  int get slotCount => rowCount * weekdayColumnCount;
  int get trailingSlotCount => slotCount - leadingSlotCount - dayCount;

  int slotIndexForDay(int day) {
    _checkDay(day);
    return leadingSlotCount + day - 1;
  }

  int rowForDay(int day) => slotIndexForDay(day) ~/ weekdayColumnCount;

  int columnForDay(int day) => slotIndexForDay(day) % weekdayColumnCount;

  /// Returns null for leading/trailing non-calendar space.  Those slots must
  /// have neither a visual day square nor a semantic/hit-test day node.
  int? dayAtSlot(int slot) {
    if (slot < 0 || slot >= slotCount) {
      throw RangeError.range(slot, 0, slotCount - 1, 'slot');
    }
    final day = slot - leadingSlotCount + 1;
    return day < 1 || day > dayCount ? null : day;
  }

  void _checkDay(int day) {
    if (day < 1 || day > dayCount) {
      throw RangeError.range(day, 1, dayCount, 'day');
    }
  }
}
