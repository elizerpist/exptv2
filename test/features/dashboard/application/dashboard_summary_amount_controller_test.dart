import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_summary_amount_controller.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_summary_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
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
      values: const <String, DashboardTimeChildSummary>{},
    );
  }
}

void main() {
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
      final controller = DashboardSummaryAmountController(
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
    final controller = DashboardSummaryAmountController(
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
      final controller = DashboardSummaryAmountController(
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
}
