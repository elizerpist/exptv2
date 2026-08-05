import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('prepared deck key keeps every data-changing dimension', () {
    final parent = _parentScope();
    final key = DashboardPreparedDeckKey.fromScope(
      parentScope: parent,
      childKind: DashboardChildKind.day,
      coreRevision: 7,
      pageSize: 24,
      semanticWindowIdentity: 'days:2026-06',
    );

    expect(key.modelVersion, DashboardPreparedDeckKey.currentModelVersion);
    expect(key.direction, LedgerDirection.income);
    expect(key.parentQueryKey, parent.key);
    expect(key.categoryIdsKey, 'a,b');
    expect(key.partnerIdsKey, 'p1,p2');
    expect(key.refinementsKey, 'maximum=200,minimum=100');
    expect(key.childKind, DashboardChildKind.day);
    expect(key.coreRevision, 7);
    expect(key.pageSize, 24);
    expect(key.semanticWindowIdentity, 'days:2026-06');
  });

  test('complete frame atomically owns amount count and LogBox identity', () {
    final childScope = _parentScope().copyWith(
      timeScope: const DayScope(LocalDate(year: 2026, month: 6, day: 1)),
    );
    final frame = _frame(childScope, revision: 7, totalMinor: 12345, count: 2);

    expect(frame.queryKey, childScope.key);
    expect(frame.amount.queryKey, childScope.key);
    expect(frame.count.queryKey, childScope.key);
    expect(frame.logBox.queryKey, childScope.key);
    expect(frame.amount.coreRevision, 7);
    expect(frame.count.coreRevision, 7);
    expect(frame.logBox.revision, 7);
    expect(frame.amount.formattedAmount, '123,45 Ft');
    expect(frame.count.formattedEntryCount, '2');
    expect(frame.emptyState.isEmpty, isFalse);
    expect(frame.loading, isFalse);
    expect(frame.stale, isFalse);
  });

  test('rejects revision zero and mismatched LogBox identity', () {
    final childScope = _parentScope().copyWith(
      timeScope: const DayScope(LocalDate(year: 2026, month: 6, day: 1)),
    );
    expect(
      () => _frame(childScope, revision: 0, totalMinor: 0, count: 0),
      throwsArgumentError,
    );

    final wrongLog = DashboardLogViewportState(
      queryKey: const LedgerQueryKey('wrong'),
      revision: 7,
      groups: const [],
      entryCount: 0,
      nextCursor: null,
      isPreview: true,
      isCommitted: false,
      direction: LedgerDirection.income,
    );
    expect(
      () => DashboardPreparedFrame.complete(
        scope: childScope,
        parentQueryKey: _parentScope().key,
        coreRevision: 7,
        totalMinor: 0,
        formattedAmount: '0 Ft',
        entryCount: 0,
        formattedEntryCount: '0',
        logBox: wrongLog,
        presentationDigest: 1,
      ),
      throwsArgumentError,
    );
  });

  test('complete deck requires one exact frame for every catalog entry', () {
    final parent = _parentScope();
    final catalog = DashboardSemanticCatalog.forParent(
      parentScope: parent,
      childKind: DashboardChildKind.day,
    );
    final frames = {
      for (final entry in catalog.entries)
        entry.queryKey: _frame(
          entry.scope,
          revision: 7,
          totalMinor: 0,
          count: 0,
        ),
    };
    final parentFrame = _frame(parent, revision: 7, totalMinor: 0, count: 0);
    final key = DashboardPreparedDeckKey.fromScope(
      parentScope: parent,
      childKind: DashboardChildKind.day,
      coreRevision: 7,
      pageSize: 24,
      semanticWindowIdentity: catalog.windowIdentity,
    );
    final deck = DashboardPreparedDeck.complete(
      key: key,
      parentScope: parent,
      parentFrame: parentFrame,
      semanticCatalog: catalog,
      frames: frames,
      contentDigest: 77,
      generation: 3,
      preparedAt: DateTime.utc(2026, 8, 5),
    );

    expect(deck.isComplete, isTrue);
    expect(deck.childCount, 30);
    expect(deck.frames, hasLength(30));
    expect(deck.frames[catalog[0].queryKey], same(frames[catalog[0].queryKey]));

    final incomplete = Map<LedgerQueryKey, DashboardPreparedFrame>.of(frames)
      ..remove(catalog[0].queryKey);
    expect(
      () => DashboardPreparedDeck.complete(
        key: key,
        parentScope: parent,
        parentFrame: parentFrame,
        semanticCatalog: catalog,
        frames: incomplete,
        contentDigest: 77,
        generation: 3,
        preparedAt: DateTime.utc(2026, 8, 5),
      ),
      throwsArgumentError,
    );
  });
}

DashboardPreparedFrame _frame(
  CurrentLedgerQueryScope scope, {
  required int revision,
  required int totalMinor,
  required int count,
}) {
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: revision,
    groups: const [],
    entryCount: count,
    nextCursor: null,
    isPreview: true,
    isCommitted: false,
    direction: scope.direction,
  );
  return DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: _parentScope().key,
    coreRevision: revision,
    totalMinor: totalMinor,
    formattedAmount: totalMinor == 0 ? '0 Ft' : '123,45 Ft',
    entryCount: count,
    formattedEntryCount: '$count',
    logBox: logBox,
    presentationDigest: Object.hash(scope.key, revision, totalMinor, count),
  );
}

CurrentLedgerQueryScope _parentScope() => CurrentLedgerQueryScope(
  direction: LedgerDirection.income,
  timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
  categoryIds: const {'b', 'a'},
  partnerIds: const {'p2', 'p1'},
  refinements: const {'minimum': 100, 'maximum': 200},
);
