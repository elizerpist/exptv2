import 'package:flutter/widgets.dart';

import '../../../core/design/dashboard_corner_profile.dart';

/// Dashboard-lifetime, session-only owner for independently tunable dashboard
/// corner families. It owns no layout, data or query state.
final class DashboardCornerRoundnessController
    extends ValueNotifier<DashboardCornerSettings> {
  DashboardCornerRoundnessController()
    : super(DashboardCornerSettings.defaults);

  void setPosition(DashboardCornerSurfaceFamily family, double position) {
    final next = value.withPosition(family, position);
    if (next != value) value = next;
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
      scope?.notifier?.value ?? DashboardCornerSettings.defaults,
    );
  }
}
