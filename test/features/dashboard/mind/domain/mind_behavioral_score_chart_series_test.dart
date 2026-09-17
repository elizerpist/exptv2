import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';

void main() {
  const range = QueryAmountRangeValues(
    minimumScaled100: 100,
    maximumScaled100: 900,
    lowerScaled100: 200,
    upperScaled100: 700,
  );

  MindBehavioralScoreProjection projection({
    required LedgerDirection direction,
    required Iterable<MindBehavioralScoreContribution> contributions,
  }) => MindBehavioralScoreProjection.build(
    identity: MindBehavioralScoreIdentity(
      upstreamScopeKey: '${direction.name}|chart',
      indexGeneration: 1,
      coreRevision: 1,
      direction: direction,
    ),
    contributions: contributions,
  );

  test(
    'MHC-06 chart series is chronological, bounded and uses canonical daily score points',
    () {
      final prepared = projection(
        direction: LedgerDirection.expense,
        contributions: <MindBehavioralScoreContribution>[
          for (var day = 0; day <= 140; day += 1)
            MindBehavioralScoreContribution(
              bookedLocalEpochDay: 20000 + day,
              amountMinor: 100 + (day % 7) * 100,
            ),
        ],
      );

      final series = prepared.chartSeries(
        range: range,
        startInclusiveEpochDay: 20000,
        endInclusiveEpochDay: 20140,
      );

      expect(series.points, isNotEmpty);
      expect(series.points.length, lessThanOrEqualTo(56));
      expect(series.startInclusiveEpochDay, 20000);
      expect(series.endInclusiveEpochDay, 20140);
      expect(series.points.first.epochDay, 20000);
      expect(series.points.last.epochDay, 20140);
      for (var index = 1; index < series.points.length; index += 1) {
        expect(
          series.points[index].epochDay,
          greaterThan(series.points[index - 1].epochDay),
        );
      }
      for (final point in series.points) {
        expect(
          point,
          prepared.preview(range: range, targetEpochDay: point.epochDay).point,
        );
      }
    },
  );

  test(
    'MHC-06 chart series applies the inclusive amount range before sampling',
    () {
      final prepared = projection(
        direction: LedgerDirection.expense,
        contributions: const <MindBehavioralScoreContribution>[
          MindBehavioralScoreContribution(
            bookedLocalEpochDay: 10,
            amountMinor: 199,
          ),
          MindBehavioralScoreContribution(
            bookedLocalEpochDay: 11,
            amountMinor: 200,
          ),
          MindBehavioralScoreContribution(
            bookedLocalEpochDay: 12,
            amountMinor: 700,
          ),
          MindBehavioralScoreContribution(
            bookedLocalEpochDay: 13,
            amountMinor: 701,
          ),
        ],
      );

      final series = prepared.chartSeries(
        range: range,
        startInclusiveEpochDay: 10,
        endInclusiveEpochDay: 13,
      );

      expect(series.points.map((point) => point.epochDay), <int>[
        10,
        11,
        12,
        13,
      ]);
      expect(series.points[1].expense!.dailyAmount, 200);
      expect(series.points[2].expense!.dailyAmount, 700);
      expect(series.points[0].expense!.dailyAmount, 0);
      expect(series.points[3].expense!.dailyAmount, 0);
    },
  );

  test(
    'MHC-07 Income history is one resident chronological pass, not a point-by-point history rescan',
    () {
      final counter = MindBehavioralScoreSourceWorkCounter();
      final prepared = MindBehavioralScoreProjection.build(
        identity: const MindBehavioralScoreIdentity(
          upstreamScopeKey: 'income|chart-long-history',
          indexGeneration: 1,
          coreRevision: 1,
          direction: LedgerDirection.income,
        ),
        contributions: <MindBehavioralScoreContribution>[
          for (var day = 0; day < 500; day += 1)
            MindBehavioralScoreContribution(
              bookedLocalEpochDay: 10000 + day,
              amountMinor: 200 + day % 11,
            ),
        ],
        sourceWorkCounter: counter,
      );

      final series = prepared.chartSeries(
        range: range,
        startInclusiveEpochDay: 10000,
        endInclusiveEpochDay: 10499,
      );

      expect(counter.chartSeriesBuildCount, 1);
      // One range-index lookup per resident day plus at most the bounded chart
      // targets that happen to contain no contribution. In particular this
      // must not be 56 independent scans of the 500-day prepared history.
      expect(
        counter.maxDayBucketsVisitedPerChartSeries,
        lessThanOrEqualTo(556),
      );
      expect(counter.sourceRowTouches, 0);
      expect(counter.sourceRowTouchesDuringPreview, 0);
      expect(counter.repositoryAccessesDuringPreview, 0);
      expect(counter.indexBuildsDuringPreview, 0);
      for (final point in series.points) {
        expect(
          point,
          prepared.preview(range: range, targetEpochDay: point.epochDay).point,
        );
      }
    },
  );
}
