import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../logbox/application/committed_vertical_geometry_manifest.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';
import 'dashboard_focus_membership_seed.dart';
import '../../motion/dashboard_semantic_catalog.dart';
import 'prepared_presentation_frame.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/dashboard_directional_query_set.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/local_date.dart';
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
    required this.metrics,
  });

  factory PreparedDashboardIndexAssembly.zeroUniverse({
    required PreparedDashboardIndexKey key,
    CurrentLedgerQueryScope? filterScope,
    DashboardDirectionalQuerySet? directionalQueries,
    required int initialYear,
    Iterable<LedgerDirection> directions = LedgerDirection.values,
  }) {
    if ((filterScope == null) == (directionalQueries == null)) {
      throw ArgumentError(
        'Zero-universe assembly requires exactly one filter scope or directional query set.',
      );
    }
    final queries =
        directionalQueries ??
        DashboardDirectionalQuerySet.fromInitial(filterScope!);
    final radius = initialYear - key.yearWindowStart;
    if (radius < 1 || key.yearWindowEndInclusive - initialYear != radius) {
      throw ArgumentError('Prepared dashboard year window must be symmetric.');
    }
    final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
    final catalogs = <LedgerQueryKey, DashboardSemanticCatalog>{};
    final scopes = <LedgerQueryKey, CurrentLedgerQueryScope>{};
    final origins = <LedgerQueryKey, DashboardDataOrigin>{};
    final catalogTimer = Stopwatch()..start();
    var scopeMicros = 0;
    var semanticEntryCount = 0;

    void addScope(CurrentLedgerQueryScope scope) {
      final started = Stopwatch()..start();
      scopes[scope.key] = scope;
      started.stop();
      scopeMicros += started.elapsedMicroseconds;
    }

    void addCatalog(DashboardSemanticCatalog catalog) {
      catalogs[catalog.parentScope.key] = catalog;
      addScope(catalog.parentScope);
      for (final semantic in catalog.entries) {
        semanticEntryCount += 1;
        addScope(semantic.scope);
      }
    }

    final requestedDirections = directions.toSet();
    if (requestedDirections.isEmpty ||
        requestedDirections.any(
          (direction) => !LedgerDirection.values.contains(direction),
        )) {
      throw ArgumentError.value(
        directions,
        'directions',
        'must contain at least one ledger direction',
      );
    }
    for (final direction in requestedDirections) {
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
    catalogTimer.stop();
    return PreparedDashboardIndexAssembly._(
      frames: frames,
      catalogs: catalogs,
      scopes: scopes,
      origins: origins,
      metrics: PreparedDashboardIndexAssemblyMetrics(
        zeroUniverseCatalogDurationMicros: catalogTimer.elapsedMicroseconds,
        zeroUniverseScopeDurationMicros: scopeMicros,
        zeroFrameMaterializationDurationMicros: 0,
        zeroScopeCount: scopes.length,
        zeroFrameCount: 0,
        semanticCatalogCount: catalogs.length,
        semanticEntryCount: semanticEntryCount,
      ),
    );
  }

  final Map<LedgerQueryKey, DashboardPreparedFrame> frames;
  final Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs;
  final Map<LedgerQueryKey, CurrentLedgerQueryScope> scopes;
  final Map<LedgerQueryKey, DashboardDataOrigin> origins;
  final PreparedDashboardIndexAssemblyMetrics metrics;
}

/// Decode-only accounting for deterministic hierarchy assembly.  This makes
/// semantic catalog construction, compact zero-scope identity and sparse
/// frame installation measurable without conflating them with rich LogBox
/// projection or isolate scheduling.
@immutable
final class PreparedDashboardIndexAssemblyMetrics {
  const PreparedDashboardIndexAssemblyMetrics({
    required this.zeroUniverseCatalogDurationMicros,
    required this.zeroUniverseScopeDurationMicros,
    required this.zeroFrameMaterializationDurationMicros,
    required this.zeroScopeCount,
    required this.zeroFrameCount,
    required this.semanticCatalogCount,
    required this.semanticEntryCount,
  });

  final int zeroUniverseCatalogDurationMicros;
  final int zeroUniverseScopeDurationMicros;
  final int zeroFrameMaterializationDurationMicros;
  final int zeroScopeCount;
  final int zeroFrameCount;
  final int semanticCatalogCount;
  final int semanticEntryCount;
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

  static const int currentModelVersion = 4;

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

  static String _filterIdentity(CurrentLedgerQueryScope scope) =>
      scope.copyWith(timeScope: const AllTimeScope()).key.value;

