import 'package:flutter/foundation.dart';

import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../motion/dashboard_semantic_catalog.dart';
import 'prepared_presentation_frame.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/dashboard_directional_query_set.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../time_navigation/domain/dashboard_temporal_availability.dart';

/// Canonical hierarchy owner for prepared frame parent identity.
///
/// This runs only while the immutable index is assembled. Navigation consumes
/// the stored parent key and never reconstructs a scope or QueryKey on its hot
/// path.
LedgerQueryKey dashboardPreparedParentQueryKey(CurrentLedgerQueryScope scope) {
  final parentTimeScope = switch (scope.timeScope) {
    AllTimeScope() => const AllTimeScope(),
    YearScope() => const AllTimeScope(),
    MonthScope(:final value) => YearScope(value.year),
    DayScope(:final date) => MonthScope(
      YearMonth(year: date.year, month: date.month),
    ),
  };
  return scope.copyWith(timeScope: parentTimeScope).key;
}

enum DataAcquisitionReason {
  bootstrap,
  databaseRevision,
  query,
  explicitCommittedVerticalPaging,
}

extension DataAcquisitionReasonPolicy on DataAcquisitionReason {
  bool get buildsIndex =>
      this == DataAcquisitionReason.bootstrap ||
      this == DataAcquisitionReason.databaseRevision ||
      this == DataAcquisitionReason.query;

  bool get readsPage =>
      this == DataAcquisitionReason.explicitCommittedVerticalPaging;

  void requireIndexBuild() {
    if (!buildsIndex) {
      throw StateError('$name cannot build a prepared dashboard index.');
    }
  }

  void requirePageRead() {
    if (!readsPage) {
      throw StateError('$name cannot read a committed dashboard page.');
    }
  }
}

enum DashboardDataOrigin {
  preparedIndex,
  deterministicZero,
  explicitCommittedPage,
}

enum DashboardPresentationMode { preview, committed }

/// Mutable only while a worker assembles an index. The completed index copies
/// every map into an immutable snapshot before it can reach presentation.
final class PreparedDashboardIndexAssembly {
  PreparedDashboardIndexAssembly._({
    required this.frames,
    required this.catalogs,
    required this.scopes,
    required this.origins,
  });

  factory PreparedDashboardIndexAssembly.zeroUniverse({
    required PreparedDashboardIndexKey key,
    CurrentLedgerQueryScope? filterScope,
    DashboardDirectionalQuerySet? directionalQueries,
    required int initialYear,
  }) {
    if ((filterScope == null) == (directionalQueries == null)) {
      throw ArgumentError(
        'Zero-universe assembly requires exactly one filter scope or directional query set.',
      );
    }
    final queries =
        directionalQueries ?? DashboardDirectionalQuerySet.fromInitial(filterScope!);
    final radius = initialYear - key.yearWindowStart;
    if (radius < 1 || key.yearWindowEndInclusive - initialYear != radius) {
      throw ArgumentError('Prepared dashboard year window must be symmetric.');
    }
    final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
    final catalogs = <LedgerQueryKey, DashboardSemanticCatalog>{};
    final scopes = <LedgerQueryKey, CurrentLedgerQueryScope>{};
    final origins = <LedgerQueryKey, DashboardDataOrigin>{};

    void addScope(CurrentLedgerQueryScope scope) {
      scopes[scope.key] = scope;
      frames.putIfAbsent(scope.key, () => _zeroFrame(scope, key.coreRevision));
      origins.putIfAbsent(
        scope.key,
        () => DashboardDataOrigin.deterministicZero,
      );
    }

    void addCatalog(DashboardSemanticCatalog catalog) {
      catalogs[catalog.parentScope.key] = catalog;
      addScope(catalog.parentScope);
      for (final semantic in catalog.entries) {
        addScope(semantic.scope);
      }
    }

    for (final direction in LedgerDirection.values) {
      final template = queries.scopeFor(direction);
      final availability = DashboardTemporalAvailability.fromTemporalFilter(
        template.temporalFilter,
      );
      final allScope = template.copyWith(timeScope: const AllTimeScope());
      addCatalog(
        DashboardSemanticCatalog.forParent(
          parentScope: allScope,
          childKind: DashboardChildKind.year,
          retainedYear: initialYear,
          yearWindowRadius: radius,
          availability: availability,
        ),
      );
      final years =
          availability.allowedYears ??
          List<int>.generate(
            key.yearWindowEndInclusive - key.yearWindowStart + 1,
            (index) => key.yearWindowStart + index,
            growable: false,
          );
      for (final year in years) {
        final yearScope = allScope.copyWith(timeScope: YearScope(year));
        addCatalog(
          DashboardSemanticCatalog.forParent(
            parentScope: yearScope,
            childKind: DashboardChildKind.month,
            availability: availability,
          ),
        );
        final months =
            availability.monthsForYear(year) ??
            List<int>.generate(12, (index) => index + 1, growable: false);
        for (final month in months) {
          final monthScope = allScope.copyWith(
            timeScope: MonthScope(YearMonth(year: year, month: month)),
          );
          addCatalog(
            DashboardSemanticCatalog.forParent(
              parentScope: monthScope,
              childKind: DashboardChildKind.day,
              availability: availability,
            ),
          );
        }
      }
    }
    return PreparedDashboardIndexAssembly._(
      frames: frames,
      catalogs: catalogs,
      scopes: scopes,
      origins: origins,
    );
  }

