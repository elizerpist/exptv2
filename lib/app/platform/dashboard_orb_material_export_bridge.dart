import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

/// Foreground bridge from Dashboard's authoritative material renderer to the
/// persisted native AppWidget frame bundle. It listens to semantic material
/// publications, never to the Header paint ticker.
final class DashboardHeaderOrbMaterialExportCoordinator {
  DashboardHeaderOrbMaterialExportCoordinator({
    required DashboardHeaderVisualController controller,
    required this.balanceFrame,
    required this.budgetFrame,
    required this.mindFrame,
    MethodChannel? channel,
  }) : _controller = controller,
       _channel = channel ?? const MethodChannel(_channelName) {
    _controller.tuning.addListener(schedule);
    balanceFrame.addListener(schedule);
    budgetFrame.addListener(schedule);
    mindFrame.addListener(schedule);
  }

  static const _channelName = 'fluvi/orb_material_frames';

  final DashboardHeaderVisualController _controller;
  final ValueListenable<DashboardHeaderVisualFrame> balanceFrame;
  final ValueListenable<DashboardHeaderVisualFrame> budgetFrame;
  final ValueListenable<DashboardHeaderVisualFrame> mindFrame;
  final MethodChannel _channel;

  Timer? _debounce;
  Size? _headerSize;
  double _devicePixelRatio = 1;
  var _exporting = false;
  var _requestedWhileExporting = false;
  var _disposed = false;

  /// Uses Dashboard's actual Header bounds. The orb mapper later maps the
  /// entire normalized rectangle to a circle, retaining both palette ends.
  void updateHeaderGeometry({
    required Size size,
    required double devicePixelRatio,
  }) {
    if (_disposed || size.isEmpty) return;
    final dpr = devicePixelRatio.isFinite && devicePixelRatio > 0
        ? devicePixelRatio
        : 1.0;
    if (_headerSize == size && _devicePixelRatio == dpr) return;
    _headerSize = size;
    _devicePixelRatio = dpr;
    schedule();
  }

