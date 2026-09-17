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
    maximumScaled100: 2000000,
    lowerScaled100: 1,
    upperScaled100: 2000000,
  );

  MindBehavioralScoreProjection prepare({
    required MindExpenseScoreAlgorithm algorithm,
    required Iterable<MindBehavioralScoreContribution> contributions,
    required MindBehavioralScoreSourceWorkCounter counter,
  }) => MindBehavioralScoreProjection.build(
    identity: MindBehavioralScoreIdentity(
      upstreamScopeKey: 'expense|profile|${algorithm.name}',
      indexGeneration: 1,
      coreRevision: 1,
      direction: LedgerDirection.expense,
      settings: MindBehavioralScoreSettings(
        expenseAlgorithm: algorithm,
        causalHistoryOrigin: MindCausalHistoryOrigin.fullFilteredHistory,
        revision: 0,
      ),
    ),
    contributions: contributions,
    sourceWorkCounter: counter,
  );

  test('MSS-18 profile: Fastfood and dense multi-year previews stay resident', () {
    final fastfood = <MindBehavioralScoreContribution>[
      for (final row in exactFastfood2027Rows)
        MindBehavioralScoreContribution(
          bookedLocalEpochDay: LocalDate(
            year: 2027,
            month: row.month,
            day: row.day,
          ).epochDay,
          amountMinor: row.amountHuf * 100,
        ),
    ];
    const denseStart = LocalDate(year: 2021, month: 1, day: 1);
    const denseDays = 365 * 5;
    final dense = <MindBehavioralScoreContribution>[
      for (var offset = 0; offset < denseDays; offset += 1)
        MindBehavioralScoreContribution(
          bookedLocalEpochDay: denseStart.epochDay + offset,
          amountMinor: 100000 + (offset % 31) * 1000,
        ),
    ];

    for (final algorithm in MindExpenseScoreAlgorithm.values) {
      for (final scenario
          in <(String, List<MindBehavioralScoreContribution>, int, int)>[
            (
              'fastfood2027',
              fastfood,
              const LocalDate(year: 2027, month: 1, day: 1).epochDay,
              const LocalDate(year: 2027, month: 12, day: 30).epochDay,
            ),
            (
              'dense5y',
              dense,
              denseStart.epochDay,
              denseStart.epochDay + denseDays - 1,
            ),
          ]) {
        final counter = MindBehavioralScoreSourceWorkCounter(
          measurePreviewDurations: true,
        );
        final prepareWatch = Stopwatch()..start();
        final projection = prepare(
          algorithm: algorithm,
          contributions: scenario.$2,
          counter: counter,
        );
        prepareWatch.stop();
        for (var preview = 0; preview < 20; preview += 1) {
          projection.resolve(
            range: range,
            request: MindBehavioralScoreSeriesRequest(
              analyticStartInclusiveEpochDay: scenario.$3,
              analyticEndInclusiveEpochDay: scenario.$4,
              chartStartInclusiveEpochDay: scenario.$3,
              targetEpochDay: scenario.$4,
            ),
          );
        }
        final timing = counter.previewDurationSummary();
        // This is retained test evidence, not an environment-sensitive frame
        // budget threshold. The invariants below make the hot path auditable.
        // ignore: avoid_print
        print(
          'MIND_SCORE_PROFILE algorithm=${algorithm.name} '
          'scenario=${scenario.$1} prepareMicros=${prepareWatch.elapsedMicroseconds} '
          'p50=${timing['p50Micros']} p95=${timing['p95Micros']} '
          'max=${timing['maxMicros']} buckets=${counter.maxDayBucketsVisitedPerPreview}',
        );
        expect(counter.sourceRowTouches, 0);
        expect(counter.sourceRowTouchesDuringPreview, 0);
        expect(counter.repositoryAccessesDuringPreview, 0);
        expect(counter.indexBuildsDuringPreview, 0);
        expect(
          counter.maxDayBucketsVisitedPerPreview,
          lessThanOrEqualTo(scenario.$4 - scenario.$3 + 1),
        );
        expect(timing['sampleCount'], 20);
        expect(timing['maxMicros'], greaterThanOrEqualTo(0));
      }
    }
  });
}
