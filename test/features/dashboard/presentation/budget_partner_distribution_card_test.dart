import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_partner_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_ephemeral_focus_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_spending_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_partner_distribution_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_partner_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  testWidgets(
    'Partner list paints pending selection before focus acknowledgement',
    (tester) async {
      final harness = _PartnerCardHarness();
      addTearDown(harness.dispose);
      final pending = Completer<bool>();
      final calls = <String>[];
      await harness.pump(
        tester,
        onCommit: ({required partner, required source, required targetHandle}) {
          calls.add('$source:${partner.id}:$targetHandle');
          return pending.future;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey('budget-partner-distribution-row-partner-b')),
      );
      await tester.pump();

      expect(calls, <String>['partnerList:partner-b:0']);
      expect(
        find.byType(AnimatedContainer),
        findsNothing,
        reason: 'Direct Partner selection must paint its row in the tap frame.',
      );
      expect(
        find.byKey(
          const ValueKey('budget-partner-distribution-row-selected-partner-b'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-partner-distribution-clay-scene-1')),
        findsOneWidget,
        reason: 'The retained scene only changes its selected paint index.',
      );

      harness.focus.replace(
        baseScope: _scope(),
        coreRevision: 7,
        category: null,
        partner: const DashboardFocusFacet(
          id: 'partner-b',
          displayName: 'Partner B',
          colorId: 'color_01',
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('budget-partner-distribution-row-selected-partner-b'),
        ),
        findsOneWidget,
        reason: 'Authoritative acknowledgement must not flash unselected.',
      );

      pending.complete(true);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('budget-partner-distribution-row-selected-partner-b'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Partner donut uses the same immediate visual-intent path', (
    tester,
  ) async {
    final harness = _PartnerCardHarness();
    addTearDown(harness.dispose);
    final pending = Completer<bool>();
    final calls = <String>[];
    await harness.pump(
      tester,
      onCommit: ({required partner, required source, required targetHandle}) {
        calls.add('$source:${partner.id}:$targetHandle');
        return pending.future;
      },
    );

    final donut = find.byKey(
      const ValueKey('budget-partner-distribution-donut-interaction'),
    );
    await tester.tapAt(tester.getCenter(donut) + const Offset(-42, 0));
    await tester.pump();

    expect(calls, <String>['partnerPie:partner-b:0']);
    expect(
      find.byKey(
        const ValueKey('budget-partner-distribution-row-selected-partner-b'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('failed Partner focus rolls pending feedback back to authority', (
    tester,
  ) async {
    final harness = _PartnerCardHarness();
    addTearDown(harness.dispose);
    final pending = Completer<bool>();
    await harness.pump(
      tester,
      onCommit: ({required partner, required source, required targetHandle}) =>
          pending.future,
    );

    await tester.tap(
      find.byKey(const ValueKey('budget-partner-distribution-row-partner-a')),
    );
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('budget-partner-distribution-row-selected-partner-a'),
      ),
      findsOneWidget,
    );

    pending.complete(false);
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey('budget-partner-distribution-row-selected-partner-a'),
      ),
      findsNothing,
    );
  });

  testWidgets('Partner donut is exactly 90 percent of its current 150px slot', (
    tester,
  ) async {
    final harness = _PartnerCardHarness();
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onCommit: ({required partner, required source, required targetHandle}) =>
          Future<bool>.value(true),
    );

    final donut = find.byKey(const ValueKey('budget-distribution-donut-135'));
    expect(donut, findsOneWidget);
    expect(tester.getRect(donut).width, 135);
    expect(tester.getRect(donut).height, 135);
  });

  testWidgets(
    'Partner layout reserves a forty dp Rhythm plot before allocating the '
    'smaller donut and legend',
    (tester) async {
      final harness = _PartnerCardHarness();
      addTearDown(harness.dispose);
      await harness.pump(
        tester,
        height: 300,
        includeRhythm: true,
        onCommit:
            ({required partner, required source, required targetHandle}) =>
                Future<bool>.value(true),
      );

      final plot = find.byKey(const ValueKey('spending-rhythm-plot-lane'));
      final donut = find.byKey(const ValueKey('budget-distribution-donut-120'));
      expect(plot, findsOneWidget);
      expect(tester.getSize(plot).height, 40);
      expect(donut, findsOneWidget);
      expect(tester.getSize(donut).height, 120);
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('partner-spending-rhythm-chart')),
            )
            .height,
        62,
      );
    },
  );

  testWidgets(
    'Partner layout keeps a 110dp donut beside the 40dp Rhythm plot in the '
    '217dp reference Card2',
    (tester) async {
      final harness = _PartnerCardHarness();
      addTearDown(harness.dispose);
      await harness.pump(
        tester,
        height: 217,
        includeRhythm: true,
        onCommit:
            ({required partner, required source, required targetHandle}) =>
                Future<bool>.value(true),
      );

      expect(
        tester
            .getSize(find.byKey(const ValueKey('spending-rhythm-plot-lane')))
            .height,
        40,
      );
      expect(
        find.byKey(const ValueKey('budget-distribution-donut-110')),
        findsOneWidget,
        reason:
            'The reference Card2 has enough room for the readable 110dp '
            'Partner donut after Rhythm receives its fixed 40dp plot lane.',
      );
    },
  );

  testWidgets(
    'Partner layout keeps the real Rhythm plot above its 32dp floor in a '
    'shorter Card2 viewport without changing outer-card geometry',
    (tester) async {
      final harness = _PartnerCardHarness();
      addTearDown(harness.dispose);
      await harness.pump(
        tester,
        height: 190,
        includeRhythm: true,
        onCommit:
            ({required partner, required source, required targetHandle}) =>
                Future<bool>.value(true),
      );

      final plot = find.byKey(const ValueKey('spending-rhythm-plot-lane'));
      expect(plot, findsOneWidget);
      expect(tester.getSize(plot).height, greaterThanOrEqualTo(32));
      expect(tester.takeException(), isNull);
    },
  );
}

