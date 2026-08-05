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
      ]),
    );
  });

  test('scenario schema validation rejects a missing metric', () {
    final report = <String, Object?>{
      for (final key in DashboardProfileReport.requiredScenarioMetricKeys)
        key: 0,
    };

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

  test('frame budget validation runs across the complete scenario set', () {
    final reports = <String, Map<String, Object?>>{
      'A': <String, Object?>{
        'missed_frame_build_budget_count': 0,
        'missed_frame_rasterizer_budget_count': 0,
      },
      'B': <String, Object?>{
        'missed_frame_build_budget_count': 2,
        'missed_frame_rasterizer_budget_count': 0,
      },
    };

    expect(
      () => DashboardProfileReport.validateNoMissedFrames(reports),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('B'),
        ),
      ),
    );
    reports['B']!['missed_frame_build_budget_count'] = 0;
    expect(
      () => DashboardProfileReport.validateNoMissedFrames(reports),
      returnsNormally,
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