  final Map<LedgerQueryKey, DashboardPreparedFrame> frames;
  final Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs;
  final Map<LedgerQueryKey, CurrentLedgerQueryScope> scopes;
  final Map<LedgerQueryKey, DashboardDataOrigin> origins;

  static DashboardPreparedFrame _zeroFrame(
    CurrentLedgerQueryScope scope,
    int revision,
  ) => DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: dashboardPreparedParentQueryKey(scope),
    coreRevision: revision,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: revision,
      groups: const [],
      entryCount: 0,
      nextCursor: null,
      direction: scope.direction,
    ),
    presentationDigest: Object.hash(scope.key, revision, 0),
  );
}

@immutable
final class PreparedDashboardIndexKey {
  const PreparedDashboardIndexKey({
    required this.modelVersion,
    required this.coreRevision,
    required this.categoryIdsKey,
    required this.partnerIdsKey,
    required this.refinementsKey,
    required this.temporalFilterKey,
    required this.pageSize,
    required this.yearWindowStart,
    required this.yearWindowEndInclusive,
    this.incomeFilterKey = '',
    this.expenseFilterKey = '',
  });

  factory PreparedDashboardIndexKey.fromScope({
    required CurrentLedgerQueryScope scope,
    required int coreRevision,
    required int pageSize,
    required int yearWindowStart,
    required int yearWindowEndInclusive,
    int modelVersion = currentModelVersion,
  }) => PreparedDashboardIndexKey(
    modelVersion: modelVersion,
    coreRevision: coreRevision,
    categoryIdsKey: canonicalValues(scope.categoryIds),
    partnerIdsKey: canonicalValues(scope.partnerIds),
    refinementsKey: canonicalRefinements(scope.refinements),
    temporalFilterKey: scope.temporalFilter.canonicalKey,
    pageSize: pageSize,
    yearWindowStart: yearWindowStart,
    yearWindowEndInclusive: yearWindowEndInclusive,
    incomeFilterKey: _filterIdentity(
      scope.copyWith(direction: LedgerDirection.income),
    ),
    expenseFilterKey: _filterIdentity(
      scope.copyWith(direction: LedgerDirection.expense),
    ),
  );

  factory PreparedDashboardIndexKey.fromDirectionalQuerySet({
    required DashboardDirectionalQuerySet queries,
    required int coreRevision,
    required int pageSize,
    required int yearWindowStart,
    required int yearWindowEndInclusive,
    int modelVersion = currentModelVersion,
  }) => PreparedDashboardIndexKey(
    modelVersion: modelVersion,
    coreRevision: coreRevision,
    // Compatibility fields are retained for older fixtures and diagnostics;
    // all new identity checks select the directional key below.
    categoryIdsKey: canonicalValues(queries.income.categoryIds),
    partnerIdsKey: canonicalValues(queries.income.partnerIds),
    refinementsKey: canonicalRefinements(queries.income.refinements),
    temporalFilterKey: queries.income.temporalFilter.canonicalKey,
    pageSize: pageSize,
    yearWindowStart: yearWindowStart,
    yearWindowEndInclusive: yearWindowEndInclusive,
    incomeFilterKey: _filterIdentity(queries.income),
    expenseFilterKey: _filterIdentity(queries.expense),
  );

  static const int currentModelVersion = 3;

  final int modelVersion;
  final int coreRevision;
  final String categoryIdsKey;
  final String partnerIdsKey;
  final String refinementsKey;
  final String temporalFilterKey;
  final int pageSize;
  final int yearWindowStart;
  final int yearWindowEndInclusive;
  final String incomeFilterKey;
  final String expenseFilterKey;

