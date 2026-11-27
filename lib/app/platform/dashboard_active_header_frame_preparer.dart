import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import 'dashboard_orb_loop_verifier.dart';
import 'dashboard_orb_material_playback_profile.dart';

/// A complete Flutter-rendered frame and the RGBA samples used to qualify it.
/// Both belong to one captured header generation and stay app-private.
final class ActiveHeaderRenderedFrame {
  const ActiveHeaderRenderedFrame({required this.png, required this.rgba});

  final Uint8List png;
  final Uint8List rgba;
}

enum ActiveHeaderPreparationStatus {
  ready,
  stale,
  invalidFrame,
  byteBudgetExceeded,
  animatedButStationary,
  unverifiedLoop,
  rendererUnavailable,
}

/// Renders an immutable foreground snapshot before wake. An unavailable
/// Flutter shader is reported, not silently treated as a matching gradient.
Future<ActiveHeaderPreparedFrames> renderActiveHeaderFrames({
  required DashboardHeaderMaterialSnapshot snapshot,
  required ui.Size headerSize,
  required double devicePixelRatio,
  required bool motionEnabled,
  required bool Function() isCurrent,
}) async {
  final animated = motionEnabled && snapshot.isAnimated;
  final playback = DashboardOrbMaterialPlaybackProfile.resolve(
    isAnimated: animated,
    requiresDenseShaderSampling: snapshot.requiresDenseOrbSampling,
    characteristicCycleMs: snapshot.characteristicCycleMs,
    preferredTextureSizePx: 96,
    maximumFrameCount: 175,
    maximumDecodedBytes: 700 * 1024,
    applyCircularAlphaMask: false,
  );
  final renderer = DashboardHeaderMaterialFrameRenderer();
  try {
    return await prepareActiveHeaderFrames(
      playback: playback,
      animated: animated,
      isCurrent: isCurrent,
      render: (index) async {
        final image = await renderer.renderOrbTexture(
          snapshot: snapshot,
          headerSize: headerSize,
          devicePixelRatio: devicePixelRatio,
          orbSizePx: playback.frameSizePx,
          offset: Duration(milliseconds: playback.intervalMs * index),
        );
        try {
          if (!renderer.lastPaintWasExact) {
            throw StateError('active header renderer unavailable');
          }
          final rgba = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          if (rgba == null || png == null) {
            throw StateError('frame encoding failed');
          }
          return ActiveHeaderRenderedFrame(
            rgba: rgba.buffer.asUint8List(
              rgba.offsetInBytes,
              rgba.lengthInBytes,
            ),
            png: png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
          );
        } finally {
          image.dispose();
        }
      },
    );
  } catch (_) {
    return ActiveHeaderPreparedFrames._(
      status: isCurrent()
          ? ActiveHeaderPreparationStatus.rendererUnavailable
          : ActiveHeaderPreparationStatus.stale,
    );
  } finally {
    renderer.dispose();
  }
}

/// No preview is returned for an animated source: only the whole verified
/// loop may replace its same-generation semantic shader fallback.
final class ActiveHeaderPreparedFrames {
  const ActiveHeaderPreparedFrames._({
    required this.status,
    this.playback,
    this.frames,
  });

  final ActiveHeaderPreparationStatus status;
  final DashboardOrbMaterialPlaybackProfile? playback;
  final List<Uint8List>? frames;

  bool get ready => status == ActiveHeaderPreparationStatus.ready;
}

typedef ActiveHeaderFramesRenderer =
    Future<ActiveHeaderPreparedFrames> Function({
      required DashboardHeaderMaterialSnapshot snapshot,
      required ui.Size headerSize,
      required double devicePixelRatio,
      required bool motionEnabled,
      required bool Function() isCurrent,
    });