  /// Stable request identity for diagnostics and cache correlation.
  ///
  /// This deliberately reports the exact two-direction immutable input rather
  /// than the legacy compatibility income filter fields.
  String get diagnosticIdentity =>
      'rev:$coreRevision|income:$incomeFilterKey|expense:$expenseFilterKey|'
      'page:$pageSize|window:$yearWindowStart-$yearWindowEndInclusive';

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
    this.compactIndexAssemblyDurationMicros = 0,
    this.decodeWorkerWallDurationMicros = 0,
    this.zeroUniverseCatalogDurationMicros = 0,
    this.zeroUniverseScopeDurationMicros = 0,
    this.zeroFrameMaterializationDurationMicros = 0,
    this.sparseFrameInstallDurationMicros = 0,
    this.zeroScopeCount = 0,
    this.zeroFrameCount = 0,
    this.semanticCatalogCount = 0,
    this.semanticEntryCount = 0,
    this.richRowProjectionDurationMicros = 0,
    this.richFrameProjectionDurationMicros = 0,
    this.projectedUniqueRowCount = 0,
    this.projectedFrameCount = 0,
    this.reusedProjectedRowCount = 0,
    this.reusedProjectedFrameCount = 0,
    this.isSynthetic = false,
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
      compactIndexAssemblyDurationMicros = 0,
      decodeWorkerWallDurationMicros = 0,
      zeroUniverseCatalogDurationMicros = 0,
      zeroUniverseScopeDurationMicros = 0,
      zeroFrameMaterializationDurationMicros = 0,
      sparseFrameInstallDurationMicros = 0,
      zeroScopeCount = 0,
      zeroFrameCount = 0,
      semanticCatalogCount = 0,
      semanticEntryCount = 0,
      richRowProjectionDurationMicros = 0,
      richFrameProjectionDurationMicros = 0,
      projectedUniqueRowCount = 0,
      projectedFrameCount = 0,
      reusedProjectedRowCount = 0,
      reusedProjectedFrameCount = 0,
      isSynthetic = true,
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
  final int compactIndexAssemblyDurationMicros;
  final int decodeWorkerWallDurationMicros;
  final int zeroUniverseCatalogDurationMicros;
  final int zeroUniverseScopeDurationMicros;
  final int zeroFrameMaterializationDurationMicros;
  final int sparseFrameInstallDurationMicros;
  final int zeroScopeCount;
  final int zeroFrameCount;
  final int semanticCatalogCount;
  final int semanticEntryCount;
  final int richRowProjectionDurationMicros;
  final int richFrameProjectionDurationMicros;
  final int projectedUniqueRowCount;
  final int projectedFrameCount;
  final int reusedProjectedRowCount;
  final int reusedProjectedFrameCount;

  /// Marks deliberately synthetic test-only index data. Production binary
  /// decoding never sets this, so it cannot mask a missing native geometry
  /// seed in the application.
  final bool isSynthetic;
  final int payloadBytes;
  final int estimatedIndexBytes;

  PreparedDashboardIndexBuildMetrics copyWith({
    int? sqlCallCount,
    int? nativeSqlDurationMicros,
    int? aggregateBucketCount,
    int? scannedLedgerRowCount,
    int? uniquePreviewRowCount,
    int? frameCount,
    int? nativeQueryDurationMicros,
    int? nativeAggregationDurationMicros,
    int? nativeMappingDurationMicros,
    int? serializationDurationMicros,
    int? bridgeTransferDurationMicros,
    int? dartDecodeDurationMicros,
    int? dartProjectionDurationMicros,
    int? compactIndexAssemblyDurationMicros,
    int? decodeWorkerWallDurationMicros,
    int? zeroUniverseCatalogDurationMicros,
    int? zeroUniverseScopeDurationMicros,
    int? zeroFrameMaterializationDurationMicros,
    int? sparseFrameInstallDurationMicros,
    int? zeroScopeCount,
    int? zeroFrameCount,
    int? semanticCatalogCount,
    int? semanticEntryCount,
    int? richRowProjectionDurationMicros,
    int? richFrameProjectionDurationMicros,
    int? projectedUniqueRowCount,
    int? projectedFrameCount,
    int? reusedProjectedRowCount,
    int? reusedProjectedFrameCount,
    bool? isSynthetic,
    int? payloadBytes,
    int? estimatedIndexBytes,
  }) => PreparedDashboardIndexBuildMetrics(
    sqlCallCount: sqlCallCount ?? this.sqlCallCount,
    nativeSqlDurationMicros:
        nativeSqlDurationMicros ?? this.nativeSqlDurationMicros,
    aggregateBucketCount: aggregateBucketCount ?? this.aggregateBucketCount,
    scannedLedgerRowCount: scannedLedgerRowCount ?? this.scannedLedgerRowCount,
    uniquePreviewRowCount: uniquePreviewRowCount ?? this.uniquePreviewRowCount,
    frameCount: frameCount ?? this.frameCount,
    nativeQueryDurationMicros:
        nativeQueryDurationMicros ?? this.nativeQueryDurationMicros,
    nativeAggregationDurationMicros:
        nativeAggregationDurationMicros ?? this.nativeAggregationDurationMicros,
    nativeMappingDurationMicros:
        nativeMappingDurationMicros ?? this.nativeMappingDurationMicros,
    serializationDurationMicros:
        serializationDurationMicros ?? this.serializationDurationMicros,
    bridgeTransferDurationMicros:
        bridgeTransferDurationMicros ?? this.bridgeTransferDurationMicros,
    dartDecodeDurationMicros:
        dartDecodeDurationMicros ?? this.dartDecodeDurationMicros,
    dartProjectionDurationMicros:
        dartProjectionDurationMicros ?? this.dartProjectionDurationMicros,
    compactIndexAssemblyDurationMicros:
        compactIndexAssemblyDurationMicros ??
        this.compactIndexAssemblyDurationMicros,
    decodeWorkerWallDurationMicros:
        decodeWorkerWallDurationMicros ?? this.decodeWorkerWallDurationMicros,
    zeroUniverseCatalogDurationMicros:
        zeroUniverseCatalogDurationMicros ??
        this.zeroUniverseCatalogDurationMicros,
    zeroUniverseScopeDurationMicros:
        zeroUniverseScopeDurationMicros ?? this.zeroUniverseScopeDurationMicros,
    zeroFrameMaterializationDurationMicros:
        zeroFrameMaterializationDurationMicros ??
        this.zeroFrameMaterializationDurationMicros,
    sparseFrameInstallDurationMicros:
        sparseFrameInstallDurationMicros ??
        this.sparseFrameInstallDurationMicros,
    zeroScopeCount: zeroScopeCount ?? this.zeroScopeCount,
    zeroFrameCount: zeroFrameCount ?? this.zeroFrameCount,
    semanticCatalogCount: semanticCatalogCount ?? this.semanticCatalogCount,
    semanticEntryCount: semanticEntryCount ?? this.semanticEntryCount,
    richRowProjectionDurationMicros:
        richRowProjectionDurationMicros ?? this.richRowProjectionDurationMicros,
    richFrameProjectionDurationMicros:
        richFrameProjectionDurationMicros ??
        this.richFrameProjectionDurationMicros,
    projectedUniqueRowCount:
        projectedUniqueRowCount ?? this.projectedUniqueRowCount,
    projectedFrameCount: projectedFrameCount ?? this.projectedFrameCount,
    reusedProjectedRowCount:
        reusedProjectedRowCount ?? this.reusedProjectedRowCount,
    reusedProjectedFrameCount:
        reusedProjectedFrameCount ?? this.reusedProjectedFrameCount,
    isSynthetic: isSynthetic ?? this.isSynthetic,
    payloadBytes: payloadBytes ?? this.payloadBytes,
    estimatedIndexBytes: estimatedIndexBytes ?? this.estimatedIndexBytes,
  );
}

