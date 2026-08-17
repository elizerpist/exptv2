import 'package:flutter/foundation.dart';

import 'dashboard_layout_frame.dart';
import 'dashboard_mode_palette.dart';

/// Immutable, centrally-derived input for one dashboard-core mode surface.
@immutable
class DashboardCoreModePresentation {
  const DashboardCoreModePresentation({
    required this.geometry,
    required this.palette,
  });

  final DashboardLayoutFrame geometry;
  final DashboardModePalette palette;
}
