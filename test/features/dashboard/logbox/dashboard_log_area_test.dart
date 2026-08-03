import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_committed_query_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_area_state.dart';
import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/logbox/presentation/dashboard_log_area.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/scope_summary_metrics.dart';
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
      totalMinor: 901489,
      entryCount: 2,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
    ),
  );
  final state = DashboardLogData(
    snapshot: snapshot,
    groups: [
      DashboardDayLogGroup(
        localDate: const LocalDate(year: 2026, month: 3, day: 13),
        rows: const [
          DashboardLedgerEntry(
            id: 'entry-1',
            partnerId: 'partner-1',
            partnerDisplayName: 'Kávézó',
            categoryId: 'category-1',
            categoryDisplayName: 'Étkezés',
            categoryColorId: 'color_01',
            categoryIconId: 'food',
            direction: 'expense',
            amountMinor: 400000,
            bookedLocalEpochDay: 20525,
            bookedLocalTimeMinutes: 720,
          ),
          DashboardLedgerEntry(
            id: 'entry-2',
            partnerId: 'partner-2',
            categoryId: 'category-2',
            categoryDisplayName: 'Közlekedés',
            categoryColorId: 'missing-color',
            categoryIconId: 'missing-icon',
            direction: 'expense',
            amountMinor: 501489,
            bookedLocalEpochDay: 20525,
            bookedLocalTimeMinutes: 600,
            note: 'Villamos',
          ),
        ],
      ),
    ],
    nextCursor: null,
    isLoadingNextPage: false,
    isStale: false,
    cacheHit: true,
  );

  testWidgets('renders one joined day surface with category rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            height: 420,
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

    expect(
      find.byKey(const ValueKey('dashboard-logbox-entry-count')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dashboard-logbox-scroll-clearance')),
      findsOneWidget,
    );
    expect(find.text('2026. március 13.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-log-day-2026-03-13')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-log-row-entry-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-log-row-entry-2')),
      findsOneWidget,
    );
    expect(find.text('Kávézó'), findsOneWidget);
    expect(find.text('Étkezés'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('Villamos'), findsOneWidget);
    expect(find.text('Közlekedés'), findsOneWidget);
    expect(find.text('-4000,00 Ft'), findsOneWidget);
    expect(find.text('-5014,89 Ft'), findsOneWidget);
  });

  testWidgets('renders an explicit empty state rather than old query rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardLogArea(
            state: DashboardLogEmpty(snapshot: snapshot, cacheHit: false),
            onLoadNextPage: () {},
            onRetry: () {},
            onEntryTap: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-logbox-empty')),
      findsOneWidget,
    );
    expect(find.text('Nincs tranzakció ebben az időszakban.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-log-row-entry-1')),
      findsNothing,
    );
  });

  testWidgets('builds only the visible rows of a dense day group lazily', (
    tester,
  ) async {
    final denseRows = List<DashboardLedgerEntry>.generate(
      100,
      (index) => DashboardLedgerEntry(
        id: 'row-$index',
        partnerId: '',
        categoryId: 'category-1',
        categoryDisplayName: 'Étkezés',
        categoryColorId: 'color_01',
        categoryIconId: 'food',
        direction: 'expense',
        amountMinor: 10000 + index,
        bookedLocalEpochDay: 20525,
        bookedLocalTimeMinutes: 720,
        note: 'Sűrű nap $index',
      ),
    );
    final denseState = DashboardLogData(
      snapshot: snapshot,
      groups: [
        DashboardDayLogGroup(
          localDate: const LocalDate(year: 2026, month: 3, day: 13),
          rows: denseRows,
        ),
      ],
      nextCursor: null,
      isLoadingNextPage: false,
      isStale: false,
      cacheHit: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            height: 250,
            child: DashboardLogArea(
              state: denseState,
              onLoadNextPage: () {},
              onRetry: () {},
              onEntryTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-log-row-row-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-log-row-row-99')),
      findsNothing,
    );
  });

  testWidgets('does not request another page while rendering a preview', (
    tester,
  ) async {
    final previewSnapshot = DashboardPreviewQuerySnapshot(
      queryContext: scope,
      summaryMetrics: ScopeSummaryMetrics(
        scope: scope,
        canonicalQueryKey: scope.key.value,
        coreRevision: 12,
        totalMinor: 10000,
        entryCount: 100,
        source: SummaryMetricsSource.childPreviewIndex,
        isLoading: false,
        isStale: false,
        hasError: false,
      ),
    );
    final previewRows = List<DashboardLedgerEntry>.generate(
      100,
      (index) => DashboardLedgerEntry(
        id: 'preview-row-$index',
        partnerId: '',
        categoryId: 'category-1',
        categoryDisplayName: 'Étkezés',
        categoryColorId: 'color_01',
        categoryIconId: 'food',
        direction: 'expense',
        amountMinor: 10000,
        bookedLocalEpochDay: 20525,
        bookedLocalTimeMinutes: 720,
      ),
    );
    final previewState = DashboardLogData(
      snapshot: previewSnapshot,
      groups: [
        DashboardDayLogGroup(
          localDate: const LocalDate(year: 2026, month: 3, day: 13),
          rows: previewRows,
        ),
      ],
      nextCursor: const DashboardDayGroupPageCursor(
        beforeLocalDateExclusive: LocalDate(year: 2026, month: 3, day: 12),
      ),
      isLoadingNextPage: false,
      isStale: false,
      cacheHit: true,
    );
    var pageRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            height: 250,
            child: DashboardLogArea(
              state: previewState,
              onLoadNextPage: () => pageRequests += 1,
              onRetry: () {},
              onEntryTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
      const Offset(0, -10000),
    );
    await tester.pump();

    expect(pageRequests, 0);
  });
}
