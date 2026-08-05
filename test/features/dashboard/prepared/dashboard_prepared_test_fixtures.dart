import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

DashboardPreparedDeck preparedDeckFixture({
  int month = 6,
  int revision = 1,
  int generation = 1,
  LedgerDirection direction = LedgerDirection.income,
}) {
  final parentScope = CurrentLedgerQueryScope(
    direction: direction,
    timeScope: MonthScope(YearMonth(year: 2026, month: month)),
  );
  final catalog = DashboardSemanticCatalog.forParent(
    parentScope: parentScope,
    childKind: DashboardChildKind.day,
  );
  final key = DashboardPreparedDeckKey.fromScope(
    parentScope: parentScope,
    childKind: catalog.childKind,
    coreRevision: revision,
    pageSize: 24,
    semanticWindowIdentity: catalog.windowIdentity,
  );
  final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
  for (final entry in catalog.entries) {
    frames[entry.queryKey] = preparedFrameFixture(
      scope: entry.scope,
      parentQueryKey: parentScope.key,
      revision: revision,
      digest: Object.hash(month, entry.logicalIndex, direction),
    );
  }
  return DashboardPreparedDeck.complete(
    key: key,
    parentScope: parentScope,
    parentFrame: preparedFrameFixture(
      scope: parentScope,
      parentQueryKey: parentScope.key,
      revision: revision,
      digest: Object.hash(month, direction),
    ),
    semanticCatalog: catalog,
    frames: frames,
    contentDigest: Object.hash(month, revision, direction),
    generation: generation,
    preparedAt: DateTime.utc(2026, 8, 5),
    buildMetrics: const DashboardPreparedDeckBuildMetrics.synthetic(),
  );
}

DashboardPreparedFrame preparedFrameFixture({
  required CurrentLedgerQueryScope scope,
  required LedgerQueryKey parentQueryKey,
  required int revision,
  required int digest,
  Map<String, Object?>? nextCursor,
}) => DashboardPreparedFrame.complete(
  scope: scope,
  parentQueryKey: parentQueryKey,
  coreRevision: revision,
  totalMinor: digest.abs(),
  formattedAmount: '${digest.abs()},00 Ft',
  entryCount: 0,
  formattedEntryCount: '0',
  logBox: DashboardLogViewportState(
    queryKey: scope.key,
    revision: revision,
    groups: const [],
    entryCount: 0,
    nextCursor: nextCursor,
    direction: scope.direction,
  ),
  presentationDigest: digest,
);
