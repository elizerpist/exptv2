import 'dart:convert';
import 'dart:io';

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
        'logbox_raster_bytes',
        'logbox_raster_prepare_duration_micros',
        'logbox_text_layout_estimated_bytes',
        'logbox_text_layout_prepared_rows',
        'logbox_text_layout_prepared_day_headers',
        'vector_picture_decode_count',
        'vector_picture_prepare_duration_micros',
        'vector_picture_decodes_during_motion',
      ]),
    );
  });

  test('scenario schema validation rejects a missing metric', () {
    final report = <String, Object?>{
      for (final key in DashboardProfileReport.requiredScenarioMetricKeys)
        key: 0,
    };
    report['startup_index_metrics'] = _startupMetrics();
    report['rail_flight'] = _railFlightMetrics();
    report['physical_rail_report'] = _physicalRailDiagnostic();

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

  test('scenario schema rejects invalid rail-flight evidence', () {
    final report = <String, Object?>{
      for (final key in DashboardProfileReport.requiredScenarioMetricKeys)
        key: 0,
      'startup_index_metrics': _startupMetrics(),
      'rail_flight': _railFlightMetrics()..['metric_change_count'] = -1,
      'physical_rail_report': _physicalRailDiagnostic(),
    };

    expect(
      () => DashboardProfileReport.validateRequiredScenarioMetrics(report),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('metric_change_count'),
        ),
      ),
    );
  });

  test(
    'Avatar profile evidence requires an exact painted target and matching progress pixels',
    () {
      final evidence = _avatarFirstTargetEvidence();

      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        returnsNormally,
      );

      evidence['budget_progress_matches_exact_paint'] = false;
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('budget_progress_matches_exact_paint'),
          ),
        ),
      );

      evidence['budget_progress_matches_exact_paint'] = true;
      evidence['first_pipeline_terminal_outcomes'] = <String>['unknown'];
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('terminal outcome'),
          ),
        ),
      );
    },
  );

  test('Avatar K rejects the supplied aa61242 empty-only false green', () {
    final baseline =
        jsonDecode(
              File(
                'docs/superpowers/evidence/2026-09-09-avatar-target-liveness/baseline-K-avatar-first-target.json',
              ).readAsStringSync(),
            )
            as Map;
    final evidence = Map<String, Object?>.from(
      baseline['avatar_first_target'] as Map,
    );
    expect(evidence['exact_phase_a_paint_count'], greaterThan(0));
    expect((evidence['latest_exact_paint'] as Map)['exact_empty'], isTrue);
    expect(
      () => DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
      throwsStateError,
    );
  });

  for (final key in <String>[
    'physical_settle_target_handle',
    'latest_desired_target_handle',
    'latest_semantic_target_handle',
    'latest_exact_painted_target_handle',
    'selected_budget_target_handle',
    'focus_target_handle',
    'header_target_handle',
    'progress_target_handle',
    'logbox_target_handle',
    'focus_category_digest',
    'visible_query_category_digest',
    'canonical_query_category_digest',
    'logbox_query_digest',
    'header_display_numerator_scaled100',
    'progress_display_denominator_scaled100',
  ]) {
    test('Avatar K rejects final identity drift in $key', () {
      final evidence = _avatarFirstTargetEvidence();
      evidence[key] = evidence[key] is int ? 8 : 'older-category';
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        throwsStateError,
      );
    });
  }
  for (final key in <String>[
    'unresolved_pending_candidate_count',
    'generic_coordinator_rejected_count',
    'time_interaction_count',
  ]) {
    test('Avatar K rejects unresolved or reset-dependent $key', () {
      final evidence = _avatarFirstTargetEvidence()..[key] = 1;
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        throwsStateError,
      );
    });
  }
  for (final key in <String>[
    'nonempty_preview_requested_count',
    'nonempty_preview_accepted_count',
    'nonempty_preview_painted_count',
  ]) {
    test('Avatar K rejects empty-only $key despite positive total paints', () {
      final evidence = _avatarFirstTargetEvidence()..[key] = 0;
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        throwsStateError,
      );
    });
  }
  test('Avatar K rejects earlier paint with final target still pending', () {
    final evidence = _avatarFirstTargetEvidence()
      ..['physical_settle_target_handle'] = 8
      ..['latest_desired_target_handle'] = 8
      ..['unresolved_pending_candidate_count'] = 1;
    expect(
      () => DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
      throwsStateError,
    );
  });
  test(
    'Avatar K rejects a failed earlier flight even when final flight passes',
    () {
      final evidence = _avatarFirstTargetEvidence();
      (evidence['flights'] as List).first['canonical_query_category_digest'] =
          'old';
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        throwsStateError,
      );
    },
  );
  test('Avatar K rejects a single real fling', () {
    final evidence = _avatarFirstTargetEvidence()..['real_fling_count'] = 1;
    expect(
      () => DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
      throwsStateError,
    );
  });

  test(
    'Avatar K permits a superseded first request with strict final proof',
    () {
      final evidence = _avatarFirstTargetEvidence()
        ..['first_pipeline_terminal_outcomes'] = ['staleRejected'];
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        returnsNormally,
      );
    },
  );

  for (final classification in ['unknown', 'explicitInvariantFailure']) {
    test('Avatar K rejects terminal classification $classification', () {
      final evidence = _avatarFirstTargetEvidence()
        ..['preview_terminal_classifications'] = {classification: 3};
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        throwsStateError,
      );
    });
  }
  test('Avatar K rejects requests without exactly one terminal completion', () {
    final evidence = _avatarFirstTargetEvidence()
      ..['preview_terminal_count'] = 2;
    expect(
      () => DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
      throwsStateError,
    );
  });
  test(
    'Avatar K accepts accounted coalescing with an exact nonempty final paint',
    () {
      final evidence = _avatarFirstTargetEvidence();
      expect(
        () =>
            DashboardProfileReport.validateAvatarFirstTargetEvidence(evidence),
        returnsNormally,
      );
    },
  );

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

  test(
    'motion isolation gate retains a long CI frame sample when direct preparation slices remain bounded',
    () {
      final reports = <String, Map<String, Object?>>{
        'A': _motionGateReport(
          buildMisses: 1,
          rasterMisses: 24,
          worstBuildMillis: 48.001,
        ),
      };

      expect(
        () => DashboardProfileReport.validateMotionIsolationGate(reports),
        returnsNormally,
      );
    },
  );

  test(
    'motion isolation gate retains an atomic scene-layout measurement without device-time rejection',
    () {
      final reports = <String, Map<String, Object?>>{
        'A': _motionGateReport(buildMisses: 1, rasterMisses: 24)
          ..['scene_preparation_largest_contiguous_ui_slice_micros'] = 6001,
      };

      expect(
        () => DashboardProfileReport.validateMotionIsolationGate(reports),
        returnsNormally,
      );
    },
  );

  test('motion isolation gate rejects an invalid scene-layout measurement', () {
    final reports = <String, Map<String, Object?>>{
      'A': _motionGateReport(buildMisses: 1, rasterMisses: 24)
        ..['scene_preparation_largest_contiguous_ui_slice_micros'] = -1,
    };

    expect(
      () => DashboardProfileReport.validateMotionIsolationGate(reports),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('A'), contains('invalid scene')),
        ),
      ),
    );
  });

  test(
    'motion-scoped scene preparation ignores a completed pre-capture bank',
    () {
      // A scene bank can complete during the profile harness's deliberate
      // pre-capture settle. The snapshot at the actual gesture boundary is
      // authoritative, not the one before that settle.
      expect(
        DashboardProfileReport.motionScopedScenePreparationSliceMicros(
          completedPreparationEpochAtMotionStart: 8,
          completedPreparationEpochAtMotionEnd: 8,
          lastCompletedSliceMicros: 6132,
        ),
        0,
      );
      expect(
        DashboardProfileReport.motionScopedScenePreparationSliceMicros(
          completedPreparationEpochAtMotionStart: 7,
          completedPreparationEpochAtMotionEnd: 8,
          lastCompletedSliceMicros: 27372,
        ),
        27372,
      );
    },
  );

  test('motion isolation gate rejects paint-time LogBox text layout', () {
    final reports = <String, Map<String, Object?>>{
      'I': _motionGateReport(buildMisses: 0, rasterMisses: 0),
    };
    final counters = Map<String, Object?>.from(
      reports['I']!['performance_counters']! as Map,
    )..['logTextLayoutFallback'] = 1;
    reports['I']!['performance_counters'] = counters;

    expect(
      () => DashboardProfileReport.validateMotionIsolationGate(reports),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('I'), contains('logTextLayoutFallback')),
        ),
      ),
    );
  });

  test('motion isolation gate rejects vector decoding during motion', () {
    final reports = <String, Map<String, Object?>>{
      'D': _motionGateReport(buildMisses: 0, rasterMisses: 0)
        ..['vector_picture_decodes_during_motion'] = 1,
    };

    expect(
      () => DashboardProfileReport.validateMotionIsolationGate(reports),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('D'),
            contains('vector_picture_decodes_during_motion'),
          ),
        ),
      ),
    );
  });

  test('motion isolation gate rejects rail-flight interruption evidence', () {
    final reports = <String, Map<String, Object?>>{
      'B': _motionGateReport(buildMisses: 0, rasterMisses: 0),
    };
    final railFlight = Map<String, Object?>.from(
      reports['B']!['rail_flight']! as Map,
    )..['activity_interrupt_count'] = 1;
    reports['B']!['rail_flight'] = railFlight;

    expect(
      () => DashboardProfileReport.validateMotionIsolationGate(reports),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('B'), contains('activity_interrupt_count')),
        ),
      ),
    );
  });

  test(
    'motion isolation gate permits one structural LogBox bind but rejects a rebuild stream',
    () {
      final reports = <String, Map<String, Object?>>{
        'I': _motionGateReport(buildMisses: 0, rasterMisses: 0),
      };
      final railFlight = Map<String, Object?>.from(
        reports['I']!['rail_flight']! as Map,
      )..['log_viewport_rebuild_count'] = 1;
      reports['I']!['rail_flight'] = railFlight;

      expect(
        () => DashboardProfileReport.validateMotionIsolationGate(reports),
        returnsNormally,
      );

      railFlight['log_viewport_rebuild_count'] = 2;
      expect(
        () => DashboardProfileReport.validateMotionIsolationGate(reports),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(contains('I'), contains('log_viewport_rebuild_count')),
          ),
        ),
      );
    },
  );

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

