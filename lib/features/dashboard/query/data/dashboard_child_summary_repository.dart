import '../domain/time_child_summary.dart';

/// Typed grouped read capability for the time-rail amount projection.
///
/// It intentionally has no per-preview watch API. The dashboard loads a
/// parent index once, then previews perform only an in-memory lookup.
abstract interface class DashboardChildSummaryRepository {
  Future<DashboardTimeChildSummaryIndex> readChildSummaries(
    DashboardChildSummaryRequest request,
  );
}
