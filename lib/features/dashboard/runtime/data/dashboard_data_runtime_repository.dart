import 'package:flutter/foundation.dart';

import '../domain/prepared_presentation_frame.dart';
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
    required this.reason,
  });

  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  final int presentationEpoch;
  final int commitGeneration;
  final int pageSize;
  final DataAcquisitionReason reason;
}

abstract interface class DashboardCommittedPageRepository {
  Future<DashboardPreparedFrame> readCommittedPage(
    DashboardCommittedPageRequest request, {
    required Map<String, Object?> after,
    required DashboardPreparedFrame currentFrame,
  });
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
