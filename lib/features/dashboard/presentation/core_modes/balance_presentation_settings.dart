import 'package:flutter/foundation.dart';

import '../../application/balance_daily_calculation_mode.dart';
import '../../application/dashboard_balance_history_projection.dart';
import 'balance_header_glass_configuration.dart';

/// Chooses only the Balance Header renderer. Both choices consume the same
/// resident Balance presentation; this is not a second history projection.
enum BalanceHeaderGraphPresentation {
  lineChart,
  incomeExpensePartition,
  simpleIncomeExpensePartition;

  String get tunerLabel => switch (this) {
    BalanceHeaderGraphPresentation.lineChart => 'Vonaldiagram',
    BalanceHeaderGraphPresentation.incomeExpensePartition =>
      'Bevétel vs. kiadás',
    BalanceHeaderGraphPresentation.simpleIncomeExpensePartition =>
      'Egyszerű bevétel vs. kiadás',
  };
}

/// Renderer-only choices for Havi → Költés over its existing immutable daily
/// spend points. The Header has no terrain alternative: it keeps its original
/// history-chart renderer.
enum BalanceMonthlySpendingChartPresentation {
  current,
  topographic,
  reactiveSvg,
  shaderAtmosphere;

  String get tunerLabel => switch (this) {
    BalanceMonthlySpendingChartPresentation.current => 'Jelenlegi',
    BalanceMonthlySpendingChartPresentation.topographic => '3D topografikus',
    BalanceMonthlySpendingChartPresentation.reactiveSvg => 'Reaktív SVG',
    BalanceMonthlySpendingChartPresentation.shaderAtmosphere =>
      'Shaderes atmoszféra',
  };
}

/// Chooses the lower Month-wide Balance renderer over the existing immutable
/// scope payload. The rhythm alternative reads prepared daily spend points.
enum BalanceMonthCombinedCardPresentation {
  incomeExpense,
  spendingRhythm;

  String get tunerLabel => switch (this) {
    BalanceMonthCombinedCardPresentation.incomeExpense => 'Bevétel vs. kiadás',
    BalanceMonthCombinedCardPresentation.spendingRhythm =>
      'Napi költési ritmus',
  };
}

/// All-time content preferences independent of the other time scopes.
enum BalanceSumLayoutPresentation {
  current,
  focused;

  String get tunerLabel => switch (this) {
    current => 'Eddigi',
    focused => 'Új',
  };
  String get tunerDescription => switch (this) {
    current =>
      'Jelenlegi SUM Balance nézet a korábbi grafikonokkal és kártyákkal.',
    focused =>
      'Perspektívaválasztó és egyetlen nagy összesített elemzőgrafikon.',
  };
}

enum BalanceSumFocusedPresentation {
  distribution,
  positiveRatio,
  stability;

  String get tunerLabel => switch (this) {
    distribution => 'Eredmények eloszlása',
    positiveRatio => 'Pozitív hónapok aránya',
    stability => 'Pénzügyi stabilitás',
  };
  String get tunerDescription => switch (this) {
    distribution => 'A havi pénzügyi eredmények eloszlása.',
    positiveRatio => 'A pozitív eredményű hónapok aránya.',
    stability => 'A havi eredmények kiegyensúlyozottsága.',
  };
}

/// Presentation-only alternatives for the daily Balance content.
enum BalanceDayLayoutPresentation {
  current,
  focused;

  String get tunerLabel => switch (this) {
    current => 'Eddigi',
    focused => 'Új',
  };
  String get tunerDescription => switch (this) {
    current => 'Jelenlegi napi Balance nézet a korábbi kártyákkal.',
    focused => 'Interaktív ritmuscsík és fókuszált napi elemzés.',
  };
}

enum BalanceDayFocusedPresentation {
  financialCompass,
  financialComparison,
  dailyImpactFocus,
  monthlyNetMarginImpact;

