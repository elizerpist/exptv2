import '../models/transaction_category.dart';

class TransactionFilter {
  const TransactionFilter({
    this.type = TransactionType.expense,
    this.searchQuery = '',
    this.merchant,
    this.categoryId,
  });

  final TransactionType type;
  final String searchQuery;
  final String? merchant;
  final int? categoryId;

  TransactionFilter copyWith({
    TransactionType? type,
    String? searchQuery,
    String? merchant,
    int? categoryId,
    bool clearMerchant = false,
    bool clearCategory = false,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      searchQuery: searchQuery ?? this.searchQuery,
      merchant: clearMerchant ? null : merchant ?? this.merchant,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    );
  }
}
