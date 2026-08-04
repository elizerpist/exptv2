import 'package:flutter/foundation.dart';

import '../query/application/dashboard_parent_display_bundle.dart';
import '../query/data/dashboard_bounded_cache.dart';
import '../query/data/dashboard_child_preview_bundle.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/time_child_summary.dart';

/// Semantic identity of one reusable parent presentation bundle.
///
/// Revisions belong to the entry so a lookup can diagnose stale data instead
/// of retaining multiple versions of the same parent. Motion/controller state
/// deliberately cannot influence this key.
@immutable
class DashboardParentBundleKey {
  const DashboardParentBundleKey({
    required this.parentQueryKey,
    required this.childPeriod,
    required this.previewPageSize,
  }) : assert(previewPageSize > 0);

  final LedgerQueryKey parentQueryKey;
  final TimeChildPeriod childPeriod;
  final int previewPageSize;

  @override
  bool operator ==(Object other) =>
      other is DashboardParentBundleKey &&
      other.parentQueryKey == parentQueryKey &&
      other.childPeriod == childPeriod &&
      other.previewPageSize == previewPageSize;

  @override
  int get hashCode => Object.hash(parentQueryKey, childPeriod, previewPageSize);

  @override
  String toString() =>
      '${parentQueryKey.value}|child:${childPeriod.name}|page:$previewPageSize';
}

/// One atomically reusable parent summary and complete aggregate child deck.
@immutable
class DashboardParentBundleEntry {
  const DashboardParentBundleEntry({
    required this.key,
    required this.displayBundle,
    required this.childSummaryIndex,
    required this.estimatedWeight,
    required this.estimatedBytes,
    this.isFresh = true,
  });

  factory DashboardParentBundleEntry.fromDisplayBundle(
    DashboardParentDisplayBundle displayBundle, {
    bool isFresh = true,
  }) {
    final childBundle = displayBundle.childPreviewBundle;
    if (childBundle == null) {
      throw ArgumentError.value(
        displayBundle,
        'displayBundle',
        'A canonical parent bundle requires a complete child preview deck.',
      );
    }
    final index = _indexFromBundle(childBundle);
    final previewRows = childBundle.childrenByQueryKey.values.fold<int>(
      0,
      (total, child) => total + child.result.entries.length,
    );
    return DashboardParentBundleEntry(
      key: DashboardParentBundleKey(
        parentQueryKey: childBundle.parentQueryKey,
        childPeriod: childBundle.childPeriod,
        previewPageSize: childBundle.previewPageSize,
      ),
      displayBundle: displayBundle,
      childSummaryIndex: index,
      estimatedWeight: childBundle.childrenByQueryKey.length + previewRows,
      estimatedBytes:
          256 + childBundle.childrenByQueryKey.length * 96 + previewRows * 160,
      isFresh: isFresh,
    );
  }

  final DashboardParentBundleKey key;
  final DashboardParentDisplayBundle displayBundle;
  final DashboardTimeChildSummaryIndex childSummaryIndex;
  final int estimatedWeight;
  final int estimatedBytes;
  final bool isFresh;

  int get coreRevision => childSummaryIndex.coreRevision;

  bool get isComplete =>
      displayBundle.isComplete &&
      displayBundle.parentQueryKey == key.parentQueryKey &&
      displayBundle.childPreviewBundle?.childPeriod == key.childPeriod &&
      displayBundle.childPreviewBundle?.previewPageSize ==
          key.previewPageSize &&
      childSummaryIndex.isComplete &&
      childSummaryIndex.parentQueryKey == key.parentQueryKey.value &&
      childSummaryIndex.childPeriod == key.childPeriod &&
      displayBundle.parentSnapshot.coreRevision == coreRevision;

  DashboardParentBundleEntry copyWith({bool? isFresh}) =>
      DashboardParentBundleEntry(
        key: key,
        displayBundle: displayBundle,
        childSummaryIndex: childSummaryIndex,
        estimatedWeight: estimatedWeight,
        estimatedBytes: estimatedBytes,
        isFresh: isFresh ?? this.isFresh,
      );

  static DashboardTimeChildSummaryIndex _indexFromBundle(
    DashboardChildPreviewBundle bundle,
  ) {
    final values = <String, DashboardTimeChildSummary>{};
    for (final child in bundle.childrenByQueryKey.values) {
      values[child.childPeriodValue] = DashboardTimeChildSummary(
        childPeriodValue: child.childPeriodValue,
        childQueryKey: child.queryKey.value,
        totalMinor: child.result.totalMinor,
        entryCount: child.result.entryCount,
      );
    }
    return DashboardTimeChildSummaryIndex(
      parentQueryKey: bundle.parentQueryKey.value,
      direction: bundle.direction,
      childPeriod: bundle.childPeriod,
      coreRevision: bundle.coreRevision,
      isComplete: true,
      values: values,
    );
  }
}

enum DashboardParentBundleMissReason {
  none,
  absent,
  incomplete,
  stale,
  revisionMismatch,
}

