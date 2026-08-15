import 'package:flutter/foundation.dart';

import '../../logbox/application/committed_vertical_geometry_manifest.dart';
import '../../logbox/application/dashboard_log_view_models.dart';
import '../../motion/dashboard_semantic_catalog.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/dashboard_directional_query_set.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/dashboard_temporal_availability.dart';
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
    CurrentLedgerQueryScope? initialParentScope,
    CurrentLedgerQueryScope? initialSelectedChildScope,
  }) => deriveFast(
    base: base,
    effectiveQueries: effectiveQueries,
    focusedDirection: focusedDirection,
    categoryFocusId: categoryFocusId,
    partnerFocusId: partnerFocusId,
    initialYear: initialYear,
    generation: generation,
    initialParentScope: initialParentScope,
    initialSelectedChildScope: initialSelectedChildScope,
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
    CurrentLedgerQueryScope? initialParentScope,
    CurrentLedgerQueryScope? initialSelectedChildScope,
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
    // A focus is a temporal view over the retained base index, not another
    // 2014–2038 index assembly. Only the exact parent/child that can become
    // visible in this publication is materialized synchronously. Later rail
    // scopes ask the same overlay for one bounded memoized frame at a time.
    final overlay = _DashboardEphemeralFocusedOverlay(
      base: base,
      template: focusedScope,
      seed: seed,
      selectedOrdinals: selected.entryIndices,
      initialYear: initialYear,
    );
    final requestedParent =
        initialParentScope?.timeScope ?? focusedScope.timeScope;
    final parentScope = overlay.scopeForTimeScope(requestedParent);
    if (parentScope == null) {
      throw StateError(
        'Focused publication has no retained temporal parent for '
        '${requestedParent.canonicalKey}.',
      );
    }
    overlay.materializeCatalog(parentScope);
    final rootFrame = overlay.materializeFrame(parentScope);
    final requestedChild = initialSelectedChildScope?.timeScope;
    if (requestedChild != null) {
      final childScope = overlay.scopeForTimeScope(requestedChild);
      if (childScope != null) overlay.materializeFrame(childScope);
    }
    stopwatch.stop();
    final currentRootProjectionMicros = stopwatch.elapsedMicroseconds;
    final focusedFrames = <LedgerQueryKey, DashboardPreparedFrame>{
      for (final frame in overlay.materializedFrames) frame.queryKey: frame,
    };
    final inactiveDirection = switch (focusedDirection) {
      LedgerDirection.income => LedgerDirection.expense,
      LedgerDirection.expense => LedgerDirection.income,
    };
    final inactive = base.partitionFor(inactiveDirection);
    final geometrySeed = overlay.geometrySeedFor(parentScope);
    // The focused direction owns only the compact derived frames/catalogs.
    // The untouched directional partition remains a reference to [base], so
    // a focus interaction never reconstructs or copies the other universe.
    final focused = PreparedDashboardIndex.focusedDirectionalOverlay(
      base: base,
      key: key,
      focusedDirection: focusedDirection,
      focusedFrames: focusedFrames,
      focusedCatalogs: overlay.materializedCatalogs,
      focusedScopes: overlay.knownScopes,
      focusedOrigins: <LedgerQueryKey, DashboardDataOrigin>{
        for (final frame in focusedFrames.values)
          frame.queryKey: DashboardDataOrigin.preparedIndex,
      },
      focusedGeometrySeed: geometrySeed,
      focusedTemporalOverlay: overlay,
      generation: generation,
      contentDigest: Object.hash(
        base.contentDigest,
        focusedScope.key,
        categoryFocusId,
        partnerFocusId,
        // The exact focused query IDs plus its immutable base index uniquely
        // determine compact membership. Do not walk every selected all-time
        // ordinal merely to create a digest before the root can publish.
        selected.entryCount,
      ),
      preparedAt: DateTime.now().toUtc(),
      buildMetrics: base.buildMetrics.copyWith(
        dartProjectionDurationMicros: currentRootProjectionMicros,
        frameCount: inactive.frames.length + focusedFrames.length,
        estimatedIndexBytes:
            base.buildMetrics.estimatedIndexBytes + selected.entryCount * 4,
      ),
    );
    final index = focused.withBuildMetrics(
      focused.buildMetrics.copyWith(
        dartProjectionDurationMicros: currentRootProjectionMicros,
      ),
    );
    return DashboardEphemeralFocusDerivation(
      index: index,
      membershipOrdinalCount: selected.entryCount,
      membershipLookupMicros: selected.membershipLookupMicros,
      intersectionMicros: selected.intersectionMicros,
      semanticUniverseBuildMicros: 0,
      currentRootProjectionMicros: currentRootProjectionMicros,
      publicationCriticalFrameCount: overlay.materializedFrameCount,
      publicationCriticalRowCount: rootFrame.entryCount,
      eagerFocusedFrameCount: overlay.materializedFrameCount,
      lazyFocusedFrameCacheCount: overlay.materializedFrameCount,
      focusedOrdinalsVisitedBeforePublication: overlay.ordinalsVisited,
      focusedOrdinalsVisitedAfterPublication: 0,
      reusedBaseCatalogCount: 1,
      newFocusedCatalogCount: overlay.materializedCatalogCount,
      reusedPreparedRows: selected.entryCount,
    );
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
    required this.semanticUniverseBuildMicros,
    required this.currentRootProjectionMicros,
    required this.publicationCriticalFrameCount,
    required this.publicationCriticalRowCount,
    required this.eagerFocusedFrameCount,
    required this.lazyFocusedFrameCacheCount,
    required this.focusedOrdinalsVisitedBeforePublication,
    required this.focusedOrdinalsVisitedAfterPublication,
    required this.reusedBaseCatalogCount,
    required this.newFocusedCatalogCount,
    required this.reusedPreparedRows,
  });

  final PreparedDashboardIndex index;
  final int membershipOrdinalCount;
  final int membershipLookupMicros;
  final int intersectionMicros;
  final int semanticUniverseBuildMicros;
  final int currentRootProjectionMicros;
  final int publicationCriticalFrameCount;
  final int publicationCriticalRowCount;
  final int eagerFocusedFrameCount;
  final int lazyFocusedFrameCacheCount;
  final int focusedOrdinalsVisitedBeforePublication;
  final int focusedOrdinalsVisitedAfterPublication;
  final int reusedBaseCatalogCount;
  final int newFocusedCatalogCount;
  final int reusedPreparedRows;

  static const int workerDispatched = 0;
  static const int fullBaseRowsScanned = 0;
  static const int copiedPreparedRows = 0;
}

