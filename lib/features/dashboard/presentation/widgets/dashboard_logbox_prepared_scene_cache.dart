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
/// The active bank is capped. A structural rotation constructs its next bank
/// privately, then swaps it atomically. The active immutable scenes remain
/// paintable while cancellable cache maintenance yields between bounded slices;
/// navigation and input never wait for that maintenance.
final class DashboardLogBoxPreparedSceneCache extends ChangeNotifier {
  DashboardLogBoxPreparedSceneCache({
    this.maximumPinnedRows = 8192,
    this.maximumRetainedScenes = 384,
    int? maximumStagingRows,
  }) : maximumStagingRows = maximumStagingRows ?? maximumPinnedRows * 2 {
    if (maximumPinnedRows <= 0 || maximumRetainedScenes <= 0) {
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
  final int maximumStagingRows;

  _DashboardLogBoxActiveSceneBank _activeBank =
      _DashboardLogBoxActiveSceneBank.empty();
  _DashboardLogBoxStagedSceneBank? _stagedBank;
  int _generation = 0;
  int _estimatedBytes = 0;
  int _peakStagingRowCount = 0;
  int _textLayoutMissCount = 0;
  int _readySceneIncompleteCount = 0;
  int _activeWindowPartialPublishCount = 0;
  int _stagingObjectRenderedCount = 0;
  int _preparationToken = 0;
  int _sceneReuseCount = 0;
  int _scenePrepareNewCount = 0;
  int _rowLayoutReuseCount = 0;
  int _rowLayoutNewCount = 0;
  int _lastPrepareUiIsolateMicros = 0;
  int _lastPrepareLargestContiguousUiSliceMicros = 0;
  int _lastPrepareYieldCount = 0;
  int _prepareNotifierCount = 0;
  int _preparationDepth = 0;
  bool _disposed = false;

  Map<int, DashboardPreparedLogBoxScene> get _scenes => _activeBank.scenes;
  Map<int, int> get _sceneRecency => _activeBank.sceneRecency;
  int get _sceneRecencyClock => _activeBank.sceneRecencyClock;
  Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> get _rowLayouts =>
      _activeBank.rowLayouts;
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
  int get preparedSceneCount => _scenes.length;
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
  double? get surfaceWidth => _surfaceWidth;
  int get activeWindowDigest => Object.hash(
    _activeWindow?.identity,
    _surfaceWidth,
    _devicePixelRatio,
    _activeManifest?.generation,
    Object.hashAll(_scenes.keys),
    Object.hashAll(_rowLayouts.keys),
    Object.hashAll(_dayHeaders.keys),
  );

  DashboardLogBoxSceneWindowManifest? get activeWindowManifest =>
      _activeManifest;
  DashboardLogBoxSceneWindowManifest? get stagedWindowManifest =>
      _stagedBank?.manifest;

  DashboardPreparedLogBoxScene? sceneFor(
    DashboardLogViewportState payload, {
    double? devicePixelRatio,
  }) {
    final scene = _scenes[payload.viewportId];
    if (scene == null ||
        !scene.matches(
          payload,
          _surfaceWidth,
          devicePixelRatio ?? _devicePixelRatio,
        )) {
      return null;
    }
    assert(scene.isCompletelyPrepared);
    return scene.isCompletelyPrepared ? scene : null;
  }

  void recordTextLayoutMiss() => _textLayoutMissCount += 1;

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
    DashboardLogBoxScenePreparationYield? yieldToBackground,
  }) async {
    _ensureUsable();
    if (yieldEveryRows <= 0) {
      throw ArgumentError.value(yieldEveryRows, 'yieldEveryRows');
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
    _discardStagedBank();
    _preparationDepth += 1;
    final createdRows = <DashboardPreparedLogBoxRowTextLayout>[];
    final createdHeaders = <TextPainter>[];
    TextPainter? createdEmpty;
    var uiIsolateMicros = 0;
    var largestContiguousUiSliceMicros = 0;
    var yieldCount = 0;
    var sliceStartedAt = developer.Timeline.now;

    void closeSlice() {
      final elapsed = developer.Timeline.now - sliceStartedAt;
      uiIsolateMicros += elapsed;
      largestContiguousUiSliceMicros = math.max(
        largestContiguousUiSliceMicros,
        elapsed,
      );
    }

    Future<void> checkpoint() async {
      closeSlice();
      yieldCount += 1;
      await (yieldToBackground ?? _yieldToEventLoop)();
      _ensureUsable();
      _throwIfPreparationSuperseded(preparationToken);
      sliceStartedAt = developer.Timeline.now;
    }

    try {
      // A controller-owned rotation is background work. Yield before the
      // first paragraph so a settle never inherits a synchronous text-layout
      // slice; direct startup warmup intentionally omits this scheduler.
      if (yieldToBackground != null) {
        await checkpoint();
      }
      // A different layout width must construct a wholly new bank. In
      // particular, it must never clear or mutate the still-paintable active
      // bank while that replacement is being prepared.
      final canReuseActiveBank =
          _surfaceWidth == width && _devicePixelRatio == devicePixelRatio;
      final retainedScene = !canReuseActiveBank || retainViewportId == null
          ? null
          : _scenes[retainViewportId];
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
          if (++scannedSinceYield == yieldEveryRows) {
            scannedSinceYield = 0;
            await checkpoint();
          }
        }
      }
      final retainedRows =
          retainedScene?._rowLayoutKeys ?? const <_RowLayoutKey>{};
      final activeRows = canReuseActiveBank
          ? <_RowLayoutKey>{
              for (final payload
                  in _activeWindow?.payloads ??
                      const <DashboardLogViewportState>[])
                for (final item in payload.flatItems)
                  _RowLayoutKey.fromRow(item.row),
            }
          : <_RowLayoutKey>{};
      // Text layouts are immutable and width-keyed. Retain them independently
      // of the active scene bank so A→B→A does not lay out identical text
      // again.
      final requiredPinnedRows = <_RowLayoutKey>{
        ...rowsByKey.keys,
        ...retainedRows,
        ...activeRows,
      };
      if (requiredPinnedRows.length > maximumPinnedRows) {
        throw StateError(
          'Prepared LogBox scene window exceeds $maximumPinnedRows retained '
          'row layouts: ${requiredPinnedRows.length}.',
        );
      }
      // Keep bounded reusable rows after the hot target. The active and staged
      // scenes remain protected above; colder text layouts are evicted only
      // when the cache budget actually requires it.
      final finalRows = <_RowLayoutKey>{...requiredPinnedRows};
      for (final key in _rowLayouts.keys) {
        if (finalRows.length == maximumPinnedRows) break;
        finalRows.add(key);
      }
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
      final nextHeaders = canReuseActiveBank
          ? <String, TextPainter>{..._dayHeaders}
          : <String, TextPainter>{};
      if (retainedScene != null) {
        for (final key in retainedScene._rowLayoutKeys) {
          final layout = _rowLayouts[key];
          if (layout != null) nextRows[key] = layout;
        }
        for (final label in retainedScene._dayHeaderLabels) {
          final painter = _dayHeaders[label];
          if (painter != null) nextHeaders[label] = painter;
        }
      }

      var preparedSinceYield = 0;
      for (final entry in rowsByKey.entries) {
        final old = canReuseActiveBank ? _rowLayouts[entry.key] : null;
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
        if (++preparedSinceYield == yieldEveryRows) {
          preparedSinceYield = 0;
          await checkpoint();
        }
      }
      var headersSinceYield = 0;
      for (final label in headerLabels) {
        final old = canReuseActiveBank ? _dayHeaders[label] : null;
        if (old != null) {
          nextHeaders[label] = old;
        } else {
          final prepared = _headerPainter(label, width);
          createdHeaders.add(prepared);
          nextHeaders[label] = prepared;
        }
        if (++headersSinceYield == yieldEveryRows) {
          headersSinceYield = 0;
          await checkpoint();
        }
      }
      final nextEmpty = canReuseActiveBank && _empty != null
          ? _empty!
          : _emptyPainter(width);
      if (!identical(_empty, nextEmpty)) createdEmpty = nextEmpty;

      final nextScenes = <int, DashboardPreparedLogBoxScene>{
        for (final entry
            in canReuseActiveBank
                ? _scenes.entries
                : const <MapEntry<int, DashboardPreparedLogBoxScene>>[])
          if (entry.value._rowLayoutKeys.every(nextRows.containsKey))
            entry.key: entry.value,
      };
      final nextSceneRecency = <int, int>{..._sceneRecency};
      nextSceneRecency.removeWhere(
        (viewportId, _) => !nextScenes.containsKey(viewportId),
      );
      var nextSceneRecencyClock = _sceneRecencyClock;
      void touchStagedScene(int viewportId) {
        nextSceneRecency[viewportId] = ++nextSceneRecencyClock;
      }

      if (retainedScene != null) {
        nextScenes[retainedScene.viewportId] = retainedScene;
      }
      // [yieldEveryRows] is a work-unit contract, not a scene-count
      // contract. A single bounded preview scene can contain 24 rows, so
      // counting eight scenes here used to compose as many as 192 row maps in
      // one UI-isolate slice despite the coordinator requesting eight-row
      // chunks. Keep a large individual scene intact for atomic local
      // construction, but never accumulate another scene past the budget.
      var sceneRowsSinceYield = 0;
      for (final payload in window.payloads) {
        final sceneWorkUnits = math.max(1, payload.flatItems.length);
        if (sceneRowsSinceYield > 0 &&
            sceneRowsSinceYield + sceneWorkUnits > yieldEveryRows) {
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
            ? _scenes[payload.viewportId]
            : null;
        if (existing != null && existing.matches(payload, width)) {
          _sceneReuseCount += 1;
          nextScenes[payload.viewportId] = existing;
          touchStagedScene(payload.viewportId);
        } else {
          _scenePrepareNewCount += 1;
          nextScenes[payload.viewportId] = DashboardPreparedLogBoxScene._(
            payload: payload,
            surfaceWidth: width,
            devicePixelRatio: devicePixelRatio,
            rowLayouts: rows,
            rowLayoutKeys: <_RowLayoutKey>{
              for (final item in payload.flatItems)
                _RowLayoutKey.fromRow(item.row),
            },
            dayHeaders: <String, TextPainter>{
              for (final label in labels) label: nextHeaders[label]!,
            },
            empty: nextEmpty,
          );
          touchStagedScene(payload.viewportId);
        }
        sceneRowsSinceYield += sceneWorkUnits;
        if (sceneRowsSinceYield >= yieldEveryRows) {
          sceneRowsSinceYield = 0;
          await checkpoint();
        }
      }
      _evictScenesToCapacity(
        scenes: nextScenes,
        recency: nextSceneRecency,
        protectedViewportIds: <int>{
          ...?(_activeWindow?.payloads.map((payload) => payload.viewportId)),
          ...window.payloads.map((payload) => payload.viewportId),
          if (retainedScene != null) retainedScene.viewportId,
        },
      );

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
            (payload) =>
                nextScenes[payload.viewportId]?.matches(payload, width) ??
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
      _stagedBank = _DashboardLogBoxStagedSceneBank(
        window: window,
        scenes: nextScenes,
        sceneRecency: nextSceneRecency,
        sceneRecencyClock: nextSceneRecencyClock,
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
      closeSlice();
      _lastPrepareUiIsolateMicros = uiIsolateMicros;
      _lastPrepareLargestContiguousUiSliceMicros =
          largestContiguousUiSliceMicros;
      _lastPrepareYieldCount = yieldCount;
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
              'rowLayoutNew=$_rowLayoutNewCount '
              'rowLayoutReuse=$_rowLayoutReuseCount '
              'sceneNew=$_scenePrepareNewCount '
              'sceneReuse=$_sceneReuseCount semanticsWork=0 rasterWork=0 '
              'allocationCount=${createdRows.length + createdHeaders.length + _scenePrepareNewCount}',
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

  void activateWindow(DashboardLogBoxSceneWindow window) {
    _ensureUsable();
    final staged = _stagedBank;
    final complete =
        staged != null &&
        staged.window.identity == window.identity &&
        staged.manifest.isComplete &&
        window.payloads.every(
          (payload) =>
              staged.scenes[payload.viewportId]?.matches(
                payload,
                staged.surfaceWidth,
                staged.devicePixelRatio,
              ) ??
              false,
        );
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
      sceneRecency: staged.sceneRecency,
      sceneRecencyClock: staged.sceneRecencyClock,
      rowLayouts: staged.rowLayouts,
      dayHeaders: staged.dayHeaders,
      empty: staged.empty,
      surfaceWidth: staged.surfaceWidth,
      devicePixelRatio: staged.devicePixelRatio,
    );
    _stagedBank = null;
    for (final payload in window.payloads) {
      _touchScene(payload.viewportId);
    }
    _generation += 1;
    _estimatedBytes = _estimateBytes(_rowLayouts.keys, _dayHeaders.keys);
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
    'maximumPinnedRows': maximumPinnedRows,
    'maximumRetainedScenes': maximumRetainedScenes,
    'maximumStagingRows': maximumStagingRows,
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
    required Map<int, DashboardPreparedLogBoxScene> scenes,
    required Map<int, int> sceneRecency,
    required int sceneRecencyClock,
    required Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>
    rowLayouts,
    required Map<String, TextPainter> dayHeaders,
    required TextPainter empty,
    required double surfaceWidth,
    required double devicePixelRatio,
  }) {
    for (final entry in _rowLayouts.entries) {
      if (!identical(rowLayouts[entry.key], entry.value)) entry.value.dispose();
    }
    for (final entry in _dayHeaders.entries) {
      if (!identical(dayHeaders[entry.key], entry.value)) entry.value.dispose();
    }
    if (!identical(_empty, empty)) _empty?.dispose();
    _activeBank = _DashboardLogBoxActiveSceneBank(
      window: window,
      manifest: manifest,
      scenes: scenes,
      sceneRecency: sceneRecency,
      sceneRecencyClock: sceneRecencyClock,
      rowLayouts: rowLayouts,
      dayHeaders: dayHeaders,
      empty: empty,
      surfaceWidth: surfaceWidth,
      devicePixelRatio: devicePixelRatio,
    );
  }

  void _touchScene(int viewportId) {
    final recency = Map<int, int>.from(_sceneRecency)
      ..[viewportId] = _sceneRecencyClock + 1;
    _activeBank = _activeBank.copyWith(
      sceneRecency: recency,
      sceneRecencyClock: _sceneRecencyClock + 1,
    );
  }

  void _evictScenesToCapacity({
    required Map<int, DashboardPreparedLogBoxScene> scenes,
    required Map<int, int> recency,
    required Set<int> protectedViewportIds,
  }) {
    if (protectedViewportIds.length > maximumRetainedScenes) {
      throw StateError(
        'Prepared LogBox hot scene set exceeds $maximumRetainedScenes scenes: '
        '${protectedViewportIds.length}.',
      );
    }
    while (scenes.length > maximumRetainedScenes) {
      int? victim;
      var oldest = 1 << 62;
      for (final viewportId in scenes.keys) {
        if (protectedViewportIds.contains(viewportId)) continue;
        final sceneRecency = recency[viewportId] ?? 0;
        if (sceneRecency < oldest) {
          oldest = sceneRecency;
          victim = viewportId;
        }
      }
      if (victim == null) {
        throw StateError('No evictable prepared LogBox scene remains.');
      }
      scenes.remove(victim);
      recency.remove(victim);
    }
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

  /// Establishes an async boundary between bounded structural preparation
  /// chunks without depending on a frame, timer, paint, semantics, or user
  /// interaction callback. A scene still cannot activate before every chunk
  /// has completed.
  ///
  /// A microtask is deliberate here: a timer/event-loop yield would deadlock a
  /// direct bootstrap await under Flutter's FakeAsync test clock unless a
  /// second, unrelated frame were pumped.
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
    Iterable<String> headers,
  ) {
    var utf16Units = 0;
    for (final key in rowKeys) {
      utf16Units += key.textUnits;
    }
    for (final header in headers) {
      utf16Units += header.length;
    }
    return preparedRowCount * 2048 + utf16Units * 2;
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
    for (final layout in _rowLayouts.values) {
      layout.dispose();
    }
    for (final painter in _dayHeaders.values) {
      painter.dispose();
    }
    _empty?.dispose();
    _activeBank = _DashboardLogBoxActiveSceneBank.empty();
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
final class _DashboardLogBoxActiveSceneBank {
  _DashboardLogBoxActiveSceneBank({
    required this.window,
    required this.manifest,
    required Map<int, DashboardPreparedLogBoxScene> scenes,
    required Map<int, int> sceneRecency,
    required this.sceneRecencyClock,
    required Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>
    rowLayouts,
    required Map<String, TextPainter> dayHeaders,
    required this.empty,
    required this.surfaceWidth,
    required this.devicePixelRatio,
  }) : scenes = Map<int, DashboardPreparedLogBoxScene>.unmodifiable(scenes),
       sceneRecency = Map<int, int>.unmodifiable(sceneRecency),
       rowLayouts =
           Map<
             _RowLayoutKey,
             DashboardPreparedLogBoxRowTextLayout
           >.unmodifiable(rowLayouts),
       dayHeaders = Map<String, TextPainter>.unmodifiable(dayHeaders);

  factory _DashboardLogBoxActiveSceneBank.empty() =>
      _DashboardLogBoxActiveSceneBank(
        window: null,
        manifest: null,
        scenes: const <int, DashboardPreparedLogBoxScene>{},
        sceneRecency: const <int, int>{},
        sceneRecencyClock: 0,
        rowLayouts:
            const <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{},
        dayHeaders: const <String, TextPainter>{},
        empty: null,
        surfaceWidth: null,
        devicePixelRatio: null,
      );

  final DashboardLogBoxSceneWindow? window;
  final DashboardLogBoxSceneWindowManifest? manifest;
  final Map<int, DashboardPreparedLogBoxScene> scenes;
  final Map<int, int> sceneRecency;
  final int sceneRecencyClock;
  final Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> rowLayouts;
  final Map<String, TextPainter> dayHeaders;
  final TextPainter? empty;
  final double? surfaceWidth;
  final double? devicePixelRatio;

  _DashboardLogBoxActiveSceneBank copyWith({
    required Map<int, int> sceneRecency,
    required int sceneRecencyClock,
  }) => _DashboardLogBoxActiveSceneBank(
    window: window,
    manifest: manifest,
    scenes: scenes,
    sceneRecency: sceneRecency,
    sceneRecencyClock: sceneRecencyClock,
    rowLayouts: rowLayouts,
    dayHeaders: dayHeaders,
    empty: empty,
    surfaceWidth: surfaceWidth,
    devicePixelRatio: devicePixelRatio,
  );
}

/// Private, mutable-only-during-build replacement bank. It has no renderer
/// entry point; ownership transfers to the active bank exactly once on a
/// successful activation, otherwise only resources created by this build are
/// released.
final class _DashboardLogBoxStagedSceneBank {
  _DashboardLogBoxStagedSceneBank({
    required this.window,
    required Map<int, DashboardPreparedLogBoxScene> scenes,
    required Map<int, int> sceneRecency,
    required this.sceneRecencyClock,
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
  }) : scenes = Map<int, DashboardPreparedLogBoxScene>.unmodifiable(scenes),
       sceneRecency = Map<int, int>.unmodifiable(sceneRecency),
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
  final Map<int, DashboardPreparedLogBoxScene> scenes;
  final Map<int, int> sceneRecency;
  final int sceneRecencyClock;
  final Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> rowLayouts;
  final Map<String, TextPainter> dayHeaders;
  final TextPainter empty;
  final double surfaceWidth;
  final double devicePixelRatio;
  final DashboardLogBoxSceneWindowManifest manifest;
  final List<DashboardPreparedLogBoxRowTextLayout> _ownedRows;
  final List<TextPainter> _ownedHeaders;
  final TextPainter? ownedEmpty;

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

@immutable
final class DashboardPreparedLogBoxScene {
  DashboardPreparedLogBoxScene._({
    required this.payload,
    required this.surfaceWidth,
    required this.devicePixelRatio,
    required Map<String, DashboardPreparedLogBoxRowTextLayout> rowLayouts,
    required Set<_RowLayoutKey> rowLayoutKeys,
    required Map<String, TextPainter> dayHeaders,
    required this.empty,
  }) : _rowLayouts =
           Map<String, DashboardPreparedLogBoxRowTextLayout>.unmodifiable(
             rowLayouts,
           ),
       _dayHeaders = Map<String, TextPainter>.unmodifiable(dayHeaders),
       _rowLayoutKeys = Set<_RowLayoutKey>.unmodifiable(rowLayoutKeys),
       _dayHeaderLabels = Set<String>.unmodifiable(dayHeaders.keys),
       contentIdentity = _contentIdentity(payload);

  final DashboardLogViewportState payload;
  final double surfaceWidth;
  final double devicePixelRatio;
  final int contentIdentity;
  final Map<String, DashboardPreparedLogBoxRowTextLayout> _rowLayouts;
  final Map<String, TextPainter> _dayHeaders;
  final Set<_RowLayoutKey> _rowLayoutKeys;
  final Set<String> _dayHeaderLabels;
  final TextPainter empty;

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
      other.viewportId == viewportId &&
      _contentIdentity(other) == contentIdentity;

  static int _contentIdentity(DashboardLogViewportState payload) =>
      Object.hashAll(<Object?>[
        payload.queryKey,
        payload.revision,
        payload.viewportId,
        for (final item in payload.flatItems) item.row.textLayoutId,
        for (final item in payload.flatItems) item.dayLabel,
      ]);
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
