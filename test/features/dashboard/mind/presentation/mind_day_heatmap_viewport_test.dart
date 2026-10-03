import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_frame.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  testWidgets(
    'MIND-DAY-VIEW-01 RED: Day defaults to the All-vs-slider native heatmap page',
    (tester) async {
      final listenable = ValueNotifier<MindTemporalHeatmapFrame?>(_frame());
      final settings = MindYearHeatmapPresentationController();
      addTearDown(listenable.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 540,
              child: MindDayHeatmapViewport(
                frameListenable: listenable,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-day-all-slider-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-timeline-chart')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-day-content-view-toggle')),
        findsNothing,
        reason: 'The fresh presentation state leaves no selector or hit box.',
      );

      settings.setShowDayContentViewChooser(true);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('mind-day-content-view-toggle')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'MIND-DAY-VIEW-02 RED: the presentation owner switches between the all-vs-slider heatmap and the existing timeline',
    (tester) async {
      final frameListenable = ValueNotifier<MindTemporalHeatmapFrame?>(
        _frame(),
      );
      final settings = MindYearHeatmapPresentationController();
      settings.setShowDayContentViewChooser(true);
      addTearDown(frameListenable.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 540,
              child: MindDayHeatmapViewport(
                frameListenable: frameListenable,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-day-all-slider-card')),
        findsOneWidget,
      );
      settings.setDayContentView(MindDayContentView.timeline);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('mind-day-all-slider-card')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-day-timeline-chart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-timeline-title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-timeline-view-heatmap')),
        findsOneWidget,
      );
    },
  );
}

MindDayHeatmapFrame _frame() => MindDayHeatmapFrame(
  identity: const MindTemporalHeatmapIdentity(
    upstreamScopeKey: 'expense',
    indexGeneration: 1,
    coreRevision: 1,
    timeScopeKey: 'day',
  ),
  range: const QueryAmountRangeValues(
    minimumScaled100: 100,
    maximumScaled100: 10000,
    lowerScaled100: 1000,
    upperScaled100: 8000,
  ),
  date: const LocalDate(year: 2025, month: 5, day: 14),
  hours: List<MindDayHeatmapHour>.generate(
    24,
    (hour) => MindDayHeatmapHour(
      hour: hour,
      total: null,
      kind: MindYearHeatmapTileKind.empty,
      intensity: 0,
      paletteIntensity: MindYearHeatmapPaletteIntensity.empty,
    ),
  ),
  timelineEvents: const <MindDayTimelineEvent>[],
  fullTimelineEvents: const <MindDayTimelineEvent>[],
  activeHourCount: 0,
  total: 0,
  minimumNonEmptyTotal: null,
  maximumNonEmptyTotal: null,
);
