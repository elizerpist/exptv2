import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import 'dashboard_core_mode_surface_primitives.dart';

/// Budget-only material geometry. Content keeps its existing cascade, input
/// parents and controllers. Every value is a pure function of the master frame.
@immutable
final class BudgetUnifiedMotherCardGeometry {
  const BudgetUnifiedMotherCardGeometry._({
    required this.separation,
    required this.joinedBounds,
    required this.bodyBounds,
    required this.cascadeBounds,
    required this.visibleBodyBounds,
    required this.paintBounds,
    required this.headerBounds,
    required this.shape,
    required this.opacity,
    required this.bridgeHeight,
  });

  final double separation;
  final Rect joinedBounds;

  /// Unoccluded physical trajectory; its collapsed target is the exact cascade.
  final Rect bodyBounds;
  final Rect cascadeBounds;

  /// The Header stays above the body. Only its decorative material is trimmed
  /// at the separating contact edge; no clip is added to the persistent pager.
  final Rect visibleBodyBounds;
  final Rect paintBounds;
  final Rect headerBounds;
  final DashboardHeaderContentSeamShape shape;
  final double opacity;
  final double bridgeHeight;

  static BudgetUnifiedMotherCardGeometry resolve({
    required DashboardLayoutFrame frame,
    required BorderRadius headerRadius,
    required BorderRadius contentRadius,
  }) {
    final s = (1 - frame.headerExpansionProgress).clamp(0.0, 1.0).toDouble();
    Rect rect(DashboardBounds b) =>
        Rect.fromLTWH(b.left, b.top, b.width, b.height);
    final header = rect(frame.headerBounds);
    final joined = rect(
      DashboardHeaderContentMotherCardBounds.resolve(geometry: frame),
    );
    final attached = Rect.fromLTRB(
      header.left,
      header.bottom,
      header.right,
      joined.bottom,
    );
    final motion = frame.lowerCardMotion!;
    final canvasWidth = header.width + header.left * 2;
    final layoutWidth = canvasWidth - motion.left - motion.right;
    // Resolve Positioned(left/right) then top-centred scale exactly once, just
    // like Card2. The former background ignored left/right and drifted wider.
    final width = layoutWidth * motion.scale;
    final left = motion.left + (layoutWidth - width) / 2;
    final top =
        motion.top + frame.modeContentBounds.top - frame.zone2Bounds.top;
    final target = Rect.fromLTWH(
      left,
      top,
      width,
      frame.modeContentBounds.height * motion.scale,
    );
    final vertical = Rect.lerp(attached, target, s)!;
    final body = Rect.fromLTRB(
      target.left,
      vertical.top,
      target.right,
      vertical.bottom,
    );
    // Once the cascade tucks underneath the Header, its visible material
    // stops at the contact edge. The opening is derived from that same
    // structural lane and cascade visibility, not a fixed correction/duration.
    final gap =
        math.max(0.0, frame.modeContentBounds.top - header.bottom) *
        s *
        motion.opacity;
    final visibleTop = math.max(body.top, header.bottom + gap);
    final visible = Rect.fromLTRB(
      body.left,
      math.min(visibleTop, body.bottom),
      body.right,
      body.bottom,
    );
    final paint = header.expandToInclude(visible);
    return BudgetUnifiedMotherCardGeometry._(
      separation: s,
      joinedBounds: joined,
      bodyBounds: body,
      cascadeBounds: target,
      visibleBodyBounds: visible,
      paintBounds: paint,
      headerBounds: header,
      shape: DashboardHeaderContentSeamShape.resolve(
        seamless: true,
        headerRadius: headerRadius,
        contentRadius: contentRadius,
        expansionProgress: 1 - s,
      ),
      opacity: motion.opacity,
      bridgeHeight:
          (frame.modeContentBounds.top - header.bottom + 34)
              .clamp(0.0, visible.height)
              .toDouble() *
          (1 - s),
    );
  }
}
