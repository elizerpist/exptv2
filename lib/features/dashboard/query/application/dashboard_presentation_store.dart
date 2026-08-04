import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../data/dashboard_ledger_repository.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/dashboard_visible_presentation_target.dart';
import 'dashboard_presentation_diagnostics.dart';

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
    this.nextCursor,
    this.isLoading = false,
    this.isStale = false,
    this.hasError = false,
    DashboardPresentationMode presentationMode =
        DashboardPresentationMode.committed,
    this.dataOrigin = DashboardDataOrigin.memoryCache,
    int? logGroupCount,
    int? contentDigest,
    bool? isPreview,
    this.logViewportState,
  }) : entries = List.unmodifiable(entries),
       presentationMode = isPreview == null
           ? presentationMode
           : isPreview
           ? DashboardPresentationMode.preview
           : DashboardPresentationMode.committed,
       logGroupCount = logGroupCount ?? _countLogGroups(entries),
       contentDigest =
           contentDigest ??
           _contentDigest(coreRevision, totalMinor, entryCount, entries),
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
      nextCursor: result.nextCursor,
      dataOrigin: DashboardDataOrigin.freshQuery,
    );
  }

  final LedgerQueryKey queryKey;
  final int generation;
  final CurrentLedgerQueryScope? scope;
  final int? coreRevision;
  final int? totalMinor;
  final int? entryCount;
  final List<DashboardLedgerEntry> entries;
  final Map<String, Object?>? nextCursor;
  final bool isLoading;
  final bool isStale;
  final bool hasError;
  final DashboardPresentationMode presentationMode;
  final DashboardDataOrigin dataOrigin;
  final int logGroupCount;
  final int contentDigest;
  final DashboardLogViewportState? logViewportState;

  bool get isPreview => presentationMode == DashboardPresentationMode.preview;

  bool get hasValue => totalMinor != null && entryCount != null;

  DashboardPresentationSnapshot copyWith({
    LedgerQueryKey? queryKey,
    int? generation,
    CurrentLedgerQueryScope? scope,
    int? coreRevision,
    int? totalMinor,
    int? entryCount,
    List<DashboardLedgerEntry>? entries,
    Map<String, Object?>? nextCursor,
    bool clearNextCursor = false,
    bool? isLoading,
    bool? isStale,
    bool? hasError,
    DashboardPresentationMode? presentationMode,
    DashboardDataOrigin? dataOrigin,
    int? logGroupCount,
    int? contentDigest,
    bool? isPreview,
    DashboardLogViewportState? logViewportState,
    bool clearLogViewportState = false,
  }) => DashboardPresentationSnapshot(
    queryKey: queryKey ?? this.queryKey,
    generation: generation ?? this.generation,
    scope: scope ?? this.scope,
    coreRevision: coreRevision ?? this.coreRevision,
    totalMinor: totalMinor ?? this.totalMinor,
    entryCount: entryCount ?? this.entryCount,
    entries: entries ?? this.entries,
    nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
    isLoading: isLoading ?? this.isLoading,
    isStale: isStale ?? this.isStale,
    hasError: hasError ?? this.hasError,
    presentationMode: presentationMode ?? this.presentationMode,
    dataOrigin: dataOrigin ?? this.dataOrigin,
    logGroupCount: logGroupCount ?? this.logGroupCount,
    contentDigest: contentDigest ?? this.contentDigest,
    isPreview: isPreview,
    logViewportState:
        clearLogViewportState || (entries != null && logViewportState == null)
        ? null
        : logViewportState ?? this.logViewportState,
  );

  static int _countLogGroups(List<DashboardLedgerEntry> entries) =>
      entries.map((entry) => entry.bookedLocalEpochDay).toSet().length;

  static int _contentDigest(
    int? coreRevision,
    int? totalMinor,
    int? entryCount,
    List<DashboardLedgerEntry> entries,
  ) => Object.hash(
    coreRevision,
    totalMinor,
    entryCount,
    Object.hashAll(entries.map((entry) => entry.id)),
  );

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
      if (!_sameEntry(entries[index], other.entries[index])) return false;
    }
    return true;
  }

  static bool _sameEntry(
    DashboardLedgerEntry left,
    DashboardLedgerEntry right,
  ) =>
      left.id == right.id &&
      left.partnerId == right.partnerId &&
      left.categoryId == right.categoryId &&
      left.direction == right.direction &&
      left.amountMinor == right.amountMinor &&
      left.bookedLocalEpochDay == right.bookedLocalEpochDay &&
      left.bookedLocalTimeMinutes == right.bookedLocalTimeMinutes &&
      left.note == right.note &&
      left.occurredAtUtcMs == right.occurredAtUtcMs &&
      left.partnerDisplayName == right.partnerDisplayName &&
      left.categoryDisplayName == right.categoryDisplayName &&
      left.categoryColorId == right.categoryColorId &&
      left.categoryIconId == right.categoryIconId &&
      left.assignmentMode == right.assignmentMode &&
      left.originKind == right.originKind;
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
  int _settleVisualRebindCount = 0;
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;
  int _visiblePresentationPublishCount = 0;
  int _stalePlaceholderPublishCount = 0;
  int _crossKeyPublishAttemptCount = 0;
  int _rejectedChildCallbackCount = 0;
  int _lateCommittedResultCachedCount = 0;
  int _lateCommittedResultVisibleRejectedCount = 0;
  final Set<VoidCallback> _metadataListeners = <VoidCallback>{};

  DashboardVisiblePresentationTarget? _visibleTarget;

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
  int get settleVisualRebindCount => _settleVisualRebindCount;
  int get cacheHitCount => _cacheHitCount;
  int get cacheMissCount => _cacheMissCount;
  int get visiblePresentationPublishCount => _visiblePresentationPublishCount;
  int get stalePlaceholderPublishCount => _stalePlaceholderPublishCount;
  int get crossKeyPublishAttemptCount => _crossKeyPublishAttemptCount;
  int get rejectedChildCallbackCount => _rejectedChildCallbackCount;
  int get lateCommittedResultCachedCount => _lateCommittedResultCachedCount;
  int get lateCommittedResultVisibleRejectedCount =>
      _lateCommittedResultVisibleRejectedCount;
  DashboardVisiblePresentationTarget? get visibleTarget => _visibleTarget;

  void addMetadataListener(VoidCallback listener) {
    _metadataListeners.add(listener);
  }

  void removeMetadataListener(VoidCallback listener) {
    _metadataListeners.remove(listener);
  }

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

  /// Reads an already cached snapshot without affecting LRU diagnostics. It
  /// is used when a narrow metrics selector republishes the same query key so
  /// that it cannot accidentally discard detailed rows published by the
  /// query coordinator.
  DashboardPresentationSnapshot? peekSnapshot(LedgerQueryKey key) =>
      _snapshots[key];

  /// Selects the one snapshot permitted by the semantic dashboard target.
  ///
  /// A cache miss deliberately retains the complete outgoing snapshot. It
  /// never publishes a null/loading placeholder that could mix with the new
  /// title, amount or count while a committed read is still pending.
  bool setVisibleTarget(DashboardVisiblePresentationTarget target) {
    _visibleTarget = target;
    final candidate = _snapshots[target.expectedVisibleQueryKey];
    if (candidate == null || !_isValidForTarget(candidate, target)) {
      return false;
    }
    return _activate(candidate);
  }

  /// Stores a snapshot and optionally makes it the active rendered value.
  /// Re-publishing the same visual value is a no-op for listeners.
  bool publish(DashboardPresentationSnapshot snapshot, {bool activate = true}) {
    final previous = _snapshots[snapshot.queryKey];
    if (activate && _isFresh(previous) && _isPlaceholder(snapshot)) {
      _stalePlaceholderPublishCount += 1;
      return false;
    }
    if (previous != null &&
        previous.entries.isNotEmpty &&
        snapshot.entries.isEmpty) {
      snapshot = snapshot.copyWith(entries: previous.entries);
    }
    _remember(snapshot);
    if (!activate) return false;
    final target = _visibleTarget;
    if (target != null &&
        snapshot.queryKey == target.expectedVisibleQueryKey &&
        _isPlaceholder(snapshot) &&
        _isFresh(_activeSnapshot) &&
        _activeSnapshot!.queryKey != snapshot.queryKey) {
      // A cold parent/year transition keeps the complete outgoing snapshot
      // visible until the new same-key result arrives. Activating this
      // placeholder would mix the new navigation label with a null amount,
      // count and rows, or briefly expose a dash.
      _stalePlaceholderPublishCount += 1;
      return false;
    }
    if (target != null && snapshot.queryKey != target.expectedVisibleQueryKey) {
      _crossKeyPublishAttemptCount += 1;
      if (snapshot.isPreview) _rejectedChildCallbackCount += 1;
      return false;
    }
    if (target == null &&
        _activeSnapshot != null &&
        _activeSnapshot!.isPreview &&
        _activeSnapshot!.queryKey != snapshot.queryKey &&
        !snapshot.isPreview) {
      return false;
    }
    return _activate(snapshot);
  }

  /// Stores a committed result even while motion has selected another
  /// visible target. A stale result is useful for a later cache hit, but it may
  /// never replace the currently displayed preview.
  bool publishCommittedResult(
    DashboardPresentationSnapshot snapshot, {
    required int interactionEpoch,
  }) {
    final target = _visibleTarget;
    if (target != null &&
        (interactionEpoch != target.presentationEpoch ||
            snapshot.queryKey != target.expectedVisibleQueryKey)) {
      _remember(snapshot);
      _lateCommittedResultCachedCount += 1;
      _lateCommittedResultVisibleRejectedCount += 1;
      return false;
    }
    final displayed = _activeSnapshot;
    if (displayed != null &&
        displayed.queryKey == snapshot.queryKey &&
        displayed.coreRevision != null &&
        snapshot.coreRevision != null &&
        snapshot.coreRevision! < displayed.coreRevision!) {
      _remember(snapshot);
      _lateCommittedResultCachedCount += 1;
      _lateCommittedResultVisibleRejectedCount += 1;
      return false;
    }
    return publish(snapshot);
  }

  /// Promotes a preview snapshot to committed presentation without a visual
  /// rebind when its query/revision/content are identical.
  bool promote(DashboardPresentationSnapshot snapshot) {
    if (_activeSnapshot?.hasSameVisualValue(snapshot) ?? false) {
      _activeSnapshot = snapshot;
      _remember(snapshot);
      _previewPromotionCount += 1;
      for (final listener in List<VoidCallback>.of(_metadataListeners)) {
        listener();
      }
      return false;
    }
    _settleVisualRebindCount += 1;
    return publish(snapshot);
  }

  bool _activate(DashboardPresentationSnapshot snapshot) {
    if (_activeSnapshot?.hasSameVisualValue(snapshot) ?? false) {
      _activeSnapshot = snapshot;
      return false;
    }
    _activeSnapshot = snapshot;
    _visiblePresentationPublishCount += 1;
    notifyListeners();
    return true;
  }

  bool _isValidForTarget(
    DashboardPresentationSnapshot snapshot,
    DashboardVisiblePresentationTarget target,
  ) {
    if (snapshot.queryKey != target.expectedVisibleQueryKey) return false;
    if (snapshot.scope != null &&
        snapshot.scope!.direction != target.direction) {
      return false;
    }
    return !_isPlaceholder(snapshot);
  }

  static bool _isFresh(DashboardPresentationSnapshot? snapshot) =>
      snapshot != null &&
      snapshot.hasValue &&
      !snapshot.isLoading &&
      !snapshot.isStale &&
      !snapshot.hasError;

  static bool _isPlaceholder(DashboardPresentationSnapshot snapshot) =>
      snapshot.isLoading ||
      snapshot.isStale ||
      snapshot.hasError ||
      !snapshot.hasValue;

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
    _visibleTarget = null;
    _metadataListeners.clear();
    super.dispose();
  }
}
