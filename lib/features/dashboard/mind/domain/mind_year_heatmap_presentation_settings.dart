import 'package:flutter/foundation.dart';

/// Pure presentation alternatives over one immutable Mind annual data frame.
enum MindYearHeatmapPaletteStyle {
  fluvi,
  b3mMy3;

  String get tunerLabel => switch (this) {
    MindYearHeatmapPaletteStyle.fluvi => 'Fluvi',
    MindYearHeatmapPaletteStyle.b3mMy3 => 'B3M-MY3',
  };
}

enum MindYearMonthCardLayout {
  threeColumns,
  twoColumns,
  fourColumns;

  String get tunerLabel => switch (this) {
    MindYearMonthCardLayout.threeColumns => '3 × 4',
    MindYearMonthCardLayout.twoColumns => '2 × 6',
    MindYearMonthCardLayout.fourColumns => '4 × 3',
  };

  int get columnCount => switch (this) {
    MindYearMonthCardLayout.threeColumns => 3,
    MindYearMonthCardLayout.twoColumns => 2,
    MindYearMonthCardLayout.fourColumns => 4,
  };

  bool get fitsAnnualViewport => this == fourColumns;

  /// The four-column annual grid needs an additional physical Mind-body
  /// envelope once it is actually selected. Keeping this on the presentation
  /// choice prevents ordinary Sum/Month/Day and 2 × 6/3 × 4 Mind surfaces
  /// from needlessly taking vertical room away from the LogBox.
  double get requiredMindModeContentExtraHeight => switch (this) {
    MindYearMonthCardLayout.fourColumns => 50,
    MindYearMonthCardLayout.threeColumns ||
    MindYearMonthCardLayout.twoColumns => 0,
  };
}

/// Immutable user preferences for visualizing an admitted annual heatmap.
/// None of these values changes financial membership, Query state or score.
@immutable
final class MindYearHeatmapPresentationSettings {
  const MindYearHeatmapPresentationSettings({
    required this.paletteStyle,
    required this.monthCardLayout,
    required this.showMonthlyNetClose,
    required this.showMonthlyDirectionTotal,
    required this.revision,
  });

  const MindYearHeatmapPresentationSettings.defaults()
    : paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
      monthCardLayout = MindYearMonthCardLayout.threeColumns,
      showMonthlyNetClose = false,
      showMonthlyDirectionTotal = false,
      revision = 0;

  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindYearMonthCardLayout monthCardLayout;
  final bool showMonthlyNetClose;
  final bool showMonthlyDirectionTotal;
  final int revision;

  MindYearHeatmapPresentationSettings copyWith({
    MindYearHeatmapPaletteStyle? paletteStyle,
    MindYearMonthCardLayout? monthCardLayout,
    bool? showMonthlyNetClose,
    bool? showMonthlyDirectionTotal,
    int? revision,
  }) => MindYearHeatmapPresentationSettings(
    paletteStyle: paletteStyle ?? this.paletteStyle,
    monthCardLayout: monthCardLayout ?? this.monthCardLayout,
    showMonthlyNetClose: showMonthlyNetClose ?? this.showMonthlyNetClose,
    showMonthlyDirectionTotal:
        showMonthlyDirectionTotal ?? this.showMonthlyDirectionTotal,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is MindYearHeatmapPresentationSettings &&
      other.paletteStyle == paletteStyle &&
      other.monthCardLayout == monthCardLayout &&
      other.showMonthlyNetClose == showMonthlyNetClose &&
      other.showMonthlyDirectionTotal == showMonthlyDirectionTotal &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
    paletteStyle,
    monthCardLayout,
    showMonthlyNetClose,
    showMonthlyDirectionTotal,
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

  void setMonthCardLayout(MindYearMonthCardLayout layout) {
    final current = value;
    if (current.monthCardLayout == layout) return;
    value = current.copyWith(
      monthCardLayout: layout,
      revision: current.revision + 1,
    );
  }

  void setShowMonthlyNetClose(bool show) {
    final current = value;
    if (current.showMonthlyNetClose == show) return;
    value = current.copyWith(
      showMonthlyNetClose: show,
      revision: current.revision + 1,
    );
  }

  void setShowMonthlyDirectionTotal(bool show) {
    final current = value;
    if (current.showMonthlyDirectionTotal == show) return;
    value = current.copyWith(
      showMonthlyDirectionTotal: show,
      revision: current.revision + 1,
    );
  }
}
