import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tuner placement always reserves the live Header plus its gap', () {
    const gap = 12.0;
    for (final headerBottom in <double>[124, 214, 346]) {
      final placement = DashboardHeaderVisualTunerPlacement.resolve(
        headerBottom: headerBottom,
        viewportHeight: 760,
        safeBottom: 24,
        gap: gap,
      );
      expect(placement.top, greaterThanOrEqualTo(headerBottom + gap));
      expect(placement.maxHeight, greaterThanOrEqualTo(0));
    }
  });

  testWidgets('controls apply Header visual settings synchronously', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-window-width-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-header-opacity-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
      findsOneWidget,
    );

    final widthSlider = tester.widget<Slider>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('dashboard-header-window-width-slider'),
        ),
        matching: find.byType(Slider),
      ),
    );
    widthSlider.onChanged!(42);
    await tester.pump();
    expect(controller.tuning.value.budgetWindowWidthPercent, 42);

    final pulseTrigger = find.byKey(
      const ValueKey<String>('dashboard-header-pulse-trigger'),
    );
    await tester.scrollUntilVisible(
      pulseTrigger,
      220,
      scrollable: find.descendant(
        of: find.byKey(
          const ValueKey<String>('dashboard-header-visual-tuner-list'),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(pulseTrigger);
    await tester.pump();
    expect(controller.pulseAmount, 1);
    controller.dispose();
  });
}
