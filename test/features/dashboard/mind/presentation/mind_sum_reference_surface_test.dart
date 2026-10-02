import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_heatmap_palette_scope.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart';
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
    'SUMFIX-01 RED: SUM-A has one fixed four-column, twelve-month layout without a chooser',
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

      final grid = find.byKey(const ValueKey('mind-sum-month-grid-2025-4'));
      expect(grid, findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-sum-detail-mode-toggle')),
        findsNothing,
        reason: 'SUM is fixed to the source-of-truth 4 columns × 3 rows.',
      );
      expect(
        tester.getSize(grid).height,
        greaterThanOrEqualTo(120),
        reason: 'All three rows must have real vertical room; no clipped band.',
      );
    },
  );

  testWidgets(
    'SUMROW-01/02 RED: every third-row month stays inside its SUM-A and SUM-B year band',
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
              for (var month = 1; month <= 12; month += 1)
                _entry(
                  month,
                  10_000 + month,
                  LocalDate(year: 2025, month: month, day: 2),
                ),
            ],
          ).preview(
            const QueryAmountRangeValues(
              minimumScaled100: 1,
              maximumScaled100: 100_000,
              lowerScaled100: 1,
              upperScaled100: 100_000,
            ),
          );

      for (final style in <MindSumVisualStyle>[
        MindSumVisualStyle.sumA,
        MindSumVisualStyle.sumB,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 520,
                child: MindSumReferenceSurface(
                  frame: frame,
                  visualStyle: style,
                ),
              ),
            ),
          ),
        );

        final december = find.byKey(
          const ValueKey<String>('mind-sum-heatmap-cell-2025-12'),
        );
        final yearBand = find.byKey(
          ValueKey<String>(
            style == MindSumVisualStyle.sumA
                ? 'mind-sum-a-year-2025'
                : 'mind-sum-b-mother-card-2025',
          ),
        );
        expect(december, findsOneWidget);
        expect(
          tester.getRect(december).bottom,
          lessThanOrEqualTo(tester.getRect(yearBand).bottom - 8),
          reason:
              '${style.name} must leave a real lower inset after December, '
              'rather than clipping the third row at the year-band edge.',
        );
      }
    },
  );

  testWidgets(
    'SUMWINDOW-01/02 RED: phone safe-area padding cannot offset either 4×3 month grid below its year window',
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
              for (var month = 1; month <= 12; month += 1)
                _entry(
                  month,
                  10_000 + month,
                  LocalDate(year: 2025, month: month, day: 2),
                ),
            ],
          ).preview(
            const QueryAmountRangeValues(
              minimumScaled100: 1,
              maximumScaled100: 100_000,
              lowerScaled100: 1,
              upperScaled100: 100_000,
            ),
          );

      for (final style in <MindSumVisualStyle>[
        MindSumVisualStyle.sumA,
        MindSumVisualStyle.sumB,
      ]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
              child: SizedBox(
                width: 390,
                height: 300,
                child: MindSumReferenceSurface(
                  frame: frame,
                  visualStyle: style,
                ),
              ),
            ),
          ),
        );

        final grid = find.byKey(
          const ValueKey<String>('mind-sum-month-grid-2025-4'),
        );
        final december = find.byKey(
          const ValueKey<String>('mind-sum-heatmap-cell-2025-12'),
        );
        expect(december, findsOneWidget);
        expect(
          tester.getRect(december).bottom,
          lessThanOrEqualTo(tester.getRect(grid).bottom),
          reason:
              '${style.name} must use the allocated grid window itself, not '
              'a phone-level safe-area inset that hides December.',
        );
      }
    },
  );

  testWidgets(
    'SUMFIX-03 RED: SUM-A and SUM-B month cells consume the live shared heatmap palette',
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
              _entry(0, 80000, const LocalDate(year: 2025, month: 1, day: 2)),
            ],
          ).preview(
            const QueryAmountRangeValues(
              minimumScaled100: 1,
              maximumScaled100: 100000,
              lowerScaled100: 1,
              upperScaled100: 100000,
            ),
          );

      const dynamicHigh = Color(0xff145c48);
      final dynamicScale = MindHeatmapResolvedScale(<Color>[
        const Color(0xffe6f8ef),
        dynamicHigh,
      ]);
      final expected = MindYearHeatmapPaletteResolver.resolveTile(
        style: MindYearHeatmapPaletteStyle.fluvi,
        isEmpty: false,
        intensity: frame.month(year: 2025, month: 1).intensity,
        paletteIntensity: frame.month(year: 2025, month: 1).paletteIntensity,
        dynamicScale: dynamicScale,
      );
      for (final style in <MindSumVisualStyle>[
        MindSumVisualStyle.sumA,
        MindSumVisualStyle.sumB,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MindHeatmapPaletteScope(
              scale: dynamicScale,
              child: Scaffold(
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
          ),
        );
        final monthCell = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('mind-sum-heatmap-cell-2025-1')),
        );
        final decoration = monthCell.decoration as BoxDecoration;
        expect(decoration.color, expected.background);
      }
    },
  );

  testWidgets(
    'SUMFIX-02: SUM reference is body content, not a nested rounded card above the footer',
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
              minimumScaled100: 1,
              maximumScaled100: 100000,
              lowerScaled100: 1,
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
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget(find.byKey(const ValueKey('mind-sum-reference-sumA'))),
        isA<KeyedSubtree>(),
      );
    },
  );

  testWidgets(
    'SUM-REFERENCE-03 RED: SUM-B year card and mother tone follow the same live range frame as the month cells',
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
      final beforeMother = tester.widget<Container>(
        find.byKey(const ValueKey('mind-sum-b-mother-card-2026')),
      );
      final beforeMotherColors =
          (beforeMother.decoration! as BoxDecoration).gradient!.colors;
      await pump(narrowed);
      final after = tester.widget<Container>(
        find.byKey(const ValueKey('mind-sum-b-year-card-2026')),
      );
      final afterColors = (after.decoration! as BoxDecoration).gradient!.colors;
      final afterMother = tester.widget<Container>(
        find.byKey(const ValueKey('mind-sum-b-mother-card-2026')),
      );
      final afterMotherColors =
          (afterMother.decoration! as BoxDecoration).gradient!.colors;

      expect(afterColors, isNot(beforeColors));
      expect(afterMotherColors, isNot(beforeMotherColors));
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
