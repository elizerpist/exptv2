import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_repository.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_limit_edit_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_scope_analysis.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

const _defaultAsOfDate = LocalDate(year: 2026, month: 1, day: 10);

void main() {
  test(
    'semantic target and direction ticks bind dense header cells immediately',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final snapshot = _snapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: _defaultAsOfDate,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      final preparedItems = presentation.value.items;
      expect(presentation.value.header.title, 'Budget');
      presentation.setTargetHandle(1);

      expect(presentation.value.header.displayNumeratorScaled100, 330);
      expect(presentation.value.header.limitScaled100, 660);
      expect(presentation.value.header.title, 'Food');
      expect(identical(presentation.value.items, preparedItems), isTrue);

      direction.select(TransactionDirection.income);

      // Direction-local selection has no previous Income target yet, so the
      // aggregate is restored instead of reinterpreting Expense handle 1.
      expect(presentation.value.header.displayNumeratorScaled100, 40);
      expect(presentation.value.header.limitScaled100, 80);
      expect(presentation.value.header.title, 'Összbevételi cél');
      expect(identical(presentation.value.items, preparedItems), isFalse);
      expect(presentation.value.items.first.title, 'Összbevételi cél');
    },
  );

  test(
    'one target-bound visual state keeps a partial target from inheriting a full ring',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
        _category('travel'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _handoffSnapshot,
        logicalAsOfDate: _defaultAsOfDate,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final full = presentation.value.selectedLimitVisual;
      expect(full.targetHandle, 1);
      expect(full.limitKey!.target, const FinancialLimitCategoryTarget('food'));
      expect(full.rawProgress, 1);
      expect(full.visualProgress, 1);

      presentation.setTargetHandle(2);
      final partial = presentation.value.selectedLimitVisual;
      expect(presentation.value.header.title, 'Travel');
      expect(partial.targetHandle, 2);
      expect(
        partial.limitKey!.target,
        const FinancialLimitCategoryTarget('travel'),
      );
      expect(partial.rawProgress, .25);
      expect(partial.visualProgress, .25);
      expect(partial.visualProgress, isNot(full.visualProgress));

      presentation.setTargetHandle(1);
      expect(presentation.value.selectedLimitVisual.visualProgress, 1);
      expect(presentation.value.selectedLimitVisual.targetHandle, 1);
    },
  );

  test(
    'direction-local banks keep catalogs, handles and restored selection separate',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _namedCategory('salary', 'Salary'),
        _namedCategory('rent', 'Rent'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.income,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _directionalSnapshot,
        logicalAsOfDate: _defaultAsOfDate,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      expect(presentation.value.items.map((item) => item.title), [
        'Összbevételi cél',
        'Salary',
      ]);
      presentation.setTargetHandle(1);
      expect(presentation.value.liveSelection.target.category!.id, 'salary');
      expect(presentation.value.liveSelection.visual.visualProgress, .2);

      direction.select(TransactionDirection.expense);
      expect(presentation.value.items.map((item) => item.title), [
        'Budget',
        'Rent',
      ]);
      expect(presentation.value.liveSelection.target.isAggregate, isTrue);
      presentation.setTargetHandle(1);
      // Handle 1 is now Rent, never the old Income Salary visual.
      expect(presentation.value.liveSelection.target.category!.id, 'rent');
      expect(presentation.value.liveSelection.visual.visualProgress, .8);

      direction.select(TransactionDirection.income);
      expect(presentation.value.liveSelection.target.category!.id, 'salary');
      expect(presentation.value.liveSelection.visual.visualProgress, .2);
      direction.select(TransactionDirection.expense);
      expect(presentation.value.liveSelection.target.category!.id, 'rent');
      expect(
        identical(
          presentation.value.liveSelection.visual,
          presentation.value.selectedLimitVisual,
        ),
        isTrue,
      );
    },
  );

  test('non-positive limits publish no chrome and never a placeholder arc', () {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('food'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _noLimitSnapshot,
      logicalAsOfDate: _defaultAsOfDate,
    );
    addTearDown(presentation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    expect(presentation.value.header.limitScaled100, isNull);
    expect(
      presentation.value.selectedLimitVisual.paintsProgressChrome,
      isFalse,
    );
    expect(presentation.value.selectedLimitVisual.visualProgress, 0);
  });

  test(
    'a Day child retains its Month limit key while daily data stays separately prepared',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(
        _visibleFrame(
          scope: const DayScope(LocalDate(year: 2026, month: 1, day: 2)),
        ),
      );
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _dayAwareSnapshot,
        logicalAsOfDate: _defaultAsOfDate,
      );
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(presentation.dispose);

      presentation.setTargetHandle(1);

      expect(presentation.value.header.displayNumeratorScaled100, 4);
      expect(presentation.value.header.displayDenominatorScaled100, 32);
      expect(presentation.value.header.limitScaled100, 1000);
      expect(
        presentation.value.header.limitKey!.period,
        const FinancialLimitMonthOverridePeriod(2026, 1),
      );
    },
  );

  test(
    'a Day Budget publishes daily pace while preserving the monthly edit actual',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(
        _visibleFrame(
          scope: const DayScope(LocalDate(year: 2026, month: 1, day: 2)),
        ),
      );
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _dayAwareSnapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(presentation.dispose);

      presentation.setTargetHandle(1);
      final day = presentation.value.liveSelection;

      // DAY Header is average actual spend/day over allowed spend/day. The
      // month-end forecast stays available as a secondary calculation only.
      expect(day.displayNumeratorScaled100, 4);
      expect(day.displayDenominatorScaled100, 32);
      expect(day.monthlyLimitScaled100, 1000);
      expect(day.canonicalActualScaled100ForLimitEdit, 999);
      expect(day.monthEndProjection!.monthToDateActualScaled100, 42);
      expect(day.monthEndProjection!.actualDailyAverageScaled100, 4);
      expect(day.monthEndProjection!.allowedDailyAverageScaled100, 32);
      expect(day.monthEndProjection!.paceRatio, 42 * 31 / (10 * 1000));
      expect(day.monthEndProjection!.projectedMonthEndScaled100, 130);
      expect(
        day.visual.chromeGeometry,
        BudgetLimitProgressChromeGeometry.verticalProjection,
      );
      expect(day.visual.rawProgress, 42 * 31 / (10 * 1000));
      expect(day.visual.visualProgress, closeTo(.09765, 1e-9));
      expect(day.limitEditContext!.actualScaled100, 999);
      expect(
        day.limitEditContext!.key.period,
        const FinancialLimitMonthOverridePeriod(2026, 1),
      );

      visible.value = _visibleFrame(
        scope: const DayScope(LocalDate(year: 2026, month: 1, day: 19)),
      );
      final otherDay = presentation.value.liveSelection;
      expect(otherDay.displayNumeratorScaled100, 4);
      expect(otherDay.displayDenominatorScaled100, 32);
      expect(otherDay.monthEndProjection!.key, day.monthEndProjection!.key);

      visible.value = _visibleFrame(
        scope: const MonthScope(YearMonth(year: 2026, month: 1)),
      );
      final month = presentation.value.liveSelection;
      expect(month.displayNumeratorScaled100, 999);
      expect(month.canonicalActualScaled100ForLimitEdit, 999);
      expect(
        month.visual.chromeGeometry,
        BudgetLimitProgressChromeGeometry.circular,
      );
      expect(month.limitEditContext!.key, day.limitEditContext!.key);
    },
  );

  test(
    'a Day optimistic monthly-limit edit updates only the pace gauge',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(
        _visibleFrame(
          scope: const DayScope(LocalDate(year: 2026, month: 1, day: 2)),
        ),
      );
      late final DashboardBudgetPresentationController presentation;
      final edits = DashboardBudgetLimitEditController(
        repository: const _NoReadFinancialLimitRepository(),
        isKeyCurrent: (key) => presentation.value.header.limitKey == key,
      );
      presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _dayAwareSnapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
        limitEditController: edits,
      );
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(edits.dispose);
      addTearDown(presentation.dispose);

      presentation.setTargetHandle(1);
      final before = presentation.value.liveSelection;
      final session = edits.startEdit(before.limitEditContext!)!;
      edits.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 100,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.drag,
      );
      final after = presentation.value.liveSelection;

      expect(after.limitKey, before.limitKey);
      expect(after.displayNumeratorScaled100, before.displayNumeratorScaled100);
      expect(
        after.canonicalActualScaled100ForLimitEdit,
        before.canonicalActualScaled100ForLimitEdit,
      );
      expect(after.limitScaled100, 1100);
      expect(
        after.monthEndProjection!.key,
        isNot(before.monthEndProjection!.key),
        reason: 'The limit-dependent forecast presentation has a new epoch.',
      );
      expect(after.visual.rawProgress, 42 * 31 / (10 * 1100));
      expect(after.visual.visualProgress, (42 * 31 / (10 * 1100)) * .75);
    },
  );

  test('99 percent visual state cannot be published as a full ring', () {
    const key = FinancialLimitKey(
      direction: FinancialLimitDirection.expense,
      target: FinancialLimitCategoryTarget('food'),
      period: FinancialLimitMonthOverridePeriod(2026, 1),
    );
    final state = BudgetCategoryAvatarSelectedLimitVisualState.available(
      targetHandle: 1,
      limitKey: key,
      displayNumeratorScaled100: 99,
      displayDenominatorScaled100: 100,
    );

    expect(state.rawProgress, .99);
    expect(state.visualProgress, .99);
    expect(state.visualProgress, isNot(1));
  });

  test('a raw progress below one cannot round into a full ring', () {
    const key = FinancialLimitKey(
      direction: FinancialLimitDirection.expense,
      target: FinancialLimitCategoryTarget('food'),
      period: FinancialLimitMonthOverridePeriod(2026, 1),
    );
    final state = BudgetCategoryAvatarSelectedLimitVisualState.available(
      targetHandle: 1,
      limitKey: key,
      displayNumeratorScaled100: 9999,
      displayDenominatorScaled100: 10000,
    );

    expect(state.rawProgress, .9999);
    expect(
      state.visualProgress,
      isNot(1),
      reason: 'A visual full ring is valid only for rawProgress >= 1.',
    );
  });

  test('an out-of-window period fails closed without a repair path', () {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('food'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(
      _visibleFrame(year: 2030),
    );
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _snapshot,
      logicalAsOfDate: _defaultAsOfDate,
    );
    addTearDown(presentation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    expect(presentation.value.header.isAvailable, isFalse);
    expect(presentation.value.header.displayNumeratorScaled100, isNull);
  });

  test(
    'time-plane semantic ticks bind retained dense cells without rebuilding targets',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final snapshot = _snapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: _defaultAsOfDate,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final items = presentation.value.items;
      expect(
        presentation.value.header.displayNumeratorScaled100,
        330,
      ); // month/food

      visible.value = _visibleFrame(scope: const YearScope(2026));
      expect(
        presentation.value.header.displayNumeratorScaled100,
        310,
      ); // year/food
      expect(identical(presentation.value.items, items), isTrue);

      visible.value = _visibleFrame(scope: const AllTimeScope());
      expect(
        presentation.value.header.displayNumeratorScaled100,
        isNull,
      ); // no completed calendar month exists before the logical as-of date
      expect(identical(presentation.value.items, items), isTrue);
    },
  );

  test('YEAR is a twelve-month resolved analysis with no annual limit key', () {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('food'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(
      _visibleFrame(scope: const YearScope(2026)),
    );
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _yearScopeSnapshot,
      logicalAsOfDate: _defaultAsOfDate,
    );
    addTearDown(presentation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    presentation.setTargetHandle(1);
    final selection = presentation.value.liveSelection;
    final analysis = selection.scopeAnalysis! as DashboardBudgetYearAnalysis;

    expect(selection.limitKey, isNull);
    expect(presentation.value.header.limitScaled100, 1200);
    expect(presentation.value.header.displayNumeratorScaled100, 780);
    expect(analysis.monthlyActualsScaled100, hasLength(12));
    expect(analysis.monthlyResolvedLimitsScaled100, hasLength(12));
    expect(
      selection.visual.chromeGeometry,
      BudgetLimitProgressChromeGeometry.annualSegments,
    );
    expect(selection.visual.annualSegments, hasLength(12));
    expect(
      selection.visual.annualSegments[0].health,
      BudgetProgressRingAnnualSegmentHealth.healthy,
    );
    expect(
      selection.visual.annualSegments[1].health,
      BudgetProgressRingAnnualSegmentHealth.neutral,
    );
    expect(
      presentation.value.header.editContext,
      isA<DashboardBudgetYearLimitEditContext>(),
    );
  });

  test(
    'SUM is a completed-month average over the persisted base denominator',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(
        _visibleFrame(scope: const AllTimeScope()),
      );
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _typicalMonthSnapshot,
        logicalAsOfDate: _defaultAsOfDate,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final selection = presentation.value.liveSelection;
      final analysis =
          selection.scopeAnalysis! as DashboardBudgetTypicalMonthAnalysis;

      expect(presentation.value.header.displayNumeratorScaled100, 25);
      expect(presentation.value.header.limitScaled100, 200);
      expect(analysis.canonicalActualScaled100ForLimitEdit, isNull);
      expect(
        selection.limitKey!.period,
        const FinancialLimitBaseMonthlyPeriod(),
      );
      expect(
        selection.visual.chromeGeometry,
        BudgetLimitProgressChromeGeometry.typicalMarker,
      );
      expect(selection.visual.typicalMarkerPosition, .125);
    },
  );

  test(
    'header projects the exact visible analysis scope with its Budget amount',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(
        _visibleFrame(
          scope: const DayScope(LocalDate(year: 2026, month: 1, day: 19)),
        ),
      );
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _dayAwareSnapshot,
        logicalAsOfDate: _defaultAsOfDate,
      );
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(presentation.dispose);

      expect(presentation.value.header.analysisScopeLabel, '2026. január 19.');

      visible.value = _visibleFrame(
        scope: const MonthScope(YearMonth(year: 2026, month: 1)),
      );
      expect(presentation.value.header.analysisScopeLabel, '2026. január');
      visible.value = _visibleFrame(scope: const YearScope(2026));
      expect(presentation.value.header.analysisScopeLabel, '2026');
      visible.value = _visibleFrame(scope: const AllTimeScope());
      expect(presentation.value.header.analysisScopeLabel, 'Összesen');
    },
  );

  test(
    'one optimistic effective limit drives the selected header atomically',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final snapshot = _snapshot();
      late final DashboardBudgetPresentationController presentation;
      final edits = DashboardBudgetLimitEditController(
        repository: const _NoReadFinancialLimitRepository(),
        isKeyCurrent: (key) => presentation.value.header.limitKey == key,
      );
      presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: _defaultAsOfDate,
        limitEditController: edits,
      );
      addTearDown(presentation.dispose);
      addTearDown(edits.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final items = presentation.value.items;
      final session = edits.startEdit(
        presentation.value.header.limitEditContext!,
      )!;
      edits.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 100000,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.drag,
      );

      expect(presentation.value.header.title, 'Food');
      expect(presentation.value.header.displayNumeratorScaled100, 330);
      expect(presentation.value.header.limitScaled100, 100660);
      expect(presentation.value.selectedLimitVisual.targetHandle, 1);
      expect(
        presentation.value.selectedLimitVisual.displayDenominatorScaled100,
        100660,
      );
      expect(
        presentation.value.selectedLimitVisual.visualProgress,
        330 / 100660,
      );
      expect(identical(presentation.value.items, items), isTrue);
    },
  );

  test('a positive active overlay replaces the prepared limit', () {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('food'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
    late final DashboardBudgetPresentationController presentation;
    final edits = DashboardBudgetLimitEditController(
      repository: const _NoReadFinancialLimitRepository(),
      isKeyCurrent: (key) => presentation.value.header.limitKey == key,
    );
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _confirmedLimitSnapshot,
      logicalAsOfDate: _defaultAsOfDate,
      limitEditController: edits,
    );
    addTearDown(presentation.dispose);
    addTearDown(edits.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    presentation.setTargetHandle(1);
    final session = edits.startEdit(
      presentation.value.header.limitEditContext!,
    )!;
    edits.applySemanticTick(
      session,
      direction: 1,
      amountStepScaled100: 100000,
      tickCount: 1,
      source: DashboardBudgetLimitEditSource.drag,
    );

    expect(presentation.value.header.limitScaled100, 88475000);
    expect(
      presentation.value.selectedLimitVisual.displayDenominatorScaled100,
      88475000,
    );
  });

  test('without an overlay the confirmed prepared limit remains visible', () {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('food'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _confirmedLimitSnapshot,
      logicalAsOfDate: _defaultAsOfDate,
    );
    addTearDown(presentation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    presentation.setTargetHandle(1);

    expect(presentation.value.header.limitScaled100, 88375000);
    expect(
      presentation.value.selectedLimitVisual.displayDenominatorScaled100,
      88375000,
    );
  });

  test(
    'first optimistic limit tick updates header and ring together',
    () async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      late final DashboardBudgetPresentationController presentation;
      final edits = DashboardBudgetLimitEditController(
        repository: const _NoReadFinancialLimitRepository(),
        isKeyCurrent: (key) => presentation.value.header.limitKey == key,
      );
      presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _noLimitSnapshot,
        logicalAsOfDate: _defaultAsOfDate,
        limitEditController: edits,
      );
      addTearDown(presentation.dispose);
      addTearDown(edits.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      expect(presentation.value.header.limitScaled100, isNull);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isFalse,
      );

      final session = edits.startEdit(
        presentation.value.header.limitEditContext!,
      )!;
      edits.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 100,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.drag,
      );
      expect(presentation.value.header.limitScaled100, 100);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isTrue,
      );
      expect(presentation.value.selectedLimitVisual.visualProgress, .42);
    },
  );
}

