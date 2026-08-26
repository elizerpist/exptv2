import 'package:flutter/widgets.dart';

import '../../../core/design/dashboard_shadow_profile.dart';

/// Dashboard-lifetime session owner for global visual depth.
final class DashboardShadowStyleController
    extends ValueNotifier<DashboardShadowStyle> {
  DashboardShadowStyleController() : super(DashboardShadowStyle.current);

  void select(DashboardShadowStyle style) {
    if (value != style) value = style;
  }
}

/// Localizes shadow-style rebuilds to dashboard presentation leaves.
final class DashboardShadowStyleScope
    extends InheritedNotifier<DashboardShadowStyleController> {
  const DashboardShadowStyleScope({
    super.key,
    required DashboardShadowStyleController controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardShadowProfile profileOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DashboardShadowStyleScope>();
    return DashboardShadowProfile(
      scope?.notifier?.value ?? DashboardShadowStyle.current,
    );
  }
}
