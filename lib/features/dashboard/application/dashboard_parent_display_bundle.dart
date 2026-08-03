import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../logbox/application/dashboard_log_view_models.dart';
import '../logbox/domain/dashboard_log_models.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../time_navigation/domain/time_plane.dart';

/// Precomputed first-page content for one preview child.
///
/// The instance is non-null for both populated and empty children. A missing
/// map key is therefore the only cache miss representation.
@immutable
class DashboardLogPreviewSnapshot {
  DashboardLogPreviewSnapshot.populated({
    required this.scope,
    required this.coreRevision,
    required this.totalMinor,
    required this.entryCount,
    required List<DashboardDayLogGroup> groups,
  }) : groups = List<DashboardDayLogGroup>.unmodifiable(groups),
       viewGroups = List<DashboardDayLogGroupViewModel>.unmodifiable(
         DashboardLogViewModelProjector.presentGroups(groups),
       ),
       isExplicitEmpty = false,
       assert(entryCount >= 0),
       assert(scope.key.value.isNotEmpty);

  const DashboardLogPreviewSnapshot.empty({
    required this.scope,
    required this.coreRevision,
  }) : totalMinor = 0,
       entryCount = 0,
       groups = const <DashboardDayLogGroup>[],
       viewGroups = const <DashboardDayLogGroupViewModel>[],
       isExplicitEmpty = true;

  final CurrentLedgerQueryScope scope;
  final int coreRevision;
  final int totalMinor;
  final int entryCount;
  final List<DashboardDayLogGroup> groups;
  final List<DashboardDayLogGroupViewModel> viewGroups;
  final bool isExplicitEmpty;

  String get queryKey => scope.key.value;
  int get rowCount =>
      groups.fold<int>(0, (count, group) => count + group.rows.length);

  /// Stable semantic content fingerprint used by promotion. It is not a
  /// cryptographic hash; it prevents equal row IDs with changed display data
  /// from being promoted as visually identical.
  int get contentDigest => Object.hashAll(<Object?>[
    queryKey,
    coreRevision,
    totalMinor,
    entryCount,
    for (final group in groups) ...<Object?>[
      group.localDate,
      for (final row in group.rows) ...<Object?>[
        row.id,
        row.amountMinor,
        row.bookedLocalTimeMinutes,
        row.partnerDisplayName,
        row.categoryDisplayName,
        row.categoryColorId,
        row.categoryIconId,
        row.note,
      ],
    ],
  ]);
}

@immutable
class DashboardChildPreviewDeck {
  DashboardChildPreviewDeck._(Map<String, DashboardLogPreviewSnapshot> source)
    : snapshots = Map<String, DashboardLogPreviewSnapshot>.unmodifiable(source);

  final Map<String, DashboardLogPreviewSnapshot> snapshots;

  DashboardLogPreviewSnapshot? snapshotFor(CurrentLedgerQueryScope scope) =>
      snapshots[scope.key.value];

  int get rowCount => snapshots.values.fold<int>(
    0,
    (count, snapshot) => count + snapshot.rowCount,
  );
}

@immutable
class DashboardParentDisplayBundleKey {
  const DashboardParentDisplayBundleKey({
    required this.parentQueryKey,
    required this.plane,
    required this.coreRevision,
  });

  final String parentQueryKey;
  final TimePlane plane;
  final int coreRevision;

  @override
  bool operator ==(Object other) =>
      other is DashboardParentDisplayBundleKey &&
      parentQueryKey == other.parentQueryKey &&
      plane == other.plane &&
      coreRevision == other.coreRevision;

  @override
  int get hashCode => Object.hash(parentQueryKey, plane, coreRevision);
}

/// Complete, immutable preview data for one parent scope.
@immutable
class DashboardParentDisplayBundle {
  const DashboardParentDisplayBundle._({
    required this.key,
    required this.parentScope,
    required this.childDeck,
    required this.isComplete,
  });

