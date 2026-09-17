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

  test('MRA-06: approved perceptual traffic scale has exact anchors', () {
    expect(MindHeaderTrafficLightScale.sample(0), const Color(0xff991b1b));
    expect(MindHeaderTrafficLightScale.sample(18), const Color(0xffdc2626));
    expect(MindHeaderTrafficLightScale.sample(35), const Color(0xfff04a24));
    expect(MindHeaderTrafficLightScale.sample(48), const Color(0xfff97316));
    expect(MindHeaderTrafficLightScale.sample(58), const Color(0xfffbbf24));
    expect(MindHeaderTrafficLightScale.sample(70), const Color(0xff86d957));
    expect(MindHeaderTrafficLightScale.sample(82), const Color(0xff4ade80));
    expect(MindHeaderTrafficLightScale.sample(100), const Color(0xff15803d));
    expect(MindHeaderTrafficLightScale.sample(-1), const Color(0xff991b1b));
    expect(MindHeaderTrafficLightScale.sample(101), const Color(0xff15803d));
  });

  test(
    'MRA-06: intermediate sampling is deterministic and not encoded RGB',
    () {
      const encodedRgbMidpoint = Color(0xffe64b38);
      // 26.5 is exactly midway between #DC2626 at 18 and #F04A24 at 35.
      expect(
        MindHeaderTrafficLightScale.sample(26.5),
        isNot(encodedRgbMidpoint),
      );
      for (final interval in <(double, double)>[
        (0, 18),
        (18, 35),
        (35, 48),
        (48, 58),
        (58, 70),
        (70, 82),
        (82, 100),
      ]) {
        final midpoint = (interval.$1 + interval.$2) / 2;
        expect(
          MindHeaderTrafficLightScale.sample(midpoint),
          MindHeaderTrafficLightScale.sample(midpoint),
        );
      }
    },
  );

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