  bool get hasDirectionalFilters =>
      incomeFilterKey.isNotEmpty && expenseFilterKey.isNotEmpty;

  bool matchesScope(CurrentLedgerQueryScope scope) {
    if (hasDirectionalFilters) {
      final expected = switch (scope.direction) {
        LedgerDirection.income => incomeFilterKey,
        LedgerDirection.expense => expenseFilterKey,
      };
      return expected == _filterIdentity(scope);
    }
    return categoryIdsKey == canonicalValues(scope.categoryIds) &&
        partnerIdsKey == canonicalValues(scope.partnerIds) &&
        refinementsKey == canonicalRefinements(scope.refinements) &&
        temporalFilterKey == scope.temporalFilter.canonicalKey;
  }

  static String _filterIdentity(CurrentLedgerQueryScope scope) => scope
      .copyWith(timeScope: const AllTimeScope())
      .key
      .value;

  static String canonicalValues(Iterable<String> values) {
    final sorted = values.toList()..sort();
    return sorted.join(',');
  }

  static String canonicalRefinements(Map<String, Object?> refinements) {
    final entries = refinements.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join(',');
  }

  @override
  bool operator ==(Object other) =>
      other is PreparedDashboardIndexKey &&
      other.modelVersion == modelVersion &&
      other.coreRevision == coreRevision &&
      other.categoryIdsKey == categoryIdsKey &&
      other.partnerIdsKey == partnerIdsKey &&
      other.refinementsKey == refinementsKey &&
      other.temporalFilterKey == temporalFilterKey &&
      other.incomeFilterKey == incomeFilterKey &&
      other.expenseFilterKey == expenseFilterKey &&
      other.pageSize == pageSize &&
      other.yearWindowStart == yearWindowStart &&
      other.yearWindowEndInclusive == yearWindowEndInclusive;

  @override
  int get hashCode => Object.hash(
    modelVersion,
    coreRevision,
    categoryIdsKey,
    partnerIdsKey,
    refinementsKey,
    temporalFilterKey,
    incomeFilterKey,
    expenseFilterKey,
    pageSize,
    yearWindowStart,
    yearWindowEndInclusive,
  );
}

@immutable
final class PreparedDashboardIndexBuildMetrics {
  const PreparedDashboardIndexBuildMetrics({
    required this.sqlCallCount,
    required this.nativeSqlDurationMicros,
    required this.aggregateBucketCount,
    required this.scannedLedgerRowCount,
    required this.uniquePreviewRowCount,
    required this.frameCount,
    required this.nativeQueryDurationMicros,
    required this.nativeAggregationDurationMicros,
    required this.nativeMappingDurationMicros,
    required this.serializationDurationMicros,
    required this.bridgeTransferDurationMicros,
    required this.dartDecodeDurationMicros,
    required this.dartProjectionDurationMicros,
    required this.payloadBytes,
    required this.estimatedIndexBytes,
  });

  const PreparedDashboardIndexBuildMetrics.synthetic()
    : sqlCallCount = 0,
      nativeSqlDurationMicros = 0,
      aggregateBucketCount = 0,
      scannedLedgerRowCount = 0,
      uniquePreviewRowCount = 0,
      frameCount = 0,
      nativeQueryDurationMicros = 0,
      nativeAggregationDurationMicros = 0,
      nativeMappingDurationMicros = 0,
      serializationDurationMicros = 0,
      bridgeTransferDurationMicros = 0,
      dartDecodeDurationMicros = 0,
      dartProjectionDurationMicros = 0,
      payloadBytes = 0,
      estimatedIndexBytes = 0;

  final int sqlCallCount;
  final int nativeSqlDurationMicros;
  final int aggregateBucketCount;
  final int scannedLedgerRowCount;
  final int uniquePreviewRowCount;
  final int frameCount;
  final int nativeQueryDurationMicros;
  final int nativeAggregationDurationMicros;
  final int nativeMappingDurationMicros;
  final int serializationDurationMicros;
  final int bridgeTransferDurationMicros;
  final int dartDecodeDurationMicros;
  final int dartProjectionDurationMicros;
  final int payloadBytes;
  final int estimatedIndexBytes;

