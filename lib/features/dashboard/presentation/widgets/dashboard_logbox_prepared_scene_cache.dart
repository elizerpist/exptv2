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
/// privately, then swaps it atomically. This lets the old visible scene remain
/// complete while the application controller has input gated; a rail crossing
/// can therefore only select an already prepared scene.
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

  Map<int, DashboardPreparedLogBoxScene> _scenes =
      <int, DashboardPreparedLogBoxScene>{};
  Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout> _rowLayouts =
      <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{};
  Map<String, TextPainter> _dayHeaders = <String, TextPainter>{};
  TextPainter? _empty;
  double? _surfaceWidth;
  DashboardLogBoxSceneWindow? _activeWindow;
  DashboardLogBoxSceneWindow? _stagedWindow;
  int _generation = 0;
  int _estimatedBytes = 0;
  int _peakStagingRowCount = 0;
  int _textLayoutMissCount = 0;
  bool _preparing = false;
  bool _disposed = false;

  int get generation => _generation;
  int get preparedRowCount => _rowLayouts.length;
  int get preparedDayHeaderCount => _dayHeaders.length;
  int get estimatedBytes => _estimatedBytes;
  int get peakStagingRowCount => _peakStagingRowCount;
  int get textLayoutMissCount => _textLayoutMissCount;
  int get preparedSceneCount => _scenes.length;
  bool get isPreparing => _preparing;
  String? get activeWindowIdentity => _activeWindow?.identity;
  String? get stagedWindowIdentity => _stagedWindow?.identity;
  double? get surfaceWidth => _surfaceWidth;

  DashboardPreparedLogBoxScene? sceneFor(DashboardLogViewportState payload) {
    final scene = _scenes[payload.viewportId];
    return scene != null && scene.matches(payload, _surfaceWidth)
        ? scene
        : null;
  }

  void recordTextLayoutMiss() => _textLayoutMissCount += 1;

  /// Prepares but does not make [window] the active structural bank. During a
  /// parent rotation the controller retains the currently visible scene until
  /// it can commit the new prepared window.
  Future<void> prepareWindow({
    required DashboardLogBoxSceneWindow window,
    double? surfaceWidth,
    int? retainViewportId,
    int yieldEveryRows = 64,
  }) async {
    _ensureUsable();
    if (yieldEveryRows <= 0) {
      throw ArgumentError.value(yieldEveryRows, 'yieldEveryRows');
    }
    final width = _resolveSurfaceWidth(surfaceWidth);
    final startedAt = DateTime.now();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'SCENE_WINDOW_PREPARE_STARTED',
        queryKey: window.identity,
        entryCount: window.previewRowCount,
      ),
    );
    final requiredRows = _requiredRowKeys(window.payloads);
    final retainedScene = retainViewportId == null
        ? null
        : _scenes[retainViewportId];
    final retainedRows =
        retainedScene?._rowLayoutKeys ?? const <_RowLayoutKey>{};
    final finalRows = <_RowLayoutKey>{...requiredRows, ...retainedRows};
    if (finalRows.length > maximumPinnedRows) {
      throw StateError(
        'Prepared LogBox scene window exceeds $maximumPinnedRows retained '
        'row layouts: ${finalRows.length}.',
      );
    }
    final finalScenes = window.sceneCount + (retainedScene == null ? 0 : 1);
    if (finalScenes > maximumRetainedScenes) {
      throw StateError(
        'Prepared LogBox scene window exceeds $maximumRetainedScenes scenes: '
        '$finalScenes.',
      );
    }
    final stagingRows = _rowLayouts.length + requiredRows.length;
    _peakStagingRowCount = math.max(_peakStagingRowCount, stagingRows);
    if (stagingRows > maximumStagingRows) {
      throw StateError(
        'Prepared LogBox scene rotation exceeds $maximumStagingRows staging '
        'row layouts: $stagingRows.',
      );
    }

    _preparing = true;
    try {
      final nextRows = <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{};
      final nextHeaders = <String, TextPainter>{};
      final rowsByKey = <_RowLayoutKey, DashboardLogRowViewModel>{};
      final headerLabels = <String>{};
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
        }
      }
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
        final old = _rowLayouts[entry.key];
        nextRows[entry.key] =
            old ??
            DashboardPreparedLogBoxRowTextLayout.prepare(
              row: entry.value,
              surfaceWidth: width,
              contentIdentity: entry.value.textLayoutId,
            );
        if (old == null && ++preparedSinceYield == yieldEveryRows) {
          preparedSinceYield = 0;
          await _yieldToEventLoop();
          _ensureUsable();
        }
      }
      for (final label in headerLabels) {
        nextHeaders[label] = _dayHeaders[label] ?? _headerPainter(label, width);
      }
      final nextEmpty = _empty ?? _emptyPainter(width);

      final nextScenes = <int, DashboardPreparedLogBoxScene>{};
      if (retainedScene != null) {
        nextScenes[retainedScene.viewportId] = retainedScene;
      }
      for (final payload in window.payloads) {
        final rows = <String, DashboardPreparedLogBoxRowTextLayout>{
          for (final item in payload.flatItems)
            item.row.entryId: nextRows[_RowLayoutKey.fromRow(item.row)]!,
        };
        final labels = <String>{
          for (final item in payload.flatItems)
            if (item.dayLabel case final String label) label,
        };
        nextScenes[payload.viewportId] = DashboardPreparedLogBoxScene._(
          payload: payload,
          surfaceWidth: width,
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
      }

      _replaceBank(
        scenes: nextScenes,
        rowLayouts: nextRows,
        dayHeaders: nextHeaders,
        empty: nextEmpty,
        surfaceWidth: width,
      );
      _stagedWindow = window;
      _generation += 1;
      _estimatedBytes = _estimateBytes(nextRows.keys, nextHeaders.keys);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'SCENE_WINDOW_PREPARE_COMPLETED',
          queryKey: window.identity,
          entryCount: window.previewRowCount,
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
        ),
      );
      notifyListeners();
    } finally {
      _preparing = false;
    }
  }

  void activateWindow(DashboardLogBoxSceneWindow window) {
    _ensureUsable();
    if (_stagedWindow?.identity != window.identity ||
        !window.payloads.every((payload) => sceneFor(payload) != null)) {
      throw StateError(
        'A LogBox scene window may activate only after completion.',
      );
    }
    _activeWindow = window;
    _stagedWindow = null;
    final keep = window.payloads.map((payload) => payload.viewportId).toSet();
    _retainOnly(keep);
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
    'state': _preparing ? 'preparing' : 'ready',
    'activeWindow': _activeWindow?.identity,
    'stagedWindow': _stagedWindow?.identity,
    'preparedScenes': preparedSceneCount,
    'preparedTextRows': preparedRowCount,
    'preparedDayHeaders': preparedDayHeaderCount,
    'sceneCacheBytes': estimatedBytes,
    'textLayoutMisses': textLayoutMissCount,
    'maximumPinnedRows': maximumPinnedRows,
    'maximumRetainedScenes': maximumRetainedScenes,
    'maximumStagingRows': maximumStagingRows,
    'peakStagingRows': peakStagingRowCount,
  };

  void _replaceBank({
    required Map<int, DashboardPreparedLogBoxScene> scenes,
    required Map<_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>
    rowLayouts,
    required Map<String, TextPainter> dayHeaders,
    required TextPainter empty,
    required double surfaceWidth,
  }) {
    for (final entry in _rowLayouts.entries) {
      if (!identical(rowLayouts[entry.key], entry.value)) entry.value.dispose();
    }
    for (final entry in _dayHeaders.entries) {
      if (!identical(dayHeaders[entry.key], entry.value)) entry.value.dispose();
    }
    if (!identical(_empty, empty)) _empty?.dispose();
    _scenes = scenes;
    _rowLayouts = rowLayouts;
    _dayHeaders = dayHeaders;
    _empty = empty;
    _surfaceWidth = surfaceWidth;
  }

  void _retainOnly(Set<int> viewportIds) {
    if (_scenes.keys.every(viewportIds.contains)) return;
    final nextScenes = <int, DashboardPreparedLogBoxScene>{
      for (final entry in _scenes.entries)
        if (viewportIds.contains(entry.key)) entry.key: entry.value,
    };
    final rowKeys = <_RowLayoutKey>{
      for (final scene in nextScenes.values) ...scene._rowLayoutKeys,
    };
    final headerLabels = <String>{
      for (final scene in nextScenes.values) ...scene._dayHeaderLabels,
    };
    _replaceBank(
      scenes: nextScenes,
      rowLayouts: <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{
        for (final key in rowKeys) key: _rowLayouts[key]!,
      },
      dayHeaders: <String, TextPainter>{
        for (final label in headerLabels) label: _dayHeaders[label]!,
      },
      empty: _empty!,
      surfaceWidth: _surfaceWidth!,
    );
  }

  Set<_RowLayoutKey> _requiredRowKeys(
    Iterable<DashboardLogViewportState> payloads,
  ) => <_RowLayoutKey>{
    for (final payload in payloads)
      for (final item in payload.flatItems) _RowLayoutKey.fromRow(item.row),
  };

  double _resolveSurfaceWidth(double? supplied) {
    if (supplied != null) {
      if (!supplied.isFinite || supplied <= 0) {
        throw ArgumentError.value(supplied, 'surfaceWidth');
      }
      if (_surfaceWidth != null && _surfaceWidth != supplied) _clear();
      _surfaceWidth = supplied;
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

  void _ensureUsable() {
    if (_disposed) throw StateError('Prepared LogBox scene cache is disposed.');
  }

  void _clear() {
    for (final layout in _rowLayouts.values) {
      layout.dispose();
    }
    for (final painter in _dayHeaders.values) {
      painter.dispose();
    }
    _empty?.dispose();
    _scenes = <int, DashboardPreparedLogBoxScene>{};
    _rowLayouts = <_RowLayoutKey, DashboardPreparedLogBoxRowTextLayout>{};
    _dayHeaders = <String, TextPainter>{};
    _empty = null;
    _activeWindow = null;
    _stagedWindow = null;
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

@immutable
final class DashboardPreparedLogBoxScene {
  DashboardPreparedLogBoxScene._({
    required this.payload,
    required this.surfaceWidth,
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
  final int contentIdentity;
  final Map<String, DashboardPreparedLogBoxRowTextLayout> _rowLayouts;
  final Map<String, TextPainter> _dayHeaders;
  final Set<_RowLayoutKey> _rowLayoutKeys;
  final Set<String> _dayHeaderLabels;
  final TextPainter empty;

  int get viewportId => payload.viewportId;

  DashboardPreparedLogBoxRowTextLayout? rowFor(DashboardLogRowViewModel row) {
    final layout = _rowLayouts[row.entryId];
    return layout != null && layout.contentIdentity == row.textLayoutId
        ? layout
        : null;
  }

  TextPainter? dayHeaderFor(String label) => _dayHeaders[label];

  bool matches(DashboardLogViewportState other, double? width) =>
      width == surfaceWidth &&
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
