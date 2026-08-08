import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
  );

  test('retains only the visible committed page window, never all pages', () {
    final cache = CommittedLogViewportCache(
      pageSize: 24,
      maximumRetainedPages: 5,
    );
    addTearDown(cache.dispose);

    cache.seed(
      _page(scope, ordinal: 0, total: 1000, nextCursor: _cursor(0)),
      generation: 11,
    );
    for (var ordinal = 1; ordinal < 8; ordinal += 1) {
      expect(
        cache.commit(
          _page(
            scope,
            ordinal: ordinal,
            total: 1000,
            nextCursor: _cursor(ordinal),
          ),
        ),
        isTrue,
      );
    }

    cache.updateVisibleRowWindow(start: 6 * 24, end: 6 * 24 + 5);

    expect(cache.totalEntryCount, 1000);
    expect(cache.loadedEntryCount, 8 * 24);
    expect(cache.retainedPageCount, lessThanOrEqualTo(5));
    expect(cache.pageForOrdinal(6), isNotNull);
    expect(cache.pageForOrdinal(0), isNull);
    expect(cache.rowAt(6 * 24)?.row.entryId, 'row-144');
  });

  test(
    'rejects a page until it matches the active exact scope and generation',
    () {
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(cache.dispose);
      cache.seed(
        _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
        generation: 7,
      );

      expect(
        cache.commit(
          _page(scope, ordinal: 1, total: 48, nextCursor: null, generation: 6),
        ),
        isFalse,
      );
      expect(cache.stalePageDiscardCount, 1);
      expect(cache.loadedEntryCount, 24);
      expect(cache.pageForOrdinal(1), isNull);
    },
  );

  testWidgets('publishes an atomically prepared vertical page', (tester) async {
    final cache = CommittedLogViewportCache(pageSize: 24);
    addTearDown(cache.dispose);
    cache.seed(
      _page(scope, ordinal: 0, total: 48, nextCursor: _cursor(0)),
      generation: 11,
    );
    cache.configureSurfaceWidth(378);

    final initial = cache.preparedPageForOrdinal(0);
    expect(initial, isNotNull);
    expect(initial?.rowLayoutCount, 24);
    expect(initial?.dayHeaderCount, 1);
    expect(cache.layoutAt(0), isNotNull);
    expect(cache.dayHeaderAt(0), isNotNull);
    expect(cache.textLayoutMissCount, 0);

    expect(
      cache.commit(_page(scope, ordinal: 1, total: 48, nextCursor: null)),
      isTrue,
    );
    expect(cache.preparedPageForOrdinal(1)?.rowLayoutCount, 24);
    expect(cache.layoutAt(24), isNotNull);
    expect(cache.textLayoutMissCount, 0);
  });

  for (final totalRows in <int>[24, 94, 658, 1000, 10000, 50000, 100000]) {
    test(
      '$totalRows committed rows retain bounded page/layout data at the end',
      () {
        final cache = CommittedLogViewportCache(
          pageSize: 24,
          maximumRetainedPages: 5,
        );
        addTearDown(cache.dispose);
        final lastOrdinal = (totalRows - 1) ~/ 24;
        cache.seed(
          _sizedPage(scope, ordinal: 0, total: totalRows, generation: 1),
          generation: 1,
        );
        for (var ordinal = 1; ordinal <= lastOrdinal; ordinal += 1) {
          expect(
            cache.commit(
              _sizedPage(
                scope,
                ordinal: ordinal,
                total: totalRows,
                generation: 1,
              ),
            ),
            isTrue,
          );
          cache.updateVisibleRowWindow(
            start: ordinal * 24,
            end: (ordinal + 1) * 24,
          );
        }

        cache.updateVisibleRowWindow(start: lastOrdinal * 24, end: totalRows);
        expect(cache.loadedEntryCount, totalRows);
        expect(cache.rowAt(totalRows - 1)?.row.entryId, 'row-${totalRows - 1}');
        expect(cache.retainedPageCount, lessThanOrEqualTo(5));
        expect(cache.retainedRowCount, lessThanOrEqualTo(5 * 24));
        expect(cache.preparedTextRowCount, 0);
        expect(
          (cache.report()['cursorAnchors'] as int),
          lessThanOrEqualTo(cache.maximumCursorAnchors),
        );
      },
    );
  }
}

CommittedLogPage _page(
  CurrentLedgerQueryScope scope, {
  required int ordinal,
  required int total,
  required Map<String, Object?>? nextCursor,
  int generation = 11,
}) {
  final start = ordinal * 24;
  final rows = List<DashboardLogRowViewModel>.generate(
    24,
    (index) => DashboardLogRowViewModel(
      entryId: 'row-${start + index}',
      displayName: 'Név ${start + index}',
      categoryDisplayName: 'Kategória',
      formattedAmount: '-1 000 Ft',
      displayTime: '10:00',
      amountStyle: LogAmountStyle.expense,
      categoryColorId: 'fallback',
      categoryIconId: 'fallback',
      semanticLabel: 'Sor ${start + index}',
    ),
  );
  return CommittedLogPage(
    queryKey: scope.key,
    coreRevision: 3,
    generation: generation,
    ordinal: ordinal,
    startCursor: ordinal == 0 ? null : _cursor(ordinal - 1),
    previousStartCursor: ordinal < 2 ? null : _cursor(ordinal - 2),
    payload: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 3,
      groups: <DashboardDayLogGroupViewModel>[
        DashboardDayLogGroupViewModel(
          dateKey: '2026-07-01',
          dayLabel: '2026. július 1.',
          rows: rows,
        ),
      ],
      entryCount: total,
      nextCursor: nextCursor,
      direction: scope.direction,
    ),
  );
}

Map<String, Object?> _cursor(int page) => <String, Object?>{
  'bookedLocalEpochDay': 20_000 - page,
  'bookedLocalTimeMinutes': 600,
  'entryId': 'row-${page * 24 + 23}',
};

CommittedLogPage _sizedPage(
  CurrentLedgerQueryScope scope, {
  required int ordinal,
  required int total,
  required int generation,
}) {
  final start = ordinal * 24;
  final count = (total - start).clamp(0, 24);
  final rows = List<DashboardLogRowViewModel>.generate(
    count,
    (index) => DashboardLogRowViewModel(
      entryId: 'row-${start + index}',
      displayName: 'Név ${start + index}',
      categoryDisplayName: 'Kategória',
      formattedAmount: '-1 000 Ft',
      displayTime: '10:00',
      amountStyle: LogAmountStyle.expense,
      categoryColorId: 'fallback',
      categoryIconId: 'fallback',
      semanticLabel: 'Sor ${start + index}',
    ),
  );
  return CommittedLogPage(
    queryKey: scope.key,
    coreRevision: 3,
    generation: generation,
    ordinal: ordinal,
    startCursor: ordinal == 0 ? null : _cursor(ordinal - 1),
    previousStartCursor: ordinal < 2 ? null : _cursor(ordinal - 2),
    payload: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 3,
      groups: rows.isEmpty
          ? const <DashboardDayLogGroupViewModel>[]
          : <DashboardDayLogGroupViewModel>[
              DashboardDayLogGroupViewModel(
                dateKey: '2026-07-01',
                dayLabel: '2026. július 1.',
                rows: rows,
              ),
            ],
      entryCount: total,
      nextCursor: start + count < total ? _cursor(ordinal) : null,
      direction: scope.direction,
    ),
  );
}