  String get tunerLabel => switch (this) {
    financialCompass => 'Pénzügyi iránytű',
    financialComparison => 'Pénzügyi mérleg',
    dailyImpactFocus => 'Egyenlegarány',
    monthlyNetMarginImpact => 'Napi hatás',
  };
  String get tunerDescription => switch (this) {
    financialCompass => 'A kiválasztott nap pénzügyi iránya.',
    financialComparison => 'A napi bevétel és kiadás összehasonlítása.',
    dailyImpactFocus => 'Két 30 napos időszak bevételi és kiadási aránya.',
    monthlyNetMarginImpact => 'A kiválasztott nap hatása a havi nettóarányra.',
  };
}

/// Selects the presentation of the same accepted 30 + 30 day totals.
enum BalanceDayRatioViewPresentation {
  dualGauge,
  performanceIndex;

  String get tunerLabel => switch (this) {
    dualGauge => 'Két félkör',
    performanceIndex => 'Egy félkör',
  };

  String get tunerDescription => switch (this) {
    dualGauge => 'Az előző és az utolsó 30 nap külön összehasonlítása.',
    performanceIndex =>
      'Az utolsó 30 nap teljesítménye az előző időszakhoz viszonyítva.',
  };
}

/// Visual-only rendering choice for the prepared 30 day performance index.
enum BalanceDayPerformanceVisualPresentation {
  semicircle,
  horizontalMeter;

  String get tunerLabel => switch (this) {
    semicircle => 'Félkör',
    horizontalMeter => 'Vízszintes meter',
  };

  String get tunerDescription => switch (this) {
    semicircle => 'A 30 napos teljesítmény a közös clay félkörön.',
    horizontalMeter => 'Ugyanaz a teljesítmény vízszintes clay skálán.',
  };
}

enum BalanceDayRatioPresentation {
  coverage,
  netMargin;

  String get tunerLabel => switch (this) {
    coverage => 'Fedezettség',
    netMargin => 'Nettóarány',
  };

  String get tunerDescription => switch (this) {
    coverage => 'Bevétel / Kiadás. A 100% a nullszaldó.',
    netMargin => 'Nettó / Bevétel. A 0% a nullszaldó.',
  };
}

/// Presentation-only alternative for the extended monthly Balance content.
enum BalanceMonthLayoutPresentation {
  current,
  focused;

  String get tunerLabel => switch (this) {
    BalanceMonthLayoutPresentation.current => 'Eddigi',
    BalanceMonthLayoutPresentation.focused => 'Új',
  };

  String get tunerDescription => switch (this) {
    BalanceMonthLayoutPresentation.current =>
      'Jelenlegi havi Balance nézet a korábbi grafikonokkal és kártyákkal.',
    BalanceMonthLayoutPresentation.focused =>
      'Perspektívaválasztó és egyetlen nagy havi elemzőgrafikon.',
  };
}

/// Presentation-only alternative for the extended annual Balance content.
enum BalanceYearLayoutPresentation {
  current,
  focused;

  String get tunerLabel => switch (this) {
    BalanceYearLayoutPresentation.current => 'Eddigi',
    BalanceYearLayoutPresentation.focused => 'Új',
  };

  String get tunerDescription => switch (this) {
    BalanceYearLayoutPresentation.current =>
      'Három különálló pénzügyi grafikon és statisztika.',
    BalanceYearLayoutPresentation.focused =>
      'Perspektívaválasztó és egyetlen nagy, interaktív grafikon.',
  };
}

/// Material-only choice for the Balance Year bar-chart family.
///
/// The current treatment is retained as the default. In the Year scope the
/// selection is shared by the income/expense columns and the zero-centred
/// closings chart. Clay is intentionally restricted to those Year renderers,
/// not the all-time historical-years plot.
enum BalanceYearBarPresentation {
  current,
  clay3d;

