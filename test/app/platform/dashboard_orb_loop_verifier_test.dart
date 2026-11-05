import 'dart:typed_data';

import 'package:fluvi/app/platform/dashboard_orb_loop_verifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const verifier = DashboardOrbLoopVerifier();

  test('accepts a seam whose image and motion match neighbouring samples', () {
    final result = verifier.validate(
      frames: <Uint8List>[
        _frame(128),
        _frame(178),
        _frame(200),
        _frame(178),
        _frame(128),
        _frame(78),
        _frame(56),
        _frame(78),
      ],
      candidateFrameCounts: const <int>[8],
    );

    expect(result.status, DashboardOrbLoopStatus.accepted);
    expect(result.frameCount, 8);
    expect(result.seamMeanRgbDelta, isNotNull);
    expect(result.motionChangeMeanRgbDelta, isNotNull);
  });

  test('rejects a visually large last-to-first jump even when it is best', () {
    final result = verifier.validate(
      frames: <Uint8List>[
        _frame(10),
        _frame(50),
        _frame(90),
        _frame(130),
        _frame(170),
        _frame(210),
      ],
      candidateFrameCounts: const <int>[6],
    );

    expect(result.status, DashboardOrbLoopStatus.rejected);
    expect(result.frameCount, isNull);
    expect(result.seamMeanRgbDelta, greaterThan(result.seamLimit!));
  });

  test(
    'transparent-only samples cannot report a zero-delta successful seam',
    () {
      final result = verifier.validate(
        frames: List<Uint8List>.generate(4, (_) => _frame(0, alpha: 0)),
        candidateFrameCounts: const <int>[4],
      );

      expect(result.status, DashboardOrbLoopStatus.noValidSamples);
      expect(result.frameCount, isNull);
      expect(result.seamMeanRgbDelta, isNull);
      expect(result.motionChangeMeanRgbDelta, isNull);
    },
  );
}

Uint8List _frame(int value, {int alpha = 255}) =>
    Uint8List.fromList(<int>[value, value, value, alpha]);
