import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/fluvi_surface_fill.dart';

void main() {
  test('custom two-endpoint boundary moves a fixed visible middle stop', () {
    const fill = FluviSurfaceFill(
      leftArgb: 0xFF000000,
      rightArgb: 0xFFFFFFFF,
      boundaryPercent: 20,
    );

    final moved = fill.copyWith(boundaryPercent: 80);
    expect(fill.effectiveMiddle.r, closeTo(.5, .0001));
    expect(moved.effectiveMiddle.r, closeTo(.5, .0001));
    expect(fill.gradient().stops, <double>[0, .2, 1]);
    expect(moved.gradient().stops, <double>[0, .8, 1]);
  });

  test('explicit catalog middle is retained while its stop moves', () {
    const fill = FluviSurfaceFill(
      leftArgb: 0xFF001122,
      middleArgb: 0xFF334455,
      rightArgb: 0xFF667788,
      boundaryPercent: 52,
    );
    final moved = fill.copyWith(boundaryPercent: 20);
    expect(moved.effectiveMiddle.toARGB32(), 0xFF334455);
    expect(moved.gradient().stops, <double>[0, .2, 1]);
  });

  test(
    'appearance round trip retains independent applied values and slots',
    () {
      final original = FluviBrandSurfaceAppearance.defaults
          .copyWith(
            pageBackground: const FluviSurfaceFill(
              leftArgb: 0xFF112233,
              rightArgb: 0xFF445566,
              boundaryPercent: 31,
            ),
          )
          .withCustomSlot(
            2,
            const FluviSurfaceFill(
              leftArgb: 0xFF123456,
              rightArgb: 0xFF654321,
              boundaryPercent: 72,
            ),
          );

      expect(FluviBrandSurfaceAppearance.decode(original.encode()), original);
    },
  );

  test('invalid persisted appearance falls back deterministically', () {
    expect(
      FluviBrandSurfaceAppearance.decode('{"version":1,"logoTop":null}'),
      FluviBrandSurfaceAppearance.defaults,
    );
  });
}
