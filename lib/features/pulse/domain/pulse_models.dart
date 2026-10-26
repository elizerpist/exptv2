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
      );

  final int year;
  final int month;
  final int coreRevision;
  final int generatedAtUtcMs;
  final List<PulseIndicatorSnapshot> indicators;
  final List<PulseSourceOption> subscriptionOptions;

  PulseIndicatorSnapshot? byId(String id) =>
      indicators.where((indicator) => indicator.id == id).firstOrNull;

  List<PulseIndicatorSnapshot> inGroup(PulseGroup group) => indicators
      .where((indicator) => indicator.group == group)
      .toList(growable: false);
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
