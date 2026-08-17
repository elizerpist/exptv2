import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';

void main() {
  group('DashboardCoreModeController', () {
    for (final initialMode in DashboardModeSpec.values) {
      test('starts committed at ${initialMode.mode.name}', () {
        final controller = DashboardCoreModeController(
          initialMode: initialMode,
        );
        addTearDown(controller.dispose);

        expect(controller.committedMode, initialMode);
        expect(
          controller.transition.phase,
          DashboardCoreModeTransitionPhase.idle,
        );
        expect(controller.transition.targetMode, isNull);
        expect(controller.transition.direction, isNull);
      });
    }

    test('cycles forward from balance to budget to mind to balance', () {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);

      _commit(controller, DashboardCoreModeDirection.forward);
      expect(controller.committedMode, DashboardModeSpec.budget);
      _commit(controller, DashboardCoreModeDirection.forward);
      expect(controller.committedMode, DashboardModeSpec.mind);
      _commit(controller, DashboardCoreModeDirection.forward);
      expect(controller.committedMode, DashboardModeSpec.balance);
    });

    test('cycles backward from balance to mind to budget to balance', () {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);

      _commit(controller, DashboardCoreModeDirection.backward);
      expect(controller.committedMode, DashboardModeSpec.mind);
      _commit(controller, DashboardCoreModeDirection.backward);
      expect(controller.committedMode, DashboardModeSpec.budget);
      _commit(controller, DashboardCoreModeDirection.backward);
      expect(controller.committedMode, DashboardModeSpec.balance);
    });

    test('starts one target without mutating the committed mode', () {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.budget,
      );
      addTearDown(controller.dispose);

      expect(
        controller.beginTransition(DashboardCoreModeDirection.forward),
        isTrue,
      );

      expect(controller.committedMode, DashboardModeSpec.budget);
      expect(
        controller.transition.phase,
        DashboardCoreModeTransitionPhase.dragging,
      );
      expect(controller.transition.targetMode, DashboardModeSpec.mind);
      expect(
        controller.transition.direction,
        DashboardCoreModeDirection.forward,
      );
    });

    test('keeps the original target after horizontal direction commits', () {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);

      expect(
        controller.beginTransition(DashboardCoreModeDirection.forward),
        isTrue,
      );
      expect(
        controller.beginTransition(DashboardCoreModeDirection.backward),
        isFalse,
      );

      expect(controller.transition.targetMode, DashboardModeSpec.budget);
      expect(
        controller.transition.direction,
        DashboardCoreModeDirection.forward,
      );
    });

    test('commits exactly once and returns to idle only after completion', () {
      final events = <DashboardCoreModeTransitionEvent>[];
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
        onTransitionEvent: events.add,
      );
      addTearDown(controller.dispose);

      controller.beginTransition(DashboardCoreModeDirection.forward);
      expect(controller.commitTransition(), isTrue);
      expect(controller.commitTransition(), isFalse);

      expect(controller.committedMode, DashboardModeSpec.budget);
      expect(
        controller.transition.phase,
        DashboardCoreModeTransitionPhase.settlingCommitted,
      );
      expect(
        events.where(
          (event) =>
              event.kind == DashboardCoreModeTransitionEventKind.committed,
        ),
        hasLength(1),
      );

      expect(controller.completeTransition(), isTrue);
      expect(
        controller.transition.phase,
        DashboardCoreModeTransitionPhase.idle,
      );
      expect(controller.transition.targetMode, isNull);
    });

    test('cancels without changing committed mode', () {
      final events = <DashboardCoreModeTransitionEvent>[];
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
        onTransitionEvent: events.add,
      );
      addTearDown(controller.dispose);

      controller.beginTransition(DashboardCoreModeDirection.backward);
      expect(controller.cancelTransition(), isTrue);

      expect(controller.committedMode, DashboardModeSpec.mind);
      expect(
        controller.transition.phase,
        DashboardCoreModeTransitionPhase.settlingCancelled,
      );
      expect(
        events.where(
          (event) =>
              event.kind == DashboardCoreModeTransitionEventKind.cancelled,
        ),
        hasLength(1),
      );

      controller.completeTransition();
      expect(
        controller.transition.phase,
        DashboardCoreModeTransitionPhase.idle,
      );
      expect(controller.transition.targetMode, isNull);
    });

    test('remains a three-node ring across thirty completed transitions', () {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);

      for (var index = 0; index < 30; index += 1) {
        _commit(controller, DashboardCoreModeDirection.forward);
        expect(
          controller.transition.phase,
          DashboardCoreModeTransitionPhase.idle,
        );
        expect(controller.transition.targetMode, isNull);
      }

      expect(controller.committedMode, DashboardModeSpec.balance);
    });
  });
}

void _commit(
  DashboardCoreModeController controller,
  DashboardCoreModeDirection direction,
) {
  expect(controller.beginTransition(direction), isTrue);
  expect(controller.commitTransition(), isTrue);
  expect(controller.completeTransition(), isTrue);
}
