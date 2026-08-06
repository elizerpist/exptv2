import 'dart:math' as math;

abstract final class DashboardProfileReport {
  static const List<String> requiredScenarioMetricKeys = <String>[
    '50th_percentile_frame_build_time_millis',
    '90th_percentile_frame_build_time_millis',
    '95th_percentile_frame_build_time_millis',
    '99th_percentile_frame_build_time_millis',
    '50th_percentile_frame_rasterizer_time_millis',
    '90th_percentile_frame_rasterizer_time_millis',
    '95th_percentile_frame_rasterizer_time_millis',
    '99th_percentile_frame_rasterizer_time_millis',
    'worst_frame_build_time_millis',
    'worst_frame_rasterizer_time_millis',
    'missed_frame_build_budget_count',
    'missed_frame_rasterizer_budget_count',
    'motion_duration_micros',
    'performance_counters',
    'gc',
    'allocation_burst_rss_bytes',
    'peak_rss_bytes',
    'first_valid_paint_micros',
    'index_publish_duration_micros',
    'prepared_index_bytes',
    'vector_picture_decode_count',
    'vector_picture_prepare_duration_micros',
    'vector_picture_decodes_during_motion',
    'startup_index_metrics',
    'platform_channel_duration_micros',
    'platform_call_count',
    'sql_duration_micros',
    'sql_call_count',
    'dart_parsing_duration_micros',
    'prepared_projection_duration_micros',
    'visible_publish_count',
    'max_publishes_per_display_frame',
    'rail_target_index',
    'rail_settle_index',
    'controller_recreation_count',
    'physics_recreation_count',
    'scroll_position_recreation_count',
    'verbose_flow_enabled',
  ];

  static const double maxUiIsolateTaskMillis = 48;
  static const double p95FrameTargetMillis = 16.7;
  static const double p99FrameTargetMillis = 24;
  static const double maximumFrameTargetMillis = 48;

  static const List<String> motionIsolationCounterKeys = <String>[
    'sqlCallsDuringMotion',
    'platformCallsDuringMotion',
    'repositoryReadsDuringMotion',
    'liveLeaseStartsDuringMotion',
    'logBoxProjectionsDuringMotion',
    'formattingDuringMotion',
  ];

