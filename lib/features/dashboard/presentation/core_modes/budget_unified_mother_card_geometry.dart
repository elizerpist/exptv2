import 'package:flutter/material.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import 'dashboard_unified_mother_card_motion.dart';
import 'dashboard_core_mode_surface_primitives.dart';

/// Mode adapter; physical timing and bounds have one shared implementation.
@immutable
final class BudgetUnifiedMotherCardGeometry {
  const BudgetUnifiedMotherCardGeometry._(this.motion);
  final DashboardUnifiedMotherCardMotion motion;
  double get separation => motion.separation;
  Rect get joinedBounds => motion.joinedBounds;
  Rect get headerBounds => motion.headerBounds;
  Rect get bodyBounds => motion.bodyBounds;
  Rect get visibleBodyBounds => motion.visibleBodyBounds;
  Rect get paintBounds => motion.paintBounds;
  Rect get cascadeBounds => motion.detachedTargetBounds;
  DashboardHeaderContentSeamShape get shape => motion.shape;
  double get opacity => motion.bodyOpacity;
  static BudgetUnifiedMotherCardGeometry resolve({
    required DashboardLayoutFrame frame,
    required BorderRadius headerRadius,
    required BorderRadius contentRadius,
  }) => BudgetUnifiedMotherCardGeometry._(
    DashboardUnifiedMotherCardMotion.resolve(
      frame: frame,
      headerRadius: headerRadius,
      contentRadius: contentRadius,
    ),
  );
}
