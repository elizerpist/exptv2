import 'package:flutter/widgets.dart';

import '../../../core/design/dashboard_border_profile.dart';

/// Dashboard-lifetime session owner for independent outer-surface contours.
final class DashboardBorderController
    extends ValueNotifier<DashboardBorderSettings> {
  DashboardBorderController() : super(DashboardBorderSettings.defaults);

  void setEnabled(DashboardBorderSurface surface, bool enabled) {
    final next = value.copyWith(surface, enabled: enabled);
    if (next != value) value = next;
  }
}

/// Limits contour rebuilds to presentation leaves which consume the profile.
final class DashboardBorderScope
    extends InheritedNotifier<DashboardBorderController> {
  const DashboardBorderScope({
    super.key,
    required DashboardBorderController controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardBorderProfile profileOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DashboardBorderScope>();
    return DashboardBorderProfile(
      scope?.notifier?.value ?? DashboardBorderSettings.defaults,
    );
  }
}