  static void validateRequiredScenarioMetrics(Map<String, Object?> report) {
    final missing = requiredScenarioMetricKeys
        .where((key) => !report.containsKey(key))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError('Dashboard profile report is missing: $missing');
    }
    for (final key in const <String>[
      'platform_channel_duration_micros',
      'platform_call_count',
      'sql_duration_micros',
      'sql_call_count',
      'dart_parsing_duration_micros',
      'prepared_projection_duration_micros',
      'peak_rss_bytes',
      'first_valid_paint_micros',
      'index_publish_duration_micros',
      'prepared_index_bytes',
      'vector_picture_decode_count',
      'vector_picture_prepare_duration_micros',
      'vector_picture_decodes_during_motion',
    ]) {
      final value = report[key];
      if (value is! num || value < 0) {
        throw StateError('Dashboard profile metric $key must be nonnegative.');
      }
    }
    final startup = report['startup_index_metrics'];
    if (startup is! Map) {
      throw StateError('Dashboard profile startup metrics must be a map.');
    }
    for (final key in const <String>[
      'sql_call_count',
      'sql_duration_micros',
      'native_query_micros',
      'native_aggregation_micros',
      'native_mapping_micros',
      'serialization_micros',
      'bridge_transfer_micros',
      'dart_decode_micros',
      'dart_projection_micros',
      'index_publish_micros',
      'first_valid_paint_micros',
      'payload_bytes',
      'estimated_index_bytes',
    ]) {
      final value = startup[key];
      if (value is! num || value < 0) {
        throw StateError(
          'Dashboard profile startup metric $key must be nonnegative.',
        );
      }
    }
  }

  /// Validates the causal motion/data boundary while retaining frame-budget
  /// misses as measured evidence.
  ///
  /// The pinned CI renderer is gfxstream Swangle backed by SwiftShader. Its
  /// raster time can exceed a physical display budget even when the Dart UI
  /// path is idle, so raster misses cannot diagnose data coupling. The gate
  /// instead rejects any motion-time data work, identity recreation, multiple
  /// publications in one display frame, target drift, verbose logging, or a
  /// long Dart UI-isolate build task. Build and raster misses remain in every
  /// JSON report and are never rewritten or suppressed.
  static void validateMotionIsolationGate<T extends Object?>(
    Map<String, Map<String, T>> reports,
  ) {
    if (reports.isEmpty) {
      throw StateError('Dashboard profile has no scenarios.');
    }
    for (final entry in reports.entries) {
      final scenario = entry.key;
      final report = entry.value;
      final buildMisses = entry.value['missed_frame_build_budget_count'];
      final rasterMisses = entry.value['missed_frame_rasterizer_budget_count'];
      if (buildMisses is! num ||
          buildMisses < 0 ||
          rasterMisses is! num ||
          rasterMisses < 0) {
        throw StateError(
          'Dashboard profile $scenario has invalid frame-budget metrics.',
        );
      }

      final worstBuild = report['worst_frame_build_time_millis'];
      if (worstBuild is! num ||
          !worstBuild.toDouble().isFinite ||
          worstBuild < 0 ||
          worstBuild > maxUiIsolateTaskMillis) {
        throw StateError(
          'Dashboard profile $scenario has a long UI-isolate build task: '
          '$worstBuild ms (limit $maxUiIsolateTaskMillis ms).',
        );
      }

      final maximumPublishes = report['max_publishes_per_display_frame'];
      if (maximumPublishes is! num ||
          maximumPublishes < 0 ||
          maximumPublishes > 1) {
        throw StateError(
          'Dashboard profile $scenario published $maximumPublishes visible '
          'frames in one display frame.',
        );
      }

      final vectorDecodes = report['vector_picture_decodes_during_motion'];
      if (vectorDecodes is! num || vectorDecodes != 0) {
        throw StateError(
          'Dashboard profile $scenario has '
          'vector_picture_decodes_during_motion=$vectorDecodes; expected 0.',
        );
      }

      final target = report['rail_target_index'];
      final settle = report['rail_settle_index'];
      if (target is! num || settle is! num || target != settle) {
        throw StateError(
          'Dashboard profile $scenario target/settle drifted: '
          'target=$target settle=$settle.',
        );
      }

      for (final key in const <String>[
        'controller_recreation_count',
        'physics_recreation_count',
        'scroll_position_recreation_count',
      ]) {
        final value = report[key];
        if (value is! num || value != 0) {
          throw StateError(
            'Dashboard profile $scenario has $key=$value; expected 0.',
          );
        }
      }

      final counters = report['performance_counters'];
      if (counters is! Map) {
        throw StateError(
          'Dashboard profile $scenario has invalid performance counters.',
        );
      }
      for (final key in motionIsolationCounterKeys) {
        final value = counters[key];
        if (value is! num || value != 0) {
          throw StateError(
            'Dashboard profile $scenario has $key=$value; expected 0.',
          );
        }
      }

      if (report['verbose_flow_enabled'] != false) {
        throw StateError(
          'Dashboard profile $scenario must disable verbose flow logging.',
        );
      }
    }
  }

  static Map<String, Object?> physicalFrameTargetReport<T extends Object?>(
    Map<String, Map<String, T>> reports,
  ) {
    final failures = <String>[];
    for (final entry in reports.entries) {
      final scenario = entry.key;
      final report = entry.value;
      void requireAtMost(String key, double limit) {
        final value = report[key];
        if (value is! num || !value.toDouble().isFinite || value > limit) {
          failures.add('$scenario:$key=$value>$limit');
        }
      }

      requireAtMost(
        '95th_percentile_frame_build_time_millis',
        p95FrameTargetMillis,
      );
      requireAtMost(
        '95th_percentile_frame_rasterizer_time_millis',
        p95FrameTargetMillis,
      );
      requireAtMost(
        '99th_percentile_frame_build_time_millis',
        p99FrameTargetMillis,
      );
      requireAtMost(
        '99th_percentile_frame_rasterizer_time_millis',
        p99FrameTargetMillis,
      );
      requireAtMost('worst_frame_build_time_millis', maximumFrameTargetMillis);
      requireAtMost(
        'worst_frame_rasterizer_time_millis',
        maximumFrameTargetMillis,
      );
    }
    return <String, Object?>{
      'environment_requirement': 'physical-device-profile',
      'p95_limit_millis': p95FrameTargetMillis,
      'p99_limit_millis': p99FrameTargetMillis,
      'maximum_frame_millis': maximumFrameTargetMillis,
      'passed': failures.isEmpty,
      'failures': failures,
    };
  }

  static void validatePhysicalFrameTargets<T extends Object?>(
    Map<String, Map<String, T>> reports,
  ) {
    final result = physicalFrameTargetReport(reports);
    if (result['passed'] != true) {
      throw StateError(
        'Dashboard physical-device frame targets failed: '
        '${result['failures']}',
      );
    }
  }

  /// Records the semantic boundaries physically traversed between two raw
  /// carousel positions.
  ///
  /// The engine may sample several item boundaries in one display frame. The
  /// visible-frame coalescer intentionally publishes only that frame's last
  /// target, so visible publications are not a valid motion-sequence probe.
  /// This profile-only observer reconstructs the ordered boundary traversal
  /// without changing motion, physics, presentation, or production logging.
  static void appendSemanticTraversal(
    List<int> sequence, {
    required int previousRawIndex,
    required int currentRawIndex,
    required int Function(int rawIndex) normalize,
  }) {
    if (previousRawIndex == currentRawIndex) return;
    final step = currentRawIndex > previousRawIndex ? 1 : -1;
    for (var rawIndex = previousRawIndex + step; ; rawIndex += step) {
      final semanticIndex = normalize(rawIndex);
      if (sequence.isEmpty || sequence.last != semanticIndex) {
        sequence.add(semanticIndex);
      }
      if (rawIndex == currentRawIndex) return;
    }
  }

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
