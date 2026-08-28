import 'package:flutter/material.dart';

/// SUM-only current-indicator variants. The other three scope strategies stay
/// fixed regardless of this presentation preference.
enum BudgetSumRingStyle {
  current,
  coloredScaleWhiteArc,
  coloredScaleMovingSphere,
}

/// Controls visual healthy material where healthy is otherwise canonical green.
enum BudgetHealthyColorMode { fixedGreen, targetAccent }

@immutable
final class BudgetRingPresentationSettings {
  const BudgetRingPresentationSettings({
    this.sumRingStyle = BudgetSumRingStyle.current,
    this.healthyColorMode = BudgetHealthyColorMode.fixedGreen,
  });

  static const defaults = BudgetRingPresentationSettings();

  final BudgetSumRingStyle sumRingStyle;
  final BudgetHealthyColorMode healthyColorMode;

  BudgetRingPresentationSettings copyWith({
    BudgetSumRingStyle? sumRingStyle,
    BudgetHealthyColorMode? healthyColorMode,
  }) => BudgetRingPresentationSettings(
    sumRingStyle: sumRingStyle ?? this.sumRingStyle,
    healthyColorMode: healthyColorMode ?? this.healthyColorMode,
  );

  @override
  bool operator ==(Object other) =>
      other is BudgetRingPresentationSettings &&
      other.sumRingStyle == sumRingStyle &&
      other.healthyColorMode == healthyColorMode;

  @override
  int get hashCode => Object.hash(sumRingStyle, healthyColorMode);
}

final class BudgetRingPresentationController
    extends ValueNotifier<BudgetRingPresentationSettings> {
  BudgetRingPresentationController()
    : super(BudgetRingPresentationSettings.defaults);

  void selectSumRingStyle(BudgetSumRingStyle style) {
    final next = value.copyWith(sumRingStyle: style);
    if (next != value) value = next;
  }

  void selectHealthyColorMode(BudgetHealthyColorMode mode) {
    final next = value.copyWith(healthyColorMode: mode);
    if (next != value) value = next;
  }

  void reset() => value = BudgetRingPresentationSettings.defaults;
}

abstract final class BudgetHealthyVisualColorResolver {
  static Color resolve({
    required BudgetHealthyColorMode mode,
    required Color targetAccent,
    required Color fixedGreen,
  }) => switch (mode) {
    BudgetHealthyColorMode.fixedGreen => fixedGreen,
    BudgetHealthyColorMode.targetAccent => targetAccent,
  };
}

/// A core visual scope lets shared avatar artwork consume resolved
/// presentation preferences without depending on the Dashboard feature layer.
final class BudgetRingPresentationScope
    extends InheritedNotifier<BudgetRingPresentationController> {
  const BudgetRingPresentationScope({
    super.key,
    required BudgetRingPresentationController controller,
    required super.child,
  }) : super(notifier: controller);

  static BudgetRingPresentationSettings settingsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<BudgetRingPresentationScope>()
          ?.notifier
          ?.value ??
      BudgetRingPresentationSettings.defaults;
}
