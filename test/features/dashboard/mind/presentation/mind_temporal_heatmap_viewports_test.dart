import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_frame.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  const range = QueryAmountRangeValues(
    minimumScaled100: 100,
    maximumScaled100: 1000,
    lowerScaled100: 100,
    upperScaled100: 1000,
  );

  final contributions = <MindYearHeatmapPreparedContribution>[
    _entry(0, 100, const LocalDate(year: 2024, month: 1, day: 2)),
    _entry(1, 500, const LocalDate(year: 2025, month: 5, day: 3)),
    _entry(2, 1000, const LocalDate(year: 2025, month: 5, day: 4)),
  ];

  testWidgets(
    'SUM-HM-03/04/05: Sum presents real years, month axis and twelve cells per year',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      expect(find.text('Többéves hőtérkép'), findsOneWidget);
      expect(find.text('2 év · 24 hónap'), findsOneWidget);
      expect(find.text('J'), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-year-2024')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-year-2025')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-cell-2025-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-sum-heatmap-total-2025')),
        findsOneWidget,
      );
      expect(find.byType(ListView), findsOneWidget);
    },
  );

  testWidgets(
    'RED SUM-PAINT-01: a non-empty Sum month has a visible bounded rectangle',
    (tester) async {
      final frame = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 260,
              child: MindSumHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final viewport = find.byKey(
        const ValueKey<String>('mind-sum-heatmap-scroll'),
      );
      final cell = find.byKey(
        const ValueKey<String>('mind-sum-heatmap-cell-2025-5'),
      );
      final cellRect = tester.getRect(cell);
      final viewportRect = tester.getRect(viewport);
      final decoration =
          tester.widget<DecoratedBox>(cell).decoration as BoxDecoration;

      expect(cellRect.width, greaterThan(0));
      expect(cellRect.height, greaterThan(0));
      expect(viewportRect.overlaps(cellRect), isTrue);
      expect(
        decoration.color,
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.fluvi,
          isEmpty: false,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        ).background,
      );
    },
  );

  testWidgets(
    'MONTH-HM-01/05/06: Month uses a fixed six-row envelope with real numbered days and no nested scroll',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 300,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      expect(find.text('Napi aktivitás'), findsOneWidget);
      expect(find.text('31 nap'), findsOneWidget);
      expect(find.text('május 2025'), findsOneWidget);
      expect(find.text('2 aktív nap'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-month-heatmap-grid')),
        findsOneWidget,
      );
      expect(find.byType(Scrollable), findsNothing);
    },
  );

  testWidgets(
    'RED MONTH-B3M-01: wide Month content centers its grid at the 282px reference width',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 420,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final grid = find.byKey(
        const ValueKey<String>('mind-month-heatmap-grid'),
      );
      final rect = tester.getRect(grid);
      expect(rect.width, closeTo(282, .01));
      expect(rect.left, closeTo((360 - 282) / 2, .01));
      final day = find.text('3');
      expect(day, findsOneWidget);
      final dayText = tester.widget<Text>(day);
      expect(dayText.style?.fontSize, 7);
      expect(dayText.style?.fontWeight, FontWeight.w900);
      expect(mindMonthHeatmapCellCornerRadius, 6);
      expect(
        find.ancestor(of: day, matching: find.byType(Center)),
        findsNothing,
      );
    },
  );

  testWidgets(
    'MONTH-B3M-02: narrow Month content preserves the responsive centered seven-column grid',
    (tester) async {
      final frame = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      ).preview(range);
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(frame);
      addTearDown(listenable.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              height: 420,
              child: MindMonthHeatmapViewport(frameListenable: listenable),
            ),
          ),
        ),
      );

      final grid = tester.getRect(
        find.byKey(const ValueKey<String>('mind-month-heatmap-grid')),
      );
      expect(grid.width, closeTo(216, .01));
      expect(grid.left, closeTo(12, .01));
      expect(grid.height, closeTo((216 - 6 * 4) / 7 * 6 + 5 * 4, .01));
    },
  );

  testWidgets(
    'SUM/MONTH-HM-10/11: the one palette setting repaints both temporal heatmaps without frame replacement',
    (tester) async {
      final sum = MindSumHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|all',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'all',
        ),
        contributions: contributions,
      ).preview(range);
      final month = MindMonthHeatmapProjection.build(
        identity: const MindTemporalHeatmapIdentity(
          upstreamScopeKey: 'expense|month:2025-05',
          indexGeneration: 1,
          coreRevision: 1,
          timeScopeKey: 'month:2025-05',
        ),
        year: 2025,
        month: 5,
        contributions: contributions,
      ).preview(range);
      final sumListenable = ValueNotifier<MindTemporalHeatmapFrame?>(sum);
      final monthListenable = ValueNotifier<MindTemporalHeatmapFrame?>(month);
      final settings = MindYearHeatmapPresentationController();
      addTearDown(sumListenable.dispose);
      addTearDown(monthListenable.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                SizedBox(
                  width: 360,
                  height: 220,
                  child: MindSumHeatmapViewport(
                    frameListenable: sumListenable,
                    presentationSettings: settings,
                  ),
                ),
                SizedBox(
                  width: 360,
                  height: 220,
                  child: MindMonthHeatmapViewport(
                    frameListenable: monthListenable,
                    presentationSettings: settings,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final before = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('mind-sum-heatmap-cell-2025-5')),
      );
      expect(
        (before.decoration as BoxDecoration).color,
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.fluvi,
          isEmpty: false,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        ).background,
      );

      settings.setPaletteStyle(MindYearHeatmapPaletteStyle.b3mMy3);
      await tester.pump();
      final after = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('mind-sum-heatmap-cell-2025-5')),
      );
      expect(
        (after.decoration as BoxDecoration).color,
        MindYearHeatmapPaletteResolver.resolveTile(
          style: MindYearHeatmapPaletteStyle.b3mMy3,
          isEmpty: false,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        ).background,
      );
      expect(identical(sumListenable.value, sum), isTrue);
      expect(identical(monthListenable.value, month), isTrue);
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
);
