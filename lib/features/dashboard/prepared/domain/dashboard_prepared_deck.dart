import 'package:flutter/foundation.dart';

import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../motion/dashboard_semantic_catalog.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';

@immutable
final class DashboardPreparedDeckKey {
  const DashboardPreparedDeckKey({
    required this.modelVersion,
    required this.direction,
    required this.parentQueryKey,
    required this.categoryIdsKey,
    required this.partnerIdsKey,
    required this.refinementsKey,
    required this.childKind,
    required this.coreRevision,
    required this.pageSize,
    required this.semanticWindowIdentity,
  });

  factory DashboardPreparedDeckKey.fromScope({
    required CurrentLedgerQueryScope parentScope,
    required DashboardChildKind childKind,
    required int coreRevision,
    required int pageSize,
    required String semanticWindowIdentity,
    int modelVersion = currentModelVersion,
  }) {
    if (coreRevision <= 0) {
      throw ArgumentError.value(
        coreRevision,
        'coreRevision',
        'must be greater than zero',
      );
    }
    if (pageSize <= 0) {
      throw ArgumentError.value(pageSize, 'pageSize', 'must be positive');
    }
    return DashboardPreparedDeckKey(
      modelVersion: modelVersion,
      direction: parentScope.direction,
      parentQueryKey: parentScope.key,
      categoryIdsKey: _sortedValues(parentScope.categoryIds),
      partnerIdsKey: _sortedValues(parentScope.partnerIds),
      refinementsKey: _sortedRefinements(parentScope.refinements),
      childKind: childKind,
      coreRevision: coreRevision,
      pageSize: pageSize,
      semanticWindowIdentity: semanticWindowIdentity,
    );
  }

  static const int currentModelVersion = 1;

  final int modelVersion;
  final LedgerDirection direction;
  final LedgerQueryKey parentQueryKey;
  final String categoryIdsKey;
  final String partnerIdsKey;
  final String refinementsKey;
  final DashboardChildKind childKind;
  final int coreRevision;
  final int pageSize;
  final String semanticWindowIdentity;

  @override
  bool operator ==(Object other) =>
      other is DashboardPreparedDeckKey &&
      other.modelVersion == modelVersion &&
      other.direction == direction &&
      other.parentQueryKey == parentQueryKey &&
      other.categoryIdsKey == categoryIdsKey &&
      other.partnerIdsKey == partnerIdsKey &&
      other.refinementsKey == refinementsKey &&
      other.childKind == childKind &&
      other.coreRevision == coreRevision &&
      other.pageSize == pageSize &&
      other.semanticWindowIdentity == semanticWindowIdentity;

  @override
  int get hashCode => Object.hash(
    modelVersion,
    direction,
    parentQueryKey,
    categoryIdsKey,
    partnerIdsKey,
    refinementsKey,
    childKind,
    coreRevision,
    pageSize,
    semanticWindowIdentity,
  );

  @override
  String toString() => <Object>[
    modelVersion,
    direction.name,
    parentQueryKey.value,
    categoryIdsKey,
    partnerIdsKey,
    refinementsKey,
    childKind.name,
    coreRevision,
    pageSize,
    semanticWindowIdentity,
  ].join('|');

  static String _sortedValues(Iterable<String> values) {
    final sorted = values.toList()..sort();
    return sorted.join(',');
  }

  static String _sortedRefinements(Map<String, Object?> refinements) {
    final entries = refinements.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join(',');
  }
}

@immutable
final class DashboardAmountViewModel {
  const DashboardAmountViewModel({
    required this.queryKey,
    required this.coreRevision,
    required this.totalMinor,
    required this.formattedAmount,
  });

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int totalMinor;
  final String formattedAmount;
}

@immutable
final class DashboardCountViewModel {
  const DashboardCountViewModel({
    required this.queryKey,
    required this.coreRevision,
    required this.entryCount,
    required this.formattedEntryCount,
  });

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int entryCount;
  final String formattedEntryCount;
}

@immutable
final class DashboardHeaderViewModel {
  const DashboardHeaderViewModel({
    required this.queryKey,
    required this.coreRevision,
    required this.formattedEntryCount,
  });

