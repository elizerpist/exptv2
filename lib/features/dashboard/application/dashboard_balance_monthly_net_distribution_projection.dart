import 'dart:math' as math;

import 'dashboard_balance_retention_stability_projection.dart';

/// One visual interval in the adaptive distribution of complete monthly nets.
///
/// Regular intervals always have the same data-derived width. Underflow and
/// overflow are exceptional aggregate intervals retained for observations
/// outside the robust core; therefore no complete month is discarded.
enum DashboardBalanceHistogramBinKind { underflow, regular, overflow }

final class DashboardBalanceHistogramBin {
  const DashboardBalanceHistogramBin({
    required this.kind,
    required this.startMinor,
    required this.endMinor,
    required this.count,
  });

  final DashboardBalanceHistogramBinKind kind;
  final double startMinor;
  final double endMinor;
  final int count;

  double get widthMinor => endMinor - startMinor;
  double get representativeMinor => (startMinor + endMinor) / 2;
}

/// Immutable, renderer-ready histogram result. Values remain in minor units;
/// the presentation layer only formats and paints them.
final class DashboardBalanceMonthlyNetHistogramPresentation {
  DashboardBalanceMonthlyNetHistogramPresentation({
    required this.sampleCount,
    required this.positiveObservationCount,
    required this.negativeObservationCount,
    required List<DashboardBalanceHistogramBin> bins,
    required List<DashboardBalanceHistogramBin> regularBins,
    required this.regularStartMinor,
    required this.regularEndMinor,
    required this.regularBinWidthMinor,
    required this.hasZeroRegularBoundary,
    required this.minimumObservedMinor,
    required this.maximumObservedMinor,
    required this.medianMinor,
    required this.typicalLowerMinor,
    required this.typicalUpperMinor,
  }) : bins = List<DashboardBalanceHistogramBin>.unmodifiable(bins),
       regularBins = List<DashboardBalanceHistogramBin>.unmodifiable(
         regularBins,
       );

  final int sampleCount;
  final int positiveObservationCount;
  final int negativeObservationCount;
  final List<DashboardBalanceHistogramBin> bins;
  final List<DashboardBalanceHistogramBin> regularBins;
  final double regularStartMinor;
  final double regularEndMinor;
  final double regularBinWidthMinor;
  final bool hasZeroRegularBoundary;
  final double minimumObservedMinor;
  final double maximumObservedMinor;
  final double medianMinor;
  final double? typicalLowerMinor;
  final double? typicalUpperMinor;

  DashboardBalanceHistogramBin? get underflowBin =>
      _firstOf(DashboardBalanceHistogramBinKind.underflow);
  DashboardBalanceHistogramBin? get overflowBin =>
      _firstOf(DashboardBalanceHistogramBinKind.overflow);

  int get assignedSampleCount =>
      bins.fold<int>(0, (sum, bin) => sum + bin.count);

  bool get zeroIsExternalReference => !hasZeroRegularBoundary;

  List<double> get regularBoundariesMinor => List<double>.unmodifiable(<double>[
    if (regularBins.isNotEmpty) regularStartMinor,
    for (final bin in regularBins) bin.endMinor,
  ]);

  /// X-axis fraction in the categorical histogram lane. Regular bins map
  /// continuously to their equal-width positions; exceptional outlier bins
  /// get one visual lane each.
  double xFractionForValue(double valueMinor) {
    if (bins.isEmpty) return .5;
    if (regularBinWidthMinor <= _epsilon) return .5;
    final underflowOffset = underflowBin == null ? 0 : 1;
    if (valueMinor < regularStartMinor) {
      return underflowBin == null ? 0 : .5 / bins.length;
    }
    if (valueMinor > regularEndMinor) {
      return overflowBin == null
          ? 1
          : (underflowOffset + regularBins.length + .5) / bins.length;
    }
    final regularOffset =
        ((valueMinor - regularStartMinor) / regularBinWidthMinor)
            .clamp(0.0, regularBins.length.toDouble())
            .toDouble();
    return ((underflowOffset + regularOffset) / bins.length).clamp(0.0, 1.0);
  }

  /// Returns a visible external zero marker without widening an entirely
  /// positive or negative regular domain merely for the reference line.
  double get zeroReferenceFraction => hasZeroRegularBoundary
      ? xFractionForValue(0)
      : maximumObservedMinor < 0
      ? 1
      : 0;