/// Reuses the launcher's sampling and seam verifier for the actual visible
/// header. There is no launcher/widget identity in this independent path.
/// Callers supply the immutable captured snapshot through [render] and must
/// invalidate [isCurrent] when a newer source or privacy revision wins.
Future<ActiveHeaderPreparedFrames> prepareActiveHeaderFrames({
  required DashboardOrbMaterialPlaybackProfile playback,
  required bool animated,
  required bool Function() isCurrent,
  required Future<ActiveHeaderRenderedFrame> Function(int index) render,
  int maximumEncodedBytes = 2 * 1024 * 1024,
  int maximumDecodedBytes = 700 * 1024,
}) async {
  ActiveHeaderPreparedFrames outcome(ActiveHeaderPreparationStatus status) =>
      ActiveHeaderPreparedFrames._(status: status);

  if (!isCurrent()) return outcome(ActiveHeaderPreparationStatus.stale);
  if (animated != (playback.frameCount > 1) ||
      playback.frameSizePx < 32 ||
      playback.frameSizePx > 128 ||
      (animated && playback.maximumFrameCount < 3) ||
      playback.maximumFrameCount > 175 ||
      playback.intervalMs < 16 ||
      playback.intervalMs > 60000) {
    return outcome(ActiveHeaderPreparationStatus.invalidFrame);
  }

  final candidates = animated ? _candidateFrameCounts(playback) : const <int>[];
  final count = animated ? candidates.last : 1;
  final bytesPerFrame = playback.frameSizePx * playback.frameSizePx * 4;
  if (bytesPerFrame * count > maximumDecodedBytes) {
    return outcome(ActiveHeaderPreparationStatus.byteBudgetExceeded);
  }

  final encoded = <Uint8List>[];
  final samples = <Uint8List>[];
  var encodedBytes = 0;
  for (var index = 0; index < count; index++) {
    if (!isCurrent()) return outcome(ActiveHeaderPreparationStatus.stale);
    final frame = await render(index);
    if (!isCurrent()) return outcome(ActiveHeaderPreparationStatus.stale);
    if (frame.rgba.length != bytesPerFrame || frame.png.isEmpty) {
      return outcome(ActiveHeaderPreparationStatus.invalidFrame);
    }
    encodedBytes += frame.png.length;
    if (encodedBytes > maximumEncodedBytes) {
      return outcome(ActiveHeaderPreparationStatus.byteBudgetExceeded);
    }
    // Do not retain caller-owned mutable byte arrays across asynchronous work.
    encoded.add(Uint8List.fromList(frame.png));
    if (animated) samples.add(Uint8List.fromList(frame.rgba));
  }

  var resultPlayback = playback;
  if (animated) {
    final validation = const DashboardOrbLoopVerifier().validate(
      frames: samples,
      candidateFrameCounts: candidates,
    );
    if (!validation.accepted || validation.frameCount == null) {
      return outcome(ActiveHeaderPreparationStatus.unverifiedLoop);
    }
    if (!_hasInteriorMotion(
      samples.take(validation.frameCount!).toList(growable: false),
      playback.frameSizePx,
    )) {
      return outcome(ActiveHeaderPreparationStatus.animatedButStationary);
    }
    resultPlayback = playback.withLoopDurationMs(
      validation.frameCount! * playback.intervalMs,
    );
  }
  if (!isCurrent()) return outcome(ActiveHeaderPreparationStatus.stale);
  return ActiveHeaderPreparedFrames._(
    status: ActiveHeaderPreparationStatus.ready,
    playback: resultPlayback,
    frames: List<Uint8List>.unmodifiable(
      encoded.take(resultPlayback.frameCount),
    ),
  );
}

List<int> _candidateFrameCounts(DashboardOrbMaterialPlaybackProfile playback) {
  final minimum = (playback.frameCount - 16)
      .clamp(3, playback.maximumFrameCount)
      .toInt();
  final maximum = (playback.frameCount + 16)
      .clamp(3, playback.maximumFrameCount)
      .toInt();
  return List<int>.generate(maximum - minimum + 1, (index) => minimum + index);
}

bool _hasInteriorMotion(List<Uint8List> frames, int size) {
  if (frames.length < 3) return false;
  final first = frames.first;
  // An animated source must show a measurable change in real samples, not
  // merely have a seamless loop of repeated still frames. Transparent pixels
  // cannot establish motion.
  for (final frame in frames.skip(1)) {
    var changed = 0;
    for (var i = 0; i < first.length; i += 4) {
      final pixel = i ~/ 4;
      final x = pixel % size + .5 - size / 2;
      final y = pixel ~/ size + .5 - size / 2;
      if (x * x + y * y >= size * size * .1764) continue;
      if (first[i + 3] == 0 || frame[i + 3] == 0) continue;
      if ((first[i] - frame[i]).abs() >= 3 ||
          (first[i + 1] - frame[i + 1]).abs() >= 3 ||
          (first[i + 2] - frame[i + 2]).abs() >= 3) {
        changed++;
      }
      if (changed >= 64) return true;
    }
  }
  return false;
}