  final LedgerQueryKey queryKey;
  final int coreRevision;
  final String formattedEntryCount;
}

@immutable
final class DashboardEmptyStateViewModel {
  const DashboardEmptyStateViewModel({
    required this.isEmpty,
    required this.message,
  });

  final bool isEmpty;
  final String message;
}

/// Immutable preparation evidence produced outside the UI isolate.
@immutable
final class DashboardPreparedDeckBuildMetrics {
  const DashboardPreparedDeckBuildMetrics({
    required this.sqlCallCount,
    required this.aggregateBucketCount,
    required this.scannedLedgerRowCount,
    required this.materializedPreviewRowCount,
    required this.nativeQueryDurationMicros,
    required this.nativeMappingDurationMicros,
    required this.dartDecodeProjectionDurationMicros,
    required this.payloadBytes,
  });

  const DashboardPreparedDeckBuildMetrics.synthetic()
    : sqlCallCount = 0,
      aggregateBucketCount = 0,
      scannedLedgerRowCount = 0,
      materializedPreviewRowCount = 0,
      nativeQueryDurationMicros = 0,
      nativeMappingDurationMicros = 0,
      dartDecodeProjectionDurationMicros = 0,
      payloadBytes = 0;

  final int sqlCallCount;
  final int aggregateBucketCount;
  final int scannedLedgerRowCount;
  final int materializedPreviewRowCount;
  final int nativeQueryDurationMicros;
  final int nativeMappingDurationMicros;
  final int dartDecodeProjectionDurationMicros;
  final int payloadBytes;
}

/// Fully projected, immutable input for one visible dashboard state.
@immutable
final class DashboardPreparedFrame {
  const DashboardPreparedFrame._({
    required this.scope,
    required this.queryKey,
    required this.parentQueryKey,
    required this.coreRevision,
    required this.amount,
    required this.count,
    required this.logBox,
    required this.header,
    required this.emptyState,
    required this.nextCursor,
    required this.stableRowIdentities,
    required this.stableAssetIdentities,
    required this.presentationDigest,
  });

  factory DashboardPreparedFrame.complete({
    required CurrentLedgerQueryScope scope,
    required LedgerQueryKey parentQueryKey,
    required int coreRevision,
    required int totalMinor,
    required String formattedAmount,
    required int entryCount,
    required String formattedEntryCount,
    required DashboardLogViewportState logBox,
    required int presentationDigest,
  }) {
    if (coreRevision <= 0) {
      throw ArgumentError.value(
        coreRevision,
        'coreRevision',
        'must be greater than zero',
      );
    }
    final queryKey = scope.key;
    if (logBox.queryKey != queryKey ||
        logBox.revision != coreRevision ||
        logBox.entryCount != entryCount ||
        logBox.direction != scope.direction) {
      throw ArgumentError(
        'Prepared LogBox identity must match its frame key, revision, count '
        'and direction.',
      );
    }
    final rowIdentities = <String>[];
    final assetIdentities = <String>{};
    for (final group in logBox.groups) {
      for (final row in group.rows) {
        rowIdentities.add(row.entryId);
        assetIdentities.add('${row.categoryColorId}|${row.categoryIconId}');
      }
    }
    return DashboardPreparedFrame._(
      scope: scope,
      queryKey: queryKey,
      parentQueryKey: parentQueryKey,
      coreRevision: coreRevision,
      amount: DashboardAmountViewModel(
        queryKey: queryKey,
        coreRevision: coreRevision,
        totalMinor: totalMinor,
        formattedAmount: formattedAmount,
      ),
      count: DashboardCountViewModel(
        queryKey: queryKey,
        coreRevision: coreRevision,
        entryCount: entryCount,
        formattedEntryCount: formattedEntryCount,
      ),
      logBox: logBox,
      header: DashboardHeaderViewModel(
        queryKey: queryKey,
        coreRevision: coreRevision,
        formattedEntryCount: formattedEntryCount,
      ),
      emptyState: DashboardEmptyStateViewModel(
        isEmpty: entryCount == 0,
        message: entryCount == 0 ? 'Nincs listázható tranzakció' : '',
      ),
      nextCursor: logBox.nextCursor,
      stableRowIdentities: List<String>.unmodifiable(rowIdentities),
      stableAssetIdentities: List<String>.unmodifiable(assetIdentities),
      presentationDigest: presentationDigest,
    );
  }

  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey queryKey;
  final LedgerQueryKey parentQueryKey;
  final int coreRevision;
  final DashboardAmountViewModel amount;
  final DashboardCountViewModel count;
  final DashboardLogViewportState logBox;
  final DashboardHeaderViewModel header;
  final DashboardEmptyStateViewModel emptyState;
  final Map<String, Object?>? nextCursor;
  final List<String> stableRowIdentities;
  final List<String> stableAssetIdentities;
  final int presentationDigest;

