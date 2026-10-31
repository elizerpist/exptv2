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
      'new personal defaults keep the large overlay inactive until release',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.25, .75),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );

        expect(state.overlayAt(Duration.zero), isNull);
        expect(state.rippleCount, 0);
        expect(state.trailCount, 1);
        expect(state.isDragging, isFalse);
        expect(state.trails.single.connectsToPrevious, isFalse);
        state.pointerUp(timestamp: const Duration(milliseconds: 10));
        final overlay = state.overlayAt(const Duration(milliseconds: 10))!;
        expect(overlay.origin, const Offset(.25, .75));
        expect(overlay.opacity, closeTo(.72, 1e-12));
        expect(overlay.scale, closeTo(.44, 1e-12));
        expect(overlay.blur, 7);
        expect(overlay.stops, const <double>[0, .05, .11, .19, .25]);
        expect(state.rippleCount, 1);
      },
    );

    test('100 / 100 / 100 is the exact current-source reference', () {
      final state = DashboardHeaderTapWaveState()
        ..configure(
          DashboardHeaderTapWaveTuning.defaults().asCurrentReference(),
        )
        ..pointerDown(
          origin: const Offset(.25, .75),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        );

      expect(state.overlayAt(Duration.zero), isNull);

      state.pointerUp(timestamp: Duration.zero);
      final referenceAt180 = state.overlayAt(
        const Duration(milliseconds: 180),
      )!;
      final personal = DashboardHeaderTapWaveState()
        ..pointerDown(
          origin: const Offset(.25, .75),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        )
        ..pointerUp(timestamp: Duration.zero);
      expect(
        personal.overlayAt(const Duration(milliseconds: 180))!.scale,
        closeTo(referenceAt180.scale, 1e-12),
      );
    });

    test(
      'zero tap strength removes overlay and field light without changing time',
      () {
        final state = DashboardHeaderTapWaveState()
          ..configure(
            DashboardHeaderTapWaveTuning.defaults().copyWithValue(
              DashboardHeaderTapWaveCatalog.tapStrengthId,
              0,
            ),
          )
          ..pointerDown(
            origin: const Offset(.5, .5),
            timestamp: Duration.zero,
            logicalSize: _headerSize,
          );
        state.pointerUp(timestamp: Duration.zero);
        final overlay = state.overlayAt(Duration.zero)!;
        final field = state.fieldSampleAt(
          point: const Offset(.6, .5),
          timestamp: const Duration(milliseconds: 80),
        );
        expect(overlay.opacity, 0);
        expect(field.coordinate, const Offset(.6, .5));
        expect(field.pulseLight, 0);
      },
    );

    test('allocated and retained overlay frames use one scale calculation', () {
      final state = DashboardHeaderTapWaveState()
        ..pointerDown(
          origin: const Offset(.2, .3),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        )
        ..pointerUp(timestamp: Duration.zero);
      final retained = DashboardHeaderTapWaveOverlayFrame();
      state.writeOverlayFrame(
        timestamp: const Duration(milliseconds: 96),
        into: retained,
      );
      final allocated = state.overlayAt(const Duration(milliseconds: 96))!;
      expect(retained.scale, closeTo(allocated.scale, 1e-12));
      expect(retained.opacity, closeTo(allocated.opacity, 1e-12));
    });

    test(
      'tap speed scales one local release clock without changing its path',
      () {
        DashboardHeaderTapWaveState releaseAt(double speed) =>
            DashboardHeaderTapWaveState()
              ..configure(
                DashboardHeaderTapWaveTuning.defaults().copyWithValue(
                  DashboardHeaderTapWaveCatalog.tapSpeedId,
                  speed,
                ),
              )
              ..pointerDown(
                origin: const Offset(.5, .5),
                timestamp: Duration.zero,
                logicalSize: _headerSize,
              )
              ..pointerUp(timestamp: Duration.zero);

        final slow = releaseAt(
          50,
        ).overlayAt(const Duration(milliseconds: 120))!;
        final normal = releaseAt(
          100,
        ).overlayAt(const Duration(milliseconds: 120))!;
        final fast = releaseAt(
          200,
        ).overlayAt(const Duration(milliseconds: 120))!;

        expect(slow.scale, lessThan(normal.scale));
        expect(normal.scale, lessThan(fast.scale));
        expect(slow.opacity, greaterThan(normal.opacity));
        expect(normal.opacity, greaterThan(fast.opacity));
      },
    );

    test(
      'drag-ring lifetime owns both CPU expiry and normalized shader age',
      () {
        DashboardHeaderTapWaveState dragged(double lifetime) {
          final state = DashboardHeaderTapWaveState()
            ..configure(
              DashboardHeaderTapWaveTuning.defaults().copyWithValue(
                DashboardHeaderTapWaveCatalog.dragRippleLifetimeId,
                lifetime,
              ),
            )
            ..pointerDown(
              origin: const Offset(.1, .5),
              timestamp: Duration.zero,
              logicalSize: _headerSize,
            )
            ..pointerMove(
              origin: const Offset(.3, .5),
              logicalDelta: const Offset(64, 0),
              logicalSize: _headerSize,
              timestamp: const Duration(milliseconds: 80),
            );
          return state;
        }

        final short = dragged(.40);
        final long = dragged(2);
        final sample = long.trails.last;
        short.advance(const Duration(milliseconds: 600));
        long.advance(const Duration(milliseconds: 600));

        expect(short.trailCount, 0);
        expect(
          long.trailSampleAt(
            trail: sample,
            timestamp: const Duration(milliseconds: 600),
          ),
          isNotNull,
        );
      },
    );

    test('cancel closes the live touch without creating a release ripple', () {
      final state = DashboardHeaderTapWaveState()
        ..pointerDown(
          origin: const Offset(.5, .5),
          timestamp: Duration.zero,
          logicalSize: _headerSize,
        )
        ..pointerUp(
          timestamp: const Duration(milliseconds: 20),
          emitReleaseRipple: false,
        );

      expect(state.rippleCount, 0);
      expect(state.overlayAt(const Duration(milliseconds: 21)), isNull);
    });

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
      expect(state.rippleCount, 0);
      expect(state.trailCount, 1);
      expect(state.overlayAt(const Duration(milliseconds: 36)), isNull);
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
        expect(sparse.rippleCount, 0);
        expect(dense.rippleCount, 0);
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
              lessThanOrEqualTo(12.01),
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
        // The previous contact generated one release wave; a new press does
        // not erase it and does not create another until its own release.
        expect(state.rippleCount, 1);
      },
    );

    test(
      'drag keeps its live point and release starts exactly one large wave',
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
          timestamp: const Duration(milliseconds: 20),
        );

        expect(state.overlayAt(const Duration(milliseconds: 20)), isNull);
        expect(state.overlayAt(const Duration(milliseconds: 105)), isNull);
        state.pointerUp(timestamp: const Duration(milliseconds: 110));
        expect(state.overlayAt(const Duration(milliseconds: 111)), isNotNull);
        expect(state.rippleCount, 1);
      },
    );

    test(
      'retained production overlay is release-only and keeps its origin across a new press',
      () {
        final state = DashboardHeaderTapWaveState()
          ..pointerDown(
            origin: const Offset(.2, .3),
            timestamp: Duration.zero,
            logicalSize: _headerSize,
          );
        final frame = DashboardHeaderTapWaveOverlayFrame();
        state.writeOverlayFrame(timestamp: Duration.zero, into: frame);
        expect(frame.active, 0);

        state.pointerUp(
          timestamp: const Duration(milliseconds: 20),
          releaseOrigin: const Offset(.7, .8),
        );
        state.writeOverlayFrame(
          timestamp: const Duration(milliseconds: 21),
          into: frame,
        );
        expect(frame.active, 1);
        expect(frame.x, closeTo(.7, 1e-12));
        expect(frame.y, closeTo(.8, 1e-12));

        state.pointerDown(
          origin: const Offset(.1, .1),
          timestamp: const Duration(milliseconds: 30),
          logicalSize: _headerSize,
        );
        state.writeOverlayFrame(
          timestamp: const Duration(milliseconds: 31),
          into: frame,
        );
        expect(frame.active, 1);
        expect(frame.x, closeTo(.7, 1e-12));
        expect(frame.y, closeTo(.8, 1e-12));
      },
    );

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
