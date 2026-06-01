import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_log_entry.dart';
import '../models/transaction_record.dart';
import 'recurring_ghost_log_box.dart';
import 'transaction_log_box.dart';

class TransactionLogList extends StatefulWidget {
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
    this.onLoadMore,
    this.hasMore = false,
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
  final VoidCallback? onLoadMore;
  final bool hasMore;

  @override
  State<TransactionLogList> createState() => _TransactionLogListState();
}

class _TransactionLogListState extends State<TransactionLogList> {
  static const _loadMoreThreshold = 720.0;
  static const _cacheExtent = 1200.0;

  bool _loadMoreScheduled = false;
  int? _lastRequestedEntryCount;

  @override
  void didUpdateWidget(covariant TransactionLogList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sourceEntryCount(oldWidget) != _sourceEntryCount(widget) ||
        oldWidget.hasMore != widget.hasMore) {
      _loadMoreScheduled = false;
      _lastRequestedEntryCount = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logEntries = widget.entries ?? _entries();
    if (logEntries.isEmpty) {
      return const Center(
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) =>
          _handleScrollNotification(notification, logEntries.length),
      child: ListView.builder(
        cacheExtent: _cacheExtent,
        addAutomaticKeepAlives: false,
        addSemanticIndexes: false,
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: logEntries.length,
        itemBuilder: (context, index) {
          final entry = logEntries[index];
          final header = entry.header;
          if (header != null) return _DateHeader(date: header);
          final ghost = entry.ghost;
          if (ghost != null) {
            return RecurringGhostLogBox(
              key: ValueKey('recurring-ghost-log-row-${ghost.id}'),
              ghost: ghost,
              category: _categoryForId(ghost.categoryId),
            );
          }
          final record = entry.record!;
          final category = _categoryForId(record.transactionCategoryID);
          return TransactionLogBox(
            key: ValueKey('transaction-log-row-${record.id}'),
            record: record,
            category: category,
            onFastFilter: widget.onFastFilter,
            onTap: widget.onRecordTap,
            onDeleteRequested: widget.onDeleteRequested,
            onCategoryFilter: widget.onCategoryFilter,
            onRenameMerchant: widget.onRenameMerchant,
            onResetMerchantName: widget.onResetMerchantName,
          );
        },
      ),
    );
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    int entryCount,
  ) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        !widget.hasMore ||
        widget.onLoadMore == null ||
        notification.metrics.extentAfter >= _loadMoreThreshold ||
        _loadMoreScheduled ||
        _lastRequestedEntryCount == entryCount) {
      return false;
    }

    _loadMoreScheduled = true;
    _lastRequestedEntryCount = entryCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMoreScheduled = false;
      if (!widget.hasMore) return;
      widget.onLoadMore?.call();
    });
    return false;
  }

  List<TransactionLogEntry> _entries() {
    final entries = <TransactionLogEntry>[];
    String? previousDate;
    final rows = <TransactionLogEntry>[
      for (final record in widget.records) TransactionLogEntry.record(record),
      for (final ghost in widget.ghostRecords) TransactionLogEntry.ghost(ghost),
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
    final indexed = widget.categoriesById[id];
    if (indexed != null) return indexed;
    for (final category in widget.categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }

  int _sourceEntryCount(TransactionLogList list) =>
      list.entries?.length ?? list.records.length + list.ghostRecords.length;
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
