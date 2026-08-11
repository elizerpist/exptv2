import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_presets.dart';

void main() {
  test('current-month preset uses only the product reference month', () {
    expect(
      QueryTemporalPresets.currentMonth(DateTime(2026, 8, 14)).canonicalKey,
      'time=month:2026-08',
    );
  });

  test('last-three-months preset is June through August at August 2026', () {
    expect(
      QueryTemporalPresets.lastThreeMonths(DateTime(2026, 8, 14)).canonicalKey,
      'time=month:2026-06,month:2026-07,month:2026-08',
    );
  });
}
