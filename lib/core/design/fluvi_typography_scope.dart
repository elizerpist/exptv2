import 'package:flutter/widgets.dart';

import 'fluvi_global_appearance.dart';

/// Context bridge for painters and other non-Theme text owners. Ordinary
/// widgets inherit the app [Theme]; paint-time paragraph owners obtain the
/// same one global profile through this scope before they construct a cached
/// [TextPainter].
final class FluviTypographyScope extends InheritedWidget {
  const FluviTypographyScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final FluviTypographyProfile profile;

  static FluviTypographyProfile of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FluviTypographyScope>()
          ?.profile ??
      FluviTypographyProfile.app;

  @override
  bool updateShouldNotify(FluviTypographyScope oldWidget) =>
      oldWidget.profile != profile;
}
