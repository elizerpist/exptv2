import 'local_date.dart';
import 'time_scope_boundaries.dart';
import 'year_month.dart';

sealed class LedgerTimeScope {
  const LedgerTimeScope();

  String get canonicalKey;

  TimeScopeBoundaries? get boundaries;
}

final class AllTimeScope extends LedgerTimeScope {
  const AllTimeScope();

  @override
  String get canonicalKey => 'all';

  @override
  TimeScopeBoundaries? get boundaries => null;

  @override
  bool operator ==(Object other) => other is AllTimeScope;

  @override
  int get hashCode => runtimeType.hashCode;
}

final class YearScope extends LedgerTimeScope {
  const YearScope(this.year) : assert(year >= 1 && year <= 9999);

  final int year;

  @override
  String get canonicalKey => 'year:${year.toString().padLeft(4, '0')}';

  @override
  TimeScopeBoundaries get boundaries => TimeScopeBoundaries(
    startInclusive: LocalDate(year: year, month: 1, day: 1),
    endExclusive: LocalDate(year: year + 1, month: 1, day: 1),
  );

  @override
  bool operator ==(Object other) => other is YearScope && other.year == year;

  @override
  int get hashCode => Object.hash(runtimeType, year);
}

final class MonthScope extends LedgerTimeScope {
  const MonthScope(this.value);

  final YearMonth value;

  @override
  String get canonicalKey => 'month:${value.isoString}';

  @override
  TimeScopeBoundaries get boundaries => TimeScopeBoundaries(
    startInclusive: LocalDate(year: value.year, month: value.month, day: 1),
    endExclusive: () {
      final next = value.next();
      return LocalDate(year: next.year, month: next.month, day: 1);
    }(),
  );

  @override
  bool operator ==(Object other) =>
      other is MonthScope && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class DayScope extends LedgerTimeScope {
  const DayScope(this.date);

  final LocalDate date;

  @override
  String get canonicalKey => 'day:${date.isoString}';

  @override
  TimeScopeBoundaries get boundaries => TimeScopeBoundaries(
    startInclusive: date,
    endExclusive: date.nextDay(),
  );

  @override
  bool operator ==(Object other) => other is DayScope && other.date == date;

  @override
  int get hashCode => Object.hash(runtimeType, date);
}
