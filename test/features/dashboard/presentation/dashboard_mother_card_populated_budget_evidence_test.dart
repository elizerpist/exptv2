import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_pager.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_rail_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';

import '../../../support/dashboard_render_resources.dart';

void main() {
  const stage = String.fromEnvironment('MOTHER_CARD_BUDGET_EVIDENCE');
  testWidgets('populated Budget distribution intermediate evidence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await prepareDashboardTestRenderResources();
    final categories = ValueNotifier<List<FluviCategory>>([
      _category('food', 'Food', 'color_01'),
      _category('rent', 'Rent', 'color_02'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(_visible());
    final snapshot = _budgetSnapshot();
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => snapshot,
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
    );
    final bundle = DashboardBudgetCategoryDistributionProjector.project(
      snapshot: snapshot,
      categories: categories.value,
      period: const BudgetLimitPeriod.month(2026, 1),
    );
    final drawables = ValueNotifier<DashboardBudgetDistributionDrawableFrame?>(
      DashboardBudgetDistributionDrawableFrame(
        semanticBundle: bundle,
        visualBank: DashboardBudgetCategoryDistributionVisualBank.prepare(
          semanticBundle: bundle,
        ),
        analysisBank: DashboardBudgetSecondaryAnalysisBank.prepare(
          snapshot: snapshot,
          scope: const MonthScope(YearMonth(year: 2026, month: 1)),
          logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
        ),
      ),
    );
    final rail = BudgetTargetAvatarRailController();
    final pages = BudgetDistributionPageController();
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);
    addTearDown(presentation.dispose);
    addTearDown(drawables.dispose);
    addTearDown(rail.dispose);
    addTearDown(pages.dispose);
    final progressSamples = stage == 'phase3-shadow-avatar'
        ? const <double>[
            0,
            .02,
            .05,
            .10,
            .20,
            .35,
            .50,
            .65,
            .80,
            .95,
            1,
          ]
        : const <double>[0, .20, .35, .50, .65, .80, 1];
    for (final progress in progressSamples) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Inter'),
          home: Scaffold(
            backgroundColor: const Color(0xffe9edf6),
            body: RepaintBoundary(
              key: const ValueKey('populated-budget'),
              child: SizedBox(
                width: 412,
                height: 700,
                child: Stack(
                  children: [
                    BudgetDashboardCoreSurface(
                      avatarContentStyle: BudgetAvatarContentStyle.avatarRail,
                      presentation: DashboardCoreModePresentation(
                        geometry: DashboardGeometryResolver.resolve(
                          metrics: DashboardLayoutMetrics.reference,
                          mode: DashboardModeSpec.budget,
                          collapseProgress: progress * 180,
                          isRailExpanded: false,
                          hasPhysicalRail: false,
                        ),
                        palette: DashboardModePaletteResolver.resolve(
                          DashboardModeSpec.budget,
                        ),
                      ),
                      presentationController: presentation,
                      categoryCollection: categories,
                      distributionDrawables: drawables,
                      avatarRailController: rail,
                      distributionPageController: pages,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (progress == 0) {
        expect(
          find.byKey(const ValueKey('budget-distribution-pager')),
          findsOneWidget,
        );
        expect(find.text('Kategóriák eloszlása'), findsOneWidget);
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('populated-budget')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          'docs/superpowers/evidence/2026-10-24-shared-motion/$stage-populated-budget-${(progress * 100000).round()}.png',
        );
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  }, skip: stage.isEmpty);
}

FluviCategory _category(String id, String title, String colorId) =>
    FluviCategory(
      id: id,
      name: title,
      colorId: colorId,
      iconId: 'icon_01',
      isSystemUncategorized: false,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );

PreparedBudgetLimitSnapshot _budgetSnapshot() => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  incomeBank: _budgetBank(const <String>[], const <int>[0]),
  expenseBank: _budgetBank(
    const <String>['food', 'rent'],
    const <int>[100, 60, 40],
  ),
);

PreparedBudgetLimitDirectionBank _budgetBank(
  List<String> ids,
  List<int> month,
) {
  final count = ids.length + 1;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * count,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  for (var handle = 0; handle < count; handle += 1) {
    cells[2 * count + handle] = PreparedBudgetLimitCell(
      actualScaled100: month[handle],
      limitScaled100: null,
    );
  }
  return PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: ids,
    cells: cells,
  );
}

DashboardVisibleFrame _visible() {
  const timeScope = MonthScope(YearMonth(year: 2026, month: 1));
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: timeScope,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: 7,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 7,
      groups: const [],
      entryCount: 0,
      nextCursor: null,
      direction: LedgerDirection.expense,
    ),
    presentationDigest: 1,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: prepared.parentQueryKey,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: 'January',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
  );
}
