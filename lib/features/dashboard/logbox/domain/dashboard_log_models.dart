import 'package:flutter/foundation.dart';

import '../../query/data/dashboard_ledger_repository.dart';
import '../../time_navigation/domain/local_date.dart';

/// Keyset cursor for complete-day LogBox pages.
///
/// The next page may contain only dates strictly older than this value, so a
/// local civil day can never be split between two page payloads.
@immutable
class DashboardDayGroupPageCursor {
  const DashboardDayGroupPageCursor({
    required this.beforeLocalDateExclusive,
  });

  final LocalDate beforeLocalDateExclusive;

  @override
  bool operator ==(Object other) =>
      other is DashboardDayGroupPageCursor &&
      other.beforeLocalDateExclusive == beforeLocalDateExclusive;

  @override
  int get hashCode => beforeLocalDateExclusive.hashCode;
}

/// Immutable rows belonging to one persisted Europe/Budapest calendar day.
@immutable
class DashboardDayLogGroup {
  const DashboardDayLogGroup({required this.localDate, required this.rows});

  final LocalDate localDate;
  final List<DashboardLedgerEntry> rows;
}

/// One immutable page of complete LogBox day groups.
@immutable
class DashboardDayGroupPage {
  const DashboardDayGroupPage({
    required this.canonicalQueryKey,
    required this.coreRevision,
    required this.groups,
    required this.nextCursor,
  });

  final String canonicalQueryKey;
  final int coreRevision;
  final List<DashboardDayLogGroup> groups;
  final DashboardDayGroupPageCursor? nextCursor;

  bool get hasNextPage => nextCursor != null;

  int get rowCount => groups.fold<int>(
    0,
    (count, group) => count + group.rows.length,
  );
}
