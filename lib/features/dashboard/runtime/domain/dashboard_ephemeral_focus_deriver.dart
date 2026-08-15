import 'package:flutter/foundation.dart';

import '../../logbox/application/committed_vertical_geometry_manifest.dart';
import '../../logbox/application/dashboard_log_view_models.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/dashboard_directional_query_set.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/year_month.dart';
import 'prepared_dashboard_index.dart';
import 'dashboard_focus_membership_seed.dart';
import 'prepared_presentation_frame.dart';

/// Compiles the temporary focus overlay from an already committed base index.
///
/// It has no repository/channel capability. The seed was carried by the base
/// prepared partition before the pointer interaction, so a Category tap or
/// Partner swipe can create an exact independent presentation without
/// mutating the committed Query or reading Room.
abstract final class DashboardEphemeralFocusDeriver {
  /// Compatibility entry point for callers that only need the immutable
  /// focused presentation. New focus publication reads [deriveFast] metrics
  /// so diagnostics cannot call a prepared membership selection a hit while
  /// concealing worker or base-scan work.
  static PreparedDashboardIndex derive({
    required PreparedDashboardIndex base,
    required DashboardDirectionalQuerySet effectiveQueries,
    required LedgerDirection focusedDirection,
    required String? categoryFocusId,
    required String? partnerFocusId,
    required int initialYear,
    required int generation,
  }) => deriveFast(
    base: base,
    effectiveQueries: effectiveQueries,
    focusedDirection: focusedDirection,
    categoryFocusId: categoryFocusId,
    partnerFocusId: partnerFocusId,
    initialYear: initialYear,
    generation: generation,
  ).index;

  /// Derives an exact focused presentation directly from compact membership
  /// ordinals already retained by [base]. It intentionally has no isolate,
  /// repository or serialization boundary: a prepared hit is immediately
  /// usable input, not a request to copy the complete base index elsewhere.
  static DashboardEphemeralFocusDerivation deriveFast({
    required PreparedDashboardIndex base,
    required DashboardDirectionalQuerySet effectiveQueries,
    required LedgerDirection focusedDirection,
    required String? categoryFocusId,
    required String? partnerFocusId,
    required int initialYear,
    required int generation,
  }) {
    final stopwatch = Stopwatch()..start();
    if (generation <= 0) {
      throw ArgumentError.value(generation, 'generation', 'must be positive');
    }
    if (categoryFocusId == null && partnerFocusId == null) {
      throw ArgumentError('Ephemeral derivation needs at least one focus.');
    }
    final focusedScope = effectiveQueries.scopeFor(focusedDirection);
    final basePartition = base.partitionFor(focusedDirection);
    final seed = basePartition.focusMembershipSeed;
    if (seed == null) {
      throw StateError(
        'The exact base partition has no prepared focus membership seed.',
      );
    }
    final selected = seed.select(
      categoryId: categoryFocusId,
      partnerId: partnerFocusId,
    );

    final key = PreparedDashboardIndexKey.fromDirectionalQuerySet(
      queries: effectiveQueries,
      coreRevision: base.coreRevision,
      pageSize: base.pageSize,
      yearWindowStart: base.key.yearWindowStart,
      yearWindowEndInclusive: base.key.yearWindowEndInclusive,
      modelVersion: base.key.modelVersion,
    );
    final universe = PreparedDashboardIndexAssembly.zeroUniverse(
      key: key,
      directionalQueries: effectiveQueries,
      initialYear: initialYear,
      directions: <LedgerDirection>[focusedDirection],
    );
    final accumulators = <LedgerQueryKey, _FocusFrameAccumulator>{};
    var selectedIdentityDigest = 0;
    for (final ordinal in selected.entryIndices) {
      final entry = seed.entryAt(ordinal);
      if (entry.direction != focusedDirection.name) {
        throw StateError('Focus seed contains another direction.');
      }
      selectedIdentityDigest = Object.hash(selectedIdentityDigest, entry.id);
      for (final scope in _scopesForEntry(focusedScope, entry)) {
        final canonical = universe.scopes[scope.key];
        // A restrictive base temporal filter intentionally omits unavailable
        // hierarchy nodes from the immutable universe.
        if (canonical == null) continue;
        accumulators
            .putIfAbsent(canonical.key, () => _FocusFrameAccumulator(canonical))
            .add(ordinal, seed);
      }
    }

    final focusedFrames = <LedgerQueryKey, DashboardPreparedFrame>{
      for (final accumulator in accumulators.values)
        accumulator.scope.key: accumulator.toPreparedFrame(
          coreRevision: base.coreRevision,
          pageSize: base.pageSize,
        ),
    };
    final inactiveDirection = switch (focusedDirection) {
      LedgerDirection.income => LedgerDirection.expense,
      LedgerDirection.expense => LedgerDirection.income,
    };
    final inactive = base.partitionFor(inactiveDirection);
    final geometrySeed = _geometrySeed(seed, selected.entryIndices);
    // The focused direction owns only the compact derived frames/catalogs.
    // The untouched directional partition remains a reference to [base], so
    // a focus interaction never reconstructs or copies the other universe.
    final focused = PreparedDashboardIndex.focusedDirectionalOverlay(
      base: base,
      key: key,
      focusedDirection: focusedDirection,
      focusedFrames: focusedFrames,
      focusedCatalogs: universe.catalogs,
      focusedScopes: universe.scopes,
      focusedOrigins: <LedgerQueryKey, DashboardDataOrigin>{
        for (final frame in focusedFrames.values)
          frame.queryKey: DashboardDataOrigin.preparedIndex,
      },
      focusedGeometrySeed: geometrySeed,
      generation: generation,
      contentDigest: Object.hash(
        base.contentDigest,
        focusedScope.key,
        categoryFocusId,
        partnerFocusId,
        selectedIdentityDigest,
      ),
      preparedAt: DateTime.now().toUtc(),
      buildMetrics: base.buildMetrics.copyWith(
        dartProjectionDurationMicros: stopwatch.elapsedMicroseconds,
        frameCount: inactive.frames.length + focusedFrames.length,
        estimatedIndexBytes:
            base.buildMetrics.estimatedIndexBytes + selected.entryCount * 4,
      ),
    );
    stopwatch.stop();
    final index = focused.withBuildMetrics(
      focused.buildMetrics.copyWith(
        dartProjectionDurationMicros: stopwatch.elapsedMicroseconds,
      ),
    );
    return DashboardEphemeralFocusDerivation(
      index: index,
      membershipOrdinalCount: selected.entryCount,
      membershipLookupMicros: selected.membershipLookupMicros,
      intersectionMicros: selected.intersectionMicros,
      rootProjectionMicros: stopwatch.elapsedMicroseconds,
      reusedPreparedRows: selected.entryCount,
    );
  }

