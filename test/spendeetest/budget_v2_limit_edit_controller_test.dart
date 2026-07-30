import 'dart:async';

import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_limit_edit_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drag and auto ticks stay local until final release', (
    tester,
  ) async {
    var operationId = 0;
    final persisted = <(String, double, int)>[];
    final controller = BudgetV2LimitEditController(
      allocateOperationId: () => ++operationId,
      onPersist: (avatarKey, amount, writeId) {
        persisted.add((avatarKey, amount, writeId));
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
    expect(persisted, <(String, double, int)>[('food', 7000, 1)]);

    await tester.pump(const Duration(seconds: 1));
    expect(controller.previewAmount('food', fallback: 0), 7000);
    expect(persisted, hasLength(1));
  });

  testWidgets('stationary very-long press clears and persists exactly once', (
    tester,
  ) async {
    var operationId = 0;
    final persisted = <(String, double, int)>[];
    final controller = BudgetV2LimitEditController(
      allocateOperationId: () => ++operationId,
      onPersist: (avatarKey, amount, writeId) {
        persisted.add((avatarKey, amount, writeId));
      },
    );
    addTearDown(controller.dispose);

    controller.begin(avatarKey: 'travel', initialAmount: 25000, globalY: 120);
    await tester.pump(const Duration(milliseconds: 720));

    expect(controller.previewAmount('travel', fallback: 25000), 0);
    expect(persisted, <(String, double, int)>[('travel', 0, 1)]);

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
    var operationId = 0;
    final persisted = <(String, double, int)>[];
    final controller = BudgetV2LimitEditController(
      allocateOperationId: () => ++operationId,
      onPersist: (avatarKey, amount, writeId) {
        persisted.add((avatarKey, amount, writeId));
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

  test(
    'matching persistence acknowledgement releases only the completed preview',
    () {
      var operationId = 0;
      final controller = BudgetV2LimitEditController(
        allocateOperationId: () => ++operationId,
        onPersist: (_, _, _) {},
      );
      addTearDown(controller.dispose);

      controller.begin(avatarKey: 'food', initialAmount: 5000, globalY: 100);
      controller.update(globalY: 80);
      controller.finish();
      expect(controller.previewAmount('food', fallback: 9000), 6000);

      controller.acknowledgePersisted('food', operationId: 1);
      expect(controller.previewAmount('food', fallback: 9000), 9000);
    },
  );

  test('stale acknowledgement cannot clear a newer active preview', () {
    var operationId = 0;
    final controller = BudgetV2LimitEditController(
      allocateOperationId: () => ++operationId,
      onPersist: (_, _, _) {},
    );
    addTearDown(controller.dispose);

    controller.begin(avatarKey: 'food', initialAmount: 5000, globalY: 100);
    controller.update(globalY: 80);
    controller.finish();

    controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
    controller.update(globalY: 80);
    controller.acknowledgePersisted('food', operationId: 1);

    expect(controller.previewAmount('food', fallback: 9000), 7000);
  });

  testWidgets('reset drops previews and cancels every old-store timer', (
    tester,
  ) async {
    var operationId = 0;
    final persisted = <(String, double, int)>[];
    final controller = BudgetV2LimitEditController(
      allocateOperationId: () => ++operationId,
      onPersist: (key, amount, writeId) =>
          persisted.add((key, amount, writeId)),
    );
    addTearDown(controller.dispose);

    controller.begin(avatarKey: 'food', initialAmount: 5000, globalY: 100);
    controller.update(globalY: 80);
    controller.reset();
    await tester.pump(const Duration(seconds: 2));

    expect(controller.isEditing, isFalse);
    expect(controller.previewAmount('food', fallback: 9000), 9000);
    expect(persisted, isEmpty);
  });

  test(
    'same-amount newer operation rejects the older successful acknowledgement',
    () {
      var operationId = 0;
      final writes = <int>[];
      final controller = BudgetV2LimitEditController(
        allocateOperationId: () => ++operationId,
        onPersist: (_, _, writeId) => writes.add(writeId),
      );
      addTearDown(controller.dispose);

      controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
      controller.finish();
      controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
      controller.finish();

      expect(writes, <int>[1, 2]);
      controller.acknowledgePersisted('food', operationId: 1);
      expect(controller.previewAmount('food', fallback: 9000), 6000);

      controller.acknowledgePersisted('food', operationId: 2);
      expect(controller.previewAmount('food', fallback: 9000), 9000);
    },
  );

  test('failed operation keeps its pending preview until a later success', () {
    var operationId = 0;
    final controller = BudgetV2LimitEditController(
      allocateOperationId: () => ++operationId,
      onPersist: (_, _, _) {},
    );
    addTearDown(controller.dispose);

    controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
    controller.finish();

    expect(controller.previewAmount('food', fallback: 9000), 6000);
    controller.acknowledgePersisted('food', operationId: 2);
    expect(
      controller.previewAmount('food', fallback: 9000),
      6000,
      reason: 'An error path has no valid success operation to acknowledge.',
    );
  });

  testWidgets(
    'pending success followed by begin and cancel releases the old preview',
    (tester) async {
      var operationId = 0;
      final completion = Completer<void>();
      late final BudgetV2LimitEditController controller;
      controller = BudgetV2LimitEditController(
        allocateOperationId: () => ++operationId,
        onPersist: (avatarKey, _, writeId) {
          unawaited(
            completion.future.then((_) {
              controller.acknowledgePersisted(avatarKey, operationId: writeId);
            }),
          );
        },
      );
      addTearDown(controller.dispose);

      controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
      controller.finish();
      controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
      controller.update(globalY: 80);

      completion.complete();
      await tester.pump();
      expect(controller.previewAmount('food', fallback: 9000), 7000);

      controller.cancel();
      expect(
        controller.previewAmount('food', fallback: 9000),
        9000,
        reason:
            'Cancel must reveal the store value after the prior pending write '
            'succeeded during the active follow-up edit.',
      );
    },
  );

  testWidgets(
    'successful very-long clear releases its preview when the press ends',
    (tester) async {
      var operationId = 0;
      final completion = Completer<void>();
      late final BudgetV2LimitEditController controller;
      controller = BudgetV2LimitEditController(
        allocateOperationId: () => ++operationId,
        onPersist: (avatarKey, _, writeId) {
          unawaited(
            completion.future.then((_) {
              controller.acknowledgePersisted(avatarKey, operationId: writeId);
            }),
          );
        },
      );
      addTearDown(controller.dispose);

      controller.begin(avatarKey: 'travel', initialAmount: 25000, globalY: 120);
      await tester.pump(BudgetV2LimitEditController.veryLongPressDelay);
      expect(controller.pendingPreviewAmounts, <String, double>{'travel': 0});

      completion.complete();
      await tester.pump();
      controller.cancel();

      expect(controller.pendingPreviewAmounts, isEmpty);
      expect(controller.previewAmount('travel', fallback: 0), 0);
    },
  );
}
