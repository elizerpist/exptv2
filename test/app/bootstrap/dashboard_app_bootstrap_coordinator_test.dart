import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/bootstrap/dashboard_app_bootstrap_coordinator.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';

class _NeverReturningDashboardRepository implements DashboardLedgerRepository {
  const _NeverReturningDashboardRepository();

  @override
  Future<DashboardLedgerResult> read(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => Completer<DashboardLedgerResult>().future;

  @override
  Stream<DashboardLedgerResult> watch(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => const Stream<DashboardLedgerResult>.empty();
}

class _ReadyDashboardRepository
    implements
        DashboardLedgerRepository,
        DashboardLedgerFirstPagePrefetchRepository {
  const _ReadyDashboardRepository();

  DashboardLedgerResult _result(CurrentLedgerQueryScope scope) =>
      DashboardLedgerResult(totalMinor: 0, scopeKey: scope.key.value);

  @override
  Future<DashboardLedgerResult> read(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => _result(scope);

  @override
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    scope, {
    int maxDayGroups = 7,
  }) async => _result(scope);

  @override
  Stream<DashboardLedgerResult> watch(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    yield _result(scope);
  }
}

void main() {
  test(
    'seed completion precedes construction of the first dashboard query',
    () async {
      final operations = <String>[];
      final coordinator = DashboardAppBootstrapCoordinator(
        seedDemo: () async {
          operations.add('seed:start');
          await Future<void>.delayed(Duration.zero);
          operations.add('seed:ready');
        },
        createController: ({required initialDate, required autoStart}) {
          operations.add('controller:autoStart=$autoStart');
          expect(initialDate, DateTime(2026, 7, 3));
          return DashboardCoreController(
            initialDate: initialDate,
            autoStart: autoStart,
            queryRepository: const _ReadyDashboardRepository(),
          );
        },
      );

      final result = await coordinator.bootstrap();
      expect(result, isNotNull);
      final dashboard = result!;
      addTearDown(dashboard.controller.dispose);

      expect(dashboard.usedFallback, isFalse);
      expect(operations, [
        'seed:start',
        'seed:ready',
        'controller:autoStart=false',
      ]);
      expect(
        dashboard.controller.query.state.scope.timeScope.canonicalKey,
        'month:2026-07',
      );
    },
  );

  test(
    'bootstrap timeout exposes the legacy shell instead of a permanent blank',
    () async {
      final autoStartValues = <bool>[];
      final coordinator = DashboardAppBootstrapCoordinator(
        displayBootstrapTimeout: Duration.zero,
        createController: ({required initialDate, required autoStart}) {
          autoStartValues.add(autoStart);
          return DashboardCoreController(
            initialDate: initialDate,
            autoStart: autoStart,
            queryRepository: const _NeverReturningDashboardRepository(),
          );
        },
      );

      final result = await coordinator.bootstrap();
      expect(result, isNotNull);
      final dashboard = result!;
      addTearDown(dashboard.controller.dispose);

      expect(dashboard.usedFallback, isTrue);
      expect(autoStartValues, [false, true]);
    },
  );

  test(
    'cancelling bootstrap releases the outstanding display timeout',
    () async {
      final coordinator = DashboardAppBootstrapCoordinator(
        displayBootstrapTimeout: const Duration(hours: 1),
        createController: ({required initialDate, required autoStart}) =>
            DashboardCoreController(
              initialDate: initialDate,
              autoStart: autoStart,
              queryRepository: const _NeverReturningDashboardRepository(),
            ),
      );

      final result = coordinator.bootstrap();
      coordinator.cancel();

      expect(await result, isNull);
    },
  );
}