  String get tunerLabel => switch (this) {
    BalanceYearBarPresentation.current => 'Jelenlegi',
    BalanceYearBarPresentation.clay3d => '3D clay',
  };
}

/// Session-only alternatives over the immutable all-time Balance history.
/// Financial totals and the latest transaction are never settings-dependent.
@immutable
final class BalancePresentationSettings {
  const BalancePresentationSettings({
    required this.chartMode,
    this.dailyCalculationMode = BalanceDailyCalculationMode.monthToDate,
    this.headerGraphPresentation =
        BalanceHeaderGraphPresentation.incomeExpensePartition,
    this.monthlySpendingChartPresentation =
        BalanceMonthlySpendingChartPresentation.current,
    this.headerPartitionHeightPercent = 50,
    this.headerGlassConfiguration = const BalanceHeaderGlassConfiguration(),
    this.monthCombinedCardPresentation =
        BalanceMonthCombinedCardPresentation.incomeExpense,
    this.dayLayoutPresentation = BalanceDayLayoutPresentation.focused,
    this.dayFocusedPresentation =
        BalanceDayFocusedPresentation.financialCompass,
    this.dayPerformanceVisualPresentation =
        BalanceDayPerformanceVisualPresentation.semicircle,
    this.dayRatioViewPresentation = BalanceDayRatioViewPresentation.dualGauge,
    this.dayRatioPresentation = BalanceDayRatioPresentation.coverage,
    this.showFocusedDayImpact = true,
    this.sumLayoutPresentation = BalanceSumLayoutPresentation.focused,
    this.sumFocusedPresentation = BalanceSumFocusedPresentation.distribution,
    this.showSumFocusedSupplementaryStats = true,
    this.monthLayoutPresentation = BalanceMonthLayoutPresentation.focused,
    this.yearLayoutPresentation = BalanceYearLayoutPresentation.focused,
    this.yearBarPresentation = BalanceYearBarPresentation.current,
    this.usesChildCards = true,
    required this.revision,
  }) : assert(
         headerPartitionHeightPercent >= 0 &&
             headerPartitionHeightPercent <= 100,
       );

  const BalancePresentationSettings.defaults()
    : chartMode = BalanceHeaderChartMode.compound,
      dailyCalculationMode = BalanceDailyCalculationMode.monthToDate,
      headerGraphPresentation =
          BalanceHeaderGraphPresentation.incomeExpensePartition,
      monthlySpendingChartPresentation =
          BalanceMonthlySpendingChartPresentation.current,
      headerPartitionHeightPercent = 50,
      headerGlassConfiguration = const BalanceHeaderGlassConfiguration(),
      monthCombinedCardPresentation =
          BalanceMonthCombinedCardPresentation.incomeExpense,
      dayLayoutPresentation = BalanceDayLayoutPresentation.focused,
      dayFocusedPresentation = BalanceDayFocusedPresentation.financialCompass,
      dayPerformanceVisualPresentation =
          BalanceDayPerformanceVisualPresentation.semicircle,
      dayRatioViewPresentation = BalanceDayRatioViewPresentation.dualGauge,
      dayRatioPresentation = BalanceDayRatioPresentation.coverage,
      showFocusedDayImpact = true,
      sumLayoutPresentation = BalanceSumLayoutPresentation.focused,
      sumFocusedPresentation = BalanceSumFocusedPresentation.distribution,
      showSumFocusedSupplementaryStats = true,
      monthLayoutPresentation = BalanceMonthLayoutPresentation.focused,
      yearLayoutPresentation = BalanceYearLayoutPresentation.focused,
      yearBarPresentation = BalanceYearBarPresentation.current,
      usesChildCards = true,
      revision = 0;

