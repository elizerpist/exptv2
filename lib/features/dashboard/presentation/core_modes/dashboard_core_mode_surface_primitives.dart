import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import 'dashboard_header_visual_engine.dart';

class DashboardCoreModeFramePosition extends StatelessWidget {
  const DashboardCoreModeFramePosition({
    super.key,
    required this.bounds,
    required this.child,
  });

  final DashboardBounds bounds;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: bounds.left,
    top: bounds.top,
    width: bounds.width,
    height: bounds.height,
    child: child,
  );
}

class DashboardCoreModeCascadeCard extends StatelessWidget {
  const DashboardCoreModeCascadeCard({
    super.key,
    required this.bounds,
    required this.motion,
    required this.semanticKey,
    this.content,
    this.showPlaceholderSurface = true,
    this.clipOpaqueContentDuringReveal = false,
    this.contentVerticalInputOverflow = 0,
    this.contentVerticalOffset = 0,
    this.borderSurface = DashboardBorderSurface.balanceContent,
  });

  final DashboardBounds bounds;
  final CascadedCardMotion motion;
  final Key semanticKey;
  final Widget? content;
  final bool showPlaceholderSurface;

  /// A full authored content card must not become a neutral-grey slab merely
  /// because a partially transparent white material is composited over the
  /// moving Header/background. Budget Card2 opts into this reveal treatment:
  /// it stays opaque wherever it is visible and the cascade reveals its
  /// actual bounds by clipping. Placeholder/other mode cards retain their
  /// existing opacity choreography.
  final bool clipOpaqueContentDuringReveal;
  final double contentVerticalInputOverflow;

  /// An authored composition offset for a visual/input surface that is
  /// intentionally taller than its structural subheader. The enclosing
  /// positioned/hit-test parent moves with its content; callers must not use
  /// a paint-only transform for interactive rails.
  final double contentVerticalOffset;
  final DashboardBorderSurface borderSurface;

  @override
  Widget build(BuildContext context) {
    assert(contentVerticalInputOverflow >= 0);
    assert(contentVerticalOffset >= 0);
    final overflow = contentVerticalInputOverflow;
    final expandedInputSurface = !showPlaceholderSurface && overflow > 0;
    return Positioned(
      left: motion.left,
      right: motion.right,
      // The scaled top adjustment keeps the visual 72px card/avatars at the
      // exact existing coordinates while the input parent covers their 112px
      // selected-shell composition.
      top:
          motion.top -
          overflow * motion.scale +
          contentVerticalOffset * motion.scale,
      height: bounds.height + overflow * 2,
      child: IgnorePointer(
        ignoring: motion.progress < .98,
        child: Opacity(
          opacity: clipOpaqueContentDuringReveal && motion.progress > 0
              ? 1
              : motion.opacity,
          child: Transform.scale(
            scale: motion.scale,
            alignment: Alignment.topCenter,
            child: _DashboardCascadeRevealClip(
              progress: clipOpaqueContentDuringReveal ? motion.progress : 1,
              child: expandedInputSurface
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          top: overflow,
                          left: 0,
                          right: 0,
                          height: bounds.height,
                          child: KeyedSubtree(
                            key: semanticKey,
                            child: const SizedBox.expand(),
                          ),
                        ),
                        content ?? const SizedBox.expand(),
                      ],
                    )
                  : showPlaceholderSurface
                  ? Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        DashboardPlaceholderCard(
                          bounds: bounds,
                          fillParent: true,
                          semanticKey: semanticKey,
                          borderSurface: borderSurface,
                        ),
                        ?content,
                      ],
                    )
                  : KeyedSubtree(
                      key: semanticKey,
                      child: content ?? const SizedBox.expand(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps Card2's authored material physically opaque during a cascade while
/// revealing only the real portion of the card. This avoids alpha-compositing
/// a white full-card surface into an unrelated grey rectangle at intermediate
/// header-collapse progress.
final class _DashboardCascadeRevealClip extends StatelessWidget {
  const _DashboardCascadeRevealClip({
    required this.progress,
    required this.child,
  });

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (progress >= 1) return child;
    return ClipRect(
      clipper: _DashboardCascadeRevealClipper(progress),
      child: child,
    );
  }
}

final class _DashboardCascadeRevealClipper extends CustomClipper<Rect> {
  const _DashboardCascadeRevealClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * progress.clamp(0.0, 1.0));

  @override
  bool shouldReclip(covariant _DashboardCascadeRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}

class DashboardCoreModeOpacityPosition extends StatelessWidget {
  const DashboardCoreModeOpacityPosition({
    super.key,
    required this.bounds,
    required this.opacity,
    required this.child,
    this.offset = Offset.zero,
    this.scale = 1,
  });

  final DashboardBounds bounds;
  final double opacity;
  final Widget child;
  final Offset offset;
  final double scale;

  @override
  Widget build(BuildContext context) => DashboardCoreModeFramePosition(
    bounds: bounds,
    child: Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: child,
        ),
      ),
    ),
  );
}

