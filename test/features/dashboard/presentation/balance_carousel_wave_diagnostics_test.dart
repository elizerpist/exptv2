import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_carousel_wave_diagnostics.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_carousel_wave_motion.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';

void main() {
  setUp(FluviDiagnosticLogger.clear);

  test(
    'BALANCE_WAVE diagnostics observe one periodic clock, distinct geometry, a seam, and bounded samples',
    () {
      final diagnostics = BalanceCarouselWaveRuntimeDiagnostics(
        clockOwner: 'test-carousel',
        configuredDuration: const Duration(seconds: 6),
      );
      final category = BalanceCarouselWaveMotion.profileForCardId(
        'top-category',
      );
      final partner = BalanceCarouselWaveMotion.profileForCardId('top-partner');
      diagnostics.bind(
        animationEnabled: true,
        reducedMotion: false,
        clockRunning: true,
        waveOpacity: .8,
        backgroundOpacity: .6,
        speedMultiplier: 1,
        effectiveDuration: balanceCarouselWaveBaseDuration,
      );
      diagnostics.bindProfile(category, selected: true);
      diagnostics.bindProfile(partner, selected: false);
      diagnostics.settingsChanged(
        animationEnabled: true,
        reducedMotion: false,
        clockRunning: true,
        waveOpacity: .7,
        backgroundOpacity: .6,
        borderOpacity: .4,
        speedMultiplier: 1,
        effectiveDuration: balanceCarouselWaveBaseDuration,
      );
      for (var index = 0; index < 40; index += 1) {
        diagnostics.settingsChanged(
          animationEnabled: true,
          reducedMotion: false,
          clockRunning: true,
          waveOpacity: index / 40,
          backgroundOpacity: .6,
          borderOpacity: .4,
          speedMultiplier: 1,
          effectiveDuration: balanceCarouselWaveBaseDuration,
        );
      }

      final start = BalanceCarouselWaveMotion.geometryFor(
        profile: category,
        clockPhase: 0,
      );
      final later = BalanceCarouselWaveMotion.geometryFor(
        profile: category,
        clockPhase: .25,
      );
      final partnerLater = BalanceCarouselWaveMotion.geometryFor(
        profile: partner,
        clockPhase: .25,
      );
      expect(
        BalanceCarouselWaveMotion.geometryDigest(start),
        isNot(BalanceCarouselWaveMotion.geometryDigest(later)),
      );
      expect(
        BalanceCarouselWaveMotion.geometryDigest(later),
        isNot(BalanceCarouselWaveMotion.geometryDigest(partnerLater)),
      );

      // More than half a minute of 60-ish fps input must retain only the
      // bounded forensic window, not continuously evict unrelated evidence.
      for (var frame = 0; frame <= 2000; frame += 1) {
        final phase = (frame % 100) / 100;
        diagnostics.onTick(
          elapsed: Duration(milliseconds: frame * 16),
          phase: phase,
          buildRevision: 1,
        );
        diagnostics.onPaint(
          profile: category,
          globalPhase: phase,
          paintBounds: const Size(160, 72),
          geometry: BalanceCarouselWaveMotion.geometryFor(
            profile: category,
            clockPhase: phase,
          ),
          effectiveWaveAlpha: .24,
          finalTintAlpha: .075,
          painterRevision: frame + 1,
        );
      }

      final entries = FluviDiagnosticLogger.entries;
      final stages = entries.map((entry) => entry.stage).toSet();
      expect(stages, contains('BALANCE_WAVE|BOUND'));
      expect(stages, contains('BALANCE_WAVE|CARD_PROFILE'));
      expect(stages, contains('BALANCE_WAVE|CLOCK_SAMPLE'));
      expect(stages, contains('BALANCE_WAVE|GEOMETRY_SAMPLE'));
      expect(stages, contains('BALANCE_WAVE|VISIBLE_MOTION_SAMPLE'));
      expect(stages, contains('BALANCE_WAVE|LOOP_BOUNDARY'));
      expect(stages, contains('BALANCE_WAVE|FRAME_SUMMARY'));
      expect(stages, contains('BALANCE_WAVE|SETTINGS_CHANGED'));
      final loopBoundaries = entries
          .where((entry) => entry.stage == 'BALANCE_WAVE|LOOP_BOUNDARY')
          .toList(growable: false);
      expect(loopBoundaries, isNotEmpty);
      for (final boundary in loopBoundaries) {
        expect(boundary.scope, contains('discontinuityDetected=false'));
      }
      expect(
        entries
            .where((entry) => entry.stage == 'BALANCE_WAVE|FRAME_SUMMARY')
            .length,
        lessThanOrEqualTo(4),
        reason: 'Frame summaries stop after the bounded observation window.',
      );
      expect(
        entries
            .where((entry) => entry.stage == 'BALANCE_WAVE|SETTINGS_CHANGED')
            .length,
        lessThanOrEqualTo(16),
        reason: 'A slider cannot flood the shared diagnostic ring.',
      );
      expect(
        entries.length,
        lessThan(100),
        reason:
            'Geometry and final-visible samples are both bounded; there is no per-frame log flood.',
      );
      expect(diagnostics.snapshot.clockRunning, isTrue);
      expect(diagnostics.snapshot.lastGeometryHash, isNotNull);
      expect(diagnostics.snapshot.speedMultiplier, 1);
      expect(diagnostics.snapshot.effectiveDurationMs, 6000);
      final visibleSamples = entries
          .where((entry) => entry.stage == 'BALANCE_WAVE|VISIBLE_MOTION_SAMPLE')
          .toList(growable: false);
      expect(visibleSamples, isNotEmpty);
      expect(
        visibleSamples.last.scope,
        allOf(
          contains('resolvedLocalPhase='),
          contains('visibleWavePeakToPeakPx='),
          contains('effectiveWaveAlpha=0.240'),
          contains('painterRevision='),
        ),
      );
    },
  );

  test(
    'BALANCE_WAVE diagnostics preserve a static reduced-motion snapshot',
    () {
      final diagnostics = BalanceCarouselWaveRuntimeDiagnostics(
        clockOwner: 'test-carousel',
        configuredDuration: const Duration(seconds: 6),
      );
      diagnostics.bind(
        animationEnabled: true,
        reducedMotion: true,
        clockRunning: false,
        waveOpacity: 1,
        backgroundOpacity: 1,
        speedMultiplier: 1,
        effectiveDuration: balanceCarouselWaveBaseDuration,
      );

      expect(diagnostics.snapshot.reducedMotion, isTrue);
      expect(diagnostics.snapshot.clockRunning, isFalse);
      expect(diagnostics.snapshot.phase, 0);
    },
  );

  test('BALANCE_WAVE speed evidence is bounded and phase-continuous', () {
    final diagnostics = BalanceCarouselWaveRuntimeDiagnostics(
      clockOwner: 'test-carousel',
      configuredDuration: balanceCarouselWaveBaseDuration,
    );
    diagnostics.bind(
      animationEnabled: true,
      reducedMotion: false,
      clockRunning: true,
      waveOpacity: 1,
      backgroundOpacity: 1,
      speedMultiplier: 1,
      effectiveDuration: balanceCarouselWaveBaseDuration,
    );

    diagnostics.speedChanged(
      oldMultiplier: 1,
      newMultiplier: 2,
      phaseBefore: .42,
      phaseAfter: .42,
      effectiveDuration: const Duration(seconds: 3),
      controllerRecreated: false,
    );

    final event = FluviDiagnosticLogger.entries.singleWhere(
      (entry) => entry.stage == 'BALANCE_WAVE|SPEED_CHANGED',
    );
    expect(
      event.scope,
      allOf(
        contains('oldMultiplier=1.000'),
        contains('newMultiplier=2.000'),
        contains('effectiveDurationMs=3000'),
        contains('controllerRecreated=false'),
        contains('discontinuityDetected=false'),
      ),
    );
  });
}
