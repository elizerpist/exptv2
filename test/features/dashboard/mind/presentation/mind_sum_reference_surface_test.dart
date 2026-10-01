import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_sum_reference_surface.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  testWidgets(
    'SUM-REFERENCE-01 RED: SUM-A and SUM-B are native surfaces with one shared data frame and no decorative range rail',
    (tester) async {
      final frame =
          MindSumHeatmapProjection.build(
            identity: const MindTemporalHeatmapIdentity(
              upstreamScopeKey: 'expense',
              indexGeneration: 1,
              coreRevision: 1,
              timeScopeKey: 'sum',
            ),
            contributions: <MindYearHeatmapPreparedContribution>[
              _entry(0, 50000, const LocalDate(year: 2025, month: 1, day: 2)),
              _entry(1, 80000, const LocalDate(year: 2025, month: 7, day: 2)),
              _entry(2, 30000, const LocalDate(year: 2026, month: 2, day: 2)),
            ],
          ).preview(
            const QueryAmountRangeValues(
              minimumScaled100: 100,
              maximumScaled100: 100000,
              lowerScaled100: 100,
              upperScaled100: 100000,
            ),
          );

      Future<void> pump(MindSumVisualStyle style) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 480,
              child: MindSumReferenceSurface(
                frame: frame,
                visualStyle: style,
                showLayoutChooser: true,
              ),
            ),
          ),
        ),
      );

      await pump(MindSumVisualStyle.sumA);
      expect(
        find.byKey(const ValueKey('mind-sum-reference-sumA')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-a-year-2025')),
        findsOneWidget,
      );
      expect(find.byType(RangeSlider), findsNothing);

      await pump(MindSumVisualStyle.sumB);
      expect(
        find.byKey(const ValueKey('mind-sum-reference-sumB')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-b-year-card-2025')),
        findsOneWidget,
      );
      expect(find.byType(RangeSlider), findsNothing);
    },
  );

  testWidgets(
    'SUM-REFERENCE-02 RED: the visible SUM-A layout chooser changes the live month-grid layout',
    (tester) async {
      final frame =
          MindSumHeatmapProjection.build(
            identity: const MindTemporalHeatmapIdentity(
              upstreamScopeKey: 'expense',
              indexGeneration: 1,
              coreRevision: 1,
              timeScopeKey: 'sum',
            ),
            contributions: <MindYearHeatmapPreparedContribution>[
              _entry(0, 50000, const LocalDate(year: 2025, month: 1, day: 2)),
            ],
          ).preview(
            const QueryAmountRangeValues(
              minimumScaled100: 100,
              maximumScaled100: 100000,
              lowerScaled100: 100,
              upperScaled100: 100000,
            ),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 480,
              child: MindSumReferenceSurface(
                frame: frame,
                visualStyle: MindSumVisualStyle.sumA,
                showLayoutChooser: true,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-sum-month-grid-2025-4')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('mind-sum-layout-two-by-six')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-sum-month-grid-2025-6')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SUM-REFERENCE-03 RED: SUM-B year identity color follows the same live range frame as the month cells',
    (tester) async {
      final projection = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'sum',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 80000, const LocalDate(year: 2025, month: 1, day: 2)),
          _entry(1, 30000, const LocalDate(year: 2026, month: 2, day: 2)),
        ],
      );
      final full = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 1,
          maximumScaled100: 100000,
          lowerScaled100: 1,
          upperScaled100: 100000,
        ),
      );
      final narrowed = projection.preview(
        const QueryAmountRangeValues(
          minimumScaled100: 1,
          maximumScaled100: 100000,
          lowerScaled100: 80000,
          upperScaled100: 80000,
        ),
      );

      Future<void> pump(MindSumHeatmapFrame frame) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 480,
              child: MindSumReferenceSurface(
                frame: frame,
                visualStyle: MindSumVisualStyle.sumB,
                showLayoutChooser: false,
              ),
            ),
          ),
        ),
      );

      await pump(full);
      final before = tester.widget<Container>(
        find.byKey(const ValueKey('mind-sum-b-year-card-2026')),
      );
      final beforeColors =
          (before.decoration! as BoxDecoration).gradient!.colors;
      await pump(narrowed);
      final after = tester.widget<Container>(
        find.byKey(const ValueKey('mind-sum-b-year-card-2026')),
      );
      final afterColors = (after.decoration! as BoxDecoration).gradient!.colors;

      expect(afterColors, isNot(beforeColors));
    },
  );
}

MindYearHeatmapPreparedContribution _entry(
  int ordinal,
  int amount,
  LocalDate date,
) => MindYearHeatmapPreparedContribution(
  ordinal: ordinal,
  bookedLocalEpochDay: date.epochDay,
  amountMinor: amount,
  partnerLabel: 'Teszt',
);
