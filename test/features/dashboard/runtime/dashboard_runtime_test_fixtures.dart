import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_directional_query_set.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

PreparedDashboardIndex buildRuntimeTestIndex({
  required int revision,
  int generation = 1,
  int amountMultiplier = 1,
  int? entryCountOverride,
  int Function(CurrentLedgerQueryScope scope)? entryCountForScope,
  int Function(CurrentLedgerQueryScope scope)? previewRowCountForScope,
  int Function(CurrentLedgerQueryScope scope)? previewGroupCountForScope,
  DashboardDirectionalQuerySet? directionalQueries,
  bool deferredLogBoxes = false,
  int initialYear = 2026,
  int yearWindowRadius = 1,
}) {
  final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
  final catalogs = <LedgerQueryKey, DashboardSemanticCatalog>{};
  final queries =
      directionalQueries ??
      DashboardDirectionalQuerySet.fromInitial(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const AllTimeScope(),
        ),
      );

  void addFrame(CurrentLedgerQueryScope scope) {
    frames.putIfAbsent(
      scope.key,
      () => runtimeTestFrame(
        scope,
        revision: revision,
        amountMultiplier: amountMultiplier,
        entryCountOverride:
            entryCountForScope?.call(scope) ?? entryCountOverride,
        previewRowCount: previewRowCountForScope?.call(scope) ?? 0,
        previewGroupCount: previewGroupCountForScope?.call(scope) ?? 1,
        deferredLogBox: deferredLogBoxes,
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
    final all = queries
        .scopeFor(direction)
        .copyWith(timeScope: const AllTimeScope());
    addCatalog(
      DashboardSemanticCatalog.forParent(
        parentScope: all,
        childKind: DashboardChildKind.year,
        retainedYear: initialYear,
        yearWindowRadius: yearWindowRadius,
      ),
    );
    for (
      var year = initialYear - yearWindowRadius;
      year <= initialYear + yearWindowRadius;
      year += 1
    ) {
      final yearScope = all.copyWith(timeScope: YearScope(year));
      addCatalog(
        DashboardSemanticCatalog.forParent(
          parentScope: yearScope,
          childKind: DashboardChildKind.month,
        ),
      );
      for (var month = 1; month <= 12; month += 1) {
        final monthScope = all.copyWith(
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
    key: PreparedDashboardIndexKey.fromDirectionalQuerySet(
      queries: queries,
      coreRevision: revision,
      pageSize: 24,
      yearWindowStart: initialYear - yearWindowRadius,
      yearWindowEndInclusive: initialYear + yearWindowRadius,
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
  int previewRowCount = 0,
  int previewGroupCount = 1,
  bool deferredLogBox = false,
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
  if (previewRowCount < 0 || previewRowCount > entryCount) {
    throw ArgumentError.value(
      previewRowCount,
      'previewRowCount',
      'must be between zero and entryCount',
    );
  }
  if (previewRowCount > 0 &&
      (previewGroupCount < 1 || previewGroupCount > previewRowCount)) {
    throw ArgumentError.value(
      previewGroupCount,
      'previewGroupCount',
      'must be between one and previewRowCount',
    );
  }
  var nextRowIndex = 0;
  final groups = previewRowCount == 0
      ? const <DashboardDayLogGroupViewModel>[]
      : List<DashboardDayLogGroupViewModel>.generate(previewGroupCount, (
          groupIndex,
        ) {
          final remainingRows = previewRowCount - nextRowIndex;
          final remainingGroups = previewGroupCount - groupIndex;
          final groupRowCount = (remainingRows / remainingGroups).ceil();
          final firstRowIndex = nextRowIndex;
          nextRowIndex += groupRowCount;
          return DashboardDayLogGroupViewModel(
            dateKey: 'fixture-day-$groupIndex',
            dayLabel: 'Fixture day $groupIndex',
            rows: List<DashboardLogRowViewModel>.generate(groupRowCount, (
              localIndex,
            ) {
              final rowIndex = firstRowIndex + localIndex;
              return DashboardLogRowViewModel(
                entryId: '${scope.key.value}|row:$rowIndex',
                displayName: 'Fixture transaction $rowIndex',
                categoryDisplayName: 'Fixture category',
                formattedAmount: '${rowIndex + 1} Ft',
                displayTime: '12:00',
                amountStyle: scope.direction == LedgerDirection.income
                    ? LogAmountStyle.income
                    : LogAmountStyle.expense,
                categoryColorId: 'fallback',
                categoryIconId: 'fallback',
                semanticLabel: 'Fixture transaction $rowIndex',
              );
            }, growable: false),
          );
        }, growable: false);
  final logBox = deferredLogBox
      ? DashboardLogViewportState.deferredPreparedOrdered(
          scope: scope,
          revision: revision,
          entries: List<DashboardLedgerEntry>.generate(
            previewRowCount,
            (index) => DashboardLedgerEntry(
              id: '${scope.key.value}|row:$index',
              partnerId: 'fixture-partner-$index',
              categoryId: 'fixture-category-$index',
              direction: scope.direction.name,
              amountMinor: index + 1,
              bookedLocalEpochDay: 20000 - index,
              bookedLocalTimeMinutes: 720,
              partnerDisplayName: 'Fixture transaction $index',
              categoryDisplayName: 'Fixture category',
              categoryColorId: 'fallback',
              categoryIconId: 'fallback',
            ),
            growable: false,
          ),
          entryCount: entryCount,
          nextCursor: null,
        )
      : DashboardLogViewportState(
          queryKey: scope.key,
          revision: revision,
          groups: groups,
          entryCount: entryCount,
          nextCursor: null,
          direction: scope.direction,
        );
  return DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: dashboardPreparedParentQueryKey(scope),
    coreRevision: revision,
    totalMinor: amount,
    formattedAmount: '$amount Ft',
    entryCount: entryCount,
    formattedEntryCount: '$entryCount',
    logBox: logBox,
    presentationDigest: Object.hash(scope.key, revision, amount),
  );
}
