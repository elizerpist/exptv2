import 'package:flutter/foundation.dart';

enum PulseGroup { spending, cashflow, systems }

enum PulseUnit { percent, currency, ratio, days, count }

enum PulseChartKind { arcGauge, thresholdBar, trend, forecast, ratio, timeline }

enum PulseAvailability {
  available,
  earlyEstimate,
  waitingForData,
  notApplicable,
  calculationError,
}

enum PulseSignalActivityState {
  normal,
  pendingConfirmation,
  active,
  recovering,
  resolved,
  evaluationSuspended,
}

enum PulseSignalStrength { weak, medium, strong, critical }

enum PulseSignalDataQuality { sufficient, limited, insufficient, notApplicable }

enum PulseSituationState { forming, ready, improving, resolved, suspended }

enum PulseEvidenceRole {
  leading,
  independentSupport,
  derivedSupport,
  overlappingSupport,
  contextOnly,
  excluded,
}

enum PulseEvidenceIndependence { independent, derived, overlapping, unresolved }

enum PulseStoryCertainty {
  observed,
  scheduled,
  projected,
  estimated,
  unavailable,
}

enum PulseStoryFragmentRole {
  headline,
  evidence,
  timeCause,
  qualification,
  recovery,
}

@immutable
final class PulseSignalSummary {
  const PulseSignalSummary({
    required this.activityState,
    required this.strength,
    required this.dataQuality,
    required this.activeSignalCount,
    required this.totalSignalCount,
  });

  factory PulseSignalSummary.fromMap(Map<Object?, Object?> map) =>
      PulseSignalSummary(
        activityState: PulseSignalActivityState.values.byName(
          map['activityState']! as String,
        ),
        strength: (map['strength'] as String?) == null
            ? null
            : PulseSignalStrength.values.byName(map['strength']! as String),
        dataQuality: PulseSignalDataQuality.values.byName(
          map['dataQuality']! as String,
        ),
        activeSignalCount: (map['activeSignalCount'] as num?)?.toInt() ?? 0,
        totalSignalCount: (map['totalSignalCount'] as num?)?.toInt() ?? 0,
      );

  final PulseSignalActivityState activityState;
  final PulseSignalStrength? strength;
  final PulseSignalDataQuality dataQuality;
  final int activeSignalCount;
  final int totalSignalCount;
}

@immutable
final class PulseThresholdDefinition {
  const PulseThresholdDefinition({
    required this.key,
    required this.unit,
    required this.defaultValue,
    required this.minimum,
    required this.maximum,
    required this.step,
  });

  factory PulseThresholdDefinition.fromMap(Map<Object?, Object?> map) =>
      PulseThresholdDefinition(
        key: map['key']! as String,
        unit: PulseUnit.values.byName(map['unit']! as String),
        defaultValue: (map['defaultValue'] as num).toDouble(),
        minimum: (map['minimum'] as num).toDouble(),
        maximum: (map['maximum'] as num).toDouble(),
        step: (map['step'] as num).toDouble(),
      );

  final String key;
  final PulseUnit unit;
  final double defaultValue;
  final double minimum;
  final double maximum;
  final double step;
}

@immutable
final class PulseThresholdValue {
  const PulseThresholdValue({
    required this.key,
    required this.value,
    required this.definition,
    required this.isUserDefined,
  });

  factory PulseThresholdValue.fromMap(Map<Object?, Object?> map) =>
      PulseThresholdValue(
        key: map['key']! as String,
        value: (map['value'] as num).toDouble(),
        definition: PulseThresholdDefinition.fromMap(_map(map['definition'])),
        isUserDefined: map['isUserDefined'] as bool? ?? false,
      );

  final String key;
  final double value;
  final PulseThresholdDefinition definition;
  final bool isUserDefined;
}

@immutable
final class PulsePoint {
  const PulsePoint({
    required this.x,
    this.label,
    this.targetKey,
    this.actual,
    this.baseline,
    this.momentum,
    this.reference,
  });

  factory PulsePoint.fromMap(Map<Object?, Object?> map) => PulsePoint(
    x: (map['x'] as num).toInt(),
    label: map['label'] as String?,
    targetKey: map['targetKey'] as String?,
    actual: (map['actual'] as num?)?.toInt(),
    baseline: (map['baseline'] as num?)?.toInt(),
    momentum: (map['momentum'] as num?)?.toInt(),
    reference: (map['reference'] as num?)?.toInt(),
  );

  final int x;
  final String? label;
  final String? targetKey;
  final int? actual;
  final int? baseline;
  final int? momentum;
  final int? reference;
}

@immutable
final class PulseSeries {
  const PulseSeries({
    required this.key,
    required this.label,
    required this.points,
  });

  factory PulseSeries.fromMap(Map<Object?, Object?> map) => PulseSeries(
    key: map['key']! as String,
    label: map['labelHu']! as String,
    points: _list(
      map['points'],
    ).map(PulsePoint.fromMap).toList(growable: false),
  );

  final String key;
  final String label;
  final List<PulsePoint> points;
}

@immutable
final class PulseIndicatorSnapshot {
  const PulseIndicatorSnapshot({
    required this.id,
    required this.group,
    required this.title,
    required this.description,
    required this.unit,
    required this.chartKind,
    required this.availability,
    required this.value,
    required this.secondaryValue,
    required this.summary,
    required this.missingReasons,
    required this.sampleCount,
    required this.series,
    required this.thresholds,
    required this.sources,
    this.signalMetricKey = 'primary',
    this.signalMetricValue,
    this.signalSummaries = const [],
  });

  factory PulseIndicatorSnapshot.fromMap(Map<Object?, Object?> map) =>
      PulseIndicatorSnapshot(
        id: map['id']! as String,
        group: PulseGroup.values.byName(map['group']! as String),
        title: map['titleHu']! as String,
        description: map['descriptionHu']! as String,
        unit: PulseUnit.values.byName(map['unit']! as String),
        chartKind: PulseChartKind.values.byName(map['chartKind']! as String),
        availability: PulseAvailability.values.byName(
          map['availability']! as String,
        ),
        value: (map['value'] as num?)?.toDouble(),
        secondaryValue: (map['secondaryValue'] as num?)?.toDouble(),
        summary: map['summaryHu']! as String,
        missingReasons: (map['missingReasonsHu'] as List<Object?>? ?? const [])
            .cast<String>(),
        sampleCount: (map['sampleCount'] as num?)?.toInt() ?? 0,
        series: _list(
          map['series'],
        ).map(PulseSeries.fromMap).toList(growable: false),
        thresholds: _list(
          map['thresholds'],
        ).map(PulseThresholdValue.fromMap).toList(growable: false),
        sources: (map['sources'] as List<Object?>? ?? const []).cast<String>(),
        signalMetricKey: map['signalMetricKey'] as String? ?? 'primary',
        signalMetricValue: (map['signalMetricValue'] as num?)?.toDouble(),
        signalSummaries: _list(
          map['signalSummaries'],
        ).map(PulseSignalSummary.fromMap).toList(growable: false),
      );

