import '../models/transaction_category.dart';

class TransactionFilter {
  const TransactionFilter({
    this.type = TransactionType.expense,
    this.searchQuery = '',
    this.merchant,
    this.merchantColorHex,
    this.categoryId,
    this.categoryIds = const <int>{},
  });

  final TransactionType type;
  final String searchQuery;
  final String? merchant;
  final String? merchantColorHex;
  final int? categoryId;
  final Set<int> categoryIds;

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
      categoryId: nextCategoryId,
      categoryIds: nextCategoryIds,
    );
  }
}
