import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/financial_limits/domain/financial_limit.dart';
import '../../../core/financial_limits/domain/financial_limit_repository.dart';
import 'dashboard_budget_scope_analysis.dart';

/// Semantic source of a single limit increment. Raw pointer tracking belongs
/// to the presentation input shell; this controller only owns scalar draft and
/// persistence state.
enum DashboardBudgetLimitEditSource { drag, auto }

/// Shared input boundary for the one existing long-press/vertical-swipe
/// gesture. It intentionally has scalar and derived-YEAR variants rather than
/// inventing a persisted annual FinancialLimit key.
sealed class DashboardBudgetEditContext {
  const DashboardBudgetEditContext();
}

abstract interface class DashboardBudgetEditableSession {}

/// Exact immutable state captured when a quick edit begins. The current
/// prepared header has already resolved this from RAM, so an editor never needs
/// a repository read to start.
@immutable
final class DashboardBudgetLimitEditContext extends DashboardBudgetEditContext {
  const DashboardBudgetLimitEditContext({
    required this.key,
    required this.coreRevision,
    required this.targetHandle,
    required this.actualScaled100,
    required this.confirmedLimitScaled100,
  }) : super();

  final FinancialLimitKey key;
  final int coreRevision;
  final int targetHandle;

  /// Canonical accounting actual, intentionally nullable for a SUM base-limit
  /// edit whose presentation numerator is a typical-month statistic.
  final int? actualScaled100;
  final int? confirmedLimitScaled100;
}

@immutable
final class DashboardBudgetLimitEditSession
    implements DashboardBudgetEditableSession {
  const DashboardBudgetLimitEditSession._({
    required this.generation,
    required this.context,
    required this.baseLimitScaled100,
    required this.effectiveLimitScaled100,
  });

  final int generation;
  final DashboardBudgetLimitEditContext context;
  final int? baseLimitScaled100;
  final int? effectiveLimitScaled100;

  DashboardBudgetLimitEditSession copyWith({
    required int effectiveLimitScaled100,
  }) => DashboardBudgetLimitEditSession._(
    generation: generation,
    context: context,
    baseLimitScaled100: baseLimitScaled100,
    effectiveLimitScaled100: effectiveLimitScaled100,
  );
}

/// A derived annual edit is represented by the twelve concrete override keys
/// it will atomically write. No independent YEAR row can be formed from this
/// context.
@immutable
final class DashboardBudgetYearLimitEditContext
    extends DashboardBudgetEditContext {
  DashboardBudgetYearLimitEditContext({
    required this.direction,
    required this.target,
    required this.coreRevision,
    required this.targetHandle,
    required this.year,
    required List<FinancialLimitKey> monthOverrideKeys,
    required List<int> confirmedMonthlyLimitsScaled100,
    required this.canonicalAnnualActualScaled100,
  }) : monthOverrideKeys = List<FinancialLimitKey>.unmodifiable(
         monthOverrideKeys,
       ),
       confirmedMonthlyLimitsScaled100 = List<int>.unmodifiable(
         confirmedMonthlyLimitsScaled100,
       ),
       super() {
    if (this.monthOverrideKeys.length != 12 ||
        this.confirmedMonthlyLimitsScaled100.length != 12) {
      throw ArgumentError('A YEAR edit requires exactly twelve month cells.');
    }
    for (var index = 0; index < 12; index += 1) {
      final period = this.monthOverrideKeys[index].period;
      if (period is! FinancialLimitMonthOverridePeriod ||
          period.year != year ||
          period.month != index + 1) {
        throw ArgumentError('YEAR edits must own Jan–Dec month overrides.');
      }
    }
  }

  final FinancialLimitDirection direction;
  final FinancialLimitTarget target;
  final int coreRevision;
  final int targetHandle;
  final int year;
  final List<FinancialLimitKey> monthOverrideKeys;
  final List<int> confirmedMonthlyLimitsScaled100;
  final int canonicalAnnualActualScaled100;

  int get confirmedAnnualLimitScaled100 =>
      confirmedMonthlyLimitsScaled100.fold<int>(0, (sum, value) => sum + value);
}

final class DashboardBudgetYearLimitEditSession
    implements DashboardBudgetEditableSession {
  DashboardBudgetYearLimitEditSession._({
    required this.generation,
    required this.context,
    required this.baseMonthlyLimitsScaled100,
    required this.effectiveMonthlyLimitsScaled100,
  });

  final int generation;
  final DashboardBudgetYearLimitEditContext context;
  final List<int> baseMonthlyLimitsScaled100;
  final List<int> effectiveMonthlyLimitsScaled100;

  int get effectiveAnnualLimitScaled100 =>
      effectiveMonthlyLimitsScaled100.fold<int>(0, (sum, value) => sum + value);

  DashboardBudgetYearLimitEditSession copyWith({
    required List<int> effectiveMonthlyLimitsScaled100,
  }) => DashboardBudgetYearLimitEditSession._(
    generation: generation,
    context: context,
    baseMonthlyLimitsScaled100: baseMonthlyLimitsScaled100,
    effectiveMonthlyLimitsScaled100: List<int>.unmodifiable(
      effectiveMonthlyLimitsScaled100,
    ),
  );
}

