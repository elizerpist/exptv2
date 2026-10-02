import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_sum_micro_day_ribbon_surface.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  testWidgets(
    'MDR-05: the compact ribbon has twelve labels, one vertical owner, grouped year header and no SUM geometry controls',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'sum',
        ),
        contributions: <MindYearHeatmapPreparedContribution>[
          _entry(0, 1_000, const LocalDate(year: 2025, month: 1, day: 1)),
          _entry(1, 80_000, const LocalDate(year: 2025, month: 9, day: 12)),
        ],
      ).preview(_allRange);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 280,
              child: MindSumMicroDayRibbonSurface(
                frame: frame,
                paletteStyle: MindYearHeatmapPaletteStyle.fluvi,
                scaleResolution: MindHeatmapScaleResolution.ten,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('mind-sum-micro-day-ribbon-surface')),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsOneWidget);
      for (var month = 1; month <= 12; month += 1) {
        expect(
          find.byKey(
            ValueKey<String>('mind-sum-micro-day-ribbon-month-2025-$month'),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(
          const ValueKey<String>('mind-sum-micro-day-ribbon-field-2025'),
        ),
        findsOneWidget,
      );
      expect(find.byType(RangeSlider), findsNothing);
      expect(find.text('3×4'), findsNothing);
      expect(find.text('4×3'), findsNothing);
      expect(find.text('2×6'), findsNothing);

      final yearLabel = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-sum-micro-day-ribbon-year-label-2025'),
        ),
      );
      final yearTotal = tester.getRect(
        find.byKey(
          const ValueKey<String>('mind-sum-micro-day-ribbon-year-total-2025'),
        ),
      );
      expect(yearLabel.left, lessThan(yearTotal.left));
      expect(yearLabel.center.dy, closeTo(yearTotal.center.dy, .01));
    },
  );
}

const _allRange = QueryAmountRangeValues(
  minimumScaled100: 100,
  maximumScaled100: 100_000,
  lowerScaled100: 100,
  upperScaled100: 100_000,
);

MindYearHeatmapPreparedContribution _entry(
  int ordinal,
  int amount,
  LocalDate date,
) => MindYearHeatmapPreparedContribution(
  ordinal: ordinal,
  amountMinor: amount,
  bookedLocalEpochDay: date.epochDay,
);