  final String id;
  final PulseGroup group;
  final String title;
  final String description;
  final PulseUnit unit;
  final PulseChartKind chartKind;
  final PulseAvailability availability;
  final double? value;
  final double? secondaryValue;
  final String summary;
  final List<String> missingReasons;
  final int sampleCount;
  final List<PulseSeries> series;
  final List<PulseThresholdValue> thresholds;
  final List<String> sources;
  final String signalMetricKey;
  final double? signalMetricValue;
  final List<PulseSignalSummary> signalSummaries;

  PulseIndicatorSnapshot withThreshold(double value) {
    if (thresholds.isEmpty) return this;
    final first = thresholds.first;
    return PulseIndicatorSnapshot(
      id: id,
      group: group,
      title: title,
      description: description,
      unit: unit,
      chartKind: chartKind,
      availability: availability,
      value: this.value,
      secondaryValue: secondaryValue,
      summary: summary,
      missingReasons: missingReasons,
      sampleCount: sampleCount,
      series: series,
      thresholds: [
        PulseThresholdValue(
          key: first.key,
          value: value,
          definition: first.definition,
          isUserDefined: true,
        ),
        ...thresholds.skip(1),
      ],
      sources: sources,
      signalMetricKey: signalMetricKey,
      signalMetricValue: signalMetricValue,
      signalSummaries: signalSummaries,
    );
  }
}

@immutable
final class PulseSignalEvent {
  const PulseSignalEvent({
    required this.eventId,
    required this.kind,
    required this.previousState,
    required this.nextState,
    required this.previousStrength,
    required this.nextStrength,
    required this.measuredValue,
    required this.thresholdValue,
    required this.timestampUtcMs,
    required this.cause,
  });

  factory PulseSignalEvent.fromMap(Map<Object?, Object?> map) =>
      PulseSignalEvent(
        eventId: map['eventId']! as String,
        kind: map['kind']! as String,
        previousState: map['previousState'] as String?,
        nextState: map['nextState']! as String,
        previousStrength: map['previousStrength'] as String?,
        nextStrength: map['nextStrength'] as String?,
        measuredValue: (map['measuredValue'] as num?)?.toDouble(),
        thresholdValue: (map['thresholdValue'] as num?)?.toDouble(),
        timestampUtcMs: (map['timestampUtcMs'] as num).toInt(),
        cause: map['cause']! as String,
      );
  final String eventId;
  final String kind;
  final String? previousState;
  final String nextState;
  final String? previousStrength;
  final String? nextStrength;
  final double? measuredValue;
  final double? thresholdValue;
  final int timestampUtcMs;
  final String cause;
}

@immutable
final class PulseSignalInspection {
  const PulseSignalInspection({
    required this.signalKey,
    required this.indicatorId,
    required this.targetKey,
    required this.measuredValue,
    required this.metricKey,
    required this.thresholdValue,
    required this.comparisonOperator,
    required this.activityState,
    required this.strength,
    required this.dataQuality,
    required this.trendDirection,
    required this.observedDuration,
    required this.trace,
    required this.evidence,
    required this.events,
    required this.lastPersistedState,
  });

  factory PulseSignalInspection.fromMap(Map<Object?, Object?> map) =>
      PulseSignalInspection(
        signalKey: map['signalKey']! as String,
        indicatorId: map['indicatorId']! as String,
        targetKey: map['targetKey'] as String? ?? '',
        measuredValue: (map['measuredValue'] as num?)?.toDouble(),
        metricKey: map['evaluatedMetricKey']! as String,
        thresholdValue: (map['thresholdValue'] as num?)?.toDouble(),
        comparisonOperator: map['comparisonOperator']! as String,
        activityState: PulseSignalActivityState.values.byName(
          map['activityState']! as String,
        ),
        strength: (map['strength'] as String?) == null
            ? null
            : PulseSignalStrength.values.byName(map['strength']! as String),
        dataQuality: PulseSignalDataQuality.values.byName(
          map['dataQuality']! as String,
        ),
        trendDirection: map['trendDirection']! as String,
        observedDuration: (map['observedDuration'] as num?)?.toInt() ?? 0,
        trace: _map(map['trace']),
        evidence: _map(map['evidence']),
        events: _list(
          map['events'],
        ).map(PulseSignalEvent.fromMap).toList(growable: false),
        lastPersistedState: map['lastPersistedState'] == null
            ? null
            : _map(map['lastPersistedState']),
      );
  final String signalKey;
  final String indicatorId;
  final String targetKey;
  final double? measuredValue;
  final String metricKey;
  final double? thresholdValue;
  final String comparisonOperator;
  final PulseSignalActivityState activityState;
  final PulseSignalStrength? strength;
  final PulseSignalDataQuality dataQuality;
  final String trendDirection;
  final int observedDuration;
  final Map<Object?, Object?> trace;
  final Map<Object?, Object?> evidence;
  final List<PulseSignalEvent> events;
  final Map<Object?, Object?>? lastPersistedState;
}

@immutable
final class PulseSourceOption {
  const PulseSourceOption({
    required this.targetKey,
    required this.label,
    required this.kind,
    required this.isSelected,
  });

  factory PulseSourceOption.fromMap(Map<Object?, Object?> map) =>
      PulseSourceOption(
        targetKey: map['targetKey']! as String,
        label: map['labelHu']! as String,
        kind: map['kind']! as String,
        isSelected: map['isSelected'] as bool? ?? false,
      );

  final String targetKey;
  final String label;
  final String kind;
  final bool isSelected;
}

@immutable
final class PulseDashboardSnapshot {
  const PulseDashboardSnapshot({
    required this.year,
    required this.month,
    required this.coreRevision,
    required this.generatedAtUtcMs,
    required this.indicators,
    this.subscriptionOptions = const [],
    this.situations = const [],
    this.signalGeneration = 0,
    this.triageHistorical = false,
    this.priority,
  });

