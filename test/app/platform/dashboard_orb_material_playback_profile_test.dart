import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_orb_material_playback_profile.dart';

void main() {
  group('DashboardOrbMaterialPlaybackProfile', () {
    test('keeps the 4.8 second Balance cycle at its original speed', () {
      final profile = DashboardOrbMaterialPlaybackProfile.resolve(
        isAnimated: true,
        requiresDenseShaderSampling: false,
        characteristicCycleMs: 4800,
        preferredTextureSizePx: 80,
        maximumFrameCount: 175,
        maximumDecodedBytes: 700 * 1024,
        applyCircularAlphaMask: false,
      );

      expect(profile.cacheVersion, dashboardOrbMaterialCacheVersion);
      expect(profile.frameCount, 150);
      expect(profile.intervalMs, 32);
      expect(profile.transitionDurationMs, 0);
      expect(profile.loopDurationMs, 4800);
      expect(profile.frameSizePx, 32);
      expect(profile.decodedBitmapBytes, 150 * 32 * 32 * 4);
      expect(profile.threeWidgetDecodedBytes, 3 * 150 * 32 * 32 * 4);
      expect(profile.realShaderSamplesPerSecond, 31.25);
    });

    test(
      'uses denser real shader samples for Deep Drift and retains the budget',
      () {
        final profile = DashboardOrbMaterialPlaybackProfile.resolve(
          isAnimated: true,
          requiresDenseShaderSampling: true,
          characteristicCycleMs: 4800,
          preferredTextureSizePx: 80,
          maximumFrameCount: 175,
          maximumDecodedBytes: 700 * 1024,
          applyCircularAlphaMask: false,
        );

        expect(profile.frameCount, 150);
        expect(profile.intervalMs, 32);
        expect(profile.transitionDurationMs, 0);
        expect(profile.loopDurationMs, 4800);
        expect(profile.frameSizePx, 32);
        expect(profile.decodedBitmapBytes, lessThanOrEqualTo(700 * 1024));
        expect(profile.realShaderSamplesPerSecond, 31.25);
      },
    );

    test(
      'static material is one frame and the compatibility mask is explicit',
      () {
        final profile = DashboardOrbMaterialPlaybackProfile.resolve(
          isAnimated: false,
          requiresDenseShaderSampling: false,
          characteristicCycleMs: 4800,
          preferredTextureSizePx: 80,
          maximumFrameCount: 175,
          maximumDecodedBytes: 700 * 1024,
          applyCircularAlphaMask: true,
        );

        expect(profile.frameCount, 1);
        expect(profile.transitionDurationMs, 0);
        expect(profile.applyCircularAlphaMask, isTrue);
      },
    );
  });
}
