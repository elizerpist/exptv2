import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_rounded_box.dart';

/// Neutral, bounds-driven placeholder surface for the data-free dashboard.
class DashboardPlaceholderCard extends StatelessWidget {
  const DashboardPlaceholderCard({
    super.key,
    required this.bounds,
    required this.semanticKey,
    this.surfaceColor = FluviVisualTokens.surface,
  });

  final DashboardBounds bounds;
  final Key semanticKey;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: semanticKey,
      width: bounds.width,
      height: bounds.height,
      child: FluviRoundedBox(
        color: surfaceColor,
        border: Border.all(color: FluviVisualTokens.border),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Bounds-driven indicator strip for an otherwise empty Zone2 placeholder.
class DashboardPlaceholderDots extends StatelessWidget {
  const DashboardPlaceholderDots({super.key, required this.bounds});

  final DashboardBounds bounds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('dashboard-zone2-indicators'),
      width: bounds.width,
      height: bounds.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _DashboardPlaceholderDot(active: true),
          _DashboardPlaceholderDot(),
          _DashboardPlaceholderDot(),
        ],
      ),
    );
  }
}

class _DashboardPlaceholderDot extends StatelessWidget {
  const _DashboardPlaceholderDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FluviVisualTokens.dotSize,
      height: FluviVisualTokens.dotSize,
      margin: const EdgeInsets.symmetric(
        horizontal: FluviVisualTokens.dotHorizontalInset,
      ),
      decoration: BoxDecoration(
        gradient: active ? FluviVisualTokens.appHighlightGradient : null,
        color: active ? null : FluviVisualTokens.placeholderDotInactive,
        shape: BoxShape.circle,
      ),
    );
  }
}
