import 'package:flutter/material.dart';

import '../models/transaction_category.dart';
import 'category_color_manager.dart';

class CategoryColorResolver {
  const CategoryColorResolver._();

  static Color color({
    TransactionCategory? category,
    String? snapshotHex,
    Color? fallback,
  }) {
    final resolvedCategory = category;
    if (resolvedCategory != null) return resolvedCategory.slotColor;
    final hex = snapshotHex?.trim();
    if (hex != null && hex.isNotEmpty) {
      return CategoryColorManager.fromHex(hex);
    }
    return fallback ?? CategoryColorManager.color(null);
  }

  static TransactionCategory? findById(
    Iterable<TransactionCategory> categories,
    int? id,
  ) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }
}
