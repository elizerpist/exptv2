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
      });
    }

    test('switches forward immediately around the three-node ring', () {
      final events = <DashboardCoreModeSwitchEvent>[];
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
        onModeSwitched: events.add,
      );
      addTearDown(controller.dispose);

      expect(controller.switchMode(DashboardCoreModeDirection.forward), isTrue);
      expect(controller.committedMode, DashboardModeSpec.budget);
      expect(events, hasLength(1));
      expect(events.single.fromMode, DashboardModeSpec.balance);
      expect(events.single.toMode, DashboardModeSpec.budget);
      expect(events.single.direction, DashboardCoreModeDirection.forward);

      controller.switchMode(DashboardCoreModeDirection.forward);
      expect(controller.committedMode, DashboardModeSpec.mind);
      controller.switchMode(DashboardCoreModeDirection.forward);
      expect(controller.committedMode, DashboardModeSpec.balance);
      expect(events, hasLength(3));
    });

    test('switches backward immediately around the three-node ring', () {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);

      controller.switchMode(DashboardCoreModeDirection.backward);
      expect(controller.committedMode, DashboardModeSpec.mind);
      controller.switchMode(DashboardCoreModeDirection.backward);
      expect(controller.committedMode, DashboardModeSpec.budget);
      controller.switchMode(DashboardCoreModeDirection.backward);
      expect(controller.committedMode, DashboardModeSpec.balance);
    });

    test('publishes exactly one semantic event for one switch', () {
      final events = <DashboardCoreModeSwitchEvent>[];
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
        onModeSwitched: events.add,
      );
      addTearDown(controller.dispose);

      controller.switchMode(DashboardCoreModeDirection.forward);

      expect(events, hasLength(1));
      expect(events.single.fromMode, DashboardModeSpec.mind);
      expect(events.single.toMode, DashboardModeSpec.balance);
    });

    test(
      'programmatic mode replacement remains an immediate canonical write',
      () {
        final controller = DashboardCoreModeController(
          initialMode: DashboardModeSpec.balance,
        );
        addTearDown(controller.dispose);

        expect(controller.setProgrammaticMode(DashboardModeSpec.mind), isTrue);
        expect(controller.committedMode, DashboardModeSpec.mind);
        expect(controller.setProgrammaticMode(DashboardModeSpec.mind), isFalse);
      },
    );

    test('remains a three-node ring across thirty immediate switches', () {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);

      for (var index = 0; index < 30; index += 1) {
        controller.switchMode(DashboardCoreModeDirection.forward);
      }

      expect(controller.committedMode, DashboardModeSpec.balance);
    });
  });
}
