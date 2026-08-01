import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/widgets/time_refinement_rail.dart';

void main() {
  test('YEAR child label contains only the localized month name', () {
    expect(TimeRailLabelFormatter.labelFor(TimePlane.year, 5), 'május');
    expect(
      TimeRailLabelFormatter.labelFor(TimePlane.year, 5),
      isNot(contains('2026')),
    );
  });
}