class DashboardCoreModeHeaderScaffold extends StatelessWidget {
  const DashboardCoreModeHeaderScaffold({
    super.key,
    required this.bounds,
    required this.surfaceColor,
    required this.headerKey,
    required this.labelKey,
    required this.label,
    this.labelContent,
    this.visualController,
    this.visualFrameListenable,
    this.detail,
    this.detailLeft = 16,
    this.detailRight,
    this.detailTop,
    this.detailBottom = 15,
  });

  final DashboardBounds bounds;
  final Color surfaceColor;
  final Key headerKey;
  final Key labelKey;
  final String label;
  final Widget? labelContent;
  final DashboardHeaderVisualController? visualController;
  final ValueListenable<DashboardHeaderVisualFrame>? visualFrameListenable;
  final Widget? detail;
  final double detailLeft;
  final double? detailRight;
  final double? detailTop;
  final double? detailBottom;

  @override
  Widget build(BuildContext context) {
    final borderRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.header,
          size: Size(bounds.width, bounds.height),
        );
    return DashboardCoreModeFramePosition(
      bounds: bounds,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeaderPhysicalShell(
            bounds: bounds,
            semanticKey: headerKey,
            surfaceColor: surfaceColor,
            controller: visualController,
            visualFrameListenable: visualFrameListenable,
            borderRadius: borderRadius,
          ),
          Positioned(
            top: 12,
            right: visualController == null ? 14 : 62,
            child:
                labelContent ??
                Text(
                  label,
                  key: labelKey,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
          ),
          if (detail case final detail?)
            Positioned(
              left: detailLeft,
              right: detailRight,
              top: detailTop,
              bottom: detailBottom,
              child: detail,
            ),
        ],
      ),
    );
  }
}

final class _HeaderPhysicalShell extends StatelessWidget {
  const _HeaderPhysicalShell({
    required this.bounds,
    required this.semanticKey,
    required this.surfaceColor,
    required this.controller,
    required this.visualFrameListenable,
    required this.borderRadius,
  });

  final DashboardBounds bounds;
  final Key semanticKey;
  final Color surfaceColor;
  final DashboardHeaderVisualController? controller;
  final ValueListenable<DashboardHeaderVisualFrame>? visualFrameListenable;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final visualController = controller;
    final frames = visualFrameListenable;
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.header);
    final border = DashboardBorderScope.profileOf(
      context,
    ).borderFor(DashboardBorderSurface.header);
    if (visualController == null || frames == null) {
      return DashboardPlaceholderCard(
        bounds: bounds,
        fillParent: true,
        semanticKey: semanticKey,
        surfaceColor: surfaceColor,
        cornerFamily: DashboardCornerSurfaceFamily.header,
      );
    }
    return SizedBox.expand(
      key: semanticKey,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Layer 1: card shadow and border keep their existing geometry.
          FluviRoundedBox(
            color: Colors.transparent,
            borderRadius: borderRadius,
            boxShadow: depth.outerShadows,
            child: const SizedBox.expand(),
          ),
          // Layer 2: only this clipped painter listens to the shared ticker.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: ValueListenableBuilder<DashboardHeaderVisualFrame>(
                  valueListenable: frames,
                  builder: (context, frame, child) =>
                      DashboardHeaderVisualPaintLayer(
                        controller: visualController,
                        frame: frame,
                        child: const SizedBox.expand(),
                      ),
                ),
              ),
            ),
          ),
          // The Reference3D white source inner shadow cannot be placed as a
          // full DecoratedBox over a coloured animated Header: that washes out
          // the palette. This painter keeps the source highlight as an
          // edge-only ring; the animated layer remains the sole fill owner.
          if (depth.innerShadows.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(
                key: const ValueKey<String>('dashboard-header-depth-highlight'),
                painter: _HeaderDepthHighlightPainter(
                  borderRadius: borderRadius,
                  shadows: depth.innerShadows,
                ),
              ),
            ),
          // Keep the physical card border above dynamically-painted pixels.
          if (border != null)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: border,
                  borderRadius: borderRadius,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// An edge-masked rendition of the source-defined inner highlight for coloured
/// Header palettes. It keeps each source [BoxShadow]'s paint, blur style,
/// spread and offset, while the mask prevents an opaque white reference
/// surface from taking ownership of Fluvi's animated Header fill.
final class _HeaderDepthHighlightPainter extends CustomPainter {
  const _HeaderDepthHighlightPainter({
    required this.borderRadius,
    required this.shadows,
  });

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(borderRadius.toRRect(rect), doAntiAlias: true);
    for (final shadow in shadows) {
      final sourceBounds = rect
          .shift(shadow.offset)
          .inflate(shadow.spreadRadius);
      final outer = borderRadius.toRRect(sourceBounds);
      // A zero-blur reference inner shadow still has one physical edge pixel;
      // nonzero blur/spread retain their authored footprint instead of being
      // normalized to a hard-coded stroke width.
      final edgeWidth = math.max(
        1.0,
        math.max(shadow.spreadRadius.abs(), shadow.blurRadius / 2),
      );
      final inner = outer.deflate(edgeWidth);
      canvas.drawDRRect(outer, inner, shadow.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeaderDepthHighlightPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.shadows != shadows;
}
