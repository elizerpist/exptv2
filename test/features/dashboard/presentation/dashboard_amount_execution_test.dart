import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/scope_summary_metrics.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_metrics_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';

void main() {
  testWidgets('counts only an amount animation that actually starts', (
    tester,
  ) async {
    final counters = DashboardPerformanceCounters();
    final amount = ValueNotifier(_amount(100));
    addTearDown(amount.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardSummaryPill(
          bounds: const DashboardBounds(
            left: 0,
            top: 0,
            width: 378,
            height: 59,
          ),
          navigationPresentation: const SummaryNavigationPresentation(
            plane: TimePlane.month,
            planeTitle: 'Havi',
            subtitle: 'Összesen',
            isRailOpen: false,
            revision: 1,
            changeReason: SummaryContentChangeReason.initial,
            direction: SummaryTransitionDirection.forward,
          ),
          metricsListenable: amount,
          metricsPresentationBuilder: () => amount.value,
          performanceCounters: counters,
        ),
      ),
    );

    amount.value = _amount(200);
    await tester.pump();
    expect(
      counters.value(DashboardPerformanceMetric.amountAnimationStarted),
      1,
    );

    amount.value = _amount(200, revision: 2);
    await tester.pump();
    expect(
      counters.value(DashboardPerformanceMetric.amountAnimationStarted),
      1,
    );
  });
}

SummaryMetricsPresentation _amount(int totalMinor, {int revision = 1}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.income,
    timeScope: AllTimeScope(),
  );
  return SummaryMetricsPresentation.fromMetrics(
    ScopeSummaryMetrics(
      scope: scope,
      canonicalQueryKey: scope.key.value,
      coreRevision: revision,
      totalMinor: totalMinor,
      entryCount: 1,
      source: SummaryMetricsSource.freshQuery,
      isLoading: false,
      isStale: false,
      hasError: false,
    ),
  );
}
