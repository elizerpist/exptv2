import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

PreparedDashboardIndex buildRuntimeTestIndex({
  required int revision,
  int generation = 1,
  int amountMultiplier = 1,
  int? entryCountOverride,
}) {
  final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
  final catalogs = <LedgerQueryKey, DashboardSemanticCatalog>{};

  void addFrame(CurrentLedgerQueryScope scope) {
    frames.putIfAbsent(
      scope.key,
      () => runtimeTestFrame(
        scope,
        revision: revision,
        amountMultiplier: amountMultiplier,
        entryCountOverride: entryCountOverride,
      ),
    );
  }

  void addCatalog(DashboardSemanticCatalog catalog) {
    catalogs[catalog.parentScope.key] = catalog;
    addFrame(catalog.parentScope);
    for (final entry in catalog.entries) {
      addFrame(entry.scope);
    }
  }

  for (final direction in LedgerDirection.values) {
    final all = CurrentLedgerQueryScope(
      direction: direction,
      timeScope: const AllTimeScope(),
    );
    addCatalog(
      DashboardSemanticCatalog.forParent(
        parentScope: all,
        childKind: DashboardChildKind.year,
        retainedYear: 2026,
        yearWindowRadius: 1,
      ),
    );
    for (var year = 2025; year <= 2027; year += 1) {
      final yearScope = CurrentLedgerQueryScope(
        direction: direction,
        timeScope: YearScope(year),
      );
      addCatalog(
        DashboardSemanticCatalog.forParent(
          parentScope: yearScope,
          childKind: DashboardChildKind.month,
        ),
      );
      for (var month = 1; month <= 12; month += 1) {
        final monthScope = CurrentLedgerQueryScope(
          direction: direction,
          timeScope: MonthScope(YearMonth(year: year, month: month)),
        );
        addCatalog(
          DashboardSemanticCatalog.forParent(
            parentScope: monthScope,
            childKind: DashboardChildKind.day,
          ),
        );
      }
    }
  }
  return PreparedDashboardIndex.complete(
    key: PreparedDashboardIndexKey(
      modelVersion: 1,
      coreRevision: revision,
      categoryIdsKey: '',
      partnerIdsKey: '',
      refinementsKey: '',
      pageSize: 24,
      yearWindowStart: 2025,
      yearWindowEndInclusive: 2027,
    ),
    frames: frames,
    catalogs: catalogs,
    generation: generation,
    contentDigest: Object.hash(revision, generation, amountMultiplier),
    preparedAt: DateTime.utc(2026, 8, 6),
    buildMetrics: const PreparedDashboardIndexBuildMetrics.synthetic(),
  );
}

DashboardPreparedFrame runtimeTestFrame(
  CurrentLedgerQueryScope scope, {
  required int revision,
  int amountMultiplier = 1,
  int? entryCountOverride,
}) {
  final periodValue = switch (scope.timeScope) {
    AllTimeScope() => 1,
    YearScope(:final year) => year,
    MonthScope(:final value) => value.year * 100 + value.month,
    DayScope(:final date) => date.year * 10000 + date.month * 100 + date.day,
  };
  final directionMultiplier = scope.direction == LedgerDirection.income ? 1 : 2;
  final amount = periodValue * directionMultiplier * amountMultiplier;
  final entryCount = entryCountOverride ?? (amount == 0 ? 0 : 1);
  return DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: dashboardPreparedParentQueryKey(scope),
    coreRevision: revision,
    totalMinor: amount,
    formattedAmount: '$amount Ft',
    entryCount: entryCount,
    formattedEntryCount: '$entryCount',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: revision,
      groups: const [],
      entryCount: entryCount,
      nextCursor: null,
      direction: scope.direction,
    ),
    presentationDigest: Object.hash(scope.key, revision, amount),
  );
}
