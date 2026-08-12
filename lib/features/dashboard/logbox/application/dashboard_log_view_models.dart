import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import 'dashboard_log_viewport_state.dart';

export 'dashboard_log_viewport_state.dart';

/// Pure snapshot-to-view-model adapter. It has no repository, navigation,
/// paging, or widget side effects and can be exercised independently.
abstract final class DashboardLogViewModelProjector {
  /// Records compact native row references for one scope. Rich row/group
  /// presentation is projected only when an exact scene/committed window
  /// consumes this payload; navigation and rendering never trigger it.
  static DashboardLogViewportState presentPreparedReferences({
    required CurrentLedgerQueryScope scope,
    required int revision,
    required List<DashboardLedgerEntry> rowTable,
    DashboardLogRowProjectionCache? rowProjectionCache,
    required List<int> rowIndices,
    required int entryCount,
    required Map<String, Object?>? nextCursor,
  }) {
    return DashboardLogViewportState.deferredPreparedReferences(
      scope: scope,
      revision: revision,
      rowTable: rowTable,
      rowProjectionCache: rowProjectionCache,
      rowIndices: rowIndices,
      entryCount: entryCount,
      nextCursor: nextCursor,
    );
  }

  /// Projects rows that already arrive in stable date/time/id descending
  /// order. This performs one contiguous pass and never groups or sorts.
  static DashboardLogViewportState presentPreparedOrdered({
    required CurrentLedgerQueryScope scope,
    required int revision,
    required List<DashboardLedgerEntry> entries,
    required int entryCount,
    required Map<String, Object?>? nextCursor,
  }) => DashboardLogViewportState.deferredPreparedOrdered(
    scope: scope,
    revision: revision,
    entries: entries,
    entryCount: entryCount,
    nextCursor: nextCursor,
  );

  static DashboardLogRowViewModel presentRow(DashboardLedgerEntry entry) =>
      DashboardLogRowViewModel.fromLedgerEntry(entry);
}
