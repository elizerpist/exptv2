enum FastInfoProgressKind { bar, ring }

enum FastInfoChartKind { sparkline, weeklyBars, multiLine }

enum FastInfoSemantic { neutral, good, warning, bad }

enum FastInfoTrendDirection { up, down }

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
  final List<FastInfoChartSeries> chartSeries;
  final List<FastInfoWeeklyBar> weeklyBars;
}
