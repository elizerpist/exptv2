import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/category_repository.dart';
import '../domain/fluvi_category.dart';

typedef CategoryCollectionDiagnosticCallback =
    void Function(CategoryCollectionDiagnosticEvent event);

enum CategoryCollectionDiagnosticStage { loadStarted, ready, failed }

/// Bounded, semantic diagnostics for root category inventory bootstrap.
@immutable
final class CategoryCollectionDiagnosticEvent {
  const CategoryCollectionDiagnosticEvent({
    required this.stage,
    this.categoryCount,
    this.durationMs,
    this.error,
  });

  final CategoryCollectionDiagnosticStage stage;
  final int? categoryCount;
  final int? durationMs;
  final Object? error;
}

/// App-lifetime owner of the current authoritative category collection.
///
/// It subscribes once to [CategoryRepository.watchCategories], which supplies
/// its initial inventory snapshot before any later category mutations. Widgets
/// consume the immutable value only; they never access the repository.
final class CategoryCollectionController
    extends ValueNotifier<List<FluviCategory>> {
  CategoryCollectionController({
    required CategoryRepository repository,
    CategoryCollectionDiagnosticCallback? onDiagnostic,
  }) : _repository = repository,
       _onDiagnostic = onDiagnostic,
       super(const <FluviCategory>[]);

  final CategoryRepository _repository;
  final CategoryCollectionDiagnosticCallback? _onDiagnostic;

  StreamSubscription<List<FluviCategory>>? _subscription;
  Future<void>? _startOperation;
  Completer<void>? _firstCollection;
  Stopwatch? _loadStopwatch;
  bool _disposed = false;

  /// Starts the one repository subscription and completes at its first value.
  ///
  /// Repeated callers join the same first-load operation. An empty collection
  /// is a valid ready result; a repository error is propagated to the caller.
  Future<void> start() {
    final existing = _startOperation;
    if (existing != null) return existing;
    if (_disposed) {
      return Future<void>.error(
        StateError('CategoryCollectionController is already disposed.'),
      );
    }

    final firstCollection = Completer<void>();
    _firstCollection = firstCollection;
    _loadStopwatch = Stopwatch()..start();
    _onDiagnostic?.call(
      const CategoryCollectionDiagnosticEvent(
        stage: CategoryCollectionDiagnosticStage.loadStarted,
      ),
    );
    _startOperation = firstCollection.future;
    _subscription = _repository.watchCategories().listen(
      _onCategories,
      onError: _onRepositoryError,
      onDone: _onRepositoryDone,
      cancelOnError: true,
    );
    return _startOperation!;
  }

  void _onCategories(List<FluviCategory> categories) {
    if (_disposed) return;
    final next = List<FluviCategory>.unmodifiable(categories);
    if (!_sameCategories(value, next)) value = next;

    final firstCollection = _firstCollection;
    if (firstCollection == null || firstCollection.isCompleted) return;
    _loadStopwatch?.stop();
    _onDiagnostic?.call(
      CategoryCollectionDiagnosticEvent(
        stage: CategoryCollectionDiagnosticStage.ready,
        categoryCount: next.length,
        durationMs: _loadStopwatch?.elapsedMilliseconds ?? 0,
      ),
    );
    firstCollection.complete();
  }

  void _onRepositoryError(Object error, StackTrace stackTrace) {
    _completeFirstLoadFailure(error, stackTrace);
  }

  void _onRepositoryDone() {
    final firstCollection = _firstCollection;
    if (firstCollection == null || firstCollection.isCompleted || _disposed) {
      return;
    }
    _completeFirstLoadFailure(
      StateError('CategoryRepository closed before its first collection.'),
      StackTrace.current,
    );
  }

  void _completeFirstLoadFailure(Object error, StackTrace stackTrace) {
    if (_disposed) return;
    final firstCollection = _firstCollection;
    if (firstCollection == null || firstCollection.isCompleted) return;
    _loadStopwatch?.stop();
    _onDiagnostic?.call(
      CategoryCollectionDiagnosticEvent(
        stage: CategoryCollectionDiagnosticStage.failed,
        durationMs: _loadStopwatch?.elapsedMilliseconds ?? 0,
        error: error,
      ),
    );
    firstCollection.completeError(error, stackTrace);
    _firstCollection = null;
    _startOperation = null;
    _subscription = null;
  }

  static bool _sameCategories(
    List<FluviCategory> left,
    List<FluviCategory> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      final previous = left[index];
      final next = right[index];
      if (previous.id != next.id ||
          previous.name != next.name ||
          previous.colorId != next.colorId ||
          previous.iconId != next.iconId ||
          previous.isSystemUncategorized != next.isSystemUncategorized ||
          previous.updatedAtUtcMs != next.updatedAtUtcMs) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
