import 'package:flutter/foundation.dart';

/// Pure presentation alternatives over one immutable Mind annual data frame.
enum MindYearHeatmapPaletteStyle {
  fluvi,
  b3mMy3,
  meadowGreen,
  fluviStretched,
  b3mMy3Stretched;

  String get tunerLabel => switch (this) {
    MindYearHeatmapPaletteStyle.fluvi => 'Fluvi',
    MindYearHeatmapPaletteStyle.b3mMy3 => 'B3M-MY3',
    MindYearHeatmapPaletteStyle.meadowGreen => 'Meadow Green',
    MindYearHeatmapPaletteStyle.fluviStretched => 'Fluvi — stretched',
    MindYearHeatmapPaletteStyle.b3mMy3Stretched => 'B3M-MY3 — stretched',
  };
}

/// The authored palette path can be displayed at its original ten stops or
/// at the approved twenty-stop refinement. This is presentation-only; it
/// never changes the immutable financial frame or normalized intensity.
enum MindHeatmapScaleResolution {
  ten,
  twenty;

  String get tunerLabel => switch (this) {
    MindHeatmapScaleResolution.ten => '10 szín',
    MindHeatmapScaleResolution.twenty => '20 szín',
  };

  int get authoredStopCount => switch (this) {
    MindHeatmapScaleResolution.ten => 10,
    MindHeatmapScaleResolution.twenty => 20,
  };
}

/// Sum-only visual density alternative over the unchanged month frame.
enum MindSumYearRowLayout {
  twoRowExpanded,
  oneRowCompact;

  String get tunerLabel => switch (this) {
    MindSumYearRowLayout.twoRowExpanded => 'Két soros',
    MindSumYearRowLayout.oneRowCompact => 'Egy soros, kompakt',
  };
}

/// Where the static Hungarian initial appears relative to a Sum month tile.
enum MindSumMonthLabelPlacement {
  none,
  belowEachRow,
  insideMonthCells;

  String get tunerLabel => switch (this) {
    MindSumMonthLabelPlacement.none => 'Sehol',
    MindSumMonthLabelPlacement.belowEachRow => 'Minden sor alatt',
    MindSumMonthLabelPlacement.insideMonthCells => 'A hónapcellákban',
  };
}

/// Immutable user preferences for visualizing an admitted annual heatmap.
/// None of these values changes financial membership, Query state or score.
@immutable
final class MindYearHeatmapPresentationSettings {
  const MindYearHeatmapPresentationSettings({
    required this.paletteStyle,
    required this.revision,
    this.scaleResolution = MindHeatmapScaleResolution.ten,
    this.sumYearRowLayout = MindSumYearRowLayout.twoRowExpanded,
    this.sumMonthLabelPlacement = MindSumMonthLabelPlacement.none,
    this.yearThreeColumnProfitabilityTintEnabled = false,
    this.yearThreeColumnProfitabilityTintOpacity = .16,
  });

  const MindYearHeatmapPresentationSettings.defaults()
    : paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
      scaleResolution = MindHeatmapScaleResolution.ten,
      sumYearRowLayout = MindSumYearRowLayout.twoRowExpanded,
      sumMonthLabelPlacement = MindSumMonthLabelPlacement.none,
      yearThreeColumnProfitabilityTintEnabled = false,
      yearThreeColumnProfitabilityTintOpacity = .16,
      revision = 0;

  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindSumYearRowLayout sumYearRowLayout;
  final MindSumMonthLabelPlacement sumMonthLabelPlacement;

  /// 3×4 Year MonthCard background only. This never affects cell palette
  /// inputs, financial data or the 4×3 presentation.
  final bool yearThreeColumnProfitabilityTintEnabled;
  final double yearThreeColumnProfitabilityTintOpacity;
  final int revision;

