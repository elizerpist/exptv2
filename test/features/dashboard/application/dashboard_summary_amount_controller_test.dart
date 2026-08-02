import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_summary_amount_controller.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_summary_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/scope_summary_metrics.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _NoopLedgerRepository implements DashboardLedgerRepository {
  int watchCount = 0;

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
  }) async* {
    watchCount += 1;
    yield const DashboardLedgerResult(totalMinor: 0);
  }
}

class _StreamingLedgerRepository implements DashboardLedgerRepository {
  final controllers = <String, StreamController<DashboardLedgerResult>>{};

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
  }) =>
      (controllers[scope.key.value] ??=
              StreamController<DashboardLedgerResult>.broadcast())
          .stream;

  void emit(CurrentLedgerQueryScope scope, DashboardLedgerResult result) {
    controllers[scope.key.value]!.add(result);
  }

  Future<void> dispose() async {
    for (final controller in controllers.values) {
      await controller.close();
    }
  }
}

class _RecordingChildSummaryRepository
    implements DashboardChildSummaryRepository {
  final requests = <DashboardChildSummaryRequest>[];
  final pending = <Completer<DashboardTimeChildSummaryIndex>>[];

  @override
  Future<DashboardTimeChildSummaryIndex> readChildSummaries(
    DashboardChildSummaryRequest request,
  ) {
    requests.add(request);
    final result = Completer<DashboardTimeChildSummaryIndex>();
    pending.add(result);
    return result.future;
  }
}

class _ImmediateChildSummaryRepository
    implements DashboardChildSummaryRepository {
  final requests = <DashboardChildSummaryRequest>[];

  @override
  Future<DashboardTimeChildSummaryIndex> readChildSummaries(
    DashboardChildSummaryRequest request,
  ) async {
    requests.add(request);
    return DashboardTimeChildSummaryIndex(
      parentQueryKey: request.parentScope.key.value,
      direction: request.parentScope.direction,
      childPeriod: request.childPeriod,
      coreRevision: 1,
      isComplete: true,
      values: const <String, DashboardTimeChildSummary>{},
    );
  }
}

