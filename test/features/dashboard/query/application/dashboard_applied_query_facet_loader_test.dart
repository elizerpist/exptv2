import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_applied_query_facet_loader.dart';
import 'package:fluvi/features/dashboard/query/data/query_menu_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'AMD-01: structural Year scope owns the active Mind amount domain',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final scopeChanges = ValueNotifier<int>(0);
      addTearDown(scopeChanges.dispose);
      final template = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final queries = CurrentQueryController(initialScope: template);
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final visible2027Scope = template.copyWith(
        timeScope: const YearScope(2027),
      );
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        scopeChanges: scopeChanges,
        activeDirection: () => direction.value,
        activeScopeForDirection: (_) => visible2027Scope,
        repository: repository,
      );
      addTearDown(loader.dispose);

      final loading = loader.start();

      expect(repository.requestedScopes, hasLength(1));
      expect(
        repository.requestedScopes.single.timeScope,
        const YearScope(2027),
        reason:
            'The adaptive range must query the visible 2027 scope rather '
            'than the all-time CurrentQuery template.',
      );
      repository.completeNext(_data(maximum: 1350000));
      await loading;

      expect(
        queries.amountDomainForScope(visible2027Scope)?.maximumAmountScaled100,
        1350000,
        reason:
            'The exact Fastfood 2027 maximum must be published against its '
            'own non-amount domain, not the 260,000 Ft all-time rent domain.',
      );
    },
  );

  test(
    'AMD-03: a visible structural scope change replaces the prior domain',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final scopeChanges = ValueNotifier<int>(0);
      addTearDown(scopeChanges.dispose);
      final template = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final queries = CurrentQueryController(initialScope: template);
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      var visibleScope = template.copyWith(timeScope: const YearScope(2027));
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        scopeChanges: scopeChanges,
        activeDirection: () => direction.value,
        activeScopeForDirection: (_) => visibleScope,
        repository: repository,
      );
      addTearDown(loader.dispose);

      final first = loader.start();
      repository.completeAt(0, _data(maximum: 1350000));
      await first;
      expect(
        queries.amountDomainForScope(visibleScope)?.maximumAmountScaled100,
        1350000,
      );

      visibleScope = template.copyWith(
        timeScope: const MonthScope(YearMonth(year: 2027, month: 5)),
      );
      scopeChanges.value += 1;
      await Future<void>.microtask(() {});

      expect(repository.requestedScopes, hasLength(2));
      expect(
        repository.requestedScopes.last.timeScope,
        const MonthScope(YearMonth(year: 2027, month: 5)),
      );
      expect(
        queries.amountDomainForScope(visibleScope),
        isNull,
        reason: 'The prior Year domain must never be reused for a Month.',
      );
    },
  );

  test(
    'publishes the initial applied Query domain into CurrentQueryController',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final queries = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: repository,
      );
      addTearDown(loader.dispose);

      final loading = loader.start();
      expect(repository.requestedScopes, hasLength(1));
      expect(queries.facetPresentationFor(LedgerDirection.expense), isNull);

      repository.completeNext(_data(maximum: 860000));
      await loading;

      expect(
        queries
            .facetPresentationFor(LedgerDirection.expense)
            ?.amountDomain
            .maximumAmountScaled100,
        860000,
      );
      expect(
        repository.requestedScopes,
        hasLength(2),
        reason:
            'The opposite canonical direction is warmed before a later tap.',
      );
      repository.completeAt(1, _data(maximum: 860000));
      await Future<void>.microtask(() {});
    },
  );

  test(
    'RED MYHR-10: a ready active canonical domain prewarms exactly one opposite direction before a direction tap',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.income);
      addTearDown(direction.dispose);
      final queries = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: repository,
      );
      addTearDown(loader.dispose);

      final active = loader.start();
      expect(repository.requestedScopes, hasLength(1));
      expect(
        repository.requestedScopes.single.direction,
        LedgerDirection.income,
      );
      repository.completeAt(0, _data(maximum: 860000));
      await active;
      await Future<void>.microtask(() {});

      expect(repository.requestedScopes, hasLength(2));
      expect(repository.requestedScopes[1].direction, LedgerDirection.expense);
      repository.completeAt(1, _data(maximum: 740000));
      await Future<void>.microtask(() {});
      expect(
        queries
            .amountDomainFor(LedgerDirection.expense)
            ?.maximumAmountScaled100,
        740000,
      );

      direction.value = LedgerDirection.expense;
      await Future<void>.microtask(() {});
      expect(
        repository.requestedScopes,
        hasLength(2),
        reason:
            'The user direction path activates the already-canonical domain; '
            'it performs no repository request.',
      );
    },
  );

  test(
    'RED MR-01: records the canonical Mind range request through publication',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final queries = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: repository,
      );
      addTearDown(loader.dispose);

      FluviDiagnosticLogger.clear();
      final operation = loader.start();

      expect(
        FluviDiagnosticLogger.entries.map((entry) => entry.stage),
        containsAllInOrder(<String>[
          'MIND|RANGE_REQUIRED',
          'MIND|RANGE_REQUEST',
          'MIND|RANGE_STATE',
        ]),
      );
      repository.completeNext(_data(maximum: 860000));
      await operation;

      final stages = FluviDiagnosticLogger.entries
          .map((entry) => entry.stage)
          .toList(growable: false);
      expect(
        stages,
        containsAllInOrder(<String>[
          'MIND|RANGE_REQUIRED',
          'MIND|RANGE_REQUEST',
          'MIND|RANGE_STATE',
          'MIND|RANGE_RESULT',
          'MIND|RANGE_PUBLISH',
          'MIND|RANGE_STATE',
        ]),
      );
      expect(
        FluviDiagnosticLogger.entries
            .lastWhere((entry) => entry.stage == 'MIND|RANGE_STATE')
            .scope,
        contains('state=ready'),
      );
    },
  );

  test(
    'MR-02: a terminal range failure is explicit rather than remaining loading',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final queries = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: repository,
      );
      addTearDown(loader.dispose);

      FluviDiagnosticLogger.clear();
      final operation = loader.start();
      repository.failNext(StateError('native facets unavailable'));
      await operation;

      expect(loader.state, DashboardAppliedQueryFacetLoadState.failed);
      expect(loader.isLoading, isFalse);
      expect(loader.error, isA<StateError>());
      expect(
        FluviDiagnosticLogger.entries
            .lastWhere((entry) => entry.stage == 'MIND|RANGE_STATE')
            .scope,
        contains('state=failed'),
      );
    },
  );

  test(
    'MR-02: a direct retry reuses the canonical scope and can publish ready',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final queries = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: repository,
      );
      addTearDown(loader.dispose);

      FluviDiagnosticLogger.clear();
      final first = loader.start();
      repository.failNext(StateError('native facets unavailable'));
      await first;
      expect(loader.state, DashboardAppliedQueryFacetLoadState.failed);

      final retry = loader.retry();
      expect(repository.requestedScopes, hasLength(2));
      repository.completeAt(1, _data(maximum: 970000));
      await retry;

      expect(loader.state, DashboardAppliedQueryFacetLoadState.ready);
      expect(
        queries
            .facetPresentationFor(LedgerDirection.expense)
            ?.amountDomain
            .maximumAmountScaled100,
        970000,
      );
    },
  );

  test(
    'drops an old-direction facet completion instead of replacing current domain',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final queries = CurrentQueryController(
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: AllTimeScope(),
        ),
      );
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: repository,
      );
      addTearDown(loader.dispose);

      FluviDiagnosticLogger.clear();
      final first = loader.start();
      direction.value = LedgerDirection.income;
      await Future<void>.microtask(() {});
      expect(repository.requestedScopes, hasLength(2));

      repository.completeAt(0, _data(maximum: 300000));
      repository.completeAt(1, _data(maximum: 970000));
      await first;
      await loader.whenIdle;

      expect(queries.facetPresentationFor(LedgerDirection.expense), isNull);
      expect(
        queries
            .facetPresentationFor(LedgerDirection.income)
            ?.amountDomain
            .maximumAmountScaled100,
        970000,
      );
      expect(
        FluviDiagnosticLogger.entries
            .lastWhere((entry) => entry.stage == 'MIND|RANGE_REJECT')
            .scope,
        contains('reason=superseded'),
        reason:
            'MR-01: an old directional result must identify why canonical '
            'publication was rejected rather than silently leaving Mind blank.',
      );
    },
  );

  test(
    'amount-only applied changes reuse one non-amount domain without loading or refetch',
    () async {
      final direction = ValueNotifier<LedgerDirection>(LedgerDirection.expense);
      addTearDown(direction.dispose);
      final initial = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: AllTimeScope(),
        refinements: const <String, Object?>{'minimumAmountScaled100': 200000},
      );
      final queries = CurrentQueryController(initialScope: initial);
      addTearDown(queries.dispose);
      final repository = _DeferredRepository();
      final loader = DashboardAppliedQueryFacetLoader(
        currentQuery: queries,
        directionChanges: direction,
        activeDirection: () => direction.value,
        repository: repository,
      );
      addTearDown(loader.dispose);

      final first = loader.start();
      expect(repository.requestedScopes.single.refinements, isEmpty);
      repository.completeNext(_data(maximum: 26000000));
      await first;
      expect(loader.state, DashboardAppliedQueryFacetLoadState.ready);
      expect(repository.requestedScopes, hasLength(2));
      repository.completeAt(1, _data(maximum: 26000000));
      await Future<void>.microtask(() {});

      queries.replaceDirection(
        LedgerDirection.expense,
        initial.copyWith(
          refinements: const <String, Object?>{
            'minimumAmountScaled100': 700000,
            'maximumAmountScaled100': 1500000,
          },
        ),
      );
      await Future<void>.microtask(() {});

      expect(repository.requestedScopes, hasLength(2));
      expect(loader.state, DashboardAppliedQueryFacetLoadState.ready);
      expect(queries.amountDomainFor(LedgerDirection.expense), isNotNull);
    },
  );
}

QueryMenuData _data({required int maximum}) => QueryMenuData(
  result: const QueryMenuResultSummary(entryCount: 4, amountScaled100: 1),
  amountDomain: QueryMenuAmountDomain(
    minimumAmountScaled100: 100000,
    maximumAmountScaled100: maximum,
  ),
  availableMonths: const <QueryMenuAvailableMonth>[],
  categories: const <QueryMenuCategoryFacet>[],
  partners: const <QueryMenuPartnerFacet>[],
);

final class _DeferredRepository implements QueryMenuRepository {
  final List<CurrentLedgerQueryScope> requestedScopes =
      <CurrentLedgerQueryScope>[];
  final List<Completer<QueryMenuData>> _pending = <Completer<QueryMenuData>>[];

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope scope) {
    requestedScopes.add(scope);
    final pending = Completer<QueryMenuData>();
    _pending.add(pending);
    return pending.future;
  }

  void completeNext(QueryMenuData data) => completeAt(0, data);

  void completeAt(int index, QueryMenuData data) =>
      _pending[index].complete(data);

  void failNext(Object error) => _pending.first.completeError(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