  PreparedDashboardIndexBuildMetrics copyWith({
    int? bridgeTransferDurationMicros,
  }) => PreparedDashboardIndexBuildMetrics(
    sqlCallCount: sqlCallCount,
    nativeSqlDurationMicros: nativeSqlDurationMicros,
    aggregateBucketCount: aggregateBucketCount,
    scannedLedgerRowCount: scannedLedgerRowCount,
    uniquePreviewRowCount: uniquePreviewRowCount,
    frameCount: frameCount,
    nativeQueryDurationMicros: nativeQueryDurationMicros,
    nativeAggregationDurationMicros: nativeAggregationDurationMicros,
    nativeMappingDurationMicros: nativeMappingDurationMicros,
    serializationDurationMicros: serializationDurationMicros,
    bridgeTransferDurationMicros:
        bridgeTransferDurationMicros ?? this.bridgeTransferDurationMicros,
    dartDecodeDurationMicros: dartDecodeDurationMicros,
    dartProjectionDurationMicros: dartProjectionDurationMicros,
    payloadBytes: payloadBytes,
    estimatedIndexBytes: estimatedIndexBytes,
  );
}

/// One complete immutable data source for every dashboard interaction.
@immutable
final class PreparedDashboardIndex {
  const PreparedDashboardIndex._({
    required this.key,
    required this.frames,
    required this.catalogs,
    required this.catalogsByDirectionAndScope,
    required this.origins,
    required this.generation,
    required this.contentDigest,
    required this.preparedAt,
    required this.buildMetrics,
  });

  factory PreparedDashboardIndex.complete({
    required PreparedDashboardIndexKey key,
    required Map<LedgerQueryKey, DashboardPreparedFrame> frames,
    required Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs,
    Map<LedgerQueryKey, DashboardDataOrigin>? origins,
    required int generation,
    required int contentDigest,
    required DateTime preparedAt,
    required PreparedDashboardIndexBuildMetrics buildMetrics,
  }) {
    if (key.modelVersion <= 0 ||
        key.coreRevision <= 0 ||
        key.pageSize <= 0 ||
        key.yearWindowStart < 1 ||
        key.yearWindowEndInclusive < key.yearWindowStart ||
        generation <= 0) {
      throw ArgumentError('Prepared dashboard index identity is invalid.');
    }
    for (final entry in frames.entries) {
      final frame = entry.value;
      if (entry.key != frame.queryKey ||
          frame.coreRevision != key.coreRevision ||
          frame.parentQueryKey !=
              dashboardPreparedParentQueryKey(frame.scope) ||
          !key.matchesScope(frame.scope)) {
        throw ArgumentError('Prepared frame identity is inconsistent.');
      }
    }
    for (final entry in catalogs.entries) {
      final catalog = entry.value;
      if (entry.key != catalog.parentScope.key ||
          !key.matchesScope(catalog.parentScope)) {
        throw ArgumentError('Prepared semantic catalog is inconsistent.');
      }
      for (final semantic in catalog.entries) {
        final frame = frames[semantic.queryKey];
        if (frame == null || frame.scope != semantic.scope) {
          throw ArgumentError(
            'Prepared index has no frame for ${semantic.queryKey.value}.',
          );
        }
      }
    }
    final resolvedOrigins =
        origins ??
        <LedgerQueryKey, DashboardDataOrigin>{
          for (final queryKey in frames.keys)
            queryKey: DashboardDataOrigin.preparedIndex,
        };
    if (resolvedOrigins.length != frames.length ||
        resolvedOrigins.keys.any((queryKey) => !frames.containsKey(queryKey))) {
      throw ArgumentError('Prepared frame origins are incomplete.');
    }
    final catalogsByDirectionAndScope =
        <LedgerDirection, Map<LedgerTimeScope, DashboardSemanticCatalog>>{
          for (final direction in LedgerDirection.values)
            direction: <LedgerTimeScope, DashboardSemanticCatalog>{},
        };
    for (final catalog in catalogs.values) {
      catalogsByDirectionAndScope[catalog.parentScope.direction]![catalog
              .parentScope
              .timeScope] =
          catalog;
    }
    return PreparedDashboardIndex._(
      key: key,
      frames: Map<LedgerQueryKey, DashboardPreparedFrame>.unmodifiable(frames),
      catalogs: Map<LedgerQueryKey, DashboardSemanticCatalog>.unmodifiable(
        catalogs,
      ),
      catalogsByDirectionAndScope:
          Map<
            LedgerDirection,
            Map<LedgerTimeScope, DashboardSemanticCatalog>
          >.unmodifiable(
            <LedgerDirection, Map<LedgerTimeScope, DashboardSemanticCatalog>>{
              for (final entry in catalogsByDirectionAndScope.entries)
                entry.key:
                    Map<LedgerTimeScope, DashboardSemanticCatalog>.unmodifiable(
                      entry.value,
                    ),
            },
          ),
      origins: Map<LedgerQueryKey, DashboardDataOrigin>.unmodifiable(
        resolvedOrigins,
      ),
      generation: generation,
      contentDigest: contentDigest,
      preparedAt: preparedAt.toUtc(),
      buildMetrics: buildMetrics,
    );
  }

