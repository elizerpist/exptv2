import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

void main() {
  test('YEAR child label contains only the localized month name', () {
    const expected = <String>[
      'január',
      'február',
      'március',
      'április',
      'május',
      'június',
      'július',
      'augusztus',
      'szeptember',
      'október',
      'november',
      'december',
    ];

    for (var month = 1; month <= 12; month++) {
      final label = TimeRailLabelFormatter.labelFor(TimePlane.year, month);
      expect(label, expected[month - 1]);
      expect(label, isNot(contains('2026')));
    }
  });
}
