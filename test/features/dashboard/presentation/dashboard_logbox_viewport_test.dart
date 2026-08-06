import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  setUpAll(PreparedVectorAssetAtlas.instance.prepare);

  testWidgets('viewport State and Scrollable identity survive frame swaps', (
    tester,
  ) async {
    final store = DashboardVisibleFrameStore();
    final counters = DashboardPerformanceCounters();
    addTearDown(store.dispose);
    store.publish(_visible(rowId: 'first', epoch: 1));

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
            visibleFrames: store,
            onLoadNextPage: () {},
            performanceCounters: counters,
          ),
        ),
      ),
    );
    final viewportFinder = find.byType(DashboardLogBoxViewport);
    final viewportState = tester.state(viewportFinder);
    final scrollState = tester.state(find.byType(Scrollable));
    counters.reset();

    store.publish(_visible(rowId: 'second', epoch: 2));
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
    expect(
      counters.value(DashboardPerformanceMetric.logViewportBuild),
      0,
      reason: 'A frame swap must not rebuild the viewport shell.',
    );
    expect(counters.value(DashboardPerformanceMetric.logBoxBuild), 1);
  });

  testWidgets('day-group rows are built lazily', (tester) async {
    final rows = List<DashboardLogRowViewModel>.generate(
      1000,
      (index) => _row('row-$index'),
    );
    final group = DashboardDayLogGroupViewModel(
      dateKey: '2026-07-01',
      dayLabel: '2026. július 1.',
      rows: rows,
    );
    final counters = DashboardPerformanceCounters();
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    store.publish(_visibleWithGroups(<DashboardDayLogGroupViewModel>[group]));

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
            visibleFrames: store,
            onLoadNextPage: () {},
            performanceCounters: counters,
          ),
        ),
      ),
    );

    final builtRows = tester.widgetList<DashboardLogRow>(
      find.byType(DashboardLogRow),
    );
    expect(builtRows.length, inInclusiveRange(1, 999));
    expect(
      counters.value(DashboardPerformanceMetric.logRowBuild),
      lessThan(1000),
    );
  });

  testWidgets('many prepared day groups use one lazy flattened sliver', (
    tester,
  ) async {
    final groups = List<DashboardDayLogGroupViewModel>.generate(
      24,
      (index) => DashboardDayLogGroupViewModel(
        dateKey: '2026-07-${(index + 1).toString().padLeft(2, '0')}',
        dayLabel: '2026. július ${index + 1}.',
        rows: <DashboardLogRowViewModel>[_row('row-$index')],
      ),
    );
    final store = DashboardVisibleFrameStore();
    final counters = DashboardPerformanceCounters();
    addTearDown(store.dispose);
    store.publish(_visibleWithGroups(groups));

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 378,
          height: 420,
          child: DashboardLogBoxViewport(
            bounds: const DashboardBounds(
              left: 0,
              top: 28,
              width: 378,
              height: 28,
            ),
            visibleFrames: store,
            onLoadNextPage: () {},
            performanceCounters: counters,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-logbox-flat-sliver-list')),
      findsOneWidget,
    );
    expect(
      counters.value(DashboardPerformanceMetric.logRowBuild),
      lessThan(groups.length),
    );
    expect(store.value!.logBox.flatItems.length, groups.length * 3 - 1);
  });

  testWidgets(
    'metadata-only settle enables paging without remount or visual notify',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      store.publish(
        _visible(
          rowId: 'page',
          epoch: 1,
          rowCount: 40,
          nextCursor: const <String, Object?>{'entryId': 'page-39'},
          mode: DashboardVisibleMode.preview,
        ),
      );
      var pageRequests = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              onLoadNextPage: () => pageRequests += 1,
            ),
          ),
        ),
      );
      final viewportState = tester.state(find.byType(DashboardLogBoxViewport));
      expect(
        store.promoteCommitted(
          expectedKey: store.value!.queryKey,
          epoch: store.value!.presentationEpoch,
        ),
        isTrue,
      );

      await tester.drag(
        find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        const Offset(0, -1600),
      );
      await tester.pump();

      expect(pageRequests, greaterThan(0));
      expect(
        identical(
          tester.state(find.byType(DashboardLogBoxViewport)),
          viewportState,
        ),
        isTrue,
      );
    },
  );
}

DashboardVisibleFrame _visible({
  required String rowId,
  required int epoch,
  int rowCount = 1,
  Map<String, Object?>? nextCursor,
  DashboardVisibleMode mode = DashboardVisibleMode.committed,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: [
      DashboardDayLogGroupViewModel(
        dateKey: '2026-07-01',
        dayLabel: '2026. július 1.',
        rows: List<DashboardLogRowViewModel>.generate(
          rowCount,
          (index) => _row(rowCount == 1 ? rowId : '$rowId-$index'),
        ),
      ),
    ],
    entryCount: rowCount,
    nextCursor: nextCursor,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: epoch * 100,
    formattedAmount: '$epoch,00 Ft',
    entryCount: rowCount,
    formattedEntryCount: '$rowCount',
    logBox: logBox,
    presentationDigest: Object.hash(rowId, epoch),
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: '2026. július',
    navigationEpoch: epoch,
    presentationEpoch: epoch,
    frameGeneration: epoch,
    mode: mode,
  );
}

DashboardVisibleFrame _visibleWithGroups(
  List<DashboardDayLogGroupViewModel> groups,
) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const YearScope(2026),
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: groups,
    entryCount: groups.length,
    nextCursor: null,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: groups.length * 100,
    formattedAmount: '${groups.length},00 Ft',
    entryCount: groups.length,
    formattedEntryCount: '${groups.length}',
    logBox: logBox,
    presentationDigest: groups.length,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.year,
    railOpen: true,
    semanticIndex: 0,
    childLabel: '2026',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.preview,
  );
}

DashboardLogRowViewModel _row(String id) => DashboardLogRowViewModel(
  entryId: id,
  displayName: 'Partner $id',
  categoryDisplayName: 'Category',
  formattedAmount: '-1,00 Ft',
  displayTime: '12:00',
  amountStyle: LogAmountStyle.expense,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
  semanticLabel: 'Partner $id, -1,00 Ft, kiadás, Category',
);
