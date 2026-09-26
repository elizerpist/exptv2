import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_history_projection.dart';

/// Static axis-label visibility for Balance's already-published Header trend.
/// It is deliberately independent from Mind's equivalent presentation choice.
enum BalanceHeaderChartTimeLabels {
  hidden,
  visible;

  String get tunerLabel => switch (this) {
    BalanceHeaderChartTimeLabels.hidden => 'KI',
    BalanceHeaderChartTimeLabels.visible => 'BE',
  };
}

/// Render-only alternatives for the selected Balance Latest carousel card.
/// Both variants consume the same immutable scoped transaction; neither can
/// alter Balance selection, financial values or carousel motion.
enum BalanceLatestTransactionCardPresentation {
  avatarPartner,
  threeLine;

  String get tunerLabel => switch (this) {
    BalanceLatestTransactionCardPresentation.avatarPartner =>
      'Avatar + partner',
    BalanceLatestTransactionCardPresentation.threeLine => '3 soros',
  };
}

/// Session-only alternatives over the immutable all-time Balance history.
/// Financial totals and the latest transaction are never settings-dependent.
@immutable
final class BalancePresentationSettings {
  const BalancePresentationSettings({
    required this.chartMode,
    required this.timeLabels,
    required this.latestTransactionCardPresentation,
    required this.balanceCarouselBorderEnabled,
    required this.balanceCarouselBorderOpacity,
    required this.balanceCarouselBackgroundOpacity,
    required this.balanceCarouselWaveOpacity,
    required this.balanceCarouselTintedBackgroundEnabled,
    required this.balanceCarouselWaveAnimationEnabled,
    required this.balanceContentCardColoredBorderEnabled,
    required this.balanceContentCardBorderOpacity,
    required this.revision,
  }) : assert(
         balanceCarouselBorderOpacity >= 0 && balanceCarouselBorderOpacity <= 1,
       ),
       assert(
         balanceCarouselBackgroundOpacity >= 0 &&
             balanceCarouselBackgroundOpacity <= 1,
       ),
       assert(
         balanceCarouselWaveOpacity >= 0 && balanceCarouselWaveOpacity <= 1,
       ),
       assert(
         balanceContentCardBorderOpacity >= 0 &&
             balanceContentCardBorderOpacity <= 1,
       );

  const BalancePresentationSettings.defaults()
    : chartMode = BalanceHeaderChartMode.compound,
      timeLabels = BalanceHeaderChartTimeLabels.hidden,
      latestTransactionCardPresentation =
          BalanceLatestTransactionCardPresentation.avatarPartner,
      balanceCarouselBorderEnabled = true,
      balanceCarouselBorderOpacity = 1,
      balanceCarouselBackgroundOpacity = 1,
      balanceCarouselWaveOpacity = 1,
      balanceCarouselTintedBackgroundEnabled = true,
      balanceCarouselWaveAnimationEnabled = false,
      balanceContentCardColoredBorderEnabled = false,
      balanceContentCardBorderOpacity = 1,
      revision = 0;

  final BalanceHeaderChartMode chartMode;
  final BalanceHeaderChartTimeLabels timeLabels;
  final BalanceLatestTransactionCardPresentation
  latestTransactionCardPresentation;
  final bool balanceCarouselBorderEnabled;
  final double balanceCarouselBorderOpacity;
  final double balanceCarouselBackgroundOpacity;
  final double balanceCarouselWaveOpacity;
  final bool balanceCarouselTintedBackgroundEnabled;
  final bool balanceCarouselWaveAnimationEnabled;
  final bool balanceContentCardColoredBorderEnabled;
  final double balanceContentCardBorderOpacity;
  final int revision;

  bool get showsTimeLabels =>
      timeLabels == BalanceHeaderChartTimeLabels.visible;