final class _PartnerCardHarness {
  _PartnerCardHarness()
    : categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category(),
      ]),
      direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      ),
      visible = ValueNotifier<DashboardVisibleFrame?>(_visible()) {
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => _budgetSnapshot(),
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
    );
    final categoryBundle = DashboardBudgetCategoryDistributionProjector.project(
      snapshot: _budgetSnapshot(),
      categories: categories.value,
      period: const BudgetLimitPeriod.month(2026, 7),
    );
    final partnerBundle = DashboardBudgetPartnerDistributionProjector.project(
      snapshot: _partnerSnapshot(),
      categories: categories.value,
      period: const BudgetLimitPeriod.month(2026, 7),
    );
    drawables = ValueNotifier<DashboardBudgetDistributionDrawableFrame?>(
      DashboardBudgetDistributionDrawableFrame(
        semanticBundle: categoryBundle,
        visualBank: DashboardBudgetCategoryDistributionVisualBank.prepare(
          semanticBundle: categoryBundle,
        ),
        partnerSemanticBundle: partnerBundle,
        partnerVisualBank: DashboardBudgetPartnerDistributionVisualBank.prepare(
          semanticBundle: partnerBundle,
        ),
      ),
    );
  }

  final ValueNotifier<List<FluviCategory>> categories;
  final TransactionDirectionController direction;
  final ValueNotifier<DashboardVisibleFrame?> visible;
  final DashboardEphemeralFocusController focus =
      DashboardEphemeralFocusController();
  late final DashboardBudgetPresentationController presentation;
  late final ValueNotifier<DashboardBudgetDistributionDrawableFrame?> drawables;
  final ValueNotifier<DashboardSpendingRhythmState?> rhythm =
      ValueNotifier<DashboardSpendingRhythmState?>(
        DashboardSpendingRhythmState(
          analysis: DaySpendingRhythm(
            coreRevision: 7,
            direction: LedgerDirection.expense,
            targetHandle: 0,
            scope: const DayScope(LocalDate(year: 2026, month: 7, day: 1)),
            buckets: const <SpendingRhythmBucket>[
              SpendingRhythmBucket(
                label: '0',
                accessibilityLabel: 'Éjfél',
                actualScaled100: 10,
              ),
              SpendingRhythmBucket(
                label: '3',
                accessibilityLabel: 'Hajnal',
                actualScaled100: 20,
              ),
              SpendingRhythmBucket(
                label: '6',
                accessibilityLabel: 'Reggel',
                actualScaled100: 5,
              ),
              SpendingRhythmBucket(
                label: '9',
                accessibilityLabel: 'Délelőtt',
                actualScaled100: 0,
              ),
              SpendingRhythmBucket(
                label: '12',
                accessibilityLabel: 'Kora délután',
                actualScaled100: 0,
              ),
              SpendingRhythmBucket(
                label: '15',
                accessibilityLabel: 'Délután',
                actualScaled100: 0,
              ),
              SpendingRhythmBucket(
                label: '18',
                accessibilityLabel: 'Este',
                actualScaled100: 0,
              ),
              SpendingRhythmBucket(
                label: '21',
                accessibilityLabel: 'Késő este',
                actualScaled100: 0,
              ),
            ],
          ),
          startColorArgb: 0xffaa00ff,
          middleColorArgb: 0xffbb00ff,
          endColorArgb: 0xffcc00ff,
        ),
      );

  Future<void> pump(
    WidgetTester tester, {
    required BudgetPartnerFocusCommit onCommit,
    double height = 208,
    bool includeRhythm = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 378,
            height: height,
            child: BudgetPartnerDistributionCard(
              presentation: presentation,
              drawableFrames: drawables,
              partnerFocusCommit: onCommit,
              focusController: focus,
              rhythm: includeRhythm ? rhythm : null,
            ),
          ),
        ),
      ),
    ),
  );

  void dispose() {
    categories.dispose();
    direction.dispose();
    visible.dispose();
    presentation.dispose();
    drawables.dispose();
    rhythm.dispose();
  }
}

