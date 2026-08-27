import 'package:flutter/foundation.dart';

enum DashboardBottomNavEdgeShape { rounded, straight }

enum DashboardBottomNavTopBorder { off, thinGrey }

@immutable
final class DashboardShellPresentationSettings {
  const DashboardShellPresentationSettings({
    this.bottomNavEdgeShape = DashboardBottomNavEdgeShape.rounded,
    this.bottomNavTopBorder = DashboardBottomNavTopBorder.off,
  });

  static const defaults = DashboardShellPresentationSettings();

  final DashboardBottomNavEdgeShape bottomNavEdgeShape;
  final DashboardBottomNavTopBorder bottomNavTopBorder;

  DashboardShellPresentationSettings copyWith({
    DashboardBottomNavEdgeShape? bottomNavEdgeShape,
    DashboardBottomNavTopBorder? bottomNavTopBorder,
  }) => DashboardShellPresentationSettings(
    bottomNavEdgeShape: bottomNavEdgeShape ?? this.bottomNavEdgeShape,
    bottomNavTopBorder: bottomNavTopBorder ?? this.bottomNavTopBorder,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardShellPresentationSettings &&
      other.bottomNavEdgeShape == bottomNavEdgeShape &&
      other.bottomNavTopBorder == bottomNavTopBorder;

  @override
  int get hashCode => Object.hash(bottomNavEdgeShape, bottomNavTopBorder);
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

  void reset() => value = DashboardShellPresentationSettings.defaults;
}
