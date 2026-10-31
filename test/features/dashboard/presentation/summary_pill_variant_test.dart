import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_body_order.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shell_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_presentation.dart';

void main() {
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
      <DashboardBodyComponent>[
        DashboardBodyComponent.modeContent,
        DashboardBodyComponent.direction,
        DashboardBodyComponent.summary,
      ],
    );
  });

  test(
    'MOVERS-DEFAULTS-RED: dashboard defaults seed sectioned Summary without separators and flat straight navigation',
    () {
      final shell = DashboardShellPresentationController();
      final summary = DashboardSummaryPresentationController();
      addTearDown(shell.dispose);
      addTearDown(summary.dispose);

      expect(summary.value.showSeparators, isFalse);
      expect(
        shell.value.bottomNavEdgeShape,
        DashboardBottomNavEdgeShape.straight,
      );
      expect(
        shell.value.bottomNavLayoutStyle,
        DashboardBottomNavLayoutStyle.containedFlat,
      );

      summary.setSeparatorsVisible(true);
      shell
        ..selectBottomNavEdgeShape(DashboardBottomNavEdgeShape.rounded)
        ..selectBottomNavLayoutStyle(DashboardBottomNavLayoutStyle.raisedFab);
      expect(summary.value.showSeparators, isTrue);
      expect(
        shell.value.bottomNavEdgeShape,
        DashboardBottomNavEdgeShape.rounded,
      );
      expect(
        shell.value.bottomNavLayoutStyle,
        DashboardBottomNavLayoutStyle.raisedFab,
      );
    },
  );

  testWidgets(
    'the Header menu no longer exposes a Summary implementation choice',
    (tester) async {
      final headerController = DashboardHeaderVisualController(vsync: tester);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 520,
            child: DashboardHeaderVisualTuner(controller: headerController),
          ),
        ),
      );
      expect(find.text('Időnavigáció / SummaryPill'), findsNothing);
      expect(find.text('Klasszikus'), findsNothing);
      expect(find.text('Szekciós'), findsNothing);
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
      await tester.tap(find.text('Fejléc sorrend').first);
      await tester.pump();

      for (final component in DashboardBodyComponent.values) {
        expect(
          find.byKey(
            ValueKey<String>('dashboard-body-order-${component.name}'),
          ),
          findsOneWidget,
        );
      }
      await tester.tap(
        find.byKey(const ValueKey<String>('dashboard-body-order-down-0')),
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
