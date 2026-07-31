import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_controller.dart';

void main() {
  test('DashboardRailController toggles only its open state', () {
    final controller = DashboardRailController();

    expect(controller.isExpanded, isFalse);
    controller.toggle();
    expect(controller.isExpanded, isTrue);
    controller.toggle();
    expect(controller.isExpanded, isFalse);
  });
}