  final PreparedDashboardIndexKey key;
  final Map<LedgerQueryKey, DashboardPreparedFrame> frames;
  final Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs;
  final Map<LedgerDirection, Map<LedgerTimeScope, DashboardSemanticCatalog>>
  catalogsByDirectionAndScope;
  final Map<LedgerQueryKey, DashboardDataOrigin> origins;
  final int generation;
  final int contentDigest;
  final DateTime preparedAt;
  final PreparedDashboardIndexBuildMetrics buildMetrics;

  int get coreRevision => key.coreRevision;
  int get pageSize => key.pageSize;

  /// Adds the transport timing measured by the MethodChannel caller without
  /// rebuilding, validating or copying the immutable frame/index maps.
  PreparedDashboardIndex withBridgeTransferDurationMicros(int duration) {
    if (duration < 0) {
      throw ArgumentError.value(duration, 'duration', 'must be nonnegative');
    }
    if (duration == buildMetrics.bridgeTransferDurationMicros) return this;
    return PreparedDashboardIndex._(
      key: key,
      frames: frames,
      catalogs: catalogs,
      catalogsByDirectionAndScope: catalogsByDirectionAndScope,
      origins: origins,
      generation: generation,
      contentDigest: contentDigest,
      preparedAt: preparedAt,
      buildMetrics: buildMetrics.copyWith(
        bridgeTransferDurationMicros: duration,
      ),
    );
  }

  DashboardPreparedFrame frameFor(CurrentLedgerQueryScope scope) {
    _requireScopeIdentity(scope);
    return frames[scope.key] ?? _zeroFrame(scope);
  }

  DashboardPreparedFrame frameForKey(LedgerQueryKey queryKey) {
    final frame = frames[queryKey];
    if (frame == null) {
      throw StateError(
        'Prepared index has no interactive frame for ${queryKey.value}.',
      );
    }
    return frame;
  }

  DashboardSemanticCatalog catalogFor(CurrentLedgerQueryScope parentScope) {
    _requireScopeIdentity(parentScope);
    return catalogForKey(parentScope.key);
  }

  DashboardSemanticCatalog catalogForKey(LedgerQueryKey parentQueryKey) {
    final catalog = catalogs[parentQueryKey];
    if (catalog == null) {
      throw StateError(
        'Prepared index has no catalog for ${parentQueryKey.value}.',
      );
    }
    return catalog;
  }

  DashboardSemanticCatalog? catalogForIdentity({
    required LedgerDirection direction,
    required LedgerTimeScope timeScope,
  }) => catalogsByDirectionAndScope[direction]?[timeScope];

  bool hasCatalogFor(CurrentLedgerQueryScope parentScope) {
    _requireScopeIdentity(parentScope);
    return hasCatalogForKey(parentScope.key);
  }

  bool hasCatalogForKey(LedgerQueryKey parentQueryKey) =>
      catalogs.containsKey(parentQueryKey);

  DashboardDataOrigin originFor(LedgerQueryKey queryKey) =>
      origins[queryKey] ?? DashboardDataOrigin.deterministicZero;

  void _requireScopeIdentity(CurrentLedgerQueryScope scope) {
    if (!key.matchesScope(scope)) {
      throw StateError('Dashboard scope does not match the prepared index.');
    }
  }

  DashboardPreparedFrame _zeroFrame(CurrentLedgerQueryScope scope) =>
      DashboardPreparedFrame.complete(
        scope: scope,
        parentQueryKey: dashboardPreparedParentQueryKey(scope),
        coreRevision: coreRevision,
        totalMinor: 0,
        formattedAmount: '0 Ft',
        entryCount: 0,
        formattedEntryCount: '0',
        logBox: DashboardLogViewportState(
          queryKey: scope.key,
          revision: coreRevision,
          groups: const [],
          entryCount: 0,
          nextCursor: null,
          direction: scope.direction,
        ),
        presentationDigest: Object.hash(scope.key, coreRevision, 0),
      );
}
