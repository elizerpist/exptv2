import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_demand_planner.dart';

void main() {
  test('derives a bounded live target from the drawable last visible page', () {
    final desired = CommittedVerticalDemandPlanner.plan(
      lastVisibleOrdinal: 3,
      highestReadyOrdinal: 3,
      currentDesiredOrdinal: 3,
      lastPossibleOrdinal: 102,
      hasMorePages: true,
      distanceToDrawableEnd: 0,
      viewportDimension: 420,
    );

    expect(desired, 5);
  });

  test('frontier proximity requests only the next missing exact page', () {
    final desired = CommittedVerticalDemandPlanner.plan(
      lastVisibleOrdinal: 0,
      highestReadyOrdinal: 5,
      currentDesiredOrdinal: 5,
      lastPossibleOrdinal: 102,
      hasMorePages: true,
      distanceToDrawableEnd: 10,
      viewportDimension: 420,
    );

    expect(desired, 6);
  });

  test(
    'fixed visible progress and repeated completion cannot preload a ledger',
    () {
      final desired = CommittedVerticalDemandPlanner.plan(
        lastVisibleOrdinal: 0,
        highestReadyOrdinal: 5,
        currentDesiredOrdinal: 5,
        lastPossibleOrdinal: 102,
        hasMorePages: true,
        distanceToDrawableEnd: 4000,
        viewportDimension: 420,
      );

      expect(desired, 5);
    },
  );

  test('never requests beyond the exact terminal ordinal', () {
    final desired = CommittedVerticalDemandPlanner.plan(
      lastVisibleOrdinal: 8,
      highestReadyOrdinal: 8,
      currentDesiredOrdinal: 8,
      lastPossibleOrdinal: 9,
      hasMorePages: true,
      distanceToDrawableEnd: 0,
      viewportDimension: 420,
    );

    expect(desired, 9);
  });
}
