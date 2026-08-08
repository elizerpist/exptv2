import 'package:flutter/foundation.dart';

import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/prepared_dashboard_index.dart';

@immutable
final class PreparedDashboardIndexRequest {
  const PreparedDashboardIndexRequest({
    required this.key,
    required this.filterScope,
    required this.initialYear,
    required this.reason,
  });

  final PreparedDashboardIndexKey key;
  final CurrentLedgerQueryScope filterScope;
  final int initialYear;
  final DataAcquisitionReason reason;
}

final class DashboardIndexPreparationToken {
  DashboardIndexPreparationToken({required this.generation});

  final int generation;
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

abstract interface class PreparedDashboardIndexRepository {
  Future<PreparedDashboardIndex> prepareIndex(
    PreparedDashboardIndexRequest request,
    DashboardIndexPreparationToken token,
  );
}

abstract interface class DashboardCoreRevisionRepository {
  Stream<int> watchCoreRevision();
}

@immutable
final class DashboardCommittedPageRequest {
  const DashboardCommittedPageRequest({
    required this.scope,
    required this.parentQueryKey,
    required this.coreRevision,
    required this.presentationEpoch,
    required this.commitGeneration,
    required this.pageSize,
    required this.pageOrdinal,
    required this.startCursor,
    required this.previousStartCursor,
    required this.reason,
  });

  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  final int presentationEpoch;
  final int commitGeneration;
  final int pageSize;
  final int pageOrdinal;
  final Map<String, Object?>? startCursor;
  final Map<String, Object?>? previousStartCursor;
  final DataAcquisitionReason reason;
}

abstract interface class DashboardCommittedPageRepository {
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  );
}

abstract interface class DashboardDataRuntimeMetrics {
  Map<String, Object?> performanceReport();
}

/// Composition-boundary contract implemented by the native adapter and test
/// fixtures. Navigation/presentation modules never receive this type.
abstract interface class DashboardDataRuntimeRepository
    implements
        PreparedDashboardIndexRepository,
        DashboardCoreRevisionRepository,
        DashboardCommittedPageRepository,
        DashboardDataRuntimeMetrics {}
