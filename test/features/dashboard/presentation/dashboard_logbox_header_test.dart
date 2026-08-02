import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_header.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/scope_summary_metrics.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_metrics_presentation.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_navigation_presentation.dart';

import '../../../support/test_pump.dart';

class _StreamingLedgerRepository implements DashboardLedgerRepository {
  final StreamController<DashboardLedgerResult> _events =
      StreamController<DashboardLedgerResult>.broadcast();
  int watchCount = 0;

  void emit(DashboardLedgerResult result) => _events.add(result);

  Future<void> dispose() => _events.close();

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => const DashboardLedgerResult(totalMinor: 0);

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    watchCount += 1;
    return _events.stream;
  }
}

SummaryMetricsPresentation _dayMetrics({
  required int totalMinor,
  required int entryCount,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
  );
  return SummaryMetricsPresentation.fromMetrics(
    ScopeSummaryMetrics(
      scope: scope,
      canonicalQueryKey: scope.key.value,
      coreRevision: 1,
      totalMinor: totalMinor,
      entryCount: entryCount,
      source: SummaryMetricsSource.childPreviewIndex,
      isLoading: false,
      isStale: false,
      hasError: false,
    ),
  );
}

void main() {
  testWidgets(
    'renders the immediate query transaction count directly below the handler',
    (tester) async {
      final repository = _StreamingLedgerRepository();
      final controller = DashboardCoreController(queryRepository: repository);
      addTearDown(repository.dispose);
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
      );

      expect(
        find.byKey(const ValueKey('dashboard-logbox-header')),
        findsOneWidget,
      );
      expect(find.text('— tranzakció listázva'), findsOneWidget);

      repository.emit(
        const DashboardLedgerResult(totalMinor: 250000, entryCount: 4),
      );
      await tester.pump();

      expect(find.text('4 tranzakció listázva'), findsOneWidget);
      expect(repository.watchCount, 1);

      final handler = tester.getRect(
        find.byKey(const ValueKey('dashboard-collapse-handle')),
      );
      final logBoxHeader = tester.getRect(
        find.byKey(const ValueKey('dashboard-logbox-header')),
      );
      expect(logBoxHeader.top, handler.bottom);
    },
  );

  testWidgets(
    'emits one debug record for a changed LogBox count presentation',
    (tester) async {
      final repository = _StreamingLedgerRepository();
      final controller = DashboardCoreController(queryRepository: repository);
      addTearDown(repository.dispose);
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
      );
      FluviDiagnosticLogger.clear();

      const result = DashboardLedgerResult(totalMinor: 250000, entryCount: 4);
      repository.emit(result);
      await tester.pump();

      final firstEmission = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'D11')
          .toList();
      expect(firstEmission, hasLength(1));
      expect(firstEmission.single.entryCount, 4);
      expect(
        firstEmission.single.message,
        contains('source=summaryMetricsPresentation'),
      );

      repository.emit(result);
      await tester.pump();

      expect(
        FluviDiagnosticLogger.entries.where((event) => event.stage == 'D11'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'SummaryPill amount and LogBox count render one child metrics snapshot',
    (tester) async {
      final metrics = ValueNotifier(
        _dayMetrics(totalMinor: 1075384, entryCount: 4),
      );
      addTearDown(metrics.dispose);
      final navigation = SummaryNavigationPresentation(
        plane: TimePlane.month,
        planeTitle: 'Havi',
        subtitle: '2026. március 21.',
        isRailOpen: true,
        revision: 1,
        changeReason: SummaryContentChangeReason.initial,
        direction: SummaryTransitionDirection.forward,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DashboardSummaryPill(
                  bounds: const DashboardBounds(
                    left: 0,
                    top: 0,
                    width: 378,
                    height: 59,
                  ),
                  navigationPresentation: navigation,
                  metricsPresentation: metrics.value,
                  metricsListenable: metrics,
                  metricsPresentationBuilder: () => metrics.value,
                ),
                DashboardLogBoxHeader(
                  bounds: const DashboardBounds(
                    left: 0,
                    top: 0,
                    width: 378,
                    height: 32,
                  ),
                  metricsListenable: metrics,
                  metricsPresentationBuilder: () => metrics.value,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('10753,84 Ft'), findsOneWidget);
      expect(find.text('4 tranzakció listázva'), findsOneWidget);

      metrics.value = _dayMetrics(totalMinor: 0, entryCount: 0);
      await tester.pump();

      expect(find.text('0 Ft'), findsOneWidget);
      expect(find.text('0 tranzakció listázva'), findsOneWidget);
    },
  );
}
