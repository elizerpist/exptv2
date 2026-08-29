import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_category_scale.dart';

void main() {
  test(
    'G5: COMPRESSED V1 retains exact canonical category identity in slot 7',
    () {
      final scale = DashboardHeaderCategoryCompressedV1Scale.forColorId(
        'color_12',
      );

      expect(scale.slots, hasLength(10));
      expect(
        scale.slots[6],
        CategoryColorCatalog.resolve('color_12').middleColor,
      );
    },
  );

  test('G5: COMPRESSED V1 matches the approved HTML card anchors', () {
    final scale = DashboardHeaderCategoryCompressedV1Scale.forColorId(
      'color_12',
    );

    expect(
      scale.slots.map((color) => color.toARGB32()).toList(),
      const <int>[
        0xffffffff,
        0xffdff6f7,
        0xffaff6fe,
        0xff8fedff,
        0xff7ae4ff,
        0xff5bd9ff,
        0xff2bc4f3,
        0xff10afe7,
        0xff0da3dd,
        0xff0b97d3,
      ],
      reason:
          'category_palette_variation_lab.html → compressed card → V1 '
          'Spectrum 40° (lead 24°, tail 16°).',
    );
  });

  test('G5: remaining percentage is the inverse Budget palette coordinate', () {
    final scale = DashboardHeaderCategoryCompressedV1Scale.forColorId(
      'color_12',
    );

    expect(
      DashboardHeaderCategoryWindowSampler.remainingPercent(
        spentScaled100: 0,
        limitScaled100: 100000,
      ),
      100,
    );
    expect(
      DashboardHeaderCategoryWindowSampler.remainingPercent(
        spentScaled100: 100000,
        limitScaled100: 100000,
      ),
      0,
    );
    expect(
      DashboardHeaderCategoryWindowSampler.sample(
        scale: scale,
        remainingPercent: 10,
        windowWidthPercent: 28,
      ).centerPercent,
      10,
    );
  });

  test('G5: aggregate has no category scale', () {
    expect(
      DashboardHeaderCategoryCompressedV1Scale.forColorIdOrNull(null),
      isNull,
    );
  });
}
