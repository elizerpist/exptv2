import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/application/category_collection_controller.dart';
import 'package:fluvi/core/categories/domain/category_repository.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';

void main() {
  test(
    'start awaits and publishes the first authoritative category emission',
    () async {
      final repository = _FakeCategoryRepository();
      final diagnostics = <CategoryCollectionDiagnosticEvent>[];
      final controller = CategoryCollectionController(
        repository: repository,
        onDiagnostic: diagnostics.add,
      );
      addTearDown(() async {
        controller.dispose();
        await repository.dispose();
      });

      final started = controller.start();

      expect(repository.watchCalls, 1);
      expect(controller.value, isEmpty);
      repository.emit([_category(id: 'groceries')]);
      await started;

      expect(controller.value.map((category) => category.id), ['groceries']);
      expect(diagnostics.map((event) => event.stage), [
        CategoryCollectionDiagnosticStage.loadStarted,
        CategoryCollectionDiagnosticStage.ready,
      ]);
      expect(diagnostics.last.categoryCount, 1);
    },
  );

  test('an empty first inventory is a successful ready collection', () async {
    final repository = _FakeCategoryRepository();
    final controller = CategoryCollectionController(repository: repository);
    addTearDown(() async {
      controller.dispose();
      await repository.dispose();
    });

    final started = controller.start();
    repository.emit(const []);
    await started;

    expect(controller.value, isEmpty);
  });

  test('repeated start calls share one category subscription', () async {
    final repository = _FakeCategoryRepository();
    final controller = CategoryCollectionController(repository: repository);
    addTearDown(() async {
      controller.dispose();
      await repository.dispose();
    });

    final first = controller.start();
    final second = controller.start();

    expect(identical(first, second), isTrue);
    expect(repository.watchCalls, 1);
    repository.emit([_category(id: 'groceries')]);
    await first;
  });

  test(
    'repeated category identity does not republish but visual changes do',
    () async {
      final repository = _FakeCategoryRepository();
      final controller = CategoryCollectionController(repository: repository);
      addTearDown(() async {
        controller.dispose();
        await repository.dispose();
      });
      var publications = 0;
      controller.addListener(() => publications += 1);

      final started = controller.start();
      repository.emit([_category(id: 'groceries')]);
      await started;
      repository.emit([_category(id: 'groceries')]);
      repository.emit([
        _category(id: 'groceries', colorId: 'color_13', updatedAtUtcMs: 2),
      ]);

      expect(publications, 2);
      expect(controller.value.single.colorId, 'color_13');
    },
  );

  test('dispose cancels the one authoritative category subscription', () async {
    final repository = _FakeCategoryRepository();
    final controller = CategoryCollectionController(repository: repository);
    final started = controller.start();
    repository.emit([_category(id: 'groceries')]);
    await started;

    controller.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(repository.cancelCalls, 1);
    await repository.dispose();
  });

  test(
    'first-load errors propagate through start and are diagnosed once',
    () async {
      final repository = _FakeCategoryRepository();
      final diagnostics = <CategoryCollectionDiagnosticEvent>[];
      final controller = CategoryCollectionController(
        repository: repository,
        onDiagnostic: diagnostics.add,
      );
      addTearDown(() async {
        controller.dispose();
        await repository.dispose();
      });

      final started = controller.start();
      repository.fail(StateError('category bridge unavailable'));

      await expectLater(started, throwsStateError);
      expect(diagnostics.map((event) => event.stage), [
        CategoryCollectionDiagnosticStage.loadStarted,
        CategoryCollectionDiagnosticStage.failed,
      ]);
    },
  );

  test('a later start retries after a terminal first-load error', () async {
    final repository = _FakeCategoryRepository();
    final controller = CategoryCollectionController(repository: repository);
    addTearDown(() async {
      controller.dispose();
      await repository.dispose();
    });

    final failedAttempt = controller.start();
    final expectedFailure = expectLater(failedAttempt, throwsStateError);
    repository.fail(StateError('category bridge unavailable'));
    await expectedFailure;

    final retry = controller.start();
    repository.emit([_category(id: 'groceries')]);
    await retry;

    expect(repository.watchCalls, 2);
    expect(controller.value.single.id, 'groceries');
  });
}

final class _FakeCategoryRepository implements CategoryRepository {
  final StreamController<List<FluviCategory>> _changes =
      StreamController<List<FluviCategory>>.broadcast(sync: true);
  var watchCalls = 0;
  var cancelCalls = 0;

  _FakeCategoryRepository() {
    _changes.onCancel = () {
      cancelCalls += 1;
    };
  }

  @override
  Stream<List<FluviCategory>> watchCategories() {
    watchCalls += 1;
    return _changes.stream;
  }

  void emit(List<FluviCategory> categories) => _changes.add(categories);

  void fail(Object error) => _changes.addError(error);

  Future<void> dispose() => _changes.close();

  @override
  Future<FluviCategory> createCategory({
    required String name,
    required String colorId,
    required String iconId,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCategory(String id) => throw UnimplementedError();

  @override
  Future<FluviCategory?> getCategoryById(String id) =>
      throw UnimplementedError();

  @override
  Future<List<FluviCategory>> getCategories() => throw UnimplementedError();

  @override
  Future<FluviCategory> updateCategory({
    required String id,
    required String name,
    required String colorId,
    required String iconId,
  }) => throw UnimplementedError();
}

FluviCategory _category({
  required String id,
  String name = 'Groceries',
  String colorId = 'color_08',
  String iconId = 'icon_08',
  bool isSystemUncategorized = false,
  int updatedAtUtcMs = 1,
}) => FluviCategory(
  id: id,
  name: name,
  colorId: colorId,
  iconId: iconId,
  isSystemUncategorized: isSystemUncategorized,
  createdAtUtcMs: 1,
  updatedAtUtcMs: updatedAtUtcMs,
);
