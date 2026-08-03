import 'package:flutter/foundation.dart';

import '../../query/application/dashboard_presentation_store.dart';
import '../../query/data/dashboard_ledger_repository.dart';

/// Owns only committed LogBox next-page requests. Preview snapshots never
/// enter this lane and the query/store remain the visible-state owners.
class DashboardLogPagingCoordinator extends ChangeNotifier {
  DashboardLogPagingCoordinator({
    required DashboardPresentationStore store,
    required DashboardLedgerRepository repository,
  }) : _store = store,
       _repository = repository;

  final DashboardPresentationStore _store;
  final DashboardLedgerRepository _repository;
  final Set<String> _loadingCursors = <String>{};
  bool _disposed = false;

  int get requestCount => _loadingCursors.length;

  Future<void> loadNextPage() async {
    final snapshot = _store.activeSnapshot;
    if (_disposed ||
        snapshot == null ||
        snapshot.isPreview ||
        snapshot.scope == null ||
        snapshot.nextCursor == null) {
      return;
    }
    final cursor = snapshot.nextCursor!;
    final cursorKey = _cursorKey(cursor);
    if (!_loadingCursors.add('${snapshot.queryKey.value}|$cursorKey')) return;
    try {
      final result = await _repository.read(snapshot.scope!, after: cursor);
      if (_disposed ||
          _store.visibleTarget?.expectedVisibleQueryKey != snapshot.queryKey ||
          (result.scopeKey != null &&
              result.scopeKey != snapshot.queryKey.value)) {
        return;
      }
      final known = snapshot.entries.map((entry) => entry.id).toSet();
      final appended = <DashboardLedgerEntry>[
        ...snapshot.entries,
        for (final entry in result.entries)
          if (known.add(entry.id)) entry,
      ];
      _store.publish(
        snapshot.copyWith(
          generation: snapshot.generation + 1,
          entries: appended,
          nextCursor: result.nextCursor,
          clearNextCursor: result.nextCursor == null,
        ),
      );
    } finally {
      _loadingCursors.remove('${snapshot.queryKey.value}|$cursorKey');
    }
  }

  static String _cursorKey(Map<String, Object?> cursor) {
    final entries = cursor.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join('|');
  }

  @override
  void dispose() {
    _disposed = true;
    _loadingCursors.clear();
    super.dispose();
  }
}
