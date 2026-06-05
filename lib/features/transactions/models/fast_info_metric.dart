enum FastInfoProgressKind { bar, ring }

enum FastInfoChartKind { sparkline, weeklyBars, multiLine }

enum FastInfoSemantic { neutral, good, warning, bad }

enum FastInfoTrendDirection { up, down }

enum FastInfoVisualKind {
  none,
  thresholdMarkerBar,
  deviationMeter,
  sameDayIndexMarker,
  goalMarker,
  zoneMarker,
  avatar,
  projectionFill,
  overflowRisk,
  activityStrip,
  spikeLine,
  sevenDayStrip,
  miniAvatarRow,
  analogMeter,
  fixedLoad,
  paidRemainingSplit,
  incomeComparisonBars,
  remainingSpentSplit,
}

class FastInfoTrend {
  const FastInfoTrend({
    required this.direction,
    required this.text,
    required this.semantic,
  });

  final FastInfoTrendDirection direction;
  final String text;
  final FastInfoSemantic semantic;
}

class FastInfoAvatar {
  const FastInfoAvatar({required this.colorHex, required this.iconSlot});

  final String colorHex;
  final int? iconSlot;
}

class FastInfoChartSeries {
  const FastInfoChartSeries({required this.label, required this.values});

  final String label;
  final List<double> values;
}

class FastInfoWeeklyBar {
  const FastInfoWeeklyBar({
    required this.value,
    required this.isFuture,
    required this.semantic,
  });

  final double value;
  final bool isFuture;
  final FastInfoSemantic semantic;
}

class FastInfoVisualPoint {
  const FastInfoVisualPoint({
    required this.label,
    required this.value,
    this.semantic = FastInfoSemantic.neutral,
    this.avatar,
    this.isToday = false,
    this.isFuture = false,
  });

  final String label;
  final double value;
  final FastInfoSemantic semantic;
  final FastInfoAvatar? avatar;
  final bool isToday;
  final bool isFuture;
}

class FastInfoVisualDescriptor {
  const FastInfoVisualDescriptor({
    required this.kind,
    this.value,
    this.marker,
    this.compareValue,
    this.semantic = FastInfoSemantic.neutral,
    this.avatar,
    this.values = const <double>[],
    this.series = const <FastInfoChartSeries>[],
    this.points = const <FastInfoVisualPoint>[],
  });

  static const none = FastInfoVisualDescriptor(kind: FastInfoVisualKind.none);

  final FastInfoVisualKind kind;
  final double? value;
  final double? marker;
  final double? compareValue;
  final FastInfoSemantic semantic;
  final FastInfoAvatar? avatar;
  final List<double> values;
  final List<FastInfoChartSeries> series;
  final List<FastInfoVisualPoint> points;
}

class FastInfoMetricResult {
  const FastInfoMetricResult({
    required this.pillValue,
    required this.primaryValue,
    this.secondaryValues = const <String>[],
    this.progressKind,
    this.chartKind,
    this.semantic = FastInfoSemantic.neutral,
    this.progress,
    this.trend,
    this.avatar,
    this.visual = FastInfoVisualDescriptor.none,
    this.chartSeries = const <FastInfoChartSeries>[],
    this.weeklyBars = const <FastInfoWeeklyBar>[],
  });

  final String pillValue;
  final String primaryValue;
  final List<String> secondaryValues;
  final FastInfoProgressKind? progressKind;
  final FastInfoChartKind? chartKind;
  final FastInfoSemantic semantic;
  final double? progress;
  final FastInfoTrend? trend;
  final FastInfoAvatar? avatar;
  final FastInfoVisualDescriptor visual;
  final List<FastInfoChartSeries> chartSeries;
  final List<FastInfoWeeklyBar> weeklyBars;

  String get boxValue => primaryValue;
  String get boxSubtitle => secondaryValues.join(' · ');
  List<double> get series =>
      chartSeries.isEmpty ? const <double>[] : chartSeries.first.values;
}
