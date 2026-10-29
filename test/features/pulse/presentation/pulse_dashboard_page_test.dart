import 'package:fluvi/features/pulse/domain/pulse_models.dart';
import 'package:fluvi/features/pulse/domain/pulse_repository.dart';
import 'package:fluvi/features/pulse/application/pulse_delivery_coordinator.dart';
import 'package:fluvi/features/pulse/presentation/pulse_dashboard_page.dart';
import 'package:fluvi/features/pulse/presentation/widgets/pulse_header_presentation_layer.dart';
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

  testWidgets('native Priority focus opens the Priority Inspector', (
    tester,
  ) async {
    final situation = _situation();
    final priority = _priority(situation.situationKey);
    final repository = _Repository(
      _snapshot(situations: [situation], priority: priority),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PulseDashboardPage(
          repository: repository,
          coreRevisions: const Stream<Object?>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final focus = find.byKey(const ValueKey('pulse-priority-focus'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(focus);
    await tester.pumpAndSettle();
    expect(find.text('Fontossági sorrend'), findsOneWidget);
    expect(find.text('Pontszám részletezése'), findsOneWidget);
  });

  testWidgets('native Story preview opens its Copy Map inspector', (
    tester,
  ) async {
    final situation = _situation();
    final repository = _Repository(
      _snapshot(
        situations: [situation],
        priority: _priority(situation.situationKey),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PulseDashboardPage(
          repository: repository,
          coreRevisions: const Stream<Object?>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pulse-priority-focus')));
    await tester.pumpAndSettle();

    expect(find.text('Üzenet előnézete'), findsOneWidget);
    expect(find.text('A hónap végére túllépheted a kereted.'), findsOneWidget);
    await tester.tap(find.text('Üzenet előnézete'));
    await tester.pumpAndSettle();
    expect(find.text('Story Inspector'), findsOneWidget);
    expect(find.text('Mondatrészek és források'), findsOneWidget);
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

  testWidgets(
    'header delivery copy passes through while its own actions stay interactive',
    (tester) async {
      final repository = _Repository(_snapshot())..deliveryEnabled = true;
      final coordinator = PulseDeliveryCoordinator(repository: repository);
      addTearDown(coordinator.dispose);
      var backgroundPointerDowns = 0;
      coordinator.updateSurface(
        appActive: true,
        ledgerVisible: true,
        headerVisible: true,
        unobstructed: true,
        interactionIdle: true,
        headerLayoutSupported: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 640,
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Listener(
                    key: const ValueKey('pulse-header-pass-through-target'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => backgroundPointerDowns += 1,
                    child: const SizedBox.expand(),
                  ),
                  PulseHeaderPresentationLayer(
                    coordinator: coordinator,
                    onLayoutSupported: coordinator.reportHeaderLayout,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('A hónap végére túllépheted a kereted.'),
        findsOneWidget,
      );
      expect(
        find.byType(SizedBox).evaluate().any((element) {
          final render = element.renderObject;
          return render is RenderBox && render.size == const Size(640, 180);
        }),
        isTrue,
      );
      expect(find.text('Részletek'), findsNothing);
      expect(
        find.byKey(const ValueKey('pulse-header-dismiss')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pulse-header-actions')),
        findsOneWidget,
      );
      expect(coordinator.presentation, isNotNull);

      await tester.tap(find.byTooltip('Elrejtés'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(repository.dismissCalls, 1);

      await coordinator.reconcile();
      await tester.pump();
      await tester.pump();
      await _selectHeaderAction(tester, 0);
      await tester.pump();
      expect(repository.snoozeCalls, 1);

      await coordinator.reconcile();
      await tester.pump();
      await tester.pump();
      await _selectHeaderAction(tester, 2);
      await tester.pump();
      expect(repository.muteCalls, 1);

      await coordinator.reconcile();
      await tester.pump();
      await tester.pump();
      await tester.tap(
        find.text('A hónap végére túllépheted a kereted.'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(backgroundPointerDowns, 1);
      expect(repository.confirmCalls, 0);
    },
  );
}

Future<void> _selectHeaderAction(WidgetTester tester, int index) async {
  final finder = find.byKey(const ValueKey('pulse-header-actions'));
  final dynamic menu = tester.widget(finder);
  final dynamic entry = menu.itemBuilder(tester.element(finder))[index];
  menu.onSelected!(entry.value);
  await tester.pump();
}

PulseDashboardSnapshot _snapshot({
  List<PulseSituationSnapshot> situations = const [],
  PulsePriorityFrame? priority,
}) => PulseDashboardSnapshot(
  year: 2026,
  month: 10,
  coreRevision: 42,
  generatedAtUtcMs: 1,
  situations: situations,
  priority: priority,
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
  int confirmCalls = 0;
  int dismissCalls = 0;
  int snoozeCalls = 0;
  int muteCalls = 0;
  bool deliveryEnabled = false;

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
  Future<PulsePriorityInspection> priorityInspection({
    required int year,
    required int month,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => PulsePriorityInspection(
    priority:
        snapshot.priority ??
        const PulsePriorityFrame(
          sourceCoreRevision: 42,
          sourceTriageFrameId: 'test',
          policyVersion: 1,
          evaluationMode: 'live',
          evaluatedAtUtcMs: 1,
          rankedCandidates: [],
          selectedSituationKey: null,
          selectionReason: null,
        ),
    situations: snapshot.situations,
    events: const [],
  );

  @override
  Future<PulseStoryInspection> selectedStoryPreview({
    required int year,
    required int month,
  }) async => _storyInspection();

  @override
  Future<PulseStoryInspection> candidateStoryPreview({
    required int year,
    required int month,
    required String situationKey,
  }) async => _storyInspection(situationKey: situationKey);

  @override
  Future<PulseStoryInspection> storyInspection({
    required int year,
    required int month,
    required String situationKey,
  }) async => _storyInspection(situationKey: situationKey);

  @override
  Future<PulseDeliveryDecision> deliveryDecision({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
  }) async => deliveryEnabled
      ? _deliveryDecision()
      : const PulseDeliveryDecision(
          sourceCoreRevision: 42,
          sourceTriageFrameId: 'frame',
          evaluationMode: 'live',
          prioritySelectedSituationKey: null,
          deliverySelectedSituationKey: null,
          deliverySelectionReason: 'no-priority-candidate',
          candidates: [],
        );

  @override
  Future<PulseDeliveryInspection> deliveryInspection({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => PulseDeliveryInspection(
    decision: await deliveryDecision(
      year: year,
      month: month,
      surface: surface,
    ),
    preferences: const PulseDeliveryPreferences(
      automaticEnabled: true,
      normalCooldownMillis: 600000,
      controlRevision: 0,
      updatedAtUtcMs: 0,
    ),
    controls: const [],
    activeAttempt: null,
    events: const [],
  );

  @override
  Future<PulseDeliveryPreferences> deliveryPreferences() async =>
      const PulseDeliveryPreferences(
        automaticEnabled: true,
        normalCooldownMillis: 600000,
        controlRevision: 0,
        updatedAtUtcMs: 0,
      );

  @override
  Future<PulseHeaderPresentationReservation?> reserveHeaderPresentation({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    required String commandKey,
  }) async => deliveryEnabled ? _reservation() : null;

  @override
  Future<bool> reportPresentationStarted({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async => true;

  @override
  Future<bool> reportPresented({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async => true;

  @override
  Future<bool> confirmQualifiedExposure({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async {
    confirmCalls += 1;
    return true;
  }

  @override
  Future<bool> finishPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    String reason = 'readable-duration-ended',
  }) async => true;

  @override
  Future<bool> cancelPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String reason,
  }) async => true;

  @override
  Future<bool> dismissStory({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String commandKey,
  }) async {
    dismissCalls += 1;
    return true;
  }

  @override
  Future<bool> snoozeSituation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required int untilUtcMs,
    required String commandKey,
  }) async {
    snoozeCalls += 1;
    return true;
  }

  @override
  Future<void> muteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  }) async {
    muteCalls += 1;
  }

  @override
  Future<bool> unmuteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  }) async => true;

  @override
  Future<bool> clearDeliveryControl({
    required String controlId,
    required String commandKey,
  }) async => true;

  @override
  Future<PulseDeliveryPreferences> updateDeliveryPreferences({
    required bool automaticEnabled,
    required int normalCooldownMillis,
    required String commandKey,
  }) async => PulseDeliveryPreferences(
    automaticEnabled: automaticEnabled,
    normalCooldownMillis: normalCooldownMillis,
    controlRevision: 1,
    updatedAtUtcMs: 1,
  );

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

PulseStoryInspection _storyInspection({
  String situationKey = 'monthly-budget/2026-10',
}) => PulseStoryInspection(
  priorityFrameId: 'frame',
  sourceCoreRevision: 42,
  facts: const [],
  result: PulseStoryCompositionResult(
    status: 'composed',
    reasonCode: null,
    explanation: null,
    draft: PulseStoryDraft(
      storyKey: 'story/$situationKey/risk',
      situationKey: situationKey,
      candidateKind: 'ready',
      claimType: 'projectedBreach',
      headline: 'A hónap végére túllépheted a kereted.',
      detail: 'Az előrejelzés 24 000 Ft-os kerettúllépést mutat.',
      fragments: [
        PulseStoryFragment(
          role: PulseStoryFragmentRole.headline,
          templateId: 'monthly-budget-projected-breach-v1',
          renderedText: 'A hónap végére túllépheted a kereted.',
          sourceSignalKeys: ['PULSE-004/global/2026-10/default'],
          sourceEvidenceKeys: ['forecast'],
          sourceFactKeys: ['forecast/overrun'],
          certainty: PulseStoryCertainty.projected,
        ),
      ],
      exclusions: [],
      priorityFrameId: 'frame',
      sourceCoreRevision: 42,
      templateVersion: 1,
      contentFingerprint: 'test',
      materialFingerprint: 'material',
      evaluationMode: 'live',
      generatedAtUtcMs: 1,
    ),
  ),
);

PulseDeliveryDecision _deliveryDecision() {
  final story = _storyInspection().result;
  return PulseDeliveryDecision(
    sourceCoreRevision: 42,
    sourceTriageFrameId: 'frame',
    evaluationMode: 'live',
    prioritySelectedSituationKey: 'monthly-budget/2026-10',
    deliverySelectedSituationKey: 'monthly-budget/2026-10',
    deliverySelectionReason: 'first-eligible-priority-candidate',
    candidates: [
      PulseDeliveryCandidate(
        situationKey: 'monthly-budget/2026-10',
        situationEpisodeId: 'episode',
        targetScope: 'monthlyBudget:aggregate',
        priorityRank: 1,
        priorityScore: 85,
        story: story,
        materialSemanticKey: 'material',
        contentFingerprint: 'content',
        deliveryKey: 'header|episode|story|material|automatic',
        presentationIntentId: 'automatic',
        eligibility: PulseDeliveryEligibility.eligible,
        reasonCode: 'eligible',
        explanation: 'Megjeleníthető.',
      ),
    ],
  );
}

PulseHeaderPresentationReservation _reservation() =>
    PulseHeaderPresentationReservation(
      attemptId: 'attempt',
      leaseToken: 'lease',
      hostSessionId: 'header-test',
      deliveryKey: 'header|episode|story|material|automatic',
      presentationIntentId: 'automatic',
      situationEpisodeId: 'episode',
      targetScope: 'monthlyBudget:aggregate',
      validUntilUtcMs: 9999999999999,
      readableDurationMillis: 8000,
      sourceFrameId: 'frame',
      controlRevision: 0,
      story: _storyInspection().result.draft!,
    );

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

PulsePriorityFrame _priority(String situationKey) => PulsePriorityFrame(
  sourceCoreRevision: 42,
  sourceTriageFrameId: 'frame',
  policyVersion: 1,
  evaluationMode: 'live',
  evaluatedAtUtcMs: 1,
  selectedSituationKey: situationKey,
  selectionReason: const PulsePrioritySelectionReason(
    reasonCode: 'higher-priority-score',
    explanation: 'A kiválasztott helyzet pontszáma magasabb.',
    tieBreakApplied: false,
    tieBreakExplanation: null,
  ),
  rankedCandidates: const [
    PulsePriorityCandidate(
      situationKey: 'monthly-budget/2026-10',
      kind: 'ready',
      leadingEvidenceKey: 'evidence',
      leadingSignalKey: 'PULSE-001/global/2026-10/default',
      leadingIndicatorId: 'PULSE-001',
      basePriority: 65,
      modifiers: [
        PulsePriorityModifier(
          id: 'material-impact',
          value: 15,
          applied: true,
          reasonCode: 'material-impact-material',
          explanation: 'Valós hatás.',
          observedImpactMinor: 1500000,
        ),
        PulsePriorityModifier(
          id: 'due-soon',
          value: 0,
          applied: false,
          reasonCode: 'due-soon-not-applicable',
          explanation: 'Nincs konkrét esedékesség.',
          observedImpactMinor: null,
        ),
        PulsePriorityModifier(
          id: 'independent-evidence',
          value: 10,
          applied: true,
          reasonCode: 'independent-evidence-confirmed',
          explanation: 'Független bizonyíték.',
          observedImpactMinor: null,
        ),
      ],
      rawTotal: 90,
      finalScore: 90,
      rank: 1,
      tieBreakFacts: PulsePriorityTieBreakFacts(
        dueLocalEpochDay: null,
        dueDistanceDays: null,
        severityRank: 2,
        comparableImpactMinor: 1500000,
        lastMaterialChangeAtUtcMs: 1,
      ),
    ),
  ],
);
