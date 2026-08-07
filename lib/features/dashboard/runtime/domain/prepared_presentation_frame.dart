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

/// Constant-time scalar presentation selected by a rail crossing.
///
/// It deliberately contains no transaction-row collection. Equality in the
/// visible lanes is the precomputed [presentationId], never a deep value walk.
@immutable
final class PreparedSummaryFrame {
  const PreparedSummaryFrame({
    required this.queryKey,
    required this.parentQueryKey,
    required this.coreRevision,
    required this.amount,
    required this.count,
    required this.header,
    required this.emptyState,
    required this.logViewportId,
    required this.presentationId,
    required this.amountPresentationId,
    required this.countPresentationId,
  });

  final LedgerQueryKey queryKey;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  final DashboardAmountViewModel amount;
  final DashboardCountViewModel count;
  final DashboardHeaderViewModel header;
  final DashboardEmptyStateViewModel emptyState;
  final int logViewportId;
  final int presentationId;
  final int amountPresentationId;
  final int countPresentationId;

  int get totalMinor => amount.totalMinor;
  String get formattedAmount => amount.formattedAmount;
  int get entryCount => count.entryCount;
}

/// One immutable prepared LogBox payload referenced by its constant-time ID.
///
/// Projection, grouping, ordering and identity creation have already happened
/// before this object can reach the UI isolate's interaction path.
@immutable
final class PreparedLogViewportPayload {
  const PreparedLogViewportPayload({
    required this.viewport,
    required this.logViewportId,
  });

  final DashboardLogViewportState viewport;
  final int logViewportId;

  LedgerQueryKey get queryKey => viewport.queryKey;
  int? get revision => viewport.revision;
  int get entryCount => viewport.entryCount;
  Map<String, Object?>? get nextCursor => viewport.nextCursor;
  List<String> get stableRowIdentities => viewport.stableRowIdentities;
  List<String> get stableAssetIdentities => viewport.stableAssetIdentities;
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
    required this.summary,
    required this.logViewport,
    required this.nextCursor,
    required this.stableRowIdentities,
    required this.stableAssetIdentities,
    required this.frameId,
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
    final amount = DashboardAmountViewModel(
      queryKey: queryKey,
      coreRevision: coreRevision,
      totalMinor: totalMinor,
      formattedAmount: formattedAmount,
    );
    final count = DashboardCountViewModel(
      queryKey: queryKey,
      coreRevision: coreRevision,
      entryCount: entryCount,
      formattedEntryCount: formattedEntryCount,
    );
    final header = DashboardHeaderViewModel(
      queryKey: queryKey,
      coreRevision: coreRevision,
      formattedEntryCount: formattedEntryCount,
    );
    final emptyState = DashboardEmptyStateViewModel(
      isEmpty: entryCount == 0,
      message: entryCount == 0 ? 'Nincs listázható tranzakció' : '',
    );
    final amountPresentationId = Object.hash(
      queryKey,
      coreRevision,
      totalMinor,
      formattedAmount,
    );
    final countPresentationId = Object.hash(
      queryKey,
      coreRevision,
      entryCount,
      formattedEntryCount,
    );
    final logViewportId = logBox.viewportId;
    final summary = PreparedSummaryFrame(
      queryKey: queryKey,
      parentQueryKey: parentQueryKey,
      coreRevision: coreRevision,
      amount: amount,
      count: count,
      header: header,
      emptyState: emptyState,
      logViewportId: logViewportId,
      presentationId: Object.hash(queryKey, coreRevision, presentationDigest),
      amountPresentationId: amountPresentationId,
      countPresentationId: countPresentationId,
    );
    return DashboardPreparedFrame._(
      scope: scope,
      queryKey: queryKey,
      parentQueryKey: parentQueryKey,
      coreRevision: coreRevision,
      summary: summary,
      logViewport: PreparedLogViewportPayload(
        viewport: logBox,
        logViewportId: logViewportId,
      ),
      nextCursor: logBox.nextCursor,
      stableRowIdentities: logBox.stableRowIdentities,
      stableAssetIdentities: logBox.stableAssetIdentities,
      frameId: Object.hash(queryKey, coreRevision, presentationDigest),
      presentationDigest: presentationDigest,
    );
  }

  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey queryKey;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  final PreparedSummaryFrame summary;
  final PreparedLogViewportPayload logViewport;
  final Map<String, Object?>? nextCursor;
  final List<String> stableRowIdentities;
  final List<String> stableAssetIdentities;
  final int frameId;
  final int presentationDigest;

  DashboardAmountViewModel get amount => summary.amount;
  DashboardCountViewModel get count => summary.count;
  DashboardLogViewportState get logBox => logViewport.viewport;
  DashboardHeaderViewModel get header => summary.header;
  DashboardEmptyStateViewModel get emptyState => summary.emptyState;
  int get amountPresentationId => summary.amountPresentationId;
  int get countPresentationId => summary.countPresentationId;
  int get logViewportId => logViewport.logViewportId;
  int get totalMinor => summary.totalMinor;
  int get entryCount => summary.entryCount;
  bool get loading => false;
  bool get stale => false;
  Object? get error => null;
}
