import 'package:flutter/widgets.dart';

import '../../../core/design/dashboard_corner_profile.dart';

/// Dashboard-lifetime, session-only owner for the global shape comparison.
/// It owns no layout, data or query state.
final class DashboardCornerRoundnessController
    extends ValueNotifier<DashboardCornerRoundness> {
  DashboardCornerRoundnessController()
    : super(DashboardCornerRoundness.minimum);

  void setPosition(double position) {
    final next = DashboardCornerRoundness(position);
    if (next.position != value.position) value = next;
  }
}

/// Lets only the rounded presentation leaves rebuild when the tuner changes
/// shape. Consumers still resolve their own semantic surface family and size.
final class DashboardCornerRoundnessScope
    extends InheritedNotifier<DashboardCornerRoundnessController> {
  const DashboardCornerRoundnessScope({
    super.key,
    required DashboardCornerRoundnessController controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardCornerProfile profileOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DashboardCornerRoundnessScope>();
    return DashboardCornerProfile(
      scope?.notifier?.value ?? DashboardCornerRoundness.minimum,
    );
  }
}
