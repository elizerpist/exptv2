import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_repository.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_limit_edit_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_limit_quick_edit_gesture.dart';

void main() {
  group('BudgetLimitQuickEditGestureController', () {
    test('uses direction-epoch travel for exact drag step mapping', () {
      expect(
        BudgetLimitQuickEditRules.dragBatch(
          accumulator: 12,
          directionalTravel: 49,
          direction: 1,
        ),
        const BudgetLimitQuickEditBatch(
          direction: 1,
          tickCount: 1,
          amountStepScaled100: 100000,
          remainingAccumulator: 0,
        ),
      );
      expect(
        BudgetLimitQuickEditRules.dragBatch(
          accumulator: 36,
          directionalTravel: 50,
          direction: -1,
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
          directionalTravel: 1,
          direction: 1,
        ),
        isNull,
      );
    });

    test(
      'uses direction-epoch travel and semantic direction for auto-repeat',
      () {
        expect(
          BudgetLimitQuickEditRules.autoTickFor(
            directionalTravel: 13.9,
            lastAppliedSemanticDirection: 1,
          ),
          isNull,
        );
        expect(
          BudgetLimitQuickEditRules.autoTickFor(
            directionalTravel: 14,
            lastAppliedSemanticDirection: 1,
          ),
          const BudgetLimitQuickEditAutoTick(
            direction: 1,
            amountStepScaled100: 100000,
            interval: Duration(milliseconds: 367),
          ),
        );
        expect(
          BudgetLimitQuickEditRules.autoTickFor(
            directionalTravel: 50,
            lastAppliedSemanticDirection: -1,
          ),
          const BudgetLimitQuickEditAutoTick(
            direction: -1,
            amountStepScaled100: 1000000,
            interval: Duration(milliseconds: 180),
          ),
        );
      },
    );

    test(
      'very-long clear is armed after long press, remains editable, and defers persistence',
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
        expect(gesture.isEditing, isTrue);
        expect(harness.edits.effectiveLimitFor(harness.key, 200000), isNull);
        expect(harness.repository.deleteCalls, 0);
        expect(harness.repository.upsertCalls, 0);
        expect(haptics.last, BudgetLimitEditHaptic.heavy);
        scheduler.fire(BudgetLimitQuickEditRules.veryLongDelay);
        expect(
          haptics.where((value) => value == BudgetLimitEditHaptic.heavy),
          hasLength(1),
        );

        gesture.longPressMoved(globalY: 88);
        expect(
          harness.edits.effectiveLimitFor(harness.key, 200000),
          BudgetLimitQuickEditRules.smallStepScaled100,
        );
        expect(harness.repository.deleteCalls, 0);
        expect(harness.repository.upsertCalls, 0);
        await gesture.longPressEnded();
        expect(harness.repository.deleteCalls, 0);
        expect(harness.repository.upsertCalls, 1);
        expect(
          haptics.where((value) => value == BudgetLimitEditHaptic.heavy),
          hasLength(1),
        );
        expect(
          haptics.where((value) => value == BudgetLimitEditHaptic.selection),
          hasLength(1),
        );
      },
    );

    test(
      'very-long clear accepts upward then downward relative ticks in one pointer session',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        final scheduler = _ManualTimerScheduler();
        final gesture = BudgetLimitQuickEditGestureController(
          edits: harness.edits,
          contextForCurrentSelection: () => harness.context,
          scheduler: scheduler,
          haptic: (_) {},
        );
        addTearDown(gesture.dispose);

        gesture.longPressStarted(globalY: 100);
        scheduler.fire(BudgetLimitQuickEditRules.veryLongDelay);
        gesture.longPressMoved(globalY: 88);
        expect(harness.edits.effectiveLimitFor(harness.key, 200000), 100000);

        gesture.longPressMoved(globalY: 100);
        expect(harness.edits.effectiveLimitFor(harness.key, 200000), 0);
        expect(gesture.isEditing, isTrue);
        expect(harness.repository.deleteCalls, 0);
        expect(harness.repository.upsertCalls, 0);

        await gesture.longPressEnded();
        expect(harness.repository.deleteCalls, 0);
        expect(harness.repository.upsertCalls, 1);
        expect(harness.repository.lastUpsertAmount, 0);
      },
    );

    test(
      'very-long clear persists one delete only after the pointer ends',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        final scheduler = _ManualTimerScheduler();
        final gesture = BudgetLimitQuickEditGestureController(
          edits: harness.edits,
          contextForCurrentSelection: () => harness.context,
          scheduler: scheduler,
          haptic: (_) {},
        );
        addTearDown(gesture.dispose);

        gesture.longPressStarted(globalY: 100);
        scheduler.fire(BudgetLimitQuickEditRules.veryLongDelay);

        expect(gesture.isEditing, isTrue);
        expect(harness.edits.effectiveLimitFor(harness.key, 200000), isNull);
        expect(harness.repository.deleteCalls, 0);
        expect(harness.repository.upsertCalls, 0);

        await gesture.longPressEnded();

        expect(harness.repository.deleteCalls, 1);
        expect(harness.repository.upsertCalls, 0);
      },
    );

    test(
      'relative reversal below activation cancels stale auto and follows the new semantic direction',
      () {
        final harness = _Harness(confirmedLimitScaled100: 5000000);
        addTearDown(harness.dispose);
        final scheduler = _ManualTimerScheduler();
        final gesture = BudgetLimitQuickEditGestureController(
          edits: harness.edits,
          contextForCurrentSelection: () => harness.context,
          scheduler: scheduler,
          haptic: (_) {},
        );
        addTearDown(gesture.dispose);

        gesture.longPressStarted(globalY: 100);
        gesture.longPressMoved(
          globalY: 180,
        ); // Down 80px: four coarse -10k ticks.
        expect(harness.edits.effectiveLimitFor(harness.key, 5000000), 1000000);

        gesture.longPressMoved(
          globalY: 168,
        ); // Still below 100, but up 12px: +1k.
        expect(harness.edits.effectiveLimitFor(harness.key, 5000000), 1100000);
        gesture.longPressMoved(
          globalY: 166,
        ); // Up epoch reaches 14px and arms + auto.
        expect(scheduler.hasActive(const Duration(milliseconds: 367)), isTrue);

        gesture.longPressMoved(
          globalY: 178,
        ); // Reverse: down epoch is fine again.
        expect(harness.edits.effectiveLimitFor(harness.key, 5000000), 1000000);
        scheduler.fireCancelled(const Duration(milliseconds: 367));
        expect(harness.edits.effectiveLimitFor(harness.key, 5000000), 1000000);

        gesture.longPressMoved(
          globalY: 180,
        ); // New down epoch reaches auto threshold.
        scheduler.fire(const Duration(milliseconds: 367));
        expect(harness.edits.effectiveLimitFor(harness.key, 5000000), 900000);
      },
    );

    test('identical relative deltas ignore absolute pointer location', () {
      final first = _Harness();
      final second = _Harness();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final firstGesture = BudgetLimitQuickEditGestureController(
        edits: first.edits,
        contextForCurrentSelection: () => first.context,
        haptic: (_) {},
      );
      final secondGesture = BudgetLimitQuickEditGestureController(
        edits: second.edits,
        contextForCurrentSelection: () => second.context,
        haptic: (_) {},
      );
      addTearDown(firstGesture.dispose);
      addTearDown(secondGesture.dispose);

      firstGesture.longPressStarted(globalY: 100);
      firstGesture.longPressMoved(globalY: 112);
      firstGesture.longPressMoved(globalY: 100);

      secondGesture.longPressStarted(globalY: 420);
      secondGesture.longPressMoved(globalY: 432);
      secondGesture.longPressMoved(globalY: 420);

      expect(
        first.edits.effectiveLimitFor(first.key, 200000),
        second.edits.effectiveLimitFor(second.key, 200000),
      );
      expect(first.edits.effectiveLimitFor(first.key, 200000), 200000);
    });

    test(
      'downward movement decreases while the pointer remains above activation',
      () {
        final harness = _Harness(confirmedLimitScaled100: 2000000);
        addTearDown(harness.dispose);
        final gesture = BudgetLimitQuickEditGestureController(
          edits: harness.edits,
          contextForCurrentSelection: () => harness.context,
          haptic: (_) {},
        );
        addTearDown(gesture.dispose);

        gesture.longPressStarted(globalY: 300);
        gesture.longPressMoved(
          globalY: 220,
        ); // Up 80px: four coarse +10k ticks.
        expect(harness.edits.effectiveLimitFor(harness.key, 2000000), 6000000);

        gesture.longPressMoved(
          globalY: 232,
        ); // Still above 300, but down 12px: -1k.
        expect(harness.edits.effectiveLimitFor(harness.key, 2000000), 5900000);
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

  void fireCancelled(Duration duration) {
    final timer = _timers.firstWhere(
      (candidate) => candidate.duration == duration && candidate.cancelled,
    );
    timer.callback();
  }

  bool hasActive(Duration duration) =>
      _timers.any((timer) => timer.duration == duration && !timer.cancelled);
}

final class _Harness {
  _Harness({this.confirmedLimitScaled100 = 200000})
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
      confirmedLimitScaled100: confirmedLimitScaled100,
    );
  }

  final FinancialLimitKey key;
  final int confirmedLimitScaled100;
  final _Repository repository;
  late final DashboardBudgetLimitEditController edits;
  late final DashboardBudgetLimitEditContext context;

  void dispose() => edits.dispose();
}

final class _Repository implements FinancialLimitRepository {
  int upsertCalls = 0;
  int deleteCalls = 0;
  int? lastUpsertAmount;

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
    lastUpsertAmount = amountScaled100;
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
