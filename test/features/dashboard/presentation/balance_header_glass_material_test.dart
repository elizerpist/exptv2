import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_bar.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_configuration.dart';

void main() {
  testWidgets(
    'BGF-01: native 25/75 bar has one physical backdrop sample and one body',
    (tester) async {
      await tester.pumpWidget(
        _GlassHarness(
          configuration: const BalanceHeaderGlassConfiguration(
            renderer: BalanceHeaderGlassRenderer.flutterNative,
            independentIncomeFillSettings: true,
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-physical-body'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-income-material-field'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BGF-02: income field remains inside the one physical native body',
    (tester) async {
      await tester.pumpWidget(
        _GlassHarness(
          configuration: const BalanceHeaderGlassConfiguration(
            renderer: BalanceHeaderGlassRenderer.flutterNative,
            independentIncomeFillSettings: true,
          ),
        ),
      );

      final body = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-physical-body'),
        ),
      );
      final income = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-income-material-field'),
        ),
      );
      expect(income.left, closeTo(body.left, .01));
      expect(income.width, closeTo(body.width * .25, .01));
      expect(find.byType(BackdropFilter), findsOneWidget);
    },
  );

  test(
    'BGF-04: native production defaults no longer use a broad white wash',
    () {
      const configuration = BalanceHeaderGlassConfiguration(
        renderer: BalanceHeaderGlassRenderer.flutterNative,
      );
      final material = configuration.materialFor(incomeFill: false);

      expect(material.gradientStartOpacity, lessThanOrEqualTo(.10));
      expect(material.gradientEndOpacity, lessThanOrEqualTo(.04));
      expect(material.specularOpacity, lessThanOrEqualTo(.12));
    },
  );

  testWidgets(
    'BGF-05: native tint configuration is consumed by the rendered body',
    (tester) async {
      const redTint = 0xffff4455;
      const configuration = BalanceHeaderGlassConfiguration(
        renderer: BalanceHeaderGlassRenderer.flutterNative,
        materials:
            <BalanceHeaderGlassRenderer, BalanceGlassMaterialConfiguration>{
              BalanceHeaderGlassRenderer.baseline:
                  BalanceGlassMaterialConfiguration(blurX: 0, blurY: 0),
              BalanceHeaderGlassRenderer.flutterNative:
                  BalanceGlassMaterialConfiguration(
                    tintArgb: redTint,
                    tintOpacity: .45,
                  ),
              BalanceHeaderGlassRenderer.glassKit:
                  BalanceGlassMaterialConfiguration(),
              BalanceHeaderGlassRenderer.glassmorphism:
                  BalanceGlassMaterialConfiguration(),
              BalanceHeaderGlassRenderer.flutterGlassUiKit:
                  BalanceGlassMaterialConfiguration(),
              BalanceHeaderGlassRenderer.liquidGlassWidgets:
                  BalanceGlassMaterialConfiguration(),
            },
      );
      await tester.pumpWidget(_GlassHarness(configuration: configuration));

      final paint = tester.widget<DecoratedBox>(
        find.byKey(
          const ValueKey<String>('balance-header-glass-native-track-tint'),
        ),
      );
      expect(
        (paint.decoration as BoxDecoration).color,
        const Color(redTint).withValues(alpha: .45),
      );
    },
  );

  testWidgets(
    'BGF-06: each renderer uses one shared geometry and one income field',
    (tester) async {
      for (final renderer in BalanceHeaderGlassRenderer.values) {
        await tester.pumpWidget(
          _GlassHarness(
            configuration: BalanceHeaderGlassConfiguration(
              renderer: renderer,
              independentIncomeFillSettings: true,
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey<String>('balance-header-glass-physical-body'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>(
              'balance-header-glass-income-material-field',
            ),
          ),
          findsOneWidget,
        );
        if (renderer == BalanceHeaderGlassRenderer.flutterNative) {
          expect(find.byType(BackdropFilter), findsOneWidget);
        }
      }
    },
  );

  test('BGF-06: renderer defaults retain distinct material recipes', () {
    const configuration = BalanceHeaderGlassConfiguration();
    final native =
        configuration.materials[BalanceHeaderGlassRenderer.flutterNative]!;
    final kit = configuration.materials[BalanceHeaderGlassRenderer.glassKit]!;
    final morphism =
        configuration.materials[BalanceHeaderGlassRenderer.glassmorphism]!;
    final liquidMaterial =
        configuration.materials[BalanceHeaderGlassRenderer.liquidGlassWidgets]!;

    expect(kit.tintArgb, isNot(native.tintArgb));
    expect(morphism.tintArgb, isNot(kit.tintArgb));
    expect(liquidMaterial.thickness, isNot(native.thickness));
    expect(
      liquidMaterial.gradientStartOpacity,
      lessThan(native.gradientStartOpacity),
    );
  });

  testWidgets(
    'BGF-08: liquid Premium stays one independent 1.8.1 physical surface',
    (tester) async {
      await tester.pumpWidget(
        _GlassHarness(
          configuration: const BalanceHeaderGlassConfiguration(
            renderer: BalanceHeaderGlassRenderer.liquidGlassWidgets,
            quality: BalanceGlassQuality.premium,
            independentIncomeFillSettings: true,
          ),
        ),
      );

      expect(find.byType(liquid.GlassContainer), findsOneWidget);
      final container = tester.widget<liquid.GlassContainer>(
        find.byType(liquid.GlassContainer),
      );
      expect(container.useOwnLayer, isTrue);
      expect(container.quality, liquid.GlassQuality.premium);
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-glass-income-material-field'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BGF-03: native material keeps a filtered high-contrast backdrop visible',
    (tester) async {
      await tester.pumpWidget(
        _GlassHarness(
          configuration: const BalanceHeaderGlassConfiguration(
            renderer: BalanceHeaderGlassRenderer.flutterNative,
            independentIncomeFillSettings: true,
          ),
          goldenBoundary: true,
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-header-glass-material-golden'),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_header_glass_native_material.png',
        ),
      );
    },
  );

  testWidgets(
    'BGF-07: native material remains translucent over the Header-like pastel',
    (tester) async {
      await tester.pumpWidget(
        _GlassHarness(
          configuration: const BalanceHeaderGlassConfiguration(
            renderer: BalanceHeaderGlassRenderer.flutterNative,
            independentIncomeFillSettings: true,
          ),
          goldenBoundary: true,
          goldenKey: 'balance-header-glass-pastel-golden',
          highContrastBackdrop: false,
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-header-glass-pastel-golden'),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_header_glass_native_pastel.png',
        ),
      );
    },
  );
}

final class _GlassHarness extends StatelessWidget {
  const _GlassHarness({
    required this.configuration,
    this.goldenBoundary = false,
    this.goldenKey = 'balance-header-glass-material-golden',
    this.highContrastBackdrop = true,
  });

  final BalanceHeaderGlassConfiguration configuration;
  final bool goldenBoundary;
  final String goldenKey;
  final bool highContrastBackdrop;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: 360,
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          highContrastBackdrop
              ? const _DeterministicHeaderBackdrop()
              : const _PastelHeaderBackdrop(),
          BalanceHeaderGlassBar(
            incomeMinor: 25,
            expenseMinor: 75,
            heightPercent: 72,
            configuration: configuration,
            plotTop: 48,
            plotHeight: 104,
            valueTop: 14,
          ),
        ],
      ),
    );
    return MaterialApp(
      home: Scaffold(
        body: goldenBoundary
            ? RepaintBoundary(key: ValueKey<String>(goldenKey), child: content)
            : content,
      ),
    );
  }
}

final class _PastelHeaderBackdrop extends StatelessWidget {
  const _PastelHeaderBackdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xff6751b9), Color(0xffa8d5df)],
      ),
    ),
  );
}

final class _DeterministicHeaderBackdrop extends StatelessWidget {
  const _DeterministicHeaderBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xff6054c7), Color(0xff9ac8df)],
      ),
    ),
    child: Stack(
      children: <Widget>[
        for (var index = 0; index < 12; index++)
          Positioned(
            left: index * 31.0 - 8,
            top: index.isEven ? 34 : 78,
            width: 22,
            height: 62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: index.isEven
                    ? const Color(0xccffcb6b)
                    : const Color(0xcc293c90),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 103,
          height: 3,
          child: const ColoredBox(color: Color(0xfff9f0f0)),
        ),
      ],
    ),
  );
}
