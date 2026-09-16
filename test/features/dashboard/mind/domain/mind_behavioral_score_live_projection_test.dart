import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_live_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';

void main() {
  const range = QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 1000,
    lowerScaled100: 1,
    upperScaled100: 1000,
  );
  const projectionIdentity = MindBehavioralScoreIdentity(
    upstreamScopeKey: 'expense|all|category:food',
    indexGeneration: 1,
    coreRevision: 9,
    direction: LedgerDirection.expense,
  );

  test(
    'MBS-01 live publication retargets only its installed score universe',
    () {
      final live = MindBehavioralScoreLiveProjection();
      addTearDown(live.dispose);
      final projection = MindBehavioralScoreProjection.build(
        identity: projectionIdentity,
        contributions: const <MindBehavioralScoreContribution>[
          MindBehavioralScoreContribution(
            bookedLocalEpochDay: 100,
            amountMinor: 200,
          ),
        ],
      );
      live.install(
        projection: projection,
        identity: const MindBehavioralScorePublicationIdentity(
          projection: projectionIdentity,
          targetEpochDay: 100,
          navigationEpoch: 3,
        ),
        range: range,
      );
      final published = live.publishTarget(
        expectedProjectionIdentity: projectionIdentity,
        targetEpochDay: 101,
        navigationEpoch: 4,
        range: range,
      );

      expect(published, isTrue);
      expect(live.value!.point.epochDay, 101);
      expect(live.identity!.navigationEpoch, 4);
      expect(live.publicationCount, 2);
    },
  );

  test('MBS-01 stale score publication cannot resurrect an old scope', () {
    final live = MindBehavioralScoreLiveProjection();
    addTearDown(live.dispose);
    final projection = MindBehavioralScoreProjection.build(
      identity: projectionIdentity,
      contributions: const <MindBehavioralScoreContribution>[],
    );
    live.install(
      projection: projection,
      identity: const MindBehavioralScorePublicationIdentity(
        projection: projectionIdentity,
        targetEpochDay: 100,
        navigationEpoch: 3,
      ),
      range: range,
    );

    final accepted = live.publishPreview(
      expectedIdentity: const MindBehavioralScorePublicationIdentity(
        projection: projectionIdentity,
        targetEpochDay: 99,
        navigationEpoch: 2,
      ),
      range: range,
    );

    expect(accepted, isFalse);
    expect(live.value!.point.epochDay, 100);
    expect(live.stalePublicationRejectCount, 1);
  });

  test(
    'MBS-01 identical score semantics do not emit a ticker-like rebuild',
    () {
      final live = MindBehavioralScoreLiveProjection();
      addTearDown(live.dispose);
      final projection = MindBehavioralScoreProjection.build(
        identity: projectionIdentity,
        contributions: const <MindBehavioralScoreContribution>[],
      );
      const identity = MindBehavioralScorePublicationIdentity(
        projection: projectionIdentity,
        targetEpochDay: 100,
        navigationEpoch: 3,
      );
      live.install(projection: projection, identity: identity, range: range);
      var listenerCalls = 0;
      live.addListener(() => listenerCalls += 1);

      expect(
        live.publishTarget(
          expectedProjectionIdentity: projectionIdentity,
          targetEpochDay: 100,
          navigationEpoch: 3,
          range: range,
        ),
        isTrue,
      );
      expect(listenerCalls, 0);
      expect(live.publicationCount, 1);
    },
  );
}
