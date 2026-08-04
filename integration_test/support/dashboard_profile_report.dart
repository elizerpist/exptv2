import 'dart:math' as math;

abstract final class DashboardProfileReport {
  static int percentileMicros(List<int> values, double percentile) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
    if (percentile <= 0 || percentile > 1) {
      throw ArgumentError.value(
        percentile,
        'percentile',
        'must be greater than zero and at most one',
      );
    }
    final sorted = List<int>.of(values)..sort();
    final rank = math.max(1, (percentile * sorted.length).ceil());
    return sorted[rank - 1];
  }

  static void addRequiredPercentiles(Map<String, dynamic> summary) {
    _addPercentiles(
      summary,
      rawKey: 'frame_build_times',
      label: 'frame_build_time',
    );
    _addPercentiles(
      summary,
      rawKey: 'frame_rasterizer_times',
      label: 'frame_rasterizer_time',
    );
  }

  static double? densityDeltaPercent(num baseline, num candidate) {
    if (baseline == 0) return null;
    return ((candidate - baseline) / baseline) * 100.0;
  }

  static Map<String, Object?> compareDensityP95(
    Map<int, Map<String, dynamic>> reportsByDensity, {
    double targetMaxAbsoluteDeltaPercent = 10,
  }) {
    const referenceDensity = 94;
    const candidateDensities = <int>[0, 1000];
    final reference = reportsByDensity[referenceDensity];
    if (reference == null) {
      throw ArgumentError.value(
        reportsByDensity.keys,
        'reportsByDensity',
        'must contain the 94-row reference report',
      );
    }

    final buildDeltas = <String, double>{};
    final rasterDeltas = <String, double>{};
    var withinTarget = true;
    for (final density in candidateDensities) {
      final candidate = reportsByDensity[density];
      if (candidate == null) {
        throw ArgumentError.value(
          reportsByDensity.keys,
          'reportsByDensity',
          'must contain the $density-row candidate report',
        );
      }
      final buildDelta = _requiredDensityDelta(
        reference,
        candidate,
        '95th_percentile_frame_build_time_millis',
      );
      final rasterDelta = _requiredDensityDelta(
        reference,
        candidate,
        '95th_percentile_frame_rasterizer_time_millis',
      );
      buildDeltas['$density'] = buildDelta;
      rasterDeltas['$density'] = rasterDelta;
      withinTarget =
          withinTarget &&
          buildDelta.abs() <= targetMaxAbsoluteDeltaPercent &&
          rasterDelta.abs() <= targetMaxAbsoluteDeltaPercent;
    }

    return <String, Object?>{
      'reference_density': referenceDensity,
      'candidate_densities': candidateDensities,
      'target_max_absolute_delta_percent': targetMaxAbsoluteDeltaPercent
          .toDouble(),
      'frame_build_p95_delta_percent': buildDeltas,
      'frame_raster_p95_delta_percent': rasterDeltas,
      'within_target': withinTarget,
      // Each density scenario asserts visible target/query identity before it
      // is admitted to this aggregate report.
      'target_drift_detected': false,
    };
  }

  static void _addPercentiles(
    Map<String, dynamic> summary, {
    required String rawKey,
    required String label,
  }) {
    final raw = summary[rawKey];
    if (raw is! List || raw.isEmpty) return;
    final values = raw.map((value) => (value as num).toInt()).toList();
    summary['50th_percentile_${label}_millis'] =
        percentileMicros(values, 0.50) / 1000.0;
    summary['90th_percentile_${label}_millis'] =
        percentileMicros(values, 0.90) / 1000.0;
    summary['95th_percentile_${label}_millis'] =
        percentileMicros(values, 0.95) / 1000.0;
    summary['99th_percentile_${label}_millis'] =
        percentileMicros(values, 0.99) / 1000.0;
  }

  static double _requiredDensityDelta(
    Map<String, dynamic> reference,
    Map<String, dynamic> candidate,
    String key,
  ) {
    final baseline = reference[key];
    final value = candidate[key];
    if (baseline is! num || value is! num) {
      throw ArgumentError('Missing numeric $key in a density report.');
    }
    final delta = densityDeltaPercent(baseline, value);
    if (delta == null) {
      throw ArgumentError.value(baseline, key, 'reference must be non-zero');
    }
    return double.parse(delta.toStringAsFixed(6));
  }
}
