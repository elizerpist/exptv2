import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Owns the physical system-inset paint for every Fluvi route and overlay.
///
/// Android's edge-to-edge modes ignore legacy opaque system-bar colors. The
/// white [ColoredBox] is therefore deliberately outside the safe application
/// content; [SafeArea] reserves the actual dynamic insets instead of guessing
/// a status/navigation-bar height. Dialog and bottom-sheet barriers stay in
/// the child region, leaving the system surfaces consistently white.
final class FluviSystemSurface extends StatelessWidget {
  const FluviSystemSurface({super.key, required this.child});

  final Widget child;

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
    // iOS interprets this as the brightness of the background, resulting in
    // dark status icons against the white painted system inset.
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: _overlayStyle,
    child: ColoredBox(
      key: ValueKey('fluvi-system-surface'),
      color: Colors.white,
      child: SafeArea(child: child),
    ),
  );
}
