import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_settings.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

import 'fixtures/fastfood_2027_fixture.dart';

void main() {
  const range = QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 100000,
    lowerScaled100: 1,
    upperScaled100: 100000,
  );

  MindBehavioralScoreContribution contribution(LocalDate date, int amount) =>
      MindBehavioralScoreContribution(
        bookedLocalEpochDay: date.epochDay,
        amountMinor: amount,
      );

  LocalDate plusDays(LocalDate date, int days) {
    final value = DateTime.utc(1970).add(Duration(days: date.epochDay + days));
    return LocalDate(year: value.year, month: value.month, day: value.day);
  }

  MindBehavioralScoreProjection projection({
    required MindExpenseScoreAlgorithm algorithm,
    required Iterable<MindBehavioralScoreContribution> contributions,
    MindCausalHistoryOrigin origin =
        MindCausalHistoryOrigin.fullFilteredHistory,
  }) => MindBehavioralScoreProjection.build(
    identity: MindBehavioralScoreIdentity(
      upstreamScopeKey: 'expense|food',
      indexGeneration: 1,
      coreRevision: 1,
      direction: LedgerDirection.expense,
      settings: MindBehavioralScoreSettings(
        expenseAlgorithm: algorithm,
        causalHistoryOrigin: origin,
        revision: 0,
      ),
    ),
    contributions: contributions,
  );

  final start = const LocalDate(year: 2027, month: 1, day: 1);
  final lateTarget = plusDays(start, 80);
  final contributions = <MindBehavioralScoreContribution>[
    // Dense once: these are thirteen qualifying days early in the same
    // filtered history. The later active target is isolated in its own 31-day
    // trailing window, which was the rejected terminal-zero shape.
    for (var offset = 0; offset < 13; offset += 1)
      contribution(plusDays(start, offset), 1000 + offset * 10),
    contribution(lateTarget, 4200),
  ];

  MindBehavioralScoreSeriesRequest requestFor({
    required int analyticStart,
    required int analyticEnd,
    required int target,
  }) => MindBehavioralScoreSeriesRequest(
    analyticStartInclusiveEpochDay: analyticStart,
    analyticEndInclusiveEpochDay: analyticEnd,
    chartStartInclusiveEpochDay: analyticStart,
    targetEpochDay: target,
  );

  test(
    'MSS-10 causal trailing stays dense after its thirteenth cumulative active day',
    () {
      final frame =
          projection(
            algorithm: MindExpenseScoreAlgorithm.causalTrailing,
            contributions: contributions,
          ).resolve(
            range: range,
            request: requestFor(
              analyticStart: start.epochDay,
              analyticEnd: lateTarget.epochDay,
              target: lateTarget.epochDay,
            ),
          );

      expect(frame.point.expense!.isSparse, isFalse);
      expect(frame.point.score, isNot(0));
    },
  );

  test(
    'MSS-08 HTML trailing makes one scope-wide dense decision, not one local decision per target',
    () {
      final frame =
          projection(
            algorithm: MindExpenseScoreAlgorithm.htmlTrailing,
            contributions: contributions,
          ).resolve(
            range: range,
            request: requestFor(
              analyticStart: start.epochDay,
              analyticEnd: lateTarget.epochDay,
              target: lateTarget.epochDay,
            ),
          );

      expect(frame.point.expense!.isSparse, isFalse);
      expect(frame.point.score, isNot(0));
    },
  );

  test('MSS-05 HTML centered intentionally reads future window values', () {
    final target = plusDays(start, 15);
    final early = <MindBehavioralScoreContribution>[
      for (var offset = 0; offset < 13; offset += 1)
        contribution(plusDays(start, offset), 1000),
    ];
    MindBehavioralScoreFrame frameFor(
      Iterable<MindBehavioralScoreContribution> values,
    ) =>
        projection(
          algorithm: MindExpenseScoreAlgorithm.htmlCentered,
          contributions: values,
        ).resolve(
          range: range,
          request: requestFor(
            analyticStart: start.epochDay,
            analyticEnd: plusDays(start, 45).epochDay,
            target: target.epochDay,
          ),
          maximumChartPoints: 100,
        );

    final before = frameFor(early);
    final after = frameFor(<MindBehavioralScoreContribution>[
      ...early,
      contribution(plusDays(target, 10), 9000),
    ]);
    expect(after.point.score, isNot(closeTo(before.point.score, 1e-9)));
  });

  test(
    'MSS-09 HTML trailing excludes centered leakage but keeps whole-series normalization dependency',
    () {
      final target = plusDays(start, 12);
      final early = <MindBehavioralScoreContribution>[
        for (var offset = 0; offset < 13; offset += 1)
          contribution(plusDays(start, offset), 1000),
      ];
      MindBehavioralScoreFrame frameFor(
        Iterable<MindBehavioralScoreContribution> values,
      ) =>
          projection(
            algorithm: MindExpenseScoreAlgorithm.htmlTrailing,
            contributions: values,
          ).resolve(
            range: range,
            request: requestFor(
              analyticStart: start.epochDay,
              analyticEnd: plusDays(start, 60).epochDay,
              target: target.epochDay,
            ),
            maximumChartPoints: 100,
          );

      final before = frameFor(early);
      final after = frameFor(<MindBehavioralScoreContribution>[
        ...early,
        // It lies outside target's trailing [d-30,d] window. A changed
        // target score therefore proves the explicitly intentional global
        // max / whole-scope dense dependency, not centered-window leakage.
        contribution(plusDays(target, 40), 9000),
      ]);
      expect(
        after.point.expense!.rollingAmount,
        before.point.expense!.rollingAmount,
      );
      expect(after.point.score, isNot(closeTo(before.point.score, 1e-9)));
    },
  );

  test(
    'MSS-11 causal trailing never lets a future row rewrite a past point',
    () {
      final target = plusDays(start, 12);
      final past = <MindBehavioralScoreContribution>[
        for (var offset = 0; offset < 13; offset += 1)
          contribution(plusDays(start, offset), 1000 + offset),
      ];
      MindBehavioralScoreFrame frameFor(
        Iterable<MindBehavioralScoreContribution> values,
      ) =>
          projection(
            algorithm: MindExpenseScoreAlgorithm.causalTrailing,
            contributions: values,
          ).resolve(
            range: range,
            request: requestFor(
              analyticStart: start.epochDay,
              analyticEnd: target.epochDay,
              target: target.epochDay,
            ),
            maximumChartPoints: 100,
          );

      final before = frameFor(past);
      final after = frameFor(<MindBehavioralScoreContribution>[
        ...past,
        contribution(plusDays(target, 1), 99999),
        contribution(plusDays(target, 80), 99999),
      ]);
      expect(after.point, before.point);
    },
  );

  test('MSS-12 causal history origin resets only at selected-scope start', () {
    final selectedScopeStart = plusDays(start, 50);
    final target = plusDays(selectedScopeStart, 11);
    final values = <MindBehavioralScoreContribution>[
      for (var offset = 0; offset < 13; offset += 1)
        contribution(plusDays(start, offset), 1000),
      for (var offset = 0; offset < 12; offset += 1)
        contribution(plusDays(selectedScopeStart, offset), 1200),
    ];
    final prepared = projection(
      algorithm: MindExpenseScoreAlgorithm.causalTrailing,
      contributions: values,
    );
    final fullHistory = prepared.resolve(
      range: range,
      request: MindBehavioralScoreSeriesRequest(
        analyticStartInclusiveEpochDay: start.epochDay,
        analyticEndInclusiveEpochDay: target.epochDay,
        chartStartInclusiveEpochDay: selectedScopeStart.epochDay,
        targetEpochDay: target.epochDay,
      ),
      maximumChartPoints: 100,
    );
    final scopeStart = prepared.resolve(
      range: range,
      request: MindBehavioralScoreSeriesRequest(
        analyticStartInclusiveEpochDay: selectedScopeStart.epochDay,
        analyticEndInclusiveEpochDay: target.epochDay,
        chartStartInclusiveEpochDay: selectedScopeStart.epochDay,
        targetEpochDay: target.epochDay,
      ),
      maximumChartPoints: 100,
    );
    final sameFullHistoryDateThroughOtherView = prepared.resolve(
      range: range,
      request: MindBehavioralScoreSeriesRequest(
        analyticStartInclusiveEpochDay: start.epochDay,
        analyticEndInclusiveEpochDay: target.epochDay,
        chartStartInclusiveEpochDay: plusDays(selectedScopeStart, 5).epochDay,
        targetEpochDay: target.epochDay,
      ),
      maximumChartPoints: 100,
    );

    expect(fullHistory.point.expense!.isSparse, isFalse);
    expect(scopeStart.point.expense!.isSparse, isTrue);
    expect(fullHistory.point, sameFullHistoryDateThroughOtherView.point);
    expect(scopeStart.point.score, isNot(fullHistory.point.score));
  });

  test(
    'MSS-14 every Expense algorithm publishes one coherent Header/chart end',
    () {
      final values = <MindBehavioralScoreContribution>[
        for (var offset = 0; offset < 14; offset += 1)
          contribution(plusDays(start, offset), 1000 + offset * 100),
      ];
      final target = plusDays(start, 13);
      for (final algorithm in MindExpenseScoreAlgorithm.values) {
        final frame = projection(algorithm: algorithm, contributions: values)
            .resolve(
              range: range,
              request: requestFor(
                analyticStart: start.epochDay,
                analyticEnd: target.epochDay,
                target: target.epochDay,
              ),
              maximumChartPoints: 100,
            );
        expect(frame.chartSeries, isNotNull, reason: algorithm.name);
        expect(
          frame.point,
          frame.chartSeries!.points.last,
          reason: algorithm.name,
        );
      }
    },
  );

  test(
    'MSS-16 exact 2027 Fastfood HTML-centered series matches categorySeries',
    () {
      expect(exactFastfood2027Rows, hasLength(100));
      expect(
        exactFastfood2027Rows.fold<int>(0, (sum, row) => sum + row.amountHuf),
        exactFastfood2027TotalHuf,
      );
      final projection = MindBehavioralScoreProjection.build(
        identity: const MindBehavioralScoreIdentity(
          upstreamScopeKey: 'expense|fastfood|2027',
          indexGeneration: 7,
          coreRevision: 7,
          direction: LedgerDirection.expense,
          settings: MindBehavioralScoreSettings(
            expenseAlgorithm: MindExpenseScoreAlgorithm.htmlCentered,
            causalHistoryOrigin: MindCausalHistoryOrigin.fullFilteredHistory,
            revision: 0,
          ),
        ),
        contributions: <MindBehavioralScoreContribution>[
          for (final row in exactFastfood2027Rows)
            MindBehavioralScoreContribution(
              bookedLocalEpochDay: LocalDate(
                year: 2027,
                month: row.month,
                day: row.day,
              ).epochDay,
              amountMinor: row.amountHuf * 100,
            ),
        ],
      );
      const scopeStart = LocalDate(year: 2027, month: 1, day: 1);
      const scopeEnd = LocalDate(year: 2027, month: 12, day: 31);
      const target = LocalDate(year: 2027, month: 12, day: 30);

      final frame = projection.resolve(
        range: const QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 1350000,
          lowerScaled100: 100000,
          upperScaled100: 1350000,
        ),
        request: MindBehavioralScoreSeriesRequest(
          analyticStartInclusiveEpochDay: scopeStart.epochDay,
          analyticEndInclusiveEpochDay: scopeEnd.epochDay,
          chartStartInclusiveEpochDay: scopeStart.epochDay,
          targetEpochDay: target.epochDay,
        ),
        maximumChartPoints: 400,
      );

      final reference = _htmlCategorySeriesReference(
        start: scopeStart,
        end: scopeEnd,
      );
      expect(reference, isNotEmpty);
      expect(frame.chartSeries!.points, hasLength(reference.length));
      for (final (index, expected) in reference.indexed) {
        expect(frame.chartSeries!.points[index].score, closeTo(expected, 1e-9));
      }
      expect(reference.last.round(), 85);
      expect(frame.point.roundedScore, 85);
    },
  );
}

