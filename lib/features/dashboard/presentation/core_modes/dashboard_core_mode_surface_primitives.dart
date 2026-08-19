import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../widgets/dashboard_placeholder_card.dart';

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
    this.detail,
  });

  final DashboardBounds bounds;
  final Color surfaceColor;
  final Key headerKey;
  final Key labelKey;
  final String label;
  final Widget? detail;

  @override
  Widget build(BuildContext context) => DashboardCoreModeFramePosition(
    bounds: bounds,
    child: Stack(
      fit: StackFit.expand,
      children: [
        DashboardPlaceholderCard(
          bounds: bounds,
          fillParent: true,
          semanticKey: headerKey,
          surfaceColor: surfaceColor,
        ),
        Positioned(
          top: 12,
          right: 14,
          child: Text(
            label,
            key: labelKey,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ),
        if (detail case final detail?)
          Positioned(left: 16, bottom: 15, child: detail),
      ],
    ),
  );
}
