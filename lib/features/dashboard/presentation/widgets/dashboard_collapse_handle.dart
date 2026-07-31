import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';

/// Shared collapse handle that forwards supplied tap and vertical gesture intents.
class DashboardCollapseHandle extends StatelessWidget {
  const DashboardCollapseHandle({
    super.key,
    required this.bounds,
    required this.onTap,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final DashboardBounds bounds;
  final VoidCallback onTap;
  final GestureDragStartCallback? onVerticalDragStart;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bounds.width,
      height: bounds.height,
      child: GestureDetector(
        key: const ValueKey('dashboard-collapse-handle'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onVerticalDragStart: onVerticalDragStart,
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
        child: Center(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: FluviVisualTokens.border,
              borderRadius: FluviVisualTokens.pillRadius,
            ),
            child: const SizedBox(
              width: FluviVisualTokens.handleBarWidth,
              height: FluviVisualTokens.handleBarHeight,
            ),
          ),
        ),
      ),
    );
  }
}
