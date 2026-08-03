import 'package:flutter/foundation.dart';

import '../domain/dashboard_log_models.dart';
import 'dashboard_committed_query_snapshot.dart';
import 'dashboard_log_view_models.dart';

/// Explicit presentation states for the dashboard's committed LogBox area.
sealed class DashboardLogAreaState {
  const DashboardLogAreaState({
    required this.queryKey,
    required this.coreRevision,
  });

  final String queryKey;
  final int? coreRevision;
}

final class DashboardLogInitialLoading extends DashboardLogAreaState {
  const DashboardLogInitialLoading({
    required super.queryKey,
    super.coreRevision,
  });
}

final class DashboardLogData extends DashboardLogAreaState {
  DashboardLogData({
    required this.snapshot,
    required this.groups,
    required this.nextCursor,
    required this.isLoadingNextPage,
    required this.isStale,
    required this.cacheHit,
  }) : viewGroups = DashboardLogViewModelProjector.presentGroups(groups),
       super(
         queryKey: snapshot.summaryMetrics.canonicalQueryKey,
         coreRevision: snapshot.summaryMetrics.coreRevision,
       );

  final DashboardCommittedQuerySnapshot snapshot;
  final List<DashboardDayLogGroup> groups;
  final List<DashboardDayLogGroupViewModel> viewGroups;
  final DashboardDayGroupPageCursor? nextCursor;
  final bool isLoadingNextPage;
  final bool isStale;
  final bool cacheHit;

  bool get hasNextPage => nextCursor != null;

  DashboardLogData copyWith({
    List<DashboardDayLogGroup>? groups,
    DashboardDayGroupPageCursor? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingNextPage,
    bool? isStale,
    bool? cacheHit,
  }) => DashboardLogData(
    snapshot: snapshot,
    groups: groups ?? this.groups,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
    isStale: isStale ?? this.isStale,
    cacheHit: cacheHit ?? this.cacheHit,
  );
}

final class DashboardLogEmpty extends DashboardLogAreaState {
  DashboardLogEmpty({required this.snapshot, required this.cacheHit})
    : super(
        queryKey: snapshot.summaryMetrics.canonicalQueryKey,
        coreRevision: snapshot.summaryMetrics.coreRevision,
      );

  final DashboardCommittedQuerySnapshot snapshot;
  final bool cacheHit;
}

final class DashboardLogError extends DashboardLogAreaState {
  const DashboardLogError({
    required super.queryKey,
    required this.error,
    this.previousData,
    super.coreRevision,
  });

  final Object error;
  final DashboardLogData? previousData;
}