/// Immutable half of the one dashboard index. It has no independent
/// publication path: a new [PreparedDashboardIndex] only references it while
/// its filter identity and immutable core revision are exact. Shared lifetime
/// is ordinary immutable Dart object ownership: active and staged composite
/// indexes retain this instance by reference, and the VM may collect it only
/// after the final composite index releases it.
@immutable
final class PreparedDashboardDirectionalPartition {
  PreparedDashboardDirectionalPartition._({
    required this.direction,
    required this.filterKey,
    required this.coreRevision,
    required Map<LedgerQueryKey, DashboardPreparedFrame> frames,
    required Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs,
    required Map<LedgerQueryKey, DashboardDataOrigin> origins,
    required Map<LedgerQueryKey, DashboardPreparedCompactZeroFrame>
    compactZeroFrames,
    required List<CommittedVerticalGeometryDayBucket> verticalGeometrySeed,
    required this.focusMembershipSeed,
  }) : frames = Map<LedgerQueryKey, DashboardPreparedFrame>.unmodifiable(
         frames,
       ),
       catalogs = Map<LedgerQueryKey, DashboardSemanticCatalog>.unmodifiable(
         catalogs,
       ),
       origins = Map<LedgerQueryKey, DashboardDataOrigin>.unmodifiable(origins),
       compactZeroFrames =
           Map<LedgerQueryKey, DashboardPreparedCompactZeroFrame>.unmodifiable(
             compactZeroFrames,
           ),
       verticalGeometrySeed =
           List<CommittedVerticalGeometryDayBucket>.unmodifiable(
             verticalGeometrySeed,
           ) {
    if (frames.values.any((frame) => frame.scope.direction != direction) ||
        catalogs.values.any(
          (catalog) => catalog.parentScope.direction != direction,
        ) ||
        origins.keys.any((key) => frames[key]?.scope.direction != direction) ||
        compactZeroFrames.values.any(
          (zero) => zero.scope.direction != direction,
        ) ||
        !_isValidVerticalGeometrySeed(verticalGeometrySeed)) {
      throw ArgumentError('Prepared partition contains another direction.');
    }
  }

  final LedgerDirection direction;
  final String filterKey;
  final int coreRevision;
  final Map<LedgerQueryKey, DashboardPreparedFrame> frames;
  final Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs;
  final Map<LedgerQueryKey, DashboardDataOrigin> origins;
  final Map<LedgerQueryKey, DashboardPreparedCompactZeroFrame>
  compactZeroFrames;

  /// Ordered newest-to-oldest daily counts for this exact directional Query
  /// partition. This is aggregate metadata only; it does not materialize
  /// rows, labels or TextPainters.
  final List<CommittedVerticalGeometryDayBucket> verticalGeometrySeed;

  /// Exact base-scope semantic row membership for ephemeral focus. It remains
  /// compact/raw and never creates row view models or TextPainters by itself.
  final DashboardFocusMembershipSeed? focusMembershipSeed;

