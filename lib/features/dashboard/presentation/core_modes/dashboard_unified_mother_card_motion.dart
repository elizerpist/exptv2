import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/header_cascade_motion.dart';
import 'dashboard_core_mode_surface_primitives.dart';

/// One physical motion contract for every dashboard Mother Card. HeaderCascade
/// already consumes the master reveal; no second easing or clock is applied.
///
/// The canonical content canvas determines the lower edge, rather than a lerp
/// toward a moving, full-height modeContentBounds rectangle. Its trailing lane
/// remains part of the existing authored canvas, not a screenshot correction.
@immutable
final class DashboardUnifiedMotherCardMotion {
  const DashboardUnifiedMotherCardMotion._({
    required this.separation,
    required this.joinedBounds,
    required this.headerBounds,
    required this.attachedBodyBounds,
    required this.detachedTargetBounds,
    required this.bodyBounds,
    required this.visibleBodyBounds,
    required this.contentMotionBounds,
    required this.contentTransform,
    required this.contentScale,
    required this.bodyOpacity,
    required this.shape,
  });

  final double separation;
  final Rect joinedBounds, headerBounds, attachedBodyBounds;
  final Rect detachedTargetBounds, bodyBounds, visibleBodyBounds;
  final Rect contentMotionBounds;
  final Matrix4 contentTransform;
  final double contentScale, bodyOpacity;
  final DashboardHeaderContentSeamShape shape;
  Rect get paintBounds => headerBounds.expandToInclude(visibleBodyBounds);
  double get depthProgress => separation;
  double get borderProgress => separation;

  static Rect rect(DashboardBounds b) =>
      Rect.fromLTWH(b.left, b.top, b.width, b.height);

  static DashboardUnifiedMotherCardMotion resolve({
    required DashboardLayoutFrame frame,
    required BorderRadius headerRadius,
    required BorderRadius contentRadius,
  }) {
    final s = (1 - frame.headerExpansionProgress).clamp(0.0, 1.0).toDouble();
    final header = rect(frame.headerBounds);
    final gap = frame.motherCardGap;
    final spec = frame.motherCardCascadeGeometry;
    final lower = frame.motherCardCascade.lower;
    final expandedTop = spec.upperExpandedTop - gap;
    final attached = Rect.fromLTWH(
      header.left,
      expandedTop,
      header.width,
      frame.canonicalMotherCardContentHeight,
    );
    final canvasWidth = header.width + header.left * 2;
    ({double left, double width, double scale}) horizontal(
      CascadedCardMotion m,
    ) {
      final layoutWidth = canvasWidth - m.left - m.right;
      final width = layoutWidth * m.scale;
      return (
        left: m.left + (layoutWidth - width) / 2,
        width: width,
        scale: width / header.width,
      );
    }

    final h = horizontal(lower);
    final lowerOriginOffset = spec.upperHeight + gap;
    final cascadeTop = lower.top - lowerOriginOffset;
    final lowerShift = lower.top - spec.lowerExpandedTop;

    // This is the accepted analytical track's origin, not an interpolated
    // physical rectangle. Keeping it preserves Balance's current lower slide.
    final contentAnchor = header.bottom + (cascadeTop - header.bottom) * s;
    final contentTop = contentAnchor + lowerShift;
    final content = Rect.fromLTWH(
      h.left,
      contentTop,
      h.width,
      frame.canonicalMotherCardContentHeight * h.scale,
    );

    // The physical top follows the actual cascade immediately, closing only
    // the existing attached structural gap. The bottom follows the separately
    // moving canonical content envelope, including its authored trailing lane.
    // These distinct edges provide translation AND compression, never a
    // stationary rectangle with a height-only reveal.
    final top = cascadeTop - gap * (1 - s);
    final body = Rect.fromLTRB(
      h.left,
      top,
      h.left + h.width,
      math.max(top, content.bottom),
    );
    final collapsed = HeaderCascadeMotion.calculate(
      masterProgress: 0,
      geometry: spec,
    ).lower;
    final endH = horizontal(collapsed);
    final endTop = collapsed.top - lowerOriginOffset;
    final target = Rect.fromLTWH(
      endH.left,
      endTop,
      endH.width,
      math.max(
        0,
        collapsed.top -
            spec.lowerExpandedTop +
            frame.canonicalMotherCardContentHeight * endH.scale,
      ),
    );
    final contactGap =
        math.max(0.0, spec.upperExpandedTop - header.bottom) *
        s *
        lower.opacity;
    final visibleTop = math.min(
      body.bottom,
      math.max(body.top, header.bottom + contactGap),
    );
    final visible = Rect.fromLTRB(
      body.left,
      visibleTop,
      body.right,
      body.bottom,
    );
    final transform = Matrix4.identity()
      ..translateByDouble(
        h.left - header.left * h.scale,
        contentTop - header.bottom * h.scale,
        0,
        1,
      )
      ..scaleByDouble(h.scale, h.scale, 1, 1);
    return DashboardUnifiedMotherCardMotion._(
      separation: s,
      joinedBounds: rect(
        DashboardHeaderContentMotherCardBounds.resolve(geometry: frame),
      ),
      headerBounds: header,
      attachedBodyBounds: attached,
      detachedTargetBounds: target,
      bodyBounds: body,
      visibleBodyBounds: visible,
      contentMotionBounds: content,
      contentTransform: transform,
      contentScale: h.scale,
      bodyOpacity: lower.opacity,
      shape: DashboardHeaderContentSeamShape.resolve(
        seamless: true,
        headerRadius: headerRadius,
        contentRadius: contentRadius,
        expansionProgress: 1 - s,
      ),
    );
  }