/// Narrow selected-target state. The immutable target catalog and prepared
/// snapshot are intentionally outside this listenable.
@immutable
final class DashboardBudgetLimitEditPresentation {
  const DashboardBudgetLimitEditPresentation({
    required this.key,
    required this.coreRevision,
    required this.targetHandle,
    required this.actualScaled100,
    required this.effectiveLimitScaled100,
    required this.generation,
  });

  final FinancialLimitKey key;
  final int coreRevision;
  final int targetHandle;
  final int actualScaled100;
  final int? effectiveLimitScaled100;
  final int generation;
}

/// Narrow immutable category overlay for one direction and persisted limit
/// period. It contains only active/pending category edits, never a projection
/// of the prepared category bank.
@immutable
final class DashboardBudgetCategoryAllocationOverlay {
  const DashboardBudgetCategoryAllocationOverlay._({
    required this.allocationDeltaScaled100,
    required this.effectiveLimitByCategoryId,
  });

  static const empty = DashboardBudgetCategoryAllocationOverlay._(
    allocationDeltaScaled100: 0,
    effectiveLimitByCategoryId: <String, int>{},
  );

  final int allocationDeltaScaled100;
  final Map<String, int> effectiveLimitByCategoryId;

  bool hasOverrideForCategoryId(String categoryId) =>
      effectiveLimitByCategoryId.containsKey(categoryId);

  int? effectiveLimitForCategoryId(String categoryId) =>
      effectiveLimitByCategoryId[categoryId];
}

final class _PendingBudgetLimitMutation {
  const _PendingBudgetLimitMutation({
    required this.generation,
    required this.baseCoreRevision,
    required this.intendedLimitScaled100,
    required this.confirmedLimitScaled100,
  });

  final int generation;
  final int baseCoreRevision;
  final int intendedLimitScaled100;
  final int? confirmedLimitScaled100;
}

final class _BudgetYearEditIdentity {
  const _BudgetYearEditIdentity({
    required this.direction,
    required this.target,
    required this.year,
  });

  final FinancialLimitDirection direction;
  final FinancialLimitTarget target;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is _BudgetYearEditIdentity &&
      other.direction == direction &&
      other.target == target &&
      other.year == year;

  @override
  int get hashCode => Object.hash(direction, target, year);
}

final class _PendingBudgetYearMutation {
  const _PendingBudgetYearMutation({
    required this.generation,
    required this.baseCoreRevision,
    required this.intendedMonthlyLimitsScaled100,
  });

  final int generation;
  final int baseCoreRevision;
  final List<int> intendedMonthlyLimitsScaled100;
}

final class _BudgetCategoryAllocationScope {
  const _BudgetCategoryAllocationScope({
    required this.direction,
    required this.period,
  });

  final FinancialLimitDirection direction;
  final FinancialLimitPeriod period;

  @override
  bool operator ==(Object other) =>
      other is _BudgetCategoryAllocationScope &&
      other.direction == direction &&
      other.period == period;

  @override
  int get hashCode => Object.hash(direction, period);
}

final class _BudgetCategoryAllocationContribution {
  const _BudgetCategoryAllocationContribution({
    required this.confirmedLimitScaled100,
    required this.effectiveLimitScaled100,
  });

  final int? confirmedLimitScaled100;
  final int effectiveLimitScaled100;

  int get deltaScaled100 =>
      _positiveLimit(effectiveLimitScaled100) -
      _positiveLimit(confirmedLimitScaled100);
}

final class _BudgetCategoryAllocationBucket {
  final Map<String, _BudgetCategoryAllocationContribution> _contributions =
      <String, _BudgetCategoryAllocationContribution>{};
  final Map<String, int> _effectiveLimitByCategoryId = <String, int>{};
  late final Map<String, int> _effectiveLimitView =
      UnmodifiableMapView<String, int>(_effectiveLimitByCategoryId);
  var _allocationDeltaScaled100 = 0;
  DashboardBudgetCategoryAllocationOverlay _overlay =
      DashboardBudgetCategoryAllocationOverlay.empty;

  DashboardBudgetCategoryAllocationOverlay get overlay => _overlay;
  bool get isEmpty => _contributions.isEmpty;

  void replace({
    required String categoryId,
    required int? confirmedLimitScaled100,
    required int effectiveLimitScaled100,
  }) {
    final previous = _contributions[categoryId];
    if (previous != null) {
      _allocationDeltaScaled100 -= previous.deltaScaled100;
    }
    if (effectiveLimitScaled100 == confirmedLimitScaled100) {
      _contributions.remove(categoryId);
      _effectiveLimitByCategoryId.remove(categoryId);
    } else {
      final next = _BudgetCategoryAllocationContribution(
        confirmedLimitScaled100: confirmedLimitScaled100,
        effectiveLimitScaled100: effectiveLimitScaled100,
      );
      _contributions[categoryId] = next;
      _effectiveLimitByCategoryId[categoryId] = effectiveLimitScaled100;
      _allocationDeltaScaled100 += next.deltaScaled100;
    }
    _publishOverlay();
  }

