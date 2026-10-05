import 'package:fluvi/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fluvi_wave_fixture.dart';

void main() {
  test('HS-04 the inner return preserves the mountain cross-section', () {
    final terrain = FluviTopographicWaveTerrain.resolve(
      values: waveData(waveLinked(waveReferenceForints)),
      size: const Size(240, 128),
    );
    final rimProminence =
        terrain.ridgeSamples[10 * 14].dy - terrain.ridgeSamples[14 * 14].dy;
    for (final depth in [.9, .95, 1.0]) {
      final prominence =
          terrain.shell!.sample(10 * 14, depth).position.dy -
          terrain.shell!.sample(14 * 14, depth).position.dy;
      // The returned mountain stays comparable to the genuine rim. The
      // foreground turn is deliberately lower and broader in the reference;
      // its separate anti-flattening/ordering test must not require half-height.
      expect(prominence, greaterThan(rimProminence / 2));
    }
  });
  test('HS-04 the visible outer turn is oblique, not only its far endpoint', () {
    final terrain = FluviTopographicWaveTerrain.resolve(
      values: waveData(waveLinked(waveReferenceForints)),
      size: const Size(240, 128),
    );
    final column = terrain.highestIndex! * 14;
    for (final depth in [.15, .25, .5]) {
      final delta =
          terrain.shell!.sample(column, depth).position -
          terrain.ridgeSamples[column];
      // Expected crop: the central rim's right shoulder moves roughly 20px
      // right over 50px down. Allow a less oblique 1:3 continuation, but reject
      // a nearly vertical outer face with displacement only at the far end.
      expect(delta.dx, greaterThan(delta.dy / 3));
    }
  });
  test('HS-04 the rounded turn must not collapse peaks to a common floor', () {
    final terrain = FluviTopographicWaveTerrain.resolve(
      values: waveData(waveLinked(waveReferenceForints)),
      size: const Size(240, 128),
    );
    for (final depth in [.45, .5, .55, .6]) {
      final peak = terrain.shell!.sample(14 * 14, depth).position;
      final valley = terrain.shell!.sample(10 * 14, depth).position;
      expect(
        valley.dy - peak.dy,
        greaterThan(1),
        reason:
            'The peak/valley continuation at the turn must remain visible beyond the roughly one-logical-pixel rim, not flatten into a common floor.',
      );
    }
  });
  test('HS-04 curved turn, foreshortening and normals belong to one shell', () {
    for (final size in [
      const Size(240, 128),
      const Size(194, 96),
      const Size(320, 200),
    ]) {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: waveData(waveLinked(waveReferenceForints)),
        size: size,
      );
      final shell = terrain.shell!;
      expect(
        shell.vertexCount,
        terrain.ridgeSamples.length * FluviWaveShell.rows,
      );
      expect(shell.vertexCount, lessThan(65536));
      final peak = terrain.highestIndex! * 14;
      final rim = shell.sample(peak, 0);
      final turn = shell.sample(peak, .5);
      final returned = shell.sample(peak, 1);
      expect(rim.position, terrain.dataOffsets[terrain.highestIndex!]);
      expect(
        turn.position.dy,
        greaterThan(returned.position.dy),
        reason:
            'The section must bend back inward, not be a straight extrusion.',
      );
      expect(turn.normal, isNot(rim.normal));
      expect(returned.normal, isNot(turn.normal));
      final firstDelta =
          shell.sample(0, 1).position - terrain.ridgeSamples.first;
      final lastDelta =
          shell.sample(terrain.ridgeSamples.length - 1, 1).position -
          terrain.ridgeSamples.last;
      expect(
        lastDelta.dx,
        lessThan(firstDelta.dx),
        reason: 'Foreshortening, not uniformly shifted copies.',
      );
      for (var column = 0; column < terrain.ridgeSamples.length; column++) {
        for (var row = 0; row < FluviWaveShell.rows; row++) {
          final point = shell.sample(column, row / (FluviWaveShell.rows - 1));
          expect((Offset.zero & size).contains(point.position), isTrue);
          final n = point.normal;
          expect(n.$1 * n.$1 + n.$2 * n.$2 + n.$3 * n.$3, closeTo(1, 1e-9));
        }
      }
    }
  });
  test('HS-04 inner return retains corresponding financial peak landmarks', () {
    final terrain = FluviTopographicWaveTerrain.resolve(
      values: waveData(waveLinked(waveReferenceForints)),
      size: const Size(240, 128),
    );
    for (var day = 1; day < waveReferenceForints.length - 1; day++) {
      if (waveReferenceForints[day] > waveReferenceForints[day - 1] &&
          waveReferenceForints[day] > waveReferenceForints[day + 1]) {
        final returned = terrain.surfaceFootSamples[day * 14];
        expect(
          returned.dy,
          lessThan(terrain.surfaceFootSamples[(day - 1) * 14].dy),
        );
        expect(
          returned.dy,
          lessThan(terrain.surfaceFootSamples[(day + 1) * 14].dy),
        );
      }
    }
  });
  test('HS-04 corresponding shell features continue right and down', () {
    for (final amounts in [waveReferenceForints, waveSparseForints(31)]) {
      final terrain = FluviTopographicWaveTerrain.resolve(
        values: waveData(waveLinked(amounts)),
        size: const Size(240, 128),
      );
      for (var i = 0; i < terrain.ridgeSamples.length; i++) {
        final rim = terrain.ridgeSamples[i];
        final inner = terrain.surfaceFootSamples[i];
        expect(
          inner.dx,
          greaterThan(rim.dx),
          reason: 'Corresponding feature $i must enter rightward depth.',
        );
        expect(
          inner.dy,
          greaterThan(rim.dy),
          reason: 'The return belongs below, not on a frontal duplicate rim.',
        );
      }
    }
  });
}
