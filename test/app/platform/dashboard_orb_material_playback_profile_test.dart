import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_orb_material_playback_profile.dart';

void main() {
  group('DashboardOrbMaterialPlaybackProfile', () {
    test('keeps the 4.8 second Balance cycle at its original speed', () {
      final profile = DashboardOrbMaterialPlaybackProfile.resolve(
        isAnimated: true,
        requiresDenseShaderSampling: false,
        characteristicCycleMs: 4800,
        preferredDisplaySizePx: 80,
        maximumFrameCount: 160,
        maximumDecodedBytes: 700 * 1024,
        applyCircularAlphaMask: false,
      );

      expect(profile.cacheVersion, dashboardOrbMaterialCacheVersion);
      expect(profile.frameCount, 24);
      expect(profile.intervalMs, 200);
      expect(profile.transitionDurationMs, 200);
      expect(profile.loopDurationMs, 4800);
      expect(profile.frameSizePx, 80);
      expect(profile.decodedBitmapBytes, 24 * 80 * 80 * 4);
      expect(profile.threeWidgetDecodedBytes, 3 * 24 * 80 * 80 * 4);
    });

    test(
      'uses denser real shader samples for Deep Drift and retains the budget',
      () {
        final profile = DashboardOrbMaterialPlaybackProfile.resolve(
          isAnimated: true,
          requiresDenseShaderSampling: true,
          characteristicCycleMs: 4800,
          preferredDisplaySizePx: 80,
          maximumFrameCount: 160,
          maximumDecodedBytes: 700 * 1024,
          applyCircularAlphaMask: false,
        );

        expect(profile.frameCount, 60);
        expect(profile.intervalMs, 80);
        expect(profile.transitionDurationMs, 80);
        expect(profile.loopDurationMs, 4800);
        expect(profile.frameSizePx, 48);
        expect(profile.decodedBitmapBytes, lessThanOrEqualTo(700 * 1024));
        expect(profile.realShaderSamplesPerSecond, 12.5);
      },
    );

    test(
      'static material is one frame and the compatibility mask is explicit',
      () {
        final profile = DashboardOrbMaterialPlaybackProfile.resolve(
          isAnimated: false,
          requiresDenseShaderSampling: false,
          characteristicCycleMs: 4800,
          preferredDisplaySizePx: 80,
          maximumFrameCount: 160,
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
