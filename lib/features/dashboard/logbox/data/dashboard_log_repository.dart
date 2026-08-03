import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/dashboard_log_models.dart';

/// Read-only page boundary for complete-day dashboard LogBox data.
///
/// It deliberately does not own the current scope or a watch subscription;
/// `CurrentQueryController` remains the one committed query owner.
abstract interface class DashboardLogPageRepository {
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  });
}