  final BalanceHeaderChartMode chartMode;
  final BalanceDailyCalculationMode dailyCalculationMode;
  final BalanceHeaderGraphPresentation headerGraphPresentation;
  final BalanceMonthlySpendingChartPresentation
  monthlySpendingChartPresentation;
  final double headerPartitionHeightPercent;
  final BalanceHeaderGlassConfiguration headerGlassConfiguration;
  final BalanceMonthCombinedCardPresentation monthCombinedCardPresentation;
  final BalanceDayLayoutPresentation dayLayoutPresentation;
  final BalanceDayFocusedPresentation dayFocusedPresentation;
  final BalanceDayPerformanceVisualPresentation
  dayPerformanceVisualPresentation;
  final BalanceDayRatioViewPresentation dayRatioViewPresentation;
  final BalanceDayRatioPresentation dayRatioPresentation;
  final bool showFocusedDayImpact;
  final BalanceSumLayoutPresentation sumLayoutPresentation;
  final BalanceSumFocusedPresentation sumFocusedPresentation;
  final bool showSumFocusedSupplementaryStats;
  final BalanceMonthLayoutPresentation monthLayoutPresentation;
  final BalanceYearLayoutPresentation yearLayoutPresentation;
  final BalanceYearBarPresentation yearBarPresentation;
  final bool usesChildCards;
  final int revision;

  BalancePresentationSettings copyWith({
    BalanceHeaderChartMode? chartMode,
    BalanceDailyCalculationMode? dailyCalculationMode,
    BalanceHeaderGraphPresentation? headerGraphPresentation,
    BalanceMonthlySpendingChartPresentation? monthlySpendingChartPresentation,
    double? headerPartitionHeightPercent,
    BalanceHeaderGlassConfiguration? headerGlassConfiguration,
    BalanceMonthCombinedCardPresentation? monthCombinedCardPresentation,
    BalanceDayLayoutPresentation? dayLayoutPresentation,
    BalanceDayFocusedPresentation? dayFocusedPresentation,
    BalanceDayPerformanceVisualPresentation? dayPerformanceVisualPresentation,
    BalanceDayRatioViewPresentation? dayRatioViewPresentation,
    BalanceDayRatioPresentation? dayRatioPresentation,
    bool? showFocusedDayImpact,
    BalanceSumLayoutPresentation? sumLayoutPresentation,
    BalanceSumFocusedPresentation? sumFocusedPresentation,
    bool? showSumFocusedSupplementaryStats,
    BalanceMonthLayoutPresentation? monthLayoutPresentation,
    BalanceYearLayoutPresentation? yearLayoutPresentation,
    BalanceYearBarPresentation? yearBarPresentation,
    bool? usesChildCards,
    int? revision,
  }) => BalancePresentationSettings(
    chartMode: chartMode ?? this.chartMode,
    dailyCalculationMode: dailyCalculationMode ?? this.dailyCalculationMode,
    headerGraphPresentation:
        headerGraphPresentation ?? this.headerGraphPresentation,
    monthlySpendingChartPresentation:
        monthlySpendingChartPresentation ??
        this.monthlySpendingChartPresentation,
    headerPartitionHeightPercent:
        headerPartitionHeightPercent ?? this.headerPartitionHeightPercent,
    headerGlassConfiguration:
        headerGlassConfiguration ?? this.headerGlassConfiguration,
    monthCombinedCardPresentation:
        monthCombinedCardPresentation ?? this.monthCombinedCardPresentation,
    dayLayoutPresentation: dayLayoutPresentation ?? this.dayLayoutPresentation,
    dayFocusedPresentation:
        dayFocusedPresentation ?? this.dayFocusedPresentation,
    dayPerformanceVisualPresentation:
        dayPerformanceVisualPresentation ??
        this.dayPerformanceVisualPresentation,
    dayRatioViewPresentation:
        dayRatioViewPresentation ?? this.dayRatioViewPresentation,
    dayRatioPresentation: dayRatioPresentation ?? this.dayRatioPresentation,
    showFocusedDayImpact: showFocusedDayImpact ?? this.showFocusedDayImpact,
    sumLayoutPresentation: sumLayoutPresentation ?? this.sumLayoutPresentation,
    sumFocusedPresentation:
        sumFocusedPresentation ?? this.sumFocusedPresentation,
    showSumFocusedSupplementaryStats:
        showSumFocusedSupplementaryStats ??
        this.showSumFocusedSupplementaryStats,
    monthLayoutPresentation:
        monthLayoutPresentation ?? this.monthLayoutPresentation,
    yearLayoutPresentation:
        yearLayoutPresentation ?? this.yearLayoutPresentation,
    yearBarPresentation: yearBarPresentation ?? this.yearBarPresentation,
    usesChildCards: usesChildCards ?? this.usesChildCards,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is BalancePresentationSettings &&
      other.chartMode == chartMode &&
      other.dailyCalculationMode == dailyCalculationMode &&
      other.headerGraphPresentation == headerGraphPresentation &&
      other.monthlySpendingChartPresentation ==
          monthlySpendingChartPresentation &&
      other.headerPartitionHeightPercent == headerPartitionHeightPercent &&
      other.headerGlassConfiguration == headerGlassConfiguration &&
      other.monthCombinedCardPresentation == monthCombinedCardPresentation &&
      other.dayLayoutPresentation == dayLayoutPresentation &&
      other.dayFocusedPresentation == dayFocusedPresentation &&
      other.dayPerformanceVisualPresentation ==
          dayPerformanceVisualPresentation &&
      other.dayRatioViewPresentation == dayRatioViewPresentation &&
      other.dayRatioPresentation == dayRatioPresentation &&
      other.showFocusedDayImpact == showFocusedDayImpact &&
      other.sumLayoutPresentation == sumLayoutPresentation &&
      other.sumFocusedPresentation == sumFocusedPresentation &&
      other.showSumFocusedSupplementaryStats ==
          showSumFocusedSupplementaryStats &&
      other.monthLayoutPresentation == monthLayoutPresentation &&
      other.yearLayoutPresentation == yearLayoutPresentation &&
      other.yearBarPresentation == yearBarPresentation &&
      other.usesChildCards == usesChildCards &&
      other.revision == revision;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    chartMode,
    dailyCalculationMode,
    headerGraphPresentation,
    monthlySpendingChartPresentation,
    headerPartitionHeightPercent,
    headerGlassConfiguration,
    monthCombinedCardPresentation,
    dayLayoutPresentation,
    dayFocusedPresentation,
    dayPerformanceVisualPresentation,
    dayRatioViewPresentation,
    dayRatioPresentation,
    showFocusedDayImpact,
    sumLayoutPresentation,
    sumFocusedPresentation,
    showSumFocusedSupplementaryStats,
    monthLayoutPresentation,
    yearLayoutPresentation,
    yearBarPresentation,
    usesChildCards,
    revision,
  ]);
}

