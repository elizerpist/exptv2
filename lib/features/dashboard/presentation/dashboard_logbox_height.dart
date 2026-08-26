import 'package:flutter/widgets.dart';

import '../../../core/design/dashboard_logbox_layout_profile.dart';

/// Dashboard-lifetime session owner for the stepped LogBox row-height setting.
final class DashboardLogBoxHeightController
    extends ValueNotifier<DashboardLogBoxHeight> {
  DashboardLogBoxHeightController() : super(DashboardLogBoxHeight.zero);

  void setPosition(double position) {
    final next = DashboardLogBoxHeight(position);
    if (next != value) value = next;
  }
}

/// Gives paint/layout leaves the exact same profile that Core publishes into
/// committed LogBox geometry.
final class DashboardLogBoxLayoutScope
    extends InheritedNotifier<DashboardLogBoxHeightController> {
  const DashboardLogBoxLayoutScope({
    super.key,
    required DashboardLogBoxHeightController controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardLogBoxLayoutProfile profileOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DashboardLogBoxLayoutScope>();
    return DashboardLogBoxLayoutProfile(
      scope?.notifier?.value ?? DashboardLogBoxHeight.zero,
    );
  }
}
