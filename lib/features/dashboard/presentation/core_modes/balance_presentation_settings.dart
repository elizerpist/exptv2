import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_history_projection.dart';

/// Stable semantic identities for the finite Balance carousel catalog.
///
/// This belongs to the presentation settings owner because visibility is
/// session presentation state, never financial data. Defaults derive from the
/// enum, so a future catalog member starts visible automatically.
enum BalanceCarouselCardKind {
  cashflow,
  closings,
  momentum,
  retention,
  stability,
  ghost,
  forecast,
  latestTransaction,
  categoryMovers,
  topCategory,
  topPartner;

  String get stableId => switch (this) {
    BalanceCarouselCardKind.cashflow => 'cashflow',
    BalanceCarouselCardKind.closings => 'closings',
    BalanceCarouselCardKind.momentum => 'momentum',
    BalanceCarouselCardKind.retention => 'retention',
    BalanceCarouselCardKind.stability => 'stability',
    BalanceCarouselCardKind.ghost => 'ghost',
    BalanceCarouselCardKind.forecast => 'forecast',
    BalanceCarouselCardKind.latestTransaction => 'latest-transaction',
    BalanceCarouselCardKind.categoryMovers => 'category-movers',
    BalanceCarouselCardKind.topCategory => 'top-category',
    BalanceCarouselCardKind.topPartner => 'top-partner',
  };

  String get visibilityLabel => switch (this) {
    BalanceCarouselCardKind.cashflow => 'Cashflow',
    BalanceCarouselCardKind.closings => 'Zárások',
    BalanceCarouselCardKind.momentum => 'Balance momentum',
    BalanceCarouselCardKind.retention => 'Megtakarítási arány',
    BalanceCarouselCardKind.stability => 'Cashflow stabilitás',
    BalanceCarouselCardKind.ghost => 'Fix terhek',
    BalanceCarouselCardKind.forecast => 'Forecast',
    BalanceCarouselCardKind.latestTransaction => 'Utolsó tranzakció',
    BalanceCarouselCardKind.categoryMovers => 'Kategóriaváltozás',
    BalanceCarouselCardKind.topCategory => 'Top kategória',
    BalanceCarouselCardKind.topPartner => 'Top partner',
  };
}

/// The authored period of the ambient carousel wave at 1.00× speed.
const balanceCarouselWaveBaseDuration = Duration(seconds: 6);
const balanceCarouselWaveMinimumSpeedMultiplier = .25;
const balanceCarouselWaveMaximumSpeedMultiplier = 3.0;
const balanceCarouselWaveDefaultSpeedMultiplier = 1.0;

/// Resolves the running period without exposing milliseconds as a user setting.
///
/// Clamping here keeps every consumer—including a restored or programmatic
/// setting—inside the same authored contract.
Duration balanceCarouselWaveEffectiveDuration(double multiplier) {
  final bounded = multiplier
      .clamp(
        balanceCarouselWaveMinimumSpeedMultiplier,
        balanceCarouselWaveMaximumSpeedMultiplier,
      )
      .toDouble();
  return Duration(
    microseconds: (balanceCarouselWaveBaseDuration.inMicroseconds / bounded)
        .round(),
  );
}

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

/// Balance can retain its established independent Header/detail cards or use
/// the Budget/Mind-derived continuous Header-to-content parent surface.
enum BalanceContentSurfaceStyle {
  separateCards,
  unifiedCard;

  String get tunerLabel => switch (this) {
    BalanceContentSurfaceStyle.separateCards => 'Külön kártyák',
    BalanceContentSurfaceStyle.unifiedCard => 'Egybefüggő kártya',
  };
}

/// A subordinate composition preference. It is retained while separate
/// Balance is active, but only rendered when [BalanceContentSurfaceStyle]
/// resolves to [BalanceContentSurfaceStyle.unifiedCard].
enum BalanceUnifiedBodyLayout {
  currentCarouselDetail,
  fourSectionTetris;

  String get tunerLabel => switch (this) {
    BalanceUnifiedBodyLayout.currentCarouselDetail =>
      'Jelenlegi — carousel + részletek',
    BalanceUnifiedBodyLayout.fourSectionTetris => 'Alternatív — 4 szekció',
  };
}