  factory DashboardParentDisplayBundle.completeFinite({
    required CurrentLedgerQueryScope parentScope,
    required TimePlane plane,
    required int coreRevision,
    required Iterable<CurrentLedgerQueryScope> expectedChildren,
    required Iterable<DashboardLogPreviewSnapshot> snapshots,
  }) {
    final expected = <String, CurrentLedgerQueryScope>{
      for (final child in expectedChildren) child.key.value: child,
    };
    final completed = <String, DashboardLogPreviewSnapshot>{};
    for (final snapshot in snapshots) {
      if (!expected.containsKey(snapshot.queryKey)) {
        throw ArgumentError.value(
          snapshot.queryKey,
          'snapshots',
          'Preview child does not belong to the finite parent deck.',
        );
      }
      if (snapshot.coreRevision != coreRevision) {
        throw ArgumentError.value(
          snapshot.coreRevision,
          'snapshots',
          'Preview child revision does not match its parent bundle.',
        );
      }
      if (completed.containsKey(snapshot.queryKey)) {
        throw ArgumentError.value(
          snapshot.queryKey,
          'snapshots',
          'Duplicate preview child key.',
        );
      }
      completed[snapshot.queryKey] = snapshot;
    }
    for (final child in expected.values) {
      completed.putIfAbsent(
        child.key.value,
        () => DashboardLogPreviewSnapshot.empty(
          scope: child,
          coreRevision: coreRevision,
        ),
      );
    }
    if (completed.length != expected.length) {
      throw StateError(
        'Finite preview deck must contain every expected child.',
      );
    }
    return DashboardParentDisplayBundle._(
      key: DashboardParentDisplayBundleKey(
        parentQueryKey: parentScope.key.value,
        plane: plane,
        coreRevision: coreRevision,
      ),
      parentScope: parentScope,
      childDeck: DashboardChildPreviewDeck._(completed),
      isComplete: true,
    );
  }

  final DashboardParentDisplayBundleKey key;
  final CurrentLedgerQueryScope parentScope;
  final DashboardChildPreviewDeck childDeck;
  final bool isComplete;

  int get rowCount => childDeck.rowCount;
}

/// Whole-bundle LRU. Pinning protects complete active decks, never individual
/// child entries, so the finite preview completeness invariant survives cache
/// pressure.
class DashboardParentDisplayBundleCache {
  DashboardParentDisplayBundleCache({required this.capacity})
    : assert(capacity > 0);

  final int capacity;
  final LinkedHashMap<
    DashboardParentDisplayBundleKey,
    DashboardParentDisplayBundle
  >
  _bundles =
      LinkedHashMap<
        DashboardParentDisplayBundleKey,
        DashboardParentDisplayBundle
      >();
  final Set<DashboardParentDisplayBundleKey> _pinned =
      <DashboardParentDisplayBundleKey>{};

  DashboardParentDisplayBundle? lookup(DashboardParentDisplayBundleKey key) {
    final bundle = _bundles.remove(key);
    if (bundle == null) return null;
    _bundles[key] = bundle;
    return bundle;
  }

  bool contains(DashboardParentDisplayBundleKey key) =>
      _bundles.containsKey(key);

  void put(DashboardParentDisplayBundle bundle) {
    if (!bundle.isComplete) {
      throw ArgumentError.value(bundle, 'bundle', 'Only complete decks cache.');
    }
    _bundles
      ..remove(bundle.key)
      ..[bundle.key] = bundle;
    _evictWholeBundles();
  }

  void pin(DashboardParentDisplayBundleKey key) {
    _pinned.add(key);
  }

  void unpin(DashboardParentDisplayBundleKey key) {
    _pinned.remove(key);
    _evictWholeBundles();
  }

  void _evictWholeBundles() {
    while (_bundles.length > capacity) {
      final victim = _bundles.keys.firstWhere(
        (key) => !_pinned.contains(key),
        orElse: () => _bundles.keys.first,
      );
      if (_pinned.contains(victim)) return;
      _bundles.remove(victim);
    }
  }
}