  int get totalMinor => amount.totalMinor;
  int get entryCount => count.entryCount;
  bool get loading => false;
  bool get stale => false;
  Object? get error => null;
}

@immutable
final class DashboardPreparedDeck {
  const DashboardPreparedDeck._({
    required this.key,
    required this.parentScope,
    required this.parentFrame,
    required this.semanticCatalog,
    required this.frames,
    required this.contentDigest,
    required this.generation,
    required this.preparedAt,
    required this.buildMetrics,
  });

  factory DashboardPreparedDeck.complete({
    required DashboardPreparedDeckKey key,
    required CurrentLedgerQueryScope parentScope,
    required DashboardPreparedFrame parentFrame,
    required DashboardSemanticCatalog semanticCatalog,
    required Map<LedgerQueryKey, DashboardPreparedFrame> frames,
    required int contentDigest,
    required int generation,
    required DateTime preparedAt,
    required DashboardPreparedDeckBuildMetrics buildMetrics,
  }) {
    if (key.coreRevision <= 0 ||
        key.parentQueryKey != parentScope.key ||
        key.parentQueryKey != semanticCatalog.parentScope.key ||
        key.childKind != semanticCatalog.childKind ||
        key.semanticWindowIdentity != semanticCatalog.windowIdentity ||
        parentFrame.queryKey != parentScope.key ||
        parentFrame.coreRevision != key.coreRevision ||
        frames.length != semanticCatalog.length) {
      throw ArgumentError('Prepared deck identity or completeness mismatch.');
    }
    for (final entry in semanticCatalog.entries) {
      final frame = frames[entry.queryKey];
      if (frame == null ||
          frame.queryKey != entry.queryKey ||
          frame.parentQueryKey != parentScope.key ||
          frame.coreRevision != key.coreRevision) {
        throw ArgumentError(
          'Prepared deck has no exact frame for ${entry.queryKey.value}.',
        );
      }
    }
    return DashboardPreparedDeck._(
      key: key,
      parentScope: parentScope,
      parentFrame: parentFrame,
      semanticCatalog: semanticCatalog,
      frames: Map<LedgerQueryKey, DashboardPreparedFrame>.unmodifiable(frames),
      contentDigest: contentDigest,
      generation: generation,
      preparedAt: preparedAt.toUtc(),
      buildMetrics: buildMetrics,
    );
  }

  final DashboardPreparedDeckKey key;
  final CurrentLedgerQueryScope parentScope;
  final DashboardPreparedFrame parentFrame;
  final DashboardSemanticCatalog semanticCatalog;
  final Map<LedgerQueryKey, DashboardPreparedFrame> frames;
  final int contentDigest;
  final int generation;
  final DateTime preparedAt;
  final DashboardPreparedDeckBuildMetrics buildMetrics;

  bool get isComplete => true;
  int get coreRevision => key.coreRevision;
  int get pageSize => key.pageSize;
  int get childCount => semanticCatalog.length;

  DashboardPreparedFrame frameFor(LedgerQueryKey queryKey) {
    final frame = frames[queryKey];
    if (frame == null) {
      throw StateError('Prepared deck has no frame for ${queryKey.value}.');
    }
    return frame;
  }
}
