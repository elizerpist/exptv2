import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_scope_boundaries.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('YearMonth rolls across year boundaries and clamps leap days', () {
    const december = YearMonth(year: 2026, month: 12);
    expect(december.next(), const YearMonth(year: 2027, month: 1));
    expect(december.previous(), const YearMonth(year: 2026, month: 11));
    expect(
      const YearMonth(year: 2024, month: 2).daysInMonth,
      29,
    );
    expect(
      const YearMonth(year: 2024, month: 2).clampDay(31),
      const LocalDate(year: 2024, month: 2, day: 29),
    );
  });

  test('scope values are typed, immutable and canonically equal', () {
    const may = YearMonth(year: 2026, month: 5);
    expect(const AllTimeScope(), const AllTimeScope());
    expect(const YearScope(2026), const YearScope(2026));
    expect(const MonthScope(may), const MonthScope(may));
    expect(
      const DayScope(LocalDate(year: 2026, month: 5, day: 14)),
      const DayScope(LocalDate(year: 2026, month: 5, day: 14)),
    );
    expect(const MonthScope(may).canonicalKey, 'month:2026-05');
    expect(
      const DayScope(LocalDate(year: 2026, month: 5, day: 14)).canonicalKey,
      'day:2026-05-14',
    );
  });

  test('time scope boundaries are half-open local dates', () {
    expect(
      const YearScope(2026).boundaries,
      const TimeScopeBoundaries(
        startInclusive: LocalDate(year: 2026, month: 1, day: 1),
        endExclusive: LocalDate(year: 2027, month: 1, day: 1),
      ),
    );
    expect(
      const MonthScope(YearMonth(year: 2026, month: 5)).boundaries,
      const TimeScopeBoundaries(
        startInclusive: LocalDate(year: 2026, month: 5, day: 1),
        endExclusive: LocalDate(year: 2026, month: 6, day: 1),
      ),
    );
    expect(
      const DayScope(LocalDate(year: 2026, month: 5, day: 14)).boundaries,
      const TimeScopeBoundaries(
        startInclusive: LocalDate(year: 2026, month: 5, day: 14),
        endExclusive: LocalDate(year: 2026, month: 5, day: 15),
      ),
    );
  });

  test('time plane is finite and ordered from broad to fine', () {
    expect(TimePlane.values, const [TimePlane.sum, TimePlane.year, TimePlane.month]);
    expect(TimePlane.sum.isBroaderThan(TimePlane.year), isTrue);
    expect(TimePlane.month.isBroaderThan(TimePlane.year), isFalse);
  });
}
