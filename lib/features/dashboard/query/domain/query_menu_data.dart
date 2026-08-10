import 'current_ledger_query_scope.dart';

final class QueryMenuResultSummary {
  const QueryMenuResultSummary({
    required this.entryCount,
    required this.amountScaled100,
  });

  final int entryCount;
  final int amountScaled100;
}

final class QueryMenuAmountDomain {
  const QueryMenuAmountDomain({
    required this.minimumAmountScaled100,
    required this.maximumAmountScaled100,
  });

  final int minimumAmountScaled100;
  final int maximumAmountScaled100;
}

/// One real month represented by the current direction's ledger. This is
/// supplied by the core aggregate boundary, never constructed from a UI date
/// range or a materialized Dart ledger.
final class QueryMenuAvailableMonth {
  const QueryMenuAvailableMonth({required this.year, required this.month})
    : assert(month >= 1 && month <= 12);

  final int year;
  final int month;
}

final class QueryMenuCategoryFacet {
  const QueryMenuCategoryFacet({
    required this.id,
    required this.displayName,
    required this.colorId,
    required this.iconId,
    required this.entryCount,
  });

  final String id;
  final String displayName;
  final String colorId;
  final String iconId;
  final int entryCount;
}

final class QueryMenuPartnerFacet {
  const QueryMenuPartnerFacet({
    required this.id,
    required this.displayName,
    required this.categoryId,
    required this.categoryColorId,
    required this.categoryIconId,
    required this.entryCount,
  });

  final String id;
  final String displayName;
  final String categoryId;
  final String categoryColorId;
  final String categoryIconId;
  final int entryCount;
}

final class QueryMenuData {
  const QueryMenuData({
    required this.result,
    required this.amountDomain,
    required this.availableMonths,
    required this.categories,
    required this.partners,
  });

  final QueryMenuResultSummary result;
  final QueryMenuAmountDomain amountDomain;
  final List<QueryMenuAvailableMonth> availableMonths;
  final List<QueryMenuCategoryFacet> categories;
  final List<QueryMenuPartnerFacet> partners;
}

/// Persisted named Query configuration. It never contains result data.
final class SavedLedgerQuery {
  const SavedLedgerQuery({
    required this.id,
    required this.name,
    required this.scope,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
  });

  final String id;
  final String name;
  final CurrentLedgerQueryScope scope;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
}