  MindYearHeatmapPresentationSettings copyWith({
    MindYearHeatmapPaletteStyle? paletteStyle,
    MindHeatmapScaleResolution? scaleResolution,
    MindSumYearRowLayout? sumYearRowLayout,
    MindSumMonthLabelPlacement? sumMonthLabelPlacement,
    bool? yearThreeColumnProfitabilityTintEnabled,
    double? yearThreeColumnProfitabilityTintOpacity,
    int? revision,
  }) => MindYearHeatmapPresentationSettings(
    paletteStyle: paletteStyle ?? this.paletteStyle,
    scaleResolution: scaleResolution ?? this.scaleResolution,
    sumYearRowLayout: sumYearRowLayout ?? this.sumYearRowLayout,
    sumMonthLabelPlacement:
        sumMonthLabelPlacement ?? this.sumMonthLabelPlacement,
    yearThreeColumnProfitabilityTintEnabled:
        yearThreeColumnProfitabilityTintEnabled ??
        this.yearThreeColumnProfitabilityTintEnabled,
    yearThreeColumnProfitabilityTintOpacity:
        yearThreeColumnProfitabilityTintOpacity ??
        this.yearThreeColumnProfitabilityTintOpacity,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is MindYearHeatmapPresentationSettings &&
      other.paletteStyle == paletteStyle &&
      other.scaleResolution == scaleResolution &&
      other.sumYearRowLayout == sumYearRowLayout &&
      other.sumMonthLabelPlacement == sumMonthLabelPlacement &&
      other.yearThreeColumnProfitabilityTintEnabled ==
          yearThreeColumnProfitabilityTintEnabled &&
      other.yearThreeColumnProfitabilityTintOpacity ==
          yearThreeColumnProfitabilityTintOpacity &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
    paletteStyle,
    scaleResolution,
    sumYearRowLayout,
    sumMonthLabelPlacement,
    yearThreeColumnProfitabilityTintEnabled,
    yearThreeColumnProfitabilityTintOpacity,
    revision,
  );
}

/// One small presentation owner for Mind's annual grid. It intentionally has
/// no data/repository/Query dependency; the viewport merely listens to it.
final class MindYearHeatmapPresentationController
    extends ValueNotifier<MindYearHeatmapPresentationSettings> {
  MindYearHeatmapPresentationController({
    MindYearHeatmapPresentationSettings? initial,
  }) : super(initial ?? const MindYearHeatmapPresentationSettings.defaults());

  void setPaletteStyle(MindYearHeatmapPaletteStyle style) {
    final current = value;
    if (current.paletteStyle == style) return;
    value = current.copyWith(
      paletteStyle: style,
      revision: current.revision + 1,
    );
  }

  void setScaleResolution(MindHeatmapScaleResolution resolution) {
    final current = value;
    if (current.scaleResolution == resolution) return;
    value = current.copyWith(
      scaleResolution: resolution,
      revision: current.revision + 1,
    );
  }

  void setSumYearRowLayout(MindSumYearRowLayout layout) {
    final current = value;
    if (current.sumYearRowLayout == layout) return;
    value = current.copyWith(
      sumYearRowLayout: layout,
      revision: current.revision + 1,
    );
  }

  void setSumMonthLabelPlacement(MindSumMonthLabelPlacement placement) {
    final current = value;
    if (current.sumMonthLabelPlacement == placement) return;
    value = current.copyWith(
      sumMonthLabelPlacement: placement,
      revision: current.revision + 1,
    );
  }

  void setYearThreeColumnProfitabilityTintEnabled(bool enabled) {
    final current = value;
    if (current.yearThreeColumnProfitabilityTintEnabled == enabled) return;
    value = current.copyWith(
      yearThreeColumnProfitabilityTintEnabled: enabled,
      revision: current.revision + 1,
    );
  }

  void setYearThreeColumnProfitabilityTintOpacity(double opacity) {
    final normalized = opacity.clamp(0.0, 1.0).toDouble();
    final current = value;
    if (current.yearThreeColumnProfitabilityTintOpacity == normalized) return;
    value = current.copyWith(
      yearThreeColumnProfitabilityTintOpacity: normalized,
      revision: current.revision + 1,
    );
  }
}
