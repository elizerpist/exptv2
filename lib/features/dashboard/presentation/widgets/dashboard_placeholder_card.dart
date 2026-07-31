import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';

/// Neutral, bounds-driven placeholder surface for the data-free dashboard.
class DashboardPlaceholderCard extends StatelessWidget {
  const DashboardPlaceholderCard({
    super.key,
    required this.bounds,
    required this.radius,
    required this.semanticKey,
  });

  final DashboardBounds bounds;
  final BorderRadiusGeometry radius;
  final Key semanticKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: semanticKey,
      width: bounds.width,
      height: bounds.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FluviVisualTokens.surface,
          border: Border.all(color: FluviVisualTokens.border),
          borderRadius: radius,
        ),
      ),
    );
  }
}