  factory PulseDashboardSnapshot.fromMap(Map<Object?, Object?> map) =>
      PulseDashboardSnapshot(
        year: (map['year'] as num).toInt(),
        month: (map['month'] as num).toInt(),
        coreRevision: (map['coreRevision'] as num).toInt(),
        generatedAtUtcMs: (map['generatedAtUtcMs'] as num).toInt(),
        indicators: _list(
          map['indicators'],
        ).map(PulseIndicatorSnapshot.fromMap).toList(growable: false),
        subscriptionOptions: _list(
          map['subscriptionOptions'],
        ).map(PulseSourceOption.fromMap).toList(growable: false),
        situations: _list(
          map['situations'],
        ).map(PulseSituationSnapshot.fromMap).toList(growable: false),
        signalGeneration: (map['signalGeneration'] as num?)?.toInt() ?? 0,
        triageHistorical: map['triageHistorical'] as bool? ?? false,
        priority: map['priority'] == null
            ? null
            : PulsePriorityFrame.fromMap(_map(map['priority'])),
      );

  final int year;
  final int month;
  final int coreRevision;
  final int generatedAtUtcMs;
  final List<PulseIndicatorSnapshot> indicators;
  final List<PulseSourceOption> subscriptionOptions;
  final List<PulseSituationSnapshot> situations;
  final int signalGeneration;
  final bool triageHistorical;
  final PulsePriorityFrame? priority;

  PulseIndicatorSnapshot? byId(String id) =>
      indicators.where((indicator) => indicator.id == id).firstOrNull;

  List<PulseIndicatorSnapshot> inGroup(PulseGroup group) => indicators
      .where((indicator) => indicator.group == group)
      .toList(growable: false);
}

@immutable
final class PulseEvidenceUnit {
  const PulseEvidenceUnit({
    required this.evidenceKey,
    required this.sourceSignalKeys,
    required this.sourceFactKeys,
    required this.evidenceFamily,
    required this.strength,
    required this.role,
    required this.independence,
    required this.countableForFormation,
    required this.standaloneEligible,
    required this.reasonCodes,
    required this.indicatorId,
    required this.title,
    required this.measuredValue,
    required this.dataQuality,
    required this.actualImpactMinor,
    required this.projectedImpactMinor,
    required this.affectedBudgetMinor,
    required this.affectedObligationMinor,
    required this.impactRatio,
    required this.dueLocalEpochDay,
  });

  factory PulseEvidenceUnit.fromMap(
    Map<Object?, Object?> map,
  ) => PulseEvidenceUnit(
    evidenceKey: map['evidenceKey']! as String,
    sourceSignalKeys: (map['sourceSignalKeys'] as List<Object?>? ?? const [])
        .cast<String>(),
    sourceFactKeys: (map['sourceFactKeys'] as List<Object?>? ?? const [])
        .cast<String>(),
    evidenceFamily: map['evidenceFamily']! as String,
    strength: (map['strength'] as String?) == null
        ? null
        : PulseSignalStrength.values.byName(map['strength']! as String),
    role: PulseEvidenceRole.values.byName(map['role']! as String),
    independence: PulseEvidenceIndependence.values.byName(
      map['independence']! as String,
    ),
    countableForFormation: map['countableForFormation'] as bool? ?? false,
    standaloneEligible: map['standaloneEligible'] as bool? ?? false,
    reasonCodes: (map['reasonCodes'] as List<Object?>? ?? const [])
        .cast<String>(),
    indicatorId: map['indicatorId']! as String,
    title: map['titleHu']! as String,
    measuredValue: (map['measuredValue'] as num?)?.toDouble(),
    dataQuality: PulseSignalDataQuality.values.byName(
      map['dataQuality']! as String,
    ),
    actualImpactMinor: (map['actualImpactMinor'] as num?)?.toInt(),
    projectedImpactMinor: (map['projectedImpactMinor'] as num?)?.toInt(),
    affectedBudgetMinor: (map['affectedBudgetMinor'] as num?)?.toInt(),
    affectedObligationMinor: (map['affectedObligationMinor'] as num?)?.toInt(),
    impactRatio: (map['impactRatio'] as num?)?.toDouble(),
    dueLocalEpochDay: (map['dueLocalEpochDay'] as num?)?.toInt(),
  );

  final String evidenceKey;
  final List<String> sourceSignalKeys;
  final List<String> sourceFactKeys;
  final String evidenceFamily;
  final PulseSignalStrength? strength;
  final PulseEvidenceRole role;
  final PulseEvidenceIndependence independence;
  final bool countableForFormation;
  final bool standaloneEligible;
  final List<String> reasonCodes;
  final String indicatorId;
  final String title;
  final double? measuredValue;
  final PulseSignalDataQuality dataQuality;
  final int? actualImpactMinor;
  final int? projectedImpactMinor;
  final int? affectedBudgetMinor;
  final int? affectedObligationMinor;
  final double? impactRatio;
  final int? dueLocalEpochDay;
}

@immutable
final class PulseTriageRuleResult {
  const PulseTriageRuleResult({
    required this.ruleId,
    required this.applicable,
    required this.passed,
    required this.requiredEvidenceCount,
    required this.actualEvidenceCount,
    required this.requiredStrength,
    required this.dataQualityPassed,
    required this.materialImpactPassed,
    required this.reasonCodes,
  });

  factory PulseTriageRuleResult.fromMap(
    Map<Object?, Object?> map,
  ) => PulseTriageRuleResult(
    ruleId: map['ruleId']! as String,
    applicable: map['applicable'] as bool? ?? false,
    passed: map['passed'] as bool? ?? false,
    requiredEvidenceCount: (map['requiredEvidenceCount'] as num?)?.toInt() ?? 0,
    actualEvidenceCount: (map['actualEvidenceCount'] as num?)?.toInt() ?? 0,
    requiredStrength: (map['requiredStrength'] as String?) == null
        ? null
        : PulseSignalStrength.values.byName(map['requiredStrength']! as String),
    dataQualityPassed: map['dataQualityPassed'] as bool? ?? false,
    materialImpactPassed: map['materialImpactPassed'] as bool?,
    reasonCodes: (map['reasonCodes'] as List<Object?>? ?? const [])
        .cast<String>(),
  );

  final String ruleId;
  final bool applicable;
  final bool passed;
  final int requiredEvidenceCount;
  final int actualEvidenceCount;
  final PulseSignalStrength? requiredStrength;
  final bool dataQualityPassed;
  final bool? materialImpactPassed;
  final List<String> reasonCodes;
}

@immutable
final class PulseTriageTrace {
  const PulseTriageTrace({
    required this.matchedRule,
    required this.relatedSignalCount,
    required this.independentEvidenceCount,
    required this.countedEvidenceKeys,
    required this.supportingEvidenceKeys,
    required this.missingRequirements,
    required this.explanation,
    required this.rules,
  });

