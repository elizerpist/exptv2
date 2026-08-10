import 'package:flutter/services.dart';

import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/query_menu_data.dart';
import 'current_ledger_query_scope_wire_codec.dart';
import 'query_menu_repository.dart';

/// Flutter adapter for the focused Query Menu Android bridge.
final class MethodChannelQueryMenuRepository implements QueryMenuRepository {
  MethodChannelQueryMenuRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.fluvi/query_menu';
  final MethodChannel _channel;

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope draft) async =>
      _data(
        await _channel.invokeMethod<Object?>(
          'readQueryMenuFacets',
          CurrentLedgerQueryScopeWireCodec.encodeFilter(draft),
        ),
      );

  @override
  Future<List<SavedLedgerQuery>> listSaved(LedgerDirection direction) async {
    final raw = await _channel.invokeMethod<Object?>('listSavedQueries', {
      'direction': direction.name,
    });
    if (raw is! List) {
      throw const FormatException('Saved Queries must be a list.');
    }
    return raw.map(_saved).toList(growable: false);
  }

  @override
  Future<SavedLedgerQuery> createSaved({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) async => _saved(
    await _channel.invokeMethod<Object?>('createSavedQuery', {
      ...CurrentLedgerQueryScopeWireCodec.encodeFilter(scope),
      'name': name,
    }),
  );

  @override
  Future<SavedLedgerQuery> loadSaved({
    required String id,
    required LedgerDirection activeDirection,
  }) async => _saved(
    await _channel.invokeMethod<Object?>('loadSavedQuery', {
      'id': id,
      'direction': activeDirection.name,
    }),
  );

  @override
  Future<SavedLedgerQuery> updateSaved({
    required String id,
    required String name,
    required CurrentLedgerQueryScope scope,
  }) async => _saved(
    await _channel.invokeMethod<Object?>('updateSavedQuery', {
      ...CurrentLedgerQueryScopeWireCodec.encodeFilter(scope),
      'id': id,
      'name': name,
    }),
  );

  @override
  Future<SavedLedgerQuery> renameSaved({
    required String id,
    required String name,
  }) async => _saved(
    await _channel.invokeMethod<Object?>('renameSavedQuery', {
      'id': id,
      'name': name,
    }),
  );

  @override
  Future<void> deleteSaved({required String id}) =>
      _channel.invokeMethod<void>('deleteSavedQuery', {'id': id});

  static QueryMenuData _data(Object? raw) {
    final map = _map(raw, 'Query Menu data');
    final result = _map(map['result'], 'result');
    final amountDomain = _map(map['amountDomain'], 'amount domain');
    return QueryMenuData(
      result: QueryMenuResultSummary(
        entryCount: _int(result['entryCount'], 'entryCount'),
        amountScaled100: _int(result['amountScaled100'], 'amountScaled100'),
      ),
      amountDomain: QueryMenuAmountDomain(
        minimumAmountScaled100: _int(
          amountDomain['minimumAmountScaled100'],
          'minimumAmountScaled100',
        ),
        maximumAmountScaled100: _int(
          amountDomain['maximumAmountScaled100'],
          'maximumAmountScaled100',
        ),
      ),
      availableMonths: _list(map['availableMonths'], 'available months')
          .map((rawMonth) {
            final month = _map(rawMonth, 'available month');
            return QueryMenuAvailableMonth(
              year: _int(month['year'], 'available month year'),
              month: _int(month['month'], 'available month'),
            );
          })
          .toList(growable: false),
      categories: _list(map['categories'], 'categories')
          .map((rawCategory) {
            final category = _map(rawCategory, 'category');
            return QueryMenuCategoryFacet(
              id: _string(category['id'], 'category id'),
              displayName: _string(category['displayName'], 'category name'),
              colorId: _string(category['colorId'], 'category color'),
              iconId: _string(category['iconId'], 'category icon'),
              entryCount: _int(category['entryCount'], 'category entry count'),
            );
          })
          .toList(growable: false),
      partners: _list(map['partners'], 'partners')
          .map((rawPartner) {
            final partner = _map(rawPartner, 'partner');
            return QueryMenuPartnerFacet(
              id: _string(partner['id'], 'partner id'),
              displayName: _string(partner['displayName'], 'partner name'),
              categoryId: _string(partner['categoryId'], 'partner category id'),
              categoryColorId: _string(
                partner['categoryColorId'],
                'partner category color',
              ),
              categoryIconId: _string(
                partner['categoryIconId'],
                'partner category icon',
              ),
              entryCount: _int(partner['entryCount'], 'partner entry count'),
            );
          })
          .toList(growable: false),
    );
  }

  static SavedLedgerQuery _saved(Object? raw) {
    final map = _map(raw, 'saved Query');
    return SavedLedgerQuery(
      id: _string(map['id'], 'saved Query id'),
      name: _string(map['name'], 'saved Query name'),
      scope: CurrentLedgerQueryScopeWireCodec.decodeSavedScope(map),
      createdAtUtcMs: _int(map['createdAtUtcMs'], 'saved Query creation'),
      updatedAtUtcMs: _int(map['updatedAtUtcMs'], 'saved Query update'),
    );
  }

  static Map<Object?, Object?> _map(Object? raw, String label) {
    if (raw is! Map) throw FormatException('$label must be a map.');
    return raw;
  }

  static List<Object?> _list(Object? raw, String label) {
    if (raw is! List) throw FormatException('$label must be a list.');
    return List<Object?>.from(raw);
  }

  static String _string(Object? raw, String label) {
    if (raw is! String) throw FormatException('$label must be a string.');
    return raw;
  }

  static int _int(Object? raw, String label) {
    if (raw is! num) throw FormatException('$label must be numeric.');
    return raw.toInt();
  }
}
