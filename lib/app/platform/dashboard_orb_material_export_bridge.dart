import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import '../../features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'dashboard_orb_loop_verifier.dart';
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
        final activePackageIdentity = raw['activePackageIdentity'] as String?;
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
          activePackageIdentity: activePackageIdentity,
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
    required String? activePackageIdentity,
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
    final packageIdentity = _packageIdentity(
      mode: mode,
      configurationRevision: configurationRevision,
      visualCacheKey: snapshot.orbVisualCacheKey,
    );
    // An identical focus/privacy-safe visual identity is already the exact
    // retained package we want. Replacing it would merely restart a launcher
    // flipper and cannot improve its cadence.
    if (activePackageIdentity == packageIdentity) return;
    final cached = _frameCache.remove(cacheKey);
    if (cached != null) {
      _frameCache[cacheKey] = cached;
      final timing = _OrbExportTiming(
        debounceMs: debounceMs,
        sceneQueryMs: sceneQueryMs,
        cacheHit: true,
        requestedAt: requestedAt,
      );
      if (snapshot.isAnimated) {
        await _publishFrames(
          widgetId: widgetId,
          configurationRevision: configurationRevision,
          mode: mode,
          snapshot: snapshot,
          playback: cached.playback.asStaticPreview(),
          frames: <Uint8List>[cached.frames.first],
          phaseOriginUtcMs: DateTime.now().millisecondsSinceEpoch,
          timing: timing,
          packageIdentity: packageIdentity,
          packageStage: 'static-preview',
          loopValidation: null,
        );
      }
      await _publishFrames(
        widgetId: widgetId,
        configurationRevision: configurationRevision,
        mode: mode,
        snapshot: snapshot,
        playback: cached.playback,
        frames: cached.frames,
        phaseOriginUtcMs: cached.phaseOriginUtcMs,
        timing: timing,
        packageIdentity: packageIdentity,
        packageStage: 'complete-cache',
        loopValidation: cached.loopValidation,
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
      final rgbaFrames = <Uint8List>[];
      DashboardOrbMaterialPlaybackProfile playback = initialPlayback;
      final candidateFrameCounts = snapshot.isAnimated
          ? _candidateFrameCounts(initialPlayback)
          : const <int>[];
      final frameRenderCount = snapshot.isAnimated
          ? candidateFrameCounts.last
          : playback.frameCount;
      for (var index = 0; index < frameRenderCount; index += 1) {
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
          final rgba = await orb.toByteData(format: ImageByteFormat.rawRgba);
          if (rgba == null) throw StateError('Orb RGBA encoding failed.');
          rgbaFrames.add(Uint8List.fromList(rgba.buffer.asUint8List()));
          final pngWatch = Stopwatch()..start();
          final bytes = await orb.toByteData(format: ImageByteFormat.png);
          pngWatch.stop();
          timing.pngEncodeMs += pngWatch.elapsedMilliseconds;
          if (bytes == null) throw StateError('Orb PNG encoding failed.');
          frames.add(Uint8List.fromList(bytes.buffer.asUint8List()));
        } finally {
          orb.dispose();
        }

        // First display is an accurate still, never an unchecked animated
        // starter loop. A previous package is left untouched only when its
        // focus/privacy-safe material identity exactly matches this request.
        if (snapshot.isAnimated && index == 0) {
          if (!isCurrent()) return;
          await _publishFrames(
            widgetId: widgetId,
            configurationRevision: configurationRevision,
            mode: mode,
            snapshot: snapshot,
            playback: initialPlayback.asStaticPreview(),
            frames: <Uint8List>[frames.first],
            phaseOriginUtcMs: DateTime.now().millisecondsSinceEpoch,
            timing: timing,
            packageIdentity: packageIdentity,
            packageStage: 'static-preview',
            loopValidation: null,
          );
        }
      }

      DashboardOrbLoopValidation? loopValidation;
      if (snapshot.isAnimated) {
        final loopWatch = Stopwatch()..start();
        loopValidation = const DashboardOrbLoopVerifier().validate(
          frames: rgbaFrames,
          candidateFrameCounts: candidateFrameCounts,
        );
        loopWatch.stop();
        timing.loopSelectionMs = loopWatch.elapsedMilliseconds;
        await _recordLoopVerification(
          widgetId: widgetId,
          configurationRevision: configurationRevision,
          packageIdentity: packageIdentity,
          validation: loopValidation,
        );
        // Do not turn the least-bad candidate into an animated package. The
        // static preview remains visible, explicitly without a continuity
        // claim, when this finite sample budget cannot close the effect.
        if (!loopValidation.accepted) return;
        playback = initialPlayback.withLoopDurationMs(
          loopValidation.frameCount! * initialPlayback.intervalMs,
        );
      }
      if (!isCurrent()) return;
      final completeFrames = snapshot.isAnimated
          ? List<Uint8List>.unmodifiable(frames.take(playback.frameCount))
          : List<Uint8List>.unmodifiable(frames);
      final channelPngBytes = completeFrames.fold<int>(
        0,
        (sum, frame) => sum + frame.length,
      );
      _remember(
        cacheKey,
        _CachedOrbMaterialPackage(
          playback: playback,
          frames: completeFrames,
          phaseOriginUtcMs: phaseOriginUtcMs,
          loopValidation: loopValidation,
          encodedBytes: channelPngBytes,
        ),
      );
      await _publishFrames(
        widgetId: widgetId,
        configurationRevision: configurationRevision,
        mode: mode,
        snapshot: snapshot,
        playback: playback,
        frames: completeFrames,
        phaseOriginUtcMs: phaseOriginUtcMs,
        timing: timing,
        packageIdentity: packageIdentity,
        packageStage: 'complete',
        loopValidation: loopValidation,
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

  List<int> _candidateFrameCounts(
    DashboardOrbMaterialPlaybackProfile playback,
  ) {
    final minimum = (playback.frameCount - 16)
        .clamp(3, playback.maximumFrameCount)
        .toInt();
    final maximum = (playback.frameCount + 16)
        .clamp(3, playback.maximumFrameCount)
        .toInt();
    return List<int>.generate(
      maximum - minimum + 1,
      (index) => minimum + index,
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
    required String packageIdentity,
    required String packageStage,
    required DashboardOrbLoopValidation? loopValidation,
  }) async {
    final beforePublication = Stopwatch()..start();
    final encodedBytes = frames.fold<int>(
      0,
      (sum, frame) => sum + frame.length,
    );
    String metric(double? value) =>
        value == null ? 'n/a' : value.toStringAsFixed(2);
    final loop = loopValidation;
    final loopStatus = loop?.status.name ?? 'static-preview';
    final description =
        'HeaderMaterial/v${playback.cacheVersion};stage=$packageStage;mode=$mode;'
        'effect=${snapshot.tuning.effect.name};loopMs=${playback.loopDurationMs};'
        'frames=${frames.length};shaderHz=${playback.realShaderSamplesPerSecond.toStringAsFixed(2)};'
        'texture=${playback.frameSizePx};decoded=${playback.decodedBitmapBytes};png=$encodedBytes;'
        'identity=$packageIdentity;loopStatus=$loopStatus;'
        'seamRgb=${metric(loop?.seamMeanRgbDelta)};seamLimit=${metric(loop?.seamLimit)};'
        'motionRgb=${metric(loop?.motionChangeMeanRgbDelta)};motionLimit=${metric(loop?.motionChangeLimit)};'
        'seamCandidates=${loop?.candidateCount ?? 0};validSeamCandidates=${loop?.validCandidateCount ?? 0};'
        // RemoteViews has no callback that proves which child the launcher is
        // displaying. A phase-based initial index is alignment intent only.
        'pacing=unverified;cache=${timing.cacheHit};'
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
      'packageIdentity': packageIdentity,
      'sourceDescription': description,
      'frames': frames,
    });
    beforePublication.stop();
    timing.nativeWriteAndQueueMs += beforePublication.elapsedMilliseconds;
    timing.firstPublicationMs ??= DateTime.now()
        .difference(timing.requestedAt)
        .inMilliseconds;
  }

  Future<void> _recordLoopVerification({
    required int widgetId,
    required int configurationRevision,
    required String packageIdentity,
    required DashboardOrbLoopValidation validation,
  }) => _channel
      .invokeMethod<Object?>('recordLoopVerification', <String, Object?>{
        'widgetId': widgetId,
        'configurationRevision': configurationRevision,
        'packageIdentity': packageIdentity,
        'status': validation.status.name,
        'candidateCount': validation.candidateCount,
        'validCandidateCount': validation.validCandidateCount,
        'seamMeanRgbDelta': validation.seamMeanRgbDelta,
        'seamLimit': validation.seamLimit,
        'motionChangeMeanRgbDelta': validation.motionChangeMeanRgbDelta,
        'motionChangeLimit': validation.motionChangeLimit,
      });

  String _packageIdentity({
    required String mode,
    required int configurationRevision,
    required String visualCacheKey,
  }) {
    var hash = 0x811c9dc5;
    for (final unit
        in '$mode|$configurationRevision|$visualCacheKey'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'v$dashboardOrbMaterialCacheVersion-$mode-$configurationRevision-${hash.toUnsigned(32).toRadixString(16)}';
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
    required this.loopValidation,
    required this.encodedBytes,
  });

  final DashboardOrbMaterialPlaybackProfile playback;
  final List<Uint8List> frames;
  final int phaseOriginUtcMs;
  final DashboardOrbLoopValidation? loopValidation;
  final int encodedBytes;
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
  int nativeWriteAndQueueMs = 0;
  int? firstPublicationMs;
}
