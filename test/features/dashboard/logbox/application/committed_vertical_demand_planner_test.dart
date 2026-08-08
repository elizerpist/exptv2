import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_demand_planner.dart';

void main() {
  test(
    'requests the final 94-row page when first visible remains page zero',
    () {
      final desired = CommittedVerticalDemandPlanner.plan(
        lastVisibleOrdinal: 2,
        highestReadyOrdinal: 2,
        currentDesiredOrdinal: 2,
        lastPossibleOrdinal: 3,
        hasMorePages: true,
        distanceToDrawableEnd: 0,
        viewportDimension: 600,
      );

      expect(desired, 3);
    },
  );

  test('keeps demand bounded and does not preload the full list', () {
    final desired = CommittedVerticalDemandPlanner.plan(
      lastVisibleOrdinal: 0,
      highestReadyOrdinal: 0,
      currentDesiredOrdinal: 0,
      lastPossibleOrdinal: 41,
      hasMorePages: true,
      distanceToDrawableEnd: 2000,
      viewportDimension: 600,
    );

    expect(desired, 2);
  });

  test(
    'reaches every terminal page boundary without first-page dependence',
    () {
      for (final totalRows in <int>[24, 25, 48, 49, 72, 73, 94, 1000]) {
        final lastOrdinal = (totalRows - 1) ~/ 24;
        final desired = CommittedVerticalDemandPlanner.plan(
          // This intentionally models the June bug: page zero can remain the
          // first visible page while the lower edge has reached the frontier.
          lastVisibleOrdinal: lastOrdinal,
          highestReadyOrdinal: lastOrdinal == 0 ? 0 : lastOrdinal - 1,
          currentDesiredOrdinal: lastOrdinal == 0 ? 0 : lastOrdinal - 1,
          lastPossibleOrdinal: lastOrdinal,
          hasMorePages: lastOrdinal > 0,
          distanceToDrawableEnd: 0,
          viewportDimension: 420,
        );

        expect(
          desired,
          lastOrdinal,
          reason: '$totalRows rows must demand terminal ordinal $lastOrdinal',
        );
      }
    },
  );

  test('uses the same frontier rule across phone viewport heights', () {
    for (final viewportHeight in <double>[320, 640, 960]) {
      expect(
        CommittedVerticalDemandPlanner.plan(
          lastVisibleOrdinal: 2,
          highestReadyOrdinal: 2,
          currentDesiredOrdinal: 2,
          lastPossibleOrdinal: 3,
          hasMorePages: true,
          distanceToDrawableEnd: 0,
          viewportDimension: viewportHeight,
        ),
        3,
      );
    }
  });
}