  /// The existing Balance lower-content matrix is intentionally independent
  /// of the corrected physical edges. Non-default body orders retain their
  /// own structural content allocation, with no geometry feedback loop.
  static Matrix4 acceptedBalanceContentTransform(DashboardLayoutFrame frame) {
    final s = 1 - frame.headerExpansionProgress;
    final header = frame.headerBounds;
    final lower = frame.lowerCardMotion ?? frame.motherCardCascade.lower;
    final layoutWidth =
        header.width + 2 * header.left - lower.left - lower.right;
    final width = layoutWidth * lower.scale;
    final scale = width / header.width;
    final left = lower.left + (layoutWidth - width) / 2;
    final targetTop =
        lower.top + frame.modeContentBounds.top - frame.zone2Bounds.top;
    final anchor = header.bottom + (targetTop - header.bottom) * s;
    return Matrix4.identity()
      ..translateByDouble(
        left - header.left * scale,
        anchor + frame.zone2Shift - header.bottom * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }
}

/// The clipping topology is constant for every progress value. A caller may
/// disable the clip for an existing split presentation without reparenting its
/// interactive subtree. Header stays a later foreground sibling.
class DashboardMotherCardContentClip extends StatelessWidget {
  const DashboardMotherCardContentClip({
    super.key,
    required this.bounds,
    required this.radius,
    required this.child,
    this.enabled = true,
    this.trailingFadeExtent = 0,
  });
  final Rect bounds;
  final BorderRadius radius;
  final Widget child;
  final bool enabled;
  final double trailingFadeExtent;
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ClipPath(
      clipBehavior: enabled ? Clip.hardEdge : Clip.none,
      clipper: _MotherCardBodyClipper(bounds, radius),
      child: _MotherCardTrailingFade(
        bottom: bounds.bottom,
        extent: enabled ? trailingFadeExtent : 0,
        child: Stack(clipBehavior: Clip.none, children: [child]),
      ),
    ),
  );
}

final class _MotherCardBodyClipper extends CustomClipper<Path> {
  const _MotherCardBodyClipper(this.bounds, this.radius);
  final Rect bounds;
  final BorderRadius radius;
  @override
  Path getClip(Size size) => Path()..addRRect(radius.toRRect(bounds));
  @override
  bool shouldReclip(_MotherCardBodyClipper old) =>
      old.bounds != bounds || old.radius != radius;
}

/// Paint-only edge attenuation. The authored content transform and its own
/// opacity remain untouched; only ink approaching the physical clip fades.
class _MotherCardTrailingFade extends SingleChildRenderObjectWidget {
  const _MotherCardTrailingFade({
    required this.bottom,
    required this.extent,
    required super.child,
  });
  final double bottom, extent;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMotherCardTrailingFade(bottom, extent);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMotherCardTrailingFade renderObject,
  ) => renderObject.update(bottom, extent);
}

class _RenderMotherCardTrailingFade extends RenderProxyBox {
  _RenderMotherCardTrailingFade(this._bottom, this._extent);
  double _bottom, _extent;
  void update(double bottom, double extent) {
    if (_bottom == bottom && _extent == extent) return;
    final wasComposited = alwaysNeedsCompositing;
    _bottom = bottom;
    _extent = extent;
    if (wasComposited != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _extent > 0;
  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;
  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || _extent <= 0) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    layer ??= ShaderMaskLayer();
    layer!
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, _bottom - _extent, size.width, _extent))
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    context.pushLayer(layer!, super.paint, offset);
  }
}
