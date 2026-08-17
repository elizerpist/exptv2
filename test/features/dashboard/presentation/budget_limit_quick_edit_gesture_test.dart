import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_repository.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_limit_edit_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_limit_quick_edit_gesture.dart';

void main() {
  group('BudgetLimitQuickEditGestureController', () {
    test('uses the exact drag distance and scaled-100 HUF step mapping', () {
      expect(
        BudgetLimitQuickEditRules.dragBatch(accumulator: 12, totalDistance: 49),
        const BudgetLimitQuickEditBatch(
          direction: 1,
          tickCount: 1,
          amountStepScaled100: 100000,
          remainingAccumulator: 0,
        ),
      );
      expect(
        BudgetLimitQuickEditRules.dragBatch(
          accumulator: -36,
          totalDistance: 50,
        ),
        const BudgetLimitQuickEditBatch(
          direction: -1,
          tickCount: 2,
          amountStepScaled100: 1000000,
          remainingAccumulator: 0,
        ),
      );
      expect(
        BudgetLimitQuickEditRules.dragBatch(
          accumulator: 11.9,
          totalDistance: 1,
        ),
        isNull,
      );
    });

    test('uses the exact auto-repeat threshold, interval, sign and step', () {
      expect(BudgetLimitQuickEditRules.autoTickFor(13.9), isNull);
      expect(
        BudgetLimitQuickEditRules.autoTickFor(-14),
        const BudgetLimitQuickEditAutoTick(
          direction: 1,
          amountStepScaled100: 100000,
          interval: Duration(milliseconds: 367),
        ),
      );
      expect(
        BudgetLimitQuickEditRules.autoTickFor(50),
        const BudgetLimitQuickEditAutoTick(
          direction: -1,
          amountStepScaled100: 1000000,
          interval: Duration(milliseconds: 180),
        ),
      );
    });

    test(
      'very-long delete is armed after long press and cancelled by 5px move',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        final scheduler = _ManualTimerScheduler();
        final haptics = <BudgetLimitEditHaptic>[];
        final gesture = BudgetLimitQuickEditGestureController(
          edits: harness.edits,
          contextForCurrentSelection: () => harness.context,
          scheduler: scheduler,
          haptic: haptics.add,
        );
        addTearDown(gesture.dispose);

        gesture.longPressStarted(globalY: 100);
        expect(haptics, <BudgetLimitEditHaptic>[BudgetLimitEditHaptic.medium]);
        gesture.longPressMoved(globalY: 106);
        expect(scheduler.hasActive(const Duration(milliseconds: 720)), isFalse);
        expect(harness.repository.deleteCalls, 0);

        gesture.longPressEnded();
        gesture.longPressStarted(globalY: 100);
        scheduler.fire(const Duration(milliseconds: 720));
        await Future<void>.delayed(Duration.zero);
        expect(harness.repository.deleteCalls, 1);
        expect(haptics.last, BudgetLimitEditHaptic.heavy);
        await gesture.longPressEnded();
        expect(harness.repository.upsertCalls, 0);
      },
    );

    test(
      'semantic ticks have one haptic per batch and persist once on release',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        final haptics = <BudgetLimitEditHaptic>[];
        final gesture = BudgetLimitQuickEditGestureController(
          edits: harness.edits,
          contextForCurrentSelection: () => harness.context,
          haptic: haptics.add,
        );
        addTearDown(gesture.dispose);

        gesture.longPressStarted(globalY: 100);
        gesture.longPressMoved(globalY: 64); // 36px up => 3 coalesced 1k ticks.
        expect(
          haptics.where((value) => value == BudgetLimitEditHaptic.selection),
          hasLength(1),
        );
        expect(harness.edits.effectiveLimitFor(harness.key, 200000), 500000);
        expect(harness.repository.upsertCalls, 0);
        await gesture.longPressEnded();
        expect(harness.repository.upsertCalls, 1);
      },
    );
  });
}

final class _ManualTimer implements BudgetLimitEditTimer {
  _ManualTimer(this.duration, this.callback);

  final Duration duration;
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;
}

final class _ManualTimerScheduler implements BudgetLimitEditTimerScheduler {
  final List<_ManualTimer> _timers = <_ManualTimer>[];

  @override
  BudgetLimitEditTimer schedule(Duration duration, void Function() callback) {
    final timer = _ManualTimer(duration, callback);
    _timers.add(timer);
    return timer;
  }

  void fire(Duration duration) {
    final timer = _timers.firstWhere(
      (candidate) => candidate.duration == duration && !candidate.cancelled,
    );
    timer.callback();
  }

  bool hasActive(Duration duration) =>
      _timers.any((timer) => timer.duration == duration && !timer.cancelled);
}

final class _Harness {
  _Harness()
    : key = const FinancialLimitKey(
        direction: FinancialLimitDirection.expense,
        target: FinancialLimitCategoryTarget('food'),
        period: FinancialLimitMonthPeriod(2026, 7),
      ),
      repository = _Repository() {
    edits = DashboardBudgetLimitEditController(
      repository: repository,
      isKeyCurrent: (candidate) => candidate == key,
    );
    context = DashboardBudgetLimitEditContext(
      key: key,
      coreRevision: 7,
      targetHandle: 1,
      actualScaled100: 100000,
      confirmedLimitScaled100: 200000,
    );
  }

  final FinancialLimitKey key;
  final _Repository repository;
  late final DashboardBudgetLimitEditController edits;
  late final DashboardBudgetLimitEditContext context;

  void dispose() => edits.dispose();
}

final class _Repository implements FinancialLimitRepository {
  int upsertCalls = 0;
  int deleteCalls = 0;

  @override
  Future<bool> delete(FinancialLimitKey key) {
    deleteCalls += 1;
    return Future<bool>.value(true);
  }

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) =>
      Future<FinancialLimit?>.value(null);

  @override
  Future<List<FinancialLimit>> list() =>
      Future<List<FinancialLimit>>.value(const <FinancialLimit>[]);

  @override
  Future<FinancialLimit> upsert(FinancialLimitKey key, int amountScaled100) {
    upsertCalls += 1;
    return Future<FinancialLimit>.value(
      FinancialLimit(
        key: key,
        amountScaled100: amountScaled100,
        createdAtUtcMs: 1,
        updatedAtUtcMs: 1,
      ),
    );
  }
}
