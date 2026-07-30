import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('physical updates cannot regress settled or committed phases', () {
    final controller = BudgetV2SelectionController(
      initialAvatarKey: 'overview',
    );
    addTearDown(controller.dispose);

    final generation = controller.beginPointerDown();
    controller.updatePhysical(offset: -72);
    expect(controller.settleAvatar('food', generation: generation), isTrue);

    controller.updatePhysical(offset: -144);
    expect(controller.phase, BudgetV2SelectionPhase.settled);
    expect(controller.physicalOffset, -72);

    expect(controller.commitIfCurrent(generation), isTrue);
    controller.updatePhysical(offset: -216);
    expect(controller.phase, BudgetV2SelectionPhase.committed);
    expect(controller.physicalOffset, -72);
  });

  test('commit diagnostics retain only a bounded recent generation window', () {
    final controller = BudgetV2SelectionController(
      initialAvatarKey: 'overview',
    );
    addTearDown(controller.dispose);
    var firstGeneration = 0;
    var latestGeneration = 0;

    for (
      var index = 0;
      index < BudgetV2SelectionController.maxRememberedGenerations + 1;
      index += 1
    ) {
      final generation = controller.beginPointerDown();
      firstGeneration = firstGeneration == 0 ? generation : firstGeneration;
      latestGeneration = generation;
      expect(
        controller.settleAvatar('avatar-$index', generation: generation),
        isTrue,
      );
      expect(controller.commitIfCurrent(generation), isTrue);
    }

    expect(controller.commitsForGeneration(firstGeneration), 0);
    expect(controller.commitsForGeneration(latestGeneration), 1);
  });
}
