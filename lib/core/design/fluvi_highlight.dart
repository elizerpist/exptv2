import 'package:flutter/material.dart';

import 'dashboard_mode_palette.dart';

/// Applies the single Fluvi highlight ramp to text or icon content.
class FluviHighlightMask extends StatelessWidget {
  const FluviHighlightMask({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => FluviVisualTokens.appHighlightGradient
          .createShader(Offset.zero & bounds.size),
      child: child,
    );
  }
}