  factory PulseTriageTrace.fromMap(Map<Object?, Object?> map) =>
      PulseTriageTrace(
        matchedRule: map['matchedRule'] as String?,
        relatedSignalCount: (map['relatedSignalCount'] as num?)?.toInt() ?? 0,
        independentEvidenceCount:
            (map['independentEvidenceCount'] as num?)?.toInt() ?? 0,
        countedEvidenceKeys:
            (map['countedEvidenceKeys'] as List<Object?>? ?? const [])
                .cast<String>(),
        supportingEvidenceKeys:
            (map['supportingEvidenceKeys'] as List<Object?>? ?? const [])
                .cast<String>(),
        missingRequirements:
            (map['missingRequirements'] as List<Object?>? ?? const [])
                .cast<String>(),
        explanation: (map['explanationHu'] as List<Object?>? ?? const [])
            .cast<String>(),
        rules: _list(
          map['evaluatedRules'],
        ).map(PulseTriageRuleResult.fromMap).toList(growable: false),
      );

  final String? matchedRule;
  final int relatedSignalCount;
  final int independentEvidenceCount;
  final List<String> countedEvidenceKeys;
  final List<String> supportingEvidenceKeys;
  final List<String> missingRequirements;
  final List<String> explanation;
  final List<PulseTriageRuleResult> rules;
}

@immutable
final class PulseSituationSnapshot {
  const PulseSituationSnapshot({
    required this.situationKey,
    required this.domain,
    required this.title,
    required this.targetKey,
    required this.periodKey,
    required this.state,
    required this.formationRule,
    required this.independentEvidenceCount,
    required this.relatedSignalKeys,
    required this.evidenceUnits,
    required this.decisionTrace,
    required this.lastMaterialChangeAtUtcMs,
    required this.historicalInspection,
  });

  factory PulseSituationSnapshot.fromMap(Map<Object?, Object?> map) =>
      PulseSituationSnapshot(
        situationKey: map['situationKey']! as String,
        domain: map['domain']! as String,
        title: map['titleHu']! as String,
        targetKey: map['targetKey']! as String,
        periodKey: map['periodKey']! as String,
        state: PulseSituationState.values.byName(map['state']! as String),
        formationRule: map['formationRule'] as String?,
        independentEvidenceCount:
            (map['independentEvidenceCount'] as num?)?.toInt() ?? 0,
        relatedSignalKeys:
            (map['relatedSignalKeys'] as List<Object?>? ?? const [])
                .cast<String>(),
        evidenceUnits: _list(
          map['evidenceUnits'],
        ).map(PulseEvidenceUnit.fromMap).toList(growable: false),
        decisionTrace: PulseTriageTrace.fromMap(_map(map['decisionTrace'])),
        lastMaterialChangeAtUtcMs: (map['lastMaterialChangeAtUtcMs'] as num?)
            ?.toInt(),
        historicalInspection: map['historicalInspection'] as bool? ?? false,
      );

  final String situationKey;
  final String domain;
  final String title;
  final String targetKey;
  final String periodKey;
  final PulseSituationState state;
  final String? formationRule;
  final int independentEvidenceCount;
  final List<String> relatedSignalKeys;
  final List<PulseEvidenceUnit> evidenceUnits;
  final PulseTriageTrace decisionTrace;
  final int? lastMaterialChangeAtUtcMs;
  final bool historicalInspection;
}

@immutable
final class PulseSituationEvent {
  const PulseSituationEvent({
    required this.eventId,
    required this.kind,
    required this.previousState,
    required this.nextState,
    required this.previousEvidenceCount,
    required this.nextEvidenceCount,
    required this.explanation,
    required this.createdAtUtcMs,
  });

  factory PulseSituationEvent.fromMap(
    Map<Object?, Object?> map,
  ) => PulseSituationEvent(
    eventId: map['eventId']! as String,
    kind: map['kind']! as String,
    previousState: (map['previousState'] as String?) == null
        ? null
        : PulseSituationState.values.byName(map['previousState']! as String),
    nextState: PulseSituationState.values.byName(map['nextState']! as String),
    previousEvidenceCount: (map['previousEvidenceCount'] as num?)?.toInt() ?? 0,
    nextEvidenceCount: (map['nextEvidenceCount'] as num?)?.toInt() ?? 0,
    explanation: (map['explanationHu'] as List<Object?>? ?? const [])
        .cast<String>(),
    createdAtUtcMs: (map['createdAtUtcMs'] as num).toInt(),
  );

  final String eventId;
  final String kind;
  final PulseSituationState? previousState;
  final PulseSituationState nextState;
  final int previousEvidenceCount;
  final int nextEvidenceCount;
  final List<String> explanation;
  final int createdAtUtcMs;
}

@immutable
final class PulseSituationInspection {
  const PulseSituationInspection({
    required this.situation,
    required this.events,
  });
  factory PulseSituationInspection.fromMap(Map<Object?, Object?> map) =>
      PulseSituationInspection(
        situation: PulseSituationSnapshot.fromMap(_map(map['situation'])),
        events: _list(
          map['events'],
        ).map(PulseSituationEvent.fromMap).toList(growable: false),
      );
  final PulseSituationSnapshot situation;
  final List<PulseSituationEvent> events;
}

@immutable
final class PulsePriorityModifier {
  const PulsePriorityModifier({
    required this.id,
    required this.value,
    required this.applied,
    required this.reasonCode,
    required this.explanation,
    required this.observedImpactMinor,
  });

  factory PulsePriorityModifier.fromMap(Map<Object?, Object?> map) =>
      PulsePriorityModifier(
        id: map['id']! as String,
        value: (map['value'] as num?)?.toInt() ?? 0,
        applied: map['applied'] as bool? ?? false,
        reasonCode: map['reasonCode']! as String,
        explanation: map['explanationHu']! as String,
        observedImpactMinor: (map['observedImpactMinor'] as num?)?.toInt(),
      );

  final String id;
  final int value;
  final bool applied;
  final String reasonCode;
  final String explanation;
  final int? observedImpactMinor;
}

@immutable
final class PulsePriorityTieBreakFacts {
  const PulsePriorityTieBreakFacts({
    required this.dueLocalEpochDay,
    required this.dueDistanceDays,
    required this.severityRank,
    required this.comparableImpactMinor,
    required this.lastMaterialChangeAtUtcMs,
  });

  factory PulsePriorityTieBreakFacts.fromMap(Map<Object?, Object?> map) =>
      PulsePriorityTieBreakFacts(
        dueLocalEpochDay: (map['dueLocalEpochDay'] as num?)?.toInt(),
        dueDistanceDays: (map['dueDistanceDays'] as num?)?.toInt(),
        severityRank: (map['severityRank'] as num?)?.toInt() ?? 0,
        comparableImpactMinor: (map['comparableImpactMinor'] as num?)?.toInt(),
        lastMaterialChangeAtUtcMs: (map['lastMaterialChangeAtUtcMs'] as num?)
            ?.toInt(),
      );

