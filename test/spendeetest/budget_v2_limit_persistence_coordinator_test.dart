import 'dart:async';

import 'package:exptv2/features/transactions/state/budget_v2_limit_persistence_coordinator.dart';
import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_limit_edit_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'same-scope serialization prevents reverse success from restoring an older amount',
    () async {
      final store = Object();
      final coordinator = BudgetV2LimitPersistenceCoordinator(
        initialStoreIdentity: store,
      );
      addTearDown(coordinator.dispose);
      final firstCompletion = Completer<void>();
      final secondCompletion = Completer<void>()..complete();
      final starts = <int>[];
      final appliedAmounts = <double>[];
      final acknowledged = <int>[];

      Future<void> write(
        int operationId,
        double amount,
        Completer<void> completion,
        bool Function() isCurrentRuntime,
      ) async {
        starts.add(operationId);
        await completion.future;
        if (isCurrentRuntime()) appliedAmounts.add(amount);
      }

      final first = coordinator.schedule(
        storeIdentity: store,
        avatarKey: 'food',
        operationId: 1,
        write: (isCurrent) => write(1, 6000, firstCompletion, isCurrent),
        onSuccess: acknowledged.add,
        onError: (_, _, _) => fail('The first write should succeed.'),
      );
      final second = coordinator.schedule(
        storeIdentity: store,
        avatarKey: 'food',
        operationId: 2,
        write: (isCurrent) => write(2, 7000, secondCompletion, isCurrent),
        onSuccess: acknowledged.add,
        onError: (_, _, _) => fail('The second write should succeed.'),
      );

      await Future<void>.delayed(Duration.zero);
      expect(starts, <int>[1]);

      firstCompletion.complete();
      await Future.wait(<Future<void>>[first, second]);

      expect(starts, <int>[1, 2]);
      expect(appliedAmounts, <double>[6000, 7000]);
      expect(appliedAmounts.last, 7000);
      expect(acknowledged, <int>[1, 2]);
    },
  );

  test(
    'a stale error cannot stop or acknowledge the newer queued write',
    () async {
      final store = Object();
      final coordinator = BudgetV2LimitPersistenceCoordinator(
        initialStoreIdentity: store,
      );
      addTearDown(coordinator.dispose);
      final firstCompletion = Completer<void>();
      final secondCompletion = Completer<void>()..complete();
      final starts = <int>[];
      final acknowledged = <int>[];
      final failed = <int>[];

      final first = coordinator.schedule(
        storeIdentity: store,
        avatarKey: 'food',
        operationId: 1,
        write: (_) async {
          starts.add(1);
          await firstCompletion.future;
        },
        onSuccess: acknowledged.add,
        onError: (operationId, _, _) => failed.add(operationId),
      );
      final second = coordinator.schedule(
        storeIdentity: store,
        avatarKey: 'food',
        operationId: 2,
        write: (_) async {
          starts.add(2);
          await secondCompletion.future;
        },
        onSuccess: acknowledged.add,
        onError: (operationId, _, _) => failed.add(operationId),
      );

      await Future<void>.delayed(Duration.zero);
      expect(starts, <int>[1]);
      firstCompletion.completeError(StateError('stale write failed'));
      await Future.wait(<Future<void>>[first, second]);

      expect(starts, <int>[1, 2]);
      expect(failed, <int>[1]);
      expect(acknowledged, <int>[2]);
    },
  );

  test(
    'same-amount newer operation keeps preview until its own controlled success',
    () async {
      final store = Object();
      final coordinator = BudgetV2LimitPersistenceCoordinator(
        initialStoreIdentity: store,
      );
      addTearDown(coordinator.dispose);
      final completions = <Completer<void>>[
        Completer<void>(),
        Completer<void>(),
      ];
      final scheduled = <Future<void>>[];
      var nextOperationId = 0;
      late final BudgetV2LimitEditController controller;
      controller = BudgetV2LimitEditController(
        allocateOperationId: () => ++nextOperationId,
        onPersist: (avatarKey, amount, operationId) {
          scheduled.add(
            coordinator.schedule(
              storeIdentity: store,
              avatarKey: avatarKey,
              operationId: operationId,
              write: (_) => completions[operationId - 1].future,
              onSuccess: (completedOperationId) {
                controller.acknowledgePersisted(
                  avatarKey,
                  operationId: completedOperationId,
                );
              },
              onError: (_, _, _) => fail('Both writes should succeed.'),
            ),
          );
        },
      );
      addTearDown(controller.dispose);

      controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
      controller.finish();
      controller.begin(avatarKey: 'food', initialAmount: 6000, globalY: 100);
      controller.finish();

      completions.first.complete();
      await scheduled.first;
      expect(
        controller.previewAmount('food', fallback: 9000),
        6000,
        reason:
            'Operation 1 has the same amount but cannot acknowledge operation 2.',
      );

      completions.last.complete();
      await Future.wait(scheduled);
      expect(controller.previewAmount('food', fallback: 9000), 9000);
    },
  );

  test(
    'ABA runtime generation blocks the old A result and acknowledges only new A',
    () async {
      final storeA = Object();
      final storeB = Object();
      final coordinator = BudgetV2LimitPersistenceCoordinator(
        initialStoreIdentity: storeA,
      );
      addTearDown(coordinator.dispose);
      final oldACompletion = Completer<void>();
      final newACompletion = Completer<void>()..complete();
      final starts = <int>[];
      final applied = <int>[];
      final acknowledged = <int>[];

      final oldA = coordinator.schedule(
        storeIdentity: storeA,
        avatarKey: 'food',
        operationId: 1,
        write: (isCurrentRuntime) async {
          starts.add(1);
          await oldACompletion.future;
          if (isCurrentRuntime()) applied.add(1);
        },
        onSuccess: acknowledged.add,
        onError: (_, _, _) => fail('The old A write should complete cleanly.'),
      );
      await Future<void>.delayed(Duration.zero);
      coordinator.replaceStoreIdentity(storeB);
      coordinator.replaceStoreIdentity(storeA);
      final newA = coordinator.schedule(
        storeIdentity: storeA,
        avatarKey: 'food',
        operationId: 2,
        write: (isCurrentRuntime) async {
          starts.add(2);
          await newACompletion.future;
          if (isCurrentRuntime()) applied.add(2);
        },
        onSuccess: acknowledged.add,
        onError: (_, _, _) => fail('The new A write should succeed.'),
      );

      oldACompletion.complete();
      await Future.wait(<Future<void>>[oldA, newA]);

      expect(starts, <int>[1, 2]);
      expect(applied, <int>[2]);
      expect(acknowledged, <int>[2]);
      expect(coordinator.runtimeGeneration, 2);
    },
  );

  test(
    'same-store queue and operation IDs survive dashboard runtime disposal',
    () async {
      final store = Object();
      final oldRuntime = BudgetV2LimitPersistenceCoordinator(
        initialStoreIdentity: store,
      );
      final oldCompletion = Completer<void>();
      final newCompletion = Completer<void>()..complete();
      final starts = <int>[];
      final applied = <int>[];
      final acknowledged = <int>[];

      final oldOperationId = oldRuntime.allocateOperationId(store);
      final oldWrite = oldRuntime.schedule(
        storeIdentity: store,
        avatarKey: 'food',
        operationId: oldOperationId,
        write: (isCurrentRuntime) async {
          starts.add(oldOperationId);
          await oldCompletion.future;
          if (isCurrentRuntime()) applied.add(oldOperationId);
        },
        onSuccess: acknowledged.add,
        onError: (_, _, _) => fail('The old write should complete cleanly.'),
      );
      await Future<void>.delayed(Duration.zero);
      oldRuntime.dispose();

      final newRuntime = BudgetV2LimitPersistenceCoordinator(
        initialStoreIdentity: store,
      );
      addTearDown(newRuntime.dispose);
      final newOperationId = newRuntime.allocateOperationId(store);
      final newWrite = newRuntime.schedule(
        storeIdentity: store,
        avatarKey: 'food',
        operationId: newOperationId,
        write: (isCurrentRuntime) async {
          starts.add(newOperationId);
          await newCompletion.future;
          if (isCurrentRuntime()) applied.add(newOperationId);
        },
        onSuccess: acknowledged.add,
        onError: (_, _, _) => fail('The new write should succeed.'),
      );

      await Future<void>.delayed(Duration.zero);
      expect(
        starts,
        <int>[oldOperationId],
        reason:
            'The new dashboard runtime must join the store-scoped old tail.',
      );
      oldCompletion.complete();
      await Future.wait(<Future<void>>[oldWrite, newWrite]);

      expect(newOperationId, oldOperationId + 1);
      expect(starts, <int>[oldOperationId, newOperationId]);
      expect(applied, <int>[newOperationId]);
      expect(acknowledged, <int>[newOperationId]);
    },
  );
}
