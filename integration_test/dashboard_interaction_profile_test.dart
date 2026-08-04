import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/fluvi_app.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_performance_diagnostics.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:integration_test/integration_test.dart';

import 'support/dashboard_profile_fixture_repository.dart';
import 'support/dashboard_profile_report.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'records identical dashboard gestures at 0, 94 and 1000 rows',
    (tester) async {
      final reportsByDensity = <int, Map<String, dynamic>>{};
      for (final density in const <int>[0, 94, 1000]) {
        reportsByDensity[density] = await _runDensityScenario(
          binding,
          tester,
          density,
        );
      }
      binding.reportData!['density_p95_comparison'] =
          DashboardProfileReport.compareDensityP95(reportsByDensity);
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Future<Map<String, dynamic>> _runDensityScenario(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  int density,
) async {
  final repository = DashboardProfileFixtureRepository(entryCount: density);
  await tester.pumpWidget(FluviApp(dashboardRepository: repository));
  await _pumpUntilFound(tester, find.byType(CoreDashboard));
  final controller = tester
      .widget<CoreDashboard>(find.byType(CoreDashboard))
      .controller;
  await _warmInteractionTargets(controller);
  await _settle(tester);

  await _runInteractionScript(tester, density: density, iterations: 1);
  controller.performanceCounters.reset();
  final rssBefore = ProcessInfo.currentRss;
  final maxRssBefore = ProcessInfo.maxRss;
  final frameKey = 'density_${density}_frames';
  final timelineKey = 'density_${density}_timeline';

  await binding.watchPerformance(
    () => binding.traceAction(
      () => _runInteractionScript(tester, density: density, iterations: 3),
      reportKey: timelineKey,
      streams: const <String>['Dart', 'Embedder', 'GC', 'Compiler'],
    ),
    reportKey: frameKey,
  );

  final rawFrameReport = binding.reportData?[frameKey];
  expect(rawFrameReport, isA<Map<String, dynamic>>());
  final frameReport = Map<String, dynamic>.from(
    rawFrameReport! as Map<String, dynamic>,
  );
  DashboardProfileReport.addRequiredPercentiles(frameReport);
  frameReport.addAll(<String, dynamic>{
    'fixture_entry_count': density,
    'rss_before_bytes': rssBefore,
    'rss_after_bytes': ProcessInfo.currentRss,
    'max_rss_before_bytes': maxRssBefore,
    'max_rss_after_bytes': ProcessInfo.maxRss,
    'performance_counters': _counterReport(controller),
    'logbox_phases': _logPhaseReport(controller),
    'cache_estimated_bytes': controller.parentBundleRegistry.estimatedBytes,
    'cache_estimated_weight': controller.parentBundleRegistry.estimatedWeight,
    'cache_evictions': controller.parentBundleRegistry.evictionCount,
    'background_max_concurrent': controller.backgroundWork.maxConcurrentCount,
    'stale_rail_callbacks_rejected': controller.staleRailCallbacksRejected,
    'verbose_flow_enabled': false,
  });
  binding.reportData![frameKey] = frameReport;

  expect(controller.query.exactWatchStartCount, 0);
  expect(controller.backgroundWork.maxConcurrentCount, lessThanOrEqualTo(1));
  expect(
    controller.presentationStore.activeSnapshot?.queryKey,
    controller.presentationStore.visibleTarget?.expectedVisibleQueryKey,
  );

  await tester.pumpWidget(const SizedBox.shrink());
  await _settle(tester);
  return frameReport;
}

Future<void> _warmInteractionTargets(DashboardCoreController controller) async {
  final currentScope = controller.query.state.scope;
  final currentParent = controller.rail.state.parentScope;
  if (currentParent is! MonthScope) {
    throw StateError('Dashboard profile harness expects a month parent.');
  }
  final months = <YearMonth>{
    currentParent.value.previous(),
    currentParent.value,
    currentParent.value.next(),
  };
  for (final month in months) {
    await controller.summaryMetrics.prepareParentDisplayBundle(
      parentScope: currentScope.copyWith(timeScope: MonthScope(month)),
      childPeriod: TimeChildPeriod.day,
      source: 'profileWarmup',
      pinCurrent: month == currentParent.value,
    );
  }
  await controller.summaryMetrics.prepareParentDisplayBundle(
    parentScope: currentScope.copyWith(direction: LedgerDirection.expense),
    childPeriod: TimeChildPeriod.day,
    source: 'profileWarmupOppositeDirection',
  );
}

Future<void> _runInteractionScript(
  WidgetTester tester, {
  required int density,
  required int iterations,
}) async {
  for (var iteration = 0; iteration < iterations; iteration += 1) {
    await _timelineStep('log_scroll', density, iteration, () async {
      final log = find.byKey(const ValueKey('dashboard-logbox-scroll-view'));
      if (log.evaluate().isEmpty) return;
      await tester.fling(log, const Offset(0, -420), 1800);
      await _settle(tester);
      await tester.fling(log, const Offset(0, 420), 1800);
      await _settle(tester);
    });
    await _timelineStep('direction_toggle', density, iteration, () async {
      await tester.tap(find.byKey(const ValueKey('fluvi-expense-button')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('fluvi-income-button')));
      await _settle(tester);
    });
    await _timelineStep('summary_open_rail', density, iteration, () async {
      await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
      await _settle(tester);
    });
    await _timelineStep('child_rail_fling', density, iteration, () async {
      final rail = find.byKey(const ValueKey('dashboard-time-rail'));
      await tester.fling(rail, const Offset(-360, 0), 2200);
      await _settle(tester);
      await tester.fling(rail, const Offset(360, 0), 2200);
      await _settle(tester);
    });
    await _timelineStep('parent_summary_fling', density, iteration, () async {
      final summary = find.byKey(
        const ValueKey('dashboard-summary-shell-transform'),
      );
      await tester.fling(summary, const Offset(-160, 0), 1200);
      await _settle(tester);
      await tester.fling(summary, const Offset(160, 0), 1200);
      await _settle(tester);
    });
    await _timelineStep('summary_close_rail', density, iteration, () async {
      await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));
      await _settle(tester);
    });
  }
}

Future<void> _timelineStep(
  String name,
  int density,
  int iteration,
  Future<void> Function() action,
) async {
  final task = developer.TimelineTask()
    ..start(
      name,
      arguments: <String, Object?>{
        'fixtureEntryCount': density,
        'iteration': iteration,
      },
    );
  try {
    await action();
  } finally {
    task.finish();
  }
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle(
  const Duration(milliseconds: 100),
  EnginePhase.sendSemanticsUpdate,
  const Duration(seconds: 5),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}

Map<String, int> _counterReport(DashboardCoreController controller) => {
  for (final entry in controller.performanceCounters.snapshot().entries)
    entry.key.name: entry.value,
};

Map<String, Object?> _logPhaseReport(DashboardCoreController controller) => {
  for (final phase in DashboardLogPerformancePhase.values)
    phase.name: <String, int>{
      'count': controller.logPerformanceDiagnostics.countFor(phase),
      'total_micros': controller.logPerformanceDiagnostics.totalMicrosFor(
        phase,
      ),
    },
};
