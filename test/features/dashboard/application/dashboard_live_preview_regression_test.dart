import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_summary_amount_controller.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_summary_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _StreamingLedgerRepository implements DashboardLedgerRepository {
  final Map<String, StreamController<DashboardLedgerResult>> _streams =
      <String, StreamController<DashboardLedgerResult>>{};

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
  }) {
    watchCount += 1;
    return (_streams[scope.key.value] ??=
            StreamController<DashboardLedgerResult>.broadcast())
        .stream;
  }

  void emit(CurrentLedgerQueryScope scope, DashboardLedgerResult result) {
    _streams[scope.key.value]!.add(result);
  }

  Future<void> dispose() async {
    for (final stream in _streams.values) {
      await stream.close();
    }
  }
}

class _ImmediateChildSummaryRepository
    implements DashboardChildSummaryRepository {
  DashboardTimeChildSummaryIndex? index;

  @override
  Future<DashboardTimeChildSummaryIndex> readChildSummaries(
    DashboardChildSummaryRequest request,
  ) async =>
      index ??
      DashboardTimeChildSummaryIndex(
        parentQueryKey: request.parentScope.key.value,
        direction: request.parentScope.direction,
        childPeriod: request.childPeriod,
        coreRevision: 1,
        isComplete: true,
        values: const <String, DashboardTimeChildSummary>{},
      );
}

class _StaticChildPreviewRepository implements DashboardChildPreviewRepository {
  _StaticChildPreviewRepository(this.bundle);

  final DashboardChildPreviewBundle bundle;
  int readCount = 0;

  @override
  Future<DashboardChildPreviewBundle> readChildPreviewBundle(
    DashboardChildPreviewBundleRequest request,
  ) async {
    readCount += 1;
    return bundle;
  }
}

