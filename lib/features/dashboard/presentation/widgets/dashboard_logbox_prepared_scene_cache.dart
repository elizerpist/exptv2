import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../logbox/application/dashboard_logbox_scene_window.dart';
import 'dashboard_logbox_text_layout_cache.dart';

/// Exact-width, bounded owner of every paragraph needed by rail-reachable
/// LogBox preview scenes.
///
/// A structural rotation constructs its next bank privately, then swaps it
/// atomically. The active immutable scenes remain paintable while cancellable
/// cache maintenance yields between bounded slices; navigation and input never
/// wait for that maintenance.
final class DashboardLogBoxPreparedSceneCache extends ChangeNotifier {
  DashboardLogBoxPreparedSceneCache({
    this.maximumPinnedRows = 8192,
    this.maximumRetainedScenes = 32768,
    this.maximumRetainedCandidateBanks = 6,
    this.maximumRetainedCandidateRows = 2048,
    this.maximumRetainedCandidateBytes = 16 * 1024 * 1024,
    int? maximumStagingRows,
    int Function()? nowMicros,
  }) : maximumStagingRows = maximumStagingRows ?? maximumPinnedRows * 2,
       _nowMicros = nowMicros ?? (() => developer.Timeline.now) {
    if (maximumPinnedRows <= 0 ||
        maximumRetainedScenes <= 0 ||
        maximumRetainedCandidateBanks <= 0 ||
        maximumRetainedCandidateRows <= 0 ||
        maximumRetainedCandidateBytes <= 0) {
      throw ArgumentError('Prepared scene cache bounds must be positive.');
    }
    if (this.maximumStagingRows < maximumPinnedRows) {
      throw ArgumentError.value(
        this.maximumStagingRows,
        'maximumStagingRows',
        'must preserve one complete active scene bank.',
      );
    }
  }

  final int maximumPinnedRows;
  final int maximumRetainedScenes;
  final int maximumRetainedCandidateBanks;
  final int maximumRetainedCandidateRows;
  final int maximumRetainedCandidateBytes;
  final int maximumStagingRows;
  final int Function() _nowMicros;

  RailCriticalSceneBank _activeBank = RailCriticalSceneBank.empty();
  _DashboardLogBoxStagedSceneBank? _stagedBank;
  final LinkedHashMap<String, _DashboardLogBoxStagedSceneBank>
  _retainedCandidateBanks =
      LinkedHashMap<String, _DashboardLogBoxStagedSceneBank>();
  Set<String> _protectedCandidateKeys = const <String>{};
  int _generation = 0;
  int _estimatedBytes = 0;
  int _peakStagingRowCount = 0;
  int _textLayoutMissCount = 0;
  final int _readySceneIncompleteCount = 0;
  int _activeWindowPartialPublishCount = 0;
  final int _stagingObjectRenderedCount = 0;
  int _railCriticalLookupHitCount = 0;
  int _railCriticalLookupMissCount = 0;
  int _visiblePayloadWithoutDrawableCount = 0;
  int _visiblePayloadWithoutPaintCount = 0;
  int _preparationToken = 0;
  int _sceneReuseCount = 0;
  int _scenePrepareNewCount = 0;
  int _rowLayoutReuseCount = 0;
  int _rowLayoutNewCount = 0;
  int _lastPrepareUiIsolateMicros = 0;
  int _lastPrepareLargestContiguousUiSliceMicros = 0;
  int _lastPrepareYieldCount = 0;
  final int _prepareNotifierCount = 0;
  int _preparationDepth = 0;
  bool _disposed = false;

  Map<String, DashboardPreparedLogBoxScene> get _scenes => _activeBank.scenes;
  Set<String> get _emptyQueryKeys => _activeBank.emptyQueryKeys;
  Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> get _rowLayouts =>
      _activeBank._rowLayouts;
  Map<String, TextPainter> get _dayHeaders => _activeBank.dayHeaders;
  TextPainter? get _empty => _activeBank.empty;
  double? get _surfaceWidth => _activeBank.surfaceWidth;
  double? get _devicePixelRatio => _activeBank.devicePixelRatio;
  DashboardLogBoxSceneWindow? get _activeWindow => _activeBank.window;
  DashboardLogBoxSceneWindowManifest? get _activeManifest =>
      _activeBank.manifest;

  int get generation => _generation;
  int get preparedRowCount => _rowLayouts.length;
  int get preparedDayHeaderCount => _dayHeaders.length;
  int get estimatedBytes => _estimatedBytes;
  int get peakStagingRowCount => _peakStagingRowCount;
  int get textLayoutMissCount => _textLayoutMissCount;
  int get readySceneIncompleteCount => _readySceneIncompleteCount;
  int get activeWindowPartialPublishCount => _activeWindowPartialPublishCount;
  int get stagingObjectRenderedCount => _stagingObjectRenderedCount;
  int get railCriticalLookupHitCount => _railCriticalLookupHitCount;
  int get railCriticalLookupMissCount => _railCriticalLookupMissCount;
  int get visiblePayloadWithoutDrawableCount =>
      _visiblePayloadWithoutDrawableCount;
  int get visiblePayloadWithoutPaintCount => _visiblePayloadWithoutPaintCount;
  RailCriticalSceneBank get railCriticalSceneBank => _activeBank;
  int get preparedSceneCount => _activeBank.sceneCount;
  int get sceneReuseCount => _sceneReuseCount;
  int get scenePrepareNewCount => _scenePrepareNewCount;
  int get rowLayoutReuseCount => _rowLayoutReuseCount;
  int get rowLayoutNewCount => _rowLayoutNewCount;
  int get lastPrepareUiIsolateMicros => _lastPrepareUiIsolateMicros;
  int get lastPrepareLargestContiguousUiSliceMicros =>
      _lastPrepareLargestContiguousUiSliceMicros;
  int get lastPrepareYieldCount => _lastPrepareYieldCount;
  bool get isPreparing => _preparationDepth > 0;
  String? get activeWindowIdentity => _activeWindow?.identity;
  String? get stagedWindowIdentity => _stagedBank?.window.identity;
  int get retainedCandidateBankCount => _retainedCandidateBanks.length;
  int get protectedCandidateBankCount => _protectedCandidateKeys.length;
  int get retainedCandidatePreparedRowCount =>
      _retainedCandidateUniqueResources.rowLayouts.length;
  int get retainedCandidateEstimatedBytes =>
      _retainedCandidateUniqueResources.estimatedBytes;
  _RetainedCandidateUniqueResources get _retainedCandidateUniqueResources =>
      _RetainedCandidateUniqueResources.fromBanks(
        _retainedCandidateBanks.values,
      );
  int get sharedPreparedRowLayoutCount {
    final activeLayouts =
        HashSet<DashboardPreparedLogBoxRowTextLayout>.identity()
          ..addAll(_rowLayouts.values);
    final shared = HashSet<DashboardPreparedLogBoxRowTextLayout>.identity();
    for (final bank in _retainedCandidateBanks.values) {
      for (final layout in bank.rowLayouts.values) {
        if (activeLayouts.contains(layout)) shared.add(layout);
      }
    }
    return shared.length;
  }

  int get sharedPreparedDayHeaderCount {
    final activeHeaders = HashSet<TextPainter>.identity()
      ..addAll(_dayHeaders.values);
    final shared = HashSet<TextPainter>.identity();
    for (final bank in _retainedCandidateBanks.values) {
      for (final header in bank.dayHeaders.values) {
        if (activeHeaders.contains(header)) shared.add(header);
      }
    }
    return shared.length;
  }

  double? get surfaceWidth => _surfaceWidth;
  int get activeWindowDigest => Object.hash(
    _activeWindow?.identity,
    _surfaceWidth,
    _devicePixelRatio,
    _activeManifest?.generation,
    Object.hashAll(_scenes.keys),
    Object.hashAll(_emptyQueryKeys),
    Object.hashAll(_rowLayouts.keys),
    Object.hashAll(_dayHeaders.keys),
  );

  DashboardLogBoxSceneWindowManifest? get activeWindowManifest =>
      _activeManifest;
  DashboardLogBoxSceneWindowManifest? get stagedWindowManifest =>
      _stagedBank?.manifest;

