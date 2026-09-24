import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart';

void main() {
  test(
    'the four pre-existing Balance family × variant anchors remain exact',
    () {
      final expected =
          <
            DashboardBalanceHeaderPalette,
            Map<DashboardBalanceHeaderPaletteVariant, List<int>>
          >{
            DashboardBalanceHeaderPalette.softRainbow: _variants(
              <int>[
                0xfffbf8cc,
                0xfffde4cf,
                0xffffcfd2,
                0xfff1c0e8,
                0xffcfbaf0,
                0xffa3c4f3,
                0xff90dbf4,
                0xff8eecf5,
                0xff98f5e1,
                0xffb9fbc0,
              ],
              <int>[
                0xfffff99f,
                0xffffcea4,
                0xffffa6ac,
                0xffff89e9,
                0xffb382ff,
                0xff6eaaff,
                0xff5cd6ff,
                0xff5bf1ff,
                0xff65ffde,
                0xff8cff98,
              ],
              <int>[
                0xffffd81a,
                0xffff9d45,
                0xffff6674,
                0xfff044c7,
                0xff8a5cff,
                0xff3d84f7,
                0xff27c0eb,
                0xff20dde4,
                0xff28ddb4,
                0xff58e66b,
              ],
            ),
            DashboardBalanceHeaderPalette.levanderRoseEmbrace: _variants(
              <int>[0xffaf99ff, 0xffcaadff, 0xffffc2e2, 0xffffadc7, 0xffff99b6],
              <int>[0xff9678ff, 0xffb388ff, 0xffff9ed6, 0xffff7fae, 0xffff6a95],
              <int>[0xff7a52ff, 0xff9f66ff, 0xffff78cb, 0xffff4f96, 0xffff3380],
            ),
            DashboardBalanceHeaderPalette.limitColorLab: _variants(
              <int>[
                0xff6d28d9,
                0xff8b5cf6,
                0xffa78bfa,
                0xffd8b4fe,
                0xfffbcfe8,
                0xfff9a8d4,
                0xfff472b6,
                0xffec4899,
                0xffe23883,
                0xffdb2777,
              ],
              <int>[
                0xff5b1acf,
                0xff7c3ff2,
                0xff9568f7,
                0xffc99afd,
                0xfff8a8d8,
                0xfff678bf,
                0xffec409f,
                0xffe51e7e,
                0xffd81f6e,
                0xffc9165f,
              ],
              <int>[
                0xff4a0fbf,
                0xff6829e8,
                0xff7e3ef5,
                0xffb876fb,
                0xfff48ace,
                0xfff43ea8,
                0xffe91a85,
                0xffd7006b,
                0xffc10058,
                0xffad004b,
              ],
            ),
            DashboardBalanceHeaderPalette.customBalance: _variants(
              <int>[
                0xff7c5cff,
                0xff9b7bff,
                0xffb794ff,
                0xffd9a1f3,
                0xfff08bd6,
                0xffff7bb7,
                0xffff6ea4,
                0xffff8a7a,
                0xffff9b5f,
                0xffffb36b,
              ],
              <int>[
                0xff6842ff,
                0xff8758ff,
                0xffa272ff,
                0xffca78ec,
                0xffed5ac6,
                0xffff4ba4,
                0xffff3b8a,
                0xffff6a58,
                0xffff7f36,
                0xffffa74a,
              ],
              <int>[
                0xff5628ff,
                0xff7139ff,
                0xff924eff,
                0xffbb4fe8,
                0xffe331b7,
                0xffff228c,
                0xffff0f6e,
                0xffff4b36,
                0xffff6a14,
                0xffff9526,
              ],
            ),
          };

      expect(
        DashboardBalanceHeaderPaletteCatalog.palettes.take(4),
        <DashboardBalanceHeaderPalette>[
          DashboardBalanceHeaderPalette.softRainbow,
          DashboardBalanceHeaderPalette.levanderRoseEmbrace,
          DashboardBalanceHeaderPalette.limitColorLab,
          DashboardBalanceHeaderPalette.customBalance,
        ],
      );
      expect(DashboardBalanceHeaderPaletteCatalog.palettes, hasLength(8));
      expect(DashboardBalanceHeaderPaletteCatalog.variants, hasLength(3));
      expect(
        expected.length * DashboardBalanceHeaderPaletteCatalog.variants.length,
        12,
      );
      for (final family in expected.keys) {
        final variants = expected[family]!;
        for (final variant in DashboardBalanceHeaderPaletteCatalog.variants) {
          final actual = DashboardBalanceHeaderPaletteCatalog.scaleFor(
            family,
            variant,
          );
          expect(actual.palette, family);
          expect(actual.variant, variant);
          expect(actual.colors, variants[variant]!.map(Color.new).toList());
          expect(
            actual.colors.length,
            variants[DashboardBalanceHeaderPaletteVariant.original]!.length,
          );
        }
      }
    },
  );

  test('default, copy and sampler preserve variant identity and geometry', () {
    const defaults = DashboardBalanceHeaderColorState.defaults();
    expect(defaults.palette, DashboardBalanceHeaderPalette.softRainbow);
    expect(defaults.variant, DashboardBalanceHeaderPaletteVariant.original);
    expect(defaults.positionPercent, 50);
    expect(defaults.windowWidthPercent, 28);

    final vivid = defaults.copyWith(
      variant: DashboardBalanceHeaderPaletteVariant.vivid,
    );
    expect(vivid.palette, defaults.palette);
    expect(vivid.positionPercent, defaults.positionPercent);
    expect(vivid.windowWidthPercent, defaults.windowWidthPercent);
    expect(vivid, isNot(defaults));
    expect(vivid.hashCode, isNot(defaults.hashCode));

    final original = DashboardBalanceHeaderWindowSampler.sample(defaults);
    final saturated = DashboardBalanceHeaderWindowSampler.sample(
      defaults.copyWith(
        variant: DashboardBalanceHeaderPaletteVariant.saturated,
      ),
    );
    final vividWindow = DashboardBalanceHeaderWindowSampler.sample(vivid);
    for (final window in <DashboardBalanceHeaderColorWindow>[
      saturated,
      vividWindow,
    ]) {
      expect(window.leftSamplePercent, original.leftSamplePercent);
      expect(window.rightSamplePercent, original.rightSamplePercent);
      expect(window.state.positionPercent, original.state.positionPercent);
      expect(
        window.state.windowWidthPercent,
        original.state.windowWidthPercent,
      );
    }
    expect(saturated.colorMid, isNot(original.colorMid));
    expect(vividWindow.colorMid, isNot(original.colorMid));
  });
}

Map<DashboardBalanceHeaderPaletteVariant, List<int>> _variants(
  List<int> original,
  List<int> saturated,
  List<int> vivid,
) => <DashboardBalanceHeaderPaletteVariant, List<int>>{
  DashboardBalanceHeaderPaletteVariant.original: original,
  DashboardBalanceHeaderPaletteVariant.saturated: saturated,
  DashboardBalanceHeaderPaletteVariant.vivid: vivid,
};
