import 'local_date.dart';

class YearMonth {
  const YearMonth({required this.year, required this.month})
    : assert(year >= 1 && year <= 9999),
      assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  int get daysInMonth => DateTime(year, month + 1, 0).day;

  YearMonth next() {
    if (month == 12) return YearMonth(year: year + 1, month: 1);
    return YearMonth(year: year, month: month + 1);
  }

  YearMonth previous() {
    if (month == 1) return YearMonth(year: year - 1, month: 12);
    return YearMonth(year: year, month: month - 1);
  }

  LocalDate clampDay(int day) {
    final clamped = day.clamp(1, daysInMonth);
    return LocalDate(year: year, month: month, day: clamped);
  }

  String get isoString =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => isoString;
}
