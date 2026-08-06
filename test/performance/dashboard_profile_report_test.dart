import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/dashboard_profile_report.dart';

void main() {
  test('adds exact p50 p90 p95 and p99 frame percentiles', () {
    final summary = <String, dynamic>{
      'frame_build_times': <int>[5000, 1000, 3000, 2000, 4000],
      'frame_rasterizer_times': <int>[10000, 2000, 6000, 4000, 8000],
    };

    DashboardProfileReport.addRequiredPercentiles(summary);

    expect(summary['50th_percentile_frame_build_time_millis'], 3.0);
    expect(summary['90th_percentile_frame_build_time_millis'], 5.0);
    expect(summary['95th_percentile_frame_build_time_millis'], 5.0);
    expect(summary['99th_percentile_frame_build_time_millis'], 5.0);
    expect(summary['50th_percentile_frame_rasterizer_time_millis'], 6.0);
    expect(summary['90th_percentile_frame_rasterizer_time_millis'], 10.0);
    expect(summary['95th_percentile_frame_rasterizer_time_millis'], 10.0);
    expect(summary['99th_percentile_frame_rasterizer_time_millis'], 10.0);
  });

  test('required scenario schema includes every requested duration lane', () {
    expect(
      DashboardProfileReport.requiredScenarioMetricKeys,
      containsAll(<String>[
        'platform_channel_duration_micros',
        'platform_call_count',
        'sql_duration_micros',
        'sql_call_count',
        'dart_parsing_duration_micros',
        'prepared_projection_duration_micros',
        'first_valid_paint_micros',
        'index_publish_duration_micros',
        'peak_rss_bytes',
        'prepared_index_bytes',
      ]),
    );
  });

  test('scenario schema validation rejects a missing metric', () {
    final report = <String, Object?>{
      for (final key in DashboardProfileReport.requiredScenarioMetricKeys)
        key: 0,
    };
    report['startup_index_metrics'] = _startupMetrics();

    expect(
      () => DashboardProfileReport.validateRequiredScenarioMetrics(report),
      returnsNormally,
    );
    report.remove('sql_duration_micros');
    expect(
      () => DashboardProfileReport.validateRequiredScenarioMetrics(report),
      throwsA(isA<StateError>()),
    );
  });

  test('motion isolation gate records renderer misses without masking I/O', () {
    final reports = <String, Map<String, Object?>>{
      'A': _motionGateReport(buildMisses: 2, rasterMisses: 36),
      'B': _motionGateReport(buildMisses: 1, rasterMisses: 24),
    };

    expect(
      () => DashboardProfileReport.validateMotionIsolationGate(reports),
      returnsNormally,
    );

    final counters = Map<String, Object?>.from(
      reports['B']!['performance_counters']! as Map,
    );
    counters['sqlCallsDuringMotion'] = 1;
    reports['B']!['performance_counters'] = counters;
    expect(
      () => DashboardProfileReport.validateMotionIsolationGate(reports),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('B'), contains('sqlCallsDuringMotion')),
        ),
      ),
    );
  });

  test('motion isolation gate rejects a long UI-isolate build task', () {
    final reports = <String, Map<String, Object?>>{
      'A': _motionGateReport(
        buildMisses: 1,
        rasterMisses: 24,
        worstBuildMillis: 48.001,
      ),
    };

    expect(
      () => DashboardProfileReport.validateMotionIsolationGate(reports),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('A'), contains('48.001')),
        ),
      ),
    );
  });

  test('physical frame targets report and reject exact p95/p99 lanes', () {
    final passing = <String, Map<String, Object?>>{'A': _physicalFrameReport()};
    expect(
      DashboardProfileReport.physicalFrameTargetReport(passing)['passed'],
      isTrue,
    );
    expect(
      () => DashboardProfileReport.validatePhysicalFrameTargets(passing),
      returnsNormally,
    );

    final failing = <String, Map<String, Object?>>{
      'A': _physicalFrameReport()
        ..['99th_percentile_frame_rasterizer_time_millis'] = 24.001,
    };
    expect(
      () => DashboardProfileReport.validatePhysicalFrameTargets(failing),
      throwsA(isA<StateError>()),
    );
  });

  test('semantic traversal retains every crossed cyclic boundary', () {
    final sequence = <int>[];

    DashboardProfileReport.appendSemanticTraversal(
      sequence,
      previousRawIndex: 6,
      currentRawIndex: 15,
      normalize: (index) => index % 12,
    );

    expect(sequence, <int>[7, 8, 9, 10, 11, 0, 1, 2, 3]);
  });

  test('semantic traversal is deterministic in both directions', () {
    final forward = <int>[];
    final reverse = <int>[];

    DashboardProfileReport.appendSemanticTraversal(
      forward,
      previousRawIndex: 13,
      currentRawIndex: 22,
      normalize: (index) => index % 31,
    );
    DashboardProfileReport.appendSemanticTraversal(
      reverse,
      previousRawIndex: 22,
      currentRawIndex: 13,
      normalize: (index) => index % 31,
    );

    expect(forward, <int>[14, 15, 16, 17, 18, 19, 20, 21, 22]);
    expect(reverse, <int>[21, 20, 19, 18, 17, 16, 15, 14, 13]);
  });
}

Map<String, Object?> _startupMetrics() => <String, Object?>{
  'sql_call_count': 5,
  'sql_duration_micros': 1,
  'native_query_micros': 1,
  'native_aggregation_micros': 1,
  'native_mapping_micros': 1,
  'serialization_micros': 1,
  'bridge_transfer_micros': 1,
  'dart_decode_micros': 1,
  'dart_projection_micros': 1,
  'index_publish_micros': 1,
  'first_valid_paint_micros': 1,
  'payload_bytes': 1,
  'estimated_index_bytes': 1,
};

Map<String, Object?> _motionGateReport({
  required int buildMisses,
  required int rasterMisses,
  double worstBuildMillis = 35,
}) => <String, Object?>{
  'missed_frame_build_budget_count': buildMisses,
  'missed_frame_rasterizer_budget_count': rasterMisses,
  'worst_frame_build_time_millis': worstBuildMillis,
  'max_publishes_per_display_frame': 1,
  'rail_target_index': 22,
  'rail_settle_index': 22,
  'controller_recreation_count': 0,
  'physics_recreation_count': 0,
  'scroll_position_recreation_count': 0,
  'verbose_flow_enabled': false,
  'performance_counters': <String, Object?>{
    'sqlCallsDuringMotion': 0,
    'platformCallsDuringMotion': 0,
    'repositoryReadsDuringMotion': 0,
    'liveLeaseStartsDuringMotion': 0,
    'logBoxProjectionsDuringMotion': 0,
    'formattingDuringMotion': 0,
  },
};

Map<String, Object?> _physicalFrameReport() => <String, Object?>{
  '95th_percentile_frame_build_time_millis': 16,
  '95th_percentile_frame_rasterizer_time_millis': 16,
  '99th_percentile_frame_build_time_millis': 23,
  '99th_percentile_frame_rasterizer_time_millis': 23,
  'worst_frame_build_time_millis': 47,
  'worst_frame_rasterizer_time_millis': 47,
};