  void schedule() {
    if (_disposed) return;
    if (_exporting) {
      _requestedWhileExporting = true;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      unawaited(_export());
    });
  }

  Future<void> _export() async {
    final size = _headerSize;
    if (_disposed || size == null || _exporting) return;
    _exporting = true;
    try {
      final scenes = await _channel.invokeListMethod<Object?>(
        'configuredScenes',
      );
      if (scenes == null || scenes.isEmpty || _disposed) return;
      for (final raw in scenes) {
        if (_disposed || raw is! Map<Object?, Object?>) continue;
        final widgetId = raw['widgetId'] as int?;
        final revision = raw['configurationRevision'] as int?;
        final mode = raw['mode'] as String?;
        final orbSize = raw['frameSizePx'] as int?;
        if (widgetId == null ||
            revision == null ||
            mode == null ||
            orbSize == null) {
          continue;
        }
        // This handover deliberately enables only Balance. Budget's category
        // and per-axis scene resolver is not yet available off-screen; using
        // the currently visible Budget frame for another widget would publish
        // the wrong material. Its existing last-good package/fallback remains
        // intact until that resolver is introduced.
        if (mode != 'balance') continue;
        final frame = switch (mode) {
          'balance' => balanceFrame.value,
          _ => null,
        };
        if (frame == null) continue;
        await _publishScene(
          widgetId: widgetId,
          configurationRevision: revision,
          mode: mode,
          targetSizePx: orbSize,
          frame: frame,
          headerSize: size,
        );
      }
    } on MissingPluginException {
      // Non-Android and isolated widget-test hosts have no frame sink.
    } on PlatformException {
      // A widget can disappear while a foreground export is in flight.
    } finally {
      _exporting = false;
      if (_requestedWhileExporting && !_disposed) {
        _requestedWhileExporting = false;
        schedule();
      }
    }
  }

  Future<void> _publishScene({
    required int widgetId,
    required int configurationRevision,
    required String mode,
    required int targetSizePx,
    required DashboardHeaderVisualFrame frame,
    required Size headerSize,
  }) async {
    final snapshot = DashboardHeaderMaterialSnapshot.capture(
      controller: _controller,
      frame: frame,
    );
    final frameCount = snapshot.isAnimated ? 24 : 1;
    final intervalMs = snapshot.isAnimated
        ? (snapshot.characteristicCycleMs / frameCount).round().clamp(40, 60000)
        : 1000;
    final renderer = DashboardHeaderMaterialFrameRenderer();
    try {
      final frames = <Uint8List>[];
      Uint8List? firstOrbRgba;
      for (var index = 0; index < frameCount; index += 1) {
        final header = await renderer.render(
          snapshot: snapshot,
          headerSize: headerSize,
          devicePixelRatio: _devicePixelRatio,
          offset: Duration(milliseconds: intervalMs * index),
        );
        try {
          final orb = await DashboardHeaderOrbFrameMapper.map(
            header: header,
            orbSizePx: targetSizePx,
          );
          try {
            if (index == 0) {
              final rgba = await orb.toByteData(
                format: ImageByteFormat.rawRgba,
              );
              if (rgba == null) throw StateError('Orb RGBA encoding failed.');
              firstOrbRgba = Uint8List.fromList(rgba.buffer.asUint8List());
            }
            final bytes = await orb.toByteData(format: ImageByteFormat.png);
            if (bytes == null) throw StateError('Orb PNG encoding failed.');
            frames.add(bytes.buffer.asUint8List());
          } finally {
            orb.dispose();
          }
        } finally {
          header.dispose();
        }
      }
      final loopDurationMs = intervalMs * frameCount;
      final seamMeanRgbDelta = snapshot.isAnimated
          ? await _loopSeamMeanRgbDelta(
              renderer: renderer,
              snapshot: snapshot,
              headerSize: headerSize,
              targetSizePx: targetSizePx,
              firstOrbRgba: firstOrbRgba!,
              loopDuration: Duration(milliseconds: loopDurationMs),
            )
          : 0.0;
      final seamDescription = snapshot.isAnimated
          ? seamMeanRgbDelta >= 2
                ? 'repeat=visible-sampling-seam'
                : 'repeat=continuous-within-sample-threshold'
          : 'repeat=static';
      await _channel.invokeMethod<void>('publishFrames', <String, Object>{
        'widgetId': widgetId,
        'configurationRevision': configurationRevision,
        'intervalMs': intervalMs,
        'sourceDescription':
            'DashboardHeaderMaterialFrameRenderer; mode=$mode; '
            'effect=${snapshot.tuning.effect.name}; '
            'targetCycleMs=${snapshot.characteristicCycleMs}; '
            'loopMs=$loopDurationMs; '
            'sampling=${frameCount}x${intervalMs}ms; '
            'loopSeamMeanRgb=${seamMeanRgbDelta.toStringAsFixed(2)}; '
            '$seamDescription',
        'frames': frames,
      });
    } finally {
      renderer.dispose();
    }
  }

  Future<double> _loopSeamMeanRgbDelta({
    required DashboardHeaderMaterialFrameRenderer renderer,
    required DashboardHeaderMaterialSnapshot snapshot,
    required Size headerSize,
    required int targetSizePx,
    required Uint8List firstOrbRgba,
    required Duration loopDuration,
  }) async {
    final header = await renderer.render(
      snapshot: snapshot,
      headerSize: headerSize,
      devicePixelRatio: _devicePixelRatio,
      offset: loopDuration,
    );
    try {
      final orb = await DashboardHeaderOrbFrameMapper.map(
        header: header,
        orbSizePx: targetSizePx,
      );
      try {
        final data = await orb.toByteData(format: ImageByteFormat.rawRgba);
        if (data == null) throw StateError('Orb seam RGBA encoding failed.');
        return _meanRgbDelta(firstOrbRgba, data.buffer.asUint8List());
      } finally {
        orb.dispose();
      }
    } finally {
      header.dispose();
    }
  }

  static double _meanRgbDelta(Uint8List first, Uint8List repeated) {
    if (first.length != repeated.length || first.length % 4 != 0) {
      throw ArgumentError('Mismatched orb frame pixels for loop seam check.');
    }
    var total = 0;
    var samples = 0;
    for (var index = 0; index < first.length; index += 4) {
      // The transparent square corners are not part of the visible orb.
      if (first[index + 3] == 0 || repeated[index + 3] == 0) continue;
      total += (first[index] - repeated[index]).abs();
      total += (first[index + 1] - repeated[index + 1]).abs();
      total += (first[index + 2] - repeated[index + 2]).abs();
      samples += 3;
    }
    return samples == 0 ? 0 : total / samples;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _debounce?.cancel();
    _controller.tuning.removeListener(schedule);
    balanceFrame.removeListener(schedule);
    budgetFrame.removeListener(schedule);
    mindFrame.removeListener(schedule);
  }
}
