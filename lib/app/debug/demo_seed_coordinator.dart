import 'package:flutter/foundation.dart';

import '../../core/demo_data/demo_data_bridge.dart';
import '../../core/demo_data/demo_seed_report.dart';
import '../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../features/dashboard/time_navigation/domain/year_month.dart';
import '../../features/dashboard/runtime/application/dashboard_data_runtime.dart';

/// App-level debug orchestration for the native deterministic demo dataset.
///
/// The coordinator owns the sequence, while the bridge owns only transport and
/// the time-navigation controller owns the dashboard navigation state.
class DemoSeedCoordinator {
  const DemoSeedCoordinator({
    required this.bridge,
    required this.timeNavigation,
    required this.preparedYearWindow,
  });

  final MethodChannelDemoDataBridge bridge;
  final DashboardNavigationController timeNavigation;
  final DashboardPreparedYearWindow preparedYearWindow;

  Future<DemoSeedReport> seedAndNavigate({bool forceReset = false}) async {
    assert(() {
      debugPrint(
        '[DashboardQuery] event=D0 demoSeedStarted '
        'time=${DateTime.now().microsecondsSinceEpoch}',
      );
      return true;
    }());
    final report = await bridge.seedDemoDataset(
      forceReset: forceReset,
      financialLimitYearWindowStart: preparedYearWindow.start,
      financialLimitYearWindowEndInclusive: preparedYearWindow.endInclusive,
    );
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
    final highDensity2025 = report.monthlyReports
        .where((month) => month.year == 2025)
        .toList(growable: false);
    if (highDensity2025.isNotEmpty) {
      final entryCount = highDensity2025.fold<int>(
        0,
        (total, month) => total + month.entryCount,
      );
      final incomeMinor = highDensity2025.fold<int>(
        0,
        (total, month) => total + month.incomeTotalMinor,
      );
      final expenseMinor = highDensity2025.fold<int>(
        0,
        (total, month) => total + month.expenseTotalMinor,
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'DEMO_SEED_2025_SUMMARY',
          entryCount: entryCount,
          totalMinor: incomeMinor,
          message:
              'months=${highDensity2025.length} '
              'incomeMinor=$incomeMinor '
              'expenseMinor=$expenseMinor',
        ),
      );
    }
    timeNavigation.navigateToMonth(const YearMonth(year: 2026, month: 7));
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
