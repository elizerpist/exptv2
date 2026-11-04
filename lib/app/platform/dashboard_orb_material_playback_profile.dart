/// The finite, launcher-owned playback contract for a Dashboard orb export.
///
/// The launcher gets the complete sequence in one RemoteViews update. It then
/// blends neighbouring source frames locally, so [frameCount] describes real
/// shader renders rather than display refreshes. Keeping this decision here
/// makes the Dart exporter and the native package validator use the same
/// bounded format.
const int dashboardOrbMaterialCacheVersion = 3;

final class DashboardOrbMaterialPlaybackProfile {
  const DashboardOrbMaterialPlaybackProfile._({
    required this.cacheVersion,
    required this.frameCount,
    required this.frameSizePx,
    required this.displaySizePx,
    required this.intervalMs,
    required this.transitionDurationMs,
    required this.targetCycleMs,
    required this.loopDurationMs,
    required this.usesDenseShaderSampling,
    required this.applyCircularAlphaMask,
  });

  /// v3 invalidates the former binary-circle / 24-frame payload only after a
  /// complete replacement has been written. Native keeps a v2 package alive
  /// until then.
  final int cacheVersion;
  final int frameCount;

  /// Texture resolution. It may be lower than [displaySizePx] for dense
  /// motion; the launcher-owned geometric clip preserves the circle edge.
  final int frameSizePx;
  final int displaySizePx;
  final int intervalMs;
  final int transitionDurationMs;
  final int targetCycleMs;
  final int loopDurationMs;
  final bool usesDenseShaderSampling;

  /// API < 31 does not have the RemoteViews outline APIs used by the normal
  /// path, so its source pixels retain an anti-aliased circular alpha mask.
  final bool applyCircularAlphaMask;

  int get decodedBitmapBytes => frameSizePx * frameSizePx * frameCount * 4;
  int get oneWidgetDecodedBytes => decodedBitmapBytes;
  int get threeWidgetDecodedBytes => decodedBitmapBytes * 3;
  double get realShaderSamplesPerSecond => 1000 / intervalMs;

  /// Resolves source sampling and texture size together under the exact raw
  /// bitmap budget that Android validates on receipt.
  factory DashboardOrbMaterialPlaybackProfile.resolve({
    required bool isAnimated,
    required bool requiresDenseShaderSampling,
    required int characteristicCycleMs,
    required int preferredDisplaySizePx,
    required int maximumFrameCount,
    required int maximumDecodedBytes,
    required bool applyCircularAlphaMask,
  }) {
    final displaySize = preferredDisplaySizePx.clamp(32, 128).toInt();
    if (!isAnimated) {
      return DashboardOrbMaterialPlaybackProfile._(
        cacheVersion: dashboardOrbMaterialCacheVersion,
        frameCount: 1,
        frameSizePx: displaySize,
        displaySizePx: displaySize,
        intervalMs: 1000,
        transitionDurationMs: 0,
        targetCycleMs: 1000,
        loopDurationMs: 1000,
        usesDenseShaderSampling: false,
        applyCircularAlphaMask: applyCircularAlphaMask,
      );
    }

    final targetCycle = characteristicCycleMs.clamp(1000, 3600000).toInt();
    final sampleTargetMs = requiresDenseShaderSampling ? 80 : 200;
    final desiredFrameCount = (targetCycle / sampleTargetMs).ceil();
    final sizes =
        <int>{
            displaySize,
            96,
            80,
            72,
            64,
            56,
            48,
            40,
            32,
          }.where((size) => size <= displaySize).toList()
          ..sort((a, b) => b.compareTo(a));

    var frameSize = sizes.last;
    var frameLimit = 2;
    for (final candidate in sizes) {
      final budgetLimit = maximumDecodedBytes ~/ (candidate * candidate * 4);
      final limit = budgetLimit.clamp(2, maximumFrameCount).toInt();
      if (desiredFrameCount <= limit) {
        frameSize = candidate;
        frameLimit = limit;
        break;
      }
      if (candidate == sizes.last) {
        frameSize = candidate;
        frameLimit = limit;
      }
    }

    final selected = _selectFrameTiming(
      targetCycleMs: targetCycle,
      desiredSampleMs: sampleTargetMs,
      maximumFrameCount: frameLimit,
    );
    return DashboardOrbMaterialPlaybackProfile._(
      cacheVersion: dashboardOrbMaterialCacheVersion,
      frameCount: selected.frameCount,
      frameSizePx: frameSize,
      displaySizePx: displaySize,
      intervalMs: selected.intervalMs,
      transitionDurationMs: _transitionAtMost(selected.intervalMs),
      targetCycleMs: targetCycle,
      loopDurationMs: selected.frameCount * selected.intervalMs,
      usesDenseShaderSampling: requiresDenseShaderSampling,
      applyCircularAlphaMask: applyCircularAlphaMask,
    );
  }

  /// These are actual XML animation durations. The selected value is never
  /// longer than its ViewFlipper interval, so an outgoing layer cannot be
  /// resurrected by the next flip. 200 ms is exact for the 4.8 s / 24-frame
  /// Balance reference package.
  static const List<int> _transitionDurationsMs = <int>[
    40,
    60,
    80,
    100,
    120,
    140,
    160,
    180,
    190,
    200,
    220,
    240,
    280,
    320,
    400,
    500,
    600,
    800,
    1000,
    2000,
    4000,
    8000,
    16000,
    32000,
    60000,
  ];

  static int _transitionAtMost(int intervalMs) {
    for (final duration in _transitionDurationsMs.reversed) {
      if (duration <= intervalMs) return duration;
    }
    return 0;
  }

  static _FrameTiming _selectFrameTiming({
    required int targetCycleMs,
    required int desiredSampleMs,
    required int maximumFrameCount,
  }) {
    final minimum = (targetCycleMs / (desiredSampleMs * 1.25))
        .ceil()
        .clamp(2, maximumFrameCount)
        .toInt();
    final maximum = (targetCycleMs / (desiredSampleMs * .75))
        .floor()
        .clamp(minimum, maximumFrameCount)
        .toInt();
    _FrameTiming? winner;
    var winnerScore = double.infinity;
    for (var count = minimum; count <= maximum; count += 1) {
      final interval = (targetCycleMs / count).round().clamp(16, 60000).toInt();
      final loop = interval * count;
      // Preserving the Header cycle dominates. The remaining terms select a
      // useful source density and a transition that almost fills each slot.
      final score =
          (loop - targetCycleMs).abs() * 1000000 +
          (interval - desiredSampleMs).abs() * 100 +
          (interval - _transitionAtMost(interval)).abs();
      if (score < winnerScore) {
        winner = _FrameTiming(frameCount: count, intervalMs: interval);
        winnerScore = score.toDouble();
      }
    }
    return winner!;
  }
}

final class _FrameTiming {
  const _FrameTiming({required this.frameCount, required this.intervalMs});

  final int frameCount;
  final int intervalMs;
}
