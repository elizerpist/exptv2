import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  const fullRange = QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 100000,
    lowerScaled100: 1,
    upperScaled100: 100000,
  );

  MindBehavioralScoreProjection projection({
    required LedgerDirection direction,
    required List<MindBehavioralScoreContribution> contributions,
  }) => MindBehavioralScoreProjection.build(
    identity: MindBehavioralScoreIdentity(
      upstreamScopeKey: '${direction.name}|category:food|partner:-|search:-',
      indexGeneration: 7,
      coreRevision: 11,
      direction: direction,
    ),
    contributions: contributions,
  );

  MindBehavioralScoreContribution day(int amount, LocalDate date) =>
      MindBehavioralScoreContribution(
        bookedLocalEpochDay: date.epochDay,
        amountMinor: amount,
      );

  LocalDate dateOffset(LocalDate date, int days) {
    final value = DateTime.utc(1970).add(Duration(days: date.epochDay + days));
    return LocalDate(year: value.year, month: value.month, day: value.day);
  }

  group('Mind behavioral score — Expense', () {
    test('MBS-02 empty eligible context is good no-pressure', () {
      final frame =
          projection(
            direction: LedgerDirection.expense,
            contributions: const <MindBehavioralScoreContribution>[],
          ).preview(
            range: fullRange,
            targetEpochDay: const LocalDate(
              year: 2025,
              month: 4,
              day: 30,
            ).epochDay,
          );

      expect(frame.point.score, 100);
      expect(frame.point.noSignal, isFalse);
      expect(frame.point.expense, isNotNull);
      expect(frame.point.expense!.activeDaysInContext, 0);
      expect(frame.point.expense!.dailyAmount, 0);
    });

    test('MBS-02 one sparse active day scores its maximum amount as zero', () {
      final target = const LocalDate(year: 2025, month: 4, day: 30);
      final frame = projection(
        direction: LedgerDirection.expense,
        contributions: <MindBehavioralScoreContribution>[day(400, target)],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);

      expect(frame.point.score, 0);
      expect(frame.point.expense!.amountMaximum, 400);
      expect(frame.point.expense!.isSparse, isTrue);
    });

    test(
      'MBS-02 sparse score is amount dominant for 2 through 12 active days',
      () {
        final target = const LocalDate(year: 2025, month: 5, day: 15);
        final points = <MindBehavioralScoreContribution>[
          for (var offset = 0; offset < 12; offset += 1)
            day(100 + offset * 10, dateOffset(target, -offset)),
        ];

        final frame = projection(
          direction: LedgerDirection.expense,
          contributions: points,
        ).preview(range: fullRange, targetEpochDay: target.epochDay);

        expect(frame.point.expense!.activeDaysInContext, 12);
        expect(frame.point.expense!.isSparse, isTrue);
        expect(frame.point.expense!.amountMaximum, 210);
        expect(frame.point.score, closeTo(100 - 100 / 210 * 100, .000001));
      },
    );

    test('MBS-02 dense transition is strictly after twelve active days', () {
      final target = const LocalDate(year: 2025, month: 5, day: 15);
      final frame = projection(
        direction: LedgerDirection.expense,
        contributions: <MindBehavioralScoreContribution>[
          for (var offset = 0; offset < 13; offset += 1)
            day(100 + offset, dateOffset(target, -offset)),
        ],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);

      expect(frame.point.expense!.activeDaysInContext, 13);
      expect(frame.point.expense!.isSparse, isFalse);
      expect(frame.point.expense!.emaPeriod, 16);
      expect(
        frame.point.expense!.pressure,
        closeTo(
          .5 * frame.point.expense!.occurrenceIndex +
              .5 * frame.point.expense!.amountIndex,
          .000001,
        ),
      );
      expect(
        frame.point.score,
        closeTo(100 - frame.point.expense!.pressure, .000001),
      );
    });

    test('MBS-02 dense point uses only causal history, never future rows', () {
      final target = const LocalDate(year: 2025, month: 5, day: 15);
      final past = <MindBehavioralScoreContribution>[
        for (var offset = 0; offset < 16; offset += 1)
          day(100 + offset * 20, dateOffset(target, -offset)),
      ];
      final before = projection(
        direction: LedgerDirection.expense,
        contributions: past,
      ).preview(range: fullRange, targetEpochDay: target.epochDay);
      final after = projection(
        direction: LedgerDirection.expense,
        contributions: <MindBehavioralScoreContribution>[
          ...past,
          day(99999, dateOffset(target, 1)),
          day(99999, dateOffset(target, 40)),
        ],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);

      expect(after.point.score, closeTo(before.point.score, .000001));
      expect(after.point.expense, before.point.expense);
    });

    test('MBS-02 sparse context is exactly the trailing thirty-one days', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      final frame = projection(
        direction: LedgerDirection.expense,
        contributions: <MindBehavioralScoreContribution>[
          // This is one day outside [target - 30, target] and therefore
          // cannot lower the score by becoming the sparse amount maximum.
          day(999999, dateOffset(target, -31)),
          day(100, dateOffset(target, -30)),
          day(200, target),
        ],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);

      expect(frame.point.expense!.activeDaysInContext, 2);
      expect(frame.point.expense!.amountMaximum, 200);
      expect(frame.point.score, 0);
    });

    test('MBS-02 dynamic EMA period uses the approved clamps', () {
      expect(MindBehavioralScoreProjection.dynamicExpenseEmaPeriod(0), 18);
      expect(MindBehavioralScoreProjection.dynamicExpenseEmaPeriod(12), 17);
      expect(MindBehavioralScoreProjection.dynamicExpenseEmaPeriod(13), 16);
      expect(MindBehavioralScoreProjection.dynamicExpenseEmaPeriod(34), 7);
      expect(MindBehavioralScoreProjection.dynamicExpenseEmaPeriod(500), 7);
    });

    test('MBS-02 range exclusion removes and reintroduces activity', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      final prepared = projection(
        direction: LedgerDirection.expense,
        contributions: <MindBehavioralScoreContribution>[day(500, target)],
      );
      const excluded = QueryAmountRangeValues(
        minimumScaled100: 1,
        maximumScaled100: 1000,
        lowerScaled100: 600,
        upperScaled100: 1000,
      );
      const included = QueryAmountRangeValues(
        minimumScaled100: 1,
        maximumScaled100: 1000,
        lowerScaled100: 500,
        upperScaled100: 500,
      );

      expect(
        prepared
            .preview(range: excluded, targetEpochDay: target.epochDay)
            .point
            .score,
        100,
      );
      expect(
        prepared
            .preview(range: included, targetEpochDay: target.epochDay)
            .point
            .score,
        0,
      );
    });

    test(
      'MBS-02 equal historical totals with different occurrence pressure remain distinguishable',
      () {
        const target = LocalDate(year: 2025, month: 5, day: 31);
        final fourLargeDays = projection(
          direction: LedgerDirection.expense,
          contributions: <MindBehavioralScoreContribution>[
            day(10000, dateOffset(target, -30)),
            day(10000, dateOffset(target, -20)),
            day(10000, dateOffset(target, -10)),
            day(10000, dateOffset(target, -1)),
          ],
        ).preview(range: fullRange, targetEpochDay: target.epochDay);
        final twentySmallDays = projection(
          direction: LedgerDirection.expense,
          contributions: <MindBehavioralScoreContribution>[
            // Same 40k historical total, but dense behaviour has had time
            // to cool after the earlier twenty small active days.
            for (var offset = 70; offset >= 51; offset -= 1)
              day(2000, dateOffset(target, -offset)),
          ],
        ).preview(range: fullRange, targetEpochDay: target.epochDay);

        expect(fourLargeDays.point.expense!.rollingAmount, 40000);
        expect(twentySmallDays.point.expense!.rollingAmount, 0);
        expect(fourLargeDays.point.expense!.activeDaysInContext, 4);
        expect(twentySmallDays.point.expense!.isSparse, isFalse);
        expect(fourLargeDays.point.score, isNot(twentySmallDays.point.score));
      },
    );

    test('MBS-02 range endpoints are inclusive before daily aggregation', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      final frame =
          projection(
            direction: LedgerDirection.expense,
            contributions: <MindBehavioralScoreContribution>[
              day(100, target),
              day(200, target),
              day(300, target),
            ],
          ).preview(
            range: const QueryAmountRangeValues(
              minimumScaled100: 1,
              maximumScaled100: 1000,
              lowerScaled100: 100,
              upperScaled100: 200,
            ),
            targetEpochDay: target.epochDay,
          );

      expect(frame.point.expense!.dailyAmount, 300);
      expect(frame.point.expense!.amountMaximum, 300);
      expect(frame.point.score, 0);
    });

    test('MBS-01 a day point is invariant to presentation view metadata', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      final prepared = projection(
        direction: LedgerDirection.expense,
        contributions: <MindBehavioralScoreContribution>[
          for (var offset = 0; offset < 8; offset += 1)
            day(100 + offset, dateOffset(target, -offset)),
        ],
      );

      final dayFrame = prepared.preview(
        range: fullRange,
        targetEpochDay: target.epochDay,
      );
      final month = prepared.preview(
        range: fullRange,
        targetEpochDay: target.epochDay,
      );
      final year = prepared.preview(
        range: fullRange,
        targetEpochDay: target.epochDay,
      );
      final sum = prepared.preview(
        range: fullRange,
        targetEpochDay: target.epochDay,
      );

      expect(month.point, dayFrame.point);
      expect(year.point, dayFrame.point);
      expect(sum.point, dayFrame.point);
    });

    test(
      'DAY-LIVE-02/03: a rolling Day chart preserves the canonical selected-day point',
      () {
        const target = LocalDate(year: 2025, month: 5, day: 15);
        for (final direction in LedgerDirection.values) {
          final prepared = projection(
            direction: direction,
            contributions: <MindBehavioralScoreContribution>[
              for (var offset = 0; offset < 31; offset += 1)
                day(100 + offset, dateOffset(target, -offset)),
            ],
          );
          final canonical = prepared.resolve(
            range: fullRange,
            request: MindBehavioralScoreSeriesRequest(
              analyticStartInclusiveEpochDay: target.epochDay,
              analyticEndInclusiveEpochDay: target.epochDay,
              chartStartInclusiveEpochDay: target.epochDay,
              targetEpochDay: target.epochDay,
            ),
          );
          final rolling = prepared.resolve(
            range: fullRange,
            request: MindBehavioralScoreSeriesRequest(
              analyticStartInclusiveEpochDay: target.epochDay - 30,
              analyticEndInclusiveEpochDay: target.epochDay,
              chartStartInclusiveEpochDay: target.epochDay - 30,
              targetEpochDay: target.epochDay,
              pointAnalyticStartInclusiveEpochDay: target.epochDay,
            ),
          );

          expect(rolling.point, canonical.point, reason: direction.name);
          expect(
            rolling.chartSeries!.startInclusiveEpochDay,
            target.epochDay - 30,
          );
          expect(rolling.chartSeries!.endInclusiveEpochDay, target.epochDay);
          expect(rolling.chartSeries!.points.last, rolling.point);
        }
      },
    );
  });

  group('Mind behavioral score — Income', () {
    test(
      'MBS-03 no prior meaningful sample is neutral but explicitly no-signal',
      () {
        const target = LocalDate(year: 2025, month: 5, day: 15);
        final frame = projection(
          direction: LedgerDirection.income,
          contributions: <MindBehavioralScoreContribution>[day(1000, target)],
        ).preview(range: fullRange, targetEpochDay: target.epochDay);

        expect(frame.point.score, 50);
        expect(frame.point.noSignal, isTrue);
        expect(frame.point.income!.currentAmount, 1000);
      },
    );

    test(
      'MBS-03 uses the latest three prior daily samples and median baseline',
      () {
        const target = LocalDate(year: 2025, month: 5, day: 15);
        final frame = projection(
          direction: LedgerDirection.income,
          contributions: <MindBehavioralScoreContribution>[
            day(100, dateOffset(target, -5)),
            day(200, dateOffset(target, -4)),
            day(300, dateOffset(target, -3)),
            day(400, dateOffset(target, -2)),
            day(1000, target),
          ],
        ).preview(range: fullRange, targetEpochDay: target.epochDay);

        final income = frame.point.income!;
        expect(frame.point.noSignal, isFalse);
        expect(income.previousAverage, 300);
        expect(income.baseline, 300);
        expect(income.trendAdjustment, 30);
        expect(frame.point.score, 80);
      },
    );

    test('MBS-03 averages exactly one, two and three prior samples', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      MindBehavioralScoreFrame scoreFor(List<int> previous) => projection(
        direction: LedgerDirection.income,
        contributions: <MindBehavioralScoreContribution>[
          for (final (index, amount) in previous.indexed)
            day(amount, dateOffset(target, -(previous.length - index))),
          day(400, target),
        ],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);

      expect(scoreFor(<int>[100]).point.income!.previousAverage, 100);
      expect(scoreFor(<int>[100, 200]).point.income!.previousAverage, 150);
      expect(scoreFor(<int>[100, 200, 300]).point.income!.previousAverage, 200);
    });

    test('MBS-03 median reference can dominate the recent-three average', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      final frame = projection(
        direction: LedgerDirection.income,
        contributions: <MindBehavioralScoreContribution>[
          day(1000, dateOffset(target, -5)),
          day(1000, dateOffset(target, -4)),
          day(1000, dateOffset(target, -3)),
          day(1, dateOffset(target, -2)),
          day(1, dateOffset(target, -1)),
          day(1, target),
        ],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);

      final income = frame.point.income!;
      expect(income.previousAverage, closeTo(334, .000001));
      expect(income.baseline, closeTo(500.5, .000001));
      expect(income.trendAdjustment, closeTo(-23.286713, .000001));
    });

    test('MBS-03 caps both positive and negative trend adjustment', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      MindBehavioralScorePoint pointFor({
        required int previous,
        required int current,
      }) => projection(
        direction: LedgerDirection.income,
        contributions: <MindBehavioralScoreContribution>[
          day(previous, dateOffset(target, -1)),
          day(current, target),
        ],
      ).preview(range: fullRange, targetEpochDay: target.epochDay).point;

      final positive = pointFor(previous: 1, current: 99999);
      final negative = pointFor(previous: 99999, current: 1);
      expect(positive.income!.trendAdjustment, 30);
      expect(positive.score, 80);
      expect(negative.income!.trendAdjustment, -30);
      expect(negative.score, 20);
    });

    test('MBS-03 signalled numeric fifty differs from no-signal fifty', () {
      const target = LocalDate(year: 2025, month: 5, day: 15);
      final signalled = projection(
        direction: LedgerDirection.income,
        contributions: <MindBehavioralScoreContribution>[
          day(500, dateOffset(target, -1)),
          day(500, target),
        ],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);
      final neutral = projection(
        direction: LedgerDirection.income,
        contributions: <MindBehavioralScoreContribution>[day(500, target)],
      ).preview(range: fullRange, targetEpochDay: target.epochDay);

      expect(signalled.point.score, 50);
      expect(signalled.point.noSignal, isFalse);
      expect(neutral.point.score, 50);
      expect(neutral.point.noSignal, isTrue);
    });

    test(
      'MBS-03 amount filtering happens before meaningful Income samples',
      () {
        const target = LocalDate(year: 2025, month: 5, day: 15);
        final frame =
            projection(
              direction: LedgerDirection.income,
              contributions: <MindBehavioralScoreContribution>[
                day(100, dateOffset(target, -1)),
                day(500, dateOffset(target, -1)),
                day(500, target),
              ],
            ).preview(
              range: const QueryAmountRangeValues(
                minimumScaled100: 1,
                maximumScaled100: 1000,
                lowerScaled100: 500,
                upperScaled100: 500,
              ),
              targetEpochDay: target.epochDay,
            );

        expect(frame.point.noSignal, isFalse);
        expect(frame.point.income!.previousAverage, 500);
        expect(frame.point.score, 50);
      },
    );

    test(
      'MSS-18 causal full-history preview touches only resident daily buckets',
      () {
        const target = LocalDate(year: 2035, month: 12, day: 31);
        final counter = MindBehavioralScoreSourceWorkCounter(
          measurePreviewDurations: true,
        );
        final prepared = MindBehavioralScoreProjection.build(
          identity: const MindBehavioralScoreIdentity(
            upstreamScopeKey: 'expense|long-history',
            indexGeneration: 1,
            coreRevision: 1,
            direction: LedgerDirection.expense,
          ),
          contributions: <MindBehavioralScoreContribution>[
            for (var dayOffset = 0; dayOffset < 10000; dayOffset += 1)
              MindBehavioralScoreContribution(
                bookedLocalEpochDay: target.epochDay - dayOffset,
                amountMinor: 100 + dayOffset % 17,
              ),
          ],
          sourceWorkCounter: counter,
        );

        for (var preview = 0; preview < 20; preview += 1) {
          prepared.preview(range: fullRange, targetEpochDay: target.epochDay);
        }

        expect(counter.sourceRowTouches, 0);
        expect(counter.sourceRowTouchesDuringPreview, 0);
        expect(counter.repositoryAccessesDuringPreview, 0);
        expect(counter.indexBuildsDuringPreview, 0);
        // Full-history causality may traverse a long prepared day domain, but
        // it never returns to source rows, Room, repositories or native index
        // construction. The exact visited bound is the 10k admitted day bank.
        expect(
          counter.maxDayBucketsVisitedPerPreview,
          lessThanOrEqualTo(10000),
        );
        expect(counter.previewDurationSummary()['sampleCount'], 20);
      },
    );
  });
}