/// The one Dashboard-lifetime presentation owner for Balance-only chart and
/// content alternatives. It owns no Query, financial data or shared motion.
final class BalancePresentationController
    extends ValueNotifier<BalancePresentationSettings> {
  BalancePresentationController({BalancePresentationSettings? initial})
    : super(initial ?? const BalancePresentationSettings.defaults());

  void setDailyCalculationMode(BalanceDailyCalculationMode next) {
    final current = value;
    if (current.dailyCalculationMode == next) return;
    value = current.copyWith(
      dailyCalculationMode: next,
      revision: current.revision + 1,
    );
  }

  void setChartMode(BalanceHeaderChartMode next) {
    final current = value;
    if (current.chartMode == next) return;
    value = current.copyWith(chartMode: next, revision: current.revision + 1);
  }

  void setHeaderGraphPresentation(BalanceHeaderGraphPresentation next) {
    final current = value;
    if (current.headerGraphPresentation == next) return;
    value = current.copyWith(
      headerGraphPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setMonthlySpendingChartPresentation(
    BalanceMonthlySpendingChartPresentation next,
  ) {
    final current = value;
    if (current.monthlySpendingChartPresentation == next) return;
    value = current.copyWith(
      monthlySpendingChartPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setHeaderPartitionHeightPercent(double next) {
    final normalized = _normalizedPercent(next);
    final current = value;
    if (current.headerPartitionHeightPercent == normalized) return;
    value = current.copyWith(
      headerPartitionHeightPercent: normalized,
      revision: current.revision + 1,
    );
  }

  void setHeaderGlassConfiguration(BalanceHeaderGlassConfiguration next) {
    final current = value;
    if (current.headerGlassConfiguration == next) return;
    value = current.copyWith(
      headerGlassConfiguration: next,
      revision: current.revision + 1,
    );
  }

  void setMonthCombinedCardPresentation(
    BalanceMonthCombinedCardPresentation next,
  ) {
    final current = value;
    if (current.monthCombinedCardPresentation == next) return;
    value = current.copyWith(
      monthCombinedCardPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setDayLayoutPresentation(BalanceDayLayoutPresentation next) {
    final current = value;
    if (current.dayLayoutPresentation == next) return;
    value = current.copyWith(
      dayLayoutPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setDayFocusedPresentation(BalanceDayFocusedPresentation next) {
    final current = value;
    if (current.dayFocusedPresentation == next) return;
    value = current.copyWith(
      dayFocusedPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setDayPerformanceVisualPresentation(
    BalanceDayPerformanceVisualPresentation next,
  ) {
    final current = value;
    if (current.dayPerformanceVisualPresentation == next) return;
    value = current.copyWith(
      dayPerformanceVisualPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setDayRatioViewPresentation(BalanceDayRatioViewPresentation next) {
    final current = value;
    if (current.dayRatioViewPresentation == next) return;
    value = current.copyWith(
      dayRatioViewPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setDayRatioPresentation(BalanceDayRatioPresentation next) {
    final current = value;
    if (current.dayRatioPresentation == next) return;
    value = current.copyWith(
      dayRatioPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setShowFocusedDayImpact(bool next) {
    final current = value;
    if (current.showFocusedDayImpact == next) return;
    value = current.copyWith(
      showFocusedDayImpact: next,
      revision: current.revision + 1,
    );
  }

  void setSumLayoutPresentation(BalanceSumLayoutPresentation next) {
    final current = value;
    if (current.sumLayoutPresentation == next) return;
    value = current.copyWith(
      sumLayoutPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setSumFocusedPresentation(BalanceSumFocusedPresentation next) {
    final current = value;
    if (current.sumFocusedPresentation == next) return;
    value = current.copyWith(
      sumFocusedPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setShowSumFocusedSupplementaryStats(bool next) {
    final current = value;
    if (current.showSumFocusedSupplementaryStats == next) return;
    value = current.copyWith(
      showSumFocusedSupplementaryStats: next,
      revision: current.revision + 1,
    );
  }

  void setMonthLayoutPresentation(BalanceMonthLayoutPresentation next) {
    final current = value;
    if (current.monthLayoutPresentation == next) return;
    value = current.copyWith(
      monthLayoutPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setYearLayoutPresentation(BalanceYearLayoutPresentation next) {
    final current = value;
    if (current.yearLayoutPresentation == next) return;
    value = current.copyWith(
      yearLayoutPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setYearBarPresentation(BalanceYearBarPresentation next) {
    final current = value;
    if (current.yearBarPresentation == next) return;
    value = current.copyWith(
      yearBarPresentation: next,
      revision: current.revision + 1,
    );
  }

  void setUsesChildCards(bool next) {
    final current = value;
    if (current.usesChildCards == next) return;
    value = current.copyWith(
      usesChildCards: next,
      revision: current.revision + 1,
    );
  }

  void reset() => value = const BalancePresentationSettings.defaults();

  double _normalizedPercent(double value) => value.clamp(0, 100).toDouble();
}
