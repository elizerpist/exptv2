import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/channel_tolerance_golden_comparator.dart';

void main() {
  test(
    'accepts only per-channel raster rounding within the configured delta',
    () {
      final expected = Uint8List.fromList(<int>[
        10,
        20,
        30,
        255,
        100,
        110,
        120,
        255,
      ]);
      final withinTolerance = Uint8List.fromList(<int>[
        12,
        18,
        31,
        255,
        98,
        112,
        120,
        255,
      ]);
      final outsideTolerance = Uint8List.fromList(<int>[
        13,
        20,
        30,
        255,
        100,
        110,
        120,
        255,
      ]);

      expect(
        countPixelsOutsideChannelTolerance(
          withinTolerance,
          expected,
          maxChannelDelta: 2,
        ),
        0,
      );
      expect(
        countPixelsOutsideChannelTolerance(
          outsideTolerance,
          expected,
          maxChannelDelta: 2,
        ),
        1,
      );
    },
  );

  test('rejects image buffers with different geometry-sized payloads', () {
    expect(
      countPixelsOutsideChannelTolerance(
        Uint8List(4),
        Uint8List(8),
        maxChannelDelta: 2,
      ),
      -1,
    );
  });
}