  final int? dueLocalEpochDay;
  final int? dueDistanceDays;
  final int severityRank;
  final int? comparableImpactMinor;
  final int? lastMaterialChangeAtUtcMs;
}

@immutable
final class PulsePriorityCandidate {
  const PulsePriorityCandidate({
    required this.situationKey,
    required this.kind,
    required this.leadingEvidenceKey,
    required this.leadingSignalKey,
    required this.leadingIndicatorId,
    required this.basePriority,
    required this.modifiers,
    required this.rawTotal,
    required this.finalScore,
    required this.rank,
    required this.tieBreakFacts,
  });

  factory PulsePriorityCandidate.fromMap(Map<Object?, Object?> map) =>
      PulsePriorityCandidate(
        situationKey: map['situationKey']! as String,
        kind: map['kind']! as String,
        leadingEvidenceKey: map['leadingEvidenceKey']! as String,
        leadingSignalKey: map['leadingSignalKey']! as String,
        leadingIndicatorId: map['leadingIndicatorId']! as String,
        basePriority: (map['basePriority'] as num).toInt(),
        modifiers: _list(
          map['modifiers'],
        ).map(PulsePriorityModifier.fromMap).toList(growable: false),
        rawTotal: (map['rawTotal'] as num).toInt(),
        finalScore: (map['finalScore'] as num).toInt(),
        rank: (map['rank'] as num).toInt(),
        tieBreakFacts: PulsePriorityTieBreakFacts.fromMap(
          _map(map['tieBreakFacts']),
        ),
      );

  final String situationKey;
  final String kind;
  final String leadingEvidenceKey;
  final String leadingSignalKey;
  final String leadingIndicatorId;
  final int basePriority;
  final List<PulsePriorityModifier> modifiers;
  final int rawTotal;
  final int finalScore;
  final int rank;
  final PulsePriorityTieBreakFacts tieBreakFacts;
}

@immutable
final class PulsePrioritySelectionReason {
  const PulsePrioritySelectionReason({
    required this.reasonCode,
    required this.explanation,
    required this.tieBreakApplied,
    required this.tieBreakExplanation,
  });

  factory PulsePrioritySelectionReason.fromMap(Map<Object?, Object?> map) =>
      PulsePrioritySelectionReason(
        reasonCode: map['reasonCode']! as String,
        explanation: map['explanationHu']! as String,
        tieBreakApplied: map['tieBreakApplied'] as bool? ?? false,
        tieBreakExplanation: map['tieBreakExplanationHu'] as String?,
      );

  final String reasonCode;
  final String explanation;
  final bool tieBreakApplied;
  final String? tieBreakExplanation;
}

@immutable
final class PulsePriorityFrame {
  const PulsePriorityFrame({
    required this.sourceCoreRevision,
    required this.sourceTriageFrameId,
    required this.policyVersion,
    required this.evaluationMode,
    required this.evaluatedAtUtcMs,
    required this.rankedCandidates,
    required this.selectedSituationKey,
    required this.selectionReason,
  });

  factory PulsePriorityFrame.fromMap(Map<Object?, Object?> map) =>
      PulsePriorityFrame(
        sourceCoreRevision: (map['sourceCoreRevision'] as num).toInt(),
        sourceTriageFrameId: map['sourceTriageFrameId']! as String,
        policyVersion: (map['policyVersion'] as num).toInt(),
        evaluationMode: map['evaluationMode']! as String,
        evaluatedAtUtcMs: (map['evaluatedAtUtcMs'] as num).toInt(),
        rankedCandidates: _list(
          map['rankedCandidates'],
        ).map(PulsePriorityCandidate.fromMap).toList(growable: false),
        selectedSituationKey: map['selectedSituationKey'] as String?,
        selectionReason: map['selectionReason'] == null
            ? null
            : PulsePrioritySelectionReason.fromMap(
                _map(map['selectionReason']),
              ),
      );

  final int sourceCoreRevision;
  final String sourceTriageFrameId;
  final int policyVersion;
  final String evaluationMode;
  final int evaluatedAtUtcMs;
  final List<PulsePriorityCandidate> rankedCandidates;
  final String? selectedSituationKey;
  final PulsePrioritySelectionReason? selectionReason;

  PulsePriorityCandidate? get selected => selectedSituationKey == null
      ? null
      : () {
          for (final candidate in rankedCandidates) {
            if (candidate.situationKey == selectedSituationKey) {
              return candidate;
            }
          }
          return null;
        }();
}

@immutable
final class PulsePriorityEvent {
  const PulsePriorityEvent({
    required this.eventId,
    required this.kind,
    required this.previousSelectedSituationKey,
    required this.nextSelectedSituationKey,
    required this.previousScore,
    required this.nextScore,
    required this.selectionReason,
    required this.createdAtUtcMs,
  });

  factory PulsePriorityEvent.fromMap(Map<Object?, Object?> map) =>
      PulsePriorityEvent(
        eventId: map['eventId']! as String,
        kind: map['kind']! as String,
        previousSelectedSituationKey:
            map['previousSelectedSituationKey'] as String?,
        nextSelectedSituationKey: map['nextSelectedSituationKey'] as String?,
        previousScore: (map['previousScore'] as num?)?.toInt(),
        nextScore: (map['nextScore'] as num?)?.toInt(),
        selectionReason: map['selectionReason']! as String,
        createdAtUtcMs: (map['createdAtUtcMs'] as num).toInt(),
      );

  final String eventId;
  final String kind;
  final String? previousSelectedSituationKey;
  final String? nextSelectedSituationKey;
  final int? previousScore;
  final int? nextScore;
  final String selectionReason;
  final int createdAtUtcMs;
}

@immutable
final class PulsePriorityInspection {
  const PulsePriorityInspection({
    required this.priority,
    required this.situations,
    required this.events,
  });

  factory PulsePriorityInspection.fromMap(Map<Object?, Object?> map) =>
      PulsePriorityInspection(
        priority: PulsePriorityFrame.fromMap(_map(map['priority'])),
        situations: _list(
          map['situations'],
        ).map(PulseSituationSnapshot.fromMap).toList(growable: false),
        events: _list(
          map['events'],
        ).map(PulsePriorityEvent.fromMap).toList(growable: false),
      );

  final PulsePriorityFrame priority;
  final List<PulseSituationSnapshot> situations;
  final List<PulsePriorityEvent> events;
}

@immutable
final class PulseStoryFact {
  const PulseStoryFact({
    required this.factKey,
    required this.kind,
    required this.sourceSignalKeys,
    required this.sourceEvidenceKeys,
    required this.sourceFactKeys,
    required this.certainty,
    required this.amountMinor,
    required this.decimalValue,
    required this.countValue,
    required this.dueLocalEpochDay,
    required this.periodKey,
    required this.sourceCoreRevision,
    required this.includedInForecast,
  });

