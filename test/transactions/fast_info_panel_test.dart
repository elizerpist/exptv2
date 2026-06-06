import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric.dart';
import 'package:exptv2/features/transactions/widgets/header_card/fast_info_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders all structured visual types compositionally', (
    tester,
  ) async {
    final config = FastInfoConfig(
      pills: [
        _slot('mai_koltes', FastInfoSlotType.pill),
        _slot('koltesi_trend', FastInfoSlotType.pill),
        null,
      ],
      boxes: [
        _slot('havi_koltes', FastInfoSlotType.box),
        _slot('heti_koltes', FastInfoSlotType.box),
        _slot('legutobbi_tranzakcio', FastInfoSlotType.box),
      ],
    );
    final metrics = <String, FastInfoMetricResult>{
      'mai_koltes': const FastInfoMetricResult(
        pillValue: '7k',
        primaryValue: '7 000 Ft elköltve',
        progressKind: FastInfoProgressKind.bar,
        progress: .5,
        trend: FastInfoTrend(
          direction: FastInfoTrendDirection.up,
          text: '+5%',
          semantic: FastInfoSemantic.bad,
        ),
      ),
      'koltesi_trend': const FastInfoMetricResult(
        pillValue: '53k',
        primaryValue: '53 000 Ft',
        trend: FastInfoTrend(
          direction: FastInfoTrendDirection.down,
          text: '-10%',
          semantic: FastInfoSemantic.good,
        ),
      ),
      'havi_koltes': const FastInfoMetricResult(
        pillValue: '27k',
        primaryValue: '27 000 Ft',
        secondaryValues: <String>['9% a havi keretből'],
        progressKind: FastInfoProgressKind.bar,
        progress: .09,
        chartKind: FastInfoChartKind.multiLine,
        chartSeries: <FastInfoChartSeries>[
          FastInfoChartSeries(label: 'Aktuális', values: <double>[8, 12, 7]),
          FastInfoChartSeries(label: 'Előző', values: <double>[5, 9, 4]),
          FastInfoChartSeries(label: 'Két hónapja', values: <double>[4, 7, 6]),
        ],
      ),
      'heti_koltes': const FastInfoMetricResult(
        pillValue: '27k',
        primaryValue: '27 000 Ft',
        chartKind: FastInfoChartKind.weeklyBars,
        weeklyBars: <FastInfoWeeklyBar>[
          FastInfoWeeklyBar(
            value: 8,
            isFuture: false,
            semantic: FastInfoSemantic.good,
          ),
          FastInfoWeeklyBar(
            value: 12,
            isFuture: false,
            semantic: FastInfoSemantic.warning,
          ),
          FastInfoWeeklyBar(
            value: 7,
            isFuture: false,
            semantic: FastInfoSemantic.bad,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
        ],
      ),
      'legutobbi_tranzakcio': const FastInfoMetricResult(
        pillValue: '-2k',
        primaryValue: '-2 000 Ft',
        secondaryValues: <String>['Kávézó', 'Étel · 14:00'],
        avatar: FastInfoAvatar(colorHex: '#22c55e', iconSlot: 0),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('fastinfo-progress-havi_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-weekly-bars-heti_koltes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-monthly-line-havi_koltes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-multiline-havi_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-avatar-legutobbi_tranzakcio')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-trend-koltesi_trend')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-pill-trend-mai_koltes')),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('fastinfo-box-slot-0'))).height,
      136,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('approved pill anatomy renders title values and visual', (
    tester,
  ) async {
    final config = FastInfoConfig(
      pills: [_slot('kiadas_bevetel_arany', FastInfoSlotType.pill), null, null],
      boxes: const [null, null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'kiadas_bevetel_arany': FastInfoMetricResult(
        pillValue: '29% maradt',
        primaryValue: '29% maradt',
        secondaryValues: <String>['180 000 Ft bevételből'],
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.remainingSpentSplit,
          value: .29,
          compareValue: .71,
          semantic: FastInfoSemantic.good,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('fastinfo-pill-title-kiadas_bevetel_arany')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-pill-primary-kiadas_bevetel_arany')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('fastinfo-pill-secondary-kiadas_bevetel_arany'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('fastinfo-visual-remaining-spent-kiadas_bevetel_arany'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily spend pill follows approved markerbar anatomy', (
    tester,
  ) async {
    final config = FastInfoConfig(
      pills: [_slot('mai_koltes', FastInfoSlotType.pill), null, null],
      boxes: const [null, null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'mai_koltes': FastInfoMetricResult(
        pillValue: '7k',
        primaryValue: '7 000 Ft elköltve',
        secondaryValues: <String>[
          '1 tranzakció ma',
          '3 000 Ft költhető',
          'napi átlaghoz képest:',
        ],
        progressKind: FastInfoProgressKind.bar,
        progress: .66,
        semantic: FastInfoSemantic.good,
        trend: FastInfoTrend(
          direction: FastInfoTrendDirection.up,
          text: '+268%',
          semantic: FastInfoSemantic.bad,
        ),
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.thresholdMarkerBar,
          value: .66,
          marker: .78,
          semantic: FastInfoSemantic.good,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(find.text('Mai költés'), findsOneWidget);
    expect(find.text('7 000 Ft'), findsOneWidget);
    expect(find.text('7 000 Ft elköltve'), findsNothing);
    expect(find.text('3 000 Ft költhető'), findsOneWidget);
    expect(find.text('1 tranzakció ma'), findsNothing);
    expect(find.text('+268%'), findsNothing);
    expect(find.text('átl'), findsOneWidget);
    final pillChart = find.byKey(
      const ValueKey('fastinfo-daily-pill-limit-mai_koltes'),
    );
    expect(pillChart, findsOneWidget);
    expect(tester.getSize(pillChart), const Size(84, 24));
    expect(
      find.byKey(const ValueKey('fastinfo-daily-pill-overflow-mai_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-pill-trend-mai_koltes')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'daily spend pill shows dashed overflow when average exceeds today limit',
    (tester) async {
      final config = FastInfoConfig(
        pills: [_slot('mai_koltes', FastInfoSlotType.pill), null, null],
        boxes: const [null, null, null],
      );
      const metrics = <String, FastInfoMetricResult>{
        'mai_koltes': FastInfoMetricResult(
          pillValue: '7k',
          primaryValue: '7 000 Ft elköltve',
          secondaryValues: <String>['1 tranzakció ma', '3 000 Ft költhető'],
          progressKind: FastInfoProgressKind.bar,
          progress: .66,
          semantic: FastInfoSemantic.good,
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.thresholdMarkerBar,
            value: .66,
            marker: 1.28,
            semantic: FastInfoSemantic.good,
          ),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FastInfoPanel(config: config, metrics: metrics),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('fastinfo-daily-pill-overflow-mai_koltes')),
        findsOneWidget,
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('fastinfo-daily-pill-limit-mai_koltes')),
        ),
        const Size(84, 24),
      );
      expect(find.text('átl'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('daily spend box follows approved mockup anatomy', (
    tester,
  ) async {
    final config = FastInfoConfig(
      pills: const [null, null, null],
      boxes: [_slot('mai_koltes', FastInfoSlotType.box), null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'mai_koltes': FastInfoMetricResult(
        pillValue: '7k',
        primaryValue: '7 000 Ft elköltve',
        secondaryValues: <String>[
          '1 tranzakció ma',
          '3 000 Ft költhető',
          'napi átlaghoz képest:',
        ],
        progressKind: FastInfoProgressKind.bar,
        progress: .66,
        semantic: FastInfoSemantic.good,
        trend: FastInfoTrend(
          direction: FastInfoTrendDirection.down,
          text: '-86%',
          semantic: FastInfoSemantic.good,
        ),
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.thresholdMarkerBar,
          value: .66,
          marker: .14,
          semantic: FastInfoSemantic.good,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(find.text('Mai költés'), findsOneWidget);
    expect(find.text('7 000 Ft'), findsOneWidget);
    expect(find.text('7 000 Ft elköltve'), findsNothing);
    expect(find.text('1 tranzakció ma'), findsOneWidget);
    expect(find.text('Napi keret:'), findsOneWidget);
    expect(find.text('3 000 Ft költhető'), findsOneWidget);
    expect(find.text('Napi átlaghoz képest:'), findsOneWidget);
    expect(find.text('-86%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fastinfo-daily-limit-progress-mai_koltes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-visual-threshold-marker-mai_koltes')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly spend box follows v25 anatomy', (tester) async {
    final config = FastInfoConfig(
      pills: const [null, null, null],
      boxes: [_slot('heti_koltes', FastInfoSlotType.box), null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'heti_koltes': FastInfoMetricResult(
        pillValue: '374k',
        primaryValue: '374 800 Ft',
        secondaryValues: <String>[
          '19 tranzakció',
          '42 300 Ft költhető',
          'időarányhoz képest 39p',
        ],
        chartKind: FastInfoChartKind.weeklyBars,
        weeklyBars: <FastInfoWeeklyBar>[
          FastInfoWeeklyBar(
            value: 34,
            isFuture: false,
            semantic: FastInfoSemantic.good,
          ),
          FastInfoWeeklyBar(
            value: 55,
            isFuture: false,
            semantic: FastInfoSemantic.good,
          ),
          FastInfoWeeklyBar(
            value: 76,
            isFuture: false,
            semantic: FastInfoSemantic.warning,
          ),
          FastInfoWeeklyBar(
            value: 96,
            isFuture: false,
            semantic: FastInfoSemantic.bad,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
        ],
        trend: FastInfoTrend(
          direction: FastInfoTrendDirection.up,
          text: '+18%',
          semantic: FastInfoSemantic.bad,
        ),
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.deviationMeter,
          value: .39,
          semantic: FastInfoSemantic.bad,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(find.text('Heti költés'), findsOneWidget);
    expect(find.text('374 800 Ft'), findsOneWidget);
    expect(find.text('19 tranzakció'), findsOneWidget);
    expect(find.text('Fixek nélkül a keret'), findsOneWidget);
    expect(find.text('Heti ritmus:'), findsOneWidget);
    expect(find.text('42 300 Ft költhető'), findsOneWidget);
    expect(find.text('Heti átlaghoz képest:'), findsOneWidget);
    expect(find.text('+18%'), findsOneWidget);
    final weeklyBars = find.byKey(
      const ValueKey('fastinfo-weekly-bars-heti_koltes'),
    );
    expect(weeklyBars, findsOneWidget);
    expect(tester.getSize(weeklyBars).height, 23);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly spend pill follows v25 balance decision', (tester) async {
    final config = FastInfoConfig(
      pills: [_slot('heti_koltes', FastInfoSlotType.pill), null, null],
      boxes: const [null, null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'heti_koltes': FastInfoMetricResult(
        pillValue: '374k',
        primaryValue: '374 800 Ft',
        secondaryValues: <String>[
          '19 tranzakció',
          '42 300 Ft költhető',
          'időarányhoz képest 39p',
        ],
        chartKind: FastInfoChartKind.weeklyBars,
        weeklyBars: <FastInfoWeeklyBar>[
          FastInfoWeeklyBar(
            value: 34,
            isFuture: false,
            semantic: FastInfoSemantic.good,
          ),
          FastInfoWeeklyBar(
            value: 55,
            isFuture: false,
            semantic: FastInfoSemantic.good,
          ),
          FastInfoWeeklyBar(
            value: 76,
            isFuture: false,
            semantic: FastInfoSemantic.warning,
          ),
          FastInfoWeeklyBar(
            value: 96,
            isFuture: false,
            semantic: FastInfoSemantic.bad,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
          FastInfoWeeklyBar(
            value: 0,
            isFuture: true,
            semantic: FastInfoSemantic.neutral,
          ),
        ],
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.deviationMeter,
          value: .39,
          semantic: FastInfoSemantic.bad,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(find.text('Heti költés'), findsOneWidget);
    expect(find.text('374 800 Ft'), findsOneWidget);
    expect(find.text('időarányhoz képest 39p'), findsOneWidget);
    expect(find.text('42 300 Ft költhető'), findsNothing);
    expect(find.text('19 tranzakció'), findsNothing);
    expect(
      find.byKey(const ValueKey('fastinfo-weekly-bars-heti_koltes')),
      findsNothing,
    );
    final balance = find.byKey(
      const ValueKey('fastinfo-weekly-balance-heti_koltes'),
    );
    expect(balance, findsOneWidget);
    expect(tester.getSize(balance), const Size(84, 24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly spend box follows v25 anatomy', (tester) async {
    final config = FastInfoConfig(
      pills: const [null, null, null],
      boxes: [_slot('havi_koltes', FastInfoSlotType.box), null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'havi_koltes': FastInfoMetricResult(
        pillValue: '948k',
        primaryValue: '948 632 Ft',
        secondaryValues: <String>[
          '59% a havi keretből',
          'előző hónap index: 59%',
          '141 368 Ft költhető',
        ],
        progressKind: FastInfoProgressKind.bar,
        progress: .59,
        semantic: FastInfoSemantic.good,
        trend: FastInfoTrend(
          direction: FastInfoTrendDirection.down,
          text: '-50%',
          semantic: FastInfoSemantic.good,
        ),
        chartKind: FastInfoChartKind.multiLine,
        chartSeries: <FastInfoChartSeries>[
          FastInfoChartSeries(
            label: 'Aktuális',
            values: <double>[24, 18, 15, 6, 16, 14, 8],
          ),
          FastInfoChartSeries(
            label: 'Előző',
            values: <double>[23, 20, 16, 12, 10, 18, 9],
          ),
          FastInfoChartSeries(
            label: 'Két hónapja',
            values: <double>[20, 18, 15, 13, 10, 12, 11],
          ),
        ],
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.sameDayIndexMarker,
          value: .59,
          compareValue: .59,
          semantic: FastInfoSemantic.good,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(find.text('Havi költés'), findsOneWidget);
    expect(find.text('948 632 Ft'), findsOneWidget);
    expect(find.text('aktuális hó eddig'), findsOneWidget);
    expect(find.text('Előző hó azonos napjáig'), findsOneWidget);
    expect(find.text('Havi vonal:'), findsOneWidget);
    expect(find.text('előző / aktuális / előző előtti'), findsOneWidget);
    expect(find.text('Azonos napig:'), findsOneWidget);
    expect(find.text('-50%'), findsOneWidget);
    final line = find.byKey(
      const ValueKey('fastinfo-monthly-line-havi_koltes'),
    );
    expect(line, findsOneWidget);
    expect(tester.getSize(line).height, 29);
    expect(
      find.byKey(const ValueKey('fastinfo-progress-havi_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-multiline-havi_koltes')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly spend pill follows v25 index decision', (tester) async {
    final config = FastInfoConfig(
      pills: [_slot('havi_koltes', FastInfoSlotType.pill), null, null],
      boxes: const [null, null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'havi_koltes': FastInfoMetricResult(
        pillValue: '948k',
        primaryValue: '948 632 Ft',
        secondaryValues: <String>[
          '59% a havi keretből',
          'előző hónap index: 59%',
          '141 368 Ft költhető',
        ],
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.sameDayIndexMarker,
          value: .59,
          compareValue: .59,
          semantic: FastInfoSemantic.good,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(find.text('Havi költés'), findsOneWidget);
    expect(find.text('948 632 Ft'), findsOneWidget);
    expect(find.text('előző hónap index: 59%'), findsOneWidget);
    expect(find.text('59% a havi keretből'), findsNothing);
    expect(find.text('141 368 Ft költhető'), findsNothing);
    final index = find.byKey(
      const ValueKey('fastinfo-monthly-index-havi_koltes'),
    );
    expect(index, findsOneWidget);
    expect(tester.getSize(index), const Size(84, 24));
    expect(
      find.byKey(const ValueKey('fastinfo-visual-same-day-index-havi_koltes')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not render filler visuals for plain metric', (
    tester,
  ) async {
    final config = FastInfoConfig(
      pills: const [null, null, null],
      boxes: [_slot('mai_koltes', FastInfoSlotType.box), null, null],
    );
    const metrics = <String, FastInfoMetricResult>{
      'mai_koltes': FastInfoMetricResult(
        pillValue: '0',
        primaryValue: '0 Ft elköltve',
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, metrics: metrics),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('fastinfo-progress-mai_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-sparkline-mai_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-weekly-bars-mai_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-multiline-mai_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-avatar-mai_koltes')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-trend-mai_koltes')),
      findsNothing,
    );
  });

  testWidgets('six box mode renders upper slots as a distinct box row', (
    tester,
  ) async {
    final config = FastInfoConfig.defaults().copyWith(
      layoutMode: FastInfoLayoutMode.sixBoxes,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FastInfoPanel(config: config)),
      ),
    );

    expect(find.byKey(const ValueKey('fastinfo-pill-slot-0')), findsNothing);
    expect(
      find.byKey(const ValueKey('fastinfo-upper-box-slot-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('fastinfo-box-slot-0')), findsOneWidget);

    final upperTop = tester
        .getTopLeft(find.byKey(const ValueKey('fastinfo-upper-box-slot-0')))
        .dy;
    final lowerTop = tester
        .getTopLeft(find.byKey(const ValueKey('fastinfo-box-slot-0')))
        .dy;
    expect(upperTop, lessThan(lowerTop));
  });

  testWidgets('lower row can render assigned box slots as pills', (
    tester,
  ) async {
    final config = FastInfoConfig.defaults().copyWith(
      lowerRowPresentation: FastInfoRowPresentation.pill,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(config: config, onDropBoxCard: (_, _) {}),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('fastinfo-pill-slot-0')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fastinfo-lower-pill-slot-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('fastinfo-box-slot-0')), findsNothing);
    expect(
      find.byKey(const ValueKey('fastinfo-lower-pill-drop-0')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('assigned card tap reports canonical card id', (tester) async {
    final tapped = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: FastInfoConfig.defaults(),
            onCardTap: tapped.add,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('fastinfo-pill-slot-0')));
    await tester.pumpAndSettle();

    expect(tapped, <String>['havi_koltes']);
  });

  for (final width in <double>[320, 600]) {
    for (final layoutMode in FastInfoLayoutMode.values) {
      testWidgets(
        'keeps structured panel overflow-free in ${layoutMode.name} at width $width',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: width,
                  child: FastInfoPanel(
                    config: FastInfoConfig.defaults().copyWith(
                      layoutMode: layoutMode,
                    ),
                    metrics: const <String, FastInfoMetricResult>{
                      'havi_koltes': FastInfoMetricResult(
                        pillValue: '27k',
                        primaryValue: '27 000 Ft',
                      ),
                      'koltesi_trend': FastInfoMetricResult(
                        pillValue: '-12%',
                        primaryValue: '53 000 Ft',
                      ),
                      'kiadas_bevetel_arany': FastInfoMetricResult(
                        pillValue: '42%',
                        primaryValue: '42%',
                      ),
                      'mai_koltes': FastInfoMetricResult(
                        pillValue: '7k',
                        primaryValue: '7 000 Ft elköltve',
                      ),
                      'heti_koltes': FastInfoMetricResult(
                        pillValue: '27k',
                        primaryValue: '27 000 Ft',
                      ),
                      'kovetkezo_ismetlo_kiadas': FastInfoMetricResult(
                        pillValue: '8k',
                        primaryValue: 'Telefon · 8 000 Ft',
                      ),
                    },
                  ),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

FastInfoSlot _slot(String id, FastInfoSlotType type) {
  return FastInfoSlot.fromCard(fastInfoCardById(id)!, type);
}
