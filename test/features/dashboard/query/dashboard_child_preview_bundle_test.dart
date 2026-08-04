import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('bundle keeps exact child key and immutable preview payload', () {
    final parent = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const YearScope(2026),
    );
    final child = parent.copyWith(
      timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
    );
    final preview = DashboardChildPreview(
      childPeriodValue: '2026-03',
      scope: child,
      result: DashboardLedgerResult(
        totalMinor: 100,
        entryCount: 1,
        coreRevision: 7,
        scopeKey: child.key.value,
        direction: 'expense',
        entries: const <DashboardLedgerEntry>[],
      ),
    );
    final bundle = DashboardChildPreviewBundle(
      parentScope: parent,
      childPeriod: TimeChildPeriod.month,
      coreRevision: 7,
      childrenByQueryKey: <LedgerQueryKey, DashboardChildPreview>{
        child.key: preview,
      },
    );

    expect(bundle[child.key], same(preview));
    expect(bundle.parentQueryKey, parent.key);
    expect(bundle.cacheKey, contains('revision:7'));
    expect(() => bundle.childrenByQueryKey.clear(), throwsUnsupportedError);
    expect(preview.result.entries, isEmpty);
  });
}
