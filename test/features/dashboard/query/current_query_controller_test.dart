import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _DelayedRepository implements DashboardLedgerRepository {
  final pending = <String, Completer<DashboardLedgerResult>>{};
  final requestedKeys = <String>[];

  @override
  Future<DashboardLedgerResult> read(CurrentLedgerQueryScope scope) {
    final key = scope.key.value;
    requestedKeys.add(key);
    final completer = Completer<DashboardLedgerResult>();
    pending[key] = completer;
    return completer.future;
  }
}

class _ImmediateRepository implements DashboardLedgerRepository {
  int reads = 0;

  @override
  Future<DashboardLedgerResult> read(CurrentLedgerQueryScope scope) async {
    reads += 1;
    return const DashboardLedgerResult(totalMinor: 100, coreRevision: 7);
  }
}

void main() {
  test(
    'query key is identical for equivalent scopes regardless of facet order',
    () {
      final first = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 5)),
        categoryIds: const {'b', 'a'},
        partnerIds: const {'p2', 'p1'},
        refinements: const {'note': 'food', 'min': 100},
      );
      final second = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const MonthScope(YearMonth(year: 2026, month: 5)),
        categoryIds: const {'a', 'b'},
        partnerIds: const {'p1', 'p2'},
        refinements: const {'min': 100, 'note': 'food'},
      );

      expect(first, second);
      expect(first.key, second.key);
      expect(first.key.value, contains('expense|month:2026-05'));
    },
  );

  test(
    'same scope is deduplicated and changed scope starts one read',
    () async {
      final repository = _DelayedRepository();
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(controller.dispose);

      controller.setTimeScope(const AllTimeScope());
      expect(repository.requestedKeys, isEmpty);

      controller.setTimeScope(const YearScope(2026));
      expect(repository.requestedKeys, hasLength(1));
      expect(repository.requestedKeys.single, contains('year:2026'));
    },
  );

  test('latest scope result wins over an older in-flight read', () async {
    final repository = _DelayedRepository();
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: AllTimeScope(),
      ),
    );
    addTearDown(controller.dispose);

    controller.setTimeScope(const YearScope(2025));
    controller.setTimeScope(const YearScope(2026));
    final oldKey = repository.requestedKeys[0];
    final newKey = repository.requestedKeys[1];

    repository.pending[oldKey]!.complete(
      const DashboardLedgerResult(totalMinor: 100),
    );
    await Future<void>.value();
    expect(controller.state.result, isNull);

    repository.pending[newKey]!.complete(
      const DashboardLedgerResult(totalMinor: 200),
    );
    await Future<void>.value();
    expect(controller.state.result?.totalMinor, 200);
    expect(controller.state.scope.timeScope, const YearScope(2026));
  });

  test('reuses a bounded scope cache and refresh invalidates it', () async {
    final repository = _ImmediateRepository();
    final controller = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      ),
    );
    addTearDown(controller.dispose);

    controller.setTimeScope(const YearScope(2026));
    await Future<void>.value();
    controller.setTimeScope(const AllTimeScope());
    await Future<void>.value();
    controller.setTimeScope(const YearScope(2026));
    await Future<void>.value();

    expect(repository.reads, 2);
    expect(controller.state.result?.totalMinor, 100);

    controller.refresh();
    await Future<void>.value();
    expect(repository.reads, 3);
    expect(controller.state.result?.totalMinor, 100);
  });
}