  BalancePresentationSettings copyWith({
    BalanceHeaderChartMode? chartMode,
    BalanceHeaderChartTimeLabels? timeLabels,
    BalanceLatestTransactionCardPresentation? latestTransactionCardPresentation,
    bool? balanceCarouselBorderEnabled,
    double? balanceCarouselBorderOpacity,
    double? balanceCarouselBackgroundOpacity,
    double? balanceCarouselWaveOpacity,
    bool? balanceCarouselTintedBackgroundEnabled,
    bool? balanceCarouselWaveAnimationEnabled,
    bool? balanceContentCardColoredBorderEnabled,
    double? balanceContentCardBorderOpacity,
    int? revision,
  }) => BalancePresentationSettings(
    chartMode: chartMode ?? this.chartMode,
    timeLabels: timeLabels ?? this.timeLabels,
    latestTransactionCardPresentation:
        latestTransactionCardPresentation ??
        this.latestTransactionCardPresentation,
    balanceCarouselBorderEnabled:
        balanceCarouselBorderEnabled ?? this.balanceCarouselBorderEnabled,
    balanceCarouselBorderOpacity:
        balanceCarouselBorderOpacity ?? this.balanceCarouselBorderOpacity,
    balanceCarouselBackgroundOpacity:
        balanceCarouselBackgroundOpacity ??
        this.balanceCarouselBackgroundOpacity,
    balanceCarouselWaveOpacity:
        balanceCarouselWaveOpacity ?? this.balanceCarouselWaveOpacity,
    balanceCarouselTintedBackgroundEnabled:
        balanceCarouselTintedBackgroundEnabled ??
        this.balanceCarouselTintedBackgroundEnabled,
    balanceCarouselWaveAnimationEnabled:
        balanceCarouselWaveAnimationEnabled ??
        this.balanceCarouselWaveAnimationEnabled,
    balanceContentCardColoredBorderEnabled:
        balanceContentCardColoredBorderEnabled ??
        this.balanceContentCardColoredBorderEnabled,
    balanceContentCardBorderOpacity:
        balanceContentCardBorderOpacity ?? this.balanceContentCardBorderOpacity,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is BalancePresentationSettings &&
      other.chartMode == chartMode &&
      other.timeLabels == timeLabels &&
      other.latestTransactionCardPresentation ==
          latestTransactionCardPresentation &&
      other.balanceCarouselBorderEnabled == balanceCarouselBorderEnabled &&
      other.balanceCarouselBorderOpacity == balanceCarouselBorderOpacity &&
      other.balanceCarouselBackgroundOpacity ==
          balanceCarouselBackgroundOpacity &&
      other.balanceCarouselWaveOpacity == balanceCarouselWaveOpacity &&
      other.balanceCarouselTintedBackgroundEnabled ==
          balanceCarouselTintedBackgroundEnabled &&
      other.balanceCarouselWaveAnimationEnabled ==
          balanceCarouselWaveAnimationEnabled &&
      other.balanceContentCardColoredBorderEnabled ==
          balanceContentCardColoredBorderEnabled &&
      other.balanceContentCardBorderOpacity ==
          balanceContentCardBorderOpacity &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
    chartMode,
    timeLabels,
    latestTransactionCardPresentation,
    balanceCarouselBorderEnabled,
    balanceCarouselBorderOpacity,
    balanceCarouselBackgroundOpacity,
    balanceCarouselWaveOpacity,
    balanceCarouselTintedBackgroundEnabled,
    balanceCarouselWaveAnimationEnabled,
    balanceContentCardColoredBorderEnabled,
    balanceContentCardBorderOpacity,
    revision,
  );
}

/// The one Dashboard-lifetime presentation owner for Balance-only chart and
/// carousel alternatives. It owns no Query, financial data or shared motion.
final class BalancePresentationController
    extends ValueNotifier<BalancePresentationSettings> {
  BalancePresentationController({BalancePresentationSettings? initial})
    : super(initial ?? const BalancePresentationSettings.defaults());

  void setChartMode(BalanceHeaderChartMode next) {
    final current = value;
    if (current.chartMode == next) return;
    value = current.copyWith(chartMode: next, revision: current.revision + 1);
  }

  void setTimeLabels(BalanceHeaderChartTimeLabels next) {
    final current = value;
    if (current.timeLabels == next) return;
    value = current.copyWith(timeLabels: next, revision: current.revision + 1);
  }

  void setLatestTransactionCardPresentation(
    BalanceLatestTransactionCardPresentation next,
  ) {
    final current = value;
    if (current.latestTransactionCardPresentation == next) return;
    value = current.copyWith(
      latestTransactionCardPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setBalanceCarouselBorderEnabled(bool next) {
    final current = value;
    if (current.balanceCarouselBorderEnabled == next) return;
    value = current.copyWith(
      balanceCarouselBorderEnabled: next,
      revision: current.revision + 1,
    );
  }

  void setBalanceCarouselBorderOpacity(double next) {
    final normalized = _normalizedOpacity(next);
    final current = value;
    if (current.balanceCarouselBorderOpacity == normalized) return;
    value = current.copyWith(
      balanceCarouselBorderOpacity: normalized,
      revision: current.revision + 1,
    );
  }

  void setBalanceCarouselBackgroundOpacity(double next) {
    final normalized = _normalizedOpacity(next);
    final current = value;
    if (current.balanceCarouselBackgroundOpacity == normalized) return;
    value = current.copyWith(
      balanceCarouselBackgroundOpacity: normalized,
      revision: current.revision + 1,
    );
  }

  void setBalanceCarouselWaveOpacity(double next) {
    final normalized = _normalizedOpacity(next);
    final current = value;
    if (current.balanceCarouselWaveOpacity == normalized) return;
    value = current.copyWith(
      balanceCarouselWaveOpacity: normalized,
      revision: current.revision + 1,
    );
  }

  void setBalanceCarouselTintedBackgroundEnabled(bool next) {
    final current = value;
    if (current.balanceCarouselTintedBackgroundEnabled == next) return;
    value = current.copyWith(
      balanceCarouselTintedBackgroundEnabled: next,
      revision: current.revision + 1,
    );
  }

  void setBalanceCarouselWaveAnimationEnabled(bool next) {
    final current = value;
    if (current.balanceCarouselWaveAnimationEnabled == next) return;
    value = current.copyWith(
      balanceCarouselWaveAnimationEnabled: next,
      revision: current.revision + 1,
    );
  }

  void setBalanceContentCardColoredBorderEnabled(bool next) {
    final current = value;
    if (current.balanceContentCardColoredBorderEnabled == next) return;
    value = current.copyWith(
      balanceContentCardColoredBorderEnabled: next,
      revision: current.revision + 1,
    );
  }

  void setBalanceContentCardBorderOpacity(double next) {
    final normalized = _normalizedOpacity(next);
    final current = value;
    if (current.balanceContentCardBorderOpacity == normalized) return;
    value = current.copyWith(
      balanceContentCardBorderOpacity: normalized,
      revision: current.revision + 1,
    );
  }

  double _normalizedOpacity(double value) => value.clamp(0, 1).toDouble();
}
