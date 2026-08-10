import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_availability.dart';

void main() {
  test('all-time availability keeps the rail domain unrestricted', () {
    const availability = DashboardTemporalAvailability.unrestricted();

    expect(availability.isRestrictive, isFalse);
    expect(availability.allowsYear(2025), isTrue);
    expect(availability.monthsForYear(2025), isNull);
  });

  test('a restricted time filter omits excluded years and months', () {
    final availability = DashboardTemporalAvailability.fromTemporalFilter(
      QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.year(2024),
        QueryPeriodSelection.month(2026, 2),
        QueryPeriodSelection.month(2026, 8),
      }),
    );

    expect(availability.isRestrictive, isTrue);
    expect(availability.allowedYears, orderedEquals(<int>[2024, 2026]));
    expect(availability.allowsYear(2025), isFalse);
    expect(
      availability.monthsForYear(2024),
      orderedEquals(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
    );
    expect(availability.monthsForYear(2026), orderedEquals(<int>[2, 8]));
    expect(availability.allowsMonth(2026, 4), isFalse);
  });

  test('broader OR time selections do not accidentally restrict day rails', () {
    final availability = DashboardTemporalAvailability.fromTemporalFilter(
      QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.year(2026),
        QueryPeriodSelection.day(2026, 2, 3),
      }),
    );

    expect(availability.daysForMonth(2026, 2), isNull);
  });
}
