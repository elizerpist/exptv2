import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_repository.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_limit_edit_controller.dart';

void main() {
  group('DashboardBudgetLimitEditController', () {
    test('keeps a draft local until one changed release write', () async {
      final key = _key();
      final repository = _CountingFinancialLimitRepository();
      final controller = DashboardBudgetLimitEditController(
        repository: repository,
        isKeyCurrent: (candidate) => candidate == key,
      );
      addTearDown(controller.dispose);

      final session = controller.startEdit(_context(key))!;
      controller.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 100000,
        tickCount: 3,
        source: DashboardBudgetLimitEditSource.drag,
      );

      expect(controller.effectiveLimitFor(key, 200000), 500000);
      expect(repository.getCalls, 0);
      expect(repository.listCalls, 0);
      expect(repository.upsertCalls, 0);
      expect(repository.deleteCalls, 0);

      await controller.finishEdit(session);

      expect(repository.upsertCalls, 1);
      expect(repository.lastUpsertAmount, 500000);
      expect(repository.deleteCalls, 0);
    });

    test(
      'a configured draft retains its confirmed amount until a semantic tick',
      () {
        final key = _key();
        final repository = _CountingFinancialLimitRepository();
        final controller = DashboardBudgetLimitEditController(
          repository: repository,
          isKeyCurrent: (candidate) => candidate == key,
        );
        addTearDown(controller.dispose);

        controller.startEdit(_context(key));

        expect(controller.effectiveLimitFor(key, 200000), 200000);
        expect(controller.value!.effectiveLimitScaled100, 200000);
        expect(repository.deleteCalls, 0);
        expect(repository.upsertCalls, 0);
      },
    );

    test(
      'an unchanged configured draft releases without any persistence',
      () async {
        final key = _key();
        final repository = _CountingFinancialLimitRepository();
        final controller = DashboardBudgetLimitEditController(
          repository: repository,
          isKeyCurrent: (candidate) => candidate == key,
        );
        addTearDown(controller.dispose);

        final session = controller.startEdit(_context(key))!;
        await controller.finishEdit(session);

        expect(controller.effectiveLimitFor(key, 200000), 200000);
        expect(repository.deleteCalls, 0);
        expect(repository.upsertCalls, 0);
      },
    );

    test(
      'an unconfigured draft starts at zero and persists its first positive tick',
      () async {
        final key = _key();
        final repository = _CountingFinancialLimitRepository();
        final controller = DashboardBudgetLimitEditController(
          repository: repository,
          isKeyCurrent: (candidate) => candidate == key,
        );
        addTearDown(controller.dispose);

        final session = controller.startEdit(
          DashboardBudgetLimitEditContext(
            key: key,
            coreRevision: 7,
            targetHandle: 1,
            actualScaled100: 100000,
            confirmedLimitScaled100: null,
          ),
        )!;
        controller.applySemanticTick(
          session,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );

        await controller.finishEdit(session);

        expect(repository.deleteCalls, 0);
        expect(repository.upsertCalls, 1);
        expect(repository.lastUpsertAmount, 100000);
      },
    );

    test(
      'tracks category allocation deltas incrementally across active and pending edits',
      () {
        final food = _key();
        final health = const FinancialLimitKey(
          direction: FinancialLimitDirection.expense,
          target: FinancialLimitCategoryTarget('health'),
          period: FinancialLimitMonthPeriod(2026, 7),
        );
        final repository = _CountingFinancialLimitRepository(deferWrites: true);
        final dynamic controller = DashboardBudgetLimitEditController(
          repository: repository,
          isKeyCurrent: (_) => true,
        );
        addTearDown(controller.dispose);

        final foodEdit = controller.startEdit(
          _contextFor(food, targetHandle: 1, confirmedLimitScaled100: 2500000),
        )!;
        controller.applySemanticTick(
          foodEdit,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        controller.finishEdit(foodEdit);

        final healthEdit = controller.startEdit(
          _contextFor(
            health,
            targetHandle: 2,
            confirmedLimitScaled100: 5000000,
          ),
        )!;
        controller.applySemanticTick(
          healthEdit,
          direction: -1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );

        final dynamic overlay = controller.categoryAllocationOverlayFor(
          direction: FinancialLimitDirection.expense,
          period: food.period,
        );
        expect(overlay.allocationDeltaScaled100, 0);
        expect(overlay.effectiveLimitForCategoryId('food'), 2600000);
        expect(overlay.effectiveLimitForCategoryId('health'), 4900000);
        expect(repository.upsertCalls, 1);
        expect(repository.deleteCalls, 0);
      },
    );

    test(
      'retains the newer draft while an older same-key write completes',
      () async {
        final key = _key();
        final repository = _CountingFinancialLimitRepository(deferWrites: true);
        final controller = DashboardBudgetLimitEditController(
          repository: repository,
          isKeyCurrent: (candidate) => candidate == key,
        );
        addTearDown(controller.dispose);

        final first = controller.startEdit(_context(key))!;
        controller.applySemanticTick(
          first,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        final firstWrite = controller.finishEdit(first);
        expect(repository.upsertCalls, 1);

        final second = controller.startEdit(_context(key))!;
        controller.applySemanticTick(
          second,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        final secondWrite = controller.finishEdit(second);

        repository.completeNextWrite();
        await firstWrite;
        expect(controller.effectiveLimitFor(key, 200000), 400000);

        repository.completeNextWrite();
        await secondWrite;
        expect(repository.upsertCalls, 2);
        expect(controller.effectiveLimitFor(key, 200000), 400000);
      },
    );

    test(
      'clears the optimistic overlay only after a matching later revision',
      () async {
        final key = _key();
        final repository = _CountingFinancialLimitRepository();
        final controller = DashboardBudgetLimitEditController(
          repository: repository,
          isKeyCurrent: (candidate) => candidate == key,
        );
        addTearDown(controller.dispose);

        final session = controller.startEdit(_context(key))!;
        controller.applySemanticTick(
          session,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        await controller.finishEdit(session);

        controller.observePreparedLimit(
          key: key,
          coreRevision: 7,
          confirmedLimitScaled100: 200000,
        );
        expect(controller.effectiveLimitFor(key, 200000), 300000);

        controller.observePreparedLimit(
          key: key,
          coreRevision: 8,
          confirmedLimitScaled100: 300000,
        );
        expect(controller.effectiveLimitFor(key, 300000), 300000);
        expect(controller.hasOverlayFor(key), isFalse);
      },
    );

    test(
      'structural invalidation never writes a captured value to another key',
      () async {
        final key = _key();
        var currentKey = key;
        final repository = _CountingFinancialLimitRepository();
        final controller = DashboardBudgetLimitEditController(
          repository: repository,
          isKeyCurrent: (candidate) => candidate == currentKey,
        );
        addTearDown(controller.dispose);

        final session = controller.startEdit(_context(key))!;
        controller.applySemanticTick(
          session,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        currentKey = _otherKey();
        await controller.finishEdit(session);

        expect(repository.upsertCalls, 0);
        expect(repository.deleteCalls, 0);
        expect(controller.effectiveLimitFor(key, 200000), 200000);
      },
    );

    test('persistence failure removes only its own optimistic value', () async {
      final key = _key();
      final repository = _CountingFinancialLimitRepository(failWrites: true);
      final controller = DashboardBudgetLimitEditController(
        repository: repository,
        isKeyCurrent: (candidate) => candidate == key,
      );
      addTearDown(controller.dispose);

      final session = controller.startEdit(_context(key))!;
      controller.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 100000,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.drag,
      );
      await controller.finishEdit(session);

      expect(controller.hasOverlayFor(key), isFalse);
      expect(controller.effectiveLimitFor(key, 200000), 200000);
    });

    test(
      'repeated downward ticks at the zero floor do not republish a no-op',
      () {
        final key = _key();
        final controller = DashboardBudgetLimitEditController(
          repository: _CountingFinancialLimitRepository(),
          isKeyCurrent: (candidate) => candidate == key,
        );
        addTearDown(controller.dispose);
        var publications = 0;
        controller.addListener(() => publications += 1);
        final session = controller.startEdit(_context(key))!;
        publications = 0;

        expect(
          controller.applySemanticTick(
            session,
            direction: -1,
            amountStepScaled100: 100000,
            tickCount: 2,
            source: DashboardBudgetLimitEditSource.drag,
          ),
          isTrue,
        );
        expect(controller.value!.effectiveLimitScaled100, 0);
        expect(publications, 1);

        expect(
          controller.applySemanticTick(
            session,
            direction: -1,
            amountStepScaled100: 100000,
            tickCount: 1,
            source: DashboardBudgetLimitEditSource.auto,
          ),
          isFalse,
        );
        expect(publications, 1);
        expect(controller.value!.effectiveLimitScaled100, 0);
      },
    );
  });
}

FinancialLimitKey _key() => const FinancialLimitKey(
  direction: FinancialLimitDirection.expense,
  target: FinancialLimitCategoryTarget('food'),
  period: FinancialLimitMonthPeriod(2026, 7),
);

FinancialLimitKey _otherKey() => const FinancialLimitKey(
  direction: FinancialLimitDirection.expense,
  target: FinancialLimitCategoryTarget('rent'),
  period: FinancialLimitMonthPeriod(2026, 7),
);

DashboardBudgetLimitEditContext _context(FinancialLimitKey key) =>
    _contextFor(key, targetHandle: 1, confirmedLimitScaled100: 200000);

DashboardBudgetLimitEditContext _contextFor(
  FinancialLimitKey key, {
  required int targetHandle,
  required int? confirmedLimitScaled100,
}) => DashboardBudgetLimitEditContext(
  key: key,
  coreRevision: 7,
  targetHandle: targetHandle,
  actualScaled100: 100000,
  confirmedLimitScaled100: confirmedLimitScaled100,
);

final class _CountingFinancialLimitRepository
    implements FinancialLimitRepository {
  _CountingFinancialLimitRepository({
    this.deferWrites = false,
    this.failWrites = false,
  });

  final bool deferWrites;
  final bool failWrites;
  final List<Completer<FinancialLimit>> _pendingUpserts =
      <Completer<FinancialLimit>>[];
  final List<Completer<bool>> _pendingDeletes = <Completer<bool>>[];
  int getCalls = 0;
  int listCalls = 0;
  int upsertCalls = 0;
  int deleteCalls = 0;
  int? lastUpsertAmount;

  @override
  Future<bool> delete(FinancialLimitKey key) {
    deleteCalls += 1;
    if (!deferWrites) return Future<bool>.value(true);
    final completer = Completer<bool>();
    _pendingDeletes.add(completer);
    return completer.future;
  }

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) {
    getCalls += 1;
    return Future<FinancialLimit?>.value(null);
  }

  @override
  Future<List<FinancialLimit>> list() {
    listCalls += 1;
    return Future<List<FinancialLimit>>.value(const <FinancialLimit>[]);
  }

  @override
  Future<FinancialLimit> upsert(FinancialLimitKey key, int amountScaled100) {
    upsertCalls += 1;
    lastUpsertAmount = amountScaled100;
    if (failWrites) return Future<FinancialLimit>.error(StateError('write'));
    FinancialLimit value() => FinancialLimit(
      key: key,
      amountScaled100: amountScaled100,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );
    if (!deferWrites) return Future<FinancialLimit>.value(value());
    final completer = Completer<FinancialLimit>();
    _pendingUpserts.add(completer);
    return completer.future;
  }

  void completeNextWrite() {
    if (_pendingUpserts.isNotEmpty) {
      final completer = _pendingUpserts.removeAt(0);
      completer.complete(
        FinancialLimit(
          key: _key(),
          amountScaled100: lastUpsertAmount ?? 0,
          createdAtUtcMs: 1,
          updatedAtUtcMs: 1,
        ),
      );
      return;
    }
    _pendingDeletes.removeAt(0).complete(true);
  }
}
