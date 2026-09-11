import 'dart:math' as math;

abstract final class DashboardProfileReport {
  static const suiteCompletionKey = 'dashboard_profile_suite_completion';
  static const requiredSuiteScenarioKeys = <String>[
    'A_summary_sum_year_month',
    'B_year_month_rail_populated',
    'C_year_month_rail_empty',
    'D_month_day_rail_94',
    'E_month_day_rail_empty',
    'F_parent_while_rail_open',
    'G_direction_while_rail_open',
    'H_pulse_parent_navigation',
    'I_first_fling',
    'J_tenth_fling',
    'K_avatar_first_target',
  ];

  /// Rejects incomplete driver responses even when the SDK reports success.
  /// The completion record is written only after every suite assertion.
  static void validateCompleteSuite(Object? responseData) {
    Map<String, Object?> requireMap(Object? value, String name) {
      if (value is! Map || value.keys.any((key) => key is! String)) {
        throw StateError('Dashboard profile $name must be a report map.');
      }
      return Map<String, Object?>.from(value);
    }

    final data = requireMap(responseData, 'response');
    final reports = <String, Map<String, Object?>>{};
    for (final key in requiredSuiteScenarioKeys) {
      reports[key] = requireMap(data[key], key);
    }
    final completion = requireMap(data[suiteCompletionKey], suiteCompletionKey);
    final keys = completion['scenario_report_keys'];
    if (completion['schema_version'] is! int ||
        completion['schema_version'] != 1 ||
        completion['all_assertions_passed'] != true ||
        keys is! List ||
        keys.any((key) => key is! String) ||
        keys.length != requiredSuiteScenarioKeys.length ||
        keys.toSet().length != requiredSuiteScenarioKeys.length ||
        !keys.toSet().containsAll(requiredSuiteScenarioKeys)) {
      throw StateError('Dashboard profile suite completion is invalid.');
    }
    for (final report in reports.values) {
      validateRequiredScenarioMetrics(report);
    }
    validateAvatarFirstTargetEvidence(
      requireMap(
        reports['K_avatar_first_target']!['avatar_first_target'],
        'K avatar_first_target',
      ),
    );
    validateAvatarFinalTargetEvidence(
      requireMap(
        data['dashboard_avatar_final_target_evidence'],
        'post-renderer Avatar final target',
      ),
    );
    validateDirectionCircleEvidence(
      requireMap(
        reports['G_direction_while_rail_open']!['direction_circle'],
        'G direction circle',
      ),
    );
    validateMotionIsolationGate(reports);
  }