Map<String, Object?> _railFlightMetrics() => <String, Object?>{
  'event_count': 1,
  'overwritten_event_count': 0,
  'activity_interrupt_count': 0,
  'metric_change_count': 0,
  'data_io_count': 0,
  'platform_call_count': 0,
  'sql_count': 0,
  'build_duration_micros': 0,
  'layout_duration_micros': 0,
  'paint_duration_micros': 0,
  'raster_duration_micros': 0,
};

Map<String, Object?> _avatarFirstTargetEvidence() => <String, Object?>{
  'motion_lane_observed': true,
  ..._avatarFinalTargetEvidence(),
  'real_fling_count': 2,
  'flights': [_avatarFinalTargetEvidence(), _avatarFinalTargetEvidence()],
  'fixture_category_row_counts': {
    for (var handle = 1; handle <= 8; handle++) '$handle': 1,
  },
  'fixture_aggregate_row_count': 8,
  'fixture_category_rows_disjoint': true,
  'pointer_accepted_count': 2,
  'avatar_semantic_crossings': 1,
  'preview_accepted_count': 1,
  'exact_phase_a_paint_count': 1,
  'exact_phase_a_target_handles': <int>[3],
  'exact_phase_a_all_readable': true,
  'latest_exact_paint_matches_visible': true,
  'budget_progress_painted_count': 1,
  'budget_progress_target_handles': <int>[3],
  'budget_progress_matches_exact_paint': true,
  'first_pipeline_summary_count': 1,
  'first_pipeline_terminal_outcomes': <String>['exactPhaseAPainted'],
  'avatar_motion_summary_count': 2,
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
  'scene_preparation_largest_contiguous_ui_slice_micros': 3000,
  'vector_picture_decodes_during_motion': 0,
  'rail_flight': <String, Object?>{
    ..._railFlightMetrics(),
    'root_rebuild_count': 0,
    'rail_rebuild_count': 0,
    'log_viewport_rebuild_count': 0,
  },
  'performance_counters': <String, Object?>{
    'sqlCallsDuringMotion': 0,
    'platformCallsDuringMotion': 0,
    'repositoryReadsDuringMotion': 0,
    'liveLeaseStartsDuringMotion': 0,
    'logBoxProjectionsDuringMotion': 0,
    'formattingDuringMotion': 0,
    'railPresentationDataDependencyViolation': 0,
    'railCriticalCacheMiss': 0,
    'postReadyFirstUseViolation': 0,
    'logTextLayoutFallback': 0,
  },
  'physical_rail_report': _physicalRailDiagnostic(),
};

