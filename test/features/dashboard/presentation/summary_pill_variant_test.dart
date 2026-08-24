import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/summary_pill_variant.dart';

void main() {
  test('SummaryPill experiment variants have stable runtime labels', () {
    expect(SummaryPillVariant.legacy.label, 'Klasszikus');
    expect(SummaryPillVariant.segmented.label, 'Szekciós');
    expect(SummaryPillVariant.swipeMode.label, 'Swipe mód');
  });

  test('the experiment controller defaults to the legacy control group', () {
    final controller = SummaryPillVariantController();
    addTearDown(controller.dispose);

    expect(controller.value, SummaryPillVariant.legacy);
  });

  testWidgets(
    'the existing Header menu selects all three SummaryPill variants',
    (tester) async {
      final headerController = DashboardHeaderVisualController(vsync: tester);
      final variants = SummaryPillVariantController();
      addTearDown(variants.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 520,
            child: DashboardHeaderVisualTuner(
              controller: headerController,
              summaryPillVariants: variants,
            ),
          ),
        ),
      );

      for (final variant in SummaryPillVariant.values) {
        expect(
          find.byKey(ValueKey<String>('summary-pill-variant-${variant.name}')),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('summary-pill-variant-swipeMode')),
      );
      await tester.pump();
      expect(variants.value, SummaryPillVariant.swipeMode);
      await tester.pumpWidget(const SizedBox.shrink());
      headerController.dispose();
    },
  );
}
