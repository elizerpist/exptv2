import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../core/financial_limits/domain/financial_limit.dart';
import '../../../core/financial_limits/domain/financial_limit_repository.dart';

/// Semantic source of a single limit increment. Raw pointer tracking belongs
/// to the presentation input shell; this controller only owns scalar draft and
/// persistence state.
enum DashboardBudgetLimitEditSource { drag, auto }

/// Exact immutable state captured when a quick edit begins. The current
/// prepared header has already resolved this from RAM, so an editor never needs
/// a repository read to start.
@immutable
final class DashboardBudgetLimitEditContext {
  const DashboardBudgetLimitEditContext({
    required this.key,
    required this.coreRevision,
    required this.targetHandle,
    required this.actualScaled100,
    required this.confirmedLimitScaled100,
  });

  final FinancialLimitKey key;
  final int coreRevision;
  final int targetHandle;
  final int actualScaled100;
  final int? confirmedLimitScaled100;
}

@immutable
final class DashboardBudgetLimitEditSession {
  const DashboardBudgetLimitEditSession._({
    required this.generation,
    required this.context,
    required this.baseLimitScaled100,
    required this.effectiveLimitScaled100,
    required this.clearTriggeredInGesture,
  });

  final int generation;
  final DashboardBudgetLimitEditContext context;
  final int? baseLimitScaled100;
  final int? effectiveLimitScaled100;

  /// A very-long clear is gesture history, not the final persistence intent.
  /// A later positive tick keeps this true so [finishEdit] can persist the
  /// positive final intent even when it numerically matches the starting value.
  final bool clearTriggeredInGesture;

  DashboardBudgetLimitEditSession copyWith({
    int? effectiveLimitScaled100,
    bool clearEffectiveLimit = false,
    bool? clearTriggeredInGesture,
  }) => DashboardBudgetLimitEditSession._(
    generation: generation,
    context: context,
    baseLimitScaled100: baseLimitScaled100,
    effectiveLimitScaled100: clearEffectiveLimit
        ? null
        : effectiveLimitScaled100 ?? this.effectiveLimitScaled100,
    clearTriggeredInGesture:
        clearTriggeredInGesture ?? this.clearTriggeredInGesture,
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

final class _PendingBudgetLimitMutation {
  const _PendingBudgetLimitMutation({
    required this.generation,
    required this.baseCoreRevision,
    required this.intendedLimitScaled100,
  });

  final int generation;
  final int baseCoreRevision;
  final int? intendedLimitScaled100;
}

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
  }) : _repository = repository,
       _isKeyCurrent = isKeyCurrent,
       super(null);

  final FinancialLimitRepository _repository;
  final bool Function(FinancialLimitKey key) _isKeyCurrent;
  final Map<FinancialLimitKey, _PendingBudgetLimitMutation> _pendingByKey =
      <FinancialLimitKey, _PendingBudgetLimitMutation>{};
  final Map<FinancialLimitKey, Future<void>> _writeTailByKey =
      <FinancialLimitKey, Future<void>>{};

  DashboardBudgetLimitEditSession? _active;
  int _nextGeneration = 0;
  bool _disposed = false;

  DashboardBudgetLimitEditSession? startEdit(
    DashboardBudgetLimitEditContext context,
  ) {
    if (_disposed || !_isKeyCurrent(context.key)) return null;
    // One physical pointer sequence owns one active draft. A new exact target
    // invalidates an unfinished predecessor rather than writing it elsewhere.
    _active = null;
    final pending = _pendingByKey[context.key];
    final base =
        pending?.intendedLimitScaled100 ?? context.confirmedLimitScaled100;
    final session = DashboardBudgetLimitEditSession._(
      generation: ++_nextGeneration,
      context: context,
      baseLimitScaled100: base,
      effectiveLimitScaled100: base,
      clearTriggeredInGesture: false,
    );
    _active = session;
    _publishActive(session);
    _diagnose('BUDGET_LIMIT_EDIT_STARTED', session);
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

  /// Applies a very-long clear to the active RAM draft. Persistence remains
  /// release-only so a user can clear, restore a positive amount, and produce
  /// one final upsert rather than an ordered delete/upsert pair.
  bool clearDraft(DashboardBudgetLimitEditSession session) {
    if (!_owns(session)) return false;
    final updated = _active!.copyWith(
      clearEffectiveLimit: true,
      clearTriggeredInGesture: true,
    );
    _active = updated;
    _publishActive(updated);
    _diagnose('BUDGET_LIMIT_EDIT_CLEARED_DRAFT', updated);
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
      _publishForCurrentOverlay();
      return Future<void>.value();
    }
    final current = _active!;
    _active = null;
    final finalLimit = current.effectiveLimitScaled100;
    final finalIntent = switch (finalLimit) {
      null when current.baseLimitScaled100 == null => 'noop',
      null => 'delete',
      _
          when !current.clearTriggeredInGesture &&
              finalLimit == current.baseLimitScaled100 =>
        'noop',
      _ => 'upsert',
    };
    _diagnose(
      'BUDGET_LIMIT_EDIT_FINALIZED',
      current,
      scope: 'finalIntent=$finalIntent',
    );
    if (finalIntent == 'noop') {
      _publishForCurrentOverlay();
      return Future<void>.value();
    }
    final mutation = _PendingBudgetLimitMutation(
      generation: current.generation,
      baseCoreRevision: current.context.coreRevision,
      intendedLimitScaled100: finalLimit,
    );
    _pendingByKey[current.context.key] = mutation;
    _publishForCurrentOverlay();
    return _enqueue(
      current.context.key,
      current.generation,
      finalIntent == 'delete'
          ? () => _repository.delete(current.context.key)
          : () => _repository.upsert(current.context.key, finalLimit!),
      operationName: finalIntent,
    );
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
    _diagnosePrepared(
      'BUDGET_LIMIT_EDIT_RECONCILED',
      key: key,
      coreRevision: coreRevision,
      effectiveLimitScaled100: confirmedLimitScaled100,
      generation: pending.generation,
    );
    _publishForCurrentOverlay();
  }

  void invalidateIfContextChanged(FinancialLimitKey? currentKey) {
    final active = _active;
    if (active == null || active.context.key == currentKey) return;
    _active = null;
    _publishForCurrentOverlay();
  }

  /// Lifecycle disposal is not a user release. Drop only the transient active
  /// session so its captured key can never be written after the owner is gone.
  void abortEdit(DashboardBudgetLimitEditSession session) {
    if (_active?.generation != session.generation) return;
    _active = null;
    _publishForCurrentOverlay();
  }

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
      actualScaled100: session.context.actualScaled100,
      effectiveLimitScaled100: session.effectiveLimitScaled100,
      generation: session.generation,
    );
  }

  void _publishForCurrentOverlay() {
    final active = _active;
    if (active != null) {
      _publishActive(active);
      return;
    }
    // Pending-overlay removal can change [effectiveLimitFor] while this
    // notifier is already null (for example, a failed pending delete). That
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
      FinancialLimitSumPeriod() => 'sum',
      FinancialLimitYearPeriod(:final year) => 'year:$year',
      FinancialLimitMonthPeriod(:final year, :final month) =>
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

  @override
  void dispose() {
    _disposed = true;
    _active = null;
    super.dispose();
  }
}
