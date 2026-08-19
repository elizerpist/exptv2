import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_rail_controller.dart';

void main() {
  test(
    'external category request targets the nearest cyclic logical index',
    () async {
      final delegate = _FakeRailDelegate(logicalIndex: 7, targetCount: 9);
      final controller = BudgetTargetAvatarRailController()..attach(delegate);
      addTearDown(controller.dispose);

      await controller.animateToTargetHandle(
        0,
        source: BudgetTargetNavigationSource.pieCenter,
      );

      expect(delegate.requestedLogicalIndices, <int>[9]);
      expect(controller.lastRequest!.nearestStepCount, 2);
    },
  );

  test('cyclic wrap chooses the other short route deterministically', () async {
    final delegate = _FakeRailDelegate(logicalIndex: 0, targetCount: 9);
    final controller = BudgetTargetAvatarRailController()..attach(delegate);
    addTearDown(controller.dispose);

    await controller.animateToTargetHandle(
      7,
      source: BudgetTargetNavigationSource.categoryList,
    );

    expect(delegate.requestedLogicalIndices, <int>[-2]);
    expect(controller.lastRequest!.nearestStepCount, 2);
  });

  test(
    'a detached rail never teleports semantic presentation directly',
    () async {
      final controller = BudgetTargetAvatarRailController();
      addTearDown(controller.dispose);

      await controller.animateToTargetHandle(
        3,
        source: BudgetTargetNavigationSource.pieSlice,
      );

      expect(controller.lastRequest, isNull);
    },
  );
}

final class _FakeRailDelegate implements BudgetTargetAvatarRailCommandDelegate {
  _FakeRailDelegate({required this.logicalIndex, required this.targetCount});

  @override
  int logicalIndex;

  @override
  final int targetCount;

  final List<int> requestedLogicalIndices = <int>[];

  @override
  Future<void> animateToLogicalIndex(int logicalIndex) async {
    requestedLogicalIndices.add(logicalIndex);
    this.logicalIndex = logicalIndex;
  }
}
