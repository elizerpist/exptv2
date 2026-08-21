import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_tap_wave.dart';

void main() {
  group('Color Lab Header tap-wave source contract', () {
    test(
      'transcribes the one real source control and app-added source constants',
      () {
        expect(
          DashboardHeaderTapWaveCatalog.controls.map(
            (control) => (
              control.id,
              control.label,
              control.min,
              control.max,
              control.step,
              control.defaultValue,
              control.unit,
              control.isSourceControl,
            ),
          ),
          const <
            (String, String, double, double, double, double, String, bool)
          >[
            (
              'interactionOpacity',
              'Interakció opacity',
              0,
              100,
              1,
              100,
              '%',
              true,
            ),
            (
              'releaseDurationMs',
              'Elengedési idő',
              400,
              3000,
              20,
              1640,
              'ms',
              false,
            ),
            (
              'rippleRadiusTravel',
              'Hullámsugár',
              .12,
              .80,
              .01,
              .42,
              '',
              false,
            ),
            ('rippleIntensity', 'Hullámerő', .25, 2, .01, 1, '×', false),
            ('trailSize', 'Nyom mérete', 24, 160, 1, 82, 'px', false),
            ('pulseLight', 'Mezőfény', 0, .08, .001, .025, '', false),
          ],
        );
      },
    );

    test(
      'pointer-down creates the exact fixed pink overlay, field wave and first trail',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.25, .75),
          timestamp: Duration.zero,
        );

        final overlay = state.overlayAt(Duration.zero)!;
        expect(overlay.origin, const Offset(.25, .75));
        expect(overlay.opacity, .96);
        expect(overlay.scale, .8);
        expect(overlay.blur, 7);
        expect(overlay.stops, const <double>[0, .05, .11, .19, .25]);
        expect(overlay.colors, const <Color>[
          Color(0xfaffa7e2),
          Color(0xdbff8bda),
          Color(0xc28b3eff),
          Color(0x75ffffff),
          Color(0x00ffffff),
        ]);
        expect(state.rippleCount, 1);
        expect(state.trailCount, 1);
      },
    );

    test(
      'uses source time/distance gating plus bounded rapid-wave capacity',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.5, .5),
          timestamp: Duration.zero,
        );
        state.pointerMove(
          origin: const Offset(.52, .5),
          timestamp: const Duration(milliseconds: 20),
        );
        expect(state.rippleCount, 1);
        expect(state.trailCount, 1);

        for (var index = 1; index <= 15; index += 1) {
          state.pointerMove(
            origin: Offset(.1 + index / 100, .5),
            timestamp: Duration(milliseconds: 60 * index),
          );
        }
        expect(state.rippleCount, 10);
        expect(state.trailCount, lessThanOrEqualTo(26));
      },
    );

    test(
      'field warp and pulse match the audited source equation at 50 percent ripple lifetime',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.5, .5),
          timestamp: Duration.zero,
        );

        final sample = state.fieldSampleAt(
          point: const Offset(.71, .5),
          timestamp: const Duration(microseconds: 842400),
        );
        expect(sample.coordinate, const Offset(0.7072662422299816, .5));
        expect(sample.pulseLight, closeTo(.46, 1e-12));
      },
    );

    test('trail keyframes use the audited source curve and values', () {
      final state = DashboardHeaderTapWaveState();
      state.pointerDown(origin: const Offset(.5, .5), timestamp: Duration.zero);
      final trail = state.trails.single;

      final start = state.trailSampleAt(
        trail: trail,
        timestamp: Duration.zero,
      )!;
      expect(
        (start.opacity, start.scale, start.blur, start.saturation),
        (.96, 1.0, 8.0, 2.0),
      );

      final midpoint = state.trailSampleAt(
        trail: trail,
        timestamp: const Duration(microseconds: 783000),
      )!;
      expect(
        (midpoint.opacity, midpoint.scale, midpoint.blur, midpoint.saturation),
        (.48, .58, 14.0, 1.65),
      );

      expect(
        state.trailSampleAt(
          trail: trail,
          timestamp: const Duration(milliseconds: 1350),
        ),
        isNull,
      );
    });

    test(
      'release follows the source overlay timing and drops all state after its bounded lifetime',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.5, .5),
          timestamp: Duration.zero,
        );
        state.pointerUp(timestamp: const Duration(milliseconds: 100));

        final release = state.overlayAt(const Duration(milliseconds: 100))!;
        expect(release.scale, .8);
        expect(release.blur, 7);
        expect(release.opacity, .96);
        expect(state.overlayAt(const Duration(milliseconds: 1841)), isNull);

        state.advance(const Duration(milliseconds: 1900));
        expect(state.requiresFrames, isFalse);
        expect(state.rippleCount, 0);
        expect(state.trailCount, 0);
      },
    );
  });
}
