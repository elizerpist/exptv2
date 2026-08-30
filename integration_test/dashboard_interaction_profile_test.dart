import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/demo_data/demo_data_bridge.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_flight_recorder.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_motion_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/method_channel_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:integration_test/integration_test.dart';

import 'support/dashboard_profile_report.dart';
import 'support/dashboard_profile_seed_fixture_contract.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'profiles dashboard motion-data isolation scenarios A through J',
    (tester) async {
      final seedReport = await const MethodChannelDemoDataBridge()
          .seedDemoDataset(forceReset: true);
      final fixture = DashboardProfileSeedFixtureContract.verifiedFixtureFor(
        seedReport,
      );
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['dashboard_native_seed'] = <String, Object?>{
        'seed_version': seedReport.seedVersion,
        'created_entry_count': seedReport.createdEntryCount,
        'duration_ms': seedReport.durationMs,
      };
      final reports = <String, Map<String, dynamic>>{};
      for (final scenario in _ProfileScenario.values) {
        debugPrint('[PROFILE][SCENARIO_START] ${scenario.reportKey}');
        reports[scenario.reportKey] = await _runScenario(
          binding,
          tester,
          scenario,
          fixture,
        );
        debugPrint('[PROFILE][SCENARIO_READY] ${scenario.reportKey}');
      }
      final firstPhysical = Map<String, Object?>.from(
        reports[_ProfileScenario.firstFling.reportKey]!['physical_rail_report']!
            as Map,
      );
      final tenthPhysical = Map<String, Object?>.from(
        reports[_ProfileScenario.tenthFling.reportKey]!['physical_rail_report']!
            as Map,
      );
      expect(firstPhysical['firstTenFlings'], hasLength(1));
      expect(tenthPhysical['firstTenFlings'], hasLength(10));
      final densityTimelines = <String, Object?>{};
      for (final scenario in const <_ProfileScenario>[
        _ProfileScenario.monthEmpty,
        _ProfileScenario.month94,
        _ProfileScenario.yearEmpty,
        _ProfileScenario.yearPopulated,
      ]) {
        final physical = Map<String, Object?>.from(
          reports[scenario.reportKey]!['physical_rail_report']! as Map,
        );
        expect(physical['firstTenFlings'], hasLength(10));
        densityTimelines[scenario.reportKey] = physical['firstTenFlings'];
      }
      for (final entry in reports.entries) {
        final physical = Map<String, Object?>.from(
          entry.value['physical_rail_report']! as Map,
        );
        final sceneWindow = Map<String, Object?>.from(
          physical['sceneWindow']! as Map,
        );
        for (final counter in const <String>[
          'textLayoutMisses',
          'criticalCacheMisses',
          'readySceneIncomplete',
          'activeWindowPartialPublish',
          'stagingObjectRendered',
          'railCriticalLookupMiss',
          'visiblePayloadWithoutDrawable',
          'visiblePayloadWithoutPaint',
          'railCanonicalCenterMismatch',
          'freshVerticalGestureRejected',
        ]) {
          expect(
            sceneWindow[counter],
            0,
            reason: 'Profile ${entry.key} has $counter.',
          );
        }
      }
      binding.reportData!['dashboard_first_ten_fling_timeline'] =
          tenthPhysical['firstTenFlings'];
      binding.reportData!['dashboard_density_first_ten_fling_timelines'] =
          densityTimelines;
      binding.reportData!['dashboard_profile_comparisons'] = <String, Object?>{
        'year_empty_vs_populated': _p95Comparison(
          reports[_ProfileScenario.yearPopulated.reportKey]!,
          reports[_ProfileScenario.yearEmpty.reportKey]!,
        ),
        'month_empty_vs_populated': _p95Comparison(
          reports[_ProfileScenario.month94.reportKey]!,
          reports[_ProfileScenario.monthEmpty.reportKey]!,
        ),
        'first_vs_tenth_fling': _p95Comparison(
          reports[_ProfileScenario.firstFling.reportKey]!,
          reports[_ProfileScenario.tenthFling.reportKey]!,
        ),
      };
      _expectEquivalentMotion(
        reports[_ProfileScenario.yearPopulated.reportKey]!,
        reports[_ProfileScenario.yearEmpty.reportKey]!,
        label: 'year populated/empty',
      );
      _expectEquivalentRailFlight(
        reports[_ProfileScenario.yearPopulated.reportKey]!,
        reports[_ProfileScenario.yearEmpty.reportKey]!,
        label: 'year populated/empty',
      );
      _expectEquivalentMotion(
        reports[_ProfileScenario.month94.reportKey]!,
        reports[_ProfileScenario.monthEmpty.reportKey]!,
        label: 'month populated/empty',
      );
      _expectEquivalentRailFlight(
        reports[_ProfileScenario.month94.reportKey]!,
        reports[_ProfileScenario.monthEmpty.reportKey]!,
        label: 'month populated/empty',
      );
      _expectEquivalentMotion(
        reports[_ProfileScenario.firstFling.reportKey]!,
        reports[_ProfileScenario.tenthFling.reportKey]!,
        label: 'first/tenth fling',
        requireNoSlowdown: true,
      );
      _expectEquivalentRailFlight(
        reports[_ProfileScenario.firstFling.reportKey]!,
        reports[_ProfileScenario.tenthFling.reportKey]!,
        label: 'first/tenth fling',
      );
      binding.reportData!['dashboard_physical_frame_targets'] =
          DashboardProfileReport.physicalFrameTargetReport(reports);
      DashboardProfileReport.validateMotionIsolationGate(reports);
      if (const bool.fromEnvironment('FLUVI_REQUIRE_PHYSICAL_FRAME_TARGETS')) {
        DashboardProfileReport.validatePhysicalFrameTargets(reports);
      }
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

enum _ProfileScenario {
  // This must remain first: PreparedVectorAssetAtlas is process-scoped, so the
  // cold-first fixture has to run before any other Dashboard mounts or raster
  // preparation in this integration-test process.
  firstFling,
  summaryPlane,
  yearPopulated,
  yearEmpty,
  month94,
  monthEmpty,
  parentWhileRailOpen,
  directionWhileRailOpen,
  pulseWithParentNavigation,
  tenthFling;

  String get reportKey => switch (this) {
    summaryPlane => 'A_summary_sum_year_month',
    yearPopulated => 'B_year_month_rail_populated',
    yearEmpty => 'C_year_month_rail_empty',
    month94 => 'D_month_day_rail_94',
    monthEmpty => 'E_month_day_rail_empty',
    parentWhileRailOpen => 'F_parent_while_rail_open',
    directionWhileRailOpen => 'G_direction_while_rail_open',
    pulseWithParentNavigation => 'H_pulse_parent_navigation',
    firstFling => 'I_first_fling',
    tenthFling => 'J_tenth_fling',
  };

  DateTime get initialDate => switch (this) {
    yearEmpty || monthEmpty => DateTime(2024, 7, 14),
    _ => DateTime(2026, 7, 14),
  };

  TimePlane get initialPlane => switch (this) {
    summaryPlane => TimePlane.sum,
    yearPopulated || yearEmpty => TimePlane.year,
    _ => TimePlane.month,
  };

  bool get initialRailOpen => switch (this) {
    summaryPlane => false,
    _ => true,
  };

  LedgerDirection get initialDirection => switch (this) {
    directionWhileRailOpen => LedgerDirection.income,
    _ => LedgerDirection.expense,
  };
}

int _expectedParentEntryCount(
  _ProfileScenario scenario,
  DashboardProfileSeedFixture fixture,
) {
  final year = scenario.initialPlane == TimePlane.sum
      ? null
      : scenario.initialDate.year;
  final month = scenario.initialPlane == TimePlane.month
      ? scenario.initialDate.month
      : null;
  return switch (scenario.initialDirection) {
    LedgerDirection.income => fixture.incomeEntryCount(
      year: year,
      month: month,
    ),
    LedgerDirection.expense => fixture.expenseEntryCount(
      year: year,
      month: month,
    ),
  };
}

Future<Map<String, dynamic>> _runScenario(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  _ProfileScenario scenario,
  DashboardProfileSeedFixture fixture,
) async {
  final repository = MethodChannelDashboardDataRuntimeRepository();
  final firstValidPaintTimer = Stopwatch()..start();
  await tester.pumpWidget(
    FluviApp(
      dashboardRepository: repository,
      initialDate: scenario.initialDate,
      initialPlane: scenario.initialPlane,
      initialRailOpen: scenario.initialRailOpen,
      initialDirection: scenario.initialDirection,
    ),
  );
  await _pumpUntilDashboardReady(tester);
  firstValidPaintTimer.stop();
  final controller = tester
      .widget<CoreDashboard>(find.byType(CoreDashboard))
      .controller;
  final expectedParentEntryCount = _expectedParentEntryCount(scenario, fixture);
  await _prepareScenario(
    tester,
    controller,
    scenario,
    expectedParentEntryCount: expectedParentEntryCount,
  );
  debugPrint(
    '[PROFILE][SCENARIO_PREPARED] ${scenario.reportKey} '
    'plane=${controller.navigation.state.plane.name}',
  );
  if (scenario == _ProfileScenario.tenthFling) {
    await _settle(tester);
  }
  debugPrint('[PROFILE][SCENARIO_STABLE] ${scenario.reportKey}');

  final carousel = controller.motion.carouselController;
  final scrollController = carousel.scrollController;
  final position = scrollController.position;
  final physics = controller.motion.dashboardPhysics;
  final identitiesBefore = <String, int>{
    'motion_kernel': identityHashCode(controller.motion),
    'carousel_controller': identityHashCode(carousel),
    'scroll_controller': identityHashCode(scrollController),
    'scroll_position': identityHashCode(position),
    'physics': identityHashCode(physics),
  };
  final semanticSequence = <int>[];
  final visibleSemanticSequence = <int>[];
  var traversalCatalog = controller.motion.catalog;
  final rawStartIndex = carousel.selectedLogicalIndex;
  var previousRawIndex = rawStartIndex;
  void collectMotionTraversal() {
    final currentCatalog = controller.motion.catalog;
    final currentRawIndex = carousel.selectedLogicalIndex;
    if (!identical(currentCatalog, traversalCatalog)) {
      traversalCatalog = currentCatalog;
      previousRawIndex = currentRawIndex;
      return;
    }
    DashboardProfileReport.appendSemanticTraversal(
      semanticSequence,
      previousRawIndex: previousRawIndex,
      currentRawIndex: currentRawIndex,
      normalize: (rawIndex) =>
          currentCatalog.entryAtLogicalIndex(rawIndex).logicalIndex,
    );
    previousRawIndex = currentRawIndex;
  }

  void collectVisible() {
    final index = controller.visibleFrames.value?.semanticChildIndex;
    if (index != null &&
        (visibleSemanticSequence.isEmpty ||
            visibleSemanticSequence.last != index)) {
      visibleSemanticSequence.add(index);
    }
  }

  controller.motion.addListener(collectMotionTraversal);
  controller.visibleFrames.addListener(collectVisible);
  controller.performanceCounters.reset();
  final railFlightRecorder = controller.railFlightRecorder;
  expect(
    railFlightRecorder,
    isNotNull,
    reason: 'Profile builds must enable FLUVI_RAIL_FLIGHT_RECORDER.',
  );
  railFlightRecorder!.clear();
  final vectorAtlas = PreparedVectorAssetAtlas.instance;
  final vectorPictureDecodesBefore = vectorAtlas.pictureDecodeCount;
  final repositoryBefore = repository.performanceReport();
  final visiblePublishesBefore = controller.visibleFrames.visiblePublishCount;
  final coalescedPublishesBefore = controller.frameCoalescer.publishCount;
  final staleCallbacksBefore =
      controller.dataRuntime.discardedIndexCount +
      controller.paging.stalePageRejectCount;
  final rssBefore = ProcessInfo.currentRss;
  final maxRssBefore = ProcessInfo.maxRss;
  final startIndex = traversalCatalog
      .entryAtLogicalIndex(rawStartIndex)
      .logicalIndex;
  // `_captureProfilePerformance` deliberately lets the dashboard settle
  // before it starts its trace.  Capture this boundary inside the traced
  // action, immediately before the measured gesture, so a completed
  // pre-capture warmup is never attributed to motion.
  late int completedScenePreparationEpochAtMotionStart;
  final frameKey = '${scenario.reportKey}_frames';
  final timelineKey = '${scenario.reportKey}_timeline';
  final motionDuration = Stopwatch();

  await _captureProfilePerformance(
    binding,
    () => _timelineStep(scenario.reportKey, () async {
      completedScenePreparationEpochAtMotionStart = _scenePreparationEpoch(
        Map<String, Object?>.from(
          controller.exportPhysicalRailReport()['sceneWindow']! as Map,
        ),
      );
      motionDuration.start();
      try {
        await _runMeasuredScenario(tester, controller, scenario);
      } finally {
        motionDuration.stop();
      }
    }),
    frameKey: frameKey,
    timelineKey: timelineKey,
    preCaptureDelay: scenario == _ProfileScenario.firstFling
        ? Duration.zero
        : const Duration(seconds: 2),
  );
  controller.motion.removeListener(collectMotionTraversal);
  controller.visibleFrames.removeListener(collectVisible);

  final rawFrameReport = binding.reportData?[frameKey];
  expect(rawFrameReport, isA<Map>());
  final report = Map<String, dynamic>.from(rawFrameReport! as Map);
  DashboardProfileReport.addRequiredPercentiles(report);
  final railFlightEvents = railFlightRecorder.snapshot();
  final visible = controller.visibleFrames.value!;
  final identitiesAfter = <String, int>{
    'motion_kernel': identityHashCode(controller.motion),
    'carousel_controller': identityHashCode(
      controller.motion.carouselController,
    ),
    'scroll_controller': identityHashCode(
      controller.motion.carouselController.scrollController,
    ),
    'scroll_position': identityHashCode(
      controller.motion.carouselController.scrollController.position,
    ),
    'physics': identityHashCode(controller.motion.dashboardPhysics),
  };
  final repositoryAfter = repository.performanceReport();
  final platformChannelMicros = _durationListDelta(
    repositoryBefore,
    repositoryAfter,
    'platform_duration_micros',
  );
  final dartParsingMicros = _durationListDelta(
    repositoryBefore,
    repositoryAfter,
    'index_decode_duration_micros',
  );
  final indexMetrics = controller.preparedIndex!.buildMetrics;
  final physicalRailReport = controller.exportPhysicalRailReport();
  final sceneWindowReport = Map<String, Object?>.from(
    physicalRailReport['sceneWindow']! as Map,
  );
  final completedScenePreparationEpochAfterMotion = _scenePreparationEpoch(
    sceneWindowReport,
  );
  final completedScenePreparationsDuringMotion =
      completedScenePreparationEpochAfterMotion -
      completedScenePreparationEpochAtMotionStart;
  final motionScopedScenePreparationSliceMicros =
      DashboardProfileReport.motionScopedScenePreparationSliceMicros(
        completedPreparationEpochAtMotionStart:
            completedScenePreparationEpochAtMotionStart,
        completedPreparationEpochAtMotionEnd:
            completedScenePreparationEpochAfterMotion,
        lastCompletedSliceMicros: _scenePreparationSliceMicros(
          sceneWindowReport,
        ),
      );
  final memoryBudget = Map<String, Object?>.from(
    physicalRailReport['memoryBudget']! as Map,
  );
  report.addAll(<String, dynamic>{
    'scenario': scenario.reportKey,
    'expected_parent_entry_count': expectedParentEntryCount,
    'rss_before_bytes': rssBefore,
    'rss_after_bytes': ProcessInfo.currentRss,
    'rss_delta_bytes': ProcessInfo.currentRss - rssBefore,
    'allocation_burst_rss_bytes': ProcessInfo.currentRss - rssBefore,
    'max_rss_before_bytes': maxRssBefore,
    'max_rss_after_bytes': ProcessInfo.maxRss,
    'peak_rss_bytes': math.max(maxRssBefore, ProcessInfo.maxRss),
    'first_valid_paint_micros': firstValidPaintTimer.elapsedMicroseconds,
    'index_publish_duration_micros':
        controller.dataRuntime.lastIndexPublishDurationMicros,
    'prepared_index_bytes': indexMetrics.estimatedIndexBytes,
    'logbox_raster_bytes': vectorAtlas.logBoxRasterByteEstimate,
    'logbox_raster_prepare_duration_micros':
        vectorAtlas.logBoxRasterPrepareDurationMicros,
    'logbox_text_layout_estimated_bytes':
        memoryBudget['logBoxTextLayoutEstimatedBytes'],
    'logbox_text_layout_prepared_rows':
        memoryBudget['logBoxTextLayoutPreparedRows'],
    'logbox_text_layout_prepared_day_headers':
        memoryBudget['logBoxTextLayoutPreparedDayHeaders'],
    'vector_picture_decode_count': vectorAtlas.pictureDecodeCount,
    'vector_picture_prepare_duration_micros': vectorAtlas.prepareDurationMicros,
    'vector_picture_decodes_during_motion':
        vectorAtlas.pictureDecodeCount - vectorPictureDecodesBefore,
    'motion_duration_micros': motionDuration.elapsedMicroseconds,
    'scene_preparation_largest_contiguous_ui_slice_micros':
        motionScopedScenePreparationSliceMicros,
    'scene_preparation_completed_during_motion':
        completedScenePreparationsDuringMotion,
    'platform_channel_duration_micros': platformChannelMicros,
    'sql_duration_micros': 0,
    'dart_parsing_duration_micros': dartParsingMicros,
    'prepared_projection_duration_micros': dartParsingMicros,
    'sql_call_count': 0,
    'platform_call_count': _scalarDelta(
      repositoryBefore,
      repositoryAfter,
      'platform_calls',
    ),
    'index_build_call_count': _scalarDelta(
      repositoryBefore,
      repositoryAfter,
      'index_build_calls',
    ),
    'page_read_count': _scalarDelta(
      repositoryBefore,
      repositoryAfter,
      'page_read_calls',
    ),
    'startup_index_metrics': <String, Object?>{
      'sql_call_count': indexMetrics.sqlCallCount,
      'sql_duration_micros': indexMetrics.nativeSqlDurationMicros,
      'native_query_micros': indexMetrics.nativeQueryDurationMicros,
      'native_aggregation_micros': indexMetrics.nativeAggregationDurationMicros,
      'native_mapping_micros': indexMetrics.nativeMappingDurationMicros,
      'serialization_micros': indexMetrics.serializationDurationMicros,
      'bridge_transfer_micros': indexMetrics.bridgeTransferDurationMicros,
      'dart_decode_micros': indexMetrics.dartDecodeDurationMicros,
      'dart_projection_micros': indexMetrics.dartProjectionDurationMicros,
      'index_publish_micros':
          controller.dataRuntime.lastIndexPublishDurationMicros,
      'first_valid_paint_micros': firstValidPaintTimer.elapsedMicroseconds,
      'payload_bytes': indexMetrics.payloadBytes,
      'estimated_index_bytes': indexMetrics.estimatedIndexBytes,
    },
    'native_payload_bytes': _durationListDelta(
      repositoryBefore,
      repositoryAfter,
      'payload_bytes',
    ),
    'benchmark_environment': <String, Object?>{
      'source': 'native-room-sqlite-binary-worker-isolate',
      'operating_system': Platform.operatingSystem,
      'operating_system_version': Platform.operatingSystemVersion,
      'number_of_processors': Platform.numberOfProcessors,
      'dart_version': Platform.version,
    },
    'performance_counters': _counterReport(controller),
    'rail_flight': _railFlightReport(
      railFlightEvents,
      overwrittenEventCount: railFlightRecorder.overwrittenEventCount,
    ),
    'physical_rail_report': physicalRailReport,
    'repository_before': repositoryBefore,
    'repository_after': repositoryAfter,
    'gc': _gcReport(binding.reportData?[timelineKey]),
    'semantic_sequence': semanticSequence,
    'visible_semantic_sequence': visibleSemanticSequence,
    'rail_start_index': startIndex,
    'rail_target_index': controller.motion.state.semanticIndex,
    'rail_settle_index': controller.motion.state.semanticIndex,
    'visible_publish_count':
        controller.visibleFrames.visiblePublishCount - visiblePublishesBefore,
    'coalesced_publish_count':
        controller.frameCoalescer.publishCount - coalescedPublishesBefore,
    'max_publishes_per_display_frame':
        controller.frameCoalescer.maximumPublishesInOneDisplayFrame,
    'stale_callback_count':
        controller.dataRuntime.discardedIndexCount +
        controller.paging.stalePageRejectCount -
        staleCallbacksBefore,
    'identities_before': identitiesBefore,
    'identities_after': identitiesAfter,
    'controller_recreation_count':
        identitiesBefore['carousel_controller'] ==
            identitiesAfter['carousel_controller']
        ? 0
        : 1,
    'physics_recreation_count':
        identitiesBefore['physics'] == identitiesAfter['physics'] ? 0 : 1,
    'scroll_position_recreation_count':
        identitiesBefore['scroll_position'] ==
            identitiesAfter['scroll_position']
        ? 0
        : 1,
    'visible_query_key': visible.queryKey.value,
    'visible_parent_query_key': visible.parentQueryKey.value,
    'visible_revision': visible.coreRevision,
    'verbose_flow_enabled': false,
  });
  binding.reportData!
    ..remove(frameKey)
    ..remove(timelineKey);
  DashboardProfileReport.validateRequiredScenarioMetrics(report);
  binding.reportData![scenario.reportKey] = report;

  _expectFrameInvariant(controller);
  expect(
    controller.frameCoalescer.maximumPublishesInOneDisplayFrame,
    lessThanOrEqualTo(1),
  );
  expect(identitiesAfter, identitiesBefore);
  for (final metric in <DashboardPerformanceMetric>[
    DashboardPerformanceMetric.sqlCallsDuringMotion,
    DashboardPerformanceMetric.platformCallsDuringMotion,
    DashboardPerformanceMetric.repositoryReadsDuringMotion,
    DashboardPerformanceMetric.liveLeaseStartsDuringMotion,
    DashboardPerformanceMetric.logBoxProjectionsDuringMotion,
    DashboardPerformanceMetric.formattingDuringMotion,
    DashboardPerformanceMetric.railPresentationDataDependencyViolation,
  ]) {
    expect(controller.performanceCounters.value(metric), 0);
  }

  await tester.pumpWidget(const SizedBox.shrink());
  await _settle(tester);
  return report;
}

int _scenePreparationEpoch(Map<String, Object?> sceneWindowReport) {
  final value = sceneWindowReport['completedPreparationEpoch'];
  if (value is! int || value < 0) {
    throw StateError(
      'Profile scene window has invalid completedPreparationEpoch=$value.',
    );
  }
  return value;
}

int _scenePreparationSliceMicros(Map<String, Object?> sceneWindowReport) {
  final value = sceneWindowReport['lastPrepareLargestContiguousUiSliceMicros'];
  if (value is! int || value < 0) {
    throw StateError(
      'Profile scene window has invalid '
      'lastPrepareLargestContiguousUiSliceMicros=$value.',
    );
  }
  return value;
}

Map<String, Object?> _railFlightReport(
  List<DashboardRailFlightEvent> events, {
  required int overwrittenEventCount,
}) {
  DashboardRailFlightEvent? last(DashboardRailFlightEventType type) {
    for (var index = events.length - 1; index >= 0; index -= 1) {
      if (events[index].type == type) return events[index];
    }
    return null;
  }

  int percentile(List<int> values, double fraction) => values.isEmpty
      ? 0
      : DashboardProfileReport.percentileMicros(values, fraction);

  final release = last(DashboardRailFlightEventType.gestureReleased);
  final ballistic = last(DashboardRailFlightEventType.ballisticStarted);
  final settle = last(DashboardRailFlightEventType.railSettled);
  final timing = last(DashboardRailFlightEventType.frameTiming);
  final sample = last(DashboardRailFlightEventType.gestureSampleSummary);
  final applyMicros = events
      .where(
        (event) =>
            event.type ==
            DashboardRailFlightEventType.presentationApplyCompleted,
      )
      .map((event) => event.applyMicros)
      .toList(growable: false);
  return <String, Object?>{
    'event_count': events.length,
    'overwritten_event_count': overwrittenEventCount,
    'gesture_id': settle?.gestureId ?? release?.gestureId ?? 0,
    'drag_end_velocity': release?.dragEndVelocity,
    'primary_velocity': release?.primaryVelocity,
    'ballistic_input_velocity': ballistic?.ballisticInputVelocity,
    'simulation_target_pixels': ballistic?.targetPixels,
    'item_extent':
        ballistic?.geometry?.itemExtent ?? settle?.geometry?.itemExtent,
    'start_pixels': settle?.startPixels,
    'final_pixels': settle?.finalPixels,
    'total_pixel_distance': settle == null
        ? null
        : settle.finalPixels - settle.startPixels,
    'start_logical_index': settle?.startLogicalIndex,
    'final_logical_index': settle?.finalLogicalIndex,
    'logical_delta': settle == null
        ? null
        : settle.finalLogicalIndex - settle.startLogicalIndex,
    'activity_interrupt_count': settle?.activityInterruptCount ?? 0,
    'metric_change_count': settle?.metricChangeCount ?? 0,
    'populated_child_cross_count': settle?.populatedChildCrossCount ?? 0,
    'empty_child_cross_count': settle?.emptyChildCrossCount ?? 0,
    'presentation_apply_total_micros':
        settle?.presentationApplyTotalMicros ?? 0,
    'presentation_apply_max_micros': settle?.presentationApplyMaxMicros ?? 0,
    'presentation_apply_p50_micros': percentile(applyMicros, .50),
    'presentation_apply_p95_micros': percentile(applyMicros, .95),
    'presentation_apply_p99_micros': percentile(applyMicros, .99),
    'root_rebuild_count': settle?.rootRebuildCount ?? 0,
    'rail_rebuild_count': settle?.railRebuildCount ?? 0,
    'log_viewport_rebuild_count': settle?.logViewportRebuildCount ?? 0,
    'data_io_count': settle?.dataIoCount ?? 0,
    'platform_call_count': settle?.platformCallCount ?? 0,
    'sql_count': settle?.sqlCount ?? 0,
    'gesture_sample_count': sample?.sampleCount ?? 0,
    'pointer_gap_p50_micros': sample?.pointerEventGapP50Micros ?? 0,
    'pointer_gap_p95_micros': sample?.pointerEventGapP95Micros ?? 0,
    'longest_pointer_gap_micros': sample?.longestPointerEventGapMicros ?? 0,
    'ui_frame_p50_micros': timing?.uiFrameP50Micros ?? 0,
    'ui_frame_p95_micros': timing?.uiFrameP95Micros ?? 0,
    'ui_frame_p99_micros': timing?.uiFrameP99Micros ?? 0,
    'raster_frame_p50_micros': timing?.rasterFrameP50Micros ?? 0,
    'raster_frame_p95_micros': timing?.rasterFrameP95Micros ?? 0,
    'raster_frame_p99_micros': timing?.rasterFrameP99Micros ?? 0,
    'build_duration_micros': timing?.buildDurationMicros ?? 0,
    'layout_duration_micros': timing?.layoutDurationMicros ?? 0,
    'paint_duration_micros': timing?.paintDurationMicros ?? 0,
    'raster_duration_micros': timing?.rasterDurationMicros ?? 0,
    'controller_identity': settle?.identities?.controllerIdentity,
    'position_identity': settle?.identities?.positionIdentity,
    'physics_identity': settle?.identities?.physicsIdentity,
    'viewport_identity': settle?.identities?.viewportIdentity,
    'events': events
        .map((event) => event.toReportMap())
        .toList(growable: false),
  };
}

int _durationListDelta(
  Map<String, Object?> before,
  Map<String, Object?> after,
  String key,
) {
  int sum(Object? value) => value is List
      ? value.fold<int>(0, (total, item) => total + (item as num).toInt())
      : 0;
  return sum(after[key]) - sum(before[key]);
}

int _scalarDelta(
  Map<String, Object?> before,
  Map<String, Object?> after,
  String key,
) =>
    ((after[key] as num?)?.toInt() ?? 0) -
    ((before[key] as num?)?.toInt() ?? 0);

void _expectEquivalentMotion(
  Map<String, dynamic> first,
  Map<String, dynamic> second, {
  required String label,
  bool requireNoSlowdown = false,
}) {
  expect(
    second['rail_target_index'],
    first['rail_target_index'],
    reason: '$label target drifted',
  );
  expect(
    second['rail_settle_index'],
    first['rail_settle_index'],
    reason: '$label settle drifted',
  );
  expect(
    second['semantic_sequence'],
    first['semantic_sequence'],
    reason: '$label semantic sequence drifted',
  );
  final firstDuration = (first['motion_duration_micros'] as num).toInt();
  final secondDuration = (second['motion_duration_micros'] as num).toInt();
  final tolerance = math.max(32_000, (firstDuration * .15).round());
  if (requireNoSlowdown) {
    // The tenth fling runs after warmup. Its wall-clock duration can be
    // shorter than the cold first fling without changing the rail simulation,
    // which the exact target, settle, semantic and flight checks above cover.
    // This lane is a regression gate, so reject only an actual slowdown.
    expect(
      secondDuration,
      lessThanOrEqualTo(firstDuration + tolerance),
      reason: '$label duration regressed beyond tolerance',
    );
  } else {
    expect(
      (secondDuration - firstDuration).abs(),
      lessThanOrEqualTo(tolerance),
      reason: '$label duration exceeded tolerance',
    );
  }
}

void _expectEquivalentRailFlight(
  Map<String, dynamic> first,
  Map<String, dynamic> second, {
  required String label,
}) {
  final firstFlight = Map<String, Object?>.from(first['rail_flight']! as Map);
  final secondFlight = Map<String, Object?>.from(second['rail_flight']! as Map);
  double number(Map<String, Object?> source, String key) {
    final value = source[key];
    if (value is! num) fail('$label has no numeric rail_flight.$key');
    return value.toDouble();
  }

  double relativeDifference(String key) {
    final left = number(firstFlight, key);
    final right = number(secondFlight, key);
    final denominator = math.max(left.abs(), right.abs());
    return denominator == 0 ? 0 : (left - right).abs() / denominator;
  }

  expect(
    relativeDifference('drag_end_velocity'),
    lessThanOrEqualTo(.02),
    reason: '$label drag-end velocity drifted',
  );
  expect(
    relativeDifference('ballistic_input_velocity'),
    lessThanOrEqualTo(.02),
    reason: '$label ballistic input drifted',
  );
  final halfItemExtent = number(firstFlight, 'item_extent') / 2;
  expect(
    (number(firstFlight, 'total_pixel_distance') -
            number(secondFlight, 'total_pixel_distance'))
        .abs(),
    lessThanOrEqualTo(halfItemExtent),
    reason: '$label physical endpoint drifted',
  );
  expect(
    (number(firstFlight, 'logical_delta') -
            number(secondFlight, 'logical_delta'))
        .abs(),
    lessThanOrEqualTo(1),
    reason: '$label semantic endpoint drifted',
  );
  for (final flight in <Map<String, Object?>>[firstFlight, secondFlight]) {
    for (final key in const <String>[
      'activity_interrupt_count',
      'metric_change_count',
      'root_rebuild_count',
      'rail_rebuild_count',
      'data_io_count',
      'platform_call_count',
      'sql_count',
    ]) {
      expect(flight[key], 0, reason: '$label rail_flight.$key');
    }
    expect(
      number(flight, 'log_viewport_rebuild_count'),
      lessThanOrEqualTo(
        DashboardProfileReport.maximumLogViewportRebuildsPerFlight,
      ),
      reason:
          '$label rail_flight.log_viewport_rebuild_count must remain a '
          'single structural bind, never a per-tick rebuild stream',
    );
  }
}

Future<void> _prepareScenario(
  WidgetTester tester,
  DashboardCoreController controller,
  _ProfileScenario scenario, {
  required int expectedParentEntryCount,
}) async {
  expect(controller.navigation.state.plane, scenario.initialPlane);
  expect(controller.navigation.state.isRailOpen, scenario.initialRailOpen);
  expect(
    controller.navigation.state.parentQueryScope.direction,
    scenario.initialDirection,
  );
  expect(
    controller.preparedIndex!
        .frameFor(controller.navigation.state.parentQueryScope)
        .entryCount,
    expectedParentEntryCount,
  );
  if (scenario == _ProfileScenario.tenthFling) {
    for (var index = 0; index < 9; index += 1) {
      await _resetRailToIndex(tester, controller, 13);
      await _flingRail(tester, controller);
    }
    await _resetRailToIndex(tester, controller, 13);
  }
}

Future<void> _resetRailToIndex(
  WidgetTester tester,
  DashboardCoreController controller,
  int logicalIndex,
) async {
  await _waitForMotionIdle(controller);
  await tester.pump();
  final catalog = controller.motion.catalog;
  final entry = catalog.entryAtLogicalIndex(logicalIndex);
  controller.motion.carouselController.jumpToIndex(logicalIndex);
  await _waitForVisibleReset(tester, controller, entry);
  final visiblePublishCount = controller.visibleFrames.visiblePublishCount;
  final visualDigest = controller.visibleFrames.value?.visualDigest;
  controller.settleRail(logicalIndex);
  await tester.pump();

  expect(controller.visibleFrames.visiblePublishCount, visiblePublishCount);
  expect(controller.visibleFrames.value?.visualDigest, visualDigest);
  expect(controller.motion.state.semanticIndex, entry.logicalIndex);
  expect(
    controller.visibleFrames.value?.semanticChildIndex,
    entry.logicalIndex,
  );
  expect(controller.visibleFrames.value?.queryKey, entry.queryKey);
}

Future<void> _waitForVisibleReset(
  WidgetTester tester,
  DashboardCoreController controller,
  DashboardSemanticEntry entry,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  var consecutiveReadySamples = 0;
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump();
    final visible = controller.visibleFrames.value;
    final isReady =
        controller.motion.state.semanticIndex == entry.logicalIndex &&
        visible?.semanticChildIndex == entry.logicalIndex &&
        visible?.queryKey == entry.queryKey &&
        !controller.frameCoalescer.hasPendingTarget;
    if (isReady) {
      consecutiveReadySamples += 1;
      if (consecutiveReadySamples >= 3) return;
    } else {
      consecutiveReadySamples = 0;
    }
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  fail(
    'Dashboard rail reset did not reach one coherent visible display frame: '
    'motion=${controller.motion.state.semanticIndex} '
    'visible=${controller.visibleFrames.value?.semanticChildIndex} '
    'target=${entry.logicalIndex} '
    'pending=${controller.frameCoalescer.hasPendingTarget}.',
  );
}

Future<void> _runMeasuredScenario(
  WidgetTester tester,
  DashboardCoreController controller,
  _ProfileScenario scenario,
) async {
  switch (scenario) {
    case _ProfileScenario.summaryPlane:
      await _flingSummary(tester, const Offset(0, -180));
      await _flingSummary(tester, const Offset(0, -180));
    case _ProfileScenario.yearPopulated:
    case _ProfileScenario.yearEmpty:
    case _ProfileScenario.month94:
    case _ProfileScenario.monthEmpty:
      for (var index = 0; index < 10; index += 1) {
        await _flingRail(tester, controller);
      }
    case _ProfileScenario.firstFling:
    case _ProfileScenario.tenthFling:
      await _flingRail(tester, controller);
    case _ProfileScenario.parentWhileRailOpen:
      await _flingSummary(tester, const Offset(-180, 0));
    case _ProfileScenario.directionWhileRailOpen:
      await tester.tap(find.byKey(const ValueKey('fluvi-expense-button')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('fluvi-income-button')));
      await _settle(tester);
    case _ProfileScenario.pulseWithParentNavigation:
      await tester.tap(find.byKey(const ValueKey('fluvi-income-button')));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.fling(
        find.byKey(const ValueKey('dashboard-summary-shell-transform')),
        const Offset(-180, 0),
        1200,
      );
      await _settle(tester);
  }
}

Future<void> _flingRail(
  WidgetTester tester,
  DashboardCoreController controller,
) async {
  await tester.fling(
    find.byKey(const ValueKey('dashboard-time-rail')),
    const Offset(-420, 0),
    2200,
  );
  await _waitForMotionIdle(controller);
}

Future<void> _waitForMotionIdle(DashboardCoreController controller) async {
  final carousel = controller.motion.carouselController;
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  var consecutiveIdleSamples = 0;
  while (DateTime.now().isBefore(deadline)) {
    final isIdle =
        controller.motion.state.activity == DashboardMotionActivity.idle &&
        !carousel.hasActiveScrollActivity;
    if (isIdle) {
      consecutiveIdleSamples += 1;
      if (consecutiveIdleSamples >= 3) return;
    } else {
      consecutiveIdleSamples = 0;
    }
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
  fail(
    'Dashboard rail did not become motion-idle before the profile timeout: '
    'activity=${controller.motion.state.activity.name} '
    'scrollActivity=${carousel.hasActiveScrollActivity}.',
  );
}

Future<void> _flingSummary(WidgetTester tester, Offset offset) async {
  await tester.fling(
    find.byKey(const ValueKey('dashboard-summary-shell-transform')),
    offset,
    1200,
  );
  await _settle(tester);
}

void _expectFrameInvariant(DashboardCoreController controller) {
  final frame = controller.visibleFrames.value!;
  expect(frame.amount.queryKey, frame.queryKey);
  expect(frame.count.queryKey, frame.queryKey);
  expect(frame.logBox.queryKey, frame.queryKey);
  expect(frame.amount.coreRevision, frame.coreRevision);
  expect(frame.count.coreRevision, frame.coreRevision);
  expect(frame.logBox.revision, frame.coreRevision);
}

Map<String, int> _counterReport(DashboardCoreController controller) => {
  for (final entry in controller.performanceCounters.snapshot().entries)
    entry.key.name: entry.value,
};

Map<String, Object?> _gcReport(Object? raw) {
  final durations = <int>[];
  void visit(Object? value) {
    if (value is List) {
      for (final child in value) {
        visit(child);
      }
      return;
    }
    if (value is! Map) return;
    final name = value['name']?.toString().toLowerCase() ?? '';
    final duration = value['dur'];
    if (name.contains('gc') && duration is num) {
      durations.add(duration.toInt());
    }
    for (final child in value.values) {
      visit(child);
    }
  }

  visit(raw);
  return <String, Object?>{
    'pause_count': durations.length,
    'total_pause_micros': durations.fold<int>(0, (sum, value) => sum + value),
    'max_pause_micros': durations.isEmpty
        ? 0
        : durations.reduce((left, right) => left > right ? left : right),
  };
}

Map<String, Object?> _p95Comparison(
  Map<String, dynamic> baseline,
  Map<String, dynamic> candidate,
) {
  double delta(String key) {
    final left = baseline[key] as num?;
    final right = candidate[key] as num?;
    if (left == null || right == null || left == 0) return 0;
    return ((right - left) / left) * 100;
  }

  return <String, Object?>{
    'frame_build_p95_delta_percent': delta(
      '95th_percentile_frame_build_time_millis',
    ),
    'frame_raster_p95_delta_percent': delta(
      '95th_percentile_frame_rasterizer_time_millis',
    ),
    'target_equal':
        baseline['rail_target_index'] == candidate['rail_target_index'],
    'settle_equal':
        baseline['rail_settle_index'] == candidate['rail_settle_index'],
  };
}

Future<void> _timelineStep(String name, Future<void> Function() action) async {
  final task = developer.TimelineTask()..start(name);
  try {
    await action();
  } finally {
    task.finish();
  }
}

Future<void> _captureProfilePerformance(
  IntegrationTestWidgetsFlutterBinding binding,
  Future<void> Function() action, {
  required String frameKey,
  required String timelineKey,
  Duration preCaptureDelay = const Duration(seconds: 2),
}) async {
  if (preCaptureDelay > Duration.zero) {
    await Future<void>.delayed(preCaptureDelay);
  }
  final frameTimings = <FrameTiming>[];
  void collectFrameTimings(List<FrameTiming> timings) {
    frameTimings.addAll(timings);
  }

  binding.addTimingsCallback(collectFrameTimings);
  try {
    await binding.traceAction(
      action,
      reportKey: timelineKey,
      streams: const <String>['GC'],
    );
    // The engine batches FrameTimings asynchronously.  The software-rendered
    // CI emulator can take longer than the historical two-second grace period
    // to publish the first batch after a heavy scenario.  Keep the profile
    // metric mandatory, but wait for that batch with a finite watchdog instead
    // of treating a delayed engine callback as an empty performance sample.
    const frameTimingBatchTimeout = Duration(seconds: 12);
    final frameTimingDeadline = DateTime.now().add(frameTimingBatchTimeout);
    while (frameTimings.isEmpty &&
        DateTime.now().isBefore(frameTimingDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  } finally {
    binding.removeTimingsCallback(collectFrameTimings);
  }
  expect(frameTimings, isNotEmpty);
  binding.reportData ??= <String, dynamic>{};
  binding.reportData![frameKey] = FrameTimingSummarizer(frameTimings).summary;
}

Future<void> _settle(WidgetTester _) =>
    Future<void>.delayed(const Duration(milliseconds: 1500));

Future<void> _pumpUntilDashboardReady(WidgetTester tester) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    final dashboard = find.byType(CoreDashboard);
    final gate = find.byKey(
      const ValueKey('dashboard-interaction-readiness-gate'),
    );
    if (dashboard.evaluate().length == 1 &&
        gate.evaluate().length == 1 &&
        !tester.widget<AbsorbPointer>(gate).absorbing &&
        find
            .byKey(const ValueKey('dashboard-bootstrap-surface'))
            .evaluate()
            .isEmpty) {
      return;
    }
  }
  fail('Dashboard did not reach interaction readiness before timeout.');
}
