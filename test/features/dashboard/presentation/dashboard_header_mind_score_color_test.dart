import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_mind_score_color.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_header_trend_visual_kernel.dart';
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

  test('Mind Traffic Color Lab selection changes only the visual palette', () {
    final current = MindHeaderScoreWindowSampler.sample(
      score: 50,
      windowWidthPercent: 28,
      palette: MindHeaderScorePalette.current,
    );
    final traffic = MindHeaderScoreWindowSampler.sample(
      score: 50,
      windowWidthPercent: 28,
      palette: MindHeaderScorePalette.trafficColorLab,
    );

    expect(current.palette, MindHeaderScorePalette.current);
    expect(traffic.palette, MindHeaderScorePalette.trafficColorLab);
    expect(traffic.centerPercent, current.centerPercent);
    expect(traffic.windowWidthPercent, current.windowWidthPercent);
    expect(traffic.colorMid, isNot(current.colorMid));
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

  test('Mind palette selector preserves score identity and frame data', () {
    final visual = DashboardHeaderVisualController(vsync: const TestVSync());
    final score = ValueNotifier<MindBehavioralScoreFrame?>(scoreFrame(75));
    final policy = DashboardMindHeaderColorPolicy(
      tuning: visual.tuning,
      score: score,
    );
    addTearDown(() {
      policy.dispose();
      score.dispose();
      visual.dispose();
    });

    final before = policy.value;
    final ticker = visual.tickerIdentity;
    visual.selectMindHeaderPalette(MindHeaderScorePalette.trafficColorLab);

    expect(
      policy.value.mindScoreWindow!.palette,
      MindHeaderScorePalette.trafficColorLab,
    );
    expect(policy.value.mindScoreWindow!.centerPercent, 75);
    expect(score.value!.point.score, 75);
    expect(policy.value.colors, isNot(before.colors));
    expect(visual.tickerIdentity, same(ticker));
  });

  testWidgets('Mind Header foreground frame changes text without score work', (
    tester,
  ) async {
    final visual = DashboardHeaderVisualController(vsync: tester)
      ..selectEffect(DashboardHeaderEffectId.staticEffect);
    final header = ValueNotifier<DashboardHeaderVisualFrame>(
      const DashboardHeaderVisualFrame(
        colors: <Color>[Colors.red, Colors.red],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Colors.red,
        colorB: Colors.red,
        foregroundTextColor: Colors.black,
        chartColor: Colors.white,
      ),
    );
    final score = ValueNotifier<MindBehavioralScoreFrame?>(scoreFrame(75));
    final mode = DashboardCoreModePresentation(
      geometry: DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.mind,
        collapseProgress: 0,
        isRailExpanded: false,
      ),
      palette: DashboardModePaletteResolver.resolve(DashboardModeSpec.mind),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MindDashboardCoreSurface(
            presentation: mode,
            behavioralScore: score,
            headerVisualController: visual,
            headerVisualFrame: header,
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('mind-header-score-text')),
          )
          .style!
          .color,
      Colors.black,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('mind-header-score-text')),
          )
          .style!
          .fontFamily,
      'Roboto',
    );
    final mindScore = tester.widget<Text>(
      find.byKey(const ValueKey<String>('mind-header-score-text')),
    );
    expect(mindScore.style?.fontSize, 19);
    expect(mindScore.style?.height, .96);
    expect(mindScore.style?.letterSpacing, -.76);
    expect(mindScore.style?.fontWeight, FontWeight.w900);
    final mindHeader = tester.getRect(
      find.byKey(const ValueKey<String>('dashboard-core-mode-mind-header')),
    );
    final mindScoreTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey<String>('mind-header-score-text')),
    );
    expect(
      mindScoreTopLeft.dx,
      closeTo(mindHeader.left + DashboardHeaderTrendChartStyle.detailLeft, .01),
    );
    expect(
      mindScoreTopLeft.dy,
      closeTo(mindHeader.top + DashboardHeaderTrendChartStyle.detailTop, .01),
    );
    header.value = const DashboardHeaderVisualFrame(
      colors: <Color>[Colors.red, Colors.red],
      stops: <double>[0, 1],
      opacity: 1,
      colorA: Colors.red,
      colorB: Colors.red,
      foregroundTextColor: Colors.black,
      chartColor: Colors.white,
      showsHeaderModeLabelAboveValue: true,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('mind-header-mode-label')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('mind-header-score-text')),
          )
          .dy,
      closeTo(
        mindHeader.top +
            DashboardHeaderTrendChartStyle.detailTop +
            DashboardHeaderTrendChartLayout.modeLabelReserve,
        .01,
      ),
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey<String>('dashboard-core-mode-mind-header')),
      ),
      mindHeader,
    );
    final before = score.value;
    header.value = const DashboardHeaderVisualFrame(
      colors: <Color>[Colors.red, Colors.red],
      stops: <double>[0, 1],
      opacity: 1,
      colorA: Colors.red,
      colorB: Colors.red,
      foregroundTextColor: Colors.white,
      chartColor: Colors.black,
    );
    await tester.pump();
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('mind-header-score-text')),
          )
          .style!
          .color,
      Colors.white,
    );
    header.value = const DashboardHeaderVisualFrame(
      colors: <Color>[Colors.red, Colors.red],
      stops: <double>[0, 1],
      opacity: 1,
      colorA: Colors.red,
      colorB: Colors.red,
      foregroundTextColor: Color(0xD114213A),
      chartColor: Colors.black,
      typography: FluviTypographyProfile.colorLab,
    );
    await tester.pump();
    final colorLabScore = tester.widget<Text>(
      find.byKey(const ValueKey<String>('mind-header-score-text')),
    );
    expect(colorLabScore.style!.color, const Color(0xD114213A));
    expect(colorLabScore.style!.fontFamily, 'FluviColorLabInter');
    expect(score.value, same(before));
    await tester.pumpWidget(const SizedBox.shrink());
    visual.dispose();
    header.dispose();
    score.dispose();
  });
}
