import 'transaction_log_entry.dart';

class TransactionLogProjection {
  const TransactionLogProjection._({
    required this.entries,
    required this.rows,
    required this.visibleRowCount,
    required this.totalRowCount,
    required this.totalDisplayEntryCount,
  });

  final List<TransactionLogEntry> entries;
  final List<TransactionLogEntry> rows;
  final int visibleRowCount;
  final int totalRowCount;
  final int totalDisplayEntryCount;

  bool get hasMore => visibleRowCount < totalRowCount;
}

TransactionLogProjection projectTransactionLogEntries(
  Iterable<TransactionLogEntry> source, {
  required int rowLimit,
}) {
  final limit = rowLimit < 0 ? 0 : rowLimit;
  final window = <TransactionLogEntry>[];
  final dateKeys = <String>{};
  var totalRowCount = 0;
  final canSortCompleteList =
      source is List<TransactionLogEntry> && limit >= source.length;

  for (final candidate in source) {
    if (candidate.isHeader) continue;
    totalRowCount += 1;
    dateKeys.add(_dateKey(candidate.date));
    if (canSortCompleteList) {
      window.add(candidate);
    } else {
      _insertBoundedLogEntry(window, candidate, limit);
    }
  }
  if (canSortCompleteList) {
    window.sort(_compareEntries);
  }

  return materializeOrderedTransactionLogEntries(
    window,
    rowLimit: window.length,
    totalRowCount: totalRowCount,
    totalDisplayEntryCount: totalRowCount + dateKeys.length,
  );
}

/// Materializes a bounded display window from rows that are already in the
/// canonical newest-first order.
///
/// Callers that cache a complete logical ordering should also pass its total
/// counts. The materializer then touches only the requested prefix and never
/// rescans or resorts the complete source as a paging limit grows.
TransactionLogProjection materializeOrderedTransactionLogEntries(
  List<TransactionLogEntry> orderedRows, {
  required int rowLimit,
  int? totalRowCount,
  int? totalDisplayEntryCount,
}) {
  final limit = rowLimit < 0 ? 0 : rowLimit;
  final logicalRowCount = totalRowCount ?? orderedRows.length;
  final visibleRowCount = limit.clamp(0, orderedRows.length);
  final displayEntries = <TransactionLogEntry>[];
  String? previousDate;
  for (var index = 0; index < visibleRowCount; index += 1) {
    final row = orderedRows[index];
    final date = _dateKey(row.date);
    if (date != previousDate) {
      displayEntries.add(TransactionLogEntry.header(row.date));
      previousDate = date;
    }
    displayEntries.add(row);
  }

  return TransactionLogProjection._(
    entries: List<TransactionLogEntry>.unmodifiable(displayEntries),
    rows: List<TransactionLogEntry>.unmodifiable(
      orderedRows.take(visibleRowCount),
    ),
    visibleRowCount: visibleRowCount,
    totalRowCount: logicalRowCount,
    totalDisplayEntryCount:
        totalDisplayEntryCount ??
        logicalRowCount + _orderedDateCount(orderedRows),
  );
}

int _orderedDateCount(List<TransactionLogEntry> orderedRows) {
  var count = 0;
  String? previousDate;
  for (final row in orderedRows) {
    final date = _dateKey(row.date);
    if (date == previousDate) continue;
    previousDate = date;
    count += 1;
  }
  return count;
}

int _compareEntries(TransactionLogEntry left, TransactionLogEntry right) {
  final date = _dateKey(right.date).compareTo(_dateKey(left.date));
  if (date != 0) return date;
  final time = right.time.compareTo(left.time);
  if (time != 0) return time;
  return right.sortId.compareTo(left.sortId);
}

String _dateKey(String value) => value.trim().replaceAll('.', '-');

void _insertBoundedLogEntry(
  List<TransactionLogEntry> window,
  TransactionLogEntry candidate,
  int limit,
) {
  if (limit <= 0) return;
  var low = 0;
  var high = window.length;
  while (low < high) {
    final middle = low + ((high - low) >> 1);
    if (_compareEntries(window[middle], candidate) <= 0) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  if (window.length >= limit && low >= limit) return;
  window.insert(low, candidate);
  if (window.length > limit) window.removeLast();
}
