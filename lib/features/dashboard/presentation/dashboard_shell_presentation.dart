import 'package:flutter/foundation.dart';

enum DashboardBottomNavEdgeShape { rounded, straight }

enum DashboardBottomNavTopBorder { off, thinGrey }

/// Selects between the unchanged BNB-03 raised centre and the contained,
/// horizontal-top alternative. This remains shell-local presentation state;
/// it has no navigation or destination authority.
enum DashboardBottomNavLayoutStyle { raisedFab, containedFlat }

@immutable
final class DashboardShellPresentationSettings {
  const DashboardShellPresentationSettings({
    this.bottomNavEdgeShape = DashboardBottomNavEdgeShape.rounded,
    this.bottomNavTopBorder = DashboardBottomNavTopBorder.off,
    this.bottomNavLayoutStyle = DashboardBottomNavLayoutStyle.raisedFab,
  });

  static const defaults = DashboardShellPresentationSettings();

  final DashboardBottomNavEdgeShape bottomNavEdgeShape;
  final DashboardBottomNavTopBorder bottomNavTopBorder;
  final DashboardBottomNavLayoutStyle bottomNavLayoutStyle;

  DashboardShellPresentationSettings copyWith({
    DashboardBottomNavEdgeShape? bottomNavEdgeShape,
    DashboardBottomNavTopBorder? bottomNavTopBorder,
    DashboardBottomNavLayoutStyle? bottomNavLayoutStyle,
  }) => DashboardShellPresentationSettings(
    bottomNavEdgeShape: bottomNavEdgeShape ?? this.bottomNavEdgeShape,
    bottomNavTopBorder: bottomNavTopBorder ?? this.bottomNavTopBorder,
    bottomNavLayoutStyle: bottomNavLayoutStyle ?? this.bottomNavLayoutStyle,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardShellPresentationSettings &&
      other.bottomNavEdgeShape == bottomNavEdgeShape &&
      other.bottomNavTopBorder == bottomNavTopBorder &&
      other.bottomNavLayoutStyle == bottomNavLayoutStyle;

  @override
  int get hashCode =>
      Object.hash(bottomNavEdgeShape, bottomNavTopBorder, bottomNavLayoutStyle);
}

final class DashboardShellPresentationController
    extends ValueNotifier<DashboardShellPresentationSettings> {
  DashboardShellPresentationController()
    : super(DashboardShellPresentationSettings.defaults);

  void selectBottomNavEdgeShape(DashboardBottomNavEdgeShape shape) {
    final next = value.copyWith(bottomNavEdgeShape: shape);
    if (next != value) value = next;
  }

  void selectBottomNavTopBorder(DashboardBottomNavTopBorder border) {
    final next = value.copyWith(bottomNavTopBorder: border);
    if (next != value) value = next;
  }

  void selectBottomNavLayoutStyle(DashboardBottomNavLayoutStyle style) {
    final next = value.copyWith(bottomNavLayoutStyle: style);
    if (next != value) value = next;
  }

  void reset() => value = DashboardShellPresentationSettings.defaults;
}
