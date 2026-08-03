import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/logbox/presentation/dashboard_log_area.dart';
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
    'keeps the LogBox count fixed while its transaction slivers scroll',
    (tester) async {
      final repository = _StreamingLedgerRepository();
      final controller = DashboardCoreController(queryRepository: repository);
      addTearDown(repository.dispose);
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
      );

      repository.emit(_scrollableLogBoxResult());
      await tester.pump();

      final count = find.byKey(const ValueKey('dashboard-logbox-entry-count'));
      final scrollHost = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final countTopBeforeScroll = tester.getTopLeft(count).dy;

      await tester.drag(scrollHost, const Offset(0, -80));
      await tester.pump();

      expect(tester.getTopLeft(count).dy, countTopBeforeScroll);
    },
  );

  testWidgets(
    'keeps the LogBox viewport widget identity across collapse frames',
    (tester) async {
      final repository = _StreamingLedgerRepository();
      final controller = DashboardCoreController(queryRepository: repository);
      addTearDown(repository.dispose);
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
      );

      final viewportFinder = find.byType(DashboardLogBoxViewport);
      final before = tester.element(viewportFinder).widget;
      controller.expansion.toggle();
      await tester.pump(const Duration(milliseconds: 40));
      final during = tester.element(viewportFinder).widget;
      await tester.pump(const Duration(milliseconds: 80));
      final after = tester.element(viewportFinder).widget;

      expect(during, same(before));
      expect(after, same(before));
    },
  );

  testWidgets(
    'aligns each LogBox day surface with the SummaryPill outer bounds',
    (tester) async {
      final repository = _StreamingLedgerRepository();
      final controller = DashboardCoreController(queryRepository: repository);
      addTearDown(repository.dispose);
      addTearDown(controller.dispose);

      await pumpDashboardSurface(
        tester,
        CoreDashboard(mode: DashboardModeSpec.balance, controller: controller),
      );

      repository.emit(_scrollableLogBoxResult());
      await tester.pump();

      final summaryShell = tester.getRect(
        find.byKey(const ValueKey('dashboard-summary-shell-transform')),
      );
      final daySurface = tester.getRect(
        find.byKey(const ValueKey('dashboard-log-row-entry-0')),
      );

      expect(daySurface.left, summaryShell.left);
      expect(daySurface.right, summaryShell.right);
    },
  );

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

DashboardLedgerResult _scrollableLogBoxResult() => DashboardLedgerResult(
  totalMinor: 250000,
  entryCount: 10,
  dayGroups: [
    DashboardLedgerDayGroup(
      bookedLocalEpochDay: 20525,
      entries: List<DashboardLedgerEntry>.generate(
        10,
        (index) => DashboardLedgerEntry(
          id: 'entry-$index',
          partnerId: 'partner-$index',
          partnerDisplayName: 'Tranzakció $index',
          categoryId: 'category-$index',
          categoryDisplayName: 'Kategória',
          categoryColorId: 'color_01',
          categoryIconId: 'food',
          direction: 'income',
          amountMinor: 25000,
          bookedLocalEpochDay: 20525,
          bookedLocalTimeMinutes: 720 - index,
        ),
      ),
    ),
  ],
);
