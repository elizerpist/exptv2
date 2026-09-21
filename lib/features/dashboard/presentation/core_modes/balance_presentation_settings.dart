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

/// Session-only alternatives over the immutable all-time Balance history.
/// Financial totals and the latest transaction are never settings-dependent.
@immutable
final class BalancePresentationSettings {
  const BalancePresentationSettings({
    required this.chartMode,
    required this.timeLabels,
    required this.cardWidthBoost,
    required this.carouselSpacingAdjustment,
    required this.revision,
  }) : assert(cardWidthBoost >= 0 && cardWidthBoost <= maximumCardWidthBoost),
       assert(
         carouselSpacingAdjustment >= 0 &&
             carouselSpacingAdjustment <= maximumCarouselSpacingAdjustment,
       );

  const BalancePresentationSettings.defaults()
    : chartMode = BalanceHeaderChartMode.allTime,
      timeLabels = BalanceHeaderChartTimeLabels.visible,
      cardWidthBoost = 0,
      carouselSpacingAdjustment = 0,
      revision = 0;

  /// 0 keeps the approved current width; .30 is exactly 130% of it.
  static const maximumCardWidthBoost = .30;

  /// A positive-only local gap is safe at every width setting: it never lets
  /// an authored card outgrow its real three-slot input canvas. Zero is the
  /// existing neutral spacing; 12% remains inside the tested Balance rail.
  static const maximumCarouselSpacingAdjustment = .12;

  final BalanceHeaderChartMode chartMode;
  final BalanceHeaderChartTimeLabels timeLabels;
  final double cardWidthBoost;
  final double carouselSpacingAdjustment;
  final int revision;

  bool get showsTimeLabels =>
      timeLabels == BalanceHeaderChartTimeLabels.visible;

  BalancePresentationSettings copyWith({
    BalanceHeaderChartMode? chartMode,
    BalanceHeaderChartTimeLabels? timeLabels,
    double? cardWidthBoost,
    double? carouselSpacingAdjustment,
    int? revision,
  }) => BalancePresentationSettings(
    chartMode: chartMode ?? this.chartMode,
    timeLabels: timeLabels ?? this.timeLabels,
    cardWidthBoost: cardWidthBoost ?? this.cardWidthBoost,
    carouselSpacingAdjustment:
        carouselSpacingAdjustment ?? this.carouselSpacingAdjustment,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is BalancePresentationSettings &&
      other.chartMode == chartMode &&
      other.timeLabels == timeLabels &&
      other.cardWidthBoost == cardWidthBoost &&
      other.carouselSpacingAdjustment == carouselSpacingAdjustment &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
    chartMode,
    timeLabels,
    cardWidthBoost,
    carouselSpacingAdjustment,
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

  void setCardWidthBoost(double next) {
    final normalized = next
        .clamp(0.0, BalancePresentationSettings.maximumCardWidthBoost)
        .toDouble();
    final current = value;
    if (current.cardWidthBoost == normalized) return;
    value = current.copyWith(
      cardWidthBoost: normalized,
      revision: current.revision + 1,
    );
  }

  void setCarouselSpacingAdjustment(double next) {
    final normalized = next
        .clamp(
          0.0,
          BalancePresentationSettings.maximumCarouselSpacingAdjustment,
        )
        .toDouble();
    final current = value;
    if (current.carouselSpacingAdjustment == normalized) return;
    value = current.copyWith(
      carouselSpacingAdjustment: normalized,
      revision: current.revision + 1,
    );
  }
}
