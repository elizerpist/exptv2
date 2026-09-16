import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_projection.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  testWidgets(
    'RED MYH-01/10/11: Mind Year owns card scroll while header expansion remains available',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final expansion = _ExpansionRecorder();
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: expansion,
          showYearHeatmap: true,
        ),
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
        findsOneWidget,
      );
      final grid = tester.widget<ListView>(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
      );
      expect(grid.childrenDelegate.estimatedChildCount, isNotNull);
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('dashboard-core-mode-content-gesture-region'),
        ),
        findsNothing,
      );

      final footerBefore = tester.getRect(
        find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
      );
      await tester.drag(
        find.byKey(const ValueKey('mind-year-heatmap-scroll')),
        const Offset(0, -160),
      );
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const ValueKey('mind-year-heatmap-grid')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, greaterThan(0));
      expect(expansion.starts, 0);
      expect(
        tester.getRect(
          find.byKey(const ValueKey('mind-year-heatmap-fixed-footer')),
        ),
        footerBefore,
      );

      await tester.drag(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
        const Offset(0, 80),
      );
      await tester.pump();
      expect(expansion.starts, 1);
      expect(expansion.ends, 1);
    },
  );

  testWidgets(
    'RED MYH-01: non-Year Mind composition does not mount the annual grid',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: false,
        ),
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-grid')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('mind-year-heatmap-month-1')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('dashboard-core-mode-content-gesture-region'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'MBS-07 semantic Mind Header score updates independently from its paint lane',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.mind,
      );
      final frame = ValueNotifier<MindYearHeatmapFrame?>(_frame());
      final rangeChanges = ValueNotifier<int>(0);
      final score = ValueNotifier<MindBehavioralScoreFrame?>(_score(63));
      addTearDown(mode.dispose);
      addTearDown(frame.dispose);
      addTearDown(rangeChanges.dispose);
      addTearDown(score.dispose);

      await tester.pumpWidget(
        _HostHarness(
          mode: mode,
          frame: frame,
          rangeChanges: rangeChanges,
          expansion: _ExpansionRecorder(),
          showYearHeatmap: false,
          score: score,
        ),
      );
      expect(
        find.byKey(const ValueKey('mind-header-score-text')),
        findsOneWidget,
      );
      expect(find.text('63/100'), findsOneWidget);

      score.value = _score(27);
      await tester.pump();
      expect(find.text('27/100'), findsOneWidget);
    },
  );
}

final class _HostHarness extends StatelessWidget {
  const _HostHarness({
    required this.mode,
    required this.frame,
    required this.rangeChanges,
    required this.expansion,
    required this.showYearHeatmap,
    this.score,
  });

  final DashboardCoreModeController mode;
  final ValueNotifier<MindYearHeatmapFrame?> frame;
  final ValueNotifier<int> rangeChanges;
  final _ExpansionRecorder expansion;
  final bool showYearHeatmap;
  final ValueNotifier<MindBehavioralScoreFrame?>? score;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: DashboardLayoutMetrics.reference.contentWidth + 34,
          height: DashboardLayoutMetrics.reference.canvasHeight,
          child: DashboardCoreModeHost(
            controller: mode,
            presentationFor: (mode) => DashboardCoreModePresentation(
              geometry: DashboardGeometryResolver.resolve(
                metrics: DashboardLayoutMetrics.reference,
                mode: mode,
                collapseProgress: 0,
                isRailExpanded: false,
              ),
              palette: DashboardModePaletteResolver.resolve(mode),
            ),
            mindYearHeatmap: frame,
            mindBehavioralScore: score,
            mindYearHeatmapVisible: showYearHeatmap,
            mindQueryAmountRange: () => const QueryAmountRangeValues(
              minimumScaled100: 1,
              maximumScaled100: 1000,
              lowerScaled100: 1,
              upperScaled100: 1000,
            ),
            mindQueryAmountRangeChanges: rangeChanges,
            onMindQueryAmountRangeCommitted: (_) {},
            onVerticalExpansionStart: expansion.begin,
            onVerticalExpansionDragBy: expansion.drag,
            onVerticalExpansionEnd: expansion.end,
          ),
        ),
      ),
    ),
  );
}

final class _ExpansionRecorder {
  int starts = 0;
  int ends = 0;
  double delta = 0;

  void begin() => starts += 1;
  void drag(double value) => delta += value;
  void end() => ends += 1;
}

MindYearHeatmapFrame _frame() =>
    MindYearHeatmapProjection.build(
      identity: const MindYearHeatmapIdentity(
        upstreamScopeKey: 'expense|year:2025',
        indexGeneration: 1,
        coreRevision: 1,
        year: 2025,
        navigationEpoch: 0,
      ),
      entries: List<DashboardLedgerEntry>.generate(
        48,
        (index) => DashboardLedgerEntry(
          id: 'entry-$index',
          partnerId: 'p',
          categoryId: 'c',
          direction: 'expense',
          amountMinor: index + 1,
          bookedLocalEpochDay: LocalDate(
            year: 2025,
            month: index % 12 + 1,
            day: index % 4 + 1,
          ).epochDay,
          bookedLocalTimeMinutes: 0,
        ),
        growable: false,
      ),
    ).preview(
      const QueryAmountRangeValues(
        minimumScaled100: 1,
        maximumScaled100: 1000,
        lowerScaled100: 1,
        upperScaled100: 1000,
      ),
    );

MindBehavioralScoreFrame _score(double value) => MindBehavioralScoreFrame(
  identity: const MindBehavioralScoreIdentity(
    upstreamScopeKey: 'expense|all',
    indexGeneration: 1,
    coreRevision: 1,
    direction: LedgerDirection.expense,
  ),
  range: const QueryAmountRangeValues(
    minimumScaled100: 1,
    maximumScaled100: 1000,
    lowerScaled100: 1,
    upperScaled100: 1000,
  ),
  point: MindBehavioralScorePoint(
    epochDay: const LocalDate(year: 2025, month: 1, day: 1).epochDay,
    score: value,
    noSignal: false,
  ),
);
