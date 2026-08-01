import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/time_rail_data_source_factory.dart';

void main() {
  test('SUM data source generates years in both directions', () {
    final source = TimeRailDataSourceFactory.forPlane(
      plane: TimePlane.sum,
      yearAnchor: 2026,
      monthCursor: const YearMonth(year: 2026, month: 5),
    );

    expect(source.finiteLength, isNull);
    expect(source.itemAtLogicalIndex(-1), 2025);
    expect(source.itemAtLogicalIndex(0), 2026);
    expect(source.itemAtLogicalIndex(1), 2027);
  });

  test('YEAR data source cycles months with positive modulo', () {
    final source = TimeRailDataSourceFactory.forPlane(
      plane: TimePlane.year,
      yearAnchor: 2026,
      monthCursor: const YearMonth(year: 2026, month: 5),
    );

    expect(source.finiteLength, 12);
    expect(source.itemAtLogicalIndex(-1), 12);
    expect(source.itemAtLogicalIndex(11), 12);
    expect(source.itemAtLogicalIndex(12), 1);
  });

  test('MONTH data source cycles the actual number of days', () {
    final source = TimeRailDataSourceFactory.forPlane(
      plane: TimePlane.month,
      yearAnchor: 2024,
      monthCursor: const YearMonth(year: 2024, month: 2),
    );

    expect(source.finiteLength, 29);
    expect(source.itemAtLogicalIndex(-1), 29);
    expect(source.itemAtLogicalIndex(28), 29);
    expect(source.itemAtLogicalIndex(29), 1);
  });
}
