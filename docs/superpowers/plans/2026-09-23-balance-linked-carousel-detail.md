# Balance linked carousel-detail implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Link the existing Balance upper carousel to Summary-reactive lower
details for Cashflow, Latest transaction, Top category, and Top partner.

**Architecture:** `DashboardCoreController` synchronously builds one bounded,
immutable `DashboardBalanceLinkedPresentation` from resident prepared
directional membership on a visible Summary frame. The existing
`CenteredCarousel` remains the sole motion owner; its selection callback writes
only Balance-surface local topic state, which selects the lower renderer.

**Tech stack:** Dart, Flutter widget tests, existing prepared dashboard index,
existing `CategoryVisualBadge`, shared `CenteredCarousel`.

## Global constraints

- Do not modify Mind, Budget, Summary physics, shared Header trend code,
  `CenteredCarousel`, motion profiles, global geometry, Query, Room or
  repositories.
- Header Compound linechart remains Header-only; lower Cashflow stays the
  current bars/step-lines card.
- Top category and Top partner use only `DashboardVisibleFrame.direction`.
- Latest list is scope-local across both directions, capped at five entries.
- Fifth carousel topic stays prototype; DAY Cashflow stays no-chart.
- Run Flutter commands in Ubuntu/proot; create the normal human APK only via
  the online workflow after the one application commit is pushed.

---

