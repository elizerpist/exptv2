import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_mind_score_color.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const range = QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 1000,
    lowerScaled100: 1,
    upperScaled100: 1000,
  );

  MindBehavioralScoreFrame scoreFrame(double score) => MindBehavioralScoreFrame(
    identity: const MindBehavioralScoreIdentity(
      upstreamScopeKey: 'expense|all',
      indexGeneration: 1,
      coreRevision: 1,
      direction: LedgerDirection.expense,
    ),
    range: range,
    point: MindBehavioralScorePoint(
      epochDay: 20000,
      score: score,
      noSignal: false,
    ),
  );

  test('MBS-05 traffic scale anchors and interpolation are deterministic', () {
    expect(MindHeaderTrafficLightScale.sample(0), const Color(0xffdc2626));
    expect(MindHeaderTrafficLightScale.sample(18), const Color(0xffef4444));
    expect(MindHeaderTrafficLightScale.sample(40), const Color(0xfff87171));
    expect(MindHeaderTrafficLightScale.sample(54), const Color(0xfffbbf24));
    expect(MindHeaderTrafficLightScale.sample(66), const Color(0xff4ade80));
    expect(MindHeaderTrafficLightScale.sample(84), const Color(0xff22c55e));
    expect(MindHeaderTrafficLightScale.sample(100), const Color(0xff16a34a));
    expect(
      MindHeaderTrafficLightScale.sample(25),
      MindHeaderTrafficLightScale.sample(25),
    );
  });

  test(
    'MBS-05 score window independently clamps both edges without shifting center',
    () {
      final low = MindHeaderScoreWindowSampler.sample(
        score: 0,
        windowWidthPercent: 100,
      );
      expect(low.centerPercent, 0);
      expect(low.leftSamplePercent, 0);
      expect(low.rightSamplePercent, 50);

      final high = MindHeaderScoreWindowSampler.sample(
        score: 100,
        windowWidthPercent: 100,
      );
      expect(high.centerPercent, 100);
      expect(high.leftSamplePercent, 50);
      expect(high.rightSamplePercent, 100);
    },
  );

  test('MBS-05 score positions use the exact center and width contract', () {
    for (final score in <double>[0, 25, 50, 75, 100]) {
      final window = MindHeaderScoreWindowSampler.sample(
        score: score,
        windowWidthPercent: 10,
      );
      expect(window.centerPercent, score);
      expect(window.colorMid, MindHeaderTrafficLightScale.sample(score));
    }
    expect(
      MindHeaderScoreWindowSampler.sample(
        score: 50,
        windowWidthPercent: 28,
      ).windowWidthPercent,
      28,
    );
  });

  test(
    'MBS-05 policy publishes score-window inputs independently from Budget',
    () {
      final visual = DashboardHeaderVisualController(vsync: const TestVSync());
      final score = ValueNotifier<MindBehavioralScoreFrame?>(scoreFrame(25));
      final policy = DashboardMindHeaderColorPolicy(
        tuning: visual.tuning,
        score: score,
      );
      addTearDown(() {
        policy.dispose();
        score.dispose();
        visual.dispose();
      });

      final ticker = visual.tickerIdentity;
      expect(policy.palettePublicationCount, 0);
      expect(policy.value.mindScoreWindow!.centerPercent, 25);
      expect(policy.value.mindScoreWindow!.windowWidthPercent, 28);
      expect(policy.value.budgetCoolWindow, isNull);
      expect(policy.value.budgetCategoryWindow, isNull);

      visual.setMindHeaderScoreWindowWidthPercent(100);
      expect(policy.palettePublicationCount, 1);
      expect(policy.value.mindScoreWindow!.centerPercent, 25);
      expect(policy.value.mindScoreWindow!.windowWidthPercent, 100);
      expect(visual.tuning.value.budgetCool.windowWidthPercent, 28);

      score.value = scoreFrame(75);
      expect(policy.palettePublicationCount, 2);
      expect(policy.value.mindScoreWindow!.centerPercent, 75);
      expect(policy.value.mindScoreWindow!.windowWidthPercent, 100);
      expect(visual.tickerIdentity, same(ticker));
    },
  );
}
