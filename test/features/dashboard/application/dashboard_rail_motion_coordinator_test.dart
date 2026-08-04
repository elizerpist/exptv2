import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_motion_coordinator.dart';

void main() {
  test('publishes one semantic idle and one settle per motion epoch', () {
    final coordinator = DashboardRailMotionCoordinator();

    final epoch = coordinator.begin(
      origin: DashboardRailMotionOrigin.userFling,
    );

    expect(coordinator.publishIdle(epoch: epoch, logicalIndex: 6), isTrue);
    expect(coordinator.publishIdle(epoch: epoch, logicalIndex: 6), isFalse);
    expect(coordinator.publishSettle(epoch: epoch, logicalIndex: 6), isTrue);
    expect(coordinator.publishSettle(epoch: epoch, logicalIndex: 6), isFalse);
    expect(coordinator.duplicateIdleDroppedCount, 1);
    expect(coordinator.duplicateSettleDroppedCount, 1);
  });

  test('a new motion epoch makes the previous epoch inactive', () {
    final coordinator = DashboardRailMotionCoordinator();

    final first = coordinator.begin(origin: DashboardRailMotionOrigin.userDrag);
    final second = coordinator.begin(
      origin: DashboardRailMotionOrigin.userFling,
    );

    expect(second, greaterThan(first));
    expect(coordinator.isCurrent(first), isFalse);
    expect(coordinator.isCurrent(second), isTrue);
    expect(coordinator.isMotionActive, isTrue);
  });
}