  factory PulseStoryFact.fromMap(Map<Object?, Object?> map) => PulseStoryFact(
    factKey: map['factKey']! as String,
    kind: map['kind']! as String,
    sourceSignalKeys: (map['sourceSignalKeys'] as List<Object?>? ?? const [])
        .cast<String>(),
    sourceEvidenceKeys:
        (map['sourceEvidenceKeys'] as List<Object?>? ?? const [])
            .cast<String>(),
    sourceFactKeys: (map['sourceFactKeys'] as List<Object?>? ?? const [])
        .cast<String>(),
    certainty: PulseStoryCertainty.values.byName(map['certainty']! as String),
    amountMinor: (map['amountMinor'] as num?)?.toInt(),
    decimalValue: (map['decimalValue'] as num?)?.toDouble(),
    countValue: (map['countValue'] as num?)?.toInt(),
    dueLocalEpochDay: (map['dueLocalEpochDay'] as num?)?.toInt(),
    periodKey: map['periodKey'] as String?,
    sourceCoreRevision: (map['sourceCoreRevision'] as num?)?.toInt() ?? 0,
    includedInForecast: map['includedInForecast'] as bool? ?? false,
  );

  final String factKey;
  final String kind;
  final List<String> sourceSignalKeys;
  final List<String> sourceEvidenceKeys;
  final List<String> sourceFactKeys;
  final PulseStoryCertainty certainty;
  final int? amountMinor;
  final double? decimalValue;
  final int? countValue;
  final int? dueLocalEpochDay;
  final String? periodKey;
  final int sourceCoreRevision;
  final bool includedInForecast;
}

@immutable
final class PulseStoryFragment {
  const PulseStoryFragment({
    required this.role,
    required this.templateId,
    required this.renderedText,
    required this.sourceSignalKeys,
    required this.sourceEvidenceKeys,
    required this.sourceFactKeys,
    required this.certainty,
  });

  factory PulseStoryFragment.fromMap(
    Map<Object?, Object?> map,
  ) => PulseStoryFragment(
    role: PulseStoryFragmentRole.values.byName(map['role']! as String),
    templateId: map['templateId']! as String,
    renderedText: map['renderedText']! as String,
    sourceSignalKeys: (map['sourceSignalKeys'] as List<Object?>? ?? const [])
        .cast<String>(),
    sourceEvidenceKeys:
        (map['sourceEvidenceKeys'] as List<Object?>? ?? const [])
            .cast<String>(),
    sourceFactKeys: (map['sourceFactKeys'] as List<Object?>? ?? const [])
        .cast<String>(),
    certainty: PulseStoryCertainty.values.byName(map['certainty']! as String),
  );

  final PulseStoryFragmentRole role;
  final String templateId;
  final String renderedText;
  final List<String> sourceSignalKeys;
  final List<String> sourceEvidenceKeys;
  final List<String> sourceFactKeys;
  final PulseStoryCertainty certainty;
}

@immutable
final class PulseStoryExclusion {
  const PulseStoryExclusion({
    required this.factKey,
    required this.sourceSignalKey,
    required this.sourceEvidenceKey,
    required this.reasonCode,
    required this.explanation,
  });

  factory PulseStoryExclusion.fromMap(Map<Object?, Object?> map) =>
      PulseStoryExclusion(
        factKey: map['factKey']! as String,
        sourceSignalKey: map['sourceSignalKey'] as String?,
        sourceEvidenceKey: map['sourceEvidenceKey'] as String?,
        reasonCode: map['reasonCode']! as String,
        explanation: map['explanationHu']! as String,
      );

  final String factKey;
  final String? sourceSignalKey;
  final String? sourceEvidenceKey;
  final String reasonCode;
  final String explanation;
}

@immutable
final class PulseStoryDraft {
  const PulseStoryDraft({
    required this.storyKey,
    required this.situationKey,
    required this.candidateKind,
    required this.claimType,
    required this.headline,
    required this.detail,
    required this.fragments,
    required this.exclusions,
    required this.priorityFrameId,
    required this.sourceCoreRevision,
    required this.templateVersion,
    required this.contentFingerprint,
    required this.materialFingerprint,
    required this.evaluationMode,
    required this.generatedAtUtcMs,
  });

  factory PulseStoryDraft.fromMap(Map<Object?, Object?> map) => PulseStoryDraft(
    storyKey: map['storyKey']! as String,
    situationKey: map['situationKey']! as String,
    candidateKind: map['candidateKind']! as String,
    claimType: map['claimType']! as String,
    headline: map['headline']! as String,
    detail: map['detail'] as String?,
    fragments: _list(
      map['fragments'],
    ).map(PulseStoryFragment.fromMap).toList(growable: false),
    exclusions: _list(
      map['exclusions'],
    ).map(PulseStoryExclusion.fromMap).toList(growable: false),
    priorityFrameId: map['priorityFrameId']! as String,
    sourceCoreRevision: (map['sourceCoreRevision'] as num).toInt(),
    templateVersion: (map['templateVersion'] as num).toInt(),
    contentFingerprint: map['contentFingerprint']! as String,
    materialFingerprint: map['materialFingerprint']! as String,
    evaluationMode: map['evaluationMode']! as String,
    generatedAtUtcMs: (map['generatedAtUtcMs'] as num).toInt(),
  );

  final String storyKey;
  final String situationKey;
  final String candidateKind;
  final String claimType;
  final String headline;
  final String? detail;
  final List<PulseStoryFragment> fragments;
  final List<PulseStoryExclusion> exclusions;
  final String priorityFrameId;
  final int sourceCoreRevision;
  final int templateVersion;
  final String contentFingerprint;
  final String materialFingerprint;
  final String evaluationMode;
  final int generatedAtUtcMs;
}

@immutable
final class PulseStoryCompositionResult {
  const PulseStoryCompositionResult({
    required this.status,
    required this.draft,
    required this.reasonCode,
    required this.explanation,
  });

  factory PulseStoryCompositionResult.fromMap(Map<Object?, Object?> map) =>
      PulseStoryCompositionResult(
        status: map['status']! as String,
        draft: map['draft'] == null
            ? null
            : PulseStoryDraft.fromMap(_map(map['draft'])),
        reasonCode: map['reasonCode'] as String?,
        explanation: map['explanationHu'] as String?,
      );

  final String status;
  final PulseStoryDraft? draft;
  final String? reasonCode;
  final String? explanation;
  bool get isComposed => status == 'composed' && draft != null;
}

