import 'package:flutter/foundation.dart';

import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../query/domain/current_ledger_query_scope.dart';

@immutable
final class DashboardAmountViewModel {
  const DashboardAmountViewModel({
    required this.queryKey,
    required this.coreRevision,
    required this.totalMinor,
    required this.formattedAmount,
  });

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int totalMinor;
  final String formattedAmount;
}

@immutable
final class DashboardCountViewModel {
  const DashboardCountViewModel({
    required this.queryKey,
    required this.coreRevision,
    required this.entryCount,
    required this.formattedEntryCount,
  });

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int entryCount;
  final String formattedEntryCount;
}

@immutable
final class DashboardHeaderViewModel {
  const DashboardHeaderViewModel({
    required this.queryKey,
    required this.coreRevision,
    required this.formattedEntryCount,
  });

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final String formattedEntryCount;
}

@immutable
final class DashboardEmptyStateViewModel {
  const DashboardEmptyStateViewModel({
    required this.isEmpty,
    required this.message,
  });

  final bool isEmpty;
  final String message;
}

/// Fully projected immutable input for one atomically visible dashboard
/// presentation. Amount, count and LogBox identities are validated together.
@immutable
final class DashboardPreparedFrame {
  const DashboardPreparedFrame._({
    required this.scope,
    required this.queryKey,
    required this.parentQueryKey,
    required this.coreRevision,
    required this.amount,
    required this.count,
    required this.logBox,
    required this.header,
    required this.emptyState,
    required this.nextCursor,
    required this.stableRowIdentities,
    required this.stableAssetIdentities,
    required this.frameId,
    required this.amountPresentationId,
    required this.countPresentationId,
    required this.logViewportId,
    required this.presentationDigest,
  });

  factory DashboardPreparedFrame.complete({
    required CurrentLedgerQueryScope scope,
    required LedgerQueryKey parentQueryKey,
    required int coreRevision,
    required int totalMinor,
    required String formattedAmount,
    required int entryCount,
    required String formattedEntryCount,
    required DashboardLogViewportState logBox,
    required int presentationDigest,
  }) {
    if (coreRevision <= 0) {
      throw ArgumentError.value(
        coreRevision,
        'coreRevision',
        'must be greater than zero',
      );
    }
    final queryKey = scope.key;
    if (logBox.queryKey != queryKey ||
        logBox.revision != coreRevision ||
        logBox.entryCount != entryCount ||
        logBox.direction != scope.direction) {
      throw ArgumentError(
        'Prepared LogBox identity must match its frame key, revision, count '
        'and direction.',
      );
    }
    return DashboardPreparedFrame._(
      scope: scope,
      queryKey: queryKey,
      parentQueryKey: parentQueryKey,
      coreRevision: coreRevision,
      amount: DashboardAmountViewModel(
        queryKey: queryKey,
        coreRevision: coreRevision,
        totalMinor: totalMinor,
        formattedAmount: formattedAmount,
      ),
      count: DashboardCountViewModel(
        queryKey: queryKey,
        coreRevision: coreRevision,
        entryCount: entryCount,
        formattedEntryCount: formattedEntryCount,
      ),
      logBox: logBox,
      header: DashboardHeaderViewModel(
        queryKey: queryKey,
        coreRevision: coreRevision,
        formattedEntryCount: formattedEntryCount,
      ),
      emptyState: DashboardEmptyStateViewModel(
        isEmpty: entryCount == 0,
        message: entryCount == 0 ? 'Nincs listázható tranzakció' : '',
      ),
      nextCursor: logBox.nextCursor,
      stableRowIdentities: logBox.stableRowIdentities,
      stableAssetIdentities: logBox.stableAssetIdentities,
      frameId: Object.hash(queryKey, coreRevision, presentationDigest),
      amountPresentationId: Object.hash(
        queryKey,
        coreRevision,
        totalMinor,
        formattedAmount,
      ),
      countPresentationId: Object.hash(
        queryKey,
        coreRevision,
        entryCount,
        formattedEntryCount,
      ),
      logViewportId: logBox.viewportId,
      presentationDigest: presentationDigest,
    );
  }

  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey queryKey;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  final DashboardAmountViewModel amount;
  final DashboardCountViewModel count;
  final DashboardLogViewportState logBox;
  final DashboardHeaderViewModel header;
  final DashboardEmptyStateViewModel emptyState;
  final Map<String, Object?>? nextCursor;
  final List<String> stableRowIdentities;
  final List<String> stableAssetIdentities;
  final int frameId;
  final int amountPresentationId;
  final int countPresentationId;
  final int logViewportId;
  final int presentationDigest;

  int get totalMinor => amount.totalMinor;
  int get entryCount => count.entryCount;
  bool get loading => false;
  bool get stale => false;
  Object? get error => null;
}
