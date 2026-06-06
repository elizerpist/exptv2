import 'package:exptv2/core/debug/debug_console.dart';
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
      find.byKey(
        const ValueKey('fastinfo-last-transaction-avatar-legutobbi_tranzakcio'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-avatar-legutobbi_tranzakcio')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-rolling-pill-band-koltesi_trend')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-trend-koltesi_trend')),
      findsNothing,
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
        const ValueKey('fastinfo-income-spent-split-kiadas_bevetel_arany'),
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
    for (final key in <String>[
      'fastinfo-monthly-index-good-havi_koltes',
      'fastinfo-monthly-index-warning-havi_koltes',
      'fastinfo-monthly-index-bad-havi_koltes',
    ]) {
      final segment = find.byKey(ValueKey(key));
      expect(segment, findsOneWidget);
      expect(tester.getSize(segment).height, 7);
      expect(tester.getSize(segment).width, greaterThan(0));
    }
    expect(
      find.byKey(const ValueKey('fastinfo-visual-same-day-index-havi_koltes')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('savings box and pill follow v25 projection decision', (
    tester,
  ) async {
    const metrics = <String, FastInfoMetricResult>{
      'megtakaritas': FastInfoMetricResult(
        pillValue: '220k',
        primaryValue: '220 000 Ft',
        secondaryValues: <String>[
          'bevétel - kiadás hóban',
          'cél: 300 000 Ft',
          'várható cél: 86%',
        ],
        progressKind: FastInfoProgressKind.ring,
        progress: .73,
        semantic: FastInfoSemantic.neutral,
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.goalMarker,
          value: .73,
          marker: .86,
          semantic: FastInfoSemantic.good,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: FastInfoConfig(
              pills: [_slot('megtakaritas', FastInfoSlotType.pill), null, null],
              boxes: [_slot('megtakaritas', FastInfoSlotType.box), null, null],
            ),
            metrics: metrics,
          ),
        ),
      ),
    );

    expect(find.text('Megtakarítás'), findsWidgets);
    expect(find.text('220 000 Ft'), findsWidgets);
    expect(find.text('várható cél: 86%'), findsOneWidget);
    expect(find.text('Cél haladás:'), findsOneWidget);
    expect(find.text('73%'), findsOneWidget);
    expect(find.text('cél: 300 000 Ft'), findsOneWidget);
    expect(find.text('Havi állás:'), findsOneWidget);
    expect(find.text('+220k'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fastinfo-saving-projection-megtakaritas')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-visual-goal-marker-megtakaritas')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rolling trend box and pill follow v25 fixed-free band decision',
    (tester) async {
      DebugConsole.clear();
      const metrics = <String, FastInfoMetricResult>{
        'koltesi_trend': FastInfoMetricResult(
          pillValue: '1.02M',
          primaryValue: '1 020 000 Ft',
          secondaryValues: <String>[
            'előző 30 nap: 905 000 Ft',
            'előző 30 naphoz +13%',
            'fix tételek nélkül',
          ],
          trend: FastInfoTrend(
            direction: FastInfoTrendDirection.up,
            text: '+13%',
            semantic: FastInfoSemantic.bad,
          ),
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.zoneMarker,
            value: 1.13,
            semantic: FastInfoSemantic.warning,
          ),
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FastInfoPanel(
              config: FastInfoConfig(
                pills: [
                  _slot('koltesi_trend', FastInfoSlotType.pill),
                  null,
                  null,
                ],
                boxes: [
                  _slot('koltesi_trend', FastInfoSlotType.box),
                  null,
                  null,
                ],
              ),
              metrics: metrics,
            ),
          ),
        ),
      );

      expect(find.text('30 napos trend'), findsWidgets);
      expect(find.text('1 020 000 Ft'), findsWidgets);
      expect(find.text('előző 30 naphoz +13%'), findsOneWidget);
      expect(find.text('Fix tételek nélkül'), findsOneWidget);
      expect(find.text('30 nap vs előző 30:'), findsOneWidget);
      expect(find.text('Változás:'), findsOneWidget);
      expect(find.text('+13%'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('fastinfo-rolling-pill-band-koltesi_trend')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fastinfo-rolling-pill-split-koltesi_trend')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fastinfo-rolling-split-koltesi_trend')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey('fastinfo-rolling-split-koltesi_trend'),
              ),
            )
            .height,
        13,
      );
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('fastinfo-rolling-pill-band-koltesi_trend'),
          ),
        ),
        const Size(78, 18),
      );
      final bandRect = tester.getRect(
        find.byKey(const ValueKey('fastinfo-rolling-pill-band-koltesi_trend')),
      );
      final needleRect = tester.getRect(
        find.byKey(
          const ValueKey('fastinfo-rolling-pill-band-needle-koltesi_trend'),
        ),
      );
      expect(
        needleRect.center.dx - bandRect.left,
        greaterThan(bandRect.width * .64),
      );
      for (final key in <String>[
        'fastinfo-rolling-pill-band-low-koltesi_trend',
        'fastinfo-rolling-pill-band-mid-koltesi_trend',
        'fastinfo-rolling-pill-band-high-koltesi_trend',
        'fastinfo-rolling-split-prev-koltesi_trend',
        'fastinfo-rolling-split-current-koltesi_trend',
      ]) {
        final segment = find.byKey(ValueKey(key));
        expect(segment, findsOneWidget);
        expect(tester.getSize(segment).width, greaterThan(0));
      }
      expect(
        find.byKey(const ValueKey('fastinfo-trend-koltesi_trend')),
        findsNothing,
      );
      expect(
        DebugConsole.entries.any(
          (entry) =>
              entry.contains('[FastInfo][30dTrend] pill band') &&
              entry.contains('slot=koltesi_trend') &&
              entry.contains('index=1.13'),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('latest transaction box and pill use category icon avatar', (
    tester,
  ) async {
    const metrics = <String, FastInfoMetricResult>{
      'legutobbi_tranzakcio': FastInfoMetricResult(
        pillValue: '-4 890 Ft',
        primaryValue: '-4 890 Ft',
        secondaryValues: <String>['Kávézó · Étel', 'ma 16:12'],
        avatar: FastInfoAvatar(colorHex: '#f97316', iconSlot: 2),
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.avatar,
          avatar: FastInfoAvatar(colorHex: '#f97316', iconSlot: 2),
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: FastInfoConfig(
              pills: [
                _slot('legutobbi_tranzakcio', FastInfoSlotType.pill),
                null,
                null,
              ],
              boxes: [
                _slot('legutobbi_tranzakcio', FastInfoSlotType.box),
                null,
                null,
              ],
            ),
            metrics: metrics,
          ),
        ),
      ),
    );

    expect(find.text('Utolsó tranzakció'), findsWidgets);
    expect(find.text('-4 890 Ft'), findsWidgets);
    expect(find.text('Kávézó · Étel'), findsOneWidget);
    expect(find.text('Kávézó'), findsOneWidget);
    expect(find.text('Étel'), findsOneWidget);
    expect(find.text('ma 16:12'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('fastinfo-last-transaction-avatar-legutobbi_tranzakcio'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'fastinfo-last-transaction-pill-avatar-legutobbi_tranzakcio',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fastinfo-visual-avatar-legutobbi_tranzakcio')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('forecast box and pill follow v25 trend and limit decision', (
    tester,
  ) async {
    const metrics = <String, FastInfoMetricResult>{
      'varhato_ho_vegi_koltes': FastInfoMetricResult(
        pillValue: '870k',
        primaryValue: '870 000 Ft',
        secondaryValues: <String>['havi keret 72%', 'sáv 780-940k'],
        semantic: FastInfoSemantic.good,
        chartKind: FastInfoChartKind.sparkline,
        chartSeries: <FastInfoChartSeries>[
          FastInfoChartSeries(
            label: 'Előrejelzés',
            values: <double>[20, 18, 21, 15, 9, 11, 8],
          ),
        ],
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.projectionFill,
          value: .72,
          marker: .72,
          compareValue: .58,
          values: <double>[20, 18, 21, 15, 9, 11, 8],
          semantic: FastInfoSemantic.good,
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: FastInfoConfig(
              pills: [
                _slot('varhato_ho_vegi_koltes', FastInfoSlotType.pill),
                null,
                null,
              ],
              boxes: [
                _slot('varhato_ho_vegi_koltes', FastInfoSlotType.box),
                null,
                null,
              ],
            ),
            metrics: metrics,
          ),
        ),
      ),
    );

    expect(find.text('Várható hó végi'), findsOneWidget);
    expect(find.text('Várható hó végi költés'), findsOneWidget);
    expect(find.text('870 000 Ft'), findsWidgets);
    expect(find.text('optimista/várt/pesszimista'), findsNothing);
    expect(find.text('Fix-korrigált becslés'), findsOneWidget);
    expect(find.text('Becslés trend:'), findsOneWidget);
    expect(find.text('elmúlt 7 nap · today kék'), findsOneWidget);
    expect(find.text('Becslési sáv:'), findsOneWidget);
    expect(find.text('havi keret 72%'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('fastinfo-forecast-line-varhato_ho_vegi_koltes'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('fastinfo-forecast-range-varhato_ho_vegi_koltes'),
      ),
      findsOneWidget,
    );
    final pillLimit = find.byKey(
      const ValueKey('fastinfo-forecast-pill-limit-varhato_ho_vegi_koltes'),
    );
    expect(pillLimit, findsOneWidget);
    expect(tester.getSize(pillLimit), const Size(84, 24));
    expect(
      find.byKey(
        const ValueKey('fastinfo-visual-projection-varhato_ho_vegi_koltes'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tightest limit box and pill follow v25 avatar projection decision', (
    tester,
  ) async {
    const metrics = <String, FastInfoMetricResult>{
      'leggyorsabban_fogyo_kategorialimit': FastInfoMetricResult(
        pillValue: 'Étel 90%',
        primaryValue: 'Étel',
        secondaryValues: <String>[
          '54 200 / 60 000 Ft',
          '5 800 Ft maradt',
          'várható 108%',
          'Étel hó végére',
        ],
        progressKind: FastInfoProgressKind.bar,
        progress: .90,
        semantic: FastInfoSemantic.warning,
        avatar: FastInfoAvatar(colorHex: '#f59e0b', iconSlot: 2),
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.overflowRisk,
          value: 1.08,
          compareValue: .90,
          semantic: FastInfoSemantic.bad,
          avatar: FastInfoAvatar(colorHex: '#f59e0b', iconSlot: 2),
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: FastInfoConfig(
              pills: [
                _slot(
                  'leggyorsabban_fogyo_kategorialimit',
                  FastInfoSlotType.pill,
                ),
                null,
                null,
              ],
              boxes: [
                _slot(
                  'leggyorsabban_fogyo_kategorialimit',
                  FastInfoSlotType.box,
                ),
                null,
                null,
              ],
            ),
            metrics: metrics,
          ),
        ),
      ),
    );

    expect(find.text('Legszűkebb limit'), findsWidgets);
    expect(find.text('Étel'), findsWidgets);
    expect(find.text('54 200 / 60 000 Ft'), findsOneWidget);
    expect(find.text('5 800 Ft maradt'), findsOneWidget);
    expect(find.text('Limit állás:'), findsOneWidget);
    expect(find.text('Figyelendő:'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('várható 108%'), findsOneWidget);
    expect(find.text('Étel hó végére'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'fastinfo-tightest-limit-avatar-leggyorsabban_fogyo_kategorialimit',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'fastinfo-tightest-limit-progress-leggyorsabban_fogyo_kategorialimit',
        ),
      ),
      findsOneWidget,
    );
    final overflow = find.byKey(
      const ValueKey(
        'fastinfo-tightest-limit-pill-overflow-leggyorsabban_fogyo_kategorialimit',
      ),
    );
    expect(overflow, findsOneWidget);
    expect(tester.getSize(overflow), const Size(84, 24));
    expect(
      find.byKey(
        const ValueKey(
          'fastinfo-visual-overflow-risk-leggyorsabban_fogyo_kategorialimit',
        ),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('top merchant box and pill follow v25 activity decision', (
    tester,
  ) async {
    const metrics = <String, FastInfoMetricResult>{
      'leggyakoribb_kereskedo': FastInfoMetricResult(
        pillValue: 'Spar 14x',
        primaryValue: 'Spar',
        secondaryValues: <String>[
          'legtöbb tranzakció',
          '14 alkalom',
          '82 400 Ft',
          '6 aktív nap',
          'Bolt',
        ],
        avatar: FastInfoAvatar(colorHex: '#3b82f6', iconSlot: 4),
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.activityStrip,
          value: 14,
          avatar: FastInfoAvatar(colorHex: '#3b82f6', iconSlot: 4),
          points: <FastInfoVisualPoint>[
            FastInfoVisualPoint(label: '1', value: 1),
            FastInfoVisualPoint(label: '2', value: 0),
            FastInfoVisualPoint(label: '3', value: 1),
            FastInfoVisualPoint(label: '4', value: 1),
            FastInfoVisualPoint(label: '5', value: 0),
            FastInfoVisualPoint(label: '6', value: 1),
            FastInfoVisualPoint(label: '7', value: 0),
            FastInfoVisualPoint(label: '8', value: 0),
            FastInfoVisualPoint(label: '9', value: 1),
            FastInfoVisualPoint(label: '10', value: 0),
            FastInfoVisualPoint(label: '11', value: 1, isToday: true),
            FastInfoVisualPoint(label: '12', value: 0),
            FastInfoVisualPoint(label: '13', value: 0),
            FastInfoVisualPoint(label: '14', value: 0),
          ],
        ),
      ),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: FastInfoConfig(
              pills: [
                _slot('leggyakoribb_kereskedo', FastInfoSlotType.pill),
                null,
                null,
              ],
              boxes: [
                _slot('leggyakoribb_kereskedo', FastInfoSlotType.box),
                null,
                null,
              ],
            ),
            metrics: metrics,
          ),
        ),
      ),
    );

    expect(find.text('Gyakori kereskedő'), findsWidgets);
    expect(find.text('Spar'), findsWidgets);
    expect(find.text('Spar 14x'), findsOneWidget);
    expect(find.text('legtöbb tranzakció'), findsOneWidget);
    expect(find.text('Bolt'), findsOneWidget);
    expect(find.text('Tranzakció:'), findsOneWidget);
    expect(find.text('14 alkalom'), findsOneWidget);
    expect(find.text('Összesen:'), findsOneWidget);
    expect(find.text('82 400 Ft'), findsOneWidget);
    expect(find.text('6 aktív nap'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('fastinfo-top-merchant-avatar-leggyakoribb_kereskedo'),
      ),
      findsOneWidget,
    );
    final strip = find.byKey(
      const ValueKey('fastinfo-merchant-days-leggyakoribb_kereskedo'),
    );
    expect(strip, findsOneWidget);
    expect(tester.getSize(strip), const Size(84, 24));
    expect(
      find.byKey(
        const ValueKey('fastinfo-visual-activity-leggyakoribb_kereskedo'),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('remaining v25 cards render dedicated box and pill layouts', (
    tester,
  ) async {
    final cases = <_V25SurfaceCase>[
      _V25SurfaceCase(
        id: 'atlagos_napi_koltes',
        metric: const FastInfoMetricResult(
          pillValue: '18 400 Ft',
          primaryValue: '18 400 Ft',
          secondaryValues: <String>[
            'elmúlt 30 nap átlaga',
            'Puffer: 12 nap',
            '3 kiugró nap húzza',
            'fixek nélkül',
          ],
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.spikeLine,
            values: <double>[10, 16, 12, 30, 11, 35, 14],
          ),
        ),
        expectedTexts: <String>['Napi átlag', 'Költési ritmus:', 'Elég még:'],
        expectedKeys: <String>[
          'fastinfo-average-spike-atlagos_napi_koltes',
          'fastinfo-average-line-atlagos_napi_koltes',
        ],
      ),
      _V25SurfaceCase(
        id: 'no_spend_napok_szama',
        metric: const FastInfoMetricResult(
          pillValue: '3 / 7 nap',
          primaryValue: '8 nap',
          secondaryValues: <String>[
            'aktuális hónapban',
            'elmúlt 7 nap',
            'arány: 44%',
            'fixek nélkül',
          ],
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.sevenDayStrip,
            value: .44,
            values: <double>[1, 0, 1, 1, 0, 0, 1],
            points: <FastInfoVisualPoint>[
              FastInfoVisualPoint(label: '1', value: 0),
              FastInfoVisualPoint(label: '2', value: 1),
              FastInfoVisualPoint(label: '3', value: 0),
              FastInfoVisualPoint(label: '4', value: 1, isToday: true),
            ],
          ),
        ),
        expectedTexts: <String>['Költésmentes', 'Havi ritmus:', 'Arány:'],
        expectedKeys: <String>[
          'fastinfo-no-spend-week-no_spend_napok_szama',
          'fastinfo-no-spend-month-no_spend_napok_szama',
        ],
      ),
      _V25SurfaceCase(
        id: 'top_kategoria_heten',
        metric: const FastInfoMetricResult(
          pillValue: 'Ma Étel 18.9k',
          primaryValue: 'Étel',
          secondaryValues: <String>[
            'ma 18.9k',
            'Hét 82k · Hó 144k',
            'fixek nélkül',
          ],
          avatar: FastInfoAvatar(colorHex: '#f97316', iconSlot: 0),
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.miniAvatarRow,
            points: <FastInfoVisualPoint>[
              FastInfoVisualPoint(
                label: 'Ma',
                value: 18900,
                avatar: FastInfoAvatar(colorHex: '#f97316', iconSlot: 0),
              ),
              FastInfoVisualPoint(
                label: 'Hét',
                value: 82400,
                avatar: FastInfoAvatar(colorHex: '#3b82f6', iconSlot: 1),
              ),
              FastInfoVisualPoint(
                label: 'Hó',
                value: 144000,
                avatar: FastInfoAvatar(colorHex: '#8b5cf6', iconSlot: 2),
              ),
            ],
          ),
        ),
        expectedTexts: <String>['Top kategóriák', 'Ma / hét / hó:'],
        expectedKeys: <String>[
          'fastinfo-top-categories-icons-top_kategoria_heten',
          'fastinfo-top-categories-list-top_kategoria_heten',
        ],
      ),
      _V25SurfaceCase(
        id: 'legnagyobb_novekedo_kategoria',
        metric: const FastInfoMetricResult(
          pillValue: 'Étel +22k',
          primaryValue: 'Étel ↑ +22k',
          secondaryValues: <String>['+52% · fix nélkül'],
          trend: FastInfoTrend(
            direction: FastInfoTrendDirection.up,
            text: '+52%',
            semantic: FastInfoSemantic.bad,
          ),
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.analogMeter,
            value: .52,
            values: <double>[42000, 64000],
          ),
        ),
        expectedTexts: <String>[
          'Kategóriaváltozás',
          'Mini vonal:',
          'Változás:',
        ],
        expectedKeys: <String>[
          'fastinfo-category-change-meter-legnagyobb_novekedo_kategoria',
          'fastinfo-category-change-lines-legnagyobb_novekedo_kategoria',
        ],
      ),
      _V25SurfaceCase(
        id: 'kovetkezo_ismetlo_kiadas',
        metric: const FastInfoMetricResult(
          pillValue: 'Telefon 8k',
          primaryValue: 'Telefon',
          secondaryValues: <String>[
            '8 000 Ft · 2 nap múlva',
            '7 nap: 2 tétel · 28 000 Ft',
            'Számlák',
          ],
          avatar: FastInfoAvatar(colorHex: '#8b5cf6', iconSlot: 2),
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.fixedLoad,
            values: <double>[0, 8000, 0, 20000, 0, 0, 0],
            avatar: FastInfoAvatar(colorHex: '#8b5cf6', iconSlot: 2),
          ),
        ),
        expectedTexts: <String>['Következő fix', 'Következő 7 nap:'],
        expectedKeys: <String>[
          'fastinfo-next-fixed-pill-week-kovetkezo_ismetlo_kiadas',
          'fastinfo-next-fixed-week-kovetkezo_ismetlo_kiadas',
          'fastinfo-next-fixed-avatar-kovetkezo_ismetlo_kiadas',
        ],
      ),
      _V25SurfaceCase(
        id: 'havi_fix_koltseg_osszesen',
        metric: const FastInfoMetricResult(
          pillValue: 'hátra 28k',
          primaryValue: '128 000 Ft',
          secondaryValues: <String>[
            'levonva 100k · hátra 28k',
            '128k fixből',
            'Lakbér 100k',
          ],
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.paidRemainingSplit,
            value: .78,
            compareValue: .22,
          ),
        ),
        expectedTexts: <String>['Havi fixek', 'Levont / hátra:', 'Legnagyobb:'],
        expectedKeys: <String>[
          'fastinfo-monthly-fixed-pill-split-havi_fix_koltseg_osszesen',
          'fastinfo-monthly-fixed-split-havi_fix_koltseg_osszesen',
        ],
      ),
      _V25SurfaceCase(
        id: 'bevetel_ebben_a_honapban',
        metric: const FastInfoMetricResult(
          pillValue: '+6% előzőhöz',
          primaryValue: '620 000 Ft',
          secondaryValues: <String>[
            'eddig beérkezett',
            'várt 780k · ghost 160k',
            'Fedezet: 34 nap',
          ],
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.incomeComparisonBars,
            value: 620000,
            compareValue: 585000,
            marker: 780000,
          ),
        ),
        expectedTexts: <String>['Havi bevétel', 'Bevételi tempó:', 'Fedezet:'],
        expectedKeys: <String>[
          'fastinfo-income-compare-bevetel_ebben_a_honapban',
          'fastinfo-income-bars-bevetel_ebben_a_honapban',
        ],
      ),
      _V25SurfaceCase(
        id: 'kiadas_bevetel_arany',
        metric: const FastInfoMetricResult(
          pillValue: '29% maradt',
          primaryValue: '71%',
          secondaryValues: <String>[
            '440k / 620k',
            '180k bevételből',
            'Összes tartalék: 1.2M',
          ],
          progress: .71,
          visual: FastInfoVisualDescriptor(
            kind: FastInfoVisualKind.remainingSpentSplit,
            value: .29,
            compareValue: .71,
          ),
        ),
        expectedTexts: <String>[
          'Bevétel elköltve',
          'Arány:',
          'Összes tartalék:',
        ],
        expectedKeys: <String>[
          'fastinfo-income-spent-split-kiadas_bevetel_arany',
          'fastinfo-income-spent-ratio-kiadas_bevetel_arany',
        ],
      ),
    ];

    for (final item in cases) {
      await _pumpV25SurfaceCase(tester, item);
      for (final text in item.expectedTexts) {
        expect(find.text(text), findsWidgets, reason: item.id);
      }
      for (final key in item.expectedKeys) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: item.id);
      }
      expect(tester.takeException(), isNull, reason: item.id);
    }
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
                        pillValue: 'Telefon 8k',
                        primaryValue: 'Telefon',
                        secondaryValues: <String>['8 000 Ft · 2 nap múlva'],
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

class _V25SurfaceCase {
  const _V25SurfaceCase({
    required this.id,
    required this.metric,
    required this.expectedTexts,
    required this.expectedKeys,
  });

  final String id;
  final FastInfoMetricResult metric;
  final List<String> expectedTexts;
  final List<String> expectedKeys;
}

Future<void> _pumpV25SurfaceCase(
  WidgetTester tester,
  _V25SurfaceCase item,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FastInfoPanel(
          config: FastInfoConfig(
            pills: [_slot(item.id, FastInfoSlotType.pill), null, null],
            boxes: [_slot(item.id, FastInfoSlotType.box), null, null],
          ),
          metrics: <String, FastInfoMetricResult>{item.id: item.metric},
        ),
      ),
    ),
  );
  await tester.pump();
}
