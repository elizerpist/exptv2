import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';

enum DashboardBudgetHeaderForeground { white, black }

@immutable
final class DashboardBudgetHeaderPresentationSettings {
  const DashboardBudgetHeaderPresentationSettings({
    this.partitionHeightPercent = 0,
    this.foreground = DashboardBudgetHeaderForeground.black,
  }) : assert(partitionHeightPercent >= 0 && partitionHeightPercent <= 100);

  static const defaults = DashboardBudgetHeaderPresentationSettings();

  final double partitionHeightPercent;
  final DashboardBudgetHeaderForeground foreground;

  DashboardBudgetHeaderPresentationSettings copyWith({
    double? partitionHeightPercent,
    DashboardBudgetHeaderForeground? foreground,
  }) => DashboardBudgetHeaderPresentationSettings(
    partitionHeightPercent:
        partitionHeightPercent ?? this.partitionHeightPercent,
    foreground: foreground ?? this.foreground,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardBudgetHeaderPresentationSettings &&
      other.partitionHeightPercent == partitionHeightPercent &&
      other.foreground == foreground;

  @override
  int get hashCode => Object.hash(partitionHeightPercent, foreground);
}

/// Paint/layout profile for Budget Header controls. The slider changes only
/// the partition lane thickness around its authored centerline.
@immutable
final class DashboardBudgetHeaderPresentationProfile {
  const DashboardBudgetHeaderPresentationProfile(this.settings);

  static const baselinePartitionThickness = 7.0;

  final DashboardBudgetHeaderPresentationSettings settings;

  double get partitionThickness =>
      baselinePartitionThickness * (1 + settings.partitionHeightPercent / 100);

  /// The baseline lane ends 4px above the Header's physical lower edge. As
  /// the painted lane grows, give half of that extra extent to the lower side
  /// so its authored baseline centerline stays fixed (7px → 14px leaves a
  /// safe 0.5px lower clearance rather than enlarging the Header).
  double get partitionBottomInset =>
      4 - (partitionThickness - baselinePartitionThickness) / 2;

  Color get foreground => switch (settings.foreground) {
    DashboardBudgetHeaderForeground.white => FluviVisualTokens.textOnAction,
    DashboardBudgetHeaderForeground.black => FluviVisualTokens.textPrimary,
  };
}

final class DashboardBudgetHeaderPresentationController
    extends ValueNotifier<DashboardBudgetHeaderPresentationSettings> {
  DashboardBudgetHeaderPresentationController()
    : super(DashboardBudgetHeaderPresentationSettings.defaults);

  void setPartitionHeightPercent(double percent) {
    final next = value.copyWith(
      partitionHeightPercent: percent.clamp(0.0, 100.0).toDouble(),
    );
    if (next != value) value = next;
  }

  void selectForeground(DashboardBudgetHeaderForeground foreground) {
    final next = value.copyWith(foreground: foreground);
    if (next != value) value = next;
  }

  void reset() => value = DashboardBudgetHeaderPresentationSettings.defaults;
}

final class DashboardBudgetHeaderPresentationScope
    extends InheritedNotifier<DashboardBudgetHeaderPresentationController> {
  const DashboardBudgetHeaderPresentationScope({
    super.key,
    required DashboardBudgetHeaderPresentationController controller,
    required super.child,
  }) : super(notifier: controller);

  static DashboardBudgetHeaderPresentationProfile profileOf(
    BuildContext context,
  ) => DashboardBudgetHeaderPresentationProfile(
    context
            .dependOnInheritedWidgetOfExactType<
              DashboardBudgetHeaderPresentationScope
            >()
            ?.notifier
            ?.value ??
        DashboardBudgetHeaderPresentationSettings.defaults,
  );
}
