import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'dashboard_orb_material_playback_profile.dart';

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
    _controller.portalSettingsGeneration.addListener(schedule);
    _controller.orbExportCommitGeneration.addListener(_scheduleFinal);
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
  var _requestedGeneration = 0;
  var _disposed = false;
  final Map<int, DateTime> _requestedAt = <int, DateTime>{};
  final LinkedHashMap<String, _CachedOrbMaterialPackage> _frameCache =
      LinkedHashMap<String, _CachedOrbMaterialPackage>();

  // A short debounce coalesces slider drag samples, but no longer hides the
  // completed choice behind the old 180 ms delay. Generation checks below
  // give the newest value priority if A → B → C arrives during an export.
  static const _settingsDebounce = Duration(milliseconds: 48);
  static const _starterFrameCount = 8;
  static const _maximumCachedEncodedBytes = 2 * 1024 * 1024;

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
    _requestedGeneration += 1;
    _requestedAt[_requestedGeneration] = DateTime.now();
    _requestedAt.removeWhere(
      (generation, _) => generation < _requestedGeneration - 2,
    );
    if (_exporting) {
      _requestedWhileExporting = true;
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(_settingsDebounce, () {
      unawaited(_export(_requestedGeneration));
    });
  }

  void _scheduleFinal() {
    if (_disposed) return;
    _requestedGeneration += 1;
    _requestedAt[_requestedGeneration] = DateTime.now();
    _requestedAt.removeWhere(
      (generation, _) => generation < _requestedGeneration - 2,
    );
    _debounce?.cancel();
    if (_exporting) {
      _requestedWhileExporting = true;
      return;
    }
    unawaited(_export(_requestedGeneration));
  }

  Future<void> _export(int generation) async {
    final size = _headerSize;
    if (_disposed || size == null || _exporting) return;
    _exporting = true;
    final requestedAt = _requestedAt[generation] ?? DateTime.now();
    final debounceMs = DateTime.now().difference(requestedAt).inMilliseconds;
    final sceneQuery = Stopwatch()..start();
    try {
      final scenes = await _channel.invokeListMethod<Object?>(
        'configuredScenes',
      );
      sceneQuery.stop();
      if (scenes == null ||
          scenes.isEmpty ||
          _disposed ||
          !_isCurrent(generation)) {
        return;
      }
      for (final raw in scenes) {
        if (_disposed ||
            !_isCurrent(generation) ||
            raw is! Map<Object?, Object?>) {
          return;
        }
        final widgetId = raw['widgetId'] as int?;
        final revision = raw['configurationRevision'] as int?;
        final mode = raw['mode'] as String?;
        final orbSize = raw['frameSizePx'] as int?;
        final cacheVersion = raw['cacheVersion'] as int?;
        final maximumFrameCount = raw['maximumFrameCount'] as int?;
        final maximumDecodedBytes = raw['maximumDecodedBytes'] as int?;
        final requiresAlphaMask = raw['requiresAlphaMask'] as bool? ?? false;
        if (widgetId == null ||
            revision == null ||
            mode == null ||
            orbSize == null ||
            cacheVersion != dashboardOrbMaterialCacheVersion ||
            maximumFrameCount == null ||
            maximumDecodedBytes == null) {
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
          maximumFrameCount: maximumFrameCount,
          maximumDecodedBytes: maximumDecodedBytes,
          requiresAlphaMask: requiresAlphaMask,
          isCurrent: () => _isCurrent(generation),
          frame: frame,
          headerSize: size,
          requestedAt: requestedAt,
          debounceMs: debounceMs,
          sceneQueryMs: sceneQuery.elapsedMilliseconds,
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
        // The latest drag release has already supplied its generation while
        // the stale job was rendering. Do not add a second debounce here.
        unawaited(_export(_requestedGeneration));
      }
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _requestedGeneration;

  Future<void> _publishScene({
    required int widgetId,
    required int configurationRevision,
    required String mode,
    required int targetSizePx,
    required int maximumFrameCount,
    required int maximumDecodedBytes,
    required bool requiresAlphaMask,
    required bool Function() isCurrent,
    required DashboardHeaderVisualFrame frame,
    required Size headerSize,
    required DateTime requestedAt,
    required int debounceMs,
    required int sceneQueryMs,
  }) async {
    final snapshot = DashboardHeaderMaterialSnapshot.capture(
      controller: _controller,
      frame: frame,
    );
    final initialPlayback = DashboardOrbMaterialPlaybackProfile.resolve(
      isAnimated: snapshot.isAnimated,
      requiresDenseShaderSampling: snapshot.requiresDenseOrbSampling,
      characteristicCycleMs: snapshot.characteristicCycleMs,
      preferredTextureSizePx: targetSizePx,
      maximumFrameCount: maximumFrameCount,
      maximumDecodedBytes: maximumDecodedBytes,
      applyCircularAlphaMask: requiresAlphaMask,
    );
    final cacheKey = <Object?>[
      snapshot.orbVisualCacheKey,
      targetSizePx,
      maximumFrameCount,
      maximumDecodedBytes,
      requiresAlphaMask,
      dashboardOrbMaterialCacheVersion,
    ].join('|');
    final cached = _frameCache.remove(cacheKey);
    if (cached != null) {
      _frameCache[cacheKey] = cached;
      final timing = _OrbExportTiming(
        debounceMs: debounceMs,
        sceneQueryMs: sceneQueryMs,
        cacheHit: true,
        requestedAt: requestedAt,
      );
      await _publishFrames(
        widgetId: widgetId,
        configurationRevision: configurationRevision,
        mode: mode,
        snapshot: snapshot,
        playback: cached.playback,
        frames: cached.frames,
        phaseOriginUtcMs: cached.phaseOriginUtcMs,
        timing: timing,
        packageStage: 'warm-cache',
        seamMeanRgbDelta: cached.seamMeanRgbDelta,
        seamCandidates: cached.seamCandidates,
      );
      return;
    }

    final timing = _OrbExportTiming(
      debounceMs: debounceMs,
      sceneQueryMs: sceneQueryMs,
      cacheHit: false,
      requestedAt: requestedAt,
    );
    final phaseOriginUtcMs = DateTime.now().millisecondsSinceEpoch;
    final renderer = DashboardHeaderMaterialFrameRenderer();
    try {
      final frames = <Uint8List>[];
      Uint8List? firstOrbRgba;
      DashboardOrbMaterialPlaybackProfile playback = initialPlayback;
      for (var index = 0; index < playback.frameCount; index += 1) {
        if (!isCurrent()) return;
        final renderWatch = Stopwatch()..start();
        final orb = await _renderTexture(
          renderer: renderer,
          snapshot: snapshot,
          headerSize: headerSize,
          orbSizePx: initialPlayback.frameSizePx,
          applyCircularAlphaMask: initialPlayback.applyCircularAlphaMask,
          offset: Duration(milliseconds: initialPlayback.intervalMs * index),
        );
        renderWatch.stop();
        timing.shaderRenderMs += renderWatch.elapsedMilliseconds;
        try {
          if (index == 0) {
            final rgba = await orb.toByteData(format: ImageByteFormat.rawRgba);
            if (rgba == null) throw StateError('Orb RGBA encoding failed.');
            firstOrbRgba = Uint8List.fromList(rgba.buffer.asUint8List());
          }
          final pngWatch = Stopwatch()..start();
          final bytes = await orb.toByteData(format: ImageByteFormat.png);
          pngWatch.stop();
          timing.pngEncodeMs += pngWatch.elapsedMilliseconds;
          if (bytes == null) throw StateError('Orb PNG encoding failed.');
          frames.add(Uint8List.fromList(bytes.buffer.asUint8List()));
        } finally {
          orb.dispose();
        }

        // The starter is made exclusively from the selected production
        // shader's first real time samples. It gives the launcher an early
        // visual reaction without waiting for the remaining PNG sequence.
        if (snapshot.isAnimated && index + 1 == _starterFrameCount) {
          if (!isCurrent()) return;
          await _publishFrames(
            widgetId: widgetId,
            configurationRevision: configurationRevision,
            mode: mode,
            snapshot: snapshot,
            playback: initialPlayback.withLoopDurationMs(
              _starterFrameCount * initialPlayback.intervalMs,
            ),
            frames: List<Uint8List>.unmodifiable(frames),
            phaseOriginUtcMs: phaseOriginUtcMs,
            timing: timing,
            packageStage: 'starter',
            seamMeanRgbDelta: -1,
            seamCandidates: 0,
          );
        }

        // Once the starter is out, choose the finite return point against
        // actual shader pixels. This makes the old 2π/speed assumption an
        // input candidate rather than an unverified loop guarantee.
        if (snapshot.isAnimated && index + 1 == _starterFrameCount) {
          final selected = await _selectLoopDuration(
            renderer: renderer,
            snapshot: snapshot,
            headerSize: headerSize,
            playback: initialPlayback,
            firstOrbRgba: firstOrbRgba!,
          );
          playback = initialPlayback.withLoopDurationMs(selected.durationMs);
          timing.loopSelectionMs = selected.elapsedMs;
          timing.loopSeamMeanRgbDelta = selected.meanRgbDelta;
          timing.loopCandidates = selected.candidateCount;
          // The selected package can be longer than the nominal cycle. The
          // first samples were already rendered at the same dt and remain
          // valid; this loop merely chooses where playback returns to zero.
          if (index + 1 >= playback.frameCount) break;
        }
      }
      // A static package never reaches the starter branch. Animated packages
      // whose frame count is unexpectedly below it retain the initial loop.
      if (!snapshot.isAnimated || firstOrbRgba == null) {
        timing.loopSeamMeanRgbDelta = 0;
      } else if (timing.loopCandidates == 0) {
        final seam = await _loopSeamMeanRgbDelta(
          renderer: renderer,
          snapshot: snapshot,
          headerSize: headerSize,
          targetSizePx: playback.frameSizePx,
          applyCircularAlphaMask: playback.applyCircularAlphaMask,
          firstOrbRgba: firstOrbRgba,
          loopDuration: Duration(milliseconds: playback.loopDurationMs),
        );
        timing.loopSeamMeanRgbDelta = seam;
      }
      if (!isCurrent()) return;
      final channelPngBytes = frames.fold<int>(
        0,
        (sum, frame) => sum + frame.length,
      );
      _remember(
        cacheKey,
        _CachedOrbMaterialPackage(
          playback: playback,
          frames: List<Uint8List>.unmodifiable(frames),
          phaseOriginUtcMs: phaseOriginUtcMs,
          seamMeanRgbDelta: timing.loopSeamMeanRgbDelta,
          seamCandidates: timing.loopCandidates,
          encodedBytes: channelPngBytes,
        ),
      );
      await _publishFrames(
        widgetId: widgetId,
        configurationRevision: configurationRevision,
        mode: mode,
        snapshot: snapshot,
        playback: playback,
        frames: frames,
        phaseOriginUtcMs: phaseOriginUtcMs,
        timing: timing,
        packageStage: 'complete',
        seamMeanRgbDelta: timing.loopSeamMeanRgbDelta,
        seamCandidates: timing.loopCandidates,
      );
    } finally {
      renderer.dispose();
    }
  }

  Future<Image> _renderTexture({
    required DashboardHeaderMaterialFrameRenderer renderer,
    required DashboardHeaderMaterialSnapshot snapshot,
    required Size headerSize,
    required int orbSizePx,
    required bool applyCircularAlphaMask,
    required Duration offset,
  }) async {
    final direct = await renderer.renderOrbTexture(
      snapshot: snapshot,
      headerSize: headerSize,
      devicePixelRatio: _devicePixelRatio,
      orbSizePx: orbSizePx,
      offset: offset,
    );
    if (!applyCircularAlphaMask) return direct;
    try {
      return await DashboardHeaderOrbFrameMapper.map(
        header: direct,
        orbSizePx: orbSizePx,
        applyCircularAlphaMask: true,
      );
    } finally {
      direct.dispose();
    }
  }

  Future<_LoopSelection> _selectLoopDuration({
    required DashboardHeaderMaterialFrameRenderer renderer,
    required DashboardHeaderMaterialSnapshot snapshot,
    required Size headerSize,
    required DashboardOrbMaterialPlaybackProfile playback,
    required Uint8List firstOrbRgba,
  }) async {
    final watch = Stopwatch()..start();
    var bestDurationMs = playback.loopDurationMs;
    var bestDelta = double.infinity;
    var candidates = 0;
    // A finite package cannot reproduce an arbitrarily long non-periodic
    // field. Search the representable neighbourhood in actual shader output,
    // rather than treating 2π/speed as proof that the return is seamless.
    final nominalCount = playback.frameCount;
    final minimumCount = (nominalCount - 16)
        .clamp(2, playback.maximumFrameCount)
        .toInt();
    final maximumCount = (nominalCount + 16)
        .clamp(2, playback.maximumFrameCount)
        .toInt();
    for (var count = minimumCount; count <= maximumCount; count += 1) {
      final candidateDurationMs = count * playback.intervalMs;
      final candidate = await _renderTexture(
        renderer: renderer,
        snapshot: snapshot,
        headerSize: headerSize,
        orbSizePx: playback.frameSizePx,
        applyCircularAlphaMask: playback.applyCircularAlphaMask,
        offset: Duration(milliseconds: candidateDurationMs),
      );
      try {
        final data = await candidate.toByteData(
          format: ImageByteFormat.rawRgba,
        );
        if (data == null) continue;
        final delta = _meanRgbDelta(firstOrbRgba, data.buffer.asUint8List());
        candidates += 1;
        if (delta < bestDelta) {
          bestDelta = delta;
          bestDurationMs = candidateDurationMs;
        }
      } finally {
        candidate.dispose();
      }
    }
    watch.stop();
    return _LoopSelection(
      durationMs: bestDurationMs,
      meanRgbDelta: bestDelta.isFinite ? bestDelta : 0,
      candidateCount: candidates,
      elapsedMs: watch.elapsedMilliseconds,
    );
  }

  Future<void> _publishFrames({
    required int widgetId,
    required int configurationRevision,
    required String mode,
    required DashboardHeaderMaterialSnapshot snapshot,
    required DashboardOrbMaterialPlaybackProfile playback,
    required List<Uint8List> frames,
    required int phaseOriginUtcMs,
    required _OrbExportTiming timing,
    required String packageStage,
    required double seamMeanRgbDelta,
    required int seamCandidates,
  }) async {
    final beforePublication = Stopwatch()..start();
    final encodedBytes = frames.fold<int>(
      0,
      (sum, frame) => sum + frame.length,
    );
    final seam = seamMeanRgbDelta < 0
        ? 'pending'
        : seamMeanRgbDelta.toStringAsFixed(2);
    final description =
        'HeaderMaterial/v${playback.cacheVersion};stage=$packageStage;mode=$mode;'
        'effect=${snapshot.tuning.effect.name};loopMs=${playback.loopDurationMs};'
        'frames=${frames.length};shaderHz=${playback.realShaderSamplesPerSecond.toStringAsFixed(2)};'
        'texture=${playback.frameSizePx};decoded=${playback.decodedBitmapBytes};png=$encodedBytes;'
        'seamRgb=$seam;seamCandidates=$seamCandidates;cache=${timing.cacheHit};'
        'dartMs[d=${timing.debounceMs},scene=${timing.sceneQueryMs},'
        'shader=${timing.shaderRenderMs},resize=0,png=${timing.pngEncodeMs},'
        'loop=${timing.loopSelectionMs},first=${timing.firstPublicationMs ?? -1}]';
    await _channel.invokeMethod<Object?>('publishFrames', <String, Object>{
      'widgetId': widgetId,
      'configurationRevision': configurationRevision,
      'cacheVersion': playback.cacheVersion,
      'intervalMs': playback.intervalMs,
      'phaseOriginUtcMs': phaseOriginUtcMs,
      'requestedAtUtcMs': timing.requestedAt.millisecondsSinceEpoch,
      'sourceDescription': description,
      'frames': frames,
    });
    beforePublication.stop();
    timing.nativeWriteAndQueueMs += beforePublication.elapsedMilliseconds;
    timing.firstPublicationMs ??= DateTime.now()
        .difference(timing.requestedAt)
        .inMilliseconds;
  }

  void _remember(String key, _CachedOrbMaterialPackage package) {
    _frameCache.remove(key);
    _frameCache[key] = package;
    var bytes = _frameCache.values.fold<int>(
      0,
      (sum, item) => sum + item.encodedBytes,
    );
    while (bytes > _maximumCachedEncodedBytes && _frameCache.length > 1) {
      final oldest = _frameCache.keys.first;
      bytes -= _frameCache.remove(oldest)!.encodedBytes;
    }
  }

  Future<double> _loopSeamMeanRgbDelta({
    required DashboardHeaderMaterialFrameRenderer renderer,
    required DashboardHeaderMaterialSnapshot snapshot,
    required Size headerSize,
    required int targetSizePx,
    required bool applyCircularAlphaMask,
    required Uint8List firstOrbRgba,
    required Duration loopDuration,
  }) async {
    final orb = await _renderTexture(
      renderer: renderer,
      snapshot: snapshot,
      headerSize: headerSize,
      orbSizePx: targetSizePx,
      applyCircularAlphaMask: applyCircularAlphaMask,
      offset: loopDuration,
    );
    try {
      final data = await orb.toByteData(format: ImageByteFormat.rawRgba);
      if (data == null) throw StateError('Orb seam RGBA encoding failed.');
      return _meanRgbDelta(firstOrbRgba, data.buffer.asUint8List());
    } finally {
      orb.dispose();
    }
  }

  static double _meanRgbDelta(Uint8List first, Uint8List repeated) {
    if (first.length != repeated.length || first.length % 4 != 0) {
      throw ArgumentError('Mismatched orb frame pixels for loop seam check.');
    }
    var total = 0;
    var samples = 0;
    for (var index = 0; index < first.length; index += 4) {
      // v3 normally clips in the launcher. The legacy alpha-mask fallback
      // keeps its transparent corners, which are intentionally excluded.
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
    _controller.portalSettingsGeneration.removeListener(schedule);
    _controller.orbExportCommitGeneration.removeListener(_scheduleFinal);
    balanceFrame.removeListener(schedule);
    budgetFrame.removeListener(schedule);
    mindFrame.removeListener(schedule);
  }
}

final class _CachedOrbMaterialPackage {
  const _CachedOrbMaterialPackage({
    required this.playback,
    required this.frames,
    required this.phaseOriginUtcMs,
    required this.seamMeanRgbDelta,
    required this.seamCandidates,
    required this.encodedBytes,
  });

  final DashboardOrbMaterialPlaybackProfile playback;
  final List<Uint8List> frames;
  final int phaseOriginUtcMs;
  final double seamMeanRgbDelta;
  final int seamCandidates;
  final int encodedBytes;
}

final class _LoopSelection {
  const _LoopSelection({
    required this.durationMs,
    required this.meanRgbDelta,
    required this.candidateCount,
    required this.elapsedMs,
  });

  final int durationMs;
  final double meanRgbDelta;
  final int candidateCount;
  final int elapsedMs;
}

/// Timings are persisted through the native frame diagnostics with the
/// package. They describe publication work only; they never claim that a
/// launcher has actually displayed a frame.
final class _OrbExportTiming {
  _OrbExportTiming({
    required this.debounceMs,
    required this.sceneQueryMs,
    required this.cacheHit,
    required this.requestedAt,
  });

  final int debounceMs;
  final int sceneQueryMs;
  final bool cacheHit;
  final DateTime requestedAt;
  int shaderRenderMs = 0;
  int pngEncodeMs = 0;
  int loopSelectionMs = 0;
  int loopCandidates = 0;
  double loopSeamMeanRgbDelta = 0;
  int nativeWriteAndQueueMs = 0;
  int? firstPublicationMs;
}