  /// Prepares one exact Query candidate scene bank without displacing another
  /// completed candidate. The active bank remains the renderer's only source
  /// until [activateWindow] swaps this exact bank in atomically.
  Future<void> prepareCandidateWindow({
    required String candidateKey,
    required DashboardLogBoxSceneWindow window,
    double? surfaceWidth,
    double devicePixelRatio = 1,
    int? retainViewportId,
    int yieldEveryRows = 64,
    int maxContiguousUiSliceMicros = 3000,
    DashboardLogBoxScenePreparationYield? yieldToBackground,
  }) async {
    _ensureUsable();
    // Bank-count pressure is the one retention failure that can be proven
    // without materializing a candidate's rows or TextPainters. Avoid doing
    // discardable speculative work when every retained bank is protected.
    if (!_canPossiblyRetainCandidateKey(candidateKey)) {
      _throwCandidateRetentionRejected(candidateKey, window);
    }
    await prepareWindow(
      window: window,
      surfaceWidth: surfaceWidth,
      devicePixelRatio: devicePixelRatio,
      retainViewportId: retainViewportId,
      yieldEveryRows: yieldEveryRows,
      maxContiguousUiSliceMicros: maxContiguousUiSliceMicros,
      yieldToBackground: yieldToBackground,
      candidateKey: candidateKey,
    );
  }

  /// Retains an invisible navigation hotset in this same bounded cache owner.
  /// The key is controller-owned; only [activateWindow] makes it renderable.
  Future<void> prepareRetainedWindow({
    required String retainedKey,
    required DashboardLogBoxSceneWindow window,
    double? surfaceWidth,
    double devicePixelRatio = 1,
    int? retainViewportId,
    int yieldEveryRows = 64,
    int maxContiguousUiSliceMicros = 3000,
    DashboardLogBoxScenePreparationYield? yieldToBackground,
  }) async {
    _ensureUsable();
    final width = _resolveSurfaceWidth(surfaceWidth);
    if (_canRetainCanonicalEmptyWindow(
      window,
      surfaceWidth: width,
      devicePixelRatio: devicePixelRatio,
    )) {
      _retainCanonicalEmptyWindow(
        retainedKey: retainedKey,
        window: window,
        surfaceWidth: width,
        devicePixelRatio: devicePixelRatio,
      );
      return;
    }
    await prepareCandidateWindow(
      candidateKey: retainedKey,
      window: window,
      surfaceWidth: width,
      devicePixelRatio: devicePixelRatio,
      retainViewportId: retainViewportId,
      yieldEveryRows: yieldEveryRows,
      maxContiguousUiSliceMicros: maxContiguousUiSliceMicros,
      yieldToBackground: yieldToBackground,
    );
  }

  bool hasRetainedWindow(DashboardLogBoxSceneWindow window) =>
      _retainedCandidateBankFor(window) != null;

  bool _canRetainCanonicalEmptyWindow(
    DashboardLogBoxSceneWindow window, {
    required double surfaceWidth,
    required double devicePixelRatio,
  }) =>
      window.payloads.isNotEmpty &&
      window.payloads.every((payload) => payload.previewRowCount == 0) &&
      _empty != null &&
      _surfaceWidth == surfaceWidth &&
      _devicePixelRatio == devicePixelRatio;

