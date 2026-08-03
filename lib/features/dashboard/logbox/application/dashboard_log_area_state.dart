import '../domain/dashboard_log_models.dart';
import '../../query/domain/scope_summary_metrics.dart';
import 'dashboard_committed_query_snapshot.dart';
import 'dashboard_log_view_models.dart';

/// Explicit presentation states for the dashboard's LogBox area.
///
/// Committed data and data-only rail preview share this narrow immutable UI
/// boundary; only [CurrentQueryController] may commit a query.
sealed class DashboardLogAreaState {
  const DashboardLogAreaState({
    required this.queryKey,
    required this.coreRevision,
  });

  final String queryKey;
  final int? coreRevision;

  /// Preview states are read-only projections of the first-page cache. They
  /// must never trigger paging for the independently committed query.
  bool get isPreview => false;
}

final class DashboardLogInitialLoading extends DashboardLogAreaState {
  const DashboardLogInitialLoading({
    required super.queryKey,
    super.coreRevision,
  });
}

/// A preview scope with exact summary metrics whose first LogBox page has not
/// reached the bounded cache yet. It prevents old committed rows from being
/// relabelled under a new child while preserving the immediate count.
final class DashboardLogPreviewLoading extends DashboardLogAreaState {
  DashboardLogPreviewLoading({required this.metrics})
    : super(
        queryKey: metrics.canonicalQueryKey,
        coreRevision: metrics.coreRevision,
      );

  final ScopeSummaryMetrics metrics;

  @override
  bool get isPreview => true;
}

final class DashboardLogData extends DashboardLogAreaState {
  DashboardLogData({
    required this.snapshot,
    required this.groups,
    List<DashboardDayLogGroupViewModel>? viewGroups,
    required this.nextCursor,
    required this.isLoadingNextPage,
    required this.isStale,
    required this.cacheHit,
  }) : viewGroups =
           viewGroups ?? DashboardLogViewModelProjector.presentGroups(groups),
       super(
         queryKey: snapshot.summaryMetrics.canonicalQueryKey,
         coreRevision: snapshot.summaryMetrics.coreRevision,
       );

  final DashboardLogQuerySnapshot snapshot;
  final List<DashboardDayLogGroup> groups;
  final List<DashboardDayLogGroupViewModel> viewGroups;
  final DashboardDayGroupPageCursor? nextCursor;
  final bool isLoadingNextPage;
  final bool isStale;
  final bool cacheHit;

  bool get hasNextPage => nextCursor != null;

  @override
  bool get isPreview => snapshot is DashboardPreviewQuerySnapshot;

  DashboardLogData copyWith({
    List<DashboardDayLogGroup>? groups,
    List<DashboardDayLogGroupViewModel>? viewGroups,
    DashboardDayGroupPageCursor? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingNextPage,
    bool? isStale,
    bool? cacheHit,
  }) => DashboardLogData(
    snapshot: snapshot,
    groups: groups ?? this.groups,
    viewGroups: viewGroups ?? (groups == null ? this.viewGroups : null),
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

  final DashboardLogQuerySnapshot snapshot;
  final bool cacheHit;

  @override
  bool get isPreview => snapshot is DashboardPreviewQuerySnapshot;
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
