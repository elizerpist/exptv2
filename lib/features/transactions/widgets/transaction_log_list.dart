import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import 'transaction_log_box.dart';

class TransactionLogList extends StatelessWidget {
  const TransactionLogList({
    super.key,
    required this.records,
    required this.categories,
    required this.onFastFilter,
  });

  final List<TransactionRecord> records;
  final List<TransactionCategory> categories;
  final ValueChanged<String> onFastFilter;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final category = _categoryFor(record);
        return TransactionLogBox(
          record: record,
          category: category,
          onFastFilter: onFastFilter,
        );
      },
    );
  }

  TransactionCategory? _categoryFor(TransactionRecord record) {
    for (final category in categories) {
      if (category.transactionCategoryID == record.transactionCategoryID) {
        return category;
      }
    }
    return null;
  }
}
