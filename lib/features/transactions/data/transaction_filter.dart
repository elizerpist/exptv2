import '../models/transaction_category.dart';

class TransactionFilter {
  const TransactionFilter({
    this.type = TransactionType.expense,
    this.searchQuery = '',
    this.merchant,
    this.merchantColorHex,
    this.categoryId,
  });

  final TransactionType type;
  final String searchQuery;
  final String? merchant;
  final String? merchantColorHex;
  final int? categoryId;

  TransactionFilter copyWith({
    TransactionType? type,
    String? searchQuery,
    String? merchant,
    String? merchantColorHex,
    int? categoryId,
    bool clearMerchant = false,
    bool clearCategory = false,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      searchQuery: searchQuery ?? this.searchQuery,
      merchant: clearMerchant ? null : merchant ?? this.merchant,
      merchantColorHex: clearMerchant
          ? null
          : merchantColorHex ?? this.merchantColorHex,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    );
  }
}
