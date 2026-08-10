import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test('Apply publishes one prepared restricted query scope atomically', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2025, 7, 14),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.expense,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    final draft = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
      temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2024, 2),
        QueryPeriodSelection.month(2026, 8),
      }),
      categoryIds: const <String>{'food'},
    );
    var appliedNotifications = 0;
    core.currentQuery.addListener(() => appliedNotifications += 1);

    final published = await core.applyQuery(draft);

    expect(published, isTrue);
    expect(appliedNotifications, 1);
    expect(core.currentQuery.scope, draft);
    expect(core.navigation.state.parentQueryScope.temporalFilter, draft.temporalFilter);
    expect(core.navigation.temporalAvailability.allowedYears, <int>[2024, 2026]);
    expect(core.preparedIndex?.key.temporalFilterKey, draft.temporalFilter.canonicalKey);
  });
}