### Task 1: Write and prove the linked resident projection contract

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_balance_primary_projection.dart`
- Modify: `test/features/dashboard/application/dashboard_balance_primary_projection_test.dart`

**Interfaces:**
- Consumes: `DashboardLedgerEntry`, `LedgerTimeScope`,
  `DashboardBalancePrimaryProjection`, `LedgerDirection`.
- Produces: immutable `DashboardBalanceLinkedPresentation`, which exposes
  `cashflow`, `latestTransactions`, `topCategories`, `topPartners`,
  `selectedDirection`, and a revision/scope/direction-aware `presentationId`.

- [ ] **Step 1: Add failing pure projection tests.**

  Add a private helper with fixed provenance and concrete data:

  ```dart
  DashboardBalanceLinkedPresentation linked({
    required LedgerTimeScope scope,
    required LedgerDirection direction,
    required List<DashboardLedgerEntry> income,
    required List<DashboardLedgerEntry> expense,
  }) => DashboardBalanceLinkedProjection.build(
    identity: const DashboardBalancePrimaryIdentity(
      upstreamScopeKey: 'income:all|expense:all',
      indexGeneration: 7,
      coreRevision: 11,
    ),
    timeScope: scope,
    selectedDirection: direction,
    incomeEntries: income,
    expenseEntries: expense,
  );

  test('L4-RED: latest five are scoped and ordered across directions', () {
    final result = linked(
      scope: MonthScope(const YearMonth(year: 2026, month: 7)),
      direction: LedgerDirection.expense,
      income: <DashboardLedgerEntry>[_entry('income-mid', 7000, 2026, 7, 20)],
      expense: <DashboardLedgerEntry>[
        _entry('expense-late', 5000, 2026, 7, 28),
        _entry('expense-august', 9000, 2026, 8, 1),
      ],
    );
    expect(result.latestTransactions.map((row) => row.entryId),
      <String>['expense-late', 'income-mid']);
  });

  test('L5-RED: category rank uses only active direction and absolute amount', () {
    final result = linked(
      scope: const YearScope(2026),
      direction: LedgerDirection.expense,
      income: <DashboardLedgerEntry>[_entry('income-big', 50000, 2026, 7, 1,
        categoryId: 'income-salary')],
      expense: <DashboardLedgerEntry>[_entry('expense-food', 9000, 2026, 7, 2,
        categoryId: 'expense-food')],
    );
    expect(result.topCategories.first.id, 'expense-food');
    expect(result.topCategories.first.amountMinor, 9000);
  });

  test('L6-RED: partner rank uses only active direction and transaction count', () {
    final result = linked(
      scope: const YearScope(2026),
      direction: LedgerDirection.income,
      income: <DashboardLedgerEntry>[
        _entry('recurring-1', 10, 2026, 1, 1, partnerId: 'income-recurring'),
        _entry('recurring-2', 10, 2026, 2, 1, partnerId: 'income-recurring'),
        _entry('recurring-3', 10, 2026, 3, 1, partnerId: 'income-recurring'),
        _entry('one-off', 99999, 2026, 4, 1, partnerId: 'income-one-off'),
      ],
      expense: const <DashboardLedgerEntry>[],
    );
    expect(result.topPartners.first.id, 'income-recurring');
    expect(result.topPartners.first.transactionCount, 3);
  });
  ```

  Also assert SUM/YEAR/MONTH Cashflow remains the current exact primary
  projection and a `DayScope` retains `unsupportedDay` while latest/rank data
  remains scope-filtered.

- [ ] **Step 2: Run the new tests and verify RED.**

  Run in Ubuntu/proot:

  ```sh
  /home/flutteruser/flutter/bin/flutter test \
    test/features/dashboard/application/dashboard_balance_primary_projection_test.dart
  ```

  Expected: compile/test failure because `DashboardBalanceLinkedProjection` and
  its immutable row contracts do not exist yet.

- [ ] **Step 3: Add the immutable Balance-only read model.**

  In `dashboard_balance_primary_projection.dart`, add compact immutable DTOs:

  ```dart
  final class DashboardBalanceLinkedPresentation {
    DashboardBalanceLinkedPresentation({
      required this.identity,
      required this.timeScope,
      required this.selectedDirection,
      required this.cashflow,
      required List<DashboardBalanceScopedTransaction> latestTransactions,
      required List<DashboardBalanceRankedItem> topCategories,
      required List<DashboardBalanceRankedItem> topPartners,
    }) : latestTransactions = List.unmodifiable(latestTransactions),
         topCategories = List.unmodifiable(topCategories),
         topPartners = List.unmodifiable(topPartners),
         presentationId = Object.hash(
           identity, timeScope.canonicalKey, selectedDirection,
           cashflow.presentationId, latestTransactions.map((e) => e.entryId).join('|'),
           topCategories.map((e) => '${e.id}:${e.amountMinor}').join('|'),
           topPartners.map((e) => '${e.id}:${e.transactionCount}').join('|'),
         );
  }
  ```

  `DashboardBalanceLinkedProjection.build` must first make scope-local lists
  from resident `DashboardLedgerEntry` values, call the existing primary
  projection with those two lists, then:

  ```dart
  final latest = <DashboardLedgerEntry>[...income, ...expense]
    ..sort(_newestFirstUsingOccurredOrderThenId);
  final directional = selectedDirection == LedgerDirection.income
      ? income : expense;
  final categories = _rankByCategoryAbsoluteAmount(directional).take(5);
  final partners = _rankByPartnerTransactionCount(directional).take(5);
  ```

  Preserve display/color/icon metadata from a deterministic representative
  admitted row. Tie-break by display label then stable ID. Keep all helpers
  private, pure, bounded and free of Flutter/repository/Query dependencies.

- [ ] **Step 4: Run the projection tests and verify GREEN.**

  Run the command from Step 2. Expected: all prior P2 projection tests plus
  L4/L5/L6 pass.

### Task 2: Publish the unified presentation from the Core hot path

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart`
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`

**Interfaces:**
- Consumes: `DashboardVisibleFrame.scope.timeScope`,
  `DashboardVisibleFrame.direction`, the existing exact focus-aware
  `_balancePrimaryEntriesFor` owner and Task 1 projection.
- Produces: `ValueListenable<DashboardBalanceLinkedPresentation?>
  balanceLinkedPresentation` passed from CoreDashboard through the mode host to
  the Balance surface.

- [ ] **Step 1: Add failing production-Core next-frame tests.**

  Extend the existing Balance primary test path with a fixture where Income and
  Expense differ by Summary target and direction:

  ```dart
  testWidgets('L8-RED: Summary and direction publish one resident linked presentation next frame', (tester) async {
    final fixture = await _bootBalanceCoreFixture(
      tester,
      income: _rowsForBalanceLinkedScope(),
      expense: _rowsForBalanceLinkedScope(),
    );
    final repositoryRequestsBefore = fixture.repository.requestCount;
    final indexGenerationBefore = fixture.controller.presentation.index!.generation;
    await fixture.selectScope(const YearScope(2025));
    await fixture.selectScope(MonthScope(const YearMonth(year: 2025, month: 7)));
    await fixture.selectDirection(LedgerDirection.expense);
    await tester.pump();
    final linked = fixture.controller.balanceLinkedPresentation.value!;
    expect(linked.timeScope,
      const MonthScope(YearMonth(year: 2025, month: 7)));
    expect(linked.selectedDirection,
      LedgerDirection.expense);
    expect(fixture.repository.requestCount, repositoryRequestsBefore);
    expect(fixture.controller.presentation.index!.generation, indexGenerationBefore);
  });
  ```

  Assert revisiting an exact scope/direction returns the cached immutable
  instance, and that `balancePresentation` (the all-time Header model) retains
  its identity.

- [ ] **Step 2: Run the focused Core test and verify RED.**

  ```sh
  /home/flutteruser/flutter/bin/flutter test \
    test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart
  ```

  Expected: missing linked notifier/publication contract.

- [ ] **Step 3: Replace only the Summary-aware primary notifier.**

  Keep `balancePresentation` unchanged. Replace the existing
  `balancePrimaryPresentation` notifier/cache/lifecycle with linked equivalents:

  ```dart
  final ValueNotifier<DashboardBalanceLinkedPresentation?>
      balanceLinkedPresentation = ValueNotifier(null);
  final LinkedHashMap<String, DashboardBalanceLinkedPresentation>
      _balanceLinkedProjectionCache = LinkedHashMap();

  void _publishBalanceLinkedPresentationForVisibleFrame(
      DashboardVisibleFrame frame) {
    final identity = _balancePrimaryIdentityFor(index);
    final key = '${identity.upstreamScopeKey}|${identity.indexGeneration}|'
        '${frame.scope.timeScope.canonicalKey}|${frame.direction.name}';
    final next = _balanceLinkedProjectionCache[key] ??=
        DashboardBalanceLinkedProjection.build(
          identity: identity,
          timeScope: frame.scope.timeScope,
          selectedDirection: frame.direction,
          incomeEntries: _balancePrimaryEntriesFor(
            index: index,
            direction: LedgerDirection.income,
          ),
          expenseEntries: _balancePrimaryEntriesFor(
            index: index,
            direction: LedgerDirection.expense,
          ),
        );
    if (!_disposed && identical(visibleFrames.value, frame)) {
      _setBalanceLinkedPresentation(next);
    }
  }
  ```

  Preserve the existing 24-entry LRU behavior rather than using `??=` without
  eviction. Keep the active-only Balance lifecycle gate, disposal and
  focus-membership logic. Pass the new listenable through `CoreDashboard` and
  `DashboardCoreModeHost`; neither presentation file may aggregate finance.

- [ ] **Step 4: Run Core tests and verify GREEN.**

  ```sh
  /home/flutteruser/flutter/bin/flutter test \
    test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart \
    test/features/dashboard/presentation/core_dashboard_test.dart
  ```

  Expected: new L8 next-frame/reuse/no-source-work test and existing Core
  Balance/Header tests pass.

### Task 3: Link the stable carousel selection to the lower card

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

**Interfaces:**
- Consumes: Task 2 `DashboardBalanceLinkedPresentation`; existing
  `CenteredCarousel.onSelectedChanged`.
- Produces: local `ValueNotifier<BalanceCarouselTopic>` and fixed five-card
  upper rail model.

- [ ] **Step 1: Add a failing widget test for linked selection.**

  ```dart
  testWidgets('L2-RED: centered topic changes only the matching lower Balance detail', (tester) async {
    await pumpBalanceWithLinkedPresentation(tester);
    final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
      find.byKey(const ValueKey('balance-carousel')),
    );
    carousel.controller.jumpToIndex(2);
    await tester.pump();
    expect(find.byKey(const ValueKey('balance-detail-top-category')), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-primary-card')), findsNothing);
  });
  ```

  Cover all four topics and prototype, and retain assertions for five logical
  slots, three visible slots, stable controller/ScrollPosition and exact motion
  profile identity.

- [ ] **Step 2: Run the surface test and verify RED.**

  ```sh
  /home/flutteruser/flutter/bin/flutter test \
    test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart
  ```

  Expected: the current rail has only latest/prototype kinds and the lower card
  always renders Cashflow.

- [ ] **Step 3: Lift only topic selection to Balance surface state.**

  Convert `BalanceDashboardCoreSurface` to a stateful surface that owns:

  ```dart
  final ValueNotifier<BalanceCarouselTopic> _topic =
      ValueNotifier(BalanceCarouselTopic.cashflow);
  ```

  Pass it to the upper/lower hosts. Keep the existing `_BalanceUpperCarousel`
  state as controller owner. Its `CenteredCarousel` gets:

  ```dart
  onSelectedChanged: (logicalIndex) {
    widget.onTopicChanged(balanceCarouselTopics[logicalIndex % 5]);
  },
  ```

  Build the fixed cards in the stated order from the linked payload:
  Cashflow net; scoped latest; Top category; Top partner; prototype. Do not
  change `CenteredCarouselSpec`, press feedback, material, geometry, physics
  or its stable state object.

- [ ] **Step 4: Run the surface test and verify GREEN.**

  Run Step 2's command. Expected: all old geometry/motion tests and L2 pass.

### Task 4: Render Balance-only detail companions and rank composition

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Create: `test/features/dashboard/presentation/balance_linked_detail_card_test.dart`
- Modify: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

**Interfaces:**
- Consumes: linked presentation, local `BalanceCarouselTopic`, existing
  `BalancePrimaryChartCard`, `CategoryVisualBadge`, Balance material scopes.
- Produces: lower-card child renderers, each consuming only immutable DTOs.

- [ ] **Step 1: Add failing widget tests for scoped list/rank composition.**

  ```dart
  testWidgets('L4-RED: latest detail exposes five scope-local transactions', (tester) async {
    await tester.pumpWidget(_detailHost(
      topic: BalanceCarouselTopic.latestTransaction,
      linked: _fiveTransactionLinkedPresentation(),
    ));
    expect(find.byKey(const ValueKey('balance-detail-latest-transaction')), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-latest-row-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-latest-row-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-latest-row-5')), findsNothing);
  });

  testWidgets('L5-RED: category detail features the first and following ranks', (tester) async {
    await tester.pumpWidget(_detailHost(
      topic: BalanceCarouselTopic.topCategory,
      linked: _fiveRankLinkedPresentation(),
    ));
    expect(find.byKey(const ValueKey('balance-detail-top-category')), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-ranking-featured-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('balance-ranking-row-4')), findsOneWidget);
  });

  testWidgets('L6-L7-RED: partner detail has count values and category badges', (tester) async {
    await tester.pumpWidget(_detailHost(
      topic: BalanceCarouselTopic.topPartner,
      linked: _fiveRankLinkedPresentation(),
    ));
    expect(find.byKey(const ValueKey('balance-detail-top-partner')), findsOneWidget);
    expect(find.text('5 tranzakció'), findsOneWidget);
    expect(find.byType(CategoryVisualBadge), findsNWidgets(5));
  });
  ```

  Assert card keys `balance-detail-latest-transaction`,
  `balance-detail-top-category`, and `balance-detail-top-partner`; one featured
  first rank key and bounded remaining-rank keys; category value formatting and
  partner `N tranzakció` formatting; and no internal Havi/Éves/Össz selector.

- [ ] **Step 2: Run the new widget test and verify RED.**

  ```sh
  /home/flutteruser/flutter/bin/flutter test \
    test/features/dashboard/presentation/balance_linked_detail_card_test.dart
  ```

  Expected: no linked detail widget exists.

- [ ] **Step 3: Implement the Balance-specific renderer.**

  `BalanceLinkedDetailCard` switches only on the local topic:

  ```dart
  return switch (topic) {
    BalanceCarouselTopic.cashflow => BalancePrimaryChartCard(
      presentation: linked.cashflow,
    ),
    BalanceCarouselTopic.latestTransaction => _ScopedTransactionList(
      transactions: linked.latestTransactions,
    ),
    BalanceCarouselTopic.topCategory => _BalanceRankingDetail(
      title: 'Top 5 kategória', items: linked.topCategories,
      primaryValue: (item) => DashboardPreparedFormatter.amountMinor(item.amountMinor),
    ),
    BalanceCarouselTopic.topPartner => _BalanceRankingDetail(
      title: 'Top 5 partner', items: linked.topPartners,
      primaryValue: (item) => '${item.transactionCount} tranzakció',
    ),
    BalanceCarouselTopic.prototype => const SizedBox.expand(),
  };
  ```

  Use `CategoryColorCatalog.handleOf` / `CategoryIconCatalog.handleOf` plus
  `CategoryVisualBadge` from the existing visual authority; do not make a new
  color palette or icon resolver. The lower host keeps the one existing
  `DashboardPlaceholderCard` material shell and has no oversized gesture
  catcher. Use keys/semantics for topic, rank and current value.

- [ ] **Step 4: Run the detail/surface tests and verify GREEN.**

  ```sh
  /home/flutteruser/flutter/bin/flutter test \
    test/features/dashboard/presentation/balance_linked_detail_card_test.dart \
    test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart \
    test/features/dashboard/presentation/balance_primary_chart_card_test.dart
  ```

  Expected: list/rank composition, linked selection and prior Cashflow
  SUM/YEAR/MONTH/Day shell tests pass.

### Task 5: Prove boundaries, regressions and delivery readiness

**Files:**
- Modify: `test/features/dashboard/application/dashboard_balance_primary_projection_test.dart`
- Modify: `docs/superpowers/checklists/2026-09-21-mind-entry-day-balance-checklist.md`

- [ ] **Step 1: Add a focused boundary/no-touch test before final validation.**

  Add this source-boundary test to the existing projection test file; it keeps
  the intentional source contract explicit without granting UI data access:

  ```dart
  test('L1-RED: Balance detail rendering has no repository or Room dependency', () {
    final source = File(
      'lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('repository/')));
    expect(source, isNot(contains('runtime/data')));
    expect(source, isNot(contains('PreparedDashboardIndex')));
    expect(source, contains('DashboardBalanceLinkedPresentation'));
  });
  ```

  Retain the object-identity assertions for `CenteredCarouselController`,
  `ScrollPosition` and `timeRefinementRail` after scope/direction data updates.

- [ ] **Step 2: Run the targeted suite.**

  ```sh
  /home/flutteruser/flutter/bin/flutter test \
    test/features/dashboard/application/dashboard_balance_primary_projection_test.dart \
    test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart \
    test/features/dashboard/presentation/balance_primary_chart_card_test.dart \
    test/features/dashboard/presentation/balance_linked_detail_card_test.dart \
    test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart \
    test/features/dashboard/presentation/core_dashboard_test.dart \
    test/features/dashboard/presentation/dashboard_core_mode_host_test.dart
  ```

  Expected: all target tests pass. Then run the unchanged Mind Header test and
  the relevant shared centered-carousel/Budget regression tests named by the
  affected test tree.

- [ ] **Step 3: Run final local checks before the application commit.**

  ```sh
  /home/flutteruser/flutter/bin/flutter analyze --no-pub --no-fatal-infos
  /home/flutteruser/flutter/bin/dart format --output=none --set-exit-if-changed \
    lib/features/dashboard/application/dashboard_balance_primary_projection.dart \
    lib/features/dashboard/application/dashboard_core_controller.dart \
    lib/features/dashboard/presentation/core_dashboard.dart \
    lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart \
    lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart \
    lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart \
    test/features/dashboard/application/dashboard_balance_primary_projection_test.dart \
    test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart \
    test/features/dashboard/presentation/balance_linked_detail_card_test.dart \
    test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart
  git diff --check
  ```

- [ ] **Step 4: Re-read the checklist and update L1–L9 truthfully.**

  Do not mark V2 physical validation complete. Update the acceptance checklist
  only after the corresponding evidence is present.

- [ ] **Step 5: Make one application commit and one journal-only commit.**

  The application commit body must state the resident projection authority,
  scoped direction rules, Header-only Compound boundary, exact RED/GREEN
  commands, the inherited profile baseline, and `PENDING — USER ONLY`.
  Then append factual validation/delivery evidence to
  `docs/FLUVI_ENGINEERING_JOURNAL.md` and commit only that file with `[skip ci]`.

- [ ] **Step 6: Push once and complete delivery.**

  Push the application and journal commits. Monitor the exact app workflow;
  download the successful normal human APK to `/storage/emulated/0/Download/fluvi`,
  verify its SHA-256 and embedded identity. Regenerate SCIP from the final
  application SHA on the tooling branch; ensure `manifest.source_head` equals
  that app SHA. Cancel any workflow triggered by the journal-only push.
