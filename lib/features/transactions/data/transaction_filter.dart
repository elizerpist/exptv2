import '../models/transaction_category.dart';

class TransactionFilter {
  const TransactionFilter({
    this.type = TransactionType.expense,
    this.searchQuery = '',
    this.merchant,
    this.merchantColorHex,
    this.merchantFilters = const <String>{},
    this.categoryId,
    this.categoryIds = const <int>{},
  });

  final TransactionType type;
  final String searchQuery;
  final String? merchant;
  final String? merchantColorHex;
  final Set<String> merchantFilters;
  final int? categoryId;
  final Set<int> categoryIds;

  Set<String> get effectiveMerchants {
    if (merchantFilters.isNotEmpty) return merchantFilters;
    final value = merchant?.trim();
    if (value == null || value.isEmpty) return const <String>{};
    return <String>{value};
  }

  Set<int> get effectiveCategoryIds {
    if (categoryIds.isNotEmpty) return categoryIds;
    final id = categoryId;
    if (id == null) return const <int>{};
    return <int>{id};
  }

  TransactionFilter copyWith({
    TransactionType? type,
    String? searchQuery,
    String? merchant,
    String? merchantColorHex,
    Set<String>? merchantFilters,
    int? categoryId,
    Set<int>? categoryIds,
    bool clearMerchant = false,
    bool clearCategory = false,
  }) {
    final nextCategoryIds = clearCategory
        ? const <int>{}
        : categoryIds ?? this.categoryIds;
    final nextCategoryId = clearCategory
        ? null
        : categoryIds != null
        ? (categoryIds.length == 1 ? categoryIds.first : null)
        : categoryId ?? this.categoryId;
    return TransactionFilter(
      type: type ?? this.type,
      searchQuery: searchQuery ?? this.searchQuery,
      merchant: clearMerchant ? null : merchant ?? this.merchant,
      merchantColorHex: clearMerchant
          ? null
          : merchantColorHex ?? this.merchantColorHex,
      merchantFilters: clearMerchant
          ? const <String>{}
          : merchantFilters ?? this.merchantFilters,
      categoryId: nextCategoryId,
      categoryIds: nextCategoryIds,
    );
  }
}