  void remove(String categoryId) {
    final previous = _contributions.remove(categoryId);
    if (previous == null) return;
    _allocationDeltaScaled100 -= previous.deltaScaled100;
    _effectiveLimitByCategoryId.remove(categoryId);
    _publishOverlay();
  }

  void _publishOverlay() {
    if (_contributions.isEmpty) {
      _overlay = DashboardBudgetCategoryAllocationOverlay.empty;
      return;
    }
    _overlay = DashboardBudgetCategoryAllocationOverlay._(
      allocationDeltaScaled100: _allocationDeltaScaled100,
      // The read-only view retains bucket identity while one semantic tick
      // changes only its one category key. Do not rebuild an N-category map
      // on the input hot path.
      effectiveLimitByCategoryId: _effectiveLimitView,
    );
  }
}

int _positiveLimit(int? value) => value != null && value > 0 ? value : 0;

/// Headless application owner for optimistic Budget quick-limit edits.
///
/// It never reads limits: start values come from [DashboardBudgetLimitEditContext]
/// and exact later revisions reconcile writes. One direct key lookup supplies
/// the effective value for header and ring rendering alike.
final class DashboardBudgetLimitEditController
    extends ValueNotifier<DashboardBudgetLimitEditPresentation?> {
  DashboardBudgetLimitEditController({
    required FinancialLimitRepository repository,
    required bool Function(FinancialLimitKey key) isKeyCurrent,
    bool Function(DashboardBudgetYearLimitEditContext context)?
    isYearContextCurrent,
  }) : _repository = repository,
       _isKeyCurrent = isKeyCurrent,
       _isYearContextCurrent = isYearContextCurrent ?? _neverCurrentYear,
       super(null);

  final FinancialLimitRepository _repository;
  final bool Function(FinancialLimitKey key) _isKeyCurrent;
  final bool Function(DashboardBudgetYearLimitEditContext context)
  _isYearContextCurrent;
  final Map<FinancialLimitKey, _PendingBudgetLimitMutation> _pendingByKey =
      <FinancialLimitKey, _PendingBudgetLimitMutation>{};
  final Map<FinancialLimitKey, Future<void>> _writeTailByKey =
      <FinancialLimitKey, Future<void>>{};
  final Map<_BudgetYearEditIdentity, _PendingBudgetYearMutation>
  _pendingYearByIdentity =
      <_BudgetYearEditIdentity, _PendingBudgetYearMutation>{};
  final Map<_BudgetYearEditIdentity, Future<void>> _yearWriteTailByIdentity =
      <_BudgetYearEditIdentity, Future<void>>{};
  final Map<_BudgetCategoryAllocationScope, _BudgetCategoryAllocationBucket>
  _categoryAllocationByScope =
      <_BudgetCategoryAllocationScope, _BudgetCategoryAllocationBucket>{};
  final Map<_BudgetCategoryAllocationScope, int>
  _lastReconciledCategoryAllocationRevisionByScope =
      <_BudgetCategoryAllocationScope, int>{};

  DashboardBudgetLimitEditSession? _active;
  DashboardBudgetYearLimitEditSession? _activeYear;
  int _nextGeneration = 0;
  bool _disposed = false;

  static bool _neverCurrentYear(DashboardBudgetYearLimitEditContext _) => false;

  DashboardBudgetLimitEditSession? startEdit(
    DashboardBudgetLimitEditContext context,
  ) {
    if (_disposed || !_isKeyCurrent(context.key)) return null;
    // One physical pointer sequence owns one active draft. A new exact target
    // invalidates an unfinished predecessor rather than writing it elsewhere.
    final priorActive = _active;
    if (priorActive != null) _restoreOverlayAfterActiveDrop(priorActive);
    _active = null;
    _activeYear = null;
    final pending = _pendingByKey[context.key];
    final base =
        pending?.intendedLimitScaled100 ?? context.confirmedLimitScaled100;
    final session = DashboardBudgetLimitEditSession._(
      generation: ++_nextGeneration,
      context: context,
      baseLimitScaled100: base,
      effectiveLimitScaled100: base,
    );
    _active = session;
    _publishActive(session);
    _diagnose('BUDGET_LIMIT_EDIT_STARTED', session);
    return session;
  }

  /// Starts either the existing scalar editor or a derived annual vector
  /// editor. The gesture layer stays neutral: it owns pixels/haptics, while
  /// this owner decides the persistence semantics.
  DashboardBudgetEditableSession? startContext(
    DashboardBudgetEditContext context,
  ) => switch (context) {
    DashboardBudgetLimitEditContext() => startEdit(context),
    DashboardBudgetYearLimitEditContext() => _startYearEdit(context),
  };

  DashboardBudgetYearLimitEditSession? _startYearEdit(
    DashboardBudgetYearLimitEditContext context,
  ) {
    if (_disposed || !_isYearContextCurrent(context)) return null;
    final priorScalar = _active;
    if (priorScalar != null) _restoreOverlayAfterActiveDrop(priorScalar);
    _active = null;
    _activeYear = null;
    final identity = _yearIdentityFor(context);
    final pending = _pendingYearByIdentity[identity];
    final base =
        pending?.intendedMonthlyLimitsScaled100 ??
        context.confirmedMonthlyLimitsScaled100;
    final session = DashboardBudgetYearLimitEditSession._(
      generation: ++_nextGeneration,
      context: context,
      baseMonthlyLimitsScaled100: List<int>.unmodifiable(base),
      effectiveMonthlyLimitsScaled100: List<int>.unmodifiable(base),
    );
    _activeYear = session;
    // A Year edit has no scalar presentation payload. Still notify the
    // selected Budget controller synchronously so all twelve ring segments and
    // the Header denominator update in the same interaction turn.
    notifyListeners();
    return session;
  }

  /// Applies one coalesced semantic increment synchronously. The caller owns
  /// haptics, ensuring one click per reference batch rather than per pixel.
  bool applySemanticTick(
    DashboardBudgetLimitEditSession session, {
    required int direction,
    required int amountStepScaled100,
    required int tickCount,
    required DashboardBudgetLimitEditSource source,
  }) {
    if (!_owns(session) || direction == 0 || tickCount < 1) return false;
    if (amountStepScaled100 < 0) {
      throw ArgumentError.value(amountStepScaled100, 'amountStepScaled100');
    }
    final current = _active!.effectiveLimitScaled100 ?? 0;
    final next = (current + direction * amountStepScaled100 * tickCount).clamp(
      0,
      0x7fffffffffffffff,
    );
    // Keep the repeat armed at the floor so reversing direction remains
    // immediate, but a repeated 0 -> 0 is not a semantic mutation. Publishing
    // it would spuriously rebuild the live Budget selection under the finger.
    if (next == current) return false;
    final updated = _active!.copyWith(effectiveLimitScaled100: next);
    _active = updated;
    _replaceCategoryAllocationOverlay(
      context: updated.context,
      effectiveLimitScaled100: next,
    );
    _publishActive(updated);
    _diagnose(
      source == DashboardBudgetLimitEditSource.drag
          ? 'BUDGET_LIMIT_EDIT_TICK'
          : 'BUDGET_LIMIT_EDIT_AUTO_TICK',
      updated,
      scope:
          'source=${source.name} stepScaled100=$amountStepScaled100 '
          'coalescedTickCount=$tickCount effectiveLimitScaled100=$next',
    );
    return true;
  }

  bool applyContextSemanticTick(
    DashboardBudgetEditableSession session, {
    required int direction,
    required int amountStepScaled100,
    required int tickCount,
    required DashboardBudgetLimitEditSource source,
  }) => switch (session) {
    DashboardBudgetLimitEditSession() => applySemanticTick(
      session,
      direction: direction,
      amountStepScaled100: amountStepScaled100,
      tickCount: tickCount,
      source: source,
    ),
    DashboardBudgetYearLimitEditSession() => _applyYearSemanticTick(
      session,
      direction: direction,
      amountStepScaled100: amountStepScaled100,
      tickCount: tickCount,
      source: source,
    ),
    _ => throw ArgumentError.value(session, 'session'),
  };

  bool _applyYearSemanticTick(
    DashboardBudgetYearLimitEditSession session, {
    required int direction,
    required int amountStepScaled100,
    required int tickCount,
    required DashboardBudgetLimitEditSource source,
  }) {
    if (_activeYear?.generation != session.generation ||
        direction == 0 ||
        tickCount < 1) {
      return false;
    }
    final currentAnnual = _activeYear!.effectiveAnnualLimitScaled100;
    final nextAnnual =
        (currentAnnual + direction * amountStepScaled100 * tickCount)
            .clamp(0, 0x7fffffffffffffff)
            .toInt();
    if (nextAnnual == currentAnnual) return false;
    final allocated = DashboardBudgetYearLimitAllocator.allocate(
      currentMonthlyLimitsScaled100: session.baseMonthlyLimitsScaled100,
      requestedAnnualLimitScaled100: nextAnnual,
    );
    _activeYear = session.copyWith(
      effectiveMonthlyLimitsScaled100: allocated.monthlyLimitsScaled100,
    );
    notifyListeners();
    return true;
  }

  /// Releases an active draft. No move/tick causes persistence; only this
  /// method queues one upsert for a changed final value.
  Future<void> finishEdit(DashboardBudgetLimitEditSession session) {
    if (_active?.generation != session.generation) {
      return Future<void>.value();
    }
    if (_disposed || !_isKeyCurrent(session.context.key)) {
      _active = null;
      _restoreOverlayAfterActiveDrop(session);
      _publishForCurrentOverlay();
      return Future<void>.value();
    }
    final current = _active!;
    _active = null;
    final finalLimit = current.effectiveLimitScaled100;
    if (finalLimit == null || finalLimit == current.baseLimitScaled100) {
      _diagnose(
        'BUDGET_LIMIT_EDIT_FINALIZED',
        current,
        scope: 'finalIntent=noop',
      );
      _publishForCurrentOverlay();
      return Future<void>.value();
    }
    _diagnose(
      'BUDGET_LIMIT_EDIT_FINALIZED',
      current,
      scope: 'finalIntent=upsert',
    );
    final mutation = _PendingBudgetLimitMutation(
      generation: current.generation,
      baseCoreRevision: current.context.coreRevision,
      intendedLimitScaled100: finalLimit,
      confirmedLimitScaled100: _confirmedLimitForOverlay(current.context),
    );
    _pendingByKey[current.context.key] = mutation;
    _publishForCurrentOverlay();
    return _enqueue(
      current.context.key,
      current.generation,
      () => _repository.upsert(current.context.key, finalLimit),
      operationName: 'upsert',
    );
  }

  Future<void> finishContext(DashboardBudgetEditableSession session) =>
      switch (session) {
        DashboardBudgetLimitEditSession() => finishEdit(session),
        DashboardBudgetYearLimitEditSession() => _finishYearEdit(session),
        _ => Future<void>.error(ArgumentError.value(session, 'session')),
      };

  Future<void> _finishYearEdit(DashboardBudgetYearLimitEditSession session) {
    if (_activeYear?.generation != session.generation) {
      return Future<void>.value();
    }
    if (_disposed || !_isYearContextCurrent(session.context)) {
      _activeYear = null;
      notifyListeners();
      return Future<void>.value();
    }
    final current = _activeYear!;
    _activeYear = null;
    if (listEquals(
      current.baseMonthlyLimitsScaled100,
      current.effectiveMonthlyLimitsScaled100,
    )) {
      notifyListeners();
      return Future<void>.value();
    }
    final identity = _yearIdentityFor(current.context);
    final pending = _PendingBudgetYearMutation(
      generation: current.generation,
      baseCoreRevision: current.context.coreRevision,
      intendedMonthlyLimitsScaled100: current.effectiveMonthlyLimitsScaled100,
    );
    _pendingYearByIdentity[identity] = pending;
    notifyListeners();
    return _enqueueYearBatch(
      identity: identity,
      session: current,
      pending: pending,
      mutations: <FinancialLimitMutation>[
        for (var index = 0; index < 12; index += 1)
          FinancialLimitMutation(
            key: current.context.monthOverrideKeys[index],
            amountScaled100: current.effectiveMonthlyLimitsScaled100[index],
          ),
      ],
    );
  }

  /// A complete YEAR vector is one semantic write, but successive releases of
  /// the same target/year still need scalar-style write ordering. Without this
  /// tail an older batch could finish last and overwrite a newer annual edit.
  Future<void> _enqueueYearBatch({
    required _BudgetYearEditIdentity identity,
    required DashboardBudgetYearLimitEditSession session,
    required _PendingBudgetYearMutation pending,
    required List<FinancialLimitMutation> mutations,
  }) {
    Future<void> run() async {
      _diagnoseYear('BUDGET_YEAR_LIMIT_EDIT_PERSIST_STARTED', session);
      try {
        await _repository.upsertBatch(mutations);
        _diagnoseYear('BUDGET_YEAR_LIMIT_EDIT_PERSIST_COMPLETED', session);
      } on Object catch (error) {
        if (_pendingYearByIdentity[identity] == pending) {
          _pendingYearByIdentity.remove(identity);
          notifyListeners();
        }
        _diagnoseYear(
          'BUDGET_YEAR_LIMIT_EDIT_PERSIST_FAILED',
          session,
          error: error.toString(),
        );
      }
    }

    final previous = _yearWriteTailByIdentity[identity];
    final future = previous == null
        ? run()
        : previous.catchError((_) {}).then<void>((_) => run());
    _yearWriteTailByIdentity[identity] = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_yearWriteTailByIdentity[identity], future)) {
          _yearWriteTailByIdentity.remove(identity);
        }
      }),
    );
    return future;
  }

  /// Direct O(1) overlay lookup for the presentation controller. It neither
  /// reads storage nor rebuilds a prepared vector/catalog.
  int? effectiveLimitFor(FinancialLimitKey key, int? confirmedLimitScaled100) {
    final active = _active;
    if (active != null && active.context.key == key) {
      return active.effectiveLimitScaled100;
    }
    final pending = _pendingByKey[key];
    return pending == null
        ? confirmedLimitScaled100
        : pending.intendedLimitScaled100;
  }

  bool hasOverlayFor(FinancialLimitKey key) =>
      (_active?.context.key == key) || _pendingByKey.containsKey(key);

  /// Lets a prepared presentation owner skip all overlay-only traversal on
  /// ordinary temporal ticks. This is deliberately a boolean capability, not
  /// an exposed mutable draft map.
  bool get hasScalarOverlay => _active != null || _pendingByKey.isNotEmpty;

  /// Returns the active/pending full YEAR vector without scanning a catalog or
  /// touching storage. A new prepared revision clears this semantic overlay
  /// only when all twelve resolved cells confirm it together.
  List<int> effectiveYearLimitsFor(
    DashboardBudgetYearLimitEditContext context,
  ) {
    final identity = _yearIdentityFor(context);
    final active = _activeYear;
    if (active != null && _yearIdentityFor(active.context) == identity) {
      return active.effectiveMonthlyLimitsScaled100;
    }
    return _pendingYearByIdentity[identity]?.intendedMonthlyLimitsScaled100 ??
        context.confirmedMonthlyLimitsScaled100;
  }

  bool hasYearOverlayFor(DashboardBudgetYearLimitEditContext context) {
    final identity = _yearIdentityFor(context);
    return (_activeYear != null &&
            _yearIdentityFor(_activeYear!.context) == identity) ||
        _pendingYearByIdentity.containsKey(identity);
  }

  bool get hasYearOverlay =>
      _activeYear != null || _pendingYearByIdentity.isNotEmpty;

  void observePreparedYearLimits(
    DashboardBudgetYearLimitEditContext context, {
    required List<int> confirmedMonthlyLimitsScaled100,
    required int coreRevision,
  }) {
    final identity = _yearIdentityFor(context);
    final pending = _pendingYearByIdentity[identity];
    if (pending == null || coreRevision <= pending.baseCoreRevision) return;
    if (listEquals(
      pending.intendedMonthlyLimitsScaled100,
      confirmedMonthlyLimitsScaled100,
    )) {
      _pendingYearByIdentity.remove(identity);
      notifyListeners();
    }
  }

  /// O(1) category-limit delta and effective overrides for the existing
  /// prepared bank's exact direction/period. This does not traverse categories
  /// or calculate a new aggregate on an interaction tick.
  DashboardBudgetCategoryAllocationOverlay categoryAllocationOverlayFor({
    required FinancialLimitDirection direction,
    required FinancialLimitPeriod period,
  }) =>
      _categoryAllocationByScope[_BudgetCategoryAllocationScope(
            direction: direction,
            period: period,
          )]
          ?.overlay ??
      DashboardBudgetCategoryAllocationOverlay.empty;

  /// Called only by exact prepared-revision publication. It preserves an
  /// optimistic value through stale snapshots and clears it only when a newer
  /// authoritative revision agrees with the intended final state.
  void observePreparedLimit({
    required FinancialLimitKey key,
    required int coreRevision,
    required int? confirmedLimitScaled100,
  }) {
    final pending = _pendingByKey[key];
    if (pending == null || coreRevision <= pending.baseCoreRevision) return;
    if (pending.intendedLimitScaled100 != confirmedLimitScaled100) return;
    _pendingByKey.remove(key);
    if (_active?.context.key != key) {
      _removeCategoryAllocationOverlay(key);
    }
    _diagnosePrepared(
      'BUDGET_LIMIT_EDIT_RECONCILED',
      key: key,
      coreRevision: coreRevision,
      effectiveLimitScaled100: confirmedLimitScaled100,
      generation: pending.generation,
    );
    _publishForCurrentOverlay();
  }

  /// Reconciles every pending category mutation for one exact prepared
  /// direction/period publication. This is deliberately revision-time work,
  /// never a pointer semantic tick: it visits only pending mutations and uses
  /// the caller's retained O(1) category-to-handle lookup.
  void observePreparedCategoryAllocationScope({
    required FinancialLimitDirection direction,
    required FinancialLimitPeriod period,
    required int coreRevision,
    required int? Function(String categoryId) confirmedLimitForCategoryId,
  }) {
    final scope = _BudgetCategoryAllocationScope(
      direction: direction,
      period: period,
    );
    if (_lastReconciledCategoryAllocationRevisionByScope[scope] ==
        coreRevision) {
      return;
    }
    _lastReconciledCategoryAllocationRevisionByScope[scope] = coreRevision;
    var changed = false;
    // A reconciliation can remove an entry, so retain only the pending keys
    // (not a category projection) while iterating the keyed overlay owner.
    final keys = List<FinancialLimitKey>.of(_pendingByKey.keys);
    for (final key in keys) {
      if (key.direction != direction || key.period != period) continue;
      final target = key.target;
      if (target is! FinancialLimitCategoryTarget) continue;
      final pending = _pendingByKey[key];
      if (pending == null || coreRevision <= pending.baseCoreRevision) {
        continue;
      }
      final confirmedLimitScaled100 = confirmedLimitForCategoryId(
        target.categoryId,
      );
      if (pending.intendedLimitScaled100 != confirmedLimitScaled100) {
        continue;
      }
      _pendingByKey.remove(key);
      if (_active?.context.key != key) {
        _removeCategoryAllocationOverlay(key);
      }
      _diagnosePrepared(
        'BUDGET_LIMIT_EDIT_RECONCILED',
        key: key,
        coreRevision: coreRevision,
        effectiveLimitScaled100: confirmedLimitScaled100,
        generation: pending.generation,
      );
      changed = true;
    }
    if (changed) _publishForCurrentOverlay();
  }

  void invalidateIfContextChanged(FinancialLimitKey? currentKey) {
    final active = _active;
    if (active == null || active.context.key == currentKey) return;
    _active = null;
    _restoreOverlayAfterActiveDrop(active);
    _publishForCurrentOverlay();
  }

  /// YEAR has no scalar [FinancialLimitKey]. Its transient twelve-month draft
  /// must therefore be invalidated by the same semantic-context ownership
  /// rule when target, year, direction or scope changes under a gesture.
  void invalidateYearIfContextChanged(
    DashboardBudgetYearLimitEditContext? currentContext,
  ) {
    final active = _activeYear;
    if (active == null) return;
    if (currentContext != null &&
        _yearIdentityFor(active.context) == _yearIdentityFor(currentContext) &&
        active.context.coreRevision == currentContext.coreRevision) {
      return;
    }
    _activeYear = null;
    notifyListeners();
  }

  /// Lifecycle disposal is not a user release. Drop only the transient active
  /// session so its captured key can never be written after the owner is gone.
  void abortEdit(DashboardBudgetLimitEditSession session) {
    if (_active?.generation != session.generation) return;
    _active = null;
    _restoreOverlayAfterActiveDrop(session);
    _publishForCurrentOverlay();
  }

  void abortContext(DashboardBudgetEditableSession session) {
    switch (session) {
      case DashboardBudgetLimitEditSession():
        abortEdit(session);
      case DashboardBudgetYearLimitEditSession():
        if (_activeYear?.generation != session.generation) return;
        _activeYear = null;
        notifyListeners();
      case _:
        throw ArgumentError.value(session, 'session');
    }
  }

  _BudgetYearEditIdentity _yearIdentityFor(
    DashboardBudgetYearLimitEditContext context,
  ) => _BudgetYearEditIdentity(
    direction: context.direction,
    target: context.target,
    year: context.year,
  );

  bool _owns(DashboardBudgetLimitEditSession session) =>
      !_disposed &&
      _active?.generation == session.generation &&
      _isKeyCurrent(session.context.key);

  Future<void> _enqueue(
    FinancialLimitKey key,
    int generation,
    Future<Object?> Function() write, {
    required String operationName,
  }) {
    Future<void> run() async {
      final context = _active?.generation == generation
          ? _active!.context
          : null;
      _diagnosePrepared(
        'BUDGET_LIMIT_EDIT_PERSIST_STARTED',
        key: key,
        coreRevision: context?.coreRevision,
        effectiveLimitScaled100: _pendingByKey[key]?.intendedLimitScaled100,
        generation: generation,
        scope: 'operation=$operationName',
      );
      try {
        await write();
        _diagnosePrepared(
          'BUDGET_LIMIT_EDIT_PERSIST_COMPLETED',
          key: key,
          coreRevision: context?.coreRevision,
          effectiveLimitScaled100: _pendingByKey[key]?.intendedLimitScaled100,
          generation: generation,
          scope: 'operation=$operationName',
        );
      } on Object catch (error) {
        final pending = _pendingByKey[key];
        if (pending?.generation == generation) {
          _pendingByKey.remove(key);
          if (_active?.context.key != key) {
            _removeCategoryAllocationOverlay(key);
          }
          _publishForCurrentOverlay();
        }
        _diagnosePrepared(
          'BUDGET_LIMIT_EDIT_PERSIST_FAILED',
          key: key,
          coreRevision: context?.coreRevision,
          effectiveLimitScaled100: null,
          generation: generation,
          scope: 'operation=$operationName',
          error: '$error',
        );
      }
    }

    final previous = _writeTailByKey[key];
    final future = previous == null
        ? run()
        : previous.catchError((_) {}).then<void>((_) => run());
    _writeTailByKey[key] = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_writeTailByKey[key], future)) {
          _writeTailByKey.remove(key);
        }
      }),
    );
    return future;
  }

  void _publishActive(DashboardBudgetLimitEditSession session) {
    value = DashboardBudgetLimitEditPresentation(
      key: session.context.key,
      coreRevision: session.context.coreRevision,
      targetHandle: session.context.targetHandle,
      actualScaled100: session.context.actualScaled100 ?? 0,
      effectiveLimitScaled100: session.effectiveLimitScaled100,
      generation: session.generation,
    );
  }

  void _replaceCategoryAllocationOverlay({
    required DashboardBudgetLimitEditContext context,
    required int effectiveLimitScaled100,
  }) {
    final target = context.key.target;
    if (target is! FinancialLimitCategoryTarget) return;
    final scope = _BudgetCategoryAllocationScope(
      direction: context.key.direction,
      period: context.key.period,
    );
    final bucket = _categoryAllocationByScope.putIfAbsent(
      scope,
      _BudgetCategoryAllocationBucket.new,
    );
    bucket.replace(
      categoryId: target.categoryId,
      confirmedLimitScaled100: _confirmedLimitForOverlay(context),
      effectiveLimitScaled100: effectiveLimitScaled100,
    );
    if (bucket.isEmpty) _categoryAllocationByScope.remove(scope);
  }

  int? _confirmedLimitForOverlay(DashboardBudgetLimitEditContext context) {
    final existing = _categoryContributionFor(context.key);
    if (existing != null) return existing.confirmedLimitScaled100;
    return _pendingByKey[context.key]?.confirmedLimitScaled100 ??
        context.confirmedLimitScaled100;
  }

  _BudgetCategoryAllocationContribution? _categoryContributionFor(
    FinancialLimitKey key,
  ) {
    final target = key.target;
    if (target is! FinancialLimitCategoryTarget) return null;
    return _categoryAllocationByScope[_BudgetCategoryAllocationScope(
          direction: key.direction,
          period: key.period,
        )]
        ?._contributions[target.categoryId];
  }

  void _restoreOverlayAfterActiveDrop(DashboardBudgetLimitEditSession session) {
    final target = session.context.key.target;
    if (target is! FinancialLimitCategoryTarget) return;
    final pending = _pendingByKey[session.context.key];
    if (pending == null) {
      _removeCategoryAllocationOverlay(session.context.key);
      return;
    }
    _replaceCategoryAllocationOverlay(
      context: session.context,
      effectiveLimitScaled100: pending.intendedLimitScaled100,
    );
  }

  void _removeCategoryAllocationOverlay(FinancialLimitKey key) {
    final target = key.target;
    if (target is! FinancialLimitCategoryTarget) return;
    final scope = _BudgetCategoryAllocationScope(
      direction: key.direction,
      period: key.period,
    );
    final bucket = _categoryAllocationByScope[scope];
    if (bucket == null) return;
    bucket.remove(target.categoryId);
    if (bucket.isEmpty) _categoryAllocationByScope.remove(scope);
  }

  void _publishForCurrentOverlay() {
    final active = _active;
    if (active != null) {
      _publishActive(active);
      return;
    }
    // Pending-overlay removal can change [effectiveLimitFor] while this
    // notifier is already null (for example, a failed pending write). That
    // is still a semantic presentation invalidation, so ValueNotifier's
    // equal-null assignment must not suppress it.
    if (value == null) {
      notifyListeners();
      return;
    }
    value = null;
  }

  void _diagnose(
    String stage,
    DashboardBudgetLimitEditSession session, {
    String? scope,
  }) => _diagnosePrepared(
    stage,
    key: session.context.key,
    coreRevision: session.context.coreRevision,
    effectiveLimitScaled100: session.effectiveLimitScaled100,
    generation: session.generation,
    scope: scope,
  );

  void _diagnosePrepared(
    String stage, {
    required FinancialLimitKey key,
    required int? coreRevision,
    required int? effectiveLimitScaled100,
    required int generation,
    String? scope,
    String? error,
  }) {
    final target = switch (key.target) {
      FinancialLimitAggregateTarget() => 'aggregate',
      FinancialLimitCategoryTarget(:final categoryId) => 'category:$categoryId',
    };
    final period = switch (key.period) {
      FinancialLimitBaseMonthlyPeriod() => 'base',
      FinancialLimitMonthOverridePeriod(:final year, :final month) =>
        'month:$year-$month',
    };
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: stage,
        coreRevision: coreRevision,
        direction: key.direction.name,
        totalMinor: effectiveLimitScaled100,
        scope:
            'target=$target period=$period generation=$generation '
                    '${scope ?? ''}'
                .trim(),
        error: error,
      ),
    );
  }

  void _diagnoseYear(
    String stage,
    DashboardBudgetYearLimitEditSession session, {
    String? error,
  }) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: stage,
        coreRevision: session.context.coreRevision,
        direction: session.context.direction.name,
        totalMinor: session.effectiveAnnualLimitScaled100,
        scope:
            'targetHandle=${session.context.targetHandle} '
            'year=${session.context.year} generation=${session.generation} '
            'monthCount=12',
        error: error,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    final active = _active;
    _active = null;
    if (active != null) _restoreOverlayAfterActiveDrop(active);
    _activeYear = null;
    _pendingYearByIdentity.clear();
    _yearWriteTailByIdentity.clear();
    super.dispose();
  }
}
