import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_committed_query_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_area_state.dart';
import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/logbox/presentation/dashboard_log_area.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
  );
  final snapshot = DashboardCommittedQuerySnapshot.fromResult(
    scope: scope,
    result: DashboardLedgerResult(
      totalMinor: 1,
      entryCount: 1,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
    ),
  );

  testWidgets('keeps 100, 500 and 1000-row first viewports lazy', (
    tester,
  ) async {
    for (final rowCount in [100, 500, 1000]) {
      final entries = List<DashboardLedgerEntry>.generate(
        rowCount,
        (index) => DashboardLedgerEntry(
          id: 'budget-$rowCount-$index',
          partnerId: 'partner-1',
          categoryId: 'category-1',
          categoryDisplayName: 'Étkezés',
          categoryColorId: 'color_01',
          categoryIconId: 'food',
          direction: 'expense',
          amountMinor: 10000,
          bookedLocalEpochDay: 20525,
          bookedLocalTimeMinutes: 720,
          note: 'Teszt sor $index',
        ),
      );
      final projectionStopwatch = Stopwatch()..start();
      final state = DashboardLogData(
        snapshot: snapshot,
        groups: [
          DashboardDayLogGroup(
            localDate: const LocalDate(year: 2026, month: 3, day: 13),
            rows: entries,
          ),
        ],
        nextCursor: null,
        isLoadingNextPage: false,
        isStale: false,
        cacheHit: true,
      );
      projectionStopwatch.stop();
      final viewportStopwatch = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: 260,
              child: DashboardLogArea(
                state: state,
                onLoadNextPage: () {},
                onRetry: () {},
                onEntryTap: (_) {},
              ),
            ),
          ),
        ),
      );
      viewportStopwatch.stop();

      expect(
        find.byKey(ValueKey('dashboard-log-row-budget-$rowCount-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('dashboard-log-row-budget-$rowCount-${rowCount - 1}'),
        ),
        findsNothing,
      );
      // Deterministic test-renderer evidence, not a device raster benchmark.
      // The values are captured in the test output and release notes.
      // ignore: avoid_print
      print(
        'LOGBOX_RENDER_BUDGET rows=$rowCount '
        'projectionMs=${projectionStopwatch.elapsedMilliseconds} '
        'firstViewportPumpMs=${viewportStopwatch.elapsedMilliseconds}',
      );
    }
  });
}
