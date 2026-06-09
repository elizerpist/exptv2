import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_joystick_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarJoystickRange', () {
    test('uses zero min and rounds observed max to a readable ceiling', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 12000,
        observedMax: 38200,
        fallbackMax: 50000,
      );

      expect(range.min, 0);
      expect(range.max, 50000);
      expect(range.step, 1000);
    });

    test('keeps current value inside the adaptive range even above observed max', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 120000,
        observedMax: 38000,
        fallbackMax: 50000,
      );

      expect(range.max, 250000);
      expect(range.clamp(300000), 250000);
    });

    test('falls back when there is no observed data', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 0,
        observedMax: 0,
        fallbackMax: 50000,
      );

      expect(range.max, 50000);
      expect(range.step, 1000);
    });

    test('snaps to the adaptive step and clamps to boundaries', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 1000,
        observedMax: 22000,
        fallbackMax: 50000,
      );

      expect(range.snap(1499), 1000);
      expect(range.snap(1501), 2000);
      expect(range.clamp(-100), 0);
      expect(range.clamp(range.max + range.step), range.max);
    });
  });
}
