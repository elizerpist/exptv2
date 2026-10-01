import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_temporal_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_day_all_vs_slider_heatmap_card.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_heatmap_palette_scope.dart';
import 'package:fluvi/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  testWidgets(
    'DAYFIX-04 RED: renders capacity, full-day and selected native layers for each hour',
    (tester) async {
      final frame = MindDayHeatmapFrame(
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
        timelineEvents: const <MindDayTimelineEvent>[
          MindDayTimelineEvent(ordinal: 2, timeMinutes: 8 * 60, total: 2500),
        ],
        fullTimelineEvents: const <MindDayTimelineEvent>[
          MindDayTimelineEvent(ordinal: 1, timeMinutes: 8 * 60, total: 5000),
          MindDayTimelineEvent(ordinal: 2, timeMinutes: 8 * 60, total: 2500),
          MindDayTimelineEvent(ordinal: 3, timeMinutes: 18 * 60, total: 7000),
        ],
        activeHourCount: 1,
        total: 2500,
        minimumNonEmptyTotal: 2500,
        maximumNonEmptyTotal: 2500,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 520,
              child: MindDayAllVsSliderHeatmapCard(frame: frame),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-day-all-slider-card')),
        findsOneWidget,
      );
      expect(find.text('Napi aktivitás'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('mind-day-all-slider-hour-00')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-all-slider-hour-23')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-all-slider-full-08')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mind-day-all-slider-capacity-08')),
        findsOneWidget,
        reason: 'The neutral 100% capacity bar remains behind both values.',
      );
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('mind-day-all-slider-capacity-08')),
            )
            .height,
        tester
            .getSize(
              find.byKey(const ValueKey('mind-day-all-slider-capacity-18')),
            )
            .height,
        reason: 'Every neutral capacity bar uses the common 100% envelope.',
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('mind-day-all-slider-full-08')))
            .height,
        greaterThan(
          tester
              .getSize(
                find.byKey(const ValueKey('mind-day-all-slider-selected-08')),
              )
              .height,
        ),
        reason: 'The selected foreground is a strict subset of full-day spend.',
      );
      expect(
        find.byKey(const ValueKey('mind-day-all-slider-selected-08')),
        findsOneWidget,
      );
      expect(find.text('Teljes nap'), findsOneWidget);
      expect(find.text('Aktuális szűrő'), findsOneWidget);
      expect(
        find.text('Kisebb összeg'),
        findsNothing,
        reason: 'Day must not add a second palette legend above its slider.',
      );
      expect(find.text('Nagyobb összeg'), findsNothing);
      expect(
        find.byType(RangeSlider),
        findsNothing,
        reason: 'The existing canonical range control remains the only owner.',
      );
    },
  );

  testWidgets(
    'DAYFIX-03 RED: Day selected bars consume the live shared heatmap scale',
    (tester) async {
      const dynamicHigh = Color(0xff145c48);
      await tester.pumpWidget(
        MaterialApp(
          home: MindHeatmapPaletteScope(
            scale: MindHeatmapResolvedScale(<Color>[
              Color(0xffe6f8ef),
              dynamicHigh,
            ]),
            child: Scaffold(
              body: SizedBox(
                width: 390,
                height: 520,
                child: MindDayAllVsSliderHeatmapCard(
                  frame: _frameWithActivity(),
                ),
              ),
            ),
          ),
        ),
      );

      final selected = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('mind-day-all-slider-selected-08')),
      );
      final decoration = selected.decoration as BoxDecoration;
      final expected = MindYearHeatmapPaletteResolver.resolveTile(
        style: MindYearHeatmapPaletteStyle.fluvi,
        isEmpty: false,
        intensity: 2500 / 7500,
        paletteIntensity: MindYearHeatmapPaletteIntensity.interpolated,
        dynamicScale: MindHeatmapResolvedScale(<Color>[
          const Color(0xffe6f8ef),
          dynamicHigh,
        ]),
      );
      expect(decoration.color, expected.background);
    },
  );

  testWidgets(
    'DAYFIX-02: Day is body content and cannot create a second bottom-card seam',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 520,
              child: MindDayAllVsSliderHeatmapCard(frame: _frame()),
            ),
          ),
        ),
      );
      expect(
        tester.widget(find.byKey(const ValueKey('mind-day-all-slider-card'))),
        isA<KeyedSubtree>(),
      );
    },
  );

  testWidgets(
    'MIND-DAY-ALL-SLIDER-03 RED: the shared Day header uses the truthful Hungarian March abbreviation',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 520,
              child: MindDayAllVsSliderHeatmapCard(
                frame: _frameFor(
                  const LocalDate(year: 2025, month: 3, day: 14),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2025. márc. 14. · Péntek'), findsOneWidget);
    },
  );

  testWidgets(
    'MIND-DAY-ALL-SLIDER-02 RED: the header view control forwards a timeline intent instead of rendering an inert selector',
    (tester) async {
      var timelineRequested = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 520,
              child: MindDayAllVsSliderHeatmapCard(
                frame: _frame(),
                onTimelineRequested: () => timelineRequested = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('mind-day-all-slider-view-timeline')),
      );

      expect(timelineRequested, isTrue);
    },
  );

  testWidgets(
    'MIND-DAY-ALL-SLIDER-04 RED: the supplied canonical range control is mounted once inside the Day source card',
    (tester) async {
      const rangeKey = ValueKey<String>('canonical-day-range-test');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 520,
              child: MindDayRangeFooterScope(
                range: const SizedBox(key: rangeKey),
                child: MindDayAllVsSliderHeatmapCard(frame: _frame()),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('mind-day-heatmap-range-footer')),
        findsOneWidget,
      );
      expect(find.byKey(rangeKey), findsOneWidget);
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

MindDayHeatmapFrame _frameFor(LocalDate date) => MindDayHeatmapFrame(
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
  date: date,
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

MindDayHeatmapFrame _frameWithActivity() => MindDayHeatmapFrame(
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
  timelineEvents: const <MindDayTimelineEvent>[
    MindDayTimelineEvent(ordinal: 2, timeMinutes: 8 * 60, total: 2500),
  ],
  fullTimelineEvents: const <MindDayTimelineEvent>[
    MindDayTimelineEvent(ordinal: 1, timeMinutes: 8 * 60, total: 5000),
    MindDayTimelineEvent(ordinal: 2, timeMinutes: 8 * 60, total: 2500),
  ],
  activeHourCount: 1,
  total: 2500,
  minimumNonEmptyTotal: 2500,
  maximumNonEmptyTotal: 2500,
);