void main() {
  test(
    'first mother to child open publishes the complete child preview rows',
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
      final summaries = _ImmediateChildSummaryRepository();
      final previewRepository = _StaticChildPreviewRepository(
        DashboardChildPreviewBundle(
          parentScope: parentScope,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 1,
          childrenByQueryKey: <LedgerQueryKey, DashboardChildPreview>{
            childScope.key: DashboardChildPreview(
              childPeriodValue: '2026-03-21',
              scope: childScope,
              result: DashboardLedgerResult(
                totalMinor: 68900000,
                entryCount: 1,
                coreRevision: 1,
                scopeKey: childScope.key.value,
                timeScopeKey: 'day:2026-03-21',
                direction: 'expense',
                entries: [
                  _entry(
                    id: 'child-row',
                    date: const LocalDate(year: 2026, month: 3, day: 21),
                  ),
                ],
              ),
            ),
          },
        ),
      );
      summaries.index = DashboardTimeChildSummaryIndex(
        parentQueryKey: parentScope.key.value,
        direction: LedgerDirection.expense,
        childPeriod: TimeChildPeriod.day,
        coreRevision: 1,
        isComplete: true,
        values: <String, DashboardTimeChildSummary>{
          '2026-03-21': DashboardTimeChildSummary(
            childPeriodValue: '2026-03-21',
            childQueryKey: childScope.key.value,
            totalMinor: 68900000,
            entryCount: 1,
          ),
        },
      );
      final store = DashboardPresentationStore();
      final query = CurrentQueryController(
        repository: ledger,
        initialScope: parentScope,
        presentationStore: store,
      );
      final summary = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
        childPreviewRepository: previewRepository,
        presentationStore: store,
      );
      addTearDown(summary.dispose);
      addTearDown(query.dispose);
      addTearDown(store.dispose);
      addTearDown(navigation.dispose);
      addTearDown(ledger.dispose);

      query.refresh();
      await Future<void>.value();
      ledger.emit(
        parentScope,
        DashboardLedgerResult(
          totalMinor: 68900000,
          entryCount: 1,
          coreRevision: 1,
          scopeKey: parentScope.key.value,
          entries: [
            _entry(
              id: 'child-row',
              date: const LocalDate(year: 2026, month: 3, day: 21),
            ),
          ],
        ),
      );
      await Future<void>.value();
      expect(previewRepository.readCount, 1);
      final watchCountBeforeOpen = ledger.watchCount;
      navigation.setRailOpen(true);

      final immediateChildSnapshot = store.activeSnapshot;
      expect(immediateChildSnapshot?.queryKey, childScope.key);
      expect(immediateChildSnapshot?.entries.map((entry) => entry.id), [
        'child-row',
      ]);
      expect(ledger.watchCount, watchCountBeforeOpen);

      await Future<void>.value();

      final childSnapshot = store.activeSnapshot;
      expect(childSnapshot?.queryKey, childScope.key);
      expect(childSnapshot?.totalMinor, 68900000);
      expect(childSnapshot?.entryCount, 1);
      expect(childSnapshot?.isLoading, isFalse);
      expect(childSnapshot?.isStale, isFalse);
      expect(childSnapshot?.entries.map((entry) => entry.id), ['child-row']);
      expect(ledger.watchCount, watchCountBeforeOpen);
      expect(summary.firstOpenCacheHitCount, 1);
      expect(summary.firstOpenCacheMissCount, 0);
    },
  );

  test(
    'each distinct preview crossing publishes its complete child snapshot before settle',
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
      final ledger = _StreamingLedgerRepository();
      final summaries = _ImmediateChildSummaryRepository();
      final days = <String, DashboardTimeChildSummary>{};
      final previews = <LedgerQueryKey, DashboardChildPreview>{};
      for (var day = 18; day <= 21; day += 1) {
        final childScope = parentScope.copyWith(
          timeScope: DayScope(LocalDate(year: 2026, month: 3, day: day)),
        );
        days['2026-03-${day.toString().padLeft(2, '0')}'] =
            DashboardTimeChildSummary(
              childPeriodValue: '2026-03-${day.toString().padLeft(2, '0')}',
              childQueryKey: childScope.key.value,
              totalMinor: day * 100,
              entryCount: day == 20 ? 0 : 1,
            );
        previews[childScope.key] = DashboardChildPreview(
          childPeriodValue: '2026-03-${day.toString().padLeft(2, '0')}',
          scope: childScope,
          result: DashboardLedgerResult(
            totalMinor: day * 100,
            entryCount: day == 20 ? 0 : 1,
            coreRevision: 1,
            scopeKey: childScope.key.value,
            timeScopeKey: 'day:2026-03-${day.toString().padLeft(2, '0')}',
            direction: 'expense',
            entries: day == 20
                ? const <DashboardLedgerEntry>[]
                : [
                    _entry(
                      id: 'row-$day',
                      date: LocalDate(year: 2026, month: 3, day: day),
                    ),
                  ],
          ),
        );
      }
      summaries.index = DashboardTimeChildSummaryIndex(
        parentQueryKey: parentScope.key.value,
        direction: LedgerDirection.expense,
        childPeriod: TimeChildPeriod.day,
        coreRevision: 1,
        isComplete: true,
        values: days,
      );
      final previewRepository = _StaticChildPreviewRepository(
        DashboardChildPreviewBundle(
          parentScope: parentScope,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 1,
          childrenByQueryKey: previews,
        ),
      );
      final store = DashboardPresentationStore();
      final query = CurrentQueryController(
        repository: ledger,
        initialScope: parentScope,
        presentationStore: store,
      );
      final summary = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        childSummaryRepository: summaries,
        childPreviewRepository: previewRepository,
        presentationStore: store,
      );
      addTearDown(summary.dispose);
      addTearDown(query.dispose);
      addTearDown(store.dispose);
      addTearDown(navigation.dispose);
      addTearDown(ledger.dispose);

      query.refresh();
      await Future<void>.value();
      ledger.emit(
        parentScope,
        DashboardLedgerResult(
          totalMinor: 7900,
          entryCount: 3,
          coreRevision: 1,
          scopeKey: parentScope.key.value,
          entries: [
            _entry(
              id: 'row-18',
              date: const LocalDate(year: 2026, month: 3, day: 18),
            ),
            _entry(
              id: 'row-19',
              date: const LocalDate(year: 2026, month: 3, day: 19),
            ),
            _entry(
              id: 'row-21',
              date: const LocalDate(year: 2026, month: 3, day: 21),
            ),
          ],
        ),
      );
      await Future<void>.value();
      expect(previewRepository.readCount, 1);
      navigation.setRailOpen(true);
      await Future<void>.value();

      final expected = <int, List<String>>{
        17: ['row-18'],
        18: ['row-19'],
        19: <String>[],
        20: ['row-21'],
      };
      for (final entry in expected.entries) {
        navigation.previewChildLogicalIndex(entry.key);
        final childSnapshot = store.activeSnapshot;
        expect(childSnapshot?.isPreview, isTrue);
        expect(childSnapshot?.entries.map((row) => row.id), entry.value);
        expect(childSnapshot?.entryCount, entry.value.length);
        expect(childSnapshot?.queryKey.value, contains('day:2026-03-'));
      }
      final visiblePublishesBeforeSettle =
          store.visiblePresentationPublishCount;
      final previewPromotionsBeforeSettle = store.previewPromotionCount;
      navigation.settleChildLogicalIndex(20);
      expect(store.activeSnapshot?.queryKey.value, contains('day:2026-03-21'));
      expect(
        store.visiblePresentationPublishCount,
        visiblePublishesBeforeSettle,
      );
      expect(store.previewPromotionCount, previewPromotionsBeforeSettle + 1);
      expect(store.settleVisualRebindCount, 0);
      expect(navigation.state.previewChild, isNull);
      expect(ledger.watchCount, 1);
      expect(previewRepository.readCount, 1);
    },
  );
}

DashboardLedgerEntry _entry({required String id, required LocalDate date}) {
  final epochDay = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(1970, 1, 1)).inDays;
  return DashboardLedgerEntry(
    id: id,
    partnerId: 'partner',
    categoryId: 'category',
    direction: 'expense',
    amountMinor: 100,
    bookedLocalEpochDay: epochDay,
    bookedLocalTimeMinutes: 60,
    partnerDisplayName: id,
    categoryDisplayName: 'Category',
    categoryColorId: 'color_01',
    categoryIconId: 'icon_01',
  );
}
