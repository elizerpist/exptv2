import 'package:fluvi/features/pulse/domain/pulse_models.dart';
import 'package:fluvi/features/pulse/domain/pulse_repository.dart';
import 'package:fluvi/features/pulse/presentation/pulse_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Pulse situation overview opens the typed Triage Inspector', (
    tester,
  ) async {
    final situation = _situation();
    final repository = _Repository(_snapshot(situations: [situation]));
    await tester.pumpWidget(
      MaterialApp(
        home: PulseDashboardPage(
          repository: repository,
          coreRevisions: const Stream<Object?>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pénzügyi helyzetek'), findsOneWidget);
    final situationCard = find.byKey(
      const ValueKey('pulse-situation-monthly-budget/2026-10'),
    );
    await tester.ensureVisible(situationCard);
    await tester.pumpAndSettle();
    await tester.tap(situationCard);
    await tester.pumpAndSettle();
    expect(find.text('HELYZETKÉPZÉS'), findsOneWidget);
    expect(find.text('Helyzetképzési szabályok'), findsOneWidget);
  });

  testWidgets(
    'Pulse renders seven cards per group and persists a detail threshold only on save',
    (tester) async {
      final repository = _Repository(_snapshot());
      await tester.pumpWidget(
        MaterialApp(
          home: PulseDashboardPage(
            repository: repository,
            coreRevisions: const Stream<Object?>.empty(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pulse'), findsOneWidget);
      expect(find.byKey(const ValueKey('pulse-card-PULSE-008')), findsNothing);
      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pulse-card-PULSE-001')),
        240,
        scrollable: scrollable,
      );
      expect(
        find.byKey(const ValueKey('pulse-card-PULSE-001')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pulse-card-PULSE-007')),
        240,
        scrollable: scrollable,
      );
      expect(
        find.byKey(const ValueKey('pulse-card-PULSE-007')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pulse-group-cashflow')),
        -240,
        scrollable: scrollable,
      );
      await tester.tap(find.byKey(const ValueKey('pulse-group-cashflow')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pulse-card-PULSE-008')),
        240,
        scrollable: scrollable,
      );
      expect(
        find.byKey(const ValueKey('pulse-card-PULSE-008')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pulse-card-PULSE-014')),
        240,
        scrollable: scrollable,
      );
      expect(
        find.byKey(const ValueKey('pulse-card-PULSE-014')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pulse-group-spending')),
        -240,
        scrollable: scrollable,
      );
      await tester.tap(find.byKey(const ValueKey('pulse-group-spending')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pulse-card-PULSE-003')),
        240,
        scrollable: scrollable,
      );
      await tester.tap(find.byKey(const ValueKey('pulse-card-PULSE-003')));
      await tester.pumpAndSettle();
      expect(find.text('Költési ütem'), findsWidgets);
      expect(find.text('Triggerpontok'), findsOneWidget);

      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(80, 0));
      await tester.pump();
      expect(find.text('Beállítások mentése'), findsOneWidget);
      await tester.tap(find.text('Beállítások mentése'));
      await tester.pumpAndSettle();
      expect(repository.saved, isNotEmpty);
      expect(repository.resetCalls, 0);

      await tester.scrollUntilVisible(
        find.text('Signal Inspector'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Signal Inspector'), findsOneWidget);
      expect(find.text('Megerősítésre vár'), findsOneWidget);
      await expectLater(
        find.byKey(const ValueKey('pulse-signal-detail-boundary')),
        matchesGoldenFile('../../../goldens/pulse_signal_inspector.png'),
      );
    },
  );
}

PulseDashboardSnapshot _snapshot({
  List<PulseSituationSnapshot> situations = const [],
}) => PulseDashboardSnapshot(
  year: 2026,
  month: 10,
  coreRevision: 42,
  generatedAtUtcMs: 1,
  situations: situations,
  indicators: List<PulseIndicatorSnapshot>.generate(21, (index) {
    final number = index + 1;
    final group = switch (index ~/ 7) {
      0 => PulseGroup.spending,
      1 => PulseGroup.cashflow,
      _ => PulseGroup.systems,
    };
    final chart = switch (index % 6) {
      0 => PulseChartKind.arcGauge,
      1 => PulseChartKind.thresholdBar,
      2 => PulseChartKind.trend,
      3 => PulseChartKind.forecast,
      4 => PulseChartKind.ratio,
      _ => PulseChartKind.timeline,
    };
    return PulseIndicatorSnapshot(
      id: 'PULSE-${number.toString().padLeft(3, '0')}',
      group: group,
      title: number == 3 ? 'Költési ütem' : 'Mutató $number',
      description: 'Valós Core snapshot tesztadat.',
      unit: PulseUnit.ratio,
      chartKind: chart,
      availability: PulseAvailability.available,
      value: 1.2,
      secondaryValue: null,
      summary: 'Adatalapú összefoglaló',
      missingReasons: const [],
      sampleCount: 12,
      series: const [
        PulseSeries(
          key: 'actual',
          label: 'Tény',
          points: [PulsePoint(x: 1, actual: 100, reference: 90)],
        ),
      ],
      thresholds: const [
        PulseThresholdValue(
          key: 'primary',
          value: 1.2,
          definition: PulseThresholdDefinition(
            key: 'primary',
            unit: PulseUnit.ratio,
            defaultValue: 1.2,
            minimum: 0,
            maximum: 3,
            step: .05,
          ),
          isUserDefined: false,
        ),
      ],
      sources: const ['Ledger'],
    );
  }),
);

final class _Repository implements PulseRepository {
  _Repository(this.snapshot);
  final PulseDashboardSnapshot snapshot;
  final List<double> saved = [];
  int resetCalls = 0;

  @override
  Future<PulseDashboardSnapshot> dashboard({
    required int year,
    required int month,
  }) async => snapshot;

  @override
  Future<List<PulseSignalInspection>> signalInspection({
    required int year,
    required int month,
    required String indicatorId,
    int historyLimit = 30,
  }) async => indicatorId == 'PULSE-003'
      ? [
          const PulseSignalInspection(
            signalKey: 'PULSE-003/global/2026-10/default',
            indicatorId: 'PULSE-003',
            targetKey: '',
            measuredValue: 1.67,
            metricKey: 'paceRatio',
            thresholdValue: 1.30,
            comparisonOperator: 'greaterThanOrEqual',
            activityState: PulseSignalActivityState.pendingConfirmation,
            strength: PulseSignalStrength.medium,
            dataQuality: PulseSignalDataQuality.sufficient,
            trendDirection: 'erősödő',
            observedDuration: 1,
            trace: {
              'thresholdConditionMet': true,
              'confirmationCount': 1,
              'confirmationRequired': 2,
              'missingInputsHu': <Object?>[],
            },
            evidence: {
              'situationKey': 'monthly-budget/2026-10',
              'evidenceFamily': 'spending-velocity',
              'affectedTarget': '',
            },
            events: [],
            lastPersistedState: null,
          ),
        ]
      : const [];

  @override
  Future<PulseSituationInspection> triageInspection({
    required int year,
    required int month,
    required String situationKey,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async {
    final situation = snapshot.situations.firstWhere(
      (item) => item.situationKey == situationKey,
    );
    return PulseSituationInspection(situation: situation, events: const []);
  }

  @override
  Future<void> setSubscriptionSource({
    required String targetKey,
    required bool selected,
  }) async {}

  @override
  Future<void> resetThreshold({
    required String indicatorId,
    required String thresholdKey,
    String targetKey = '',
  }) async {
    resetCalls++;
  }

  @override
  Future<void> setThreshold({
    required String indicatorId,
    required String thresholdKey,
    required double value,
    String targetKey = '',
  }) async {
    saved.add(value);
  }
}

PulseSituationSnapshot _situation() => const PulseSituationSnapshot(
  situationKey: 'monthly-budget/2026-10',
  domain: 'monthlyBudget',
  title: 'Havi kerethelyzet',
  targetKey: 'aggregate',
  periodKey: '2026-10',
  state: PulseSituationState.ready,
  formationRule: 'medium-pair',
  independentEvidenceCount: 2,
  relatedSignalKeys: ['PULSE-003/global/2026-10/default'],
  evidenceUnits: [],
  decisionTrace: PulseTriageTrace(
    matchedRule: 'medium-pair',
    relatedSignalCount: 2,
    independentEvidenceCount: 2,
    countedEvidenceKeys: [],
    supportingEvidenceKeys: [],
    missingRequirements: [],
    explanation: ['Két független bizonyíték teljesült.'],
    rules: [],
  ),
  lastMaterialChangeAtUtcMs: null,
  historicalInspection: false,
);
