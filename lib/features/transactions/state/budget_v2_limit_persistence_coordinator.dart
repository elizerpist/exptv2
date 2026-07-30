import 'dart:async';

typedef BudgetV2LimitWrite =
    Future<void> Function(bool Function() isCurrentRuntime);
typedef BudgetV2LimitWriteSuccess = void Function(int operationId);
typedef BudgetV2LimitWriteError =
    void Function(int operationId, Object error, StackTrace stackTrace);

/// Orders Budget V2 limit writes and rejects results from replaced runtimes.
///
/// The static [Expando] weakly attaches queue tails and operation IDs to the
/// injected store identity. This deliberately gives those values store
/// lifetime rather than dashboard lifetime without retaining disposed stores
/// globally. A remounted dashboard therefore joins the same per-avatar queue,
/// while an A → B → A runtime generation still prevents old A results from
/// being applied or acknowledged in the new A runtime.
class BudgetV2LimitPersistenceCoordinator {
  BudgetV2LimitPersistenceCoordinator({required Object initialStoreIdentity})
    : _currentStoreIdentity = initialStoreIdentity;

  static final Expando<_BudgetV2LimitStoreWriteState> _storeWriteStates =
      Expando<_BudgetV2LimitStoreWriteState>(
        'BudgetV2 store-scoped limit write state',
      );

  Object _currentStoreIdentity;
  var _runtimeGeneration = 0;
  var _disposed = false;

  int get runtimeGeneration => _runtimeGeneration;

  /// Allocates from store-lifetime state, so dashboard remounts cannot reuse
  /// an operation ID while an older write for the same store is still alive.
  int allocateOperationId(Object storeIdentity) {
    final state = _stateFor(storeIdentity);
    return ++state.nextOperationId;
  }

  void replaceStoreIdentity(Object storeIdentity) {
    if (_disposed) return;
    _currentStoreIdentity = storeIdentity;
    _runtimeGeneration += 1;
  }

  Future<void> schedule({
    required Object storeIdentity,
    required String avatarKey,
    required int operationId,
    required BudgetV2LimitWrite write,
    required BudgetV2LimitWriteSuccess onSuccess,
    required BudgetV2LimitWriteError onError,
  }) {
    if (_disposed) return Future<void>.value();
    final generation = _runtimeGeneration;
    final state = _stateFor(storeIdentity);
    final previous = state.scopeTails[avatarKey] ?? Future<void>.value();

    bool isCurrentRuntime() =>
        !_disposed &&
        generation == _runtimeGeneration &&
        identical(storeIdentity, _currentStoreIdentity);

    late final Future<void> scheduled;
    scheduled = previous.then((_) async {
      if (!isCurrentRuntime()) return;
      try {
        await write(isCurrentRuntime);
      } catch (error, stackTrace) {
        onError(operationId, error, stackTrace);
        return;
      }
      if (isCurrentRuntime()) onSuccess(operationId);
    });
    state.scopeTails[avatarKey] = scheduled;
    unawaited(
      scheduled.whenComplete(() {
        if (identical(state.scopeTails[avatarKey], scheduled)) {
          state.scopeTails.remove(avatarKey);
        }
      }),
    );
    return scheduled;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _runtimeGeneration += 1;
  }

  static _BudgetV2LimitStoreWriteState _stateFor(Object storeIdentity) =>
      _storeWriteStates[storeIdentity] ??= _BudgetV2LimitStoreWriteState();
}

class _BudgetV2LimitStoreWriteState {
  final Map<String, Future<void>> scopeTails = <String, Future<void>>{};
  var nextOperationId = 0;
}
