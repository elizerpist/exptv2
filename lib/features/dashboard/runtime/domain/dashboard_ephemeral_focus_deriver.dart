import '../../logbox/application/committed_vertical_geometry_manifest.dart';
import '../../logbox/application/dashboard_log_view_models.dart';
import '../../motion/dashboard_semantic_catalog.dart';
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
  static PreparedDashboardIndex derive({
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
    final selected = seed
        .select(categoryId: categoryFocusId, partnerId: partnerFocusId)
        .entries
        .toList(growable: false);
    if (selected.any((entry) => entry.direction != focusedDirection.name)) {
      throw StateError('Focus seed contains another direction.');
    }

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
    for (final entry in selected) {
      for (final scope in _scopesForEntry(focusedScope, entry)) {
        final canonical = universe.scopes[scope.key];
        // A restrictive base temporal filter intentionally omits unavailable
        // hierarchy nodes from the immutable universe.
        if (canonical == null) continue;
        accumulators
            .putIfAbsent(canonical.key, () => _FocusFrameAccumulator(canonical))
            .add(entry);
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
    final geometrySeed = _geometrySeed(selected);
    // Building immutable maps happens after all bounded frame data exists so
    // no caller can observe a mixed base/focus scene.
    final focused = PreparedDashboardIndex.complete(
      key: key,
      frames: <LedgerQueryKey, DashboardPreparedFrame>{
        ...inactive.frames,
        ...focusedFrames,
      },
      catalogs: <LedgerQueryKey, DashboardSemanticCatalog>{
        ...inactive.catalogs,
        ...universe.catalogs,
      },
      scopes: <LedgerQueryKey, CurrentLedgerQueryScope>{
        ...universe.scopes,
        for (final zero in inactive.compactZeroFrames.values)
          zero.queryKey: zero.scope,
        for (final frame in inactive.frames.values) frame.queryKey: frame.scope,
      },
      origins: <LedgerQueryKey, DashboardDataOrigin>{
        ...inactive.origins,
        for (final frame in focusedFrames.values)
          frame.queryKey: DashboardDataOrigin.preparedIndex,
      },
      geometrySeedsByDirection:
          <LedgerDirection, List<CommittedVerticalGeometryDayBucket>>{
            focusedDirection: geometrySeed,
            inactiveDirection: inactive.verticalGeometrySeed,
          },
      // The active focus partition is derived from the retained base index.
      // Do not attach the broad seed to the narrowed partition: that would
      // make a focused index look like a second base owner. The inactive half
      // remains reusable by its exact base identity.
      focusMembershipSeedsByDirection:
          <LedgerDirection, DashboardFocusMembershipSeed>{
            if (inactive.focusMembershipSeed != null)
              inactiveDirection: inactive.focusMembershipSeed!,
          },
      generation: generation,
      contentDigest: Object.hash(
        base.contentDigest,
        focusedScope.key,
        categoryFocusId,
        partnerFocusId,
        Object.hashAll(selected.map((entry) => entry.id)),
      ),
      preparedAt: DateTime.now().toUtc(),
      buildMetrics: base.buildMetrics.copyWith(
        dartProjectionDurationMicros: stopwatch.elapsedMicroseconds,
        frameCount: inactive.frames.length + focusedFrames.length,
        estimatedIndexBytes:
            base.buildMetrics.estimatedIndexBytes + selected.length * 24,
      ),
    );
    stopwatch.stop();
    return focused.withBuildMetrics(
      focused.buildMetrics.copyWith(
        dartProjectionDurationMicros: stopwatch.elapsedMicroseconds,
      ),
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
    List<DashboardLedgerEntry> entries,
  ) {
    final counts = <int, int>{};
    for (final entry in entries) {
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

final class _FocusFrameAccumulator {
  _FocusFrameAccumulator(this.scope);

  final CurrentLedgerQueryScope scope;
  final List<DashboardLedgerEntry> entries = <DashboardLedgerEntry>[];
  int totalMinor = 0;

  void add(DashboardLedgerEntry entry) {
    entries.add(entry);
    totalMinor += entry.amountMinor;
  }

  DashboardPreparedFrame toPreparedFrame({
    required int coreRevision,
    required int pageSize,
  }) {
    final preview = entries.take(pageSize).toList(growable: false);
    final cursor = entries.length > pageSize ? _cursorFor(preview.last) : null;
    final logBox = DashboardLogViewModelProjector.presentPreparedOrdered(
      scope: scope,
      revision: coreRevision,
      entries: preview,
      entryCount: entries.length,
      nextCursor: cursor,
    );
    return DashboardPreparedFrame.complete(
      scope: scope,
      parentQueryKey: dashboardPreparedParentQueryKey(scope),
      coreRevision: coreRevision,
      totalMinor: totalMinor,
      formattedAmount: DashboardPreparedFormatter.amountMinor(totalMinor),
      entryCount: entries.length,
      formattedEntryCount: DashboardPreparedFormatter.entryCount(
        entries.length,
      ),
      logBox: logBox,
      presentationDigest: Object.hash(
        scope.key,
        coreRevision,
        totalMinor,
        entries.length,
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
