import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_log_entry.dart';
import '../models/transaction_record.dart';
import 'recurring_ghost_log_box.dart';
import 'transaction_log_box.dart';

class TransactionLogList extends StatelessWidget {
  const TransactionLogList({
    super.key,
    this.records = const [],
    this.ghostRecords = const [],
    this.entries,
    this.categories = const [],
    this.categoriesById = const <int, TransactionCategory>{},
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
    this.onRenameMerchant,
    this.onResetMerchantName,
  });

  final List<TransactionRecord> records;
  final List<RecurringGhostRecord> ghostRecords;
  final List<TransactionLogEntry>? entries;
  final List<TransactionCategory> categories;
  final Map<int, TransactionCategory> categoriesById;
  final TransactionLogContextCallback onFastFilter;
  final ValueChanged<TransactionRecord> onRecordTap;
  final TransactionDeleteRequest onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;
  final TransactionRenameCallback? onRenameMerchant;
  final TransactionRecordAction? onResetMerchantName;

  @override
  Widget build(BuildContext context) {
    final logEntries = entries ?? _entries();
    if (logEntries.isEmpty) {
      return const Center(
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: logEntries.length,
      itemBuilder: (context, index) {
        final entry = logEntries[index];
        final header = entry.header;
        if (header != null) return _DateHeader(date: header);
        final ghost = entry.ghost;
        if (ghost != null) {
          return RecurringGhostLogBox(
            ghost: ghost,
            category: _categoryForId(ghost.categoryId),
          );
        }
        final record = entry.record!;
        final category = _categoryForId(record.transactionCategoryID);
        return TransactionLogBox(
          record: record,
          category: category,
          onFastFilter: onFastFilter,
          onTap: onRecordTap,
          onDeleteRequested: onDeleteRequested,
          onCategoryFilter: onCategoryFilter,
          onRenameMerchant: onRenameMerchant,
          onResetMerchantName: onResetMerchantName,
        );
      },
    );
  }

  List<TransactionLogEntry> _entries() {
    final entries = <TransactionLogEntry>[];
    String? previousDate;
    final rows = <TransactionLogEntry>[
      for (final record in records) TransactionLogEntry.record(record),
      for (final ghost in ghostRecords) TransactionLogEntry.ghost(ghost),
    ];
    rows.sort(_compareEntries);
    for (final row in rows) {
      if (row.date != previousDate) {
        entries.add(TransactionLogEntry.header(row.date));
        previousDate = row.date;
      }
      entries.add(row);
    }
    return entries;
  }

  TransactionCategory? _categoryForId(int id) {
    final indexed = categoriesById[id];
    if (indexed != null) return indexed;
    for (final category in categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('transaction-date-group-$date'),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
      child: Text(
        date,
        style: const TextStyle(
          color: AppColors.gray500,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

int _compareEntries(TransactionLogEntry left, TransactionLogEntry right) {
  final date = right.date.compareTo(left.date);
  if (date != 0) return date;
  final time = right.time.compareTo(left.time);
  if (time != 0) return time;
  return right.sortId.compareTo(left.sortId);
}
