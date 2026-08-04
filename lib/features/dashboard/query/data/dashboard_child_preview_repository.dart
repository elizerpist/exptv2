import 'dashboard_child_preview_bundle.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/time_child_summary.dart';

/// Batch read capability for complete first-page child presentations.
///
/// The dashboard requests this before rail interaction. A crossing callback
/// only looks up the already prepared bundle and never calls this interface.
abstract interface class DashboardChildPreviewRepository {
  Future<DashboardChildPreviewBundle> readChildPreviewBundle(
    DashboardChildPreviewBundleRequest request,
  );
}

class DashboardChildPreviewBundleRequest {
  const DashboardChildPreviewBundleRequest({
    required this.parentScope,
    required this.childPeriod,
    required this.requestGeneration,
    this.previewPageSize = DashboardPreviewBudget.defaultRowBudget,
  }) : assert(previewPageSize > 0);

  final CurrentLedgerQueryScope parentScope;
  final TimeChildPeriod childPeriod;
  final int previewPageSize;
  final int requestGeneration;

  String get cacheKey => [
    parentScope.key.value,
    'child:${childPeriod.name}',
    'page:$previewPageSize',
  ].join('|');

  String get requestId => '$cacheKey|generation:$requestGeneration';
}
