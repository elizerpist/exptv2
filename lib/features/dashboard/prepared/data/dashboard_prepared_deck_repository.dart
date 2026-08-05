import 'package:flutter/foundation.dart';

import '../../motion/dashboard_semantic_catalog.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/dashboard_prepared_deck.dart';

@immutable
final class DashboardPreparedDeckRequest {
  const DashboardPreparedDeckRequest({
    required this.key,
    required this.parentScope,
    required this.semanticCatalog,
  });

  factory DashboardPreparedDeckRequest.fromDeck(DashboardPreparedDeck deck) =>
      DashboardPreparedDeckRequest(
        key: deck.key,
        parentScope: deck.parentScope,
        semanticCatalog: deck.semanticCatalog,
      );

  final DashboardPreparedDeckKey key;
  final CurrentLedgerQueryScope parentScope;
  final DashboardSemanticCatalog semanticCatalog;
}

/// Cooperative preparation cancellation and priority token.
final class DashboardPreparationToken {
  DashboardPreparationToken({required this.generation, required bool required})
    : _required = required;

  final int generation;
  bool _required;
  bool _cancelled = false;

  bool get isRequired => _required;
  bool get isCancelled => _cancelled;

  void promoteToRequired() => _required = true;
  void cancel() => _cancelled = true;
}

abstract interface class DashboardPreparedDeckRepository {
  Future<DashboardPreparedDeck> prepareDeck(
    DashboardPreparedDeckRequest request,
    DashboardPreparationToken token,
  );
}
