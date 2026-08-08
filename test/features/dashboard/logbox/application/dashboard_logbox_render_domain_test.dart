import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_domain.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test('preview frames always select the prepared rail-scene domain', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    final frame = _frame(DashboardVisibleMode.preview);
    cache.seed(_root(frame), generation: 1);
    cache.configureSurfaceWidth(378);
    expect(cache.activateVerticalRendering(), isTrue);

    expect(
      resolveDashboardLogBoxRenderDomain(
        frame: frame,
        committedViewport: cache,
      ),
      DashboardLogBoxRenderDomain.railPreview,
    );
  });

  test('only the exact active committed root selects the vertical domain', () {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    final committed = _frame(DashboardVisibleMode.committed);
    cache.seed(_root(committed), generation: 1);
    cache.configureSurfaceWidth(378);
    expect(cache.activateVerticalRendering(), isTrue);

    expect(
      resolveDashboardLogBoxRenderDomain(
        frame: committed,
        committedViewport: cache,
      ),
      DashboardLogBoxRenderDomain.committedVertical,
    );

    final differentViewport = _frame(
      DashboardVisibleMode.committed,
      presentationDigest: 2,
    );
    expect(
      resolveDashboardLogBoxRenderDomain(
        frame: differentViewport,
        committedViewport: cache,
      ),
      DashboardLogBoxRenderDomain.railPreview,
    );
  });
}

DashboardVisibleFrame _frame(
  DashboardVisibleMode mode, {
  int presentationDigest = 1,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
  );
  final payload = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: const <DashboardDayLogGroupViewModel>[],
    entryCount: presentationDigest,
    nextCursor: null,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: presentationDigest,
    formattedEntryCount: '$presentationDigest',
    logBox: payload,
    presentationDigest: presentationDigest,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: '2026. július',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: presentationDigest,
    mode: mode,
  );
}

CommittedLogPage _root(DashboardVisibleFrame frame) => CommittedLogPage(
  queryKey: frame.queryKey,
  coreRevision: frame.coreRevision,
  generation: 1,
  ordinal: 0,
  startCursor: null,
  previousStartCursor: null,
  payload: frame.logBox,
);
