import 'package:flutter/foundation.dart';

import '../../core/demo_data/demo_data_bridge.dart';
import '../../core/demo_data/demo_seed_report.dart';
import '../../features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../features/dashboard/time_navigation/domain/year_month.dart';

/// App-level debug orchestration for the native deterministic demo dataset.
///
/// The coordinator owns the sequence, while the bridge owns only transport and
/// the time-navigation controller owns the dashboard navigation state.
class DemoSeedCoordinator {
  const DemoSeedCoordinator({required this.bridge, this.timeNavigation});

  final MethodChannelDemoDataBridge bridge;
  final DashboardTimeNavigationController? timeNavigation;

  /// Completes the native write before any dashboard controller is allowed to
  /// create its initial scope. App bootstrap uses this form so an August
  /// startup read cannot race the deterministic July demo dataset.
  Future<DemoSeedReport> seed({bool forceReset = false}) async {
    assert(() {
      debugPrint(
        '[DashboardQuery] event=D0 demoSeedStarted '
        'time=${DateTime.now().microsecondsSinceEpoch}',
      );
      return true;
    }());
    final report = await bridge.seedDemoDataset(forceReset: forceReset);
    assert(() {
      debugPrint(
        '[DashboardQuery] event=D1 demoSeedCommitted '
        'time=${DateTime.now().microsecondsSinceEpoch} '
        'entries=${report.createdEntryCount} '
        'alreadySeeded=${report.alreadySeeded} '
        'earliest=${report.earliestEntryAtUtcMs} '
        'latest=${report.latestEntryAtUtcMs}',
      );
      return true;
    }());
    return report;
  }

  Future<DemoSeedReport> seedAndNavigate({bool forceReset = false}) async {
    final report = await seed(forceReset: forceReset);
    final navigation = timeNavigation;
    if (navigation == null) {
      throw StateError('seedAndNavigate requires a time-navigation owner.');
    }
    navigation.navigateToMonth(const YearMonth(year: 2026, month: 7));
    assert(() {
      debugPrint(
        '[FluviDemoSeed] version=${report.seedVersion} '
        'entries=${report.createdEntryCount} '
        'alreadySeeded=${report.alreadySeeded}',
      );
      return true;
    }());
    return report;
  }
}