void main() {
  test(
    'child scope cache miss never relabels a retained mother result as child metrics',
    () async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 21),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      final parentScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
      );
      final childScope = parentScope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      final ledger = _StreamingLedgerRepository();
      final query = CurrentQueryController(
        repository: ledger,
        initialScope: parentScope,
      );
      final summaries = _RecordingChildSummaryRepository();
      final controller = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
      );
      addTearDown(controller.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);
      addTearDown(ledger.dispose);

      query.refresh();
      await Future<void>.value();
      ledger.emit(
        parentScope,
        DashboardLedgerResult(
          totalMinor: 60000000,
          entryCount: 94,
          coreRevision: 1,
          scopeKey: parentScope.key.value,
        ),
      );
      await Future<void>.value();

      navigation.setRailOpen(true);
      expect(summaries.requests, hasLength(1));

      query.setTimeScope(childScope.timeScope, reason: 'testChildCommit');

      expect(controller.presentation.scopeKey, childScope.key.value);
      expect(controller.presentation.isLoading, isTrue);
      expect(controller.presentation.formattedAmount, '— Ft');
      expect(controller.presentation.entryCount, isNull);
    },
  );

  test(
    'fresh closed scope prewarms its child index before the rail opens',
    () async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      final query = CurrentQueryController(
        repository: _NoopLedgerRepository(),
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
        ),
      );
      final summaries = _RecordingChildSummaryRepository();
      final controller = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
      );
      addTearDown(controller.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);

      expect(summaries.requests, isEmpty);

      query.refresh();
      await Future<void>.value();
      await Future<void>.value();

      expect(summaries.requests, hasLength(1));
      final request = summaries.requests.single;
      expect(
        request.parentScope.timeScope,
        const MonthScope(YearMonth(year: 2026, month: 3)),
      );
      expect(request.childPeriod, TimeChildPeriod.day);

      summaries.pending.single.complete(
        DashboardTimeChildSummaryIndex(
          parentQueryKey: request.parentScope.key.value,
          direction: LedgerDirection.expense,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 1,
          isComplete: true,
          values: const <String, DashboardTimeChildSummary>{},
        ),
      );
      await Future<void>.value();

      navigation.setRailOpen(true);

      expect(summaries.requests, hasLength(1));
      expect(controller.index, isNotNull);
      final zeroSummary = controller.index!.values['2026-03-14'];
      expect(zeroSummary, isNotNull);
      expect(zeroSummary?.totalMinor, 0);
      expect(zeroSummary?.entryCount, 0);
    },
  );

  test(
    'loaded month index changes the preview amount with no detailed query or extra index read',
    () async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearAnchor: 2026,
      );
      final ledger = _NoopLedgerRepository();
      final query = CurrentQueryController(
        repository: ledger,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 14)),
        ),
      );
      final summaries = _RecordingChildSummaryRepository();
      final controller = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
      );
      addTearDown(controller.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);

      expect(summaries.requests, hasLength(1));
      expect(
        summaries.requests.single.parentScope.timeScope,
        const MonthScope(YearMonth(year: 2026, month: 3)),
      );
      expect(summaries.requests.single.childPeriod, TimeChildPeriod.day);

      final day15Scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 15)),
      );
      summaries.pending.single.complete(
        DashboardTimeChildSummaryIndex(
          parentQueryKey: summaries.requests.single.parentScope.key.value,
          direction: LedgerDirection.expense,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 7,
          isComplete: true,
          values: <String, DashboardTimeChildSummary>{
            '2026-03-15': DashboardTimeChildSummary(
              childPeriodValue: '2026-03-15',
              childQueryKey: day15Scope.key.value,
              totalMinor: 1075384,
              entryCount: 4,
            ),
          },
        ),
      );
      await Future<void>.value();

      final readsBeforePreviews = summaries.requests.length;
      for (var index = 0; index < 100; index += 1) {
        navigation.previewChildLogicalIndex(index);
      }
      navigation.previewChildLogicalIndex(14);

      expect(controller.presentation.totalMinor, 1075384);
      expect(controller.presentation.entryCount, 4);
      expect(controller.presentation.scopeKey, day15Scope.key.value);
      expect(controller.presentation.isPreview, isTrue);
      expect(summaries.requests, hasLength(readsBeforePreviews));
      expect(ledger.watchCount, 0);

      navigation.settleChildLogicalIndex(14);

      expect(controller.presentation.isPreview, isFalse);
    },
  );

  test('stale index result cannot replace a newer parent request', () async {
    final navigation = DashboardTimeNavigationController(
      initialDate: DateTime(2026, 3, 14),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
      yearAnchor: 2026,
    );
    final query = CurrentQueryController(
      repository: _NoopLedgerRepository(),
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 14)),
      ),
    );
    final summaries = _RecordingChildSummaryRepository();
    final controller = DashboardSummaryMetricsController(
      navigation: navigation,
      query: query,
      childSummaryRepository: summaries,
    );
    addTearDown(controller.dispose);
    addTearDown(query.dispose);
    addTearDown(navigation.dispose);

    navigation.moveParentNext();
    expect(summaries.requests, hasLength(2));
    final newerRequest = summaries.requests.last;
    summaries.pending.first.complete(
      DashboardTimeChildSummaryIndex(
        parentQueryKey: summaries.requests.first.parentScope.key.value,
        direction: LedgerDirection.expense,
        childPeriod: TimeChildPeriod.day,
        coreRevision: 1,
        isComplete: true,
        values: const <String, DashboardTimeChildSummary>{},
      ),
    );
    await Future<void>.value();

    expect(controller.activeParentQueryKey, newerRequest.parentScope.key.value);
    expect(controller.index, isNull);
  });

  test(
    'child summary index cache is bounded and reloads an evicted parent',
    () async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearAnchor: 2026,
      );
      final query = CurrentQueryController(
        repository: _NoopLedgerRepository(),
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 14)),
        ),
      );
      final summaries = _ImmediateChildSummaryRepository();
      final controller = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
      );
      addTearDown(controller.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);

      await Future<void>.value();
      for (var index = 0; index < 31; index += 1) {
        navigation.moveParentNext();
        await Future<void>.value();
      }
      final requestsAfterForwardParents = summaries.requests.length;

      for (var index = 0; index < 31; index += 1) {
        navigation.moveParentPrevious();
        await Future<void>.value();
      }

      expect(requestsAfterForwardParents, 32);
      // The capacity is 30, so the original March and the following April
      // parent were evicted after the 32 distinct forward parents.
      expect(summaries.requests, hasLength(34));
      expect(
        summaries.requests.last.parentScope.timeScope,
        const MonthScope(YearMonth(year: 2026, month: 3)),
      );
    },
  );

  test(
    'open rail atomically selects the day 21 amount and count instead of the mother count',
    () async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 21),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      final parentScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
      );
      final childScope = parentScope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      final ledger = _StreamingLedgerRepository();
      final query = CurrentQueryController(
        repository: ledger,
        initialScope: parentScope,
      );
      final summaries = _RecordingChildSummaryRepository();
      final controller = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
      );
      addTearDown(controller.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);
      addTearDown(ledger.dispose);
      FluviDiagnosticLogger.clear();

      query.refresh();
      await Future<void>.value();
      ledger.emit(
        parentScope,
        DashboardLedgerResult(
          totalMinor: 60000000,
          entryCount: 94,
          coreRevision: 1,
          scopeKey: parentScope.key.value,
        ),
      );
      await Future<void>.value();
      final request = summaries.requests.single;
      summaries.pending.single.complete(
        DashboardTimeChildSummaryIndex(
          parentQueryKey: request.parentScope.key.value,
          direction: LedgerDirection.expense,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 1,
          isComplete: true,
          values: <String, DashboardTimeChildSummary>{
            '2026-03-21': DashboardTimeChildSummary(
              childPeriodValue: '2026-03-21',
              childQueryKey: childScope.key.value,
              totalMinor: 1075384,
              entryCount: 4,
            ),
          },
        ),
      );
      await Future<void>.value();

      navigation.setRailOpen(true);

      final metrics = controller.metrics!;
      expect(identical(controller.presentation.metrics, metrics), isTrue);
      expect(metrics.scope, childScope);
      expect(metrics.canonicalQueryKey, childScope.key.value);
      expect(metrics.totalMinor, 1075384);
      expect(metrics.entryCount, 4);
      expect(controller.presentation.formattedAmount, '10753,84 Ft');
      expect(controller.presentation.formattedEntryCount, '4');
      expect(controller.presentation.entryCount, 4);
      expect(controller.presentation.entryCount, isNot(94));
      final selected = FluviDiagnosticLogger.entries
          .where(
            (event) =>
                event.stage == 'D12' && event.queryKey == childScope.key.value,
          )
          .last;
      expect(selected.coreRevision, 1);
      expect(selected.totalMinor, 1075384);
      expect(selected.entryCount, 4);
      expect(selected.message, contains('source=childSettledIndex'));
      expect(selected.message, contains('displayedChild=21'));

      navigation.setRailOpen(false);
      expect(controller.metrics?.scope, parentScope);
      expect(controller.metrics?.totalMinor, 60000000);
      expect(controller.metrics?.entryCount, 94);
    },
  );

  test(
    'preview updates amount and count together without a detailed query and settle keeps the selected pair',
    () async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 21),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearAnchor: 2026,
      );
      final parentScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
      );
      final child21Scope = parentScope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      final ledger = _StreamingLedgerRepository();
      final query = CurrentQueryController(
        repository: ledger,
        initialScope: parentScope,
      );
      final summaries = _RecordingChildSummaryRepository();
      final controller = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
      );
      addTearDown(controller.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);
      addTearDown(ledger.dispose);

      final request = summaries.requests.single;
      summaries.pending.single.complete(
        DashboardTimeChildSummaryIndex(
          parentQueryKey: request.parentScope.key.value,
          direction: LedgerDirection.expense,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 1,
          isComplete: true,
          values: <String, DashboardTimeChildSummary>{
            '2026-03-20': DashboardTimeChildSummary(
              childPeriodValue: '2026-03-20',
              childQueryKey: parentScope
                  .copyWith(
                    timeScope: const DayScope(
                      LocalDate(year: 2026, month: 3, day: 20),
                    ),
                  )
                  .key
                  .value,
              totalMinor: 466229,
              entryCount: 2,
            ),
            '2026-03-21': DashboardTimeChildSummary(
              childPeriodValue: '2026-03-21',
              childQueryKey: child21Scope.key.value,
              totalMinor: 1075384,
              entryCount: 4,
            ),
          },
        ),
      );
      await Future<void>.value();

      final requestsBeforePreview = summaries.requests.length;
      navigation.previewChildLogicalIndex(19);
      expect(controller.metrics?.totalMinor, 466229);
      expect(controller.metrics?.entryCount, 2);
      navigation.previewChildLogicalIndex(20);
      expect(controller.metrics?.totalMinor, 1075384);
      expect(controller.metrics?.entryCount, 4);
      navigation.previewChildLogicalIndex(21);
      expect(controller.metrics?.totalMinor, 0);
      expect(controller.metrics?.entryCount, 0);
      expect(summaries.requests, hasLength(requestsBeforePreview));
      expect(ledger.controllers, isEmpty);

      navigation.previewChildLogicalIndex(20);
      final metricsBeforeSettle = controller.metrics;
      var presentationNotifications = 0;
      controller.addListener(() => presentationNotifications += 1);
      navigation.settleChildLogicalIndex(20);
      expect(identical(controller.metrics, metricsBeforeSettle), isFalse);
      expect(
        controller.metrics?.source,
        SummaryMetricsSource.childSettledIndex,
      );
      expect(presentationNotifications, 0);
      expect(controller.presentation.scopeKey, child21Scope.key.value);

      query.setTimeScope(child21Scope.timeScope, reason: 'testChildSettled');
      expect(ledger.controllers, hasLength(1));
    },
  );

  test(
    'maps every parent and displayed child plane to its canonical metrics scope',
    () {
      final cases =
          <({TimePlane plane, bool railOpen, LedgerTimeScope expected})>[
            (
              plane: TimePlane.sum,
              railOpen: false,
              expected: const AllTimeScope(),
            ),
            (
              plane: TimePlane.sum,
              railOpen: true,
              expected: const YearScope(2026),
            ),
            (
              plane: TimePlane.year,
              railOpen: false,
              expected: const YearScope(2026),
            ),
            (
              plane: TimePlane.year,
              railOpen: true,
              expected: const MonthScope(YearMonth(year: 2026, month: 3)),
            ),
            (
              plane: TimePlane.month,
              railOpen: false,
              expected: const MonthScope(YearMonth(year: 2026, month: 3)),
            ),
            (
              plane: TimePlane.month,
              railOpen: true,
              expected: const DayScope(
                LocalDate(year: 2026, month: 3, day: 21),
              ),
            ),
          ];

      for (final testCase in cases) {
        final navigation = DashboardTimeNavigationController(
          initialDate: DateTime(2026, 3, 21),
          initialPlane: testCase.plane,
          initialRailOpen: testCase.railOpen,
          yearAnchor: 2026,
        );
        final query = CurrentQueryController(
          repository: _NoopLedgerRepository(),
          initialScope: CurrentLedgerQueryScope(
            direction: LedgerDirection.expense,
            timeScope: const AllTimeScope(),
          ),
        );
        final controller = DashboardSummaryMetricsController(
          navigation: navigation,
          query: query,
        );

        expect(
          controller.metrics?.scope.timeScope,
          testCase.expected,
          reason: 'plane=${testCase.plane} railOpen=${testCase.railOpen}',
        );

        controller.dispose();
        query.dispose();
        navigation.dispose();
      }
    },
  );

  test(
    'direction and facet changes never reuse a child amount/count pair',
    () async {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 14),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearAnchor: 2026,
      );
      final childScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 14)),
        categoryIds: const <String>{'groceries'},
        partnerIds: const <String>{'market'},
        refinements: const <String, Object?>{'account': 'cash'},
      );
      final query = CurrentQueryController(
        repository: _NoopLedgerRepository(),
        initialScope: childScope,
      );
      final summaries = _RecordingChildSummaryRepository();
      final controller = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
      );
      addTearDown(controller.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);

      final expenseRequest = summaries.requests.single;
      summaries.pending.single.complete(
        DashboardTimeChildSummaryIndex(
          parentQueryKey: expenseRequest.parentScope.key.value,
          direction: LedgerDirection.expense,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 1,
          isComplete: true,
          values: <String, DashboardTimeChildSummary>{
            '2026-03-14': DashboardTimeChildSummary(
              childPeriodValue: '2026-03-14',
              childQueryKey: childScope.key.value,
              totalMinor: 1075384,
              entryCount: 4,
            ),
          },
        ),
      );
      await Future<void>.value();
      expect(controller.metrics?.totalMinor, 1075384);
      expect(controller.metrics?.entryCount, 4);

      query.setDirection(LedgerDirection.income);

      expect(controller.metrics?.totalMinor, isNull);
      expect(controller.metrics?.entryCount, isNull);
      expect(summaries.requests, hasLength(2));
      final incomeRequest = summaries.requests[1];
      expect(incomeRequest.parentScope.direction, LedgerDirection.income);
      expect(incomeRequest.parentScope.categoryIds, {'groceries'});
      expect(incomeRequest.parentScope.partnerIds, {'market'});
      expect(incomeRequest.parentScope.refinements, {'account': 'cash'});

      query.setFacets(
        categoryIds: const <String>{'transport'},
        partnerIds: const <String>{'taxi'},
        refinements: const <String, Object?>{'account': 'card'},
      );

      expect(controller.metrics?.totalMinor, isNull);
      expect(controller.metrics?.entryCount, isNull);
      expect(summaries.requests, hasLength(3));
      final refinedRequest = summaries.requests[2];
      expect(refinedRequest.parentScope.direction, LedgerDirection.income);
      expect(refinedRequest.parentScope.categoryIds, {'transport'});
      expect(refinedRequest.parentScope.partnerIds, {'taxi'});
      expect(refinedRequest.parentScope.refinements, {'account': 'card'});
    },
  );
}
