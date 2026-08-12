import 'package:flutter/foundation.dart';

import '../../logbox/application/committed_log_viewport_cache.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/dashboard_directional_query_set.dart';
import '../../query/domain/ledger_direction.dart';
import '../domain/prepared_dashboard_index.dart';

@immutable
final class PreparedDashboardIndexRequest {
  PreparedDashboardIndexRequest({
    required this.key,
    CurrentLedgerQueryScope? filterScope,
    DashboardDirectionalQuerySet? directionalQueries,
    required this.initialYear,
    required this.reason,
  }) : directionalQueries =
           directionalQueries ??
           DashboardDirectionalQuerySet.fromInitial(
             _requireLegacyFilterScope(filterScope),
           ),
       filterScope = filterScope ?? directionalQueries!.income;

  static CurrentLedgerQueryScope _requireLegacyFilterScope(
    CurrentLedgerQueryScope? scope,
  ) {
    if (scope == null) {
      throw ArgumentError(
        'Prepared dashboard index requests require directional queries.',
      );
    }
    return scope;
  }

  final PreparedDashboardIndexKey key;

  /// Compatibility projection for the one-template bootstrap path. New
  /// prepared-index consumers use [directionalQueries] exclusively.
  final CurrentLedgerQueryScope filterScope;
  final DashboardDirectionalQuerySet directionalQueries;
  final int initialYear;
  final DataAcquisitionReason reason;
}

final class DashboardIndexPreparationToken {
  DashboardIndexPreparationToken({
    required this.generation,
    this.reason = DataAcquisitionReason.query,
  });

  final int generation;
  final DataAcquisitionReason reason;
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

/// Optional narrow acquisition capability. The sole dashboard index is still
/// composed and published by [DashboardDataRuntime]; this adapter merely
/// acquires one immutable directional partition when the other partition is
/// already exact for the same core revision.
abstract interface class PreparedDashboardIndexPartitionRepository {
  Future<PreparedDashboardIndex> prepareIndexPartition(
    PreparedDashboardIndexPartitionRequest request,
    DashboardIndexPreparationToken token,
  );
}

/// Optional native capability for stopping obsolete foreground Query work.
///
/// The Dart token still protects publication ownership. This capability keeps
/// a superseded MethodChannel request from needlessly finishing native SQL,
/// mapping, and serialization after its result can no longer be published.
abstract interface class PreparedDashboardIndexCancellationRepository {
  Future<void> cancelPreparedIndex(DashboardIndexPreparationToken token);
}

@immutable
final class PreparedDashboardIndexPartitionRequest {
  PreparedDashboardIndexPartitionRequest({
    required this.request,
    required this.direction,
  }) {
    if (request.directionalQueries.scopeFor(direction).direction != direction) {
      throw ArgumentError('A prepared partition must own its direction.');
    }
  }

  final PreparedDashboardIndexRequest request;
  final LedgerDirection direction;

  CurrentLedgerQueryScope get scope =>
      request.directionalQueries.scopeFor(direction);
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
