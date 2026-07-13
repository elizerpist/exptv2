import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'spendee_header_glass_painters.dart';
import 'spendee_header_visual_spec.dart';

export 'spendee_header_glass_painters.dart';

/// Exact Flutter owner for the Color Lab common-header paint graph.
class SpendeeHeaderGlassSurface extends StatelessWidget {
  const SpendeeHeaderGlassSurface({
    super.key,
    required this.spec,
    required this.child,
  });

  final SpendeeHeaderVisualSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = spec.glass;
    final radius = BorderRadius.circular(glass.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: radius,
        boxShadow: glass.cardShadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: glass.backdropBlurSigma,
            sigmaY: glass.backdropBlurSigma,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                key: const ValueKey('spendee-test-header-graphic-opacity'),
                opacity: spec.graphicLayerOpacity,
                child: CustomPaint(
                  key: const ValueKey('spendee-test-header-glass-layer'),
                  painter: SpendeeHeaderGlassPainter(spec),
                ),
              ),
              KeyedSubtree(
                key: const ValueKey('spendee-test-header-semantic-content'),
                child: child,
              ),
              IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('spendee-test-header-foreground-border'),
                  painter: SpendeeHeaderBorderPainter(spec),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpendeeHeaderOuterGlowSurface extends StatelessWidget {
  const SpendeeHeaderOuterGlowSurface({super.key, required this.spec});

  final SpendeeHeaderVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: SpendeeHeaderOuterGlowPainter(spec)),
    );
  }
}

class SpendeeHeaderMenuButton extends StatelessWidget {
  const SpendeeHeaderMenuButton({
    super.key,
    required this.spec,
    required this.onPressed,
  });

  final SpendeeHeaderVisualSpec spec;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final menu = spec.menu;
    return RepaintBoundary(
      key: const ValueKey('spendee-test-header-menu-golden-boundary'),
      child: GestureDetector(
        key: const ValueKey('spendee-test-header-menu-button'),
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: menu.size,
          child: CustomPaint(
            painter: SpendeeHeaderMenuSurfacePainter(menu),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < 3; index += 1) ...[
                    if (index > 0) SizedBox(height: menu.barGap),
                    Container(
                      key: ValueKey('spendee-test-header-menu-bar-$index'),
                      width: menu.barWidth,
                      height: menu.barHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(menu.barRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: menu.barGradientColors,
                          stops: menu.barGradientStops,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpendeeHeaderHandle extends StatelessWidget {
  const SpendeeHeaderHandle({
    super.key,
    required this.spec,
    required this.onVerticalDragStart,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
  });

  final SpendeeHeaderVisualSpec spec;
  final GestureDragStartCallback onVerticalDragStart;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    final handle = spec.handle;
    return GestureDetector(
      key: const ValueKey('spendee-test-header-handle'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: handle.bottom,
            child: Center(
              child: Container(
                width: handle.width,
                height: handle.height,
                decoration: BoxDecoration(
                  color: handle.fillColor,
                  borderRadius: BorderRadius.circular(handle.radius),
                  boxShadow: <BoxShadow>[handle.outerShadow],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(handle.radius),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      color: handle.topInsetColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
