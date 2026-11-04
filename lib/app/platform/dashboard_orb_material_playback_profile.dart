/// The finite, launcher-owned playback contract for a Dashboard orb export.
///
/// Each displayed frame is rendered by the Dashboard shader at its real time
/// offset. The launcher only flips those complete frames: it never blends two
/// material states, because that creates both a brightness pulse and ghosting
/// on directional effects such as Deep Drift and Portal.
const int dashboardOrbMaterialCacheVersion = 5;

final class DashboardOrbMaterialPlaybackProfile {
  const DashboardOrbMaterialPlaybackProfile._({
    required this.cacheVersion,
    required this.frameCount,
    required this.frameSizePx,
    required this.maximumFrameCount,
    required this.intervalMs,
    required this.targetCycleMs,
    required this.loopDurationMs,
    required this.usesDenseShaderSampling,
    required this.applyCircularAlphaMask,
  });

  /// v5 invalidates the pre-phase-aligned payload. Native keeps an old package
  /// visible only until a fully validated v5 package is committed.
  final int cacheVersion;
  final int frameCount;

  /// Internal square colour texture resolution. It is deliberately separate
  /// from the AppWidget's physical diameter, which native derives from the
  /// current launcher cell at render time.
  final int frameSizePx;
  final int maximumFrameCount;
  final int intervalMs;
  final int targetCycleMs;
  final int loopDurationMs;
  final bool usesDenseShaderSampling;

  /// API < 31 does not expose the RemoteViews outline APIs used by the normal
  /// path, so its source pixels retain an anti-aliased circular alpha mask.
  final bool applyCircularAlphaMask;

  int get transitionDurationMs => 0;
  int get decodedBitmapBytes => frameSizePx * frameSizePx * frameCount * 4;
  int get oneWidgetDecodedBytes => decodedBitmapBytes;
  int get threeWidgetDecodedBytes => decodedBitmapBytes * 3;
  double get realShaderSamplesPerSecond => 1000 / intervalMs;

  /// Keeps the authored dt intact while selecting a seam-tested finite loop.
  /// Only a whole number of existing source samples can be selected, so the
  /// shader motion never gets sped up or slowed down to make a package fit.
  DashboardOrbMaterialPlaybackProfile withLoopDurationMs(int durationMs) {
    if (frameCount == 1) return this;
    final count = (durationMs ~/ intervalMs)
        .clamp(2, maximumFrameCount)
        .toInt();
    return DashboardOrbMaterialPlaybackProfile._(
      cacheVersion: cacheVersion,
      frameCount: count,
      frameSizePx: frameSizePx,
      maximumFrameCount: maximumFrameCount,
      intervalMs: intervalMs,
      targetCycleMs: targetCycleMs,
      loopDurationMs: count * intervalMs,
      usesDenseShaderSampling: usesDenseShaderSampling,
      applyCircularAlphaMask: applyCircularAlphaMask,
    );
  }

  /// Resolves source sampling and texture size under the exact raw bitmap
  /// budget Android validates on receipt. Animated profiles target thirty
  /// real shader renders per second whenever a full cycle fits the package;
  /// no synthetic cross-fade fills gaps.
  factory DashboardOrbMaterialPlaybackProfile.resolve({
    required bool isAnimated,
    required bool requiresDenseShaderSampling,
    required int characteristicCycleMs,
    required int preferredTextureSizePx,
    required int maximumFrameCount,
    required int maximumDecodedBytes,
    required bool applyCircularAlphaMask,
  }) {
    final preferredTexture = preferredTextureSizePx.clamp(32, 128).toInt();
    if (!isAnimated) {
      return DashboardOrbMaterialPlaybackProfile._(
        cacheVersion: dashboardOrbMaterialCacheVersion,
        frameCount: 1,
        frameSizePx: preferredTexture,
        maximumFrameCount: 1,
        intervalMs: 1000,
        targetCycleMs: 1000,
        loopDurationMs: 1000,
        usesDenseShaderSampling: false,
        applyCircularAlphaMask: applyCircularAlphaMask,
      );
    }

    final targetCycle = characteristicCycleMs.clamp(1000, 3600000).toInt();
    const targetSampleMs = 1000 / 30;
    final desiredFrameCount = (targetCycle / targetSampleMs)
        .round()
        .clamp(2, maximumFrameCount)
        .toInt();
    final sizes =
        <int>{
            preferredTexture,
            96,
            80,
            72,
            64,
            56,
            48,
            40,
            32,
          }.where((size) => size <= preferredTexture).toList()
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

    // Prefer an integer cadence at or above 30 Hz that closes the authored
    // cycle exactly.  4.8 s therefore becomes 150 × 32 ms, not 144 × 33 ms
    // (which would visibly speed the orbit up by 1%).
    final exactIntervalMs = Iterable<int>.generate(18, (index) => 33 - index)
        .firstWhere(
          (interval) =>
              targetCycle % interval == 0 &&
              targetCycle ~/ interval >= 2 &&
              targetCycle ~/ interval <= frameLimit,
          orElse: () => 0,
        );
    final frameCount = exactIntervalMs > 0
        ? targetCycle ~/ exactIntervalMs
        : desiredFrameCount.clamp(2, frameLimit).toInt();
    // The source's i-th sample is rendered at i × dt, then shown for that
    // same dt. An uncommon cycle without an integer cadence reports its
    // closest representable loop duration through diagnostics.
    final intervalMs =
        (exactIntervalMs > 0
                ? exactIntervalMs
                : (targetCycle / frameCount).round())
            .clamp(16, 60000)
            .toInt();
    return DashboardOrbMaterialPlaybackProfile._(
      cacheVersion: dashboardOrbMaterialCacheVersion,
      frameCount: frameCount,
      frameSizePx: frameSize,
      maximumFrameCount: frameLimit,
      intervalMs: intervalMs,
      targetCycleMs: targetCycle,
      loopDurationMs: frameCount * intervalMs,
      usesDenseShaderSampling: true,
      applyCircularAlphaMask: applyCircularAlphaMask,
    );
  }
}
