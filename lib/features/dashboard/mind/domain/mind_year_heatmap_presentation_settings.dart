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

/// Uses either the selected static authored scale or the presentation-only
/// score-driven mixed scale. It has no projection or Query authority.
enum MindHeatmapScaleMode {
  existing,
  dynamicMixed;

  String get tunerLabel => switch (this) {
    MindHeatmapScaleMode.existing => 'Jelenlegi',
    MindHeatmapScaleMode.dynamicMixed => 'Dinamikus kevert skála',
  };
}

/// Changes only Mind's painted range-thumb diameter. The shared slider keeps
/// its existing recognizer and overlay hit target.
enum MindSliderHandleSize {
  normal,
  tenPercentSmaller;

  String get tunerLabel => switch (this) {
    MindSliderHandleSize.normal => 'Normál',
    MindSliderHandleSize.tenPercentSmaller => '10%-kal kisebb',
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

/// The maximum number of annual Sum chart bands the presentation exposes at
/// once. It changes only viewport density, never the admitted years or data.
enum MindSumVisibleChartCount {
  one,
  two;

  String get tunerLabel => switch (this) {
    MindSumVisibleChartCount.one => '1 grafikon',
    MindSumVisibleChartCount.two => '2 grafikon',
  };
}

/// Paint-only curve construction for the detailed Sum chart. The admitted
/// points, selection and financial totals remain unchanged.
enum MindSumLineInterpolationMode {
  linear,
  monotoneCubic,
  catmullRom;

  String get tunerLabel => switch (this) {
    MindSumLineInterpolationMode.linear => 'Lineáris',
    MindSumLineInterpolationMode.monotoneCubic => 'Monoton köbös',
    MindSumLineInterpolationMode.catmullRom => 'Catmull–Rom',
  };
}

/// The temporal presentation window for optional weighted Sum smoothing.
/// Values express calendar-day intent; the renderer resolves it against the
/// bounded points currently available at the selected zoom.
enum MindSumSmoothingWindow {
  days3,
  days5,
  days7;

  int get dayCount => switch (this) {
    MindSumSmoothingWindow.days3 => 3,
    MindSumSmoothingWindow.days5 => 5,
    MindSumSmoothingWindow.days7 => 7,
  };

  String get tunerLabel => '$dayCount nap';
}

/// Day uses the same immutable prepared frame in both layouts. This setting
/// chooses only how much surrounding current-frame information is rendered.
enum MindDayTimelineLayout {
  statsAndTimeline,
  timelineOnly;

  String get tunerLabel => switch (this) {
    MindDayTimelineLayout.statsAndTimeline => 'Statisztikák és idővonal',
    MindDayTimelineLayout.timelineOnly => 'Csak idővonal',
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
    this.scaleMode = MindHeatmapScaleMode.existing,
    this.sliderHandleSize = MindSliderHandleSize.normal,
    this.sumYearRowLayout = MindSumYearRowLayout.twoRowExpanded,
    this.sumMonthLabelPlacement = MindSumMonthLabelPlacement.none,
    this.sumVisibleChartCount = MindSumVisibleChartCount.two,
    this.yearMonthCardBorderEnabled = true,
    this.yearMonthCardProfitabilityTintEnabled = false,
    this.yearMonthCardProfitabilityTintOpacity = .16,
    this.sumLineInterpolationMode = MindSumLineInterpolationMode.linear,
    this.sumLineCatmullRomTension = .5,
    this.sumLineTemporalSmoothingEnabled = false,
    this.sumLineSmoothingWindow = MindSumSmoothingWindow.days3,
    this.sumLineZoomAdaptiveSmoothingEnabled = false,
    this.dayTimelineLayout = MindDayTimelineLayout.statsAndTimeline,
  });

  const MindYearHeatmapPresentationSettings.defaults()
    : paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
      scaleResolution = MindHeatmapScaleResolution.ten,
      scaleMode = MindHeatmapScaleMode.existing,
      sliderHandleSize = MindSliderHandleSize.normal,
      sumYearRowLayout = MindSumYearRowLayout.twoRowExpanded,
      sumMonthLabelPlacement = MindSumMonthLabelPlacement.none,
      sumVisibleChartCount = MindSumVisibleChartCount.two,
      yearMonthCardBorderEnabled = true,
      yearMonthCardProfitabilityTintEnabled = false,
      yearMonthCardProfitabilityTintOpacity = .16,
      sumLineInterpolationMode = MindSumLineInterpolationMode.linear,
      sumLineCatmullRomTension = .5,
      sumLineTemporalSmoothingEnabled = false,
      sumLineSmoothingWindow = MindSumSmoothingWindow.days3,
      sumLineZoomAdaptiveSmoothingEnabled = false,
      dayTimelineLayout = MindDayTimelineLayout.statsAndTimeline,
      revision = 0;

  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapScaleMode scaleMode;
  final MindSliderHandleSize sliderHandleSize;
  final MindSumYearRowLayout sumYearRowLayout;
  final MindSumMonthLabelPlacement sumMonthLabelPlacement;
  final MindSumVisibleChartCount sumVisibleChartCount;

  /// MonthCard chrome applies to card-based Year layouts only. It never
  /// affects direct 4×3 cells, palette inputs or financial data.
  final bool yearMonthCardBorderEnabled;
  final bool yearMonthCardProfitabilityTintEnabled;
  final double yearMonthCardProfitabilityTintOpacity;
  final MindSumLineInterpolationMode sumLineInterpolationMode;
  final double sumLineCatmullRomTension;
  final bool sumLineTemporalSmoothingEnabled;
  final MindSumSmoothingWindow sumLineSmoothingWindow;
  final bool sumLineZoomAdaptiveSmoothingEnabled;
  final MindDayTimelineLayout dayTimelineLayout;

  @Deprecated('Use yearMonthCardProfitabilityTintEnabled.')
  bool get yearThreeColumnProfitabilityTintEnabled =>
      yearMonthCardProfitabilityTintEnabled;

  @Deprecated('Use yearMonthCardProfitabilityTintOpacity.')
  double get yearThreeColumnProfitabilityTintOpacity =>
      yearMonthCardProfitabilityTintOpacity;
  final int revision;

  MindYearHeatmapPresentationSettings copyWith({
    MindYearHeatmapPaletteStyle? paletteStyle,
    MindHeatmapScaleResolution? scaleResolution,
    MindHeatmapScaleMode? scaleMode,
    MindSliderHandleSize? sliderHandleSize,
    MindSumYearRowLayout? sumYearRowLayout,
    MindSumMonthLabelPlacement? sumMonthLabelPlacement,
    MindSumVisibleChartCount? sumVisibleChartCount,
    bool? yearMonthCardBorderEnabled,
    bool? yearMonthCardProfitabilityTintEnabled,
    double? yearMonthCardProfitabilityTintOpacity,
    MindSumLineInterpolationMode? sumLineInterpolationMode,
    double? sumLineCatmullRomTension,
    bool? sumLineTemporalSmoothingEnabled,
    MindSumSmoothingWindow? sumLineSmoothingWindow,
    bool? sumLineZoomAdaptiveSmoothingEnabled,
    MindDayTimelineLayout? dayTimelineLayout,
    int? revision,
  }) => MindYearHeatmapPresentationSettings(
    paletteStyle: paletteStyle ?? this.paletteStyle,
    scaleResolution: scaleResolution ?? this.scaleResolution,
    scaleMode: scaleMode ?? this.scaleMode,
    sliderHandleSize: sliderHandleSize ?? this.sliderHandleSize,
    sumYearRowLayout: sumYearRowLayout ?? this.sumYearRowLayout,
    sumMonthLabelPlacement:
        sumMonthLabelPlacement ?? this.sumMonthLabelPlacement,
    sumVisibleChartCount: sumVisibleChartCount ?? this.sumVisibleChartCount,
    yearMonthCardBorderEnabled:
        yearMonthCardBorderEnabled ?? this.yearMonthCardBorderEnabled,
    yearMonthCardProfitabilityTintEnabled:
        yearMonthCardProfitabilityTintEnabled ??
        this.yearMonthCardProfitabilityTintEnabled,
    yearMonthCardProfitabilityTintOpacity:
        yearMonthCardProfitabilityTintOpacity ??
        this.yearMonthCardProfitabilityTintOpacity,
    sumLineInterpolationMode:
        sumLineInterpolationMode ?? this.sumLineInterpolationMode,
    sumLineCatmullRomTension:
        sumLineCatmullRomTension ?? this.sumLineCatmullRomTension,
    sumLineTemporalSmoothingEnabled:
        sumLineTemporalSmoothingEnabled ?? this.sumLineTemporalSmoothingEnabled,
    sumLineSmoothingWindow:
        sumLineSmoothingWindow ?? this.sumLineSmoothingWindow,
    sumLineZoomAdaptiveSmoothingEnabled:
        sumLineZoomAdaptiveSmoothingEnabled ??
        this.sumLineZoomAdaptiveSmoothingEnabled,
    dayTimelineLayout: dayTimelineLayout ?? this.dayTimelineLayout,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is MindYearHeatmapPresentationSettings &&
      other.paletteStyle == paletteStyle &&
      other.scaleResolution == scaleResolution &&
      other.scaleMode == scaleMode &&
      other.sliderHandleSize == sliderHandleSize &&
      other.sumYearRowLayout == sumYearRowLayout &&
      other.sumMonthLabelPlacement == sumMonthLabelPlacement &&
      other.sumVisibleChartCount == sumVisibleChartCount &&
      other.yearMonthCardBorderEnabled == yearMonthCardBorderEnabled &&
      other.yearMonthCardProfitabilityTintEnabled ==
          yearMonthCardProfitabilityTintEnabled &&
      other.yearMonthCardProfitabilityTintOpacity ==
          yearMonthCardProfitabilityTintOpacity &&
      other.sumLineInterpolationMode == sumLineInterpolationMode &&
      other.sumLineCatmullRomTension == sumLineCatmullRomTension &&
      other.sumLineTemporalSmoothingEnabled ==
          sumLineTemporalSmoothingEnabled &&
      other.sumLineSmoothingWindow == sumLineSmoothingWindow &&
      other.sumLineZoomAdaptiveSmoothingEnabled ==
          sumLineZoomAdaptiveSmoothingEnabled &&
      other.dayTimelineLayout == dayTimelineLayout &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
    paletteStyle,
    scaleResolution,
    scaleMode,
    sliderHandleSize,
    sumYearRowLayout,
    sumMonthLabelPlacement,
    sumVisibleChartCount,
    yearMonthCardBorderEnabled,
    yearMonthCardProfitabilityTintEnabled,
    yearMonthCardProfitabilityTintOpacity,
    sumLineInterpolationMode,
    sumLineCatmullRomTension,
    sumLineTemporalSmoothingEnabled,
    sumLineSmoothingWindow,
    sumLineZoomAdaptiveSmoothingEnabled,
    dayTimelineLayout,
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

  void setScaleMode(MindHeatmapScaleMode mode) {
    final current = value;
    if (current.scaleMode == mode) return;
    value = current.copyWith(scaleMode: mode, revision: current.revision + 1);
  }

  void setSliderHandleSize(MindSliderHandleSize size) {
    final current = value;
    if (current.sliderHandleSize == size) return;
    value = current.copyWith(
      sliderHandleSize: size,
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

  void setSumVisibleChartCount(MindSumVisibleChartCount count) {
    final current = value;
    if (current.sumVisibleChartCount == count) return;
    value = current.copyWith(
      sumVisibleChartCount: count,
      revision: current.revision + 1,
    );
  }

  void setYearMonthCardBorderEnabled(bool enabled) {
    final current = value;
    if (current.yearMonthCardBorderEnabled == enabled) return;
    value = current.copyWith(
      yearMonthCardBorderEnabled: enabled,
      revision: current.revision + 1,
    );
  }

  void setYearMonthCardProfitabilityTintEnabled(bool enabled) {
    final current = value;
    if (current.yearMonthCardProfitabilityTintEnabled == enabled) return;
    value = current.copyWith(
      yearMonthCardProfitabilityTintEnabled: enabled,
      revision: current.revision + 1,
    );
  }

  void setYearMonthCardProfitabilityTintOpacity(double opacity) {
    final normalized = opacity.clamp(0.0, 1.0).toDouble();
    final current = value;
    if (current.yearMonthCardProfitabilityTintOpacity == normalized) return;
    value = current.copyWith(
      yearMonthCardProfitabilityTintOpacity: normalized,
      revision: current.revision + 1,
    );
  }

  @Deprecated('Use setYearMonthCardProfitabilityTintEnabled.')
  void setYearThreeColumnProfitabilityTintEnabled(bool enabled) =>
      setYearMonthCardProfitabilityTintEnabled(enabled);

  @Deprecated('Use setYearMonthCardProfitabilityTintOpacity.')
  void setYearThreeColumnProfitabilityTintOpacity(double opacity) =>
      setYearMonthCardProfitabilityTintOpacity(opacity);

  void setSumLineInterpolationMode(MindSumLineInterpolationMode mode) {
    final current = value;
    if (current.sumLineInterpolationMode == mode) return;
    value = current.copyWith(
      sumLineInterpolationMode: mode,
      revision: current.revision + 1,
    );
  }

  void setSumLineCatmullRomTension(double tension) {
    final normalized = tension.clamp(0.0, 1.0).toDouble();
    final current = value;
    if (current.sumLineCatmullRomTension == normalized) return;
    value = current.copyWith(
      sumLineCatmullRomTension: normalized,
      revision: current.revision + 1,
    );
  }

  void setSumLineTemporalSmoothingEnabled(bool enabled) {
    final current = value;
    if (current.sumLineTemporalSmoothingEnabled == enabled) return;
    value = current.copyWith(
      sumLineTemporalSmoothingEnabled: enabled,
      revision: current.revision + 1,
    );
  }

  void setSumLineSmoothingWindow(MindSumSmoothingWindow window) {
    final current = value;
    if (current.sumLineSmoothingWindow == window) return;
    value = current.copyWith(
      sumLineSmoothingWindow: window,
      revision: current.revision + 1,
    );
  }

  void setSumLineZoomAdaptiveSmoothingEnabled(bool enabled) {
    final current = value;
    if (current.sumLineZoomAdaptiveSmoothingEnabled == enabled) return;
    value = current.copyWith(
      sumLineZoomAdaptiveSmoothingEnabled: enabled,
      revision: current.revision + 1,
    );
  }

  void setDayTimelineLayout(MindDayTimelineLayout layout) {
    final current = value;
    if (current.dayTimelineLayout == layout) return;
    value = current.copyWith(
      dayTimelineLayout: layout,
      revision: current.revision + 1,
    );
  }
}
