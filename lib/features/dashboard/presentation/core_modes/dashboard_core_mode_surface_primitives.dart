import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
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
    this.contentVerticalInputOverflow = 0,
  });

  final DashboardBounds bounds;
  final CascadedCardMotion motion;
  final Key semanticKey;
  final Widget? content;
  final bool showPlaceholderSurface;
  final double contentVerticalInputOverflow;

  @override
  Widget build(BuildContext context) {
    assert(contentVerticalInputOverflow >= 0);
    final overflow = contentVerticalInputOverflow;
    final expandedInputSurface = !showPlaceholderSurface && overflow > 0;
    return Positioned(
      left: motion.left,
      right: motion.right,
      // The scaled top adjustment keeps the visual 72px card/avatars at the
      // exact existing coordinates while the input parent covers their 112px
      // selected-shell composition.
      top: motion.top - overflow * motion.scale,
      height: bounds.height + overflow * 2,
      child: IgnorePointer(
        ignoring: motion.progress < .98,
        child: Opacity(
          opacity: motion.opacity,
          child: Transform.scale(
            scale: motion.scale,
            alignment: Alignment.topCenter,
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
    );
  }
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
            child: Text(
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
            boxShadow: DashboardShadowStyleScope.profileOf(
              context,
            ).shadowsFor(DashboardCornerSurfaceFamily.header),
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
          // Keep the physical card border above dynamically-painted pixels.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: FluviVisualTokens.border),
                ),
                borderRadius: borderRadius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
