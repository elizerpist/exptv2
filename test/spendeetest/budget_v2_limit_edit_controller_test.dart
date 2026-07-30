import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_limit_edit_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drag and auto ticks stay local until final release', (
    tester,
  ) async {
    final persisted = <(String, double)>[];
    final controller = BudgetV2LimitEditController(
      onPersist: (avatarKey, amount) {
        persisted.add((avatarKey, amount));
      },
    );
    addTearDown(controller.dispose);

    controller.begin(avatarKey: 'food', initialAmount: 5000, globalY: 100);
    controller.update(globalY: 80);

    expect(controller.previewAmount('food', fallback: 0), 6000);
    expect(persisted, isEmpty);

    await tester.pump(const Duration(milliseconds: 337));
    expect(controller.previewAmount('food', fallback: 0), 7000);
    expect(persisted, isEmpty);

    controller.finish();
    expect(persisted, <(String, double)>[('food', 7000)]);

    await tester.pump(const Duration(seconds: 1));
    expect(controller.previewAmount('food', fallback: 0), 7000);
    expect(persisted, hasLength(1));
  });

  testWidgets('stationary very-long press clears and persists exactly once', (
    tester,
  ) async {
    final persisted = <(String, double)>[];
    final controller = BudgetV2LimitEditController(
      onPersist: (avatarKey, amount) {
        persisted.add((avatarKey, amount));
      },
    );
    addTearDown(controller.dispose);

    controller.begin(avatarKey: 'travel', initialAmount: 25000, globalY: 120);
    await tester.pump(const Duration(milliseconds: 720));

    expect(controller.previewAmount('travel', fallback: 25000), 0);
    expect(persisted, <(String, double)>[('travel', 0)]);

    controller.update(globalY: 80);
    await tester.pump(const Duration(seconds: 1));
    expect(controller.previewAmount('travel', fallback: 25000), 0);

    controller.cancel();
    expect(controller.previewAmount('travel', fallback: 25000), 0);
    expect(persisted, hasLength(1));
  });

  testWidgets('cancel stops timers and never persists a local preview', (
    tester,
  ) async {
    final persisted = <(String, double)>[];
    final controller = BudgetV2LimitEditController(
      onPersist: (avatarKey, amount) {
        persisted.add((avatarKey, amount));
      },
    );
    addTearDown(controller.dispose);

    controller.begin(avatarKey: 'food', initialAmount: 2000, globalY: 100);
    controller.update(globalY: 88);
    expect(controller.previewAmount('food', fallback: 0), 3000);

    controller.cancel();
    await tester.pump(const Duration(seconds: 2));

    expect(persisted, isEmpty);
    expect(controller.isEditing, isFalse);
    expect(controller.previewAmount('food', fallback: 2000), 2000);

    controller.begin(avatarKey: 'food', initialAmount: 9000, globalY: 100);
    expect(controller.previewAmount('food', fallback: 0), 9000);
    controller.cancel();
  });
}
