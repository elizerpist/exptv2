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

      final restored = BalanceHeaderGlassConfiguration.decode(liquid.encode());
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
