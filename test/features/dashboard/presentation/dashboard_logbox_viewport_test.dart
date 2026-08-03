import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_presentation_adapter.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_view_models.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_visible_presentation_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/scope_summary_metrics.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_metrics_presentation.dart';

void main() {
  testWidgets('viewport State and Scrollable identity survive snapshot swaps', (
    tester,
  ) async {
    final firstScope = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    final secondScope = firstScope.copyWith(
      timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
    );
    final store = DashboardPresentationStore();
    final adapter = DashboardLogPresentationAdapter(store: store);
    addTearDown(adapter.dispose);
    addTearDown(store.dispose);
    store.publish(
      DashboardPresentationSnapshot(
        queryKey: firstScope.key,
        generation: 1,
        scope: firstScope,
        coreRevision: 1,
        totalMinor: 100,
        entryCount: 1,
        entries: const [
          DashboardLedgerEntry(
            id: 'first',
            partnerId: 'p',
            categoryId: 'c',
            direction: 'expense',
            amountMinor: 100,
            bookedLocalEpochDay: 20600,
            bookedLocalTimeMinutes: 60,
          ),
        ],
      ),
      activate: false,
    );
    store.publish(
      DashboardPresentationSnapshot(
        queryKey: secondScope.key,
        generation: 2,
        scope: secondScope,
        coreRevision: 1,
        totalMinor: 200,
        entryCount: 1,
        entries: const [
          DashboardLedgerEntry(
            id: 'second',
            partnerId: 'p',
            categoryId: 'c',
            direction: 'expense',
            amountMinor: 200,
            bookedLocalEpochDay: 20601,
            bookedLocalTimeMinutes: 60,
          ),
        ],
      ),
      activate: false,
    );
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: firstScope.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 1,
      ),
    );

    SummaryMetricsPresentation metrics() {
      final snapshot = store.activeSnapshot!;
      return SummaryMetricsPresentation.fromMetrics(
        ScopeSummaryMetrics(
          scope: snapshot.scope!,
          canonicalQueryKey: snapshot.queryKey.value,
          coreRevision: snapshot.coreRevision,
          totalMinor: snapshot.totalMinor,
          entryCount: snapshot.entryCount,
          source: SummaryMetricsSource.freshQuery,
          isLoading: false,
          isStale: false,
          hasError: false,
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 378,
          height: 700,
          child: DashboardLogBoxViewport(
            bounds: const DashboardBounds(
              left: 0,
              top: 28,
              width: 378,
              height: 28,
            ),
            presentation: adapter,
            metricsListenable: store,
            metricsPresentationBuilder: metrics,
            onLoadNextPage: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final viewportFinder = find.byType(DashboardLogBoxViewport);
    final viewportState = tester.state(viewportFinder);
    final scrollState = tester.state(find.byType(Scrollable));

    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: secondScope.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.expense,
        presentationEpoch: 2,
      ),
    );
    await tester.pump();

    expect(identical(tester.state(viewportFinder), viewportState), isTrue);
    expect(
      identical(tester.state(find.byType(Scrollable)), scrollState),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('dashboard-log-row-second')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dashboard-log-row-first')), findsNothing);
  });

  testWidgets('day-group rows are built lazily', (tester) async {
    final rows = List<DashboardLogRowViewModel>.generate(
      1000,
      (index) => DashboardLogRowViewModel(
        entryId: 'row-$index',
        displayName: 'Partner $index',
        categoryDisplayName: 'Category',
        formattedAmount: '-1,00 Ft',
        displayTime: '12:00',
        amountStyle: LogAmountStyle.expense,
        categoryColorId: 'fallback',
        categoryIconId: 'fallback',
        semanticLabel: 'Partner $index, -1,00 Ft, kiadás, Category',
      ),
    );
    final group = DashboardDayLogGroupViewModel(
      dateKey: '2026-07-01',
      dayLabel: '2026. július 1.',
      rows: rows,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 378,
          height: 700,
          child: CustomScrollView(
            slivers: [
              DashboardDayLogGroupSliver(
                model: group,
                showGroupGap: false,
                onEntryTap: null,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final builtRows = tester.widgetList<DashboardLogRow>(
      find.byType(DashboardLogRow),
    );
    expect(builtRows.length, greaterThan(0));
    expect(builtRows.length, lessThan(1000));
  });
}
