import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/query_menu_data.dart';

/// Typed Query Menu data boundary. Implementations may use a platform bridge;
/// widgets and controllers only see these bounded immutable values.
abstract interface class QueryMenuRepository {
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope draft);

  Future<List<SavedLedgerQuery>> listSaved(LedgerDirection direction);

  Future<SavedLedgerQuery> createSaved({
    required String name,
    required CurrentLedgerQueryScope scope,
  });

  Future<SavedLedgerQuery> loadSaved({
    required String id,
    required LedgerDirection activeDirection,
  });

  Future<SavedLedgerQuery> updateSaved({
    required String id,
    required String name,
    required CurrentLedgerQueryScope scope,
  });

  Future<SavedLedgerQuery> renameSaved({
    required String id,
    required String name,
  });

  Future<void> deleteSaved({required String id});
}

/// Explicit no-transport implementation used only by non-native demo/web
/// surfaces. Production Android always uses the MethodChannel adapter.
final class EmptyQueryMenuRepository implements QueryMenuRepository {
  const EmptyQueryMenuRepository();

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope draft) async =>
      const QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 0, amountScaled100: 0),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 0,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );

  @override
  Future<List<SavedLedgerQuery>> listSaved(LedgerDirection direction) async =>
      const <SavedLedgerQuery>[];

  @override
  Future<SavedLedgerQuery> createSaved({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => Future<SavedLedgerQuery>.error(
    UnsupportedError('Saved Query persistence requires the native core.'),
  );

  @override
  Future<SavedLedgerQuery> loadSaved({
    required String id,
    required LedgerDirection activeDirection,
  }) => Future<SavedLedgerQuery>.error(
    UnsupportedError('Saved Query persistence requires the native core.'),
  );

  @override
  Future<SavedLedgerQuery> updateSaved({
    required String id,
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => Future<SavedLedgerQuery>.error(
    UnsupportedError('Saved Query persistence requires the native core.'),
  );

  @override
  Future<SavedLedgerQuery> renameSaved({
    required String id,
    required String name,
  }) => Future<SavedLedgerQuery>.error(
    UnsupportedError('Saved Query persistence requires the native core.'),
  );

  @override
  Future<void> deleteSaved({required String id}) => Future<void>.error(
    UnsupportedError('Saved Query persistence requires the native core.'),
  );
}
