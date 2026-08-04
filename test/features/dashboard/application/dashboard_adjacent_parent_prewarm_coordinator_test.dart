import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_adjacent_parent_prewarm_coordinator.dart';

void main() {
  test('defers adjacent prewarm until motion is idle', () async {
    final coordinator = DashboardAdjacentParentPrewarmCoordinator();
    addTearDown(coordinator.dispose);
    final started = <int>[];

    coordinator.beginMotion();
    coordinator.schedule((generation) async {
      started.add(generation);
    });
    await Future<void>.delayed(Duration.zero);
    expect(started, isEmpty);

    coordinator.endMotion();
    await Future<void>.delayed(Duration.zero);

    expect(started, hasLength(1));
    expect(coordinator.prewarmStartedCount, 1);
  });

  test('a newer schedule supersedes an older adjacent prewarm', () async {
    final coordinator = DashboardAdjacentParentPrewarmCoordinator();
    addTearDown(coordinator.dispose);
    final started = <int>[];

    coordinator.schedule((generation) async {
      started.add(generation);
    });
    coordinator.schedule((generation) async {
      started.add(generation);
    });
    await Future<void>.delayed(Duration.zero);

    expect(started, hasLength(1));
    expect(coordinator.prewarmStartedCount, 1);
  });
}