@immutable
class DashboardParentBundleLookup {
  const DashboardParentBundleLookup({
    required this.entry,
    required this.missReason,
    this.storedRevision,
  });

  final DashboardParentBundleEntry? entry;
  final DashboardParentBundleMissReason missReason;
  final int? storedRevision;

  bool get cacheHit => entry != null;
}

/// Single bounded owner for reusable parent summary + child deck payloads.
///
/// The visible current parent is pinned independently. Every other entry uses
/// the shared byte-aware LRU so retaining the current interaction payload does
/// not require raising an unbounded cache limit.
class DashboardParentBundleRegistry {
  DashboardParentBundleRegistry({
    int adjacentCapacity = 4,
    int maxAdjacentBytes = 2 * 1024 * 1024,
  }) : _adjacent = DashboardBoundedCache(
         capacity: adjacentCapacity,
         maxBytes: maxAdjacentBytes,
         weightOf: (entry) => entry.estimatedWeight,
         byteWeightOf: (entry) => entry.estimatedBytes,
       );

  final DashboardBoundedCache<
    DashboardParentBundleKey,
    DashboardParentBundleEntry
  >
  _adjacent;
  DashboardParentBundleKey? _pinnedKey;
  DashboardParentBundleEntry? _pinnedEntry;
  int _hitCount = 0;
  int _missCount = 0;

  DashboardParentBundleKey? get pinnedKey => _pinnedKey;
  int get hitCount => _hitCount;
  int get missCount => _missCount;
  int get evictionCount => _adjacent.evictionCount;
  int get estimatedWeight =>
      _adjacent.estimatedWeight + (_pinnedEntry?.estimatedWeight ?? 0);
  int get adjacentEstimatedBytes => _adjacent.estimatedBytes;
  int get estimatedBytes =>
      adjacentEstimatedBytes + (_pinnedEntry?.estimatedBytes ?? 0);

  bool put(DashboardParentBundleEntry entry, {bool pinCurrent = false}) {
    if (!entry.isComplete) return false;
    if (pinCurrent) {
      _replacePinned(entry);
      return true;
    }
    if (_pinnedKey == entry.key) {
      _pinnedEntry = entry;
      return true;
    }
    _adjacent.put(entry.key, entry);
    return _adjacent.peek(entry.key) != null;
  }

  DashboardParentBundleLookup lookup(
    DashboardParentBundleKey key, {
    int? expectedRevision,
  }) {
    final candidate = _pinnedKey == key ? _pinnedEntry : _adjacent.get(key);
    if (candidate == null) {
      _missCount += 1;
      return const DashboardParentBundleLookup(
        entry: null,
        missReason: DashboardParentBundleMissReason.absent,
      );
    }
    if (!candidate.isComplete) {
      _missCount += 1;
      return DashboardParentBundleLookup(
        entry: null,
        missReason: DashboardParentBundleMissReason.incomplete,
        storedRevision: candidate.coreRevision,
      );
    }
    if (!candidate.isFresh) {
      _missCount += 1;
      return DashboardParentBundleLookup(
        entry: null,
        missReason: DashboardParentBundleMissReason.stale,
        storedRevision: candidate.coreRevision,
      );
    }
    if (expectedRevision != null &&
        candidate.coreRevision != expectedRevision) {
      _missCount += 1;
      return DashboardParentBundleLookup(
        entry: null,
        missReason: DashboardParentBundleMissReason.revisionMismatch,
        storedRevision: candidate.coreRevision,
      );
    }
    _hitCount += 1;
    return DashboardParentBundleLookup(
      entry: candidate,
      missReason: DashboardParentBundleMissReason.none,
      storedRevision: candidate.coreRevision,
    );
  }

  bool pinCurrent(DashboardParentBundleKey key) {
    if (_pinnedKey == key) return _pinnedEntry != null;
    final entry = _adjacent.remove(key);
    if (entry == null) return false;
    _replacePinned(entry);
    return true;
  }

  bool markStale(DashboardParentBundleKey key) {
    if (_pinnedKey == key) {
      final entry = _pinnedEntry;
      if (entry == null) return false;
      _pinnedEntry = entry.copyWith(isFresh: false);
      return true;
    }
    final entry = _adjacent.remove(key);
    if (entry == null) return false;
    _adjacent.put(key, entry.copyWith(isFresh: false));
    return true;
  }

  void clear() {
    _pinnedKey = null;
    _pinnedEntry = null;
    _adjacent.clear();
  }

  void _replacePinned(DashboardParentBundleEntry entry) {
    final previousKey = _pinnedKey;
    final previousEntry = _pinnedEntry;
    if (previousKey != null &&
        previousEntry != null &&
        previousKey != entry.key) {
      _adjacent.put(previousKey, previousEntry);
    }
    _adjacent.remove(entry.key);
    _pinnedKey = entry.key;
    _pinnedEntry = entry;
  }
}