FluviCategory _category() => FluviCategory(
  id: 'food',
  name: 'Food',
  colorId: 'color_01',
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

PreparedBudgetLimitSnapshot _budgetSnapshot() => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  incomeBank: _budgetBank(const <String>[]),
  expenseBank: _budgetBank(const <String>['food']),
);

PreparedBudgetLimitDirectionBank _budgetBank(List<String> ids) {
  final count = ids.length + 1;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * count,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  for (var handle = 0; handle < count; handle += 1) {
    cells[8 * count + handle] = const PreparedBudgetLimitCell(
      actualScaled100: 100,
      limitScaled100: null,
    );
  }
  return PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: ids,
    cells: cells,
  );
}

PreparedBudgetPartnerDistributionSnapshot _partnerSnapshot() {
  PreparedBudgetPartnerDistributionDirectionBank bank() {
    const count = 2;
    final cells = List<PreparedBudgetPartnerDistributionCell>.filled(
      14 * count,
      const PreparedBudgetPartnerDistributionCell(
        actualScaled100: 0,
        dominantCategoryId: '',
      ),
    );
    cells[8 * count] = const PreparedBudgetPartnerDistributionCell(
      actualScaled100: 70,
      dominantCategoryId: 'food',
    );
    cells[8 * count + 1] = const PreparedBudgetPartnerDistributionCell(
      actualScaled100: 30,
      dominantCategoryId: 'food',
    );
    return PreparedBudgetPartnerDistributionDirectionBank(
      orderedPartnerIds: const <String>['partner-a', 'partner-b'],
      orderedPartnerTitles: const <String>['Partner A', 'Partner B'],
      cells: cells,
      orderedCategoryIds: const <String>['food'],
      categoryContributionOffsets: List<int>.filled(15, 0),
    );
  }

  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

CurrentLedgerQueryScope _scope() => CurrentLedgerQueryScope(
  direction: LedgerDirection.expense,
  timeScope: MonthScope(YearMonth(year: 2026, month: 7)),
);

DashboardVisibleFrame _visible() {
  final scope = _scope();
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
    childLabel: 'July',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
  );
}
