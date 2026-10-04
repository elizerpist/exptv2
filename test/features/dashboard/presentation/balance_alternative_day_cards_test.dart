import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_day_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart';

void main() {
  final point = DashboardBalanceDailyMomentumPoint(
    epochDay: 20,
    currentIncomeMinor: 140000,
    referenceIncomeMinor: 100000,
    currentExpenseMinor: 120000,
    referenceExpenseMinor: 90000,
    isCurrentHalf: true,
    incomeAxis: .6,
    expenseAxis: .5,
    magnitude: .55,
  );
  final momentum = DashboardBalanceDailyMomentumPresentation(
    available: true,
    selected: point,
    rhythm: <DashboardBalanceDailyMomentumPoint>[
      for (var index = 0; index < 60; index += 1)
        DashboardBalanceDailyMomentumPoint(
          epochDay: index,
          currentIncomeMinor: point.currentIncomeMinor,
          referenceIncomeMinor: point.referenceIncomeMinor,
          currentExpenseMinor: point.currentExpenseMinor,
          referenceExpenseMinor: point.referenceExpenseMinor,
          isCurrentHalf: index >= 30,
          incomeAxis: point.incomeAxis,
          expenseAxis: point.expenseAxis,
          magnitude: index / 60,
        ),
    ],
  );

  testWidgets('Napi 4 cards render the source-truth three visual regions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 720,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: BalanceAlternativeDailyMomentumCoordinateCard(
                    presentation: momentum,
                  ),
                ),
                Expanded(
                  child: BalanceAlternativeDailyMomentumRhythmCard(
                    presentation: momentum,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pénzügyi koordinátarendszer'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('balance-napi4-coordinate-map')),
      findsOneWidget,
    );
    expect(find.text('Összehasonlító ritmuscsík'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('balance-napi4-rhythm-strip')),
      findsOneWidget,
    );
    expect(find.text('Napi költség⌄'), findsOneWidget);
  });

  testWidgets(
    'BAL-RHYTHM-02 RED: comparison rhythm keeps both 30-day halves across the full short lower-card plot',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 120,
              child: BalanceAlternativeDailyMomentumRhythmCard(
                presentation: momentum,
              ),
            ),
          ),
        ),
      );

      expect(
        tester
            .getSize(
              find.byKey(const ValueKey<String>('balance-napi4-rhythm-strip')),
            )
            .width,
        greaterThan(340),
        reason:
            'The 60 daily bars should not be horizontally shrunk merely '
            'because the lower card is short.',
      );
    },
  );

  testWidgets(
    'BAL-RHYTHM-02 visual: the short production rhythm card keeps its 60-bar field edge-to-edge',
    (tester) async {
      const boundaryKey = ValueKey<String>(
        'balance-napi4-rhythm-span-golden-boundary',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 120,
              child: RepaintBoundary(
                key: boundaryKey,
                child: BalanceAlternativeDailyMomentumRhythmCard(
                  presentation: momentum,
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_day_rhythm_span.png',
        ),
      );
    },
  );

  testWidgets(
    'a worsening daily impact retains the real value and uses a coral pill',
    (tester) async {
      const impact = DashboardBalanceDailyImpactPresentation(
        available: true,
        previousSevenExpenseMinor: 700000,
        currentSevenExpenseMinor: 800000,
        valuePercent: -14.2857,
        scaleExtentPercent: 10,
        markerFraction: 0,
        overflow: true,
        todayNetMinor: -120000,
        referenceAverageNetMinor: -90000,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 700,
              child: BalanceAlternativeDailyImpactCard(presentation: impact),
            ),
          ),
        ),
      );

      expect(find.text('-14%'), findsOneWidget);
      final pill = tester.widget<Container>(
        find.byKey(
          const ValueKey<String>('balance-napi4-impact-pill-worsening'),
        ),
      );
      final decoration = pill.decoration! as BoxDecoration;
      expect(
        (decoration.gradient! as LinearGradient).colors[1],
        BalanceAlternativeHtmlTokens.dailyMomentumCoral.withValues(alpha: .23),
      );
      expect(find.text('Rontja a 7 napos átlagot'), findsOneWidget);
      expect(find.text('Figyelem'), findsOneWidget);
      expect(find.text('+10%'), findsOneWidget);
      expect(find.text('-10%'), findsOneWidget);
    },
  );

  testWidgets(
    'Napi 4 child-card composition matches its visual source contract',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const impact = DashboardBalanceDailyImpactPresentation(
        available: true,
        previousSevenExpenseMinor: 700000,
        currentSevenExpenseMinor: 630000,
        valuePercent: 10,
        scaleExtentPercent: 20,
        markerFraction: .75,
        overflow: false,
        todayNetMinor: 1200000,
        referenceAverageNetMinor: 1080000,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('balance-napi4-visual-boundary'),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final topHeight = constraints.maxHeight * .60;
                  final leftWidth = constraints.maxWidth * .70;
                  return Stack(
                    children: <Widget>[
                      Positioned.fromRect(
                        rect: Rect.fromLTWH(0, 0, leftWidth, topHeight),
                        child: BalanceAlternativeDailyMomentumCoordinateCard(
                          presentation: momentum,
                        ),
                      ),
                      Positioned.fromRect(
                        rect: Rect.fromLTWH(
                          leftWidth,
                          0,
                          constraints.maxWidth - leftWidth,
                          topHeight,
                        ),
                        child: const BalanceAlternativeDailyImpactCard(
                          presentation: impact,
                        ),
                      ),
                      Positioned.fromRect(
                        rect: Rect.fromLTWH(
                          0,
                          topHeight,
                          constraints.maxWidth,
                          constraints.maxHeight - topHeight,
                        ),
                        child: BalanceAlternativeDailyMomentumRhythmCard(
                          presentation: momentum,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(const ValueKey<String>('balance-napi4-visual-boundary')),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_napi4_cards.png',
        ),
      );
    },
  );
}
