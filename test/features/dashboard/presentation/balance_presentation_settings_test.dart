import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';

void main() {
  test('Balance child-card setting is presentation-only and revisioned', () {
    final controller = BalancePresentationController();
    addTearDown(controller.dispose);

    expect(controller.value.usesChildCards, isTrue);
    controller.setUsesChildCards(false);
    expect(controller.value.usesChildCards, isFalse);
    expect(controller.value.revision, 1);

    controller.setUsesChildCards(false);
    expect(controller.value.revision, 1);
  });
}