  CommittedVerticalGeometryManifest committedVerticalGeometryFor(
    CurrentLedgerQueryScope scope, {
    required int pageSize,
    required int totalEntryCount,
    required int coreRevision,
  }) {
    if (scope.direction != direction || coreRevision != this.coreRevision) {
      throw StateError('A geometry manifest requires its exact partition.');
    }
    final bounds = scope.timeScope.boundaries;
    final startEpochDay = bounds == null
        ? null
        : _epochDay(bounds.startInclusive);
    final endEpochDay = bounds == null ? null : _epochDay(bounds.endExclusive);
    final buckets = bounds == null
        ? verticalGeometrySeed
        : verticalGeometrySeed
              .where(
                (bucket) =>
                    bucket.bookedLocalEpochDay >= startEpochDay! &&
                    bucket.bookedLocalEpochDay < endEpochDay!,
              )
              .toList(growable: false);
    return CommittedVerticalGeometryManifest.compile(
      queryKey: scope.key,
      coreRevision: coreRevision,
      pageSize: pageSize,
      totalEntryCount: totalEntryCount,
      dayBuckets: buckets,
    );
  }

  static bool _isValidVerticalGeometrySeed(
    List<CommittedVerticalGeometryDayBucket> seed,
  ) {
    var previous = 1 << 62;
    for (final bucket in seed) {
      if (bucket.entryCount <= 0 || bucket.bookedLocalEpochDay >= previous) {
        return false;
      }
      previous = bucket.bookedLocalEpochDay;
    }
    return true;
  }

  static int _epochDay(LocalDate value) => DateTime.utc(
    value.year,
    value.month,
    value.day,
  ).difference(DateTime.utc(1970)).inDays;

  /// Compact row identity accounting must not force rich LogBox projection
  /// while a directional partition is being composed or reused.
  int get preparedRowCount {
    final identities = <String>{};
    for (final frame in frames.values) {
      frame.logBox.forEachStableRowIdentity(identities.add);
    }
    return identities.length;
  }
}

/// Compact identity for one deterministic empty scope.
///
/// The hierarchy has many valid zero scopes.  Keeping this descriptor instead
/// of a fully projected frame avoids eagerly allocating summary view models
/// and an empty LogBox viewport for every day in the physical year window.
/// The exact complete frame is memoized only when a bounded prepared scene
/// window or an already-authoritative frame selects this scope.
final class DashboardPreparedCompactZeroFrame {
  DashboardPreparedCompactZeroFrame({
    required this.scope,
    required this.coreRevision,
  }) : queryKey = scope.key,
       parentQueryKey = dashboardPreparedParentQueryKey(scope);

  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey queryKey;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  DashboardPreparedFrame? _materialized;

  bool get isMaterialized => _materialized != null;

  DashboardPreparedFrame materialize() =>
      _materialized ??= DashboardPreparedFrame.complete(
        scope: scope,
        parentQueryKey: parentQueryKey,
        coreRevision: coreRevision,
        totalMinor: 0,
        formattedAmount: '0 Ft',
        entryCount: 0,
        formattedEntryCount: '0',
        logBox: DashboardLogViewportState(
          queryKey: queryKey,
          revision: coreRevision,
          groups: const [],
          entryCount: 0,
          nextCursor: null,
          direction: scope.direction,
        ),
        presentationDigest: Object.hash(queryKey, coreRevision, 0),
      );
}

/// Immutable two-map view used by one focus overlay. The focused half and the
/// unchanged base half use disjoint directional query identities, so lookup
/// stays O(1) without copying the full base map into another index.
final class _PreparedIndexOverlayMap<K, V> extends MapBase<K, V> {
  _PreparedIndexOverlayMap(this._primary, this._fallback) {
    if (_primary.keys.any(_fallback.containsKey)) {
      throw ArgumentError('Prepared overlay maps must have disjoint keys.');
    }
  }

  final Map<K, V> _primary;
  final Map<K, V> _fallback;

  @override
  V? operator [](Object? key) {
    if (key is K && _primary.containsKey(key)) return _primary[key];
    return _fallback[key];
  }

  @override
  bool containsKey(Object? key) =>
      key is K && (_primary.containsKey(key) || _fallback.containsKey(key));

  @override
  Iterable<K> get keys sync* {
    yield* _primary.keys;
    yield* _fallback.keys;
  }

  @override
  int get length => _primary.length + _fallback.length;

  @override
  void operator []=(K key, V value) {
    throw UnsupportedError('Prepared overlay maps are immutable.');
  }

  @override
  V? remove(Object? key) {
    throw UnsupportedError('Prepared overlay maps are immutable.');
  }

  @override
  void clear() {
    throw UnsupportedError('Prepared overlay maps are immutable.');
  }
}

/// One complete immutable data source for every dashboard interaction.
@immutable
final class PreparedDashboardIndex {
  const PreparedDashboardIndex._({
    required this.key,
    required this.frames,
    required this.compactZeroFrames,
    required this.catalogs,
    required this.catalogsByDirectionAndScope,
    required this.origins,
    required this.partitions,
    required this.builtDirection,
    required this.reusedDirection,
    required this.reusedPreparedRowCount,
    required this.generation,
    required this.contentDigest,
    required this.preparedAt,
    required this.buildMetrics,
  });

