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
}