/// Test-only literal mathematical port of f332b712's Expense
/// `categorySeries()` dense/sparse path. It deliberately has no production
/// dependency beyond the exact extracted Fastfood semantic rows.
List<double> _htmlCategorySeriesReference({
  required LocalDate start,
  required LocalDate end,
}) {
  final daily = <int, int>{};
  for (final row in exactFastfood2027Rows) {
    final epochDay = LocalDate(
      year: 2027,
      month: row.month,
      day: row.day,
    ).epochDay;
    daily[epochDay] = (daily[epochDay] ?? 0) + row.amountHuf * 100;
  }
  final amounts = <int>[
    for (var epochDay = start.epochDay; epochDay <= end.epochDay; epochDay += 1)
      daily[epochDay] ?? 0,
  ];
  final first = amounts.indexWhere((amount) => amount > 0);
  if (first < 0) return const <double>[];
  var last = amounts.length - 1;
  while (amounts[last] == 0) {
    last -= 1;
  }
  final graph = amounts.sublist(first, last + 1);
  final activeDays = graph.where((amount) => amount > 0).length;
  if (activeDays <= 12) {
    final maximum = graph.fold<int>(0, math.max);
    return <double>[
      for (final amount in graph)
        if (amount > 0) (100 - amount / maximum * 100).clamp(0, 100).toDouble(),
    ];
  }
  final rollingOccurrence = List<int>.filled(graph.length, 0);
  final rollingAmount = List<int>.filled(graph.length, 0);
  for (var index = 0; index < graph.length; index += 1) {
    final lower = math.max(0, index - 15);
    final upper = math.min(graph.length - 1, index + 15);
    for (var cursor = lower; cursor <= upper; cursor += 1) {
      if (graph[cursor] == 0) continue;
      rollingOccurrence[index] += 1;
      rollingAmount[index] += graph[cursor];
    }
  }
  final period = MindBehavioralScoreProjection.dynamicExpenseEmaPeriod(
    activeDays,
  );
  final alpha = 2 / (period + 1);
  List<double> ema(List<int> source) {
    final result = List<double>.filled(source.length, 0);
    result[0] = source.first.toDouble();
    for (var index = 1; index < source.length; index += 1) {
      result[index] =
          result[index - 1] + alpha * (source[index] - result[index - 1]);
    }
    return result;
  }

  final occurrence = ema(rollingOccurrence);
  final amount = ema(rollingAmount);
  final maximumOccurrence = math.max(1, occurrence.reduce(math.max));
  final maximumAmount = math.max(1, amount.reduce(math.max));
  return List<double>.generate(graph.length, (index) {
    final occurrenceIndex = (occurrence[index] / maximumOccurrence * 100)
        .clamp(0, 100)
        .toDouble();
    final amountIndex = (amount[index] / maximumAmount * 100)
        .clamp(0, 100)
        .toDouble();
    return (100 - .5 * occurrenceIndex - .5 * amountIndex)
        .clamp(0, 100)
        .toDouble();
  });
}