  static Iterable<CurrentLedgerQueryScope> _scopesForEntry(
    CurrentLedgerQueryScope template,
    DashboardLedgerEntry entry,
  ) sync* {
    final date = _dateFromEpochDay(entry.bookedLocalEpochDay);
    yield template.copyWith(timeScope: const AllTimeScope());
    yield template.copyWith(timeScope: YearScope(date.year));
    yield template.copyWith(
      timeScope: MonthScope(YearMonth(year: date.year, month: date.month)),
    );
    yield template.copyWith(timeScope: DayScope(date));
  }

  static List<CommittedVerticalGeometryDayBucket> _geometrySeed(
    DashboardFocusMembershipSeed seed,
    DashboardFocusOrdinalSet ordinals,
  ) {
    final counts = <int, int>{};
    for (final ordinal in ordinals) {
      final entry = seed.entryAt(ordinal);
      counts.update(
        entry.bookedLocalEpochDay,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final days = counts.keys.toList()
      ..sort((left, right) => right.compareTo(left));
    return List<CommittedVerticalGeometryDayBucket>.unmodifiable(
      days.map(
        (day) => CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: day,
          entryCount: counts[day]!,
        ),
      ),
    );
  }

  static LocalDate _dateFromEpochDay(int epochDay) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      epochDay * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return LocalDate(year: date.year, month: date.month, day: date.day);
  }
}

/// Observable accounting for one prepared focus publication. All row data
/// continues to belong to the retained base; this object reports only compact
/// ordinal selection and bounded root-frame assembly.
@immutable
final class DashboardEphemeralFocusDerivation {
  const DashboardEphemeralFocusDerivation({
    required this.index,
    required this.membershipOrdinalCount,
    required this.membershipLookupMicros,
    required this.intersectionMicros,
    required this.rootProjectionMicros,
    required this.reusedPreparedRows,
  });

  final PreparedDashboardIndex index;
  final int membershipOrdinalCount;
  final int membershipLookupMicros;
  final int intersectionMicros;
  final int rootProjectionMicros;
  final int reusedPreparedRows;

  static const int workerDispatched = 0;
  static const int fullBaseRowsScanned = 0;
  static const int copiedPreparedRows = 0;
}

final class _FocusFrameAccumulator {
  _FocusFrameAccumulator(this.scope);

  final CurrentLedgerQueryScope scope;
  final List<int> _entryOrdinals = <int>[];
  DashboardFocusMembershipSeed? _seed;
  int totalMinor = 0;

  void add(int ordinal, DashboardFocusMembershipSeed seed) {
    final entry = seed.entryAt(ordinal);
    _seed ??= seed;
    if (!identical(_seed, seed)) {
      throw StateError('A focused frame may reference one base seed only.');
    }
    _entryOrdinals.add(ordinal);
    totalMinor += entry.amountMinor;
  }

  DashboardPreparedFrame toPreparedFrame({
    required int coreRevision,
    required int pageSize,
  }) {
    final seed = _seed;
    if (seed == null) throw StateError('Focused frame has no base seed.');
    final preview = <DashboardLedgerEntry>[
      for (
        var index = 0;
        index < _entryOrdinals.length && index < pageSize;
        index += 1
      )
        seed.entryAt(_entryOrdinals[index]),
    ];
    final cursor = _entryOrdinals.length > pageSize
        ? _cursorFor(preview.last)
        : null;
    final logBox = DashboardLogViewModelProjector.presentPreparedOrdered(
      scope: scope,
      revision: coreRevision,
      entries: preview,
      entryCount: _entryOrdinals.length,
      nextCursor: cursor,
    );
    return DashboardPreparedFrame.complete(
      scope: scope,
      parentQueryKey: dashboardPreparedParentQueryKey(scope),
      coreRevision: coreRevision,
      totalMinor: totalMinor,
      formattedAmount: DashboardPreparedFormatter.amountMinor(totalMinor),
      entryCount: _entryOrdinals.length,
      formattedEntryCount: DashboardPreparedFormatter.entryCount(
        _entryOrdinals.length,
      ),
      logBox: logBox,
      presentationDigest: Object.hash(
        scope.key,
        coreRevision,
        totalMinor,
        _entryOrdinals.length,
        Object.hashAll(preview.map((entry) => entry.id)),
        cursor?['entryId'],
      ),
    );
  }

  Map<String, Object?> _cursorFor(DashboardLedgerEntry entry) =>
      <String, Object?>{
        'bookedLocalEpochDay': entry.bookedLocalEpochDay,
        'bookedLocalTimeMinutes': entry.bookedLocalTimeMinutes,
        'entryId': entry.id,
      };
}