Map<String, Object?> _physicalRailDiagnostic() => <String, Object?>{
  'railCriticalCacheMissCount': 0,
  'postReadyFirstUseViolationCount': 0,
  'motionOverwrittenEventCount': 0,
  'renderOverwrittenEventCount': 0,
};

Map<String, Object?> _physicalFrameReport() => <String, Object?>{
  '95th_percentile_frame_build_time_millis': 16,
  '95th_percentile_frame_rasterizer_time_millis': 16,
  '99th_percentile_frame_build_time_millis': 23,
  '99th_percentile_frame_rasterizer_time_millis': 23,
  'worst_frame_build_time_millis': 47,
  'worst_frame_rasterizer_time_millis': 47,
};

Map<String, Object?> _avatarFinalTargetEvidence() => <String, Object?>{
  for (final key in [
    'physical_settle_target_handle',
    'latest_desired_target_handle',
    'latest_semantic_target_handle',
    'latest_exact_painted_target_handle',
    'selected_budget_target_handle',
    'focus_target_handle',
    'header_target_handle',
    'progress_target_handle',
    'logbox_target_handle',
  ])
    key: 3,
  for (final key in [
    'expected_category_digest',
    'focus_category_digest',
    'visible_query_category_digest',
    'canonical_query_category_digest',
  ])
    key: 'category-3',
  for (final key in [
    'visible_query_digest',
    'logbox_query_digest',
    'canonical_query_digest',
  ])
    key: 'query-3',
  'preview_requested_count': 3,
  'preview_terminal_count': 3,
  'preview_terminal_classifications': {
    'acceptedExactNonEmptyPainted': 1,
    'coalescedBeforeResourceReady': 2,
  },
  'unresolved_pending_candidate_count': 0,
  'exact_local_hotset_unavailable_count': 0,
  'generic_coordinator_rejected_count': 0,
  'time_interaction_count': 0,
  'nonempty_preview_requested_count': 3,
  'nonempty_preview_accepted_count': 2,
  'nonempty_preview_painted_count': 1,
  'final_target_row_count': 1,
  'final_target_exact_painted': true,
  'final_target_progress_painted': true,
  'final_target_header_painted': true,
  'final_target_canonicalized': true,
  'final_target_identity_equal': true,
  'expected_display_numerator_scaled100': 100,
  'header_display_numerator_scaled100': 100,
  'progress_display_numerator_scaled100': 100,
  'expected_display_denominator_scaled100': 200,
  'header_display_denominator_scaled100': 200,
  'progress_display_denominator_scaled100': 200,
};
