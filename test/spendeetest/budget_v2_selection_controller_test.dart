import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('physical movement settles before its generation can commit once', () {
    final controller = BudgetV2SelectionController(
      initialAvatarKey: 'overview',
    );

    final generation = controller.beginPointerDown();
    controller.updatePhysical(offset: -72);

    expect(controller.phase, BudgetV2SelectionPhase.physical);
    expect(controller.physicalOffset, -72);
    expect(controller.settledAvatarKey, 'overview');
    expect(controller.committedAvatarKey, 'overview');

    expect(controller.settleAvatar('food', generation: generation), isTrue);

    expect(controller.phase, BudgetV2SelectionPhase.settled);
    expect(controller.settledAvatarKey, 'food');
    expect(controller.committedAvatarKey, 'overview');
    expect(controller.commitIfCurrent(generation), isTrue);
    expect(controller.phase, BudgetV2SelectionPhase.committed);
    expect(controller.committedAvatarKey, 'food');
    expect(controller.commitIfCurrent(generation), isFalse);
    expect(controller.commitsForGeneration(generation), 1);
  });

  test('a new pointer generation cancels an obsolete settled commit', () {
    final controller = BudgetV2SelectionController(
      initialAvatarKey: 'overview',
    );

    final obsoleteGeneration = controller.beginPointerDown();
    controller.updatePhysical(offset: -64);
    final activeGeneration = controller.beginPointerDown();

    expect(activeGeneration, greaterThan(obsoleteGeneration));
    expect(controller.phase, BudgetV2SelectionPhase.physical);

    controller.updatePhysical(offset: -128);
    expect(
      controller.settleAvatar('travel', generation: activeGeneration),
      isTrue,
    );
    expect(
      controller.settleAvatar('food', generation: obsoleteGeneration),
      isFalse,
    );

    expect(controller.settledAvatarKey, 'travel');
    expect(controller.commitIfCurrent(obsoleteGeneration), isFalse);
    expect(controller.committedAvatarKey, 'overview');
    expect(controller.commitIfCurrent(activeGeneration), isTrue);
    expect(controller.committedAvatarKey, 'travel');
    expect(controller.commitsForGeneration(activeGeneration), 1);
  });
}