/// Session-only alternatives over the immutable all-time Balance history.
/// Financial totals and the latest transaction are never settings-dependent.
@immutable
final class BalancePresentationSettings {
  BalancePresentationSettings({
    required this.chartMode,
    required this.timeLabels,
    required this.latestTransactionCardPresentation,
    required this.balanceCarouselBorderEnabled,
    required this.balanceCarouselBorderOpacity,
    required this.balanceCarouselBackgroundOpacity,
    required this.balanceCarouselWaveOpacity,
    this.balanceCarouselWaveSpeedMultiplier =
        balanceCarouselWaveDefaultSpeedMultiplier,
    required this.balanceCarouselTintedBackgroundEnabled,
    required this.balanceCarouselWaveAnimationEnabled,
    required this.balanceContentCardColoredBorderEnabled,
    required this.balanceContentCardBorderOpacity,
    this.contentSurfaceStyle = BalanceContentSurfaceStyle.separateCards,
    this.unifiedBodyLayout = BalanceUnifiedBodyLayout.currentCarouselDetail,
    Set<BalanceCarouselCardKind> hiddenBalanceCarouselCardKinds =
        const <BalanceCarouselCardKind>{},
    required this.revision,
  }) : hiddenBalanceCarouselCardKinds =
           Set<BalanceCarouselCardKind>.unmodifiable(
             hiddenBalanceCarouselCardKinds,
           ),
       assert(
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
         balanceCarouselWaveSpeedMultiplier >=
                 balanceCarouselWaveMinimumSpeedMultiplier &&
             balanceCarouselWaveSpeedMultiplier <=
                 balanceCarouselWaveMaximumSpeedMultiplier,
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
      balanceCarouselWaveSpeedMultiplier =
          balanceCarouselWaveDefaultSpeedMultiplier,
      balanceCarouselTintedBackgroundEnabled = true,
      balanceCarouselWaveAnimationEnabled = true,
      balanceContentCardColoredBorderEnabled = true,
      balanceContentCardBorderOpacity = 1,
      contentSurfaceStyle = BalanceContentSurfaceStyle.separateCards,
      unifiedBodyLayout = BalanceUnifiedBodyLayout.currentCarouselDetail,
      hiddenBalanceCarouselCardKinds = const <BalanceCarouselCardKind>{},
      revision = 0;

  final BalanceHeaderChartMode chartMode;
  final BalanceHeaderChartTimeLabels timeLabels;
  final BalanceLatestTransactionCardPresentation
  latestTransactionCardPresentation;
  final bool balanceCarouselBorderEnabled;
  final double balanceCarouselBorderOpacity;
  final double balanceCarouselBackgroundOpacity;
  final double balanceCarouselWaveOpacity;
  final double balanceCarouselWaveSpeedMultiplier;
  final bool balanceCarouselTintedBackgroundEnabled;
  final bool balanceCarouselWaveAnimationEnabled;
  final bool balanceContentCardColoredBorderEnabled;
  final double balanceContentCardBorderOpacity;
  final BalanceContentSurfaceStyle contentSurfaceStyle;
  final BalanceUnifiedBodyLayout unifiedBodyLayout;
  final Set<BalanceCarouselCardKind> hiddenBalanceCarouselCardKinds;
  final int revision;

  bool get showsTimeLabels =>
      timeLabels == BalanceHeaderChartTimeLabels.visible;

  Set<BalanceCarouselCardKind> get visibleBalanceCarouselCardKinds =>
      Set<BalanceCarouselCardKind>.unmodifiable(
        BalanceCarouselCardKind.values.where(isBalanceCarouselCardVisible),
      );

  bool isBalanceCarouselCardVisible(BalanceCarouselCardKind kind) =>
      !hiddenBalanceCarouselCardKinds.contains(kind);

  BalancePresentationSettings copyWith({
    BalanceHeaderChartMode? chartMode,
    BalanceHeaderChartTimeLabels? timeLabels,
    BalanceLatestTransactionCardPresentation? latestTransactionCardPresentation,
    bool? balanceCarouselBorderEnabled,
    double? balanceCarouselBorderOpacity,
    double? balanceCarouselBackgroundOpacity,
    double? balanceCarouselWaveOpacity,
    double? balanceCarouselWaveSpeedMultiplier,
    bool? balanceCarouselTintedBackgroundEnabled,
    bool? balanceCarouselWaveAnimationEnabled,
    bool? balanceContentCardColoredBorderEnabled,
    double? balanceContentCardBorderOpacity,
    BalanceContentSurfaceStyle? contentSurfaceStyle,
    BalanceUnifiedBodyLayout? unifiedBodyLayout,
    Set<BalanceCarouselCardKind>? hiddenBalanceCarouselCardKinds,
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
    balanceCarouselWaveSpeedMultiplier:
        balanceCarouselWaveSpeedMultiplier ??
        this.balanceCarouselWaveSpeedMultiplier,
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
    contentSurfaceStyle: contentSurfaceStyle ?? this.contentSurfaceStyle,
    unifiedBodyLayout: unifiedBodyLayout ?? this.unifiedBodyLayout,
    hiddenBalanceCarouselCardKinds:
        hiddenBalanceCarouselCardKinds ?? this.hiddenBalanceCarouselCardKinds,
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
      other.balanceCarouselWaveSpeedMultiplier ==
          balanceCarouselWaveSpeedMultiplier &&
      other.balanceCarouselTintedBackgroundEnabled ==
          balanceCarouselTintedBackgroundEnabled &&
      other.balanceCarouselWaveAnimationEnabled ==
          balanceCarouselWaveAnimationEnabled &&
      other.balanceContentCardColoredBorderEnabled ==
          balanceContentCardColoredBorderEnabled &&
      other.balanceContentCardBorderOpacity ==
          balanceContentCardBorderOpacity &&
      other.contentSurfaceStyle == contentSurfaceStyle &&
      other.unifiedBodyLayout == unifiedBodyLayout &&
      setEquals(
        other.hiddenBalanceCarouselCardKinds,
        hiddenBalanceCarouselCardKinds,
      ) &&
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
    balanceCarouselWaveSpeedMultiplier,
    balanceCarouselTintedBackgroundEnabled,
    balanceCarouselWaveAnimationEnabled,
    balanceContentCardColoredBorderEnabled,
    balanceContentCardBorderOpacity,
    contentSurfaceStyle,
    unifiedBodyLayout,
    Object.hashAllUnordered(hiddenBalanceCarouselCardKinds),
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

  void setBalanceCarouselWaveSpeedMultiplier(double next) {
    final normalized = _normalizedWaveSpeed(next);
    final current = value;
    if (current.balanceCarouselWaveSpeedMultiplier == normalized) return;
    value = current.copyWith(
      balanceCarouselWaveSpeedMultiplier: normalized,
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

  void setContentSurfaceStyle(BalanceContentSurfaceStyle next) {
    final current = value;
    if (current.contentSurfaceStyle == next) return;
    value = current.copyWith(
      contentSurfaceStyle: next,
      revision: current.revision + 1,
    );
  }

  void setUnifiedBodyLayout(BalanceUnifiedBodyLayout next) {
    final current = value;
    if (current.unifiedBodyLayout == next) return;
    value = current.copyWith(
      unifiedBodyLayout: next,
      revision: current.revision + 1,
    );
  }

  /// Changes only the finite carousel membership. Returning false tells the
  /// UI that hiding [kind] would leave no meaningful Balance carousel.
  bool setBalanceCarouselCardVisible(
    BalanceCarouselCardKind kind,
    bool visible,
  ) {
    final current = value;
    final hidden = <BalanceCarouselCardKind>{
      ...current.hiddenBalanceCarouselCardKinds,
    };
    if (visible) {
      if (!hidden.remove(kind)) return true;
    } else {
      if (hidden.contains(kind)) return true;
      if (current.visibleBalanceCarouselCardKinds.length <= 1) return false;
      hidden.add(kind);
    }
    value = current.copyWith(
      hiddenBalanceCarouselCardKinds: hidden,
      revision: current.revision + 1,
    );
    return true;
  }

  void reset() => value = const BalancePresentationSettings.defaults();

  double _normalizedOpacity(double value) => value.clamp(0, 1).toDouble();

  double _normalizedWaveSpeed(double value) => value
      .clamp(
        balanceCarouselWaveMinimumSpeedMultiplier,
        balanceCarouselWaveMaximumSpeedMultiplier,
      )
      .toDouble();
}
