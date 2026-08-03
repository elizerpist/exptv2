import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/dashboard_ledger_repository.dart';
import '../domain/current_ledger_query_scope.dart';

/// The immutable value rendered by every dashboard consumer for one query.
///
/// Amount, count and rows intentionally live in the same object. A consumer
/// may select individual fields, but it cannot accidentally combine fields
/// from two query generations.
@immutable
class DashboardPresentationSnapshot {
  DashboardPresentationSnapshot({
    required this.queryKey,
    required this.generation,
    this.scope,
    this.coreRevision,
    this.totalMinor,
    this.entryCount,
    List<DashboardLedgerEntry> entries = const <DashboardLedgerEntry>[],
    this.isLoading = false,
    this.isStale = false,
    this.hasError = false,
    this.isPreview = false,
  }) : entries = List.unmodifiable(entries),
       assert(scope == null || scope.key == queryKey),
       assert((totalMinor == null) == (entryCount == null));

  factory DashboardPresentationSnapshot.fromResult({
    required CurrentLedgerQueryScope scope,
    required int generation,
    required DashboardLedgerResult result,
  }) {
    return DashboardPresentationSnapshot(
      queryKey: scope.key,
      generation: generation,
      scope: scope,
      coreRevision: result.coreRevision,
      totalMinor: result.totalMinor,
      entryCount: result.entryCount,
      entries: result.entries,
    );
  }

  final LedgerQueryKey queryKey;
  final int generation;
  final CurrentLedgerQueryScope? scope;
  final int? coreRevision;
  final int? totalMinor;
  final int? entryCount;
  final List<DashboardLedgerEntry> entries;
  final bool isLoading;
  final bool isStale;
  final bool hasError;
  final bool isPreview;

  bool get hasValue => totalMinor != null && entryCount != null;

  /// This comparison deliberately excludes generation. A preview and its
  /// committed counterpart can have different provenance but one visual
  /// value; promoting that pair must not rebind the list or restart animation.
  bool hasSameVisualValue(DashboardPresentationSnapshot other) {
    if (queryKey != other.queryKey ||
        coreRevision != other.coreRevision ||
        totalMinor != other.totalMinor ||
        entryCount != other.entryCount ||
        isLoading != other.isLoading ||
        isStale != other.isStale ||
        hasError != other.hasError ||
        entries.length != other.entries.length) {
      return false;
    }
    for (var index = 0; index < entries.length; index += 1) {
      if (entries[index].id != other.entries[index].id) return false;
    }
    return true;
  }
}

/// Single bounded owner of dashboard presentation snapshots.
///
/// The store is intentionally independent of scroll physics. The rail may
/// select a cached snapshot synchronously, while the query coordinator may
/// publish a fresh snapshot later. Both lanes use the same key space.
class DashboardPresentationStore extends ChangeNotifier {
  DashboardPresentationStore({int capacity = 48})
    : assert(capacity > 0),
      _capacity = capacity;

  final int _capacity;
  final LinkedHashMap<LedgerQueryKey, DashboardPresentationSnapshot>
  _snapshots = LinkedHashMap<LedgerQueryKey, DashboardPresentationSnapshot>();

  DashboardPresentationSnapshot? _activeSnapshot;
  int _previewSelectionCount = 0;
  int _committedSelectionCount = 0;
  int _repositoryReadCountDuringMotion = 0;
  int _nativeCallCountDuringMotion = 0;
  int _watchSubscribeCountDuringMotion = 0;
  int _watchCancelCountDuringMotion = 0;
  int _programmaticScrollCountDuringMotion = 0;
  int _previewPromotionCount = 0;
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;

  DashboardPresentationSnapshot? get activeSnapshot => _activeSnapshot;
  int get previewSelectionCount => _previewSelectionCount;
  int get committedSelectionCount => _committedSelectionCount;
  int get repositoryReadCountDuringMotion => _repositoryReadCountDuringMotion;
  int get nativeCallCountDuringMotion => _nativeCallCountDuringMotion;
  int get watchSubscribeCountDuringMotion => _watchSubscribeCountDuringMotion;
  int get watchCancelCountDuringMotion => _watchCancelCountDuringMotion;
  int get programmaticScrollCountDuringMotion =>
      _programmaticScrollCountDuringMotion;
  int get previewPromotionCount => _previewPromotionCount;
  int get cacheHitCount => _cacheHitCount;
  int get cacheMissCount => _cacheMissCount;

  DashboardPresentationSnapshot? snapshotFor(LedgerQueryKey key) {
    final snapshot = _snapshots[key];
    if (snapshot != null) {
      _cacheHitCount += 1;
      _snapshots
        ..remove(key)
        ..[key] = snapshot;
    } else {
      _cacheMissCount += 1;
    }
    return snapshot;
  }

  /// Stores a snapshot and optionally makes it the active rendered value.
  /// Re-publishing the same visual value is a no-op for listeners.
  bool publish(DashboardPresentationSnapshot snapshot, {bool activate = true}) {
    _remember(snapshot);
    if (!activate) return false;
    // A parent repository emission can arrive while a child preview is
    // visibly centered. It is valid to cache that parent value, but it must
    // not replace the child presentation for one frame and put amount/count
    // out of sync with the rail. The child lane explicitly promotes or
    // replaces the active snapshot when its own scope changes.
    final active = _activeSnapshot;
    if (active != null &&
        active.isPreview &&
        !snapshot.isPreview &&
        active.queryKey != snapshot.queryKey) {
      return false;
    }
    if (_activeSnapshot?.hasSameVisualValue(snapshot) ?? false) {
      _activeSnapshot = snapshot;
      return false;
    }
    _activeSnapshot = snapshot;
    notifyListeners();
    return true;
  }

  /// Promotes a preview snapshot to committed presentation without a visual
  /// rebind when its query/revision/content are identical.
  bool promote(DashboardPresentationSnapshot snapshot) {
    if (_activeSnapshot?.hasSameVisualValue(snapshot) ?? false) {
      _activeSnapshot = snapshot;
      _remember(snapshot);
      _previewPromotionCount += 1;
      return false;
    }
    return publish(snapshot);
  }

  void recordPreviewSelection() => _previewSelectionCount += 1;
  void recordCommittedSelection() => _committedSelectionCount += 1;

  void recordRepositoryReadDuringMotion() =>
      _repositoryReadCountDuringMotion += 1;
  void recordNativeCallDuringMotion() => _nativeCallCountDuringMotion += 1;
  void recordWatchSubscribeDuringMotion() =>
      _watchSubscribeCountDuringMotion += 1;
  void recordWatchCancelDuringMotion() => _watchCancelCountDuringMotion += 1;
  void recordProgrammaticScrollDuringMotion() =>
      _programmaticScrollCountDuringMotion += 1;

  void _remember(DashboardPresentationSnapshot snapshot) {
    _snapshots
      ..remove(snapshot.queryKey)
      ..[snapshot.queryKey] = snapshot;
    while (_snapshots.length > _capacity) {
      _snapshots.remove(_snapshots.keys.first);
    }
  }

  @override
  void dispose() {
    _snapshots.clear();
    _activeSnapshot = null;
    super.dispose();
  }
}
