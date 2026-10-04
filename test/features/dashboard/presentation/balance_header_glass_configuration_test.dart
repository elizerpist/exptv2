import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_bar.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_header_glass_configuration.dart';

void main() {
  test(
    'BGV-01: every renderer keeps its own serializable material settings',
    () {
      const initial = BalanceHeaderGlassConfiguration();
      final glassKit = initial
          .copyWith(renderer: BalanceHeaderGlassRenderer.glassKit)
          .updateMaterial(
            incomeFill: false,
            material: initial.materials[BalanceHeaderGlassRenderer.glassKit]!
                .copyWith(blurX: 18),
          );
      final liquid = glassKit
          .copyWith(renderer: BalanceHeaderGlassRenderer.liquidGlassWidgets)
          .updateMaterial(
            incomeFill: false,
            material: glassKit
                .materials[BalanceHeaderGlassRenderer.liquidGlassWidgets]!
                .copyWith(thickness: 35),
          );
      final incomeField = liquid
          .copyWith(independentIncomeFillSettings: true)
          .updateMaterial(
            incomeFill: true,
            material: liquid
                .materialFor(incomeFill: true)
                .copyWith(tintArgb: 0xff84c7ff, tintOpacity: .21),
          );

      final restored = BalanceHeaderGlassConfiguration.decode(
        incomeField.encode(),
      );
      expect(
        restored.materials[BalanceHeaderGlassRenderer.glassKit]!.blurX,
        18,
      );
      expect(
        restored
            .materials[BalanceHeaderGlassRenderer.liquidGlassWidgets]!
            .thickness,
        35,
      );
      expect(restored.materialFor(incomeFill: true).tintArgb, 0xff84c7ff);
      expect(restored.materialFor(incomeFill: true).tintOpacity, .21);
    },
  );

  test('BGV-02: common bar ratio and vertical range remain finite', () {
    expect(
      BalanceHeaderGlassBar.incomeRatioFor(incomeMinor: 25, expenseMinor: 75),
      .25,
    );
    expect(
      BalanceHeaderGlassBar.incomeRatioFor(incomeMinor: 0, expenseMinor: 0),
      .5,
    );
    final bottom = BalanceHeaderGlassBar.topFor(
      plotTop: 48,
      plotHeight: 80,
      valueTop: 16,
      height: 20,
      verticalPosition: 0,
    );
    final top = BalanceHeaderGlassBar.topFor(
      plotTop: 48,
      plotHeight: 80,
      valueTop: 16,
      height: 20,
      verticalPosition: 1,
    );
    expect(top, lessThan(bottom));
    expect(top, greaterThanOrEqualTo(41));
  });

  test(
    'BGV-01: reset restores only the selected renderer track and field defaults',
    () {
      const defaults = BalanceHeaderGlassConfiguration();
      final otherRenderer = defaults
          .copyWith(renderer: BalanceHeaderGlassRenderer.glassKit)
          .updateMaterial(
            incomeFill: false,
            material: defaults.materials[BalanceHeaderGlassRenderer.glassKit]!
                .copyWith(blurX: 17),
          );
      final selected = otherRenderer
          .copyWith(
            renderer: BalanceHeaderGlassRenderer.flutterNative,
            independentIncomeFillSettings: true,
          )
          .updateMaterial(
            incomeFill: false,
            material: otherRenderer
                .materials[BalanceHeaderGlassRenderer.flutterNative]!
                .copyWith(blurX: 22),
          )
          .updateMaterial(
            incomeFill: true,
            material: otherRenderer
                .fillMaterials[BalanceHeaderGlassRenderer.flutterNative]!
                .copyWith(tintOpacity: .31),
          );

      final reset = selected.resetSelectedRenderer();

      expect(
        reset.materials[BalanceHeaderGlassRenderer.flutterNative],
        defaults.materials[BalanceHeaderGlassRenderer.flutterNative],
      );
      expect(
        reset.fillMaterials[BalanceHeaderGlassRenderer.flutterNative],
        defaults.fillMaterials[BalanceHeaderGlassRenderer.flutterNative],
      );
      expect(reset.materials[BalanceHeaderGlassRenderer.glassKit]!.blurX, 17);
    },
  );

  testWidgets(
    'BGV-03: every selected renderer mounts exactly one shared live geometry',
    (tester) async {
      for (final renderer in BalanceHeaderGlassRenderer.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 180,
                child: Stack(
                  children: <Widget>[
                    BalanceHeaderGlassBar(
                      incomeMinor: 25,
                      expenseMinor: 75,
                      heightPercent: 50,
                      configuration: BalanceHeaderGlassConfiguration(
                        renderer: renderer,
                      ),
                      plotTop: 48,
                      plotHeight: 80,
                      valueTop: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.byKey(ValueKey<String>('balance-header-glass-${renderer.name}')),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(
                find.byKey(
                  const ValueKey<String>(
                    'balance-header-income-expense-partition',
                  ),
                ),
              )
              .width,
          closeTo(328, .1),
        );
      }
    },
  );
}