  DashboardBalanceHistogramBin? _firstOf(
    DashboardBalanceHistogramBinKind kind,
  ) {
    for (final bin in bins) {
      if (bin.kind == kind) return bin;
    }
    return null;
  }
}

final class DashboardBalancePositiveStreakPresentation {
  DashboardBalancePositiveStreakPresentation({
    required this.length,
    required List<int> netValuesMinor,
  }) : netValuesMinor = List<int>.unmodifiable(netValuesMinor);

  final int length;
  final List<int> netValuesMinor;
}

/// Renderer-ready placement model for the SUM Cashflow stability band.
///
/// It preserves the existing stability projection's exact median and typical
/// bounds while providing the one shared axis used by the band rules and all
/// monthly dots. It owns no classification or score label.
final class DashboardBalanceCashflowStabilityBandPresentation {
  DashboardBalanceCashflowStabilityBandPresentation({
    required List<int> observationNetTimesTwo,
    required this.medianNetTimesTwo,
    required this.typicalLowerTimesTwo,
    required this.typicalUpperTimesTwo,
  }) : observationNetTimesTwo = List<int>.unmodifiable(observationNetTimesTwo),
       _axis = _resolveAxis(
         observationNetTimesTwo: observationNetTimesTwo,
         medianNetTimesTwo: medianNetTimesTwo,
         typicalLowerTimesTwo: typicalLowerTimesTwo,
         typicalUpperTimesTwo: typicalUpperTimesTwo,
       );

  final List<int> observationNetTimesTwo;
  final int? medianNetTimesTwo;
  final int? typicalLowerTimesTwo;
  final int? typicalUpperTimesTwo;
  final (int, int) _axis;

  int get sampleCount => observationNetTimesTwo.length;
  bool get isAvailable =>
      sampleCount >=
          DashboardBalanceStabilityPresentation.minimumObservationCount &&
      medianNetTimesTwo != null &&
      typicalLowerTimesTwo != null &&
      typicalUpperTimesTwo != null;
  int get axisMinimumTimesTwo => _axis.$1;
  int get axisMaximumTimesTwo => _axis.$2;

  double xFractionForTimesTwo(int valueTimesTwo) {
    final extent = math.max(1, axisMaximumTimesTwo - axisMinimumTimesTwo);
    return ((valueTimesTwo - axisMinimumTimesTwo) / extent)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static (int, int) _resolveAxis({
    required List<int> observationNetTimesTwo,
    required int? medianNetTimesTwo,
    required int? typicalLowerTimesTwo,
    required int? typicalUpperTimesTwo,
  }) {
    final values = <int>[0, ...observationNetTimesTwo];
    if (medianNetTimesTwo != null) values.add(medianNetTimesTwo);
    if (typicalLowerTimesTwo != null) values.add(typicalLowerTimesTwo);
    if (typicalUpperTimesTwo != null) values.add(typicalUpperTimesTwo);
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    return minimum == maximum ? (minimum - 1, maximum + 1) : (minimum, maximum);
  }
}

/// Shared, immutable result for the two SUM cards that interpret the same
/// complete-month sample: the histogram and the positive closing streak.
final class DashboardBalanceMonthlyNetDistributionPresentation {
  const DashboardBalanceMonthlyNetDistributionPresentation({
    required this.histogram,
    required this.longestPositiveStreak,
    required this.cashflowBand,
  });

  final DashboardBalanceMonthlyNetHistogramPresentation histogram;
  final DashboardBalancePositiveStreakPresentation longestPositiveStreak;
  final DashboardBalanceCashflowStabilityBandPresentation cashflowBand;
}

/// Pure adaptive distribution projection for an already-established complete
/// monthly-net sample. It deliberately consumes the stability DTO, so this
/// class neither re-queries ledger data nor decides which month is open.
abstract final class DashboardBalanceMonthlyNetDistributionProjection {
  static DashboardBalanceMonthlyNetDistributionPresentation build({
    required DashboardBalanceStabilityPresentation stability,
  }) {
    final values = stability.observations
        .map((observation) => observation.netMinor.toDouble())
        .toList(growable: false);
    return DashboardBalanceMonthlyNetDistributionPresentation(
      histogram: _histogram(stability: stability, values: values),
      longestPositiveStreak: _longestPositiveStreak(stability),
      cashflowBand: DashboardBalanceCashflowStabilityBandPresentation(
        observationNetTimesTwo: stability.observations
            .map((observation) => observation.netMinor * 2)
            .toList(growable: false),
        medianNetTimesTwo: stability.medianNetTimesTwo,
        typicalLowerTimesTwo: stability.typicalBandLowerTimesTwo,
        typicalUpperTimesTwo: stability.typicalBandUpperTimesTwo,
      ),
    );
  }

