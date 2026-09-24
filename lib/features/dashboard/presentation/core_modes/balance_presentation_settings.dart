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
    required this.revision,
  });

  const BalancePresentationSettings.defaults()
    : chartMode = BalanceHeaderChartMode.allTime,
      timeLabels = BalanceHeaderChartTimeLabels.visible,
      latestTransactionCardPresentation =
          BalanceLatestTransactionCardPresentation.avatarPartner,
      revision = 0;

  final BalanceHeaderChartMode chartMode;
  final BalanceHeaderChartTimeLabels timeLabels;
  final BalanceLatestTransactionCardPresentation
  latestTransactionCardPresentation;
  final int revision;

  bool get showsTimeLabels =>
      timeLabels == BalanceHeaderChartTimeLabels.visible;

  BalancePresentationSettings copyWith({
    BalanceHeaderChartMode? chartMode,
    BalanceHeaderChartTimeLabels? timeLabels,
    BalanceLatestTransactionCardPresentation? latestTransactionCardPresentation,
    int? revision,
  }) => BalancePresentationSettings(
    chartMode: chartMode ?? this.chartMode,
    timeLabels: timeLabels ?? this.timeLabels,
    latestTransactionCardPresentation:
        latestTransactionCardPresentation ??
        this.latestTransactionCardPresentation,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is BalancePresentationSettings &&
      other.chartMode == chartMode &&
      other.timeLabels == timeLabels &&
      other.latestTransactionCardPresentation ==
          latestTransactionCardPresentation &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
    chartMode,
    timeLabels,
    latestTransactionCardPresentation,
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
}