/// Lazily materializes exact focused temporal scopes over one retained base
/// index. The focused query's semantic keys differ from the base keys, but its
/// temporal topology and row resources do not; this view therefore owns only
/// compact focused maps rather than a second full index universe.
final class _DashboardEphemeralFocusedOverlay
    implements DashboardFocusedTemporalOverlay {
  _DashboardEphemeralFocusedOverlay({
    required this.base,
    required this.template,
    required this.seed,
    required this.selectedOrdinals,
    required this.initialYear,
  }) : availability = DashboardTemporalAvailability.fromTemporalFilter(
         template.temporalFilter,
       );

  final PreparedDashboardIndex base;
  final CurrentLedgerQueryScope template;
  final DashboardFocusMembershipSeed seed;
  final DashboardFocusOrdinalSet selectedOrdinals;
  final int initialYear;
  final DashboardTemporalAvailability availability;

  final Map<LedgerQueryKey, CurrentLedgerQueryScope> _scopes =
      <LedgerQueryKey, CurrentLedgerQueryScope>{};
  final Map<LedgerQueryKey, DashboardPreparedFrame> _frames =
      <LedgerQueryKey, DashboardPreparedFrame>{};
  final Map<LedgerQueryKey, DashboardSemanticCatalog> _catalogs =
      <LedgerQueryKey, DashboardSemanticCatalog>{};
  final Map<LedgerQueryKey, List<CommittedVerticalGeometryDayBucket>>
  _geometrySeeds = <LedgerQueryKey, List<CommittedVerticalGeometryDayBucket>>{};
  int _ordinalsVisited = 0;

  @override
  LedgerDirection get direction => template.direction;

  Map<LedgerQueryKey, CurrentLedgerQueryScope> get knownScopes =>
      Map<LedgerQueryKey, CurrentLedgerQueryScope>.unmodifiable(_scopes);

  Map<LedgerQueryKey, DashboardSemanticCatalog> get materializedCatalogs =>
      Map<LedgerQueryKey, DashboardSemanticCatalog>.unmodifiable(_catalogs);

  int get ordinalsVisited => _ordinalsVisited;

  @override
  int get materializedFrameCount => _frames.length;

  @override
  int get materializedCatalogCount => _catalogs.length;

  @override
  Iterable<DashboardPreparedFrame> get materializedFrames =>
      List<DashboardPreparedFrame>.unmodifiable(_frames.values);

  @override
  bool matchesScope(CurrentLedgerQueryScope scope) =>
      scope.direction == direction &&
      scope.copyWith(timeScope: const AllTimeScope()).key ==
          template.copyWith(timeScope: const AllTimeScope()).key &&
      _hasBaseScope(scope.timeScope);

  @override
  CurrentLedgerQueryScope? scopeForTimeScope(LedgerTimeScope timeScope) {
    if (!_hasBaseScope(timeScope)) return null;
    return _register(template.copyWith(timeScope: timeScope));
  }

  @override
  CurrentLedgerQueryScope? scopeForKey(LedgerQueryKey queryKey) =>
      _scopes[queryKey];

  @override
  bool hasCatalogForScope(CurrentLedgerQueryScope parentScope) =>
      matchesScope(parentScope) &&
      base.catalogForIdentity(
            direction: direction,
            timeScope: parentScope.timeScope,
          ) !=
          null;

  @override
  DashboardSemanticCatalog materializeCatalog(
    CurrentLedgerQueryScope parentScope,
  ) {
    if (!hasCatalogForScope(parentScope)) {
      throw StateError(
        'Focused index has no catalog for ${parentScope.key.value}.',
      );
    }
    final existing = _catalogs[parentScope.key];
    if (existing != null) return existing;
    final baseCatalog = base.catalogForIdentity(
      direction: direction,
      timeScope: parentScope.timeScope,
    )!;
    final radius = initialYear - base.key.yearWindowStart;
    final catalog = DashboardSemanticCatalog.forParent(
      parentScope: _register(parentScope),
      childKind: baseCatalog.childKind,
      retainedYear: parentScope.timeScope is AllTimeScope ? initialYear : null,
      yearWindowRadius: radius,
      availability: availability,
    );
    _catalogs[parentScope.key] = catalog;
    for (final entry in catalog.entries) {
      _register(entry.scope);
    }
    return catalog;
  }

  @override
  DashboardPreparedFrame materializeFrame(CurrentLedgerQueryScope scope) {
    if (!matchesScope(scope)) {
      throw StateError('Focused frame scope does not match its base overlay.');
    }
    final canonical = _register(scope);
    final existing = _frames[canonical.key];
    if (existing != null) return existing;
    final bounds = canonical.timeScope.boundaries;
    final startEpochDay = bounds == null
        ? null
        : _epochDay(bounds.startInclusive);
    final endEpochDay = bounds == null ? null : _epochDay(bounds.endExclusive);
    var totalMinor = 0;
    var entryCount = 0;
    final preview = <DashboardLedgerEntry>[];
    final dayCounts = <int, int>{};
    for (final ordinal in selectedOrdinals) {
      _ordinalsVisited += 1;
      final entry = seed.entryAt(ordinal);
      if (entry.direction != direction.name ||
          (startEpochDay != null &&
              (entry.bookedLocalEpochDay < startEpochDay ||
                  entry.bookedLocalEpochDay >= endEpochDay!))) {
        continue;
      }
      entryCount += 1;
      totalMinor += entry.amountMinor;
      dayCounts.update(
        entry.bookedLocalEpochDay,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (preview.length < base.pageSize) preview.add(entry);
    }
    final cursor = entryCount > base.pageSize && preview.isNotEmpty
        ? _cursorFor(preview.last)
        : null;
    final frame = DashboardPreparedFrame.complete(
      scope: canonical,
      parentQueryKey: dashboardPreparedParentQueryKey(canonical),
      coreRevision: base.coreRevision,
      totalMinor: totalMinor,
      formattedAmount: DashboardPreparedFormatter.amountMinor(totalMinor),
      entryCount: entryCount,
      formattedEntryCount: DashboardPreparedFormatter.entryCount(entryCount),
      logBox: DashboardLogViewModelProjector.presentPreparedOrdered(
        scope: canonical,
        revision: base.coreRevision,
        entries: preview,
        entryCount: entryCount,
        nextCursor: cursor,
      ),
      presentationDigest: Object.hash(
        canonical.key,
        base.coreRevision,
        totalMinor,
        entryCount,
        Object.hashAll(preview.map((entry) => entry.id)),
        cursor?['entryId'],
      ),
    );
    _frames[canonical.key] = frame;
    _geometrySeeds[canonical.key] = _geometryFrom(dayCounts);
    return frame;
  }

  @override
  List<CommittedVerticalGeometryDayBucket> geometrySeedFor(
    CurrentLedgerQueryScope scope,
  ) {
    final frame = materializeFrame(scope);
    final seed = _geometrySeeds[frame.queryKey];
    if (seed == null) {
      throw StateError('Focused frame is missing exact geometry metadata.');
    }
    return seed;
  }

  @override
  bool hasMaterializedFrameForKey(LedgerQueryKey queryKey) =>
      _frames.containsKey(queryKey);

  bool _hasBaseScope(LedgerTimeScope timeScope) {
    if (base.catalogForIdentity(direction: direction, timeScope: timeScope) !=
        null) {
      return true;
    }
    if (timeScope case DayScope(:final date)) {
      final parent = base.catalogForIdentity(
        direction: direction,
        timeScope: MonthScope(YearMonth(year: date.year, month: date.month)),
      );
      return parent?.entries.any(
            (entry) => entry.scope.timeScope == timeScope,
          ) ??
          false;
    }
    return false;
  }

  CurrentLedgerQueryScope _register(CurrentLedgerQueryScope scope) {
    final existing = _scopes[scope.key];
    if (existing != null) return existing;
    _scopes[scope.key] = scope;
    return scope;
  }

  static List<CommittedVerticalGeometryDayBucket> _geometryFrom(
    Map<int, int> counts,
  ) {
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

  static int _epochDay(LocalDate value) => DateTime.utc(
    value.year,
    value.month,
    value.day,
  ).difference(DateTime.utc(1970)).inDays;

  static Map<String, Object?> _cursorFor(DashboardLedgerEntry entry) =>
      <String, Object?>{
        'bookedLocalEpochDay': entry.bookedLocalEpochDay,
        'bookedLocalTimeMinutes': entry.bookedLocalTimeMinutes,
        'entryId': entry.id,
      };
}
