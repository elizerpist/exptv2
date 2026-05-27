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
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
  });

  final List<TransactionRecord> records;
  final List<TransactionCategory> categories;
  final TransactionLogContextCallback onFastFilter;
  final ValueChanged<TransactionRecord> onRecordTap;
  final ValueChanged<TransactionRecord> onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;

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
    final entries = _entries();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final header = entry.header;
        if (header != null) return _DateHeader(date: header);
        final record = entry.record!;
        final category = _categoryFor(record);
        return TransactionLogBox(
          record: record,
          category: category,
          onFastFilter: onFastFilter,
          onTap: onRecordTap,
          onDeleteRequested: onDeleteRequested,
          onCategoryFilter: onCategoryFilter,
        );
      },
    );
  }

  List<_LogListEntry> _entries() {
    final entries = <_LogListEntry>[];
    String? previousDate;
    for (final record in records) {
      if (record.date != previousDate) {
        entries.add(_LogListEntry.header(record.date));
        previousDate = record.date;
      }
      entries.add(_LogListEntry.record(record));
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
  const _LogListEntry._({this.header, this.record});

  factory _LogListEntry.header(String date) => _LogListEntry._(header: date);
  factory _LogListEntry.record(TransactionRecord record) =>
      _LogListEntry._(record: record);

  final String? header;
  final TransactionRecord? record;
}
