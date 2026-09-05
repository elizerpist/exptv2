import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_body_order.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/summary_pill_variant.dart';

void main() {
  test(
    'SummaryPill active experiment catalog is Legacy and Segmented only',
    () {
      expect(SummaryPillVariant.values, <SummaryPillVariant>[
        SummaryPillVariant.legacy,
        SummaryPillVariant.segmented,
      ]);
      expect(SummaryPillVariant.legacy.label, 'Klasszikus');
      expect(SummaryPillVariant.segmented.label, 'Szekciós');
    },
  );

  test('the experiment controller defaults to the legacy control group', () {
    final controller = SummaryPillVariantController();
    addTearDown(controller.dispose);

    expect(controller.value, SummaryPillVariant.legacy);
  });

  test(
    'variant selection has a monotonic epoch without duplicate transitions',
    () {
      final controller = SummaryPillVariantController();
      addTearDown(controller.dispose);

      expect(controller.transitionEpoch, 0);
      controller.select(SummaryPillVariant.segmented);
      expect(controller.transitionEpoch, 1);
      controller.select(SummaryPillVariant.segmented);
      expect(controller.transitionEpoch, 1);
      controller.select(SummaryPillVariant.legacy);
      expect(controller.transitionEpoch, 2);
    },
  );

  test('body-order state rejects missing or duplicate body blocks', () {
    expect(
      () => DashboardBodyOrder(const <DashboardBodyComponent>[
        DashboardBodyComponent.direction,
        DashboardBodyComponent.summary,
        DashboardBodyComponent.summary,
      ]),
      throwsArgumentError,
    );
    expect(
      DashboardBodyOrder.defaultOrder().components,
      DashboardBodyComponent.values,
    );
  });

  testWidgets(
    'the existing Header menu selects only the active SummaryPill variants',
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
      expect(
        find.byKey(const ValueKey<String>('summary-pill-variant-swipeMode')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('summary-pill-variant-segmented')),
      );
      await tester.pump();
      expect(variants.value, SummaryPillVariant.segmented);
      await tester.pumpWidget(const SizedBox.shrink());
      headerController.dispose();
    },
  );

  testWidgets(
    'the existing Header menu moves one valid three-block body order live',
    (tester) async {
      final headerController = DashboardHeaderVisualController(vsync: tester);
      final order = DashboardBodyOrderController();
      addTearDown(order.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 520,
            child: DashboardHeaderVisualTuner(
              controller: headerController,
              bodyOrder: order,
            ),
          ),
        ),
      );

      for (final component in DashboardBodyComponent.values) {
        expect(
          find.byKey(
            ValueKey<String>('dashboard-body-order-${component.name}'),
          ),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('dashboard-body-order-up-2')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('dashboard-body-order-up-1')),
      );
      await tester.pump();

      expect(order.value.components, <DashboardBodyComponent>[
        DashboardBodyComponent.modeContent,
        DashboardBodyComponent.direction,
        DashboardBodyComponent.summary,
      ]);
      expect(
        order.value.components.toSet(),
        DashboardBodyComponent.values.toSet(),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      headerController.dispose();
    },
  );
}
