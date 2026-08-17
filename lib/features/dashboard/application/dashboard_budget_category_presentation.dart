import 'package:flutter/foundation.dart';

import '../query/application/current_query_controller.dart';
import '../query/domain/ledger_direction.dart';
import 'transaction_direction_controller.dart';

/// Immutable presentation-only category identity for the Budget avatar rail.
///
/// This intentionally carries no budget calculation, selected-category state,
/// or repository handle. Its order is the already-authoritative order from
/// the active applied Query facet snapshot.
@immutable
final class BudgetCategoryAvatarPresentationItem {
  const BudgetCategoryAvatarPresentationItem({
    required this.id,
    required this.displayName,
    required this.colorId,
    required this.iconId,
  });

  final String id;
  final String displayName;
  final String colorId;
  final String iconId;
}

/// Derives the current-direction category rail input without performing I/O.
///
/// The applied Query owner remains the sole owner of category facets. This
/// adapter listens only for already-published Query/direction changes and
/// emits a new immutable list only when its lightweight visual identity has
/// actually changed.
final class DashboardBudgetCategoryPresentation
    extends ValueNotifier<List<BudgetCategoryAvatarPresentationItem>> {
  DashboardBudgetCategoryPresentation({
    required CurrentQueryController currentQuery,
    required TransactionDirectionController transactionDirection,
  }) : _currentQuery = currentQuery,
       _transactionDirection = transactionDirection,
       super(const <BudgetCategoryAvatarPresentationItem>[]) {
    _currentQuery.addListener(_refresh);
    _transactionDirection.addListener(_refresh);
    _refresh();
  }

  final CurrentQueryController _currentQuery;
  final TransactionDirectionController _transactionDirection;

  void _refresh() {
    final direction = switch (_transactionDirection.direction) {
      TransactionDirection.income => LedgerDirection.income,
      TransactionDirection.expense => LedgerDirection.expense,
    };
    final facets =
        _currentQuery.facetPresentationFor(direction)?.categories ?? const [];
    final next = List<BudgetCategoryAvatarPresentationItem>.unmodifiable([
      for (final facet in facets)
        BudgetCategoryAvatarPresentationItem(
          id: facet.id,
          displayName: facet.displayName,
          colorId: facet.colorId,
          iconId: facet.iconId,
        ),
    ]);
    if (_sameItems(value, next)) return;
    value = next;
  }

  bool _sameItems(
    List<BudgetCategoryAvatarPresentationItem> left,
    List<BudgetCategoryAvatarPresentationItem> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      final previous = left[index];
      final next = right[index];
      if (previous.id != next.id ||
          previous.displayName != next.displayName ||
          previous.colorId != next.colorId ||
          previous.iconId != next.iconId) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _currentQuery.removeListener(_refresh);
    _transactionDirection.removeListener(_refresh);
    super.dispose();
  }
}
