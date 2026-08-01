import 'package:flutter/material.dart';

import 'dashboard_mode_palette.dart';

/// The default surface primitive for Fluvi's non-circular components.
///
/// Component-specific dimensions belong to the caller. The shape is owned by
/// this primitive so a generic surface cannot silently become a capsule.
class FluviRoundedBox extends StatelessWidget {
  const FluviRoundedBox({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.border,
    this.boxShadow,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  BoxDecoration get decoration => BoxDecoration(
    color: color,
    gradient: gradient,
    border: border,
    borderRadius: borderRadius ?? FluviVisualTokens.roundedBoxRadius,
    boxShadow: boxShadow ?? FluviVisualTokens.cardSurfaceShadows,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}
