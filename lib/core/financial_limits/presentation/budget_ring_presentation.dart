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

/// Chooses whether a Budget semicircle shows the full semantic ramp along its
/// active strip or one material family resolved from the current health.
///
/// This is deliberately a presentation preference. Financial thresholds and
/// direction-aware health resolution remain owned by the prepared Budget
/// analysis frame.
enum BudgetProgressColorPresentation { segmentedScale, solidHealth }

@immutable
final class BudgetRingPresentationSettings {
  const BudgetRingPresentationSettings({
    this.sumRingStyle = BudgetSumRingStyle.current,
    this.healthyColorMode = BudgetHealthyColorMode.fixedGreen,
    this.progressColorPresentation =
        BudgetProgressColorPresentation.segmentedScale,
    this.showBudgetNeutralDecorativeStrip = true,
    this.showBudgetActiveProgressDecorativeStrip = true,
    this.showBudgetAnalysisInfoCards = true,
  });

  static const defaults = BudgetRingPresentationSettings();

  final BudgetSumRingStyle sumRingStyle;
  final BudgetHealthyColorMode healthyColorMode;
  final BudgetProgressColorPresentation progressColorPresentation;

  /// Shared Budget semicircle material preference. It applies to SUM and the
  /// one MONTH utilization gauge; it has no financial meaning.
  final bool showBudgetNeutralDecorativeStrip;

  /// Controls only the embedded light strip on the coloured active material.
  /// It is independent from [showBudgetNeutralDecorativeStrip].
  final bool showBudgetActiveProgressDecorativeStrip;

  /// Global visibility preference for the three scope-specific Budget
  /// analysis KPIs. The underlying KPI presentation remains available for the
  /// tap-to-reveal overlay when this is false.
  final bool showBudgetAnalysisInfoCards;

  BudgetRingPresentationSettings copyWith({
    BudgetSumRingStyle? sumRingStyle,
    BudgetHealthyColorMode? healthyColorMode,
    BudgetProgressColorPresentation? progressColorPresentation,
    bool? showBudgetNeutralDecorativeStrip,
    bool? showBudgetActiveProgressDecorativeStrip,
    bool? showBudgetAnalysisInfoCards,
  }) => BudgetRingPresentationSettings(
    sumRingStyle: sumRingStyle ?? this.sumRingStyle,
    healthyColorMode: healthyColorMode ?? this.healthyColorMode,
    progressColorPresentation:
        progressColorPresentation ?? this.progressColorPresentation,
    showBudgetNeutralDecorativeStrip:
        showBudgetNeutralDecorativeStrip ??
        this.showBudgetNeutralDecorativeStrip,
    showBudgetActiveProgressDecorativeStrip:
        showBudgetActiveProgressDecorativeStrip ??
        this.showBudgetActiveProgressDecorativeStrip,
    showBudgetAnalysisInfoCards:
        showBudgetAnalysisInfoCards ?? this.showBudgetAnalysisInfoCards,
  );

  @override
  bool operator ==(Object other) =>
      other is BudgetRingPresentationSettings &&
      other.sumRingStyle == sumRingStyle &&
      other.healthyColorMode == healthyColorMode &&
      other.progressColorPresentation == progressColorPresentation &&
      other.showBudgetNeutralDecorativeStrip ==
          showBudgetNeutralDecorativeStrip &&
      other.showBudgetActiveProgressDecorativeStrip ==
          showBudgetActiveProgressDecorativeStrip &&
      other.showBudgetAnalysisInfoCards == showBudgetAnalysisInfoCards;

  @override
  int get hashCode => Object.hash(
    sumRingStyle,
    healthyColorMode,
    progressColorPresentation,
    showBudgetNeutralDecorativeStrip,
    showBudgetActiveProgressDecorativeStrip,
    showBudgetAnalysisInfoCards,
  );
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

  void selectProgressColorPresentation(
    BudgetProgressColorPresentation presentation,
  ) {
    final next = value.copyWith(progressColorPresentation: presentation);
    if (next != value) value = next;
  }

  void setBudgetNeutralDecorativeStripVisible(bool visible) {
    final next = value.copyWith(showBudgetNeutralDecorativeStrip: visible);
    if (next != value) value = next;
  }

  void setBudgetActiveProgressDecorativeStripVisible(bool visible) {
    final next = value.copyWith(
      showBudgetActiveProgressDecorativeStrip: visible,
    );
    if (next != value) value = next;
  }

  void setBudgetAnalysisInfoCardsVisible(bool visible) {
    final next = value.copyWith(showBudgetAnalysisInfoCards: visible);
    if (next != value) value = next;
  }

  void setAnalysisInfoCardsVisible(bool visible) =>
      setBudgetAnalysisInfoCardsVisible(visible);

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

  /// Reads the stable authority without subscribing the caller to every paint
  /// preference. Layout owners can listen selectively (for example only to
  /// the info-card visibility bit), while material subtrees use [settingsOf]
  /// for their immediate repaint dependency.
  static BudgetRingPresentationController? controllerOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<BudgetRingPresentationScope>();
    return (element?.widget as BudgetRingPresentationScope?)?.notifier;
  }
}
