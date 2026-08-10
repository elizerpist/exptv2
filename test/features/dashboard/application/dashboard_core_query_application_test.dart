import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/data/empty_dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'direction selection synchronizes the applied Query before opening a draft',
    () async {
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialCoreRevision: 1,
        initialDirection: LedgerDirection.income,
      );
      addTearDown(core.dispose);
      await core.bootstrap();

      core.selectDirection(TransactionDirection.expense);
      core.queryComposer.open();

      expect(
        core.presentation.navigation.state.parentQueryScope.direction,
        LedgerDirection.expense,
      );
      expect(core.currentQuery.scope.direction, LedgerDirection.expense);
      expect(core.queryComposer.draft.direction, LedgerDirection.expense);
    },
  );

  test('direction selection is ignored while a Query draft is open', () async {
    final core = DashboardCoreController(
      initialDate: DateTime(2025, 7, 14),
      initialCoreRevision: 1,
      initialDirection: LedgerDirection.expense,
    );
    addTearDown(core.dispose);
    await core.bootstrap();
    core.queryComposer.open();
    final draft = core.queryComposer.draft.copyWith(
      categoryIds: const <String>{'food'},
    );
    core.queryComposer.updateDraft(scope: draft);

    core.selectDirection(TransactionDirection.income);

    expect(
      core.presentation.navigation.state.parentQueryScope.direction,
      LedgerDirection.expense,
    );
    expect(core.currentQuery.scope.direction, LedgerDirection.expense);
    expect(core.queryComposer.draft, draft);
  });

  test(
    'Apply publishes one prepared restricted query scope atomically',
    () async {
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
      expect(
        core.navigation.state.parentQueryScope.temporalFilter,
        draft.temporalFilter,
      );
      expect(core.navigation.temporalAvailability.allowedYears, <int>[
        2024,
        2026,
      ]);
      expect(
        core.preparedIndex?.key.temporalFilterKey,
        draft.temporalFilter.canonicalKey,
      );
    },
  );

  test(
    'a failed Query index preparation returns false and can be retried',
    () async {
      final repository = _FailOnceQueryIndexRepository();
      final core = DashboardCoreController(
        dataRepository: repository,
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
          QueryPeriodSelection.year(2024),
          QueryPeriodSelection.year(2026),
        }),
      );

      expect(await core.applyQuery(draft), isFalse);
      expect(core.currentQuery.scope.temporalFilter.isRestrictive, isFalse);

      expect(await core.applyQuery(draft), isTrue);
      expect(repository.queryPreparationCount, 2);
      expect(core.currentQuery.scope, draft);
    },
  );

  test('concurrent Apply intents share one Query index preparation', () async {
    final repository = _BlockingQueryIndexRepository();
    final core = DashboardCoreController(
      dataRepository: repository,
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
        QueryPeriodSelection.year(2024),
        QueryPeriodSelection.year(2026),
      }),
    );

    final first = core.applyQuery(draft);
    final second = core.applyQuery(draft);

    expect(identical(first, second), isTrue);
    expect(repository.queryPreparationCount, 1);

    await repository.completeQueryPreparation();

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(repository.queryPreparationCount, 1);
  });
}

final class _FailOnceQueryIndexRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  var queryPreparationCount = 0;
  var _failNextQuery = true;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason == DataAcquisitionReason.query) {
      queryPreparationCount += 1;
      if (_failNextQuery) {
        _failNextQuery = false;
        return Future<PreparedDashboardIndex>.error(
          StateError('synthetic query prepare failure'),
        );
      }
    }
    return _empty.prepareIndex(request, token);
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}

final class _BlockingQueryIndexRepository
    implements DashboardDataRuntimeRepository {
  final EmptyDashboardDataRuntimeRepository _empty =
      const EmptyDashboardDataRuntimeRepository();
  var queryPreparationCount = 0;
  PreparedDashboardIndexRequest? _pendingRequest;
  DashboardIndexPreparationToken? _pendingToken;
  Completer<PreparedDashboardIndex>? _pendingCompletion;

  @override
  Stream<int> watchCoreRevision() => Stream<int>.value(1);

  @override
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  ) {
    if (request.reason != DataAcquisitionReason.query) {
      return _empty.prepareIndex(request, token);
    }
    queryPreparationCount += 1;
    _pendingRequest = request;
    _pendingToken = token;
    final completion = Completer<PreparedDashboardIndex>();
    _pendingCompletion = completion;
    return completion.future;
  }

  Future<void> completeQueryPreparation() async {
    final request = _pendingRequest;
    final token = _pendingToken;
    final completion = _pendingCompletion;
    if (request == null || token == null || completion == null) {
      throw StateError('No Query preparation is pending.');
    }
    completion.complete(await _empty.prepareIndex(request, token));
  }

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) => _empty.readCommittedPage(request);

  @override
  Map<String, Object?> performanceReport() => _empty.performanceReport();
}
