import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import 'time_plane.dart';
import 'year_month.dart';

enum DashboardTemporalAnchorChangeReason {
  initial,
  railRetainedChild,
  verticalInputTakeover,
  parentCommitted,
  planeCommitted,
  railVisibilityCommitted,
  directionCommitted,
  debugMonthCommitted,
}

/// The one semantic Y-M-D source used to derive every dashboard plane target.
///
/// Widget-local indices, visible/committed frames and asynchronous data
/// callbacks may observe this value but cannot reconstruct or mutate it.
@immutable
final class DashboardTemporalAnchor {
  DashboardTemporalAnchor({
    required this.visibleYear,
    required this.visibleMonth,
    required this.visibleDay,
    required this.sourcePlane,
    required this.sourceParentQueryKey,
    required this.sourceChildQueryKey,
    required this.sourceChildOrdinal,
    required this.direction,
    required this.filtersRefinementsIdentity,
    required this.revision,
    required this.navigationEpoch,
  }) {
    final month = YearMonth(year: visibleYear, month: visibleMonth);
    if (visibleDay < 1 || visibleDay > month.daysInMonth) {
      throw ArgumentError.value(
        visibleDay,
        'visibleDay',
        'must exist in ${month.isoString}',
      );
    }
    if (revision < 0 || navigationEpoch < 0) {
      throw ArgumentError('Temporal revision/epoch must be nonnegative.');
    }
  }

  final int visibleYear;
  final int visibleMonth;
  final int visibleDay;
  final TimePlane sourcePlane;
  final LedgerQueryKey sourceParentQueryKey;
  final LedgerQueryKey sourceChildQueryKey;
  final int sourceChildOrdinal;
  final LedgerDirection direction;
  final String filtersRefinementsIdentity;
  final int revision;
  final int navigationEpoch;

  YearMonth get visibleYearMonth =>
      YearMonth(year: visibleYear, month: visibleMonth);

  DashboardTemporalAnchor copyWith({
    int? visibleYear,
    int? visibleMonth,
    int? visibleDay,
    TimePlane? sourcePlane,
    LedgerQueryKey? sourceParentQueryKey,
    LedgerQueryKey? sourceChildQueryKey,
    int? sourceChildOrdinal,
    LedgerDirection? direction,
    String? filtersRefinementsIdentity,
    int? revision,
    int? navigationEpoch,
  }) => DashboardTemporalAnchor(
    visibleYear: visibleYear ?? this.visibleYear,
    visibleMonth: visibleMonth ?? this.visibleMonth,
    visibleDay: visibleDay ?? this.visibleDay,
    sourcePlane: sourcePlane ?? this.sourcePlane,
    sourceParentQueryKey: sourceParentQueryKey ?? this.sourceParentQueryKey,
    sourceChildQueryKey: sourceChildQueryKey ?? this.sourceChildQueryKey,
    sourceChildOrdinal: sourceChildOrdinal ?? this.sourceChildOrdinal,
    direction: direction ?? this.direction,
    filtersRefinementsIdentity:
        filtersRefinementsIdentity ?? this.filtersRefinementsIdentity,
    revision: revision ?? this.revision,
    navigationEpoch: navigationEpoch ?? this.navigationEpoch,
  );

  static String filtersRefinementsIdentityOf(CurrentLedgerQueryScope scope) {
    final categories = scope.categoryIds.toList()..sort();
    final partners = scope.partnerIds.toList()..sort();
    final refinements = scope.refinements.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return 'categories:${categories.join(',')}|'
        'partners:${partners.join(',')}|'
        'refinements:${refinements.map((entry) => '${entry.key}=${entry.value}').join(',')}';
  }
}