  static DashboardBalanceMonthlyNetHistogramPresentation _histogram({
    required DashboardBalanceStabilityPresentation stability,
    required List<double> values,
  }) {
    if (values.isEmpty) {
      return DashboardBalanceMonthlyNetHistogramPresentation(
        sampleCount: 0,
        positiveObservationCount: 0,
        negativeObservationCount: 0,
        bins: const <DashboardBalanceHistogramBin>[],
        regularBins: const <DashboardBalanceHistogramBin>[],
        regularStartMinor: 0,
        regularEndMinor: 0,
        regularBinWidthMinor: 0,
        hasZeroRegularBoundary: false,
        minimumObservedMinor: 0,
        maximumObservedMinor: 0,
        medianMinor: 0,
        typicalLowerMinor: null,
        typicalUpperMinor: null,
      );
    }
    final sorted = List<double>.of(values)..sort();
    final minimum = sorted.first;
    final maximum = sorted.last;
    final median = _median(sorted);
    final deviations =
        sorted.map((value) => (value - median).abs()).toList(growable: false)
          ..sort();
    final mad = _median(deviations);
    final q1 = _quantile(sorted, .25);
    final q3 = _quantile(sorted, .75);
    final iqr = q3 - q1;
    final typical = stability.isAvailable
        ? (
            stability.typicalBandLowerTimesTwo! / 2,
            stability.typicalBandUpperTimesTwo! / 2,
          )
        : (null, null);

    if ((maximum - minimum).abs() <= _epsilon) {
      final identical = DashboardBalanceHistogramBin(
        kind: DashboardBalanceHistogramBinKind.regular,
        startMinor: minimum,
        endMinor: maximum,
        count: values.length,
      );
      return DashboardBalanceMonthlyNetHistogramPresentation(
        sampleCount: values.length,
        positiveObservationCount: values.where((value) => value > 0).length,
        negativeObservationCount: values.where((value) => value < 0).length,
        bins: <DashboardBalanceHistogramBin>[identical],
        regularBins: <DashboardBalanceHistogramBin>[identical],
        regularStartMinor: minimum,
        regularEndMinor: maximum,
        regularBinWidthMinor: 0,
        hasZeroRegularBoundary: minimum == 0,
        minimumObservedMinor: minimum,
        maximumObservedMinor: maximum,
        medianMinor: stability.medianNetTimesTwo == null
            ? median
            : stability.medianNetTimesTwo! / 2,
        typicalLowerMinor: typical.$1,
        typicalUpperMinor: typical.$2,
      );
    }

    final fences = _robustFences(
      iqr: iqr,
      mad: mad,
      q1: q1,
      q3: q3,
      median: median,
    );
    final core = values
        .where((value) => value >= fences.$1 && value <= fences.$2)
        .toList(growable: false);
    final coreValues = core.isEmpty ? values : core;
    final coreMinimum = coreValues.reduce(math.min);
    final coreMaximum = coreValues.reduce(math.max);
    final coreRange = coreMaximum - coreMinimum;
    final fallbackTarget = math.min(
      5,
      math.max(2, math.pow(values.length, 1 / 3).ceil()),
    );
    var rawWidth = iqr > _epsilon
        ? 2 * iqr / math.pow(values.length, 1 / 3)
        : mad > _epsilon
        ? 2 * mad / math.pow(values.length, 1 / 3)
        : coreRange / fallbackTarget;
    if (rawWidth <= _epsilon) rawWidth = coreRange / fallbackTarget;
    var binWidth = _niceStep(rawWidth);
    if (binWidth <= _epsilon) binWidth = coreRange;
    var domain = _domain(coreMinimum, coreMaximum, binWidth);
    for (var attempt = 0; domain.$3 > 11 && attempt < 8; attempt += 1) {
      binWidth = _niceStep(binWidth * 1.7);
      domain = _domain(coreMinimum, coreMaximum, binWidth);
    }

    final counts = List<int>.filled(domain.$3, 0);
    var underflowCount = 0;
    var overflowCount = 0;
    for (final value in values) {
      if (value < fences.$1) {
        underflowCount += 1;
      } else if (value > fences.$2) {
        overflowCount += 1;
      } else {
        final index = ((value - domain.$1) / binWidth).floor().clamp(
          0,
          counts.length - 1,
        );
        counts[index] += 1;
      }
    }
    final regularBins = List<DashboardBalanceHistogramBin>.generate(
      counts.length,
      (index) => DashboardBalanceHistogramBin(
        kind: DashboardBalanceHistogramBinKind.regular,
        startMinor: domain.$1 + index * binWidth,
        endMinor: domain.$1 + (index + 1) * binWidth,
        count: counts[index],
      ),
      growable: false,
    );
    final bins = <DashboardBalanceHistogramBin>[
      if (underflowCount > 0)
        DashboardBalanceHistogramBin(
          kind: DashboardBalanceHistogramBinKind.underflow,
          startMinor: minimum,
          endMinor: fences.$1,
          count: underflowCount,
        ),
      ...regularBins,
      if (overflowCount > 0)
        DashboardBalanceHistogramBin(
          kind: DashboardBalanceHistogramBinKind.overflow,
          startMinor: fences.$2,
          endMinor: maximum,
          count: overflowCount,
        ),
    ];
    final crossesZero = domain.$1 <= 0 && domain.$2 >= 0;
    return DashboardBalanceMonthlyNetHistogramPresentation(
      sampleCount: values.length,
      positiveObservationCount: values.where((value) => value > 0).length,
      negativeObservationCount: values.where((value) => value < 0).length,
      bins: bins,
      regularBins: regularBins,
      regularStartMinor: domain.$1,
      regularEndMinor: domain.$2,
      regularBinWidthMinor: binWidth,
      hasZeroRegularBoundary: crossesZero,
      minimumObservedMinor: minimum,
      maximumObservedMinor: maximum,
      medianMinor: stability.medianNetTimesTwo == null
          ? median
          : stability.medianNetTimesTwo! / 2,
      typicalLowerMinor: typical.$1,
      typicalUpperMinor: typical.$2,
    );
  }

