import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import 'dashboard_core_mode_surface_primitives.dart';

/// Mind has a unified structural envelope, not Budget's lower-card cascade.
/// Material follows the canonical reveal while content retains Mind's staged
/// zone-two motion. Both are evaluated directly from the same master frame.
@immutable
final class MindUnifiedMotherCardGeometry {
  const MindUnifiedMotherCardGeometry._({
    required this.separation,
    required this.joinedBounds,
    required this.headerBounds,
    required this.bodyBounds,
    required this.visibleBodyBounds,
    required this.contentBounds,
    required this.contentScale,
    required this.opacity,
    required this.shape,
  });

  final double separation;
  final Rect joinedBounds;
  final Rect headerBounds;
  final Rect bodyBounds;
  final Rect visibleBodyBounds;
  final Rect contentBounds;
  final double contentScale;
  final double opacity;
  final DashboardHeaderContentSeamShape shape;

  static MindUnifiedMotherCardGeometry resolve({
    required DashboardLayoutFrame frame,
    required BorderRadius headerRadius,
    required BorderRadius contentRadius,
  }) {
    Rect rect(DashboardBounds b) =>
        Rect.fromLTWH(b.left, b.top, b.width, b.height);
    final s = (1 - frame.headerExpansionProgress).clamp(0.0, 1.0).toDouble();
    final header = rect(frame.headerBounds);
    final joined = rect(
      DashboardHeaderContentMotherCardBounds.resolve(geometry: frame),
    );
    final scale = 1 + (DashboardMotionTokens.zone2CollapseScale - 1) * s;
    final width = header.width * scale;
    final left = header.center.dx - width / 2;
    final top = header.bottom + frame.zone2Shift;
    // The old Mind reveal defines the accepted collapsed zero-height endpoint.
    // Keep that endpoint, but make the whole physical rectangle continuous.
    final bottom = math.max(
      header.bottom,
      top + frame.canonicalMotherCardContentHeight * (1 - s),
    );
    final body = Rect.fromLTRB(left, top, left + width, bottom);
    final structuralGap =
        frame.zone2Bounds.top - frame.subheaderOneBounds.bottom;
    final contact = header.bottom + structuralGap * s * frame.zone2Opacity;
    final visible = Rect.fromLTRB(
      left,
      math.min(contact, bottom),
      left + width,
      bottom,
    );
    return MindUnifiedMotherCardGeometry._(
      separation: s,
      joinedBounds: joined,
      headerBounds: header,
      bodyBounds: body,
      visibleBodyBounds: visible,
      contentBounds: rect(
        frame.unifiedSubheaderBounds!,
      ).shift(Offset(0, frame.zone2Shift)),
      contentScale: frame.zone2Scale,
      opacity: frame.zone2Opacity,
      shape: DashboardHeaderContentSeamShape.resolve(
        seamless: true,
        headerRadius: headerRadius,
        contentRadius: contentRadius,
        expansionProgress: frame.headerExpansionProgress,
      ),
    );
  }
}