final class _NoReadFinancialLimitRepository
    implements FinancialLimitRepository {
  const _NoReadFinancialLimitRepository();

  @override
  Future<bool> delete(FinancialLimitKey key) =>
      Future<bool>.error(StateError('not used'));

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) =>
      Future<FinancialLimit?>.error(StateError('not used'));

  @override
  Future<List<FinancialLimit>> list() =>
      Future<List<FinancialLimit>>.error(StateError('not used'));

  @override
  Future<FinancialLimit> upsert(FinancialLimitKey key, int amountScaled100) =>
      Future<FinancialLimit>.error(StateError('not used'));

  @override
  Future<List<FinancialLimit>> upsertBatch(
    List<FinancialLimitMutation> values,
  ) => Future<List<FinancialLimit>>.error(StateError('not used'));
}

FluviCategory _category(String id) => FluviCategory(
  id: id,
  name: id == 'travel' ? 'Travel' : 'Food',
  colorId: 'color_01',
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

FluviCategory _namedCategory(String id, String name) => FluviCategory(
  id: id,
  name: name,
  colorId: 'color_01',
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

PreparedBudgetLimitSnapshot _snapshot() => _snapshotFromLegacy(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  orderedCategoryIds: const <String>['food'],
  cells: List<PreparedBudgetLimitCell>.generate(
    56,
    (index) => PreparedBudgetLimitCell(
      actualScaled100: index * 10,
      limitScaled100: index * 20,
    ),
  ),
);

PreparedBudgetLimitSnapshot _yearScopeSnapshot() {
  // One year × two handles: slice 0 is SUM, 1 is YEAR, then Jan–Dec.
  final cells = List<PreparedBudgetLimitCell>.filled(
    28,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  var annualActual = 0;
  for (var month = 1; month <= 12; month += 1) {
    final actual = month * 10;
    annualActual += actual;
    final slice = 2 + month - 1;
    cells[slice * 2 + 1] = PreparedBudgetLimitCell(
      actualScaled100: actual,
      limitScaled100: 100,
    );
  }
  cells[1 * 2 + 1] = PreparedBudgetLimitCell(
    actualScaled100: annualActual,
    limitScaled100: 1200,
  );
  cells[1] = const PreparedBudgetLimitCell(
    actualScaled100: 0,
    limitScaled100: 100,
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food'],
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

PreparedBudgetLimitSnapshot _typicalMonthSnapshot() {
  // Two years × two handles: SUM, two YEAR cells, then 24 MONTH cells.
  final cells = List<PreparedBudgetLimitCell>.filled(
    54,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // SUM holds the base monthly limit. The 2025 January–December bank has
  // 100 + 0 + 200 and then zero months, so the historical average is 25.
  cells[1] = const PreparedBudgetLimitCell(
    actualScaled100: 300,
    limitScaled100: 200,
    limitSource: PreparedBudgetLimitSource.base,
  );
  cells[1 * 2 + 1] = const PreparedBudgetLimitCell(
    actualScaled100: 300,
    limitScaled100: 2400,
  );
  cells[3 * 2 + 1] = const PreparedBudgetLimitCell(
    actualScaled100: 100,
    limitScaled100: 200,
    limitSource: PreparedBudgetLimitSource.base,
  );
  cells[5 * 2 + 1] = const PreparedBudgetLimitCell(
    actualScaled100: 200,
    limitScaled100: 200,
    limitSource: PreparedBudgetLimitSource.base,
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food'],
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2025,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

PreparedBudgetLimitSnapshot _dayAwareSnapshot() {
  final cells = List<PreparedBudgetLimitCell>.filled(
    28,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  cells[5] = const PreparedBudgetLimitCell(
    actualScaled100: 999,
    limitScaled100: 1000,
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food'],
    cells: cells,
  );
  final januarySecond =
      DateTime.utc(2026, 1, 2).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  PreparedBudgetRhythmDirectionBank rhythm() =>
      PreparedBudgetRhythmDirectionBank.fromTargetPoints(
        targetPoints: <List<PreparedBudgetRhythmPoint>>[
          <PreparedBudgetRhythmPoint>[
            PreparedBudgetRhythmPoint(
              epochDay: januarySecond,
              actualScaled100: 42,
            ),
          ],
          <PreparedBudgetRhythmPoint>[
            PreparedBudgetRhythmPoint(
              epochDay: januarySecond,
              actualScaled100: 42,
            ),
          ],
        ],
      );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
    rhythmSnapshot: PreparedBudgetRhythmSnapshot(
      coreRevision: 7,
      incomeBank: rhythm(),
      expenseBank: rhythm(),
    ),
  );
}

PreparedBudgetLimitSnapshot _handoffSnapshot() {
  final cells = List<PreparedBudgetLimitCell>.filled(
    84,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // Expense / January / food and travel. The dense bank is
  // direction * 14 slices * 3 targets + month-1 slice offset * 3 + handle.
  cells[49] = const PreparedBudgetLimitCell(
    actualScaled100: 100,
    limitScaled100: 100,
  );
  cells[50] = const PreparedBudgetLimitCell(
    actualScaled100: 25,
    limitScaled100: 100,
  );
  return _snapshotFromLegacy(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    orderedCategoryIds: const <String>['food', 'travel'],
    cells: cells,
  );
}

PreparedBudgetLimitSnapshot _noLimitSnapshot() => _snapshotFromLegacy(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  orderedCategoryIds: const <String>['food'],
  cells: List<PreparedBudgetLimitCell>.filled(
    56,
    const PreparedBudgetLimitCell(actualScaled100: 42, limitScaled100: null),
  ),
);

PreparedBudgetLimitSnapshot _confirmedLimitSnapshot({
  int coreRevision = 7,
  int? limitScaled100 = 88375000,
}) {
  final cells = List<PreparedBudgetLimitCell>.filled(
    56,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // Expense / January / category handle 1 for a two-target direction bank.
  cells[33] = PreparedBudgetLimitCell(
    actualScaled100: 70707780,
    limitScaled100: limitScaled100,
  );
  return _snapshotFromLegacy(
    coreRevision: coreRevision,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    orderedCategoryIds: const <String>['food'],
    cells: cells,
  );
}

PreparedBudgetLimitSnapshot _directionalSnapshot() {
  List<PreparedBudgetLimitCell> cells(int actual) {
    final values = List<PreparedBudgetLimitCell>.filled(
      28,
      const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
    );
    values[5] = PreparedBudgetLimitCell(
      actualScaled100: actual,
      limitScaled100: 100,
    );
    return values;
  }

  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: PreparedBudgetLimitDirectionBank(
      orderedCategoryIds: const ['salary'],
      cells: cells(20),
    ),
    expenseBank: PreparedBudgetLimitDirectionBank(
      orderedCategoryIds: const ['rent'],
      cells: cells(80),
    ),
  );
}

PreparedBudgetLimitSnapshot _snapshotFromLegacy({
  required int coreRevision,
  required int yearWindowStart,
  required int yearWindowEndInclusive,
  required List<String> orderedCategoryIds,
  required List<PreparedBudgetLimitCell> cells,
}) {
  final yearCount = yearWindowEndInclusive - yearWindowStart + 1;
  final periodSliceCount = 1 + yearCount + yearCount * 12;
  final targetCount = orderedCategoryIds.length + 1;
  final cellsPerDirection = periodSliceCount * targetCount;
  PreparedBudgetLimitDirectionBank bankFor(LedgerDirection direction) =>
      PreparedBudgetLimitDirectionBank(
        orderedCategoryIds: orderedCategoryIds,
        cells: cells
            .skip(direction.index * cellsPerDirection)
            .take(cellsPerDirection)
            .toList(growable: false),
      );
  return PreparedBudgetLimitSnapshot(
    coreRevision: coreRevision,
    yearWindowStart: yearWindowStart,
    yearWindowEndInclusive: yearWindowEndInclusive,
    incomeBank: bankFor(LedgerDirection.income),
    expenseBank: bankFor(LedgerDirection.expense),
  );
}

DashboardVisibleFrame _visibleFrame({
  int year = 2026,
  LedgerTimeScope? scope,
  int coreRevision = 7,
}) {
  final effectiveScope = scope ?? MonthScope(YearMonth(year: year, month: 1));
  final queryScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: effectiveScope,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: queryScope,
    parentQueryKey: queryScope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: coreRevision,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: queryScope.key,
      revision: coreRevision,
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
