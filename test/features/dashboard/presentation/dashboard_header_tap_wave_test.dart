import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_tap_wave.dart';

const _headerSize = Size(320, 120);

void main() {
  group('Header connected water-path source contract', () {
    test('keeps the persisted trail-size control and its safe range', () {
      final control = DashboardHeaderTapWaveCatalog.controlFor('trailSize');

      expect(
        (
          control.label,
          control.min,
          control.max,
          control.step,
          control.defaultValue,
          control.unit,
        ),
        ('Nyom mérete', 24, 160, 1, 82, 'px'),
      );
      expect(control.normalize(-1), 24);
      expect(control.normalize(500), 160);
    });

    test(
      'pointer-down retains the large tap wave but creates no dot trail',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.25, .75),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );

        final overlay = state.overlayAt(Duration.zero)!;
        expect(overlay.origin, const Offset(.25, .75));
        expect(overlay.opacity, .96);
        expect(overlay.scale, .8);
        expect(overlay.blur, 7);
        expect(overlay.stops, const <double>[0, .05, .11, .19, .25]);
        expect(state.rippleCount, 1);
        expect(state.trailCount, 1);
        expect(state.isDragging, isFalse);
        expect(state.trails.single.connectsToPrevious, isFalse);
      },
    );

    test('hand tremor stays a tap and never retriggers circular ripples', () {
      final state = DashboardHeaderTapWaveState();
      state.pointerDown(
        origin: const Offset(.5, .5),
        timestamp: Duration.zero,
        logicalSize: _headerSize,
      );
      state.pointerMove(
        origin: const Offset(.506, .5),
        logicalDelta: const Offset(2, 0),
        logicalSize: _headerSize,
        timestamp: const Duration(milliseconds: 18),
      );
      state.pointerMove(
        origin: const Offset(.5, .5),
        logicalDelta: const Offset(-2, 0),
        logicalSize: _headerSize,
        timestamp: const Duration(milliseconds: 36),
      );

      expect(state.isDragging, isFalse);
      expect(state.rippleCount, 1);
      expect(state.trailCount, 1);
      expect(state.overlayAt(const Duration(milliseconds: 36)), isNotNull);
    });

    test(
      'sparse and dense pointer delivery both produce connected path pieces',
      () {
        final sparse = DashboardHeaderTapWaveState();
        sparse.pointerDown(
          origin: const Offset(.1, .5),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );
        sparse.pointerMove(
          origin: const Offset(.8, .5),
          logicalDelta: const Offset(224, 0),
          logicalSize: _headerSize,
          timestamp: const Duration(milliseconds: 140),
        );

        final dense = DashboardHeaderTapWaveState();
        dense.pointerDown(
          origin: const Offset(.1, .5),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );
        for (var index = 1; index <= 7; index += 1) {
          dense.pointerMove(
            origin: Offset(.1 + index * .1, .5),
            logicalDelta: const Offset(32, 0),
            logicalSize: _headerSize,
            timestamp: Duration(milliseconds: index * 20),
          );
        }

        expect(sparse.isDragging, isTrue);
        expect(dense.isDragging, isTrue);
        expect(sparse.rippleCount, 1);
        expect(dense.rippleCount, 1);
        expect(sparse.trailCount, greaterThan(2));
        expect(dense.trailCount, greaterThan(2));
        for (final state in <DashboardHeaderTapWaveState>[sparse, dense]) {
          final samples = state.trails.toList(growable: false);
          for (var index = 1; index < samples.length; index += 1) {
            final previous = samples[index - 1];
            final current = samples[index];
            expect(current.connectsToPrevious, isTrue);
            expect(
              (current.origin - previous.origin).distance * _headerSize.width,
              lessThanOrEqualTo(6.01),
            );
            expect(current.startedAt, greaterThanOrEqualTo(previous.startedAt));
          }
        }
      },
    );

    test('path samples have local ages and finite, bounded velocity', () {
      final state = DashboardHeaderTapWaveState();
      state.pointerDown(
        origin: const Offset(.2, .5),
        timestamp: Duration.zero,
        logicalSize: _headerSize,
      );
      // Same input timestamp is explicitly valid; velocity cannot become NaN
      // or explode just because two moves arrived in one render frame.
      state.pointerMove(
        origin: const Offset(.4, .5),
        logicalDelta: const Offset(64, 0),
        logicalSize: _headerSize,
        timestamp: const Duration(milliseconds: 20),
      );
      state.pointerMove(
        origin: const Offset(.6, .5),
        logicalDelta: const Offset(64, 0),
        logicalSize: _headerSize,
        timestamp: const Duration(milliseconds: 20),
      );

      final samples = state.trails.toList(growable: false);
      final older = state.trailSampleAt(
        trail: samples.first,
        timestamp: const Duration(milliseconds: 120),
      )!;
      final newer = state.trailSampleAt(
        trail: samples.last,
        timestamp: const Duration(milliseconds: 120),
      )!;
      expect(older.age, greaterThanOrEqualTo(newer.age));
      expect(newer.velocity, inInclusiveRange(0, 1));
      expect(newer.velocity.isFinite, isTrue);
    });

    test(
      'an S turn has no spline overshoot and a stationary finger adds nothing',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.2, .5),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );
        state.pointerMove(
          origin: const Offset(.45, .25),
          logicalDelta: const Offset(80, -30),
          logicalSize: _headerSize,
          timestamp: const Duration(milliseconds: 40),
        );
        state.pointerMove(
          origin: const Offset(.7, .75),
          logicalDelta: const Offset(80, 60),
          logicalSize: _headerSize,
          timestamp: const Duration(milliseconds: 80),
        );
        final beforeStationary = state.trailCount;
        state.pointerMove(
          origin: const Offset(.7, .75),
          logicalDelta: Offset.zero,
          logicalSize: _headerSize,
          timestamp: const Duration(milliseconds: 120),
        );

        expect(state.trailCount, beforeStationary);
        for (final sample in state.trails) {
          expect(sample.origin.dx, inInclusiveRange(.2, .7));
          expect(sample.origin.dy, inInclusiveRange(.25, .75));
        }
      },
    );

    test('a Header resize cannot become artificial path velocity', () {
      final state = DashboardHeaderTapWaveState();
      state.pointerDown(
        origin: const Offset(.2, .5),
        timestamp: Duration.zero,
        logicalSize: _headerSize,
      );
      state.pointerMove(
        origin: const Offset(.4, .5),
        logicalDelta: const Offset(64, 0),
        logicalSize: _headerSize,
        timestamp: const Duration(milliseconds: 40),
      );
      final beforeResize = state.trailCount;
      state.pointerMove(
        origin: const Offset(.4, .5),
        logicalDelta: Offset.zero,
        logicalSize: const Size(320, 72),
        timestamp: const Duration(milliseconds: 60),
      );

      expect(state.trailCount, beforeResize);
      state.pointerMove(
        origin: const Offset(.46, .5),
        logicalDelta: const Offset(19.2, 0),
        logicalSize: const Size(320, 72),
        timestamp: const Duration(milliseconds: 80),
      );
      expect(state.trails.last.connectsToPrevious, isFalse);
      expect(state.trails.last.velocity, inInclusiveRange(0, 1));
    });

    test(
      'outside detours and separate contacts never receive joining segments',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.2, .5),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );
        state.pointerMove(
          origin: const Offset(.4, .5),
          logicalDelta: const Offset(64, 0),
          logicalSize: _headerSize,
          timestamp: const Duration(milliseconds: 40),
        );
        state.breakPath();
        state.pointerMove(
          origin: const Offset(.8, .5),
          logicalDelta: const Offset(24, 0),
          logicalSize: _headerSize,
          timestamp: const Duration(milliseconds: 80),
        );
        expect(state.trails.last.connectsToPrevious, isFalse);

        state.pointerUp(timestamp: const Duration(milliseconds: 90));
        state.pointerDown(
          origin: const Offset(.1, .2),
          timestamp: const Duration(milliseconds: 120),
          logicalSize: _headerSize,
        );
        expect(state.trails.last.connectsToPrevious, isFalse);
        expect(state.rippleCount, 2);
      },
    );

    test('drag retracts the tap overlay and never restarts it on release', () {
      final state = DashboardHeaderTapWaveState();
      state.pointerDown(
        origin: const Offset(.2, .5),
        timestamp: Duration.zero,
        logicalSize: _headerSize,
      );
      state.pointerMove(
        origin: const Offset(.4, .5),
        logicalDelta: const Offset(64, 0),
        logicalSize: _headerSize,
        timestamp: const Duration(milliseconds: 20),
      );

      expect(state.overlayAt(const Duration(milliseconds: 20)), isNotNull);
      expect(state.overlayAt(const Duration(milliseconds: 105)), isNull);
      state.pointerUp(timestamp: const Duration(milliseconds: 110));
      expect(state.overlayAt(const Duration(milliseconds: 111)), isNull);
    });

    test(
      'capacity remains at 24 connected segments and all state cleans up',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.05, .5),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );
        for (var index = 1; index <= 45; index += 1) {
          state.pointerMove(
            origin: Offset(.05 + index * .018, .5),
            logicalDelta: const Offset(5.76, 0),
            logicalSize: _headerSize,
            timestamp: Duration(milliseconds: index * 18),
          );
        }
        expect(
          state.trailCount,
          lessThanOrEqualTo(DashboardHeaderTapWaveState.maxTrailSamples),
        );
        expect(
          state.trailCount - 1,
          lessThanOrEqualTo(DashboardHeaderTapWaveState.maxTrailSegments),
        );
        expect(state.trails.first.connectsToPrevious, isFalse);

        state.pointerUp(timestamp: const Duration(milliseconds: 820));
        state.advance(const Duration(milliseconds: 2600));
        expect(state.requiresFrames, isFalse);
        expect(state.rippleCount, 0);
        expect(state.trailCount, 0);
      },
    );
  });
}
