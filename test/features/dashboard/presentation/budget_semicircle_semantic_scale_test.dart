import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';

void main() {
  BudgetSemicircleScalePresentation scale(
    double value, {
    bool signed = false,
  }) => BudgetSemicircleScalePresentation(
    domainMinimum: signed ? -100 : 0,
    domainNeutral: signed ? 0 : 100,
    domainMaximum: signed ? 100 : 200,
    rawValue: value,
  );
  BudgetSemicircleMaterialPresentation material(double value) =>
      BudgetSemicircleMaterialPresentation.forScale(
        scale: scale(value, signed: true),
        activeColor: Colors.purple,
        semanticColor: Colors.green,
      );

  test('semantic scale maps both neutral points to physical arc midpoint', () {
    expect(scale(100).neutralProgress, .5);
    expect(scale(0, signed: true).neutralProgress, .5);
    expect(scale(110.7).visualProgress, closeTo(.5535, .000001));
    expect(scale(-7.1, signed: true).visualProgress, closeTo(.4645, .000001));
    expect(scale(-7.1, signed: true).rawValue, -7.1);
    expect(scale(0, signed: true).leftEndpointLabel, '−100%');
    expect(scale(0, signed: true).rightEndpointLabel, '+100%');
    expect(scale(100).neutralLabel, '100%');
  });

  test(
    'overflow preserves raw signed values and clamps physical coordinates only',
    () {
      final low = scale(-150, signed: true);
      final high = scale(250);
      expect(low.rawValue, -150);
      expect(low.visualProgress, 0);
      expect(low.hasVisualOverflow, isTrue);
      expect(low.isUnderflow, isTrue);
      expect(high.rawValue, 250);
      expect(high.visualProgress, 1);
      expect(high.hasVisualOverflow, isTrue);
      expect(high.isUnderflow, isFalse);
    },
  );

  test(
    'semantic material uses canonical clay and explicit sphere semantics',
    () {
      final value = material(-7.1);
      final clay = BudgetClayActiveMaterial.forSemanticBase(Colors.purple);
      expect(value.progressGradient, clay.colors);
      expect(value.progressDepthGradient, clay.depthColors);
      expect(value.semanticScale!.rawValue, -7.1);
      expect(value.overshootZones, isEmpty);
      expect(
        value.solidTargetAccentMaterial.sameVisualAs(value.segmentedMaterial),
        isTrue,
      );
    },
  );

  test('default Budget retains legacy 120 percent coordinates and health', () {
    final value = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: 1.15,
      direction: LedgerDirection.expense,
      activeGradient: const [Colors.purple, Colors.blue, Colors.cyan],
    );
    expect(value.semanticScale, isNull);
    expect(value.visualProgress, closeTo(1.15 / 1.2, .000001));
    expect(value.targetProgress, closeTo(1 / 1.2, .000001));
    expect(value.health, BudgetClayGaugeHealth.expenseDanger);
    expect(value.overshootZones, hasLength(2));
  });

  testWidgets(
    'semantic gauges retarget existing shared material from visible progress',
    (tester) async {
      Widget scene(double value, {bool showMarker = true}) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 220,
            height: 150,
            child: BudgetSemicircleGauge(
              key: const ValueKey('stable'),
              presentation: material(value),
              primaryLabel: '$value%',
              secondaryLabel: 'Nettóarány',
              primaryColor: Colors.green,
              showMarker: showMarker,
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene(-50));
      final initialState = tester.state(find.byType(BudgetSemicircleGauge));
      BudgetSemicircleMaterial rendered() =>
          tester.widget(find.byType(BudgetSemicircleMaterial));
      expect(rendered().progress, .25);
      await tester.pumpWidget(scene(50));
      await tester.pump(const Duration(milliseconds: 100));
      final visible = rendered().progress;
      expect(visible, greaterThan(.25));
      expect(visible, lessThan(.75));
      await tester.pumpWidget(scene(-90));
      expect(rendered().progress, closeTo(visible, .000001));
      expect(
        tester.state(find.byType(BudgetSemicircleGauge)),
        same(initialState),
      );
      await tester.pumpAndSettle();
      expect(rendered().progress, closeTo(.05, .000001));
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('−100%'), findsOneWidget);
      await tester.pumpWidget(scene(-150, showMarker: false));
      await tester.pumpAndSettle();
      expect(rendered().showMarker, isFalse);
      expect(
        find.byKey(const ValueKey('budget-semicircle-scale-overflow')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'optional compact primary type and arbitrary neutral use the same arc',
    (tester) async {
      const semantic = BudgetSemicircleScalePresentation(
        domainMinimum: 0,
        domainNeutral: 50,
        domainMaximum: 200,
        rawValue: 80,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 220,
              height: 150,
              child: BudgetSemicircleGauge(
                presentation: BudgetSemicircleMaterialPresentation.forScale(
                  scale: semantic,
                  activeColor: Colors.purple,
                  semanticColor: Colors.green,
                ),
                primaryLabel: 'Kiadás nélkül',
                secondaryLabel: 'Fedezettség',
                primaryFontSize: 16,
                showMarker: false,
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Kiadás nélkül')).style!.fontSize,
        16,
      );
      final geometry = BudgetSemicircleMaterialGeometry.resolve(
        const Size(220, 150),
        layout: BudgetSemicircleMaterialLayout.sumHero,
      );
      final scene = tester.getTopLeft(find.byType(BudgetSemicircleGauge));
      final tickCenter =
          tester.getCenter(
            find.byKey(const ValueKey('budget-semicircle-neutral-tick')),
          ) -
          scene;
      final expected = geometry.pointAtProgress(.25);
      expect(tickCenter.dx, closeTo(expected.dx, .000001));
      expect(tickCenter.dy, closeTo(expected.dy, .000001));
      expect(tickCenter.dx, lessThan(geometry.trackRect.center.dx));
      expect(find.text('50%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
