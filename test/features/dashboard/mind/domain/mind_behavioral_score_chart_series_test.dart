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
      // The lower range endpoint excludes the 100-unit first day. Sparse
      // periods preserve real meaningful dates rather than fabricate a zero
      // point at the visual boundary.
      expect(series.points.first.epochDay, 20001);
      expect(series.points.last.epochDay, 20140);
      for (var index = 1; index < series.points.length; index += 1) {
        expect(
          series.points[index].epochDay,
          greaterThan(series.points[index - 1].epochDay),
        );
      }
      final resolved = prepared.resolve(
        range: range,
        request: const MindBehavioralScoreSeriesRequest(
          analyticStartInclusiveEpochDay: 20000,
          analyticEndInclusiveEpochDay: 20140,
          chartStartInclusiveEpochDay: 20000,
          targetEpochDay: 20140,
        ),
      );
      // Header text and chart are published from one immutable scope result;
      // no chart-only financial calculation is allowed.
      expect(resolved.chartSeries, series);
      expect(resolved.point, series.points.last);
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

      // HTML sparse series contains meaningful active dates only; 199 and
      // 701 are excluded by the inclusive range before daily aggregation.
      expect(series.points.map((point) => point.epochDay), <int>[11, 12]);
      expect(series.points[0].expense!.dailyAmount, 200);
      expect(series.points[1].expense!.dailyAmount, 700);
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