@immutable
final class PulseStoryInspection {
  const PulseStoryInspection({
    required this.result,
    required this.facts,
    required this.priorityFrameId,
    required this.sourceCoreRevision,
  });

  factory PulseStoryInspection.fromMap(Map<Object?, Object?> map) =>
      PulseStoryInspection(
        result: PulseStoryCompositionResult.fromMap(_map(map['result'])),
        facts: _list(
          map['facts'],
        ).map(PulseStoryFact.fromMap).toList(growable: false),
        priorityFrameId: map['priorityFrameId']! as String,
        sourceCoreRevision: (map['sourceCoreRevision'] as num).toInt(),
      );

  final PulseStoryCompositionResult result;
  final List<PulseStoryFact> facts;
  final String priorityFrameId;
  final int sourceCoreRevision;
}

/// E-phase types mirror the native delivery state. Flutter reports surface
/// facts and renders a reservation; it never decides repeat suppression.
enum PulseDeliveryEligibility {
  eligible,
  waitingForSurface,
  waitingForInteractionIdle,
  waitingForCooldown,
  snoozed,
  muted,
  alreadyShown,
  dismissed,
  stale,
  notComposable,
  historicalOnly,
  recoveryNotPreviouslyShown,
  headerLayoutNotSupported,
  automaticDisabled,
}

enum PulseDeliveryAttemptState {
  reserved,
  presenting,
  presented,
  ended,
  cancelled,
  expired,
}

@immutable
final class PulseDeliverySurfaceContext {
  const PulseDeliverySurfaceContext({
    required this.appActive,
    required this.ledgerVisible,
    required this.headerVisible,
    required this.unobstructed,
    required this.interactionIdle,
    required this.headerLayoutSupported,
    required this.hostSessionId,
    this.interactionIdleSinceUtcMs,
  });

  Map<String, Object?> toMap() => {
    'appActive': appActive,
    'ledgerVisible': ledgerVisible,
    'headerVisible': headerVisible,
    'unobstructed': unobstructed,
    'interactionIdle': interactionIdle,
    'headerLayoutSupported': headerLayoutSupported,
    'hostSessionId': hostSessionId,
    'interactionIdleSinceUtcMs': interactionIdleSinceUtcMs,
  };

  final bool appActive;
  final bool ledgerVisible;
  final bool headerVisible;
  final bool unobstructed;
  final bool interactionIdle;
  final bool headerLayoutSupported;
  final String hostSessionId;
  final int? interactionIdleSinceUtcMs;
}

@immutable
final class PulseDeliveryPreferences {
  const PulseDeliveryPreferences({
    required this.automaticEnabled,
    required this.normalCooldownMillis,
    required this.controlRevision,
    required this.updatedAtUtcMs,
  });

  factory PulseDeliveryPreferences.fromMap(Map<Object?, Object?> map) =>
      PulseDeliveryPreferences(
        automaticEnabled: map['automaticEnabled'] as bool? ?? true,
        normalCooldownMillis:
            (map['normalCooldownMillis'] as num?)?.toInt() ?? 600000,
        controlRevision: (map['controlRevision'] as num?)?.toInt() ?? 0,
        updatedAtUtcMs: (map['updatedAtUtcMs'] as num?)?.toInt() ?? 0,
      );

  final bool automaticEnabled;
  final int normalCooldownMillis;
  final int controlRevision;
  final int updatedAtUtcMs;
}

@immutable
final class PulseDeliveryCandidate {
  const PulseDeliveryCandidate({
    required this.situationKey,
    required this.situationEpisodeId,
    required this.targetScope,
    required this.priorityRank,
    required this.priorityScore,
    required this.story,
    required this.materialSemanticKey,
    required this.contentFingerprint,
    required this.deliveryKey,
    required this.presentationIntentId,
    required this.eligibility,
    required this.reasonCode,
    required this.explanation,
  });

  factory PulseDeliveryCandidate.fromMap(Map<Object?, Object?> map) =>
      PulseDeliveryCandidate(
        situationKey: map['situationKey']! as String,
        situationEpisodeId: map['situationEpisodeId']! as String,
        targetScope: map['targetScope']! as String,
        priorityRank: (map['priorityRank'] as num).toInt(),
        priorityScore: (map['priorityScore'] as num).toInt(),
        story: PulseStoryCompositionResult.fromMap(_map(map['story'])),
        materialSemanticKey: map['materialSemanticKey'] as String?,
        contentFingerprint: map['contentFingerprint'] as String?,
        deliveryKey: map['deliveryKey'] as String?,
        presentationIntentId: map['presentationIntentId']! as String,
        eligibility: PulseDeliveryEligibility.values.byName(
          map['eligibility']! as String,
        ),
        reasonCode: map['reasonCode']! as String,
        explanation: map['explanationHu']! as String,
      );

  final String situationKey;
  final String situationEpisodeId;
  final String targetScope;
  final int priorityRank;
  final int priorityScore;
  final PulseStoryCompositionResult story;
  final String? materialSemanticKey;
  final String? contentFingerprint;
  final String? deliveryKey;
  final String presentationIntentId;
  final PulseDeliveryEligibility eligibility;
  final String reasonCode;
  final String explanation;
}

@immutable
final class PulseDeliveryDecision {
  const PulseDeliveryDecision({
    required this.sourceCoreRevision,
    required this.sourceTriageFrameId,
    required this.evaluationMode,
    required this.prioritySelectedSituationKey,
    required this.deliverySelectedSituationKey,
    required this.deliverySelectionReason,
    required this.candidates,
  });

  factory PulseDeliveryDecision.fromMap(Map<Object?, Object?> map) {
    final input = _map(map['input']);
    return PulseDeliveryDecision(
      sourceCoreRevision: (input['sourceCoreRevision'] as num?)?.toInt() ?? 0,
      sourceTriageFrameId: input['sourceTriageFrameId'] as String? ?? '',
      evaluationMode: input['evaluationMode'] as String? ?? 'live',
      prioritySelectedSituationKey:
          map['prioritySelectedSituationKey'] as String?,
      deliverySelectedSituationKey:
          map['deliverySelectedSituationKey'] as String?,
      deliverySelectionReason: map['deliverySelectionReason'] as String? ?? '',
      candidates: _list(
        map['candidates'],
      ).map(PulseDeliveryCandidate.fromMap).toList(growable: false),
    );
  }

  final int sourceCoreRevision;
  final String sourceTriageFrameId;
  final String evaluationMode;
  final String? prioritySelectedSituationKey;
  final String? deliverySelectedSituationKey;
  final String deliverySelectionReason;
  final List<PulseDeliveryCandidate> candidates;

