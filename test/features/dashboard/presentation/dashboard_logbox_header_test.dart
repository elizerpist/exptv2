import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';

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

void main() {
  testWidgets('renders the committed LogBox count directly below the handler', (
    tester,
  ) async {
    final repository = _StreamingLedgerRepository();
    final controller = DashboardCoreController(queryRepository: repository);
    addTearDown(repository.dispose);
    addTearDown(controller.dispose);

    await pumpDashboardSurface(
      tester,
      CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
    );

    expect(
      find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
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
    final logBoxArea = tester.getRect(
      find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
    );
    expect(logBoxArea.top, handler.bottom);
  });

  testWidgets(
    'emits one deduplicated debug record for a committed LogBox bind',
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
          .where((event) => event.stage == 'LOG_FIRST_PAGE_BOUND')
          .toList();
      expect(firstEmission, hasLength(1));
      expect(firstEmission.single.entryCount, 4);
      expect(firstEmission.single.message, contains('cacheHit='));

      repository.emit(result);
      await tester.pump();

      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'LOG_FIRST_PAGE_BOUND',
        ),
        hasLength(1),
      );
    },
  );
}
