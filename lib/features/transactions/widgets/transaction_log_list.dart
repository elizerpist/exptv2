import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import 'recurring_ghost_log_box.dart';
import 'transaction_log_box.dart';

class TransactionLogList extends StatelessWidget {
  const TransactionLogList({
    super.key,
    required this.records,
    this.ghostRecords = const [],
    required this.categories,
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
    this.onRenameMerchant,
    this.onResetMerchantName,
  });

  final List<TransactionRecord> records;
  final List<RecurringGhostRecord> ghostRecords;
  final List<TransactionCategory> categories;
  final TransactionLogContextCallback onFastFilter;
  final ValueChanged<TransactionRecord> onRecordTap;
  final ValueChanged<TransactionRecord> onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;
  final TransactionRenameCallback? onRenameMerchant;
  final TransactionRecordAction? onResetMerchantName;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty && ghostRecords.isEmpty) {
      return const Center(
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }
    final entries = _entries();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final header = entry.header;
        if (header != null) return _DateHeader(date: header);
        final ghost = entry.ghost;
        if (ghost != null) {
          return RecurringGhostLogBox(
            ghost: ghost,
            category: _categoryForGhost(ghost),
          );
        }
        final record = entry.record!;
        final category = _categoryFor(record);
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

  List<_LogListEntry> _entries() {
    final entries = <_LogListEntry>[];
    String? previousDate;
    final rows = <_LogListEntry>[
      for (final record in records) _LogListEntry.record(record),
      for (final ghost in ghostRecords) _LogListEntry.ghost(ghost),
    ];
    rows.sort((left, right) {
      final date = right.date.compareTo(left.date);
      if (date != 0) return date;
      final time = right.time.compareTo(left.time);
      if (time != 0) return time;
      return right.sortId.compareTo(left.sortId);
    });
    for (final row in rows) {
      if (row.date != previousDate) {
        entries.add(_LogListEntry.header(row.date));
        previousDate = row.date;
      }
      entries.add(row);
    }
    return entries;
  }

  TransactionCategory? _categoryFor(TransactionRecord record) {
    for (final category in categories) {
      if (category.transactionCategoryID == record.transactionCategoryID) {
        return category;
      }
    }
    return null;
  }

  TransactionCategory? _categoryForGhost(RecurringGhostRecord ghost) {
    for (final category in categories) {
      if (category.transactionCategoryID == ghost.categoryId) {
        return category;
      }
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

class _LogListEntry {
  const _LogListEntry._({this.header, this.record, this.ghost});

  factory _LogListEntry.header(String date) => _LogListEntry._(header: date);
  factory _LogListEntry.record(TransactionRecord record) =>
      _LogListEntry._(record: record);
  factory _LogListEntry.ghost(RecurringGhostRecord ghost) =>
      _LogListEntry._(ghost: ghost);

  final String? header;
  final TransactionRecord? record;
  final RecurringGhostRecord? ghost;

  String get date => header ?? record?.date ?? ghost!.date;
  String get time => record?.time ?? ghost?.time ?? '';
  int get sortId => record?.id ?? ghost?.id ?? 0;
}