  /// Classifies the actual nonempty renderer counters supplied by Core's
  /// exact post-paint acknowledgement. Identity is validated separately.
  static bool hasExactNonemptyAvatarPaint({
    required bool exactEmpty,
    required int readablePhaseARowsPainted,
    required int richPhaseBRowsPainted,
  }) =>
      !exactEmpty &&
      readablePhaseARowsPainted >= 0 &&
      richPhaseBRowsPainted >= 0 &&
      (readablePhaseARowsPainted > 0 || richPhaseBRowsPainted > 0);

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
    'scene_preparation_largest_contiguous_ui_slice_micros',
    'scene_preparation_completed_during_motion',
    'motion_duration_micros',
    'performance_counters',
    'rail_flight',
    'physical_rail_report',
    'gc',
    'allocation_burst_rss_bytes',
    'peak_rss_bytes',
    'first_valid_paint_micros',
    'index_publish_duration_micros',
    'prepared_index_bytes',
    'logbox_raster_bytes',
    'logbox_raster_prepare_duration_micros',
    'logbox_text_layout_estimated_bytes',
    'logbox_text_layout_prepared_rows',
    'logbox_text_layout_prepared_day_headers',
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
    'railPresentationDataDependencyViolation',
    'railCriticalCacheMiss',
    'postReadyFirstUseViolation',
    'logTextLayoutFallback',
  ];

  static const List<String> railFlightIsolationZeroKeys = <String>[
    'overwritten_event_count',
    'activity_interrupt_count',
    'metric_change_count',
    'root_rebuild_count',
    'rail_rebuild_count',
    'data_io_count',
    'platform_call_count',
    'sql_count',
  ];

  /// A live semantic flight may bind the existing LogBox viewport once when
  /// its first exact prepared root becomes visible. Rebuilding it per tick is
  /// still forbidden; row paints and render-surface updates own subsequent
  /// live data changes.
  static const int maximumLogViewportRebuildsPerFlight = 1;

  /// Returns the only completed scene-preparation slice that belongs to a
  /// measured motion window.
  ///
  /// A scene cache intentionally keeps its last completed-slice diagnostics
  /// across presentation lifetimes.  Reporting that historic value as
  /// motion-time work falsely attributes startup/candidate preparation to a
  /// later fling, so the monotonic completed-preparation epoch is the scope
  /// boundary.
  static int motionScopedScenePreparationSliceMicros({
    required int completedPreparationEpochAtMotionStart,
    required int completedPreparationEpochAtMotionEnd,
    required int lastCompletedSliceMicros,
  }) {
    if (completedPreparationEpochAtMotionStart < 0 ||
        completedPreparationEpochAtMotionEnd <
            completedPreparationEpochAtMotionStart ||
        lastCompletedSliceMicros < 0) {
      throw ArgumentError('Invalid scene-preparation motion snapshot.');
    }
    return completedPreparationEpochAtMotionEnd ==
            completedPreparationEpochAtMotionStart
        ? 0
        : lastCompletedSliceMicros;
  }

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
      'logbox_raster_bytes',
      'logbox_raster_prepare_duration_micros',
      'logbox_text_layout_estimated_bytes',
      'logbox_text_layout_prepared_rows',
      'logbox_text_layout_prepared_day_headers',
      'vector_picture_decode_count',
      'vector_picture_prepare_duration_micros',
      'vector_picture_decodes_during_motion',
      'scene_preparation_completed_during_motion',
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
    final railFlight = report['rail_flight'];
    if (railFlight is! Map) {
      throw StateError('Dashboard profile rail flight metrics must be a map.');
    }
    final physicalRail = report['physical_rail_report'];
    if (physicalRail is! Map) {
      throw StateError(
        'Dashboard profile physical rail diagnostics must be a map.',
      );
    }
    for (final key in const <String>[
      'railCriticalCacheMissCount',
      'postReadyFirstUseViolationCount',
      'motionOverwrittenEventCount',
      'renderOverwrittenEventCount',
    ]) {
      final value = physicalRail[key];
      if (value is! num || value < 0) {
        throw StateError(
          'Dashboard profile physical rail metric $key must be nonnegative.',
        );
      }
    }
    for (final key in const <String>[
      'event_count',
      'overwritten_event_count',
      'activity_interrupt_count',
      'metric_change_count',
      'data_io_count',
      'platform_call_count',
      'sql_count',
      'build_duration_micros',
      'layout_duration_micros',
      'paint_duration_micros',
      'raster_duration_micros',
    ]) {
      final value = railFlight[key];
      if (value is! num || value < 0) {
        throw StateError(
          'Dashboard profile rail flight metric $key must be nonnegative.',
        );
      }
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

  /// Validates the bounded evidence from the profile matrix's real Budget
  /// Avatar interaction. Existing production owners provide every identity
  /// and paint acknowledgement. Each real fling must finish with an exact
  /// nonempty final target and fully accounted request terminals.
  static void validateAvatarFirstTargetEvidence(Map<String, Object?> evidence) {
    void requirePositive(String key) {
      final value = evidence[key];
      if (value is! num || value < 1) {
        throw StateError(
          'Avatar profile evidence $key must be a positive count; got $value.',
        );
      }
    }

    void requireTrue(String key) {
      if (evidence[key] != true) {
        throw StateError(
          'Avatar profile evidence $key must be true; got ${evidence[key]}.',
        );
      }
    }

    requireTrue('motion_lane_observed');
    requirePositive('pointer_accepted_count');
    requirePositive('avatar_semantic_crossings');
    requirePositive('preview_accepted_count');
    requirePositive('exact_renderer_paint_count');
    requireTrue('exact_renderer_all_nonempty_painted');
    requireTrue('latest_exact_paint_matches_visible');
    requirePositive('budget_progress_painted_count');
    requireTrue('budget_progress_matches_exact_paint');
    requirePositive('avatar_motion_summary_count');

    final exactTargets = evidence['exact_renderer_target_handles'];
    if (exactTargets is! List ||
        exactTargets.isEmpty ||
        exactTargets.any((target) => target is! int)) {
      throw StateError(
        'Avatar profile evidence must retain exact painted target handles; '
        'got $exactTargets.',
      );
    }
    final progressTargets = evidence['budget_progress_target_handles'];
    if (progressTargets is! List ||
        progressTargets.isEmpty ||
        progressTargets.any((target) => target is! int)) {
      throw StateError(
        'Avatar profile evidence must retain actual progress-paint target '
        'handles; got $progressTargets.',
      );
    }

    final pipelineCount = evidence['first_pipeline_summary_count'];
    if (pipelineCount is! num || pipelineCount < 1) {
      throw StateError(
        'Avatar profile must emit first-target pipeline summaries; '
        'got $pipelineCount.',
      );
    }
    final outcomes = evidence['first_pipeline_terminal_outcomes'];
    const allowedOutcomes = <String>{
      'exactPhaseAPainted',
      'exactEmpty',
      'coalescedBeforeReadiness',
      'coalescedBeforePaint',
      // The first crossing may be superseded; the per-request terminals and
      // each physical final-target proof below remain mandatory.
      'coalescedBeforeResourceReady',
      'cancelledByNewPointer',
      'staleRejected',
    };
    if (outcomes is! List ||
        outcomes.isEmpty ||
        outcomes.any(
          (outcome) => outcome is! String || !allowedOutcomes.contains(outcome),
        )) {
      throw StateError(
        'Avatar profile has an invalid first-target terminal outcome: '
        '$outcomes.',
      );
    }
    validateAvatarFinalTargetEvidence(evidence);
    final flingCount = evidence['real_fling_count'];
    final flights = evidence['flights'];
    if (flingCount is! int ||
        flingCount < 42 ||
        flights is! List ||
        flights.length != flingCount ||
        (evidence['pointer_accepted_count'] as num) < flingCount ||
        (evidence['avatar_motion_summary_count'] as num) < flingCount) {
      throw StateError(
        'Avatar K requires repeated real flings and each final snapshot.',
      );
    }
    for (final flight in flights) {
      if (flight is! Map) {
        throw StateError('Avatar flight evidence must be a map.');
      }
      validateAvatarFinalTargetEvidence(Map<String, Object?>.from(flight));
    }
    final coveredTargetHandles = <int>{
      for (final flight in flights.cast<Map>())
        if (flight['physical_settle_target_handle'] case final int handle)
          handle,
    };
    if (coveredTargetHandles.length != 9 ||
        !coveredTargetHandles.containsAll(const <int>{
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
        })) {
      throw StateError(
        'Avatar K requires real pointer coverage of every target handle: '
        '$coveredTargetHandles.',
      );
    }
    final categories = evidence['fixture_category_row_counts'];
    if (categories is! Map ||
        categories.length != 8 ||
        [
          for (var handle = 1; handle <= 8; handle++) categories['$handle'],
        ].any((count) => count is! int || count < 1) ||
        evidence['fixture_category_rows_disjoint'] != true ||
        evidence['fixture_aggregate_row_count'] is! int ||
        (evidence['fixture_aggregate_row_count'] as int) < 8) {
      throw StateError(
        'Avatar K requires eight nonempty disjoint categories and aggregate.',
      );
    }
    final rowDiscovery = evidence['avatar_target_row_discovery_work_units'];
    if (rowDiscovery is! List || rowDiscovery.isEmpty) {
      throw StateError(
        'Avatar K requires target-correlated row-discovery evidence.',
      );
    }
    for (final unit in rowDiscovery) {
      if (unit is! Map) {
        throw StateError('Avatar row-discovery evidence must be a map.');
      }
      final target = unit['target_handle'];
      final generation = unit['focus_generation'];
      final epoch = unit['interaction_epoch'];
      final digest = unit['resource_key_digest'];
      final owner = unit['owner'];
      final workUnit = unit['work_unit'];
      final elapsed = unit['elapsed_micros'];
      if (target is! int ||
          target < 0 ||
          target > 8 ||
          generation is! int ||
          generation < 1 ||
          epoch is! int ||
          epoch < 1 ||
          digest is! String ||
          digest.isEmpty ||
          owner != 'liveInteractionResource' ||
          unit['current'] != true ||
          workUnit is! String ||
          !const <String>{
            'flatItems',
            'rowKey',
            'rowMap',
            'dayLabel',
          }.contains(workUnit) ||
          elapsed is! int ||
          elapsed < 0 ||
          unit['resource_schedule_correlated'] != true) {
        throw StateError(
          'Avatar row-discovery evidence is not tied to one current exact '
          'resource request: $unit.',
        );
      }
    }
    final preparations = evidence['avatar_target_prepare_completions'];
    if (preparations is! List || preparations.isEmpty) {
      throw StateError(
        'Avatar K requires an exact active target preparation completion.',
      );
    }
    var coldResourcePreparationObserved = false;
    for (final preparation in preparations) {
      if (preparation is! Map) {
        throw StateError('Avatar target preparation evidence must be a map.');
      }
      for (final key in const <String>[
        'target_handle',
        'focus_generation',
        'interaction_epoch',
        'ui_isolate_micros',
        'largest_contiguous_ui_slice_micros',
        'yield_count',
        'new_row_layouts',
        'reused_row_layouts',
        'scene_new',
        'scene_reuse',
        'allocation_count',
      ]) {
        final value = preparation[key];
        if (value is! int || value < 0) {
          throw StateError(
            'Avatar target preparation has invalid $key: $preparation.',
          );
        }
      }
      if (preparation['owner'] != 'liveInteractionResource' ||
          preparation['current'] != true ||
          preparation['resource_schedule_correlated'] != true ||
          preparation['resource_key_digest'] is! String ||
          (preparation['resource_key_digest'] as String).isEmpty) {
        throw StateError(
          'Avatar target preparation is not exactly resource-correlated: '
          '$preparation.',
        );
      }
      coldResourcePreparationObserved |=
          (preparation['new_row_layouts'] as int) > 0;
    }
    if (!coldResourcePreparationObserved) {
      throw StateError(
        'Avatar K requires a cold exact target preparation with new rows.',
      );
    }
  }

  /// Checks one bounded physical settle against the existing owners and actual
  /// painter acknowledgements. Positive paints from an earlier target cannot
  /// stand in for this target's final transaction.
  static void validateAvatarFinalTargetEvidence(Map<String, Object?> evidence) {
    Never reject(String key) => throw StateError(
      'Avatar final-target evidence $key is invalid: ${evidence[key]}.',
    );
    final physical = evidence['physical_settle_target_handle'];
    if (physical is! int || physical < 0 || physical > 8) {
      reject('physical_settle_target_handle');
    }
    for (final key in const [
      'latest_desired_target_handle',
      'latest_semantic_target_handle',
      'latest_exact_painted_target_handle',
      'selected_budget_target_handle',
      'focus_target_handle',
      'header_target_handle',
      'progress_target_handle',
      'logbox_target_handle',
    ]) {
      if (evidence[key] != physical) reject(key);
    }
    final category = evidence['expected_category_digest'];
    if (category is! String || category.isEmpty) {
      reject('expected_category_digest');
    }
    for (final key in const [
      'focus_category_digest',
      'visible_query_category_digest',
      'canonical_query_category_digest',
    ]) {
      if (evidence[key] != category) reject(key);
    }
    final query = evidence['visible_query_digest'];
    if (query is! String || query.isEmpty) reject('visible_query_digest');
    for (final key in const ['logbox_query_digest', 'canonical_query_digest']) {
      if (evidence[key] != query) reject(key);
    }
    final exactEmpty = evidence['exact_paint_exact_empty'];
    final phaseARows = evidence['exact_paint_readable_phase_a_rows_painted'];
    final richRows = evidence['exact_paint_rich_phase_b_rows_painted'];
    if (exactEmpty is! bool) reject('exact_paint_exact_empty');
    if (phaseARows is! int || phaseARows < 0) {
      reject('exact_paint_readable_phase_a_rows_painted');
    }
    if (richRows is! int || richRows < 0) {
      reject('exact_paint_rich_phase_b_rows_painted');
    }
    if (!hasExactNonemptyAvatarPaint(
      exactEmpty: exactEmpty,
      readablePhaseARowsPainted: phaseARows,
      richPhaseBRowsPainted: richRows,
    )) {
      reject('final_target_exact_painted');
    }
    final visibleRevision = evidence['visible_core_revision'];
    if (visibleRevision is! int || visibleRevision < 0) {
      reject('visible_core_revision');
    }
    final paintRevision = evidence['exact_paint_core_revision'];
    if (paintRevision is! int || paintRevision != visibleRevision) {
      reject('exact_paint_core_revision');
    }
    for (final key in const [
      'unresolved_pending_candidate_count',
      'generic_coordinator_rejected_count',
      'time_interaction_count',
    ]) {
      if (evidence[key] != 0) reject(key);
    }
    for (final key in const [
      'nonempty_preview_requested_count',
      'nonempty_preview_accepted_count',
      'nonempty_preview_painted_count',
      'final_target_row_count',
    ]) {
      final value = evidence[key];
      if (value is! int || value < 1) reject(key);
    }
    final requested = evidence['preview_requested_count'];
    final terminal = evidence['preview_terminal_count'];
    final classifications = evidence['preview_terminal_classifications'];
    const allowedClassifications = {
      'acceptedExactNonEmptyPainted',
      'acceptedExactEmptyPainted',
      'coalescedBeforeResourceReady',
      'cancelledByNewPointer',
      'staleRejected',
      'disposed',
    };
    if (requested is! int ||
        requested < 1 ||
        terminal != requested ||
        classifications is! Map ||
        classifications.isEmpty) {
      reject('preview_terminal_count');
    }
    var classified = 0;
    for (final entry in classifications.entries) {
      if (!allowedClassifications.contains(entry.key) ||
          entry.value is! int ||
          (entry.value as int) < 1) {
        reject('preview_terminal_classifications');
      }
      classified += entry.value as int;
    }
    if (classified != terminal ||
        classifications['acceptedExactNonEmptyPainted'] is! int ||
        (classifications['acceptedExactNonEmptyPainted'] as int) < 1) {
      reject('preview_terminal_classifications');
    }
    final unavailable = evidence['exact_local_hotset_unavailable_count'];
    if (unavailable is! int || unavailable < 0) {
      reject('exact_local_hotset_unavailable_count');
    }
    for (final key in const [
      'final_target_exact_painted',
      'final_target_progress_painted',
      'final_target_header_painted',
      'final_target_canonicalized',
      'final_target_identity_equal',
    ]) {
      if (evidence[key] != true) reject(key);
    }
    for (final value in const ['numerator', 'denominator']) {
      final expected = evidence['expected_display_${value}_scaled100'];
      if (expected is! int) reject('expected_display_${value}_scaled100');
      for (final surface in const ['header', 'progress']) {
        final key = '${surface}_display_${value}_scaled100';
        if (evidence[key] != expected) reject(key);
      }
    }
  }

  /// G intentionally gives Income and Expense different remembered Avatar
  /// targets. A direction-only switch must rebase the physical carousel to
  /// the new direction's authoritative presentation target before its circle
  /// paints; a later Avatar input may not repair this assertion.
  static void validateDirectionCircleEvidence(Map<String, Object?> evidence) {
    Never reject(String key) => throw StateError(
      'Direction-circle profile evidence $key is invalid: ${evidence[key]}.',
    );
    if (evidence['direction'] != 'expense' ||
        evidence['visible_query_direction'] != 'expense') {
      reject('direction');
    }
    final remembered = evidence['remembered_direction_target_handle'];
    if (remembered is! int || remembered <= 0) {
      reject('remembered_direction_target_handle');
    }
    for (final key in const <String>[
      'physical_avatar_target_handle',
      'presentation_selected_target_handle',
      'selected_limit_visual_target_handle',
      'selected_circle_widget_target_handle',
      'selected_circle_painted_target_handle',
    ]) {
      if (evidence[key] != remembered) reject(key);
    }
    if (evidence['circle_visible'] != true) reject('circle_visible');
    if (evidence['direction_visible_publication_count'] is! int ||
        (evidence['direction_visible_publication_count'] as int) < 1) {
      reject('direction_visible_publication_count');
    }
    if (evidence['avatar_preview_request_count_after_direction'] != 0) {
      reject('avatar_preview_request_count_after_direction');
    }
    if (evidence['identity_mismatch_count_after_direction'] != 0) {
      reject('identity_mismatch_count_after_direction');
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
  /// scene-cache ownership failure. FrameTiming build and raster misses remain
  /// in every JSON report and are never rewritten or suppressed. The scene
  /// timing metric is recorded as evidence, but this profile must not impose a
  /// device-time ceiling on an indivisible engine [TextPainter] layout. The
  /// deterministic cache suite proves the cooperative scheduling budget;
  /// this end-to-end gate proves ownership, I/O isolation and fallbacks.
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

      final largestSceneSlice =
          report['scene_preparation_largest_contiguous_ui_slice_micros'];
      if (largestSceneSlice is! num ||
          !largestSceneSlice.toDouble().isFinite ||
          largestSceneSlice < 0) {
        throw StateError(
          'Dashboard profile $scenario has an invalid scene '
          'preparation measurement: $largestSceneSlice micros.',
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

      final railFlight = report['rail_flight'];
      if (railFlight is! Map) {
        throw StateError(
          'Dashboard profile $scenario has invalid rail-flight evidence.',
        );
      }
      for (final key in railFlightIsolationZeroKeys) {
        final value = railFlight[key];
        if (value is! num || value != 0) {
          throw StateError(
            'Dashboard profile $scenario has rail_flight.$key=$value; '
            'expected 0.',
          );
        }
      }
      final logViewportRebuilds = railFlight['log_viewport_rebuild_count'];
      if (logViewportRebuilds is! num ||
          logViewportRebuilds < 0 ||
          logViewportRebuilds > maximumLogViewportRebuildsPerFlight) {
        throw StateError(
          'Dashboard profile $scenario has '
          'rail_flight.log_viewport_rebuild_count=$logViewportRebuilds; '
          'expected at most $maximumLogViewportRebuildsPerFlight.',
        );
      }

      final physicalRail = report['physical_rail_report'];
      if (physicalRail is! Map) {
        throw StateError(
          'Dashboard profile $scenario has invalid physical rail evidence.',
        );
      }
      for (final key in const <String>[
        'railCriticalCacheMissCount',
        'postReadyFirstUseViolationCount',
        'motionOverwrittenEventCount',
        'renderOverwrittenEventCount',
      ]) {
        final value = physicalRail[key];
        if (value is! num || value != 0) {
          throw StateError(
            'Dashboard profile $scenario has physical_rail_report.$key='
            '$value; expected 0.',
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
