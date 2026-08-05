import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/prepared/domain/dashboard_prepared_deck.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test(
    'visible frame preserves one atomic key and revision for every lane',
    () {
      final frame = DashboardVisibleFrame.fromPrepared(
        _preparedFrame(),
        parentQueryKey: _parentScope().key,
        plane: TimePlane.month,
        railOpen: true,
        semanticIndex: 14,
        childLabel: '15',
        navigationEpoch: 4,
        presentationEpoch: 9,
        frameGeneration: 12,
        mode: DashboardVisibleMode.preview,
      );

      expect(frame.queryKey, frame.amount.queryKey);
      expect(frame.queryKey, frame.count.queryKey);
      expect(frame.queryKey, frame.logBox.queryKey);
      expect(frame.coreRevision, frame.amount.coreRevision);
      expect(frame.coreRevision, frame.count.coreRevision);
      expect(frame.coreRevision, frame.logBox.revision);
      expect(frame.childLabel, '15');
      expect(frame.semanticChildIndex, 14);
      expect(frame.mode, DashboardVisibleMode.preview);
    },
  );

  test(
    'commit promotion changes provenance without changing visual digest',
    () {
      final preview = DashboardVisibleFrame.fromPrepared(
        _preparedFrame(),
        parentQueryKey: _parentScope().key,
        plane: TimePlane.month,
        railOpen: true,
        semanticIndex: 14,
        childLabel: '15',
        navigationEpoch: 4,
        presentationEpoch: 9,
        frameGeneration: 12,
        mode: DashboardVisibleMode.preview,
      );
      final committed = preview.asCommitted();

      expect(committed.mode, DashboardVisibleMode.committed);
      expect(committed.visualDigest, preview.visualDigest);
      expect(committed.amount, same(preview.amount));
      expect(committed.count, same(preview.count));
      expect(committed.logBox, same(preview.logBox));
    },
  );
}

DashboardPreparedFrame _preparedFrame() {
  final scope = _parentScope().copyWith(
    timeScope: const DayScope(LocalDate(year: 2026, month: 6, day: 15)),
  );
  return DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: _parentScope().key,
    coreRevision: 3,
    totalMinor: 12345,
    formattedAmount: '123,45 Ft',
    entryCount: 2,
    formattedEntryCount: '2',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 3,
      groups: const [],
      entryCount: 2,
      nextCursor: null,
      direction: LedgerDirection.income,
    ),
    presentationDigest: 72,
  );
}

CurrentLedgerQueryScope _parentScope() => CurrentLedgerQueryScope(
  direction: LedgerDirection.income,
  timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
);