  static DashboardBalancePositiveStreakPresentation _longestPositiveStreak(
    DashboardBalanceStabilityPresentation stability,
  ) {
    var activeStart = 0;
    var activeLength = 0;
    var bestStart = -1;
    var bestLength = 0;
    final values = stability.observations
        .map((observation) => observation.netMinor)
        .toList(growable: false);
    for (var index = 0; index < values.length; index += 1) {
      if (values[index] > 0) {
        if (activeLength == 0) activeStart = index;
        activeLength += 1;
        if (activeLength > bestLength) {
          bestStart = activeStart;
          bestLength = activeLength;
        }
      } else {
        activeLength = 0;
      }
    }
    return DashboardBalancePositiveStreakPresentation(
      length: bestLength,
      netValuesMinor: bestStart < 0
          ? const <int>[]
          : values.sublist(bestStart, bestStart + bestLength),
    );
  }

  static (double, double) _robustFences({
    required double iqr,
    required double mad,
    required double q1,
    required double q3,
    required double median,
  }) {
    if (iqr > _epsilon) return (q1 - 1.5 * iqr, q3 + 1.5 * iqr);
    if (mad > _epsilon) return (median - 3 * mad, median + 3 * mad);
    return (double.negativeInfinity, double.infinity);
  }

  static (double, double, int) _domain(
    double minimum,
    double maximum,
    double step,
  ) {
    final start = (minimum / step).floor() * step;
    var end = (maximum / step).ceil() * step;
    if ((end - start).abs() <= _epsilon) end = start + step;
    final count = math.max(1, ((end - start) / step).round());
    return (start, start + count * step, count);
  }

  static double _niceStep(double rawStep) {
    if (rawStep <= _epsilon) return 0;
    final magnitude = math.pow(10, math.log(rawStep) ~/ math.ln10).toDouble();
    final normalized = rawStep / magnitude;
    const candidates = <double>[1, 2, 2.5, 5, 10];
    final nearest = candidates.reduce(
      (closest, candidate) =>
          (candidate - normalized).abs() < (closest - normalized).abs()
          ? candidate
          : closest,
    );
    return nearest * magnitude;
  }

  static double _median(List<double> sorted) {
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double _quantile(List<double> sorted, double quantile) {
    final position = (sorted.length - 1) * quantile;
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower);
  }
}

const double _epsilon = 1e-9;
