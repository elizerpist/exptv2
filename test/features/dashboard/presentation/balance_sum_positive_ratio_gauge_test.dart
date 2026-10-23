import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_sum_positive_ratio_gauge.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';

void main() {
  testWidgets(
    'SUM ratio uses pixel-identical Budget income gauge at zero partial and full',
    (tester) async {
      const capture = ValueKey('capture');
      Future<void> pump(int positive, bool adapter) => tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(
                width: 340,
                height: 210,
                child: ColoredBox(
                  color: Colors.white,
                  child: Builder(
                    builder: (context) => adapter
                        ? BalanceSumPositiveRatioGauge(
                            positiveCount: positive,
                            sampleCount: 12,
                          )
                        : BudgetSemicircleGauge(
                            presentation:
                                BudgetSemicircleMaterialPresentation.resolve(
                                  rawRatio: positive / 12,
                                  direction: LedgerDirection.income,
                                  activeGradient:
                                      BudgetClayGaugeAccentResolver.resolve(
                                        context,
                                        direction: LedgerDirection.income,
                                      ),
                                ),
                            primaryLabel: '${(positive / 12 * 100).round()}%',
                            secondaryLabel:
                                'pozitív hónap • $positive / 12 hónap',
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Future<List<int>> pixels() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        return (await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final bytes = data!.buffer.asUint8List().toList();
          image.dispose();
          return bytes;
        }))!;
      }

      for (final positive in [0, 7, 12]) {
        await pump(positive, true);
        await tester.pumpAndSettle();
        final gauge = tester.widget<BudgetSemicircleGauge>(
          find.byType(BudgetSemicircleGauge),
        );
        expect(gauge.presentation.rawRatio, positive / 12);
        expect(
          find.text('pozitív hónap • $positive / 12 hónap'),
          findsOneWidget,
        );
        final actual = await pixels();
        if (positive == 7) {
          await expectLater(
            find.byKey(capture),
            matchesGoldenFile(
              '../../../goldens/balance_sum_positive_ratio_gauge.png',
            ),
          );
        }
        await pump(positive, false);
        await tester.pumpAndSettle();
        expect(
          await pixels(),
          orderedEquals(actual),
          reason: 'positive=$positive',
        );
      }
    },
  );
  testWidgets(
    'empty sample renders neutral unavailable state instead of zero gauge',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BalanceSumPositiveRatioGauge(positiveCount: 0, sampleCount: 0),
        ),
      );
      expect(find.byType(BudgetSemicircleGauge), findsNothing);
      expect(find.text('0%'), findsNothing);
      expect(find.text('Még nincs értékelhető hónap'), findsOneWidget);
    },
  );
  testWidgets(
    'compact constraints preserve canonical component without overflow',
    (tester) async {
      for (final size in [const Size(160, 85), const Size(220, 65)]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.fromSize(
                size: size,
                child: const BalanceSumPositiveRatioGauge(
                  positiveCount: 7,
                  sampleCount: 12,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BudgetSemicircleGauge), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
