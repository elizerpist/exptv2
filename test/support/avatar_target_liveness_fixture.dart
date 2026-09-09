import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/dashboard_focus_membership_seed.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

/// Only the external data seam is synthetic. Production index/focus/cache,
/// physical carousel and render surfaces are used unchanged by the fixture.
final class AvatarTargetLivenessRepository
    implements
        DashboardDataRuntimeRepository,
        PreparedBudgetLimitSnapshotRepository {
  AvatarTargetLivenessRepository({Set<int>? populatedHandles})
    : rows = List.unmodifiable([
        for (var handle = 1; handle <= 8; handle++)
          if (populatedHandles == null || populatedHandles.contains(handle))
            DashboardLedgerEntry(
              id: 'avatar-row-$handle',
              partnerId: 'partner-$handle',
              categoryId: 'avatar-category-$handle',
              direction: 'expense',
              amountMinor: handle * 100,
              bookedLocalEpochDay:
                  DateTime.utc(2026, 7, 14).millisecondsSinceEpoch ~/
                  Duration.millisecondsPerDay,
              bookedLocalTimeMinutes: 720 - handle,
              partnerDisplayName: 'Partner $handle',
              categoryDisplayName: 'Category $handle',
              categoryColorId: 'fallback',
              categoryIconId: 'fallback',
            ),
      ]);

  final List<DashboardLedgerEntry> rows;
  int indexRequests = 0;
  int pageRequests = 0;
  final categories = List<FluviCategory>.unmodifiable([
    for (var handle = 1; handle <= 8; handle++)
      FluviCategory(
        id: 'avatar-category-$handle',
        name: 'Category $handle',
        colorId: 'fallback',
        iconId: 'fallback',
        isSystemUncategorized: false,
        createdAtUtcMs: 1,
        updatedAtUtcMs: 1,
      ),
  ]);

  List<DashboardLedgerEntry> rowsFor(CurrentLedgerQueryScope scope) {
    final containsDate = switch (scope.timeScope) {
      AllTimeScope() => true,
      YearScope(:final year) => year == 2026,
      MonthScope(:final value) => value.year == 2026 && value.month == 7,
      DayScope(:final date) =>
        date.year == 2026 && date.month == 7 && date.day == 14,
    };
    if (scope.direction != LedgerDirection.expense || !containsDate) {
      return const [];
    }
    return rows
        .where(
          (row) =>
              scope.categoryIds.isEmpty ||
              scope.categoryIds.contains(row.categoryId),
        )
        .toList(growable: false);
  }

  DashboardLogViewportState payload(
    CurrentLedgerQueryScope scope,
    int revision,
  ) {
    final selected = rowsFor(scope);
    return DashboardLogViewportState.deferredPreparedOrdered(
      scope: scope,
      revision: revision,
      entries: selected,
      entryCount: selected.length,
      nextCursor: null,
    );
  }

  @override
  Stream<int> watchCoreRevision() => Stream.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) async {
    indexRequests++;
    final empty = await const EmptyDashboardDataRuntimeRepository()
        .prepareIndex(request, token);
    final scopes = <LedgerQueryKey, CurrentLedgerQueryScope>{
      for (final zero in empty.compactZeroFrames.values)
        zero.queryKey: zero.scope,
      for (final frame in empty.frames.values) frame.queryKey: frame.scope,
    };
    final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
    for (final scope in scopes.values) {
      final selected = rowsFor(scope);
      if (selected.isEmpty) continue;
      final amount = selected.fold<int>(0, (sum, row) => sum + row.amountMinor);
      frames[scope.key] = DashboardPreparedFrame.complete(
        scope: scope,
        parentQueryKey: dashboardPreparedParentQueryKey(scope),
        coreRevision: request.key.coreRevision,
        totalMinor: amount,
        formattedAmount: '$amount Ft',
        entryCount: selected.length,
        formattedEntryCount: '${selected.length}',
        logBox: payload(scope, request.key.coreRevision),
        presentationDigest: Object.hash(
          scope.key,
          request.key.coreRevision,
          amount,
        ),
      );
    }
    return PreparedDashboardIndex.complete(
      key: request.key,
      frames: frames,
      catalogs: empty.catalogs,
      scopes: scopes,
      geometrySeedsByDirection: {
        LedgerDirection.expense: [
          if (rows.isNotEmpty)
            CommittedVerticalGeometryDayBucket(
              bookedLocalEpochDay: rows.first.bookedLocalEpochDay,
              entryCount: rows.length,
            ),
        ],
      },
      focusMembershipSeedsByDirection: {
        LedgerDirection.expense: DashboardFocusMembershipSeed(rows),
        LedgerDirection.income: DashboardFocusMembershipSeed(const []),
      },
      generation: token.generation,
      contentDigest: Object.hash(request.key, rows.length),
      preparedAt: DateTime.utc(2026, 7, 14),
      buildMetrics: empty.buildMetrics,
    );
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) async {
    pageRequests++;
    return CommittedLogPage(
      queryKey: request.scope.key,
      coreRevision: request.coreRevision,
      generation: request.commitGeneration,
      ordinal: request.pageOrdinal,
      startCursor: request.startCursor,
      previousStartCursor: request.previousStartCursor,
      payload: payload(request.scope, request.coreRevision),
    );
  }

  @override
  Future<PreparedBudgetLimitSnapshot> prepareBudgetLimitSnapshot({
    required int coreRevision,
    required int yearWindowStart,
    required int yearWindowEndInclusive,
  }) async {
    final periodCount = 1 + (yearWindowEndInclusive - yearWindowStart + 1) * 13;
    PreparedBudgetLimitDirectionBank bank(bool expense) =>
        PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: categories
              .map((category) => category.id)
              .toList(),
          cells: [
            for (var period = 0; period < periodCount; period++)
              for (var handle = 0; handle <= 8; handle++)
                PreparedBudgetLimitCell(
                  actualScaled100: !expense
                      ? 0
                      : handle == 0
                      ? rows.fold<int>(0, (sum, row) => sum + row.amountMinor)
                      : rows
                            .where(
                              (row) =>
                                  row.categoryId == 'avatar-category-$handle',
                            )
                            .fold<int>(0, (sum, row) => sum + row.amountMinor),
                  limitScaled100: handle == 0 ? 10000 : 2000,
                  limitSource: PreparedBudgetLimitSource.base,
                ),
          ],
        );
    return PreparedBudgetLimitSnapshot(
      coreRevision: coreRevision,
      yearWindowStart: yearWindowStart,
      yearWindowEndInclusive: yearWindowEndInclusive,
      incomeBank: bank(false),
      expenseBank: bank(true),
    );
  }

  @override
  Map<String, Object?> performanceReport() => {
    'index_build_calls': indexRequests,
    'page_read_calls': pageRequests,
  };
}