  factory PreparedDashboardIndex.complete({
    required PreparedDashboardIndexKey key,
    required Map<LedgerQueryKey, DashboardPreparedFrame> frames,
    required Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs,
    Map<LedgerQueryKey, CurrentLedgerQueryScope>? scopes,
    Map<LedgerQueryKey, DashboardDataOrigin>? origins,
    Map<LedgerDirection, List<CommittedVerticalGeometryDayBucket>>
        geometrySeedsByDirection =
        const <LedgerDirection, List<CommittedVerticalGeometryDayBucket>>{},
    Map<LedgerDirection, DashboardFocusMembershipSeed>
        focusMembershipSeedsByDirection =
        const <LedgerDirection, DashboardFocusMembershipSeed>{},
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
    final resolvedScopes = <LedgerQueryKey, CurrentLedgerQueryScope>{
      ...?scopes,
      for (final frame in frames.values) frame.queryKey: frame.scope,
      for (final catalog
          in catalogs.values) ...<LedgerQueryKey, CurrentLedgerQueryScope>{
        catalog.parentScope.key: catalog.parentScope,
        for (final semantic in catalog.entries)
          semantic.queryKey: semantic.scope,
      },
    };
    final compactZeroFrames =
        <LedgerQueryKey, DashboardPreparedCompactZeroFrame>{
          for (final entry in resolvedScopes.entries)
            if (!frames.containsKey(entry.key))
              entry.key: DashboardPreparedCompactZeroFrame(
                scope: entry.value,
                coreRevision: key.coreRevision,
              ),
        };
    for (final entry in catalogs.entries) {
      final catalog = entry.value;
      if (entry.key != catalog.parentScope.key ||
          !key.matchesScope(catalog.parentScope)) {
        throw ArgumentError('Prepared semantic catalog is inconsistent.');
      }
      for (final semantic in catalog.entries) {
        final frame = frames[semantic.queryKey];
        final compactZero = compactZeroFrames[semantic.queryKey];
        if ((frame == null || frame.scope != semantic.scope) &&
            (compactZero == null || compactZero.scope != semantic.scope)) {
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
    final immutableFrames =
        Map<LedgerQueryKey, DashboardPreparedFrame>.unmodifiable(frames);
    final immutableCompactZeroFrames =
        Map<LedgerQueryKey, DashboardPreparedCompactZeroFrame>.unmodifiable(
          compactZeroFrames,
        );
    final immutableCatalogs =
        Map<LedgerQueryKey, DashboardSemanticCatalog>.unmodifiable(catalogs);
    final immutableOrigins =
        Map<LedgerQueryKey, DashboardDataOrigin>.unmodifiable(resolvedOrigins);
    final partitions = <LedgerDirection, PreparedDashboardDirectionalPartition>{
      for (final direction in LedgerDirection.values)
        direction: PreparedDashboardDirectionalPartition._(
          direction: direction,
          filterKey: switch (direction) {
            LedgerDirection.income => key.incomeFilterKey,
            LedgerDirection.expense => key.expenseFilterKey,
          },
          coreRevision: key.coreRevision,
          frames: <LedgerQueryKey, DashboardPreparedFrame>{
            for (final entry in immutableFrames.entries)
              if (entry.value.scope.direction == direction)
                entry.key: entry.value,
          },
          catalogs: <LedgerQueryKey, DashboardSemanticCatalog>{
            for (final entry in immutableCatalogs.entries)
              if (entry.value.parentScope.direction == direction)
                entry.key: entry.value,
          },
          origins: <LedgerQueryKey, DashboardDataOrigin>{
            for (final entry in immutableOrigins.entries)
              if (immutableFrames[entry.key]?.scope.direction == direction)
                entry.key: entry.value,
          },
          compactZeroFrames:
              <LedgerQueryKey, DashboardPreparedCompactZeroFrame>{
                for (final entry in immutableCompactZeroFrames.entries)
                  if (entry.value.scope.direction == direction)
                    entry.key: entry.value,
              },
          verticalGeometrySeed:
              geometrySeedsByDirection[direction] ??
              const <CommittedVerticalGeometryDayBucket>[],
          focusMembershipSeed: focusMembershipSeedsByDirection[direction],
        ),
    };
    return PreparedDashboardIndex._(
      key: key,
      frames: immutableFrames,
      compactZeroFrames: immutableCompactZeroFrames,
      catalogs: immutableCatalogs,
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
      origins: immutableOrigins,
      partitions:
          Map<
            LedgerDirection,
            PreparedDashboardDirectionalPartition
          >.unmodifiable(partitions),
      builtDirection: null,
      reusedDirection: null,
      reusedPreparedRowCount: 0,
      generation: generation,
      contentDigest: contentDigest,
      preparedAt: preparedAt.toUtc(),
      buildMetrics: buildMetrics,
    );
  }

  /// Creates an ephemeral directional view over [base]. Only
  /// [focusedDirection]'s compact frames/catalogs are new; the opposite
  /// directional partition stays referenced by identity. This keeps focus
  /// publication from copying or validating the base universe again while
  /// preserving the same complete [PreparedDashboardIndex] contract for the
  /// existing presentation, rail, and scene owners.
  factory PreparedDashboardIndex.focusedDirectionalOverlay({
    required PreparedDashboardIndex base,
    required PreparedDashboardIndexKey key,
    required LedgerDirection focusedDirection,
    required Map<LedgerQueryKey, DashboardPreparedFrame> focusedFrames,
    required Map<LedgerQueryKey, DashboardSemanticCatalog> focusedCatalogs,
    required Map<LedgerQueryKey, CurrentLedgerQueryScope> focusedScopes,
    required Map<LedgerQueryKey, DashboardDataOrigin> focusedOrigins,
    required List<CommittedVerticalGeometryDayBucket> focusedGeometrySeed,
    required int generation,
    required int contentDigest,
    required DateTime preparedAt,
    required PreparedDashboardIndexBuildMetrics buildMetrics,
  }) {
    if (key.coreRevision != base.coreRevision ||
        key.pageSize != base.pageSize ||
        generation <= 0) {
      throw ArgumentError('Focused directional overlay identity is invalid.');
    }
    final inactiveDirection = switch (focusedDirection) {
      LedgerDirection.income => LedgerDirection.expense,
      LedgerDirection.expense => LedgerDirection.income,
    };
    final inactive = base.partitionFor(inactiveDirection);
    final expectedInactiveFilter = switch (inactiveDirection) {
      LedgerDirection.income => key.incomeFilterKey,
      LedgerDirection.expense => key.expenseFilterKey,
    };
    if (inactive.coreRevision != key.coreRevision ||
        inactive.filterKey != expectedInactiveFilter) {
      throw ArgumentError(
        'Focused overlay may reuse only the exact inactive base partition.',
      );
    }
    final expectedFocusedFilter = switch (focusedDirection) {
      LedgerDirection.income => key.incomeFilterKey,
      LedgerDirection.expense => key.expenseFilterKey,
    };
    if (focusedFrames.values.any(
          (frame) =>
              frame.scope.direction != focusedDirection ||
              frame.coreRevision != key.coreRevision ||
              !key.matchesScope(frame.scope),
        ) ||
        focusedCatalogs.values.any(
          (catalog) =>
              catalog.parentScope.direction != focusedDirection ||
              !key.matchesScope(catalog.parentScope),
        ) ||
        focusedScopes.values.any(
          (scope) =>
              scope.direction != focusedDirection || !key.matchesScope(scope),
        ) ||
        focusedOrigins.keys.any(
          (queryKey) => !focusedFrames.containsKey(queryKey),
        )) {
      throw ArgumentError('Focused overlay contents are not exact.');
    }
    final focusedCompactZeros =
        <LedgerQueryKey, DashboardPreparedCompactZeroFrame>{
          for (final entry in focusedScopes.entries)
            if (!focusedFrames.containsKey(entry.key))
              entry.key: DashboardPreparedCompactZeroFrame(
                scope: entry.value,
                coreRevision: key.coreRevision,
              ),
        };
    final focusedPartition = PreparedDashboardDirectionalPartition._(
      direction: focusedDirection,
      filterKey: expectedFocusedFilter,
      coreRevision: key.coreRevision,
      frames: focusedFrames,
      catalogs: focusedCatalogs,
      origins: focusedOrigins,
      compactZeroFrames: focusedCompactZeros,
      verticalGeometrySeed: focusedGeometrySeed,
      focusMembershipSeed: null,
    );
    final focusedCatalogsByScope = <LedgerTimeScope, DashboardSemanticCatalog>{
      for (final catalog in focusedPartition.catalogs.values)
        catalog.parentScope.timeScope: catalog,
    };
    return PreparedDashboardIndex._(
      key: key,
      frames: _PreparedIndexOverlayMap<LedgerQueryKey, DashboardPreparedFrame>(
        focusedPartition.frames,
        inactive.frames,
      ),
      compactZeroFrames:
          _PreparedIndexOverlayMap<
            LedgerQueryKey,
            DashboardPreparedCompactZeroFrame
          >(focusedPartition.compactZeroFrames, inactive.compactZeroFrames),
      catalogs:
          _PreparedIndexOverlayMap<LedgerQueryKey, DashboardSemanticCatalog>(
            focusedPartition.catalogs,
            inactive.catalogs,
          ),
      catalogsByDirectionAndScope:
          Map<
            LedgerDirection,
            Map<LedgerTimeScope, DashboardSemanticCatalog>
          >.unmodifiable(
            <LedgerDirection, Map<LedgerTimeScope, DashboardSemanticCatalog>>{
              focusedDirection:
                  Map<LedgerTimeScope, DashboardSemanticCatalog>.unmodifiable(
                    focusedCatalogsByScope,
                  ),
              inactiveDirection:
                  base.catalogsByDirectionAndScope[inactiveDirection]!,
            },
          ),
      origins: _PreparedIndexOverlayMap<LedgerQueryKey, DashboardDataOrigin>(
        focusedPartition.origins,
        inactive.origins,
      ),
      partitions:
          Map<
            LedgerDirection,
            PreparedDashboardDirectionalPartition
          >.unmodifiable(
            <LedgerDirection, PreparedDashboardDirectionalPartition>{
              focusedDirection: focusedPartition,
              inactiveDirection: inactive,
            },
          ),
      builtDirection: focusedDirection,
      reusedDirection: inactiveDirection,
      reusedPreparedRowCount: inactive.preparedRowCount,
      generation: generation,
      contentDigest: contentDigest,
      preparedAt: preparedAt.toUtc(),
      buildMetrics: buildMetrics,
    );
  }

  factory PreparedDashboardIndex.composeDirectionalPartitions({
    required PreparedDashboardIndexKey key,
    required PreparedDashboardDirectionalPartition income,
    required PreparedDashboardDirectionalPartition expense,
    required int generation,
    required int contentDigest,
    required DateTime preparedAt,
    required PreparedDashboardIndexBuildMetrics buildMetrics,
    LedgerDirection? builtDirection,
    LedgerDirection? reusedDirection,
  }) {
    final expected = <LedgerDirection, PreparedDashboardDirectionalPartition>{
      LedgerDirection.income: income,
      LedgerDirection.expense: expense,
    };
    for (final entry in expected.entries) {
      final expectedFilter = switch (entry.key) {
        LedgerDirection.income => key.incomeFilterKey,
        LedgerDirection.expense => key.expenseFilterKey,
      };
      if (entry.value.direction != entry.key ||
          entry.value.coreRevision != key.coreRevision ||
          entry.value.filterKey != expectedFilter) {
        throw ArgumentError('Directional partition identity is inconsistent.');
      }
    }
    final complete = PreparedDashboardIndex.complete(
      key: key,
      frames: <LedgerQueryKey, DashboardPreparedFrame>{
        ...income.frames,
        ...expense.frames,
      },
      catalogs: <LedgerQueryKey, DashboardSemanticCatalog>{
        ...income.catalogs,
        ...expense.catalogs,
      },
      scopes: <LedgerQueryKey, CurrentLedgerQueryScope>{
        for (final zero in income.compactZeroFrames.values)
          zero.queryKey: zero.scope,
        for (final zero in expense.compactZeroFrames.values)
          zero.queryKey: zero.scope,
        for (final frame in income.frames.values) frame.queryKey: frame.scope,
        for (final frame in expense.frames.values) frame.queryKey: frame.scope,
      },
      origins: <LedgerQueryKey, DashboardDataOrigin>{
        ...income.origins,
        ...expense.origins,
      },
      geometrySeedsByDirection:
          <LedgerDirection, List<CommittedVerticalGeometryDayBucket>>{
            LedgerDirection.income: income.verticalGeometrySeed,
            LedgerDirection.expense: expense.verticalGeometrySeed,
          },
      focusMembershipSeedsByDirection:
          <LedgerDirection, DashboardFocusMembershipSeed>{
            if (income.focusMembershipSeed != null)
              LedgerDirection.income: income.focusMembershipSeed!,
            if (expense.focusMembershipSeed != null)
              LedgerDirection.expense: expense.focusMembershipSeed!,
          },
      generation: generation,
      contentDigest: contentDigest,
      preparedAt: preparedAt,
      buildMetrics: buildMetrics,
    );
    return PreparedDashboardIndex._(
      key: complete.key,
      frames: complete.frames,
      compactZeroFrames: complete.compactZeroFrames,
      catalogs: complete.catalogs,
      catalogsByDirectionAndScope: complete.catalogsByDirectionAndScope,
      origins: complete.origins,
      partitions:
          Map<
            LedgerDirection,
            PreparedDashboardDirectionalPartition
          >.unmodifiable(expected),
      builtDirection: builtDirection,
      reusedDirection: reusedDirection,
      reusedPreparedRowCount: reusedDirection == null
          ? 0
          : expected[reusedDirection]!.preparedRowCount,
      generation: complete.generation,
      contentDigest: complete.contentDigest,
      preparedAt: complete.preparedAt,
      buildMetrics: complete.buildMetrics,
    );
  }

  final PreparedDashboardIndexKey key;
  final Map<LedgerQueryKey, DashboardPreparedFrame> frames;
  final Map<LedgerQueryKey, DashboardPreparedCompactZeroFrame>
  compactZeroFrames;
  final Map<LedgerQueryKey, DashboardSemanticCatalog> catalogs;
  final Map<LedgerDirection, Map<LedgerTimeScope, DashboardSemanticCatalog>>
  catalogsByDirectionAndScope;
  final Map<LedgerQueryKey, DashboardDataOrigin> origins;
  final Map<LedgerDirection, PreparedDashboardDirectionalPartition> partitions;
  final LedgerDirection? builtDirection;
  final LedgerDirection? reusedDirection;
  final int reusedPreparedRowCount;
  final int generation;
  final int contentDigest;
  final DateTime preparedAt;
  final PreparedDashboardIndexBuildMetrics buildMetrics;

  int get coreRevision => key.coreRevision;
  int get pageSize => key.pageSize;

  PreparedDashboardDirectionalPartition partitionFor(
    LedgerDirection direction,
  ) => partitions[direction]!;

  /// Compiles the immutable full scroll world from the exact Query partition
  /// that already owns the frame's filtered aggregate universe. The result is
  /// intentionally independent from the bounded page/resource hotset.
  CommittedVerticalGeometryManifest committedVerticalGeometryFor(
    CurrentLedgerQueryScope scope,
  ) {
    _requireScopeIdentity(scope);
    final frame = frameFor(scope);
    final partition = partitionFor(scope.direction);
    if (partition.verticalGeometrySeed.isEmpty && frame.count.entryCount > 0) {
      if (!buildMetrics.isSynthetic) {
        throw StateError(
          'A nonempty committed scope is missing its native geometry seed.',
        );
      }
      // Existing controller/widget fixtures predate the prepared-index binary
      // geometry seed and intentionally model unrelated sparse frames. This
      // is a test-only immutable full-world stand-in, never a production
      // fallback: production decoding leaves [isSynthetic] false and fails
      // closed above instead.
      return _syntheticCommittedVerticalGeometryFor(scope, frame);
    }
    return partition.committedVerticalGeometryFor(
      scope,
      pageSize: pageSize,
      totalEntryCount: frame.count.entryCount,
      coreRevision: coreRevision,
    );
  }

  CommittedVerticalGeometryManifest _syntheticCommittedVerticalGeometryFor(
    CurrentLedgerQueryScope scope,
    DashboardPreparedFrame frame,
  ) {
    var remaining = frame.count.entryCount;
    var day = 2_000_000_000;
    final buckets = <CommittedVerticalGeometryDayBucket>[];
    for (final group in frame.logBox.groups) {
      if (remaining == 0) break;
      final rows = group.rows.length < remaining
          ? group.rows.length
          : remaining;
      if (rows == 0) continue;
      buckets.add(
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: day,
          entryCount: rows,
        ),
      );
      day -= 1;
      remaining -= rows;
    }
    if (remaining > 0) {
      buckets.add(
        CommittedVerticalGeometryDayBucket(
          bookedLocalEpochDay: day,
          entryCount: remaining,
        ),
      );
    }
    return CommittedVerticalGeometryManifest.compile(
      queryKey: scope.key,
      coreRevision: coreRevision,
      pageSize: pageSize,
      totalEntryCount: frame.count.entryCount,
      dayBuckets: buckets,
    );
  }

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
      compactZeroFrames: compactZeroFrames,
      catalogs: catalogs,
      catalogsByDirectionAndScope: catalogsByDirectionAndScope,
      origins: origins,
      partitions: partitions,
      builtDirection: builtDirection,
      reusedDirection: reusedDirection,
      reusedPreparedRowCount: reusedPreparedRowCount,
      generation: generation,
      contentDigest: contentDigest,
      preparedAt: preparedAt,
      buildMetrics: buildMetrics.copyWith(
        bridgeTransferDurationMicros: duration,
      ),
    );
  }

  /// Reattaches timing metadata measured by the transport/worker boundary
  /// without rebuilding, validating or copying the immutable index maps.
  PreparedDashboardIndex withBuildMetrics(
    PreparedDashboardIndexBuildMetrics metrics,
  ) => PreparedDashboardIndex._(
    key: key,
    frames: frames,
    compactZeroFrames: compactZeroFrames,
    catalogs: catalogs,
    catalogsByDirectionAndScope: catalogsByDirectionAndScope,
    origins: origins,
    partitions: partitions,
    builtDirection: builtDirection,
    reusedDirection: reusedDirection,
    reusedPreparedRowCount: reusedPreparedRowCount,
    generation: generation,
    contentDigest: contentDigest,
    preparedAt: preparedAt,
    buildMetrics: metrics,
  );

  DashboardPreparedFrame frameFor(CurrentLedgerQueryScope scope) {
    _requireScopeIdentity(scope);
    final frame = frames[scope.key];
    if (frame != null) return frame;
    final compactZero = compactZeroFrames[scope.key];
    if (compactZero == null) return _zeroFrame(scope);
    return compactZero.materialize();
  }

  DashboardPreparedFrame frameForKey(LedgerQueryKey queryKey) {
    final frame = frames[queryKey];
    if (frame != null) return frame;
    final compactZero = compactZeroFrames[queryKey];
    if (compactZero?.isMaterialized ?? false) {
      return compactZero!.materialize();
    }
    throw StateError(
      'Prepared index has no scene-prepared interactive frame for '
      '${queryKey.value}.',
    );
  }

  /// Explicit preparation-domain materialization for a compact deterministic
  /// zero scope.  Scene-window derivation calls this before TextPainter work;
  /// rail crossings and renderer lookup remain strict synchronous consumers
  /// of already-materialized frames through [frameForKey].
  DashboardPreparedFrame materializeFrameForPreparation(
    LedgerQueryKey queryKey,
  ) {
    final frame = frames[queryKey];
    if (frame != null) return frame;
    final compactZero = compactZeroFrames[queryKey];
    if (compactZero == null) {
      throw StateError('Prepared index has no frame for ${queryKey.value}.');
    }
    return compactZero.materialize();
  }

  /// Test/bootstrap-only expansion of a complete semantic universe. Normal
  /// production callers always provide an exact publication state and use the
  /// bounded [materializeFrameForPreparation] path instead.
  Iterable<DashboardPreparedFrame> materializeAllFramesForPreparation() sync* {
    yield* frames.values;
    for (final key in compactZeroFrames.keys) {
      yield materializeFrameForPreparation(key);
    }
  }

  bool hasMaterializedFrameForKey(LedgerQueryKey queryKey) =>
      frames.containsKey(queryKey) ||
      (compactZeroFrames[queryKey]?.isMaterialized ?? false);

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