  PulseDeliveryCandidate? get selected => deliverySelectedSituationKey == null
      ? null
      : candidates.cast<PulseDeliveryCandidate?>().firstWhere(
          (candidate) =>
              candidate?.situationKey == deliverySelectedSituationKey,
          orElse: () => null,
        );
}

@immutable
final class PulseHeaderPresentationReservation {
  const PulseHeaderPresentationReservation({
    required this.attemptId,
    required this.leaseToken,
    required this.hostSessionId,
    required this.deliveryKey,
    required this.presentationIntentId,
    required this.situationEpisodeId,
    required this.targetScope,
    required this.validUntilUtcMs,
    required this.readableDurationMillis,
    required this.sourceFrameId,
    required this.controlRevision,
    required this.story,
  });

  factory PulseHeaderPresentationReservation.fromMap(
    Map<Object?, Object?> map,
  ) => PulseHeaderPresentationReservation(
    attemptId: map['attemptId']! as String,
    leaseToken: map['leaseToken']! as String,
    hostSessionId: map['hostSessionId']! as String,
    deliveryKey: map['deliveryKey']! as String,
    presentationIntentId: map['presentationIntentId']! as String,
    situationEpisodeId: map['situationEpisodeId']! as String,
    targetScope: map['targetScope']! as String,
    validUntilUtcMs: (map['validUntilUtcMs'] as num).toInt(),
    readableDurationMillis: (map['readableDurationMillis'] as num).toInt(),
    sourceFrameId: map['sourceFrameId']! as String,
    controlRevision: (map['controlRevision'] as num).toInt(),
    story: PulseStoryDraft.fromMap(_map(map['story'])),
  );

  final String attemptId;
  final String leaseToken;
  final String hostSessionId;
  final String deliveryKey;
  final String presentationIntentId;
  final String situationEpisodeId;
  final String targetScope;
  final int validUntilUtcMs;
  final int readableDurationMillis;
  final String sourceFrameId;
  final int controlRevision;
  final PulseStoryDraft story;
}

@immutable
final class PulseDeliveryEvent {
  const PulseDeliveryEvent({
    required this.eventId,
    required this.kind,
    required this.attemptId,
    required this.situationKey,
    required this.deliveryKey,
    required this.reasonCode,
    required this.createdAtUtcMs,
  });

  factory PulseDeliveryEvent.fromMap(Map<Object?, Object?> map) =>
      PulseDeliveryEvent(
        eventId: map['eventId']! as String,
        kind: map['kind']! as String,
        attemptId: map['attemptId'] as String?,
        situationKey: map['situationKey'] as String?,
        deliveryKey: map['deliveryKey'] as String?,
        reasonCode: map['reasonCode']! as String,
        createdAtUtcMs: (map['createdAtUtcMs'] as num).toInt(),
      );

  final String eventId;
  final String kind;
  final String? attemptId;
  final String? situationKey;
  final String? deliveryKey;
  final String reasonCode;
  final int createdAtUtcMs;
}

@immutable
final class PulseDeliveryAttempt {
  const PulseDeliveryAttempt({
    required this.attemptId,
    required this.situationKey,
    required this.deliveryKey,
    required this.state,
    required this.validUntilUtcMs,
    required this.reservedAtUtcMs,
    required this.presentedAtUtcMs,
    required this.qualifiedExposureAtUtcMs,
    required this.endReason,
  });

  factory PulseDeliveryAttempt.fromMap(Map<Object?, Object?> map) =>
      PulseDeliveryAttempt(
        attemptId: map['attemptId']! as String,
        situationKey: map['situationKey']! as String,
        deliveryKey: map['deliveryKey']! as String,
        state: map['state']! as String,
        validUntilUtcMs: (map['validUntilUtcMs'] as num).toInt(),
        reservedAtUtcMs: (map['reservedAtUtcMs'] as num).toInt(),
        presentedAtUtcMs: (map['presentedAtUtcMs'] as num?)?.toInt(),
        qualifiedExposureAtUtcMs: (map['qualifiedExposureAtUtcMs'] as num?)
            ?.toInt(),
        endReason: map['endReason'] as String?,
      );

  final String attemptId;
  final String situationKey;
  final String deliveryKey;
  final String state;
  final int validUntilUtcMs;
  final int reservedAtUtcMs;
  final int? presentedAtUtcMs;
  final int? qualifiedExposureAtUtcMs;
  final String? endReason;
}

@immutable
final class PulseDeliveryControl {
  const PulseDeliveryControl({
    required this.controlId,
    required this.kind,
    required this.targetScope,
    required this.expiresAtUtcMs,
    required this.consumedAtUtcMs,
  });

  factory PulseDeliveryControl.fromMap(Map<Object?, Object?> map) =>
      PulseDeliveryControl(
        controlId: map['controlId']! as String,
        kind: map['kind']! as String,
        targetScope: map['targetScope'] as String?,
        expiresAtUtcMs: (map['expiresAtUtcMs'] as num?)?.toInt(),
        consumedAtUtcMs: (map['consumedAtUtcMs'] as num?)?.toInt(),
      );

  final String controlId;
  final String kind;
  final String? targetScope;
  final int? expiresAtUtcMs;
  final int? consumedAtUtcMs;
}

@immutable
final class PulseDeliveryInspection {
  const PulseDeliveryInspection({
    required this.decision,
    required this.preferences,
    required this.controls,
    required this.activeAttempt,
    required this.events,
  });

  factory PulseDeliveryInspection.fromMap(Map<Object?, Object?> map) =>
      PulseDeliveryInspection(
        decision: PulseDeliveryDecision.fromMap(_map(map['decision'])),
        preferences: PulseDeliveryPreferences.fromMap(_map(map['preferences'])),
        controls: _list(
          map['controls'],
        ).map(PulseDeliveryControl.fromMap).toList(growable: false),
        activeAttempt: map['activeAttempt'] == null
            ? null
            : PulseDeliveryAttempt.fromMap(_map(map['activeAttempt'])),
        events: _list(
          map['events'],
        ).map(PulseDeliveryEvent.fromMap).toList(growable: false),
      );

  final PulseDeliveryDecision decision;
  final PulseDeliveryPreferences preferences;
  final List<PulseDeliveryControl> controls;
  final PulseDeliveryAttempt? activeAttempt;
  final List<PulseDeliveryEvent> events;
}

extension on Iterable<PulseIndicatorSnapshot> {
  PulseIndicatorSnapshot? get firstOrNull => isEmpty ? null : first;
}

List<Map<Object?, Object?>> _list(Object? value) =>
    (value as List<Object?>? ?? const [])
        .map((item) => _map(item))
        .toList(growable: false);

Map<Object?, Object?> _map(Object? value) => value is Map<Object?, Object?>
    ? value
    : Map<Object?, Object?>.from(value! as Map);
