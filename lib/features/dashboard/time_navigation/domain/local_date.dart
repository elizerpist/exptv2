class LocalDate {
  const LocalDate({
    required this.year,
    required this.month,
    required this.day,
  }) : assert(year >= 1 && year <= 9999),
       assert(month >= 1 && month <= 12),
       assert(day >= 1 && day <= 31);

  final int year;
  final int month;
  final int day;

  LocalDate nextDay() {
    final current = DateTime(year, month, day);
    final next = current.add(const Duration(days: 1));
    return LocalDate(year: next.year, month: next.month, day: next.day);
  }

  String get isoString =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => isoString;
}
