import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/core/demo_data/demo_data_bridge.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/query/data/method_channel_dashboard_prepared_repository.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:integration_test/integration_test.dart';

import 'support/dashboard_profile_report.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'profiles dashboard motion-data isolation scenarios A through J',
    (tester) async {
      final seedReport = await const MethodChannelDemoDataBridge()
          .seedDemoDataset(forceReset: true);
      expect(seedReport.createdEntryCount, 700);
      expect(seedReport.monthlyReports, hasLength(7));
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['dashboard_native_seed'] = <String, Object?>{
        'seed_version': seedReport.seedVersion,
        'created_entry_count': seedReport.createdEntryCount,
        'duration_ms': seedReport.durationMs,
      };
      final reports = <String, Map<String, dynamic>>{};
      for (final scenario in _ProfileScenario.values) {
        reports[scenario.reportKey] = await _runScenario(
          binding,
          tester,
          scenario,
        );
      }
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
      _expectEquivalentMotion(
        reports[_ProfileScenario.month94.reportKey]!,
        reports[_ProfileScenario.monthEmpty.reportKey]!,
        label: 'month populated/empty',
      );
      _expectEquivalentMotion(
        reports[_ProfileScenario.firstFling.reportKey]!,
        reports[_ProfileScenario.tenthFling.reportKey]!,
        label: 'first/tenth fling',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

enum _ProfileScenario {
  summaryPlane,
  yearPopulated,
  yearEmpty,
  month94,
  monthEmpty,
  parentWhileRailOpen,
  directionWhileRailOpen,
  pulseWithParentNavigation,
  firstFling,
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

  int get density => switch (this) {
    summaryPlane || yearPopulated => 658,
    yearEmpty || monthEmpty => 0,
    directionWhileRailOpen => 6,
    _ => 94,
  };

  DateTime get initialDate => switch (this) {
    yearEmpty || monthEmpty => DateTime(2025, 7, 14),
    _ => DateTime(2026, 7, 14),
  };
}

Future<Map<String, dynamic>> _runScenario(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  _ProfileScenario scenario,
) async {
  final repository = MethodChannelDashboardPreparedRepository();
  await tester.pumpWidget(
    FluviApp(
      dashboardRepository: repository,
      initialDate: scenario.initialDate,
    ),
  );
  await _pumpUntilFound(tester, find.byType(CoreDashboard));
  final controller = tester
      .widget<CoreDashboard>(find.byType(CoreDashboard))
      .controller;
  await _prepareScenario(tester, controller, scenario);
  await _settle(tester);

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
  void collectVisible() {
    final index = controller.visibleFrames.value?.semanticChildIndex;
    if (index != null &&
        (semanticSequence.isEmpty || semanticSequence.last != index)) {
      semanticSequence.add(index);
    }
  }

  controller.visibleFrames.addListener(collectVisible);
  controller.performanceCounters.reset();
  final repositoryBefore = repository.performanceReport();
  final visiblePublishesBefore = controller.visibleFrames.visiblePublishCount;
  final coalescedPublishesBefore = controller.frameCoalescer.publishCount;
  final staleCallbacksBefore =
      controller.staleDeckCompletionCount +
      controller.committed.staleCallbackRejectedCount;
  final rssBefore = ProcessInfo.currentRss;
  final maxRssBefore = ProcessInfo.maxRss;
  final startIndex = controller.motion.state.semanticIndex;
  final frameKey = '${scenario.reportKey}_frames';
  final timelineKey = '${scenario.reportKey}_timeline';
  final motionDuration = Stopwatch();

  await binding.watchPerformance(
    () => binding.traceAction(
      () => _timelineStep(scenario.reportKey, () async {
        motionDuration.start();
        try {
          await _runMeasuredScenario(tester, controller, scenario);
        } finally {
          motionDuration.stop();
        }
      }),
      reportKey: timelineKey,
      streams: const <String>['Dart', 'Embedder', 'GC', 'Compiler'],
    ),
    reportKey: frameKey,
  );
  controller.visibleFrames.removeListener(collectVisible);

  final rawFrameReport = binding.reportData?[frameKey];
  expect(rawFrameReport, isA<Map>());
  final report = Map<String, dynamic>.from(rawFrameReport! as Map);
  DashboardProfileReport.addRequiredPercentiles(report);
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
    'platform_channel_duration_micros',
  );
  final sqlMicros = _durationListDelta(
    repositoryBefore,
    repositoryAfter,
    'sql_duration_micros',
  );
  final nativeMappingMicros = _durationListDelta(
    repositoryBefore,
    repositoryAfter,
    'native_mapping_duration_micros',
  );
  final dartParsingMicros = _durationListDelta(
    repositoryBefore,
    repositoryAfter,
    'dart_parsing_duration_micros',
  );
  final liveFrameDecodeMicros = _durationListDelta(
    repositoryBefore,
    repositoryAfter,
    'live_frame_decode_duration_micros',
  );
  report.addAll(<String, dynamic>{
    'scenario': scenario.reportKey,
    'expected_parent_entry_count': scenario.density,
    'rss_before_bytes': rssBefore,
    'rss_after_bytes': ProcessInfo.currentRss,
    'rss_delta_bytes': ProcessInfo.currentRss - rssBefore,
    'allocation_burst_rss_bytes': ProcessInfo.currentRss - rssBefore,
    'max_rss_before_bytes': maxRssBefore,
    'max_rss_after_bytes': ProcessInfo.maxRss,
    'motion_duration_micros': motionDuration.elapsedMicroseconds,
    'platform_channel_duration_micros': platformChannelMicros,
    'sql_duration_micros': sqlMicros,
    'dart_parsing_duration_micros': dartParsingMicros,
    'prepared_projection_duration_micros':
        nativeMappingMicros + dartParsingMicros + liveFrameDecodeMicros,
    'sql_call_count': _durationListDelta(
      repositoryBefore,
      repositoryAfter,
      'sql_call_counts',
    ),
    'platform_call_count': _scalarDelta(
      repositoryBefore,
      repositoryAfter,
      'platform_calls',
    ),
    'prepared_deck_call_count': _scalarDelta(
      repositoryBefore,
      repositoryAfter,
      'prepared_deck_calls',
    ),
    'committed_frame_decode_count': _scalarDelta(
      repositoryBefore,
      repositoryAfter,
      'committed_frame_decodes',
    ),
    'page_read_count': _scalarDelta(
      repositoryBefore,
      repositoryAfter,
      'page_reads',
    ),
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
    'repository_before': repositoryBefore,
    'repository_after': repositoryAfter,
    'gc': _gcReport(binding.reportData?[timelineKey]),
    'semantic_sequence': semanticSequence,
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
        controller.staleDeckCompletionCount +
        controller.committed.staleCallbackRejectedCount -
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
  expect(report['missed_frame_build_budget_count'], 0);
  expect(report['missed_frame_rasterizer_budget_count'], 0);
  for (final metric in <DashboardPerformanceMetric>[
    DashboardPerformanceMetric.sqlCallsDuringMotion,
    DashboardPerformanceMetric.platformCallsDuringMotion,
    DashboardPerformanceMetric.repositoryReadsDuringMotion,
    DashboardPerformanceMetric.liveLeaseStartsDuringMotion,
    DashboardPerformanceMetric.logBoxProjectionsDuringMotion,
    DashboardPerformanceMetric.formattingDuringMotion,
  ]) {
    expect(controller.performanceCounters.value(metric), 0);
  }

  await tester.pumpWidget(const SizedBox.shrink());
  await _settle(tester);
  return report;
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
  expect(
    (secondDuration - firstDuration).abs(),
    lessThanOrEqualTo(tolerance),
    reason: '$label duration exceeded tolerance',
  );
}

Future<void> _prepareScenario(
  WidgetTester tester,
  DashboardCoreController controller,
  _ProfileScenario scenario,
) async {
  if (scenario != _ProfileScenario.directionWhileRailOpen) {
    await tester.tap(find.byKey(const ValueKey('fluvi-expense-button')));
    await _settle(tester);
  }
  switch (scenario) {
    case _ProfileScenario.summaryPlane:
      await _ensurePlane(tester, controller, TimePlane.sum);
    case _ProfileScenario.yearPopulated:
    case _ProfileScenario.yearEmpty:
      await _ensurePlane(tester, controller, TimePlane.year);
      controller.setRailOpen(true);
    case _ProfileScenario.month94:
    case _ProfileScenario.monthEmpty:
    case _ProfileScenario.parentWhileRailOpen:
    case _ProfileScenario.directionWhileRailOpen:
    case _ProfileScenario.pulseWithParentNavigation:
    case _ProfileScenario.firstFling:
      await _ensurePlane(tester, controller, TimePlane.month);
      controller.setRailOpen(true);
    case _ProfileScenario.tenthFling:
      await _ensurePlane(tester, controller, TimePlane.month);
      controller.setRailOpen(true);
      await _settle(tester);
      for (var index = 0; index < 9; index += 1) {
        controller.motion.carouselController.jumpToIndexSilently(13);
        await tester.pump();
        await _flingRail(tester);
      }
  }
  expect(controller.activeDeck?.parentFrame.entryCount, scenario.density);
  if (scenario == _ProfileScenario.firstFling ||
      scenario == _ProfileScenario.tenthFling) {
    controller.motion.carouselController.jumpToIndexSilently(13);
    await tester.pump();
  }
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
    case _ProfileScenario.firstFling:
    case _ProfileScenario.tenthFling:
      await _flingRail(tester);
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

Future<void> _ensurePlane(
  WidgetTester tester,
  DashboardCoreController controller,
  TimePlane target,
) async {
  while (controller.navigation.state.plane != target) {
    await controller.navigatePlane(
      finer: switch ((controller.navigation.state.plane, target)) {
        (TimePlane.month, TimePlane.sum) => true,
        _ => false,
      },
    );
    await _settle(tester);
  }
}

Future<void> _flingRail(WidgetTester tester) async {
  await tester.fling(
    find.byKey(const ValueKey('dashboard-time-rail')),
    const Offset(-420, 0),
    2200,
  );
  await _settle(tester);
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

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 16),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 10),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
