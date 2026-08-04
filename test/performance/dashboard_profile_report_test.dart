import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

import '../../integration_test/support/dashboard_profile_fixture_repository.dart';
import '../../integration_test/support/dashboard_profile_report.dart';

void main() {
  test('adds exact p50, p90, p95 and p99 values to frame summaries', () {
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

  test('uses nearest-rank percentiles and reports density delta honestly', () {
    expect(DashboardProfileReport.percentileMicros(<int>[9, 1, 5], 0.50), 5);
    expect(DashboardProfileReport.percentileMicros(<int>[9, 1, 5], 0.95), 9);
    expect(DashboardProfileReport.densityDeltaPercent(10, 11), 10.0);
    expect(DashboardProfileReport.densityDeltaPercent(0, 11), isNull);
  });

  test('compares 0 and 1000 row p95 values with the 94 row reference', () {
    final comparison = DashboardProfileReport.compareDensityP95(
      <int, Map<String, dynamic>>{
        0: <String, dynamic>{
          '95th_percentile_frame_build_time_millis': 9.5,
          '95th_percentile_frame_rasterizer_time_millis': 11.0,
        },
        94: <String, dynamic>{
          '95th_percentile_frame_build_time_millis': 10.0,
          '95th_percentile_frame_rasterizer_time_millis': 10.0,
        },
        1000: <String, dynamic>{
          '95th_percentile_frame_build_time_millis': 11.2,
          '95th_percentile_frame_rasterizer_time_millis': 10.8,
        },
      },
      targetMaxAbsoluteDeltaPercent: 10,
    );

    expect(comparison['reference_density'], 94);
    expect(comparison['target_max_absolute_delta_percent'], 10.0);
    expect(comparison['target_drift_detected'], isFalse);
    expect(comparison['frame_build_p95_delta_percent'], <String, double>{
      '0': -5.0,
      '1000': 12.0,
    });
    expect(comparison['frame_raster_p95_delta_percent'], <String, double>{
      '0': 10.0,
      '1000': 8.0,
    });
    expect(comparison['within_target'], isFalse);
  });

  for (final density in const <int>[0, 94, 1000]) {
    test(
      '$density-row profile fixture keeps exact totals and bounded previews',
      () async {
        final parentScope = CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
        );
        final repository = DashboardProfileFixtureRepository(
          entryCount: density,
        );
        final parent = await repository.read(parentScope);
        final bundle = await repository.readChildPreviewBundle(
          DashboardChildPreviewBundleRequest(
            parentScope: parentScope,
            childPeriod: TimeChildPeriod.day,
            requestGeneration: 1,
          ),
        );
        final children = bundle.childrenByQueryKey.values;

        expect(children, hasLength(31));
        expect(
          children.fold<int>(0, (sum, child) => sum + child.result.entryCount),
          density,
        );
        expect(
          children.fold<int>(0, (sum, child) => sum + child.result.totalMinor),
          parent.totalMinor,
        );
        expect(
          children.fold<int>(
            0,
            (sum, child) => sum + child.result.entries.length,
          ),
          lessThanOrEqualTo(31 * bundle.previewPageSize),
        );
        expect(
          children.every(
            (child) => child.result.entries.length <= bundle.previewPageSize,
          ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }
}
