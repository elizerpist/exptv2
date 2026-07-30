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

  final displayEntries = <TransactionLogEntry>[];
  String? previousDate;
  for (final row in window) {
    final date = _dateKey(row.date);
    if (date != previousDate) {
      displayEntries.add(TransactionLogEntry.header(row.date));
      previousDate = date;
    }
    displayEntries.add(row);
  }

  return TransactionLogProjection._(
    entries: List<TransactionLogEntry>.unmodifiable(displayEntries),
    rows: List<TransactionLogEntry>.unmodifiable(window),
    visibleRowCount: window.length,
    totalRowCount: totalRowCount,
    totalDisplayEntryCount: totalRowCount + dateKeys.length,
  );
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
