import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class SpendeeAcrylicSurface extends StatelessWidget {
  const SpendeeAcrylicSurface({
    super.key,
    required this.fluentKey,
    required this.borderRadius,
    required this.child,
    this.highlightKey,
  });

  final Key fluentKey;
  final Key? highlightKey;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final materialTextStyle = DefaultTextStyle.of(context).style;
    final materialIconTheme = IconTheme.of(context);

    return fluent.FluentTheme(
      data: fluent.FluentThemeData(
        brightness: Brightness.light,
        acrylicBackgroundColor: const Color(0xFFEAFBFF),
        shadowColor: const Color(0xFF103040),
      ),
      child: fluent.Acrylic(
        key: fluentKey,
        tint: const Color(0xFFE8FBFF),
        tintAlpha: .58,
        luminosityAlpha: .42,
        blurAmount: 24,
        elevation: 12,
        shadowColor: const Color(0xFF102436),
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            DefaultTextStyle(
              style: materialTextStyle,
              child: IconTheme(data: materialIconTheme, child: child),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: highlightKey,
                  decoration: _acrylicHighlightDecoration(borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _acrylicHighlightDecoration(double radius) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xB8FFFFFF), Color(0x42FFFFFF), Color(0x1A3EC7E6)],
      stops: [0, .48, 1],
    ),
    border: Border.all(color: const Color(0xB8FFFFFF), width: 1.35),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F2B3D).withValues(alpha: .14),
        offset: const Offset(0, 10),
        blurRadius: 30,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: .42),
        offset: const Offset(-1, -1),
        blurRadius: 3,
      ),
    ],
  );
}