  /// Retains an exact empty target using the active bank's immutable empty
  /// painter. It constructs no row/header layout and emits no generic scene
  /// preparation event; normal activation still receives a complete, exact
  /// bank through the existing cache owner.
  void _retainCanonicalEmptyWindow({
    required String retainedKey,
    required DashboardLogBoxSceneWindow window,
    required double surfaceWidth,
    required double devicePixelRatio,
  }) {
    _ensureUsable();
    final empty = _empty;
    if (empty == null) return;
    final seed = window.payloads.first;
    final emptyScene = DashboardPreparedLogBoxScene._(
      payload: seed,
      surfaceWidth: surfaceWidth,
      devicePixelRatio: devicePixelRatio,
      rowLayouts: const <String, DashboardPreparedLogBoxRowTextLayout>{},
      dayHeaders: const <String, TextPainter>{},
      empty: empty,
      universalEmpty: true,
    );
    final coreRevision =
        window.coverageIdentity?.coreRevision ?? seed.revision ?? 0;
    final manifest = DashboardLogBoxSceneWindowManifest(
      requiredSceneCount: window.sceneCount,
      completeSceneCount: window.sceneCount,
      requiredTextLayoutCount: 1,
      completeTextLayoutCount: 1,
      generation: _generation + 1,
      coreRevision: coreRevision,
      surfaceWidth: surfaceWidth,
      devicePixelRatio: devicePixelRatio,
    );
    final bank = _DashboardLogBoxStagedSceneBank(
      window: window,
      scenes: const <String, DashboardPreparedLogBoxScene>{},
      emptyQueryKeys: window.payloads
          .map((payload) => payload.queryKey.value)
          .toSet(),
      emptyScene: emptyScene,
      rowLayouts: const <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{},
      dayHeaders: const <String, TextPainter>{},
      empty: empty,
      surfaceWidth: surfaceWidth,
      devicePixelRatio: devicePixelRatio,
      manifest: manifest,
      ownedRows: const <DashboardPreparedLogBoxRowTextLayout>[],
      ownedHeaders: const <TextPainter>[],
      ownedEmpty: null,
    );
    if (!_putRetainedCandidateBank(retainedKey, bank) ||
        !hasCandidateWindow(window, candidateKey: retainedKey)) {
      _throwCandidateRetentionRejected(retainedKey, window);
    }
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_WINDOW_CANONICAL_EMPTY_RETAINED',
        queryKey: window.identity,
        entryCount: 0,
        message: 'retainedKey=$retainedKey',
      ),
    );
  }

  /// Candidate readiness is exact-keyed as well as payload-complete. This is
  /// deliberately stronger than a generic retained-window hit: a different
  /// hotset may contain matching payloads, but Apply needs to know whether its
  /// own retained candidate still exists after bounded-cache eviction.
  bool hasCandidateWindow(
    DashboardLogBoxSceneWindow window, {
    required String candidateKey,
  }) {
    final bank = _retainedCandidateBanks[candidateKey];
    if (bank == null || !_matchesWindow(bank, window)) return false;
    _touchRetainedCandidateBank(candidateKey, bank);
    return bank.manifest.isComplete &&
        window.payloads.every(bank.hasCompleteSceneFor);
  }

  /// Discards only the invisible bank owned by [candidateKey].  This is used
  /// by Query Cancel and LRU eviction and can never mutate active rendering.
  void discardCandidateWindow(String candidateKey) {
    _discardRetainedCandidateBank(candidateKey);
  }

  /// The controller owns which applied-query chip targets are protected; this
  /// cache owns all banks and physical resource budgeting. A completed hotset
  /// bank may therefore survive unrelated LRU churn, but it can never bypass
  /// the hard cache budget silently.
  void setProtectedCandidateKeys(Set<String> candidateKeys) {
    _protectedCandidateKeys = Set<String>.unmodifiable(candidateKeys);
    _enforceRetainedCandidateBounds();
  }

  /// Exact renderer lookup for the revision-critical rail presentation bank.
  ///
  /// This is intentionally synchronous and complete-only. A null return is a
  /// production invariant violation for any non-empty visible rail payload;
  /// callers must never build, await, or repair a scene on the hot path.
  DashboardPreparedLogBoxScene? railCriticalSceneFor(
    DashboardLogViewportState payload, {
    double? devicePixelRatio,
  }) {
    final scene = _activeBank.sceneFor(
      payload,
      devicePixelRatio: devicePixelRatio,
    );
    if (scene == null && _activeBank.isComplete) {
      _railCriticalLookupMissCount += 1;
    } else if (scene != null) {
      _railCriticalLookupHitCount += 1;
    }
    return scene;
  }

  /// Backward-compatible name for consumers that already use the prepared
  /// scene cache. All renderer lookup is rail-critical lookup.
  DashboardPreparedLogBoxScene? sceneFor(
    DashboardLogViewportState payload, {
    double? devicePixelRatio,
  }) => railCriticalSceneFor(payload, devicePixelRatio: devicePixelRatio);

  void recordTextLayoutMiss() => _textLayoutMissCount += 1;

  /// These are presentation correctness counters, intentionally independent
  /// of background preparation state. A visible non-empty payload with no
  /// drawable or painted rows is never an acceptable transitional state.
  void recordVisiblePayloadWithoutDrawable() =>
      _visiblePayloadWithoutDrawableCount += 1;

  void recordVisiblePayloadWithoutPaint() =>
      _visiblePayloadWithoutPaintCount += 1;

  /// The controller calls this as soon as a newer target or user rail motion
  /// arrives. The active immutable bank is intentionally left untouched.
  void cancelInFlightPreparation() {
    _preparationToken += 1;
    _discardStagedBank();
  }

  /// Prepares but does not make [window] the active structural bank. Previous
  /// immutable scenes and their width-keyed text layouts remain reusable.
  Future<void> prepareWindow({
    required DashboardLogBoxSceneWindow window,
    double? surfaceWidth,
    double devicePixelRatio = 1,
    int? retainViewportId,
    int yieldEveryRows = 64,
    int maxContiguousUiSliceMicros = 3000,
    DashboardLogBoxScenePreparationYield? yieldToBackground,
    String? candidateKey,
  }) async {
    _ensureUsable();
    if (yieldEveryRows <= 0) {
      throw ArgumentError.value(yieldEveryRows, 'yieldEveryRows');
    }
    if (maxContiguousUiSliceMicros <= 0) {
      throw ArgumentError.value(
        maxContiguousUiSliceMicros,
        'maxContiguousUiSliceMicros',
      );
    }
    final width = _resolveSurfaceWidth(surfaceWidth);
    if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
      throw ArgumentError.value(devicePixelRatio, 'devicePixelRatio');
    }
    final preparationToken = ++_preparationToken;
    final startedAt = DateTime.now();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_WINDOW_PREPARE_STARTED',
        queryKey: window.identity,
        entryCount: window.previewRowCount,
      ),
    );
    // A retained Query candidate is invisible and owns only its *new* layouts.
    // Exact width/DPR/content-equivalent layouts can be leased from the active
    // immutable bank. The cache retains those references until their final
    // active/retained owner releases them; candidate disposal can never dispose
    // a layout still painted by the active bank.
    _discardStagedBank();
    if (candidateKey != null) _discardRetainedCandidateBank(candidateKey);
    _preparationDepth += 1;
    final createdRows = <DashboardPreparedLogBoxRowTextLayout>[];
    final createdHeaders = <TextPainter>[];
    TextPainter? createdEmpty;
    var uiIsolateMicros = 0;
    var largestContiguousUiSliceMicros = 0;
    var yieldCount = 0;
    final projectionBefore = _richProjectionMetricsFor(window.payloads);
    DashboardLogRichProjectionMetrics? projectionAfter;
    var sliceStartedAt = _nowMicros();

    void closeSlice() {
      final elapsed = _nowMicros() - sliceStartedAt;
      uiIsolateMicros += elapsed;
      largestContiguousUiSliceMicros = math.max(
        largestContiguousUiSliceMicros,
        elapsed,
      );
    }

    bool exceedsUiSliceBudget() =>
        _nowMicros() - sliceStartedAt >= maxContiguousUiSliceMicros;

    Future<void> checkpoint() async {
      closeSlice();
      yieldCount += 1;
      await (yieldToBackground ?? _yieldToEventLoop)();
      _ensureUsable();
      _throwIfPreparationSuperseded(preparationToken);
      sliceStartedAt = _nowMicros();
    }

    try {
      // A controller-owned rotation is background work. Yield before the
      // first paragraph so a settle never inherits a synchronous text-layout
      // slice; direct startup warmup intentionally omits this scheduler.
      if (yieldToBackground != null) {
        await checkpoint();
      }
      // Rich LogBox presentation is intentionally deferred by the compact
      // prepared index. This exact bounded scene window is its only consumer
      // before TextPainter work, never a rail crossing or render callback.
      for (final payload in window.payloads) {
        payload.materializeRichProjection();
        if (exceedsUiSliceBudget()) await checkpoint();
      }
      projectionAfter = _richProjectionMetricsFor(window.payloads);
      // A different layout width must construct a wholly new bank. In
      // particular, it must never clear or mutate the still-paintable active
      // bank while that replacement is being prepared.
      final canReuseActiveBank =
          _surfaceWidth == width && _devicePixelRatio == devicePixelRatio;
      // Candidate banks may share exact immutable text layouts even before
      // one becomes active.  A cold cache has no active width yet, so reuse
      // from retained banks is keyed by the staged bank's own width/DPR rather
      // than by active-bank availability.
      final canReuseRetainedBanks = _retainedCandidateBanks.values.every(
        (bank) =>
            bank.surfaceWidth == width &&
            bank.devicePixelRatio == devicePixelRatio,
      );
      final reusableRetainedResources = canReuseRetainedBanks
          ? _retainedCandidateReusableResources()
          : const _RetainedCandidateReusableResources.empty();
      final rowsByKey = <_RowLayoutKey, DashboardLogRowViewModel>{};
      final headerLabels = <String>{};
      var scannedSinceYield = 0;
      for (final payload in window.payloads) {
        for (final item in payload.flatItems) {
          final key = _RowLayoutKey.fromRow(item.row);
          final previous = rowsByKey[key];
          if (previous != null &&
              previous.textLayoutId != item.row.textLayoutId) {
            throw StateError(
              'One scene row layout key resolved to different text.',
            );
          }
          rowsByKey[key] = item.row;
          if (item.dayLabel case final String label) headerLabels.add(label);
          if (++scannedSinceYield >= yieldEveryRows || exceedsUiSliceBudget()) {
            scannedSinceYield = 0;
            await checkpoint();
          }
        }
      }
      // Text layouts are immutable and width-keyed. The old active bank keeps
      // its own references until the single publish swap. The next bank keeps
      // only the rows required for its exact revision universe; carrying old
      // LRU residents into it would make a rail-critical bank partial by
      // construction on a revision change.
      final requiredPinnedRows = <_RowLayoutKey>{...rowsByKey.keys};
      if (requiredPinnedRows.length > maximumPinnedRows) {
        throw StateError(
          'Prepared LogBox scene window exceeds $maximumPinnedRows retained '
          'row layouts: ${requiredPinnedRows.length}.',
        );
      }
      final finalRows = <_RowLayoutKey>{...requiredPinnedRows};
      final stagingRows = finalRows.length;
      _peakStagingRowCount = math.max(_peakStagingRowCount, stagingRows);
      if (stagingRows > maximumStagingRows) {
        throw StateError(
          'Prepared LogBox scene rotation exceeds $maximumStagingRows staging '
          'row layouts: $stagingRows.',
        );
      }
      final nextRows = <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{
        for (final key in finalRows)
          if (canReuseActiveBank && _rowLayouts.containsKey(key))
            key: _rowLayouts[key]!,
      };
      final nextHeaders = <String, TextPainter>{};

      var preparedSinceYield = 0;
      for (final entry in rowsByKey.entries) {
        final old =
            (canReuseActiveBank ? _rowLayouts[entry.key] : null) ??
            reusableRetainedResources.rowLayouts[entry.key];
        if (old != null) {
          _rowLayoutReuseCount += 1;
          nextRows[entry.key] = old;
        } else {
          final prepared = DashboardPreparedLogBoxRowTextLayout.prepare(
            row: entry.value,
            surfaceWidth: width,
            contentIdentity: entry.value.textLayoutId,
          );
          createdRows.add(prepared);
          _rowLayoutNewCount += 1;
          nextRows[entry.key] = prepared;
        }
        if (++preparedSinceYield >= yieldEveryRows || exceedsUiSliceBudget()) {
          preparedSinceYield = 0;
          await checkpoint();
        }
      }
      var headersSinceYield = 0;
      for (final label in headerLabels) {
        final old =
            (canReuseActiveBank ? _dayHeaders[label] : null) ??
            reusableRetainedResources.dayHeaders[label];
        if (old != null) {
          nextHeaders[label] = old;
        } else {
          final prepared = _headerPainter(label, width);
          createdHeaders.add(prepared);
          nextHeaders[label] = prepared;
        }
        if (++headersSinceYield >= yieldEveryRows || exceedsUiSliceBudget()) {
          headersSinceYield = 0;
          await checkpoint();
        }
      }
      final nextEmpty = canReuseActiveBank && _empty != null
          ? _empty!
          : _emptyPainter(width);
      if (!identical(_empty, nextEmpty)) createdEmpty = nextEmpty;

      if (window.sceneCount > maximumRetainedScenes) {
        throw StateError(
          'Rail-critical scene bank exceeds $maximumRetainedScenes scenes: '
          '${window.sceneCount}.',
        );
      }
      final nextScenes = <String, DashboardPreparedLogBoxScene>{};
      final nextEmptyQueryKeys = <String>{};
      DashboardPreparedLogBoxScene? nextEmptyScene;

      // [yieldEveryRows] is a work-unit contract, not a scene-count
      // contract. A single bounded preview scene can contain 24 rows, so
      // counting eight scenes here used to compose as many as 192 row maps in
      // one UI-isolate slice despite the coordinator requesting eight-row
      // chunks. Keep a large individual scene intact for atomic local
      // construction, but never accumulate another scene past the budget.
      var sceneRowsSinceYield = 0;
      var emptyScenesSinceYield = 0;
      for (final payload in window.payloads) {
        if (payload.flatItems.isEmpty) {
          nextEmptyQueryKeys.add(payload.queryKey.value);
          nextEmptyScene ??= DashboardPreparedLogBoxScene._(
            payload: payload,
            surfaceWidth: width,
            devicePixelRatio: devicePixelRatio,
            rowLayouts: const <String, DashboardPreparedLogBoxRowTextLayout>{},
            dayHeaders: const <String, TextPainter>{},
            empty: nextEmpty,
            universalEmpty: true,
          );
          // An empty scene is complete by definition, but building a large
          // revision can still enumerate thousands of them. Keep cancellation
          // responsive without turning one empty scene into one object.
          emptyScenesSinceYield += 1;
          if (emptyScenesSinceYield >= math.max(64, yieldEveryRows) ||
              exceedsUiSliceBudget()) {
            emptyScenesSinceYield = 0;
            await checkpoint();
          }
          continue;
        }
        final sceneWorkUnits = math.max(1, payload.flatItems.length);
        if ((sceneRowsSinceYield > 0 &&
                sceneRowsSinceYield + sceneWorkUnits > yieldEveryRows) ||
            exceedsUiSliceBudget()) {
          sceneRowsSinceYield = 0;
          await checkpoint();
        }
        final rows = <String, DashboardPreparedLogBoxRowTextLayout>{
          for (final item in payload.flatItems)
            item.row.entryId: nextRows[_RowLayoutKey.fromRow(item.row)]!,
        };
        final labels = <String>{
          for (final item in payload.flatItems)
            if (item.dayLabel case final String label) label,
        };
        final existing = canReuseActiveBank
            ? _scenes[payload.queryKey.value]
            : null;
        if (existing != null && existing.matches(payload, width)) {
          _sceneReuseCount += 1;
          nextScenes[payload.queryKey.value] = existing;
        } else {
          _scenePrepareNewCount += 1;
          nextScenes[payload.queryKey.value] = DashboardPreparedLogBoxScene._(
            payload: payload,
            surfaceWidth: width,
            devicePixelRatio: devicePixelRatio,
            rowLayouts: rows,
            dayHeaders: <String, TextPainter>{
              for (final label in labels) label: nextHeaders[label]!,
            },
            empty: nextEmpty,
          );
        }
        sceneRowsSinceYield += sceneWorkUnits;
        if (sceneRowsSinceYield >= yieldEveryRows || exceedsUiSliceBudget()) {
          sceneRowsSinceYield = 0;
          await checkpoint();
        }
      }
      final requiresEmptyPresentation = window.payloads.any(
        (payload) => payload.flatItems.isEmpty,
      );
      final requiredTextLayoutCount =
          rowsByKey.length +
          headerLabels.length +
          (requiresEmptyPresentation ? 1 : 0);
      final completeTextLayoutCount =
          rowsByKey.keys.where(nextRows.containsKey).length +
          headerLabels.where(nextHeaders.containsKey).length +
          (requiresEmptyPresentation ? 1 : 0);
      final completeSceneCount = window.payloads
          .where(
            (payload) => payload.flatItems.isEmpty
                ? nextEmptyQueryKeys.contains(payload.queryKey.value) &&
                      nextEmptyScene?.matchesEmptyPresentation(
                            payload,
                            width,
                            devicePixelRatio,
                          ) ==
                          true
                : nextScenes[payload.queryKey.value]?.matches(
                        payload,
                        width,
                        devicePixelRatio,
                      ) ??
                      false,
          )
          .length;
      final coreRevision =
          window.coverageIdentity?.coreRevision ??
          (window.payloads.isEmpty ? 0 : window.payloads.first.revision ?? 0);
      final manifest = DashboardLogBoxSceneWindowManifest(
        requiredSceneCount: window.sceneCount,
        completeSceneCount: completeSceneCount,
        requiredTextLayoutCount: requiredTextLayoutCount,
        completeTextLayoutCount: completeTextLayoutCount,
        generation: _generation + 1,
        coreRevision: coreRevision,
        surfaceWidth: width,
        devicePixelRatio: devicePixelRatio,
      );
      if (!manifest.isComplete) {
        throw StateError(
          'A staged LogBox scene bank must be complete before publication.',
        );
      }
      final preparedBank = _DashboardLogBoxStagedSceneBank(
        window: window,
        scenes: nextScenes,
        emptyQueryKeys: nextEmptyQueryKeys,
        emptyScene: nextEmptyScene,
        rowLayouts: nextRows,
        dayHeaders: nextHeaders,
        empty: nextEmpty,
        surfaceWidth: width,
        devicePixelRatio: devicePixelRatio,
        manifest: manifest,
        ownedRows: createdRows,
        ownedHeaders: createdHeaders,
        ownedEmpty: createdEmpty,
      );
      if (candidateKey == null) {
        _stagedBank = preparedBank;
      } else {
        final retained = _putRetainedCandidateBank(candidateKey, preparedBank);
        if (!retained ||
            !hasCandidateWindow(window, candidateKey: candidateKey)) {
          _throwCandidateRetentionRejected(candidateKey, window);
        }
      }
      closeSlice();
      _lastPrepareUiIsolateMicros = uiIsolateMicros;
      _lastPrepareLargestContiguousUiSliceMicros =
          largestContiguousUiSliceMicros;
      _lastPrepareYieldCount = yieldCount;
      final newSceneCount = preparedBank.scenes.values
          .where(
            (scene) =>
                !canReuseActiveBank ||
                !identical(_scenes[scene.payload.queryKey.value], scene),
          )
          .length;
      final reusedSceneCount = preparedBank.scenes.length - newSceneCount;
      final reusedRowLayoutCount = nextRows.length - createdRows.length;
      final completedProjection = projectionAfter;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_PREPARE_COMPLETED',
          queryKey: window.identity,
          entryCount: window.previewRowCount,
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          message:
              'uiIsolateMicros=$uiIsolateMicros '
              'largestContiguousUiSliceMicros='
              '$largestContiguousUiSliceMicros yields=$yieldCount '
              'richRowProjectionMicros='
              '${completedProjection.richRowProjectionMicros - projectionBefore.richRowProjectionMicros} '
              'richFrameProjectionMicros='
              '${completedProjection.richFrameProjectionMicros - projectionBefore.richFrameProjectionMicros} '
              'projectedUniqueRows='
              '${completedProjection.projectedUniqueRowCount - projectionBefore.projectedUniqueRowCount} '
              'projectedFrames='
              '${completedProjection.projectedFrameCount - projectionBefore.projectedFrameCount} '
              'reusedProjectedRows='
              '${completedProjection.reusedProjectedRowCount - projectionBefore.reusedProjectedRowCount} '
              'reusedProjectedFrames='
              '${completedProjection.reusedProjectedFrameCount - projectionBefore.reusedProjectedFrameCount} '
              'uniqueRowLayouts=${nextRows.length} '
              'reusedRowLayouts=$reusedRowLayoutCount '
              'newRowLayouts=${createdRows.length} '
              'sceneNew=$newSceneCount sceneReuse=$reusedSceneCount '
              'pauseCount=0 resumeCount=0 semanticsWork=0 rasterWork=0 '
              'allocationCount=${createdRows.length + createdHeaders.length + newSceneCount}',
        ),
      );
      // Deliberately no notify here: staging is hermetic and must be
      // impossible for the renderer to observe before the activation swap.
    } on DashboardLogBoxScenePreparationCancelled {
      for (final layout in createdRows) {
        layout.dispose();
      }
      for (final painter in createdHeaders) {
        painter.dispose();
      }
      createdEmpty?.dispose();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_PREPARE_CANCELLED',
          queryKey: window.identity,
          entryCount: window.previewRowCount,
        ),
      );
      rethrow;
    } on Object {
      for (final layout in createdRows) {
        layout.dispose();
      }
      for (final painter in createdHeaders) {
        painter.dispose();
      }
      createdEmpty?.dispose();
      rethrow;
    } finally {
      _preparationDepth -= 1;
    }
  }

  DashboardLogRichProjectionMetrics _richProjectionMetricsFor(
    Iterable<DashboardLogViewportState> payloads,
  ) {
    final rowOwners = HashSet<Object>.identity();
    var richRowProjectionMicros = 0;
    var richFrameProjectionMicros = 0;
    var projectedUniqueRowCount = 0;
    var projectedFrameCount = 0;
    var reusedProjectedRowCount = 0;
    var reusedProjectedFrameCount = 0;
    for (final payload in payloads) {
      final metrics = payload.richProjectionMetrics;
      richFrameProjectionMicros += metrics.richFrameProjectionMicros;
      projectedFrameCount += metrics.projectedFrameCount;
      reusedProjectedFrameCount += metrics.reusedProjectedFrameCount;
      if (rowOwners.add(payload.richProjectionOwner)) {
        richRowProjectionMicros += metrics.richRowProjectionMicros;
        projectedUniqueRowCount += metrics.projectedUniqueRowCount;
        reusedProjectedRowCount += metrics.reusedProjectedRowCount;
      }
    }
    return DashboardLogRichProjectionMetrics(
      richRowProjectionMicros: richRowProjectionMicros,
      richFrameProjectionMicros: richFrameProjectionMicros,
      projectedUniqueRowCount: projectedUniqueRowCount,
      projectedFrameCount: projectedFrameCount,
      reusedProjectedRowCount: reusedProjectedRowCount,
      reusedProjectedFrameCount: reusedProjectedFrameCount,
    );
  }

  void activateWindow(DashboardLogBoxSceneWindow window) {
    _ensureUsable();
    final generic = _stagedBank;
    final staged =
        generic != null &&
            generic.window.identity == window.identity &&
            generic.window.payloads.length == window.payloads.length &&
            generic.window.payloads.every(
              (payload) => window.payloads.any(
                (required) => required.queryKey == payload.queryKey,
              ),
            )
        ? generic
        : _retainedCandidateBankFor(window);
    final complete =
        staged != null &&
        staged.window.identity == window.identity &&
        staged.manifest.isComplete &&
        window.payloads.every((payload) => staged.hasCompleteSceneFor(payload));
    if (!complete) {
      _activeWindowPartialPublishCount += 1;
      throw StateError(
        'A LogBox scene window may activate only after completion.',
      );
    }
    _replaceActiveBank(
      window: window,
      manifest: staged.manifest,
      scenes: staged.scenes,
      emptyQueryKeys: staged.emptyQueryKeys,
      emptyScene: staged.emptyScene,
      rowLayouts: staged.rowLayouts,
      dayHeaders: staged.dayHeaders,
      empty: staged.empty,
      surfaceWidth: staged.surfaceWidth,
      devicePixelRatio: staged.devicePixelRatio,
    );
    if (identical(staged, _stagedBank)) {
      _stagedBank = null;
    } else {
      _removeRetainedCandidateBank(staged);
    }
    _generation += 1;
    _estimatedBytes = _estimateBytes(
      _rowLayouts.keys,
      _dayHeaders.keys,
      sceneCount: _scenes.length,
      hasEmptyPresentation: _empty != null,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_WINDOW_ACTIVATED',
        queryKey: window.identity,
        entryCount: window.previewRowCount,
      ),
    );
    notifyListeners();
  }

  Map<String, Object?> report() => <String, Object?>{
    'state': isPreparing ? 'preparing' : 'ready',
    'activeWindow': _activeWindow?.identity,
    'stagedWindow': _stagedBank?.window.identity,
    'retainedCandidateBanks': retainedCandidateBankCount,
    'protectedCandidateBanks': protectedCandidateBankCount,
    'retainedCandidatePreparedRows': retainedCandidatePreparedRowCount,
    'retainedCandidateBytes': retainedCandidateEstimatedBytes,
    'retainedCandidateUniqueRows': retainedCandidatePreparedRowCount,
    'retainedCandidateUniqueHeaders':
        _retainedCandidateUniqueResources.dayHeaders.length,
    'sharedPreparedRowLayouts': sharedPreparedRowLayoutCount,
    'sharedPreparedDayHeaders': sharedPreparedDayHeaderCount,
    'activeWindowManifest': _activeManifest?.toReportMap(),
    'stagedWindowManifest': _stagedBank?.manifest.toReportMap(),
    'preparedScenes': preparedSceneCount,
    'preparedTextRows': preparedRowCount,
    'preparedDayHeaders': preparedDayHeaderCount,
    'sceneCacheBytes': estimatedBytes,
    'textLayoutMisses': textLayoutMissCount,
    'readySceneIncomplete': readySceneIncompleteCount,
    'activeWindowPartialPublish': activeWindowPartialPublishCount,
    'stagingObjectRendered': stagingObjectRenderedCount,
    'railCriticalSceneCount': railCriticalSceneBank.sceneCount,
    'railCriticalUniqueTextRows': railCriticalSceneBank.uniqueRowLayoutCount,
    'railCriticalHeaderCount': railCriticalSceneBank.dayHeaderCount,
    'railCriticalBytes': railCriticalSceneBank.estimatedBytes,
    'railCriticalLookupHit': railCriticalLookupHitCount,
    'railCriticalLookupMiss': railCriticalLookupMissCount,
    'visiblePayloadWithoutDrawable': visiblePayloadWithoutDrawableCount,
    'visiblePayloadWithoutPaint': visiblePayloadWithoutPaintCount,
    'railCriticalBankIdentity': _activeWindow?.identity,
    'maximumPinnedRows': maximumPinnedRows,
    'maximumRetainedScenes': maximumRetainedScenes,
    'maximumStagingRows': maximumStagingRows,
    'maximumRetainedCandidateBanks': maximumRetainedCandidateBanks,
    'maximumRetainedCandidateRows': maximumRetainedCandidateRows,
    'maximumRetainedCandidateBytes': maximumRetainedCandidateBytes,
    'peakStagingRows': peakStagingRowCount,
    'sceneReuseCount': sceneReuseCount,
    'scenePrepareNewCount': scenePrepareNewCount,
    'rowLayoutReuseCount': rowLayoutReuseCount,
    'rowLayoutNewCount': rowLayoutNewCount,
    'lastPrepareUiIsolateMicros': lastPrepareUiIsolateMicros,
    'lastPrepareLargestContiguousUiSliceMicros':
        lastPrepareLargestContiguousUiSliceMicros,
    'lastPrepareYieldCount': lastPrepareYieldCount,
    'prepareSemanticsWork': 0,
    'prepareRasterWork': 0,
    'prepareNotifierCount': _prepareNotifierCount,
  };

  void _replaceActiveBank({
    required DashboardLogBoxSceneWindow window,
    required DashboardLogBoxSceneWindowManifest manifest,
    required Map<String, DashboardPreparedLogBoxScene> scenes,
    required Set<String> emptyQueryKeys,
    required DashboardPreparedLogBoxScene? emptyScene,
    required Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>
    rowLayouts,
    required Map<String, TextPainter> dayHeaders,
    required TextPainter empty,
    required double surfaceWidth,
    required double devicePixelRatio,
  }) {
    for (final entry in _rowLayouts.entries) {
      if (!identical(rowLayouts[entry.key], entry.value) &&
          !_retainedReferencesRowLayout(entry.value)) {
        entry.value.dispose();
      }
    }
    for (final entry in _dayHeaders.entries) {
      if (!identical(dayHeaders[entry.key], entry.value) &&
          !_retainedReferencesDayHeader(entry.value)) {
        entry.value.dispose();
      }
    }
    if (!identical(_empty, empty) && !_retainedReferencesEmpty(_empty)) {
      _empty?.dispose();
    }
    _activeBank = RailCriticalSceneBank._(
      window: window,
      manifest: manifest,
      scenes: scenes,
      emptyQueryKeys: emptyQueryKeys,
      emptyScene: emptyScene,
      rowLayouts: rowLayouts,
      dayHeaders: dayHeaders,
      empty: empty,
      surfaceWidth: surfaceWidth,
      devicePixelRatio: devicePixelRatio,
    );
  }

  double _resolveSurfaceWidth(double? supplied) {
    if (supplied != null) {
      if (!supplied.isFinite || supplied <= 0) {
        throw ArgumentError.value(supplied, 'surfaceWidth');
      }
      return supplied;
    }
    final width = _surfaceWidth;
    if (width == null) {
      throw StateError(
        'A LogBox scene window needs one normal surface layout.',
      );
    }
    return width;
  }

  /// The production render host injects a scheduler-aware yield so pointer and
  /// gesture tasks outrank preparation. This fallback keeps the cache itself
  /// deterministic for pure controller/bootstrap callers that have no Flutter
  /// binding, without ever imposing a frame-length wait.
  Future<void> _yieldToEventLoop() => Future<void>.microtask(() {});

  void _throwIfPreparationSuperseded(int token) {
    if (token != _preparationToken) {
      throw const DashboardLogBoxScenePreparationCancelled();
    }
  }

  TextPainter _headerPainter(String label, double width) => TextPainter(
    text: TextSpan(
      text: label,
      style: FluviVisualTokens.logBoxDayHeaderTextStyle,
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: width);

  TextPainter _emptyPainter(double width) => TextPainter(
    text: TextSpan(
      text: 'Nincs tranzakció ebben az időszakban.',
      style: FluviVisualTokens.logBoxHeaderTextStyle,
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: math.max(0, width - 32));

  int _estimateBytes(
    Iterable<_RowLayoutKey> rowKeys,
    Iterable<String> headers, {
    required int sceneCount,
    required bool hasEmptyPresentation,
  }) {
    var utf16Units = 0;
    var rowCount = 0;
    for (final key in rowKeys) {
      rowCount += 1;
      utf16Units += key.textUnits;
    }
    for (final header in headers) {
      utf16Units += header.length;
    }
    return rowCount * 2048 +
        utf16Units * 2 +
        sceneCount * 192 +
        (hasEmptyPresentation ? 1024 : 0);
  }

  _DashboardLogBoxStagedSceneBank? _retainedCandidateBankFor(
    DashboardLogBoxSceneWindow window,
  ) {
    String? matchingKey;
    _DashboardLogBoxStagedSceneBank? matchingBank;
    for (final entry in _retainedCandidateBanks.entries) {
      if (_matchesWindow(entry.value, window)) {
        matchingKey = entry.key;
        matchingBank = entry.value;
        break;
      }
    }
    if (matchingKey != null && matchingBank != null) {
      _touchRetainedCandidateBank(matchingKey, matchingBank);
    }
    return matchingBank;
  }

  bool _matchesWindow(
    _DashboardLogBoxStagedSceneBank bank,
    DashboardLogBoxSceneWindow window,
  ) =>
      bank.window.identity == window.identity &&
      bank.window.payloads.length == window.payloads.length &&
      bank.window.payloads.every(
        (payload) => window.payloads.any(
          (required) => required.queryKey == payload.queryKey,
        ),
      );

  void _touchRetainedCandidateBank(
    String candidateKey,
    _DashboardLogBoxStagedSceneBank bank,
  ) {
    if (_retainedCandidateBanks.keys.last == candidateKey) return;
    _retainedCandidateBanks.remove(candidateKey);
    _retainedCandidateBanks[candidateKey] = bank;
  }

  bool _putRetainedCandidateBank(
    String candidateKey,
    _DashboardLogBoxStagedSceneBank bank,
  ) {
    if (!_canRetainCandidateBank(candidateKey, bank)) return false;
    // Do the retention proof before releasing a prior exact bank. A rejected
    // replacement must not destroy the last valid candidate merely because a
    // new foreground request could not fit under the current hard bounds.
    _discardRetainedCandidateBank(candidateKey);
    _retainedCandidateBanks[candidateKey] = bank;
    _enforceRetainedCandidateBounds();
    return identical(_retainedCandidateBanks[candidateKey], bank);
  }

  /// Returns false only for a capacity failure that is independent of the
  /// candidate's eventual row/byte footprint. More nuanced byte/row pressure
  /// remains verified against the complete immutable bank below.
  bool _canPossiblyRetainCandidateKey(String candidateKey) {
    if (_retainedCandidateBanks.containsKey(candidateKey) ||
        _retainedCandidateBanks.length < maximumRetainedCandidateBanks) {
      return true;
    }
    return _retainedCandidateBanks.keys.any(
      (key) => !_protectedCandidateKeys.contains(key),
    );
  }

  Never _throwCandidateRetentionRejected(
    String candidateKey,
    DashboardLogBoxSceneWindow window,
  ) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_CANDIDATE_SCENE_RETENTION_REJECTED',
        queryKey: window.identity,
        entryCount: window.previewRowCount,
        scope:
            'candidateKey=$candidateKey '
            'retainedCandidateBankCount=${_retainedCandidateBanks.length} '
            'protectedCandidateBankCount=${_protectedCandidateKeys.length} '
            'retainedUniqueRows=$retainedCandidatePreparedRowCount '
            'retainedEstimatedBytes=$retainedCandidateEstimatedBytes '
            'maxBanks=$maximumRetainedCandidateBanks '
            'maxRows=$maximumRetainedCandidateRows '
            'maxBytes=$maximumRetainedCandidateBytes',
      ),
    );
    throw StateError(
      'QUERY_CANDIDATE_SCENE_RETENTION_REJECTED: '
      'candidateKey=$candidateKey could not remain retained.',
    );
  }

  /// Simulates exact LRU eviction before retaining [bank].  A candidate
  /// preparation is allowed to complete only if its own immutable bank can
  /// survive every hard bound; returning a successful Future for a bank that
  /// was evicted in the same call would be a false readiness signal.
  bool _canRetainCandidateBank(
    String candidateKey,
    _DashboardLogBoxStagedSceneBank bank,
  ) {
    final next =
        LinkedHashMap<String, _DashboardLogBoxStagedSceneBank>.of(
            _retainedCandidateBanks,
          )
          ..remove(candidateKey)
          ..[candidateKey] = bank;
    while (_candidateBanksExceedBounds(next.values)) {
      String? evictable;
      for (final key in next.keys) {
        if (!_protectedCandidateKeys.contains(key)) {
          evictable = key;
          break;
        }
      }
      if (evictable == null) return false;
      next.remove(evictable);
    }
    return identical(next[candidateKey], bank);
  }

  bool _candidateBanksExceedBounds(
    Iterable<_DashboardLogBoxStagedSceneBank> banks,
  ) {
    final snapshot = banks.toList(growable: false);
    final resources = _RetainedCandidateUniqueResources.fromBanks(snapshot);
    return snapshot.length > maximumRetainedCandidateBanks ||
        (snapshot.length > 1 &&
            resources.rowLayouts.length > maximumRetainedCandidateRows) ||
        (snapshot.length > 1 &&
            resources.estimatedBytes > maximumRetainedCandidateBytes);
  }

  void _enforceRetainedCandidateBounds() {
    while (_candidateBanksExceedBounds(_retainedCandidateBanks.values)) {
      final oldest = _evictableRetainedCandidateKey();
      if (oldest == null) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'QUERY_CHIP_HOTSET_CAPACITY_EXCEEDED',
            message:
                'retainedSceneBankCount=${_retainedCandidateBanks.length} '
                'protectedBankCount=${_protectedCandidateKeys.length} '
                'retainedUniqueRows=$retainedCandidatePreparedRowCount '
                'retainedEstimatedBytes=$retainedCandidateEstimatedBytes '
                'maxBanks=$maximumRetainedCandidateBanks '
                'maxRows=$maximumRetainedCandidateRows '
                'maxBytes=$maximumRetainedCandidateBytes',
          ),
        );
        return;
      }
      _discardRetainedCandidateBank(oldest);
    }
  }

  String? _evictableRetainedCandidateKey() {
    for (final key in _retainedCandidateBanks.keys) {
      if (!_protectedCandidateKeys.contains(key)) return key;
    }
    return null;
  }

  void _removeRetainedCandidateBank(_DashboardLogBoxStagedSceneBank bank) {
    String? matchedKey;
    for (final entry in _retainedCandidateBanks.entries) {
      if (identical(entry.value, bank)) {
        matchedKey = entry.key;
        break;
      }
    }
    if (matchedKey != null) _retainedCandidateBanks.remove(matchedKey);
  }

  void _discardRetainedCandidateBank(String candidateKey) {
    final removed = _retainedCandidateBanks.remove(candidateKey);
    if (removed == null) return;
    final ownedRows = HashSet<DashboardPreparedLogBoxRowTextLayout>.identity()
      ..addAll(removed.ownedRows);
    final ownedHeaders = HashSet<TextPainter>.identity()
      ..addAll(removed.ownedHeaders);
    final ownedEmpty = removed.ownedEmpty;
    removed.disposeOwnedResources();
    // A retained bank may lease immutable layouts from the active bank. Once
    // it is gone, release such a lease only when neither the active bank nor a
    // sibling retained bank still references it. The identity checks are the
    // explicit lifetime accounting for these opaque TextPainter resources.
    for (final layout in removed.rowLayouts.values) {
      if (!ownedRows.contains(layout) &&
          !_activeReferencesRowLayout(layout) &&
          !_retainedReferencesRowLayout(layout)) {
        layout.dispose();
      }
    }
    for (final header in removed.dayHeaders.values) {
      if (!ownedHeaders.contains(header) &&
          !_activeReferencesDayHeader(header) &&
          !_retainedReferencesDayHeader(header)) {
        header.dispose();
      }
    }
    final empty = removed.empty;
    if (!identical(ownedEmpty, empty) &&
        !identical(_empty, empty) &&
        !_retainedReferencesEmpty(empty)) {
      empty.dispose();
    }
  }

  bool _activeReferencesRowLayout(
    DashboardPreparedLogBoxRowTextLayout layout,
  ) => _rowLayouts.values.any((candidate) => identical(candidate, layout));

  bool _retainedReferencesRowLayout(
    DashboardPreparedLogBoxRowTextLayout layout,
  ) => _retainedCandidateBanks.values.any(
    (bank) =>
        bank.rowLayouts.values.any((candidate) => identical(candidate, layout)),
  );

  bool _activeReferencesDayHeader(TextPainter header) =>
      _dayHeaders.values.any((candidate) => identical(candidate, header));

  bool _retainedReferencesDayHeader(TextPainter header) =>
      _retainedCandidateBanks.values.any(
        (bank) => bank.dayHeaders.values.any(
          (candidate) => identical(candidate, header),
        ),
      );

  bool _retainedReferencesEmpty(TextPainter? empty) =>
      empty != null &&
      _retainedCandidateBanks.values.any(
        (bank) => identical(bank.empty, empty),
      );

  _RetainedCandidateReusableResources _retainedCandidateReusableResources() {
    final rows = <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{};
    final headers = <String, TextPainter>{};
    for (final bank in _retainedCandidateBanks.values) {
      for (final entry in bank.rowLayouts.entries) {
        rows.putIfAbsent(entry.key, () => entry.value);
      }
      for (final entry in bank.dayHeaders.entries) {
        headers.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return _RetainedCandidateReusableResources(
      rowLayouts: rows,
      dayHeaders: headers,
    );
  }

  void _discardStagedBank() {
    final staged = _stagedBank;
    _stagedBank = null;
    staged?.disposeOwnedResources();
  }

  void _ensureUsable() {
    if (_disposed) throw StateError('Prepared LogBox scene cache is disposed.');
  }

  void _clear() {
    _discardStagedBank();
    // Retained candidates may lease immutable layouts from the active bank.
    // At final disposal there is no remaining owner, so dispose each opaque
    // paragraph exactly once regardless of which bank originally created it.
    final rowLayouts = HashSet<DashboardPreparedLogBoxRowTextLayout>.identity()
      ..addAll(_rowLayouts.values);
    final dayHeaders = HashSet<TextPainter>.identity()
      ..addAll(_dayHeaders.values);
    final emptyPainters = HashSet<TextPainter>.identity();
    if (_empty case final TextPainter empty) emptyPainters.add(empty);
    for (final bank in _retainedCandidateBanks.values) {
      rowLayouts.addAll(bank.rowLayouts.values);
      dayHeaders.addAll(bank.dayHeaders.values);
      if (bank.empty case final TextPainter empty) emptyPainters.add(empty);
    }
    _retainedCandidateBanks.clear();
    for (final layout in rowLayouts) {
      layout.dispose();
    }
    for (final painter in dayHeaders) {
      painter.dispose();
    }
    for (final painter in emptyPainters) {
      painter.dispose();
    }
    _activeBank = RailCriticalSceneBank.empty();
    _estimatedBytes = 0;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _clear();
    super.dispose();
  }
}

/// The sole renderer-visible cache state. All maps are immutable snapshots;
/// publishing a new complete world means replacing this one pointer.
@immutable
final class RailCriticalSceneBank {
  RailCriticalSceneBank._({
    required this.window,
    required this.manifest,
    required Map<String, DashboardPreparedLogBoxScene> scenes,
    required Set<String> emptyQueryKeys,
    required this.emptyScene,
    required Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>
    rowLayouts,
    required Map<String, TextPainter> dayHeaders,
    required this.empty,
    required this.surfaceWidth,
    required this.devicePixelRatio,
  }) : scenes = Map<String, DashboardPreparedLogBoxScene>.unmodifiable(scenes),
       emptyQueryKeys = Set<String>.unmodifiable(emptyQueryKeys),
       _rowLayouts =
           Map<
             _RowLayoutKey,
             DashboardPreparedLogBoxRowTextLayout
           >.unmodifiable(rowLayouts),
       dayHeaders = Map<String, TextPainter>.unmodifiable(dayHeaders);

  factory RailCriticalSceneBank.empty() => RailCriticalSceneBank._(
    window: null,
    manifest: null,
    scenes: const <String, DashboardPreparedLogBoxScene>{},
    emptyQueryKeys: const <String>{},
    emptyScene: null,
    rowLayouts: const <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{},
    dayHeaders: const <String, TextPainter>{},
    empty: null,
    surfaceWidth: null,
    devicePixelRatio: null,
  );

  final DashboardLogBoxSceneWindow? window;
  final DashboardLogBoxSceneWindowManifest? manifest;
  final Map<String, DashboardPreparedLogBoxScene> scenes;
  final Set<String> emptyQueryKeys;
  final DashboardPreparedLogBoxScene? emptyScene;
  final Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> _rowLayouts;
  final Map<String, TextPainter> dayHeaders;
  final TextPainter? empty;
  final double? surfaceWidth;
  final double? devicePixelRatio;

  /// The active rail bank is publishable only when its completion proof and
  /// exact surface key both exist. Empty is a bootstrap sentinel, never a
  /// ready presentation bank.
  bool get isComplete => manifest?.isComplete == true;
  int get sceneCount => scenes.length + emptyQueryKeys.length;
  int get uniqueRowLayoutCount => _rowLayouts.length;
  int get dayHeaderCount => dayHeaders.length;
  int get estimatedBytes {
    var utf16Units = 0;
    for (final key in _rowLayouts.keys) {
      utf16Units += key.textUnits;
    }
    for (final header in dayHeaders.keys) {
      utf16Units += header.length;
    }
    return _rowLayouts.length * 2048 +
        utf16Units * 2 +
        sceneCount * 192 +
        (empty == null ? 0 : 1024);
  }

  DashboardPreparedLogBoxScene? sceneFor(
    DashboardLogViewportState payload, {
    double? devicePixelRatio,
  }) {
    final scene = scenes[payload.queryKey.value];
    if (scene == null &&
        emptyQueryKeys.contains(payload.queryKey.value) &&
        emptyScene?.matchesEmptyPresentation(
              payload,
              surfaceWidth,
              devicePixelRatio ?? this.devicePixelRatio,
            ) ==
            true) {
      assert(emptyScene!.isCompletelyPrepared);
      return emptyScene;
    }
    if (scene == null ||
        !scene.matches(
          payload,
          surfaceWidth,
          devicePixelRatio ?? this.devicePixelRatio,
        )) {
      return null;
    }
    assert(scene.isCompletelyPrepared);
    return scene.isCompletelyPrepared ? scene : null;
  }
}

/// Private, mutable-only-during-build replacement bank. It has no renderer
/// entry point; ownership transfers to the active bank exactly once on a
/// successful activation, otherwise only resources created by this build are
/// released.
final class _DashboardLogBoxStagedSceneBank {
  _DashboardLogBoxStagedSceneBank({
    required this.window,
    required Map<String, DashboardPreparedLogBoxScene> scenes,
    required Set<String> emptyQueryKeys,
    required this.emptyScene,
    required Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>
    rowLayouts,
    required Map<String, TextPainter> dayHeaders,
    required this.empty,
    required this.surfaceWidth,
    required this.devicePixelRatio,
    required this.manifest,
    required List<DashboardPreparedLogBoxRowTextLayout> ownedRows,
    required List<TextPainter> ownedHeaders,
    required this.ownedEmpty,
  }) : scenes = Map<String, DashboardPreparedLogBoxScene>.unmodifiable(scenes),
       emptyQueryKeys = Set<String>.unmodifiable(emptyQueryKeys),
       rowLayouts =
           Map<
             _RowLayoutKey,
             DashboardPreparedLogBoxRowTextLayout
           >.unmodifiable(rowLayouts),
       dayHeaders = Map<String, TextPainter>.unmodifiable(dayHeaders),
       _ownedRows = List<DashboardPreparedLogBoxRowTextLayout>.unmodifiable(
         ownedRows,
       ),
       _ownedHeaders = List<TextPainter>.unmodifiable(ownedHeaders);

  final DashboardLogBoxSceneWindow window;
  final Map<String, DashboardPreparedLogBoxScene> scenes;
  final Set<String> emptyQueryKeys;
  final DashboardPreparedLogBoxScene? emptyScene;
  final Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> rowLayouts;
  final Map<String, TextPainter> dayHeaders;
  final TextPainter empty;
  final double surfaceWidth;
  final double devicePixelRatio;
  final DashboardLogBoxSceneWindowManifest manifest;
  final List<DashboardPreparedLogBoxRowTextLayout> _ownedRows;
  final List<TextPainter> _ownedHeaders;
  final TextPainter? ownedEmpty;

  Iterable<DashboardPreparedLogBoxRowTextLayout> get ownedRows => _ownedRows;
  Iterable<TextPainter> get ownedHeaders => _ownedHeaders;

  int get estimatedBytes {
    var utf16Units = 0;
    for (final key in rowLayouts.keys) {
      utf16Units += key.textUnits;
    }
    for (final header in dayHeaders.keys) {
      utf16Units += header.length;
    }
    return rowLayouts.length * 2048 +
        utf16Units * 2 +
        (scenes.length + emptyQueryKeys.length) * 192 +
        1024;
  }

  bool hasCompleteSceneFor(DashboardLogViewportState payload) {
    if (payload.previewRowCount == 0) {
      return emptyQueryKeys.contains(payload.queryKey.value) &&
          emptyScene?.matchesEmptyPresentation(
                payload,
                surfaceWidth,
                devicePixelRatio,
              ) ==
              true;
    }
    return scenes[payload.queryKey.value]?.matches(
          payload,
          surfaceWidth,
          devicePixelRatio,
        ) ??
        false;
  }

  void disposeOwnedResources() {
    for (final layout in _ownedRows) {
      layout.dispose();
    }
    for (final painter in _ownedHeaders) {
      painter.dispose();
    }
    ownedEmpty?.dispose();
  }
}

/// Exact physical ownership accounting across invisible retained banks.
///
/// Candidate banks can lease the same immutable text layout/header from an
/// active or sibling bank.  Count each opaque resource by identity once, then
/// add the small per-bank scene manifest overhead separately.  This is the
/// bounded-cache eviction metric; summing per-bank row counts would evict a
/// correct chip neighbour merely because it shares already-owned paragraphs.
final class _RetainedCandidateUniqueResources {
  _RetainedCandidateUniqueResources.fromBanks(
    Iterable<_DashboardLogBoxStagedSceneBank> banks,
  ) : rowLayouts = HashSet<DashboardPreparedLogBoxRowTextLayout>.identity(),
      dayHeaders = HashSet<TextPainter>.identity(),
      sceneCount = 0,
      bankCount = 0 {
    for (final bank in banks) {
      rowLayouts.addAll(bank.rowLayouts.values);
      dayHeaders.addAll(bank.dayHeaders.values);
      sceneCount += bank.scenes.length + bank.emptyQueryKeys.length;
      bankCount += 1;
    }
  }

  final Set<DashboardPreparedLogBoxRowTextLayout> rowLayouts;
  final Set<TextPainter> dayHeaders;
  int sceneCount;
  int bankCount;

  int get estimatedBytes {
    // Header text is not exposed by TextPainter, but each unique header is a
    // small opaque paragraph resource.  The fixed estimate keeps eviction
    // monotonic and never multiplies a shared object by bank references.
    return rowLayouts.length * 2048 +
        dayHeaders.length * 1024 +
        sceneCount * 192 +
        bankCount * 256;
  }
}

final class _RetainedCandidateReusableResources {
  const _RetainedCandidateReusableResources({
    required this.rowLayouts,
    required this.dayHeaders,
  });

  const _RetainedCandidateReusableResources.empty()
    : rowLayouts =
          const <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{},
      dayHeaders = const <String, TextPainter>{};

  final Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> rowLayouts;
  final Map<String, TextPainter> dayHeaders;
}

@immutable
final class DashboardPreparedLogBoxScene {
  DashboardPreparedLogBoxScene._({
    required this.payload,
    required this.surfaceWidth,
    required this.devicePixelRatio,
    required Map<String, DashboardPreparedLogBoxRowTextLayout> rowLayouts,
    required Map<String, TextPainter> dayHeaders,
    required this.empty,
    this.universalEmpty = false,
  }) : _rowLayouts =
           Map<String, DashboardPreparedLogBoxRowTextLayout>.unmodifiable(
             rowLayouts,
           ),
       _dayHeaders = Map<String, TextPainter>.unmodifiable(dayHeaders),
       contentIdentity = _contentIdentity(payload);

  final DashboardLogViewportState payload;
  final double surfaceWidth;
  final double devicePixelRatio;
  final int contentIdentity;
  final Map<String, DashboardPreparedLogBoxRowTextLayout> _rowLayouts;
  final Map<String, TextPainter> _dayHeaders;
  final TextPainter empty;
  final bool universalEmpty;

  int get viewportId => payload.viewportId;
  bool get isCompletelyPrepared => true;

  DashboardPreparedLogBoxRowTextLayout? rowFor(DashboardLogRowViewModel row) {
    final layout = _rowLayouts[row.entryId];
    return layout != null && layout.contentIdentity == row.textLayoutId
        ? layout
        : null;
  }

  TextPainter? dayHeaderFor(String label) => _dayHeaders[label];

  bool matches(
    DashboardLogViewportState other,
    double? width, [
    double? requestedDevicePixelRatio,
  ]) =>
      width == surfaceWidth &&
      (requestedDevicePixelRatio == null ||
          requestedDevicePixelRatio == devicePixelRatio) &&
      other.queryKey == payload.queryKey &&
      _contentIdentity(other) == contentIdentity;

  /// A bank proves exact coverage through its query-key membership set. All
  /// empty previews for one revision and surface use the same immutable empty
  /// presentation, because they have no row or header dependency to vary.
  bool matchesEmptyPresentation(
    DashboardLogViewportState other,
    double? width, [
    double? requestedDevicePixelRatio,
  ]) =>
      universalEmpty &&
      other.previewRowCount == 0 &&
      other.revision == payload.revision &&
      width == surfaceWidth &&
      (requestedDevicePixelRatio == null ||
          requestedDevicePixelRatio == devicePixelRatio);

  /// The compact viewport id includes the exact query/revision/direction,
  /// cursor and grouped row identity. Scene preparation has already verified
  /// its rich text-layout rows before constructing this object; lookup must
  /// not re-project a cold payload merely to reject a cache miss.
  static int _contentIdentity(DashboardLogViewportState payload) =>
      payload.viewportId;
}

@immutable
final class _RowLayoutKey {
  const _RowLayoutKey({
    required this.entryId,
    required this.contentIdentity,
    required this.textUnits,
  });

  factory _RowLayoutKey.fromRow(DashboardLogRowViewModel row) => _RowLayoutKey(
    entryId: row.entryId,
    contentIdentity: row.textLayoutId,
    textUnits:
        row.entryId.length +
        row.displayName.length +
        row.categoryDisplayName.length +
        row.formattedAmount.length +
        row.displayTime.length,
  );

  final String entryId;
  final int contentIdentity;
  final int textUnits;

  @override
  bool operator ==(Object other) =>
      other is _RowLayoutKey &&
      other.entryId == entryId &&
      other.contentIdentity == contentIdentity;

  @override
  int get hashCode => Object.hash(entryId, contentIdentity);
}
