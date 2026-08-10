import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/application/query_composer_controller.dart';
import 'package:fluvi/features/dashboard/query/application/saved_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/query_menu_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'loading a saved query changes the draft but never the applied scope',
    () async {
      final applied = CurrentQueryController(initialScope: _scope());
      final composer = QueryComposerController(appliedQuery: applied)..open();
      final saved = _saved('food', _scope(categories: const <String>{'food'}));
      final controller = SavedQueryController(repository: _Repository(saved));
      addTearDown(applied.dispose);
      addTearDown(composer.dispose);
      addTearDown(controller.dispose);

      await controller.refresh(LedgerDirection.expense);
      await controller.loadIntoDraft(id: saved.id, composer: composer);

      expect(composer.draft.categoryIds, <String>{'food'});
      expect(applied.scope.categoryIds, isEmpty);
      expect(controller.activeSavedQueryId, saved.id);
      expect(controller.isDirty(composer.draft), isFalse);

      composer.updateDraft(
        scope: _scope(categories: const <String>{'transport'}),
      );
      expect(controller.isDirty(composer.draft), isTrue);
    },
  );

  test(
    'named save update rename and delete stay separate from applied scope',
    () async {
      final applied = CurrentQueryController(initialScope: _scope());
      final repository = _Repository(_saved('seed', _scope()));
      final controller = SavedQueryController(repository: repository);
      addTearDown(applied.dispose);
      addTearDown(controller.dispose);

      await controller.refresh(LedgerDirection.expense);
      final created = await controller.saveAsNew(
        name: 'Havi élelmiszer',
        scope: _scope(categories: const <String>{'food'}),
      );
      expect(controller.activeSavedQueryId, created.id);
      expect(controller.isDirty(created.scope), isFalse);

      final updated = await controller.updateActive(
        name: 'Frissített élelmiszer',
        scope: created.scope.copyWith(categoryIds: const <String>{'transport'}),
      );
      expect(updated.name, 'Frissített élelmiszer');
      expect(controller.isDirty(updated.scope), isFalse);

      final renamed = await controller.rename(
        id: updated.id,
        name: 'Fix költség',
      );
      expect(renamed.name, 'Fix költség');
      await controller.delete(renamed.id);

      expect(
        controller.savedQueries.map((entry) => entry.id),
        isNot(contains(renamed.id)),
      );
      expect(applied.scope, _scope());
    },
  );
}

CurrentLedgerQueryScope _scope({Set<String> categories = const <String>{}}) =>
    CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
      categoryIds: categories,
    );

SavedLedgerQuery _saved(String id, CurrentLedgerQueryScope scope) =>
    SavedLedgerQuery(
      id: id,
      name: 'Étel',
      scope: scope,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );

final class _Repository implements QueryMenuRepository {
  _Repository(SavedLedgerQuery saved) : _saved = <SavedLedgerQuery>[saved];

  final List<SavedLedgerQuery> _saved;

  @override
  Future<SavedLedgerQuery> loadSaved({
    required String id,
    required LedgerDirection activeDirection,
  }) async => _saved.firstWhere((saved) => saved.id == id);

  @override
  Future<List<SavedLedgerQuery>> listSaved(LedgerDirection direction) async =>
      _saved.where((saved) => saved.scope.direction == direction).toList();

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope draft) =>
      throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> createSaved({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) async {
    final saved = SavedLedgerQuery(
      id: 'saved-${_saved.length}',
      name: name,
      scope: scope,
      createdAtUtcMs: 2,
      updatedAtUtcMs: 2,
    );
    _saved.add(saved);
    return saved;
  }

  @override
  Future<void> deleteSaved({required String id}) async {
    _saved.removeWhere((saved) => saved.id == id);
  }

  @override
  Future<SavedLedgerQuery> renameSaved({
    required String id,
    required String name,
  }) async => _replace(id, name: name);

  @override
  Future<SavedLedgerQuery> updateSaved({
    required String id,
    required String name,
    required CurrentLedgerQueryScope scope,
  }) async => _replace(id, name: name, scope: scope);

  SavedLedgerQuery _replace(
    String id, {
    required String name,
    CurrentLedgerQueryScope? scope,
  }) {
    final index = _saved.indexWhere((saved) => saved.id == id);
    final previous = _saved[index];
    final next = SavedLedgerQuery(
      id: previous.id,
      name: name,
      scope: scope ?? previous.scope,
      createdAtUtcMs: previous.createdAtUtcMs,
      updatedAtUtcMs: 3,
    );
    _saved[index] = next;
    return next;
  }
}
