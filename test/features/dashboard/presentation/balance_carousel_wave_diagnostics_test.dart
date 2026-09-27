import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_carousel_wave_diagnostics.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_carousel_wave_motion.dart';

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
      );
      for (var index = 0; index < 40; index += 1) {
        diagnostics.settingsChanged(
          animationEnabled: true,
          reducedMotion: false,
          clockRunning: true,
          waveOpacity: index / 40,
          backgroundOpacity: .6,
          borderOpacity: .4,
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
          phase: phase,
          paintBounds: const Size(160, 72),
          geometry: BalanceCarouselWaveMotion.geometryFor(
            profile: category,
            clockPhase: phase,
          ),
        );
      }

      final entries = FluviDiagnosticLogger.entries;
      final stages = entries.map((entry) => entry.stage).toSet();
      expect(stages, contains('BALANCE_WAVE|BOUND'));
      expect(stages, contains('BALANCE_WAVE|CARD_PROFILE'));
      expect(stages, contains('BALANCE_WAVE|CLOCK_SAMPLE'));
      expect(stages, contains('BALANCE_WAVE|GEOMETRY_SAMPLE'));
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
      expect(entries.length, lessThan(70), reason: 'No per-frame log flood.');
      expect(diagnostics.snapshot.clockRunning, isTrue);
      expect(diagnostics.snapshot.lastGeometryHash, isNotNull);
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
      );

      expect(diagnostics.snapshot.reducedMotion, isTrue);
      expect(diagnostics.snapshot.clockRunning, isFalse);
      expect(diagnostics.snapshot.phase, 0);
    },
  );
}
