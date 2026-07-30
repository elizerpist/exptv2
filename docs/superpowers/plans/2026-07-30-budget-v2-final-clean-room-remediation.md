# Budget V2 final clean-room remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` task-by-task. The user explicitly
> approved autonomous execution, commits, push, online build and APK download
> on 2026-07-30; do not request another approval gate.

**Goal:** Close the independent final review's three remaining Budget V2
clean-room defects: local snapshot-owned query/log data, collision-free vendor
identity, and terminal-only sanitized diagnostics.

**Architecture:** `TransactionStore` remains the durable shared-filter source
and final acknowledgement adapter. `BudgetV2SelectionController` remains the
only primary-avatar lifecycle owner; a UI-free query controller owns the
locally visible source scope and selected vendor, and a UI-free projection cache
derives display-log entries from immutable prepared B2 data. The dashboard maps
user intents to those cores before making one shared-store acknowledgement;
the mother card becomes controlled presentation for vendor selection. A shared
pure log-order/projection helper is extracted instead of duplicating the
legacy Balance ordering/header algorithm.

**Tech Stack:** Flutter/Dart; existing `TransactionStore`, transaction models,
`TransactionLogEntry`, immutable Budget V2 snapshots, Flutter widget tests,
Ubuntu/proot Flutter test/analyze.

## Global Constraints

- Preserve the mandatory screenshot reference:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.
- Budget V2 must not construct/call `BalanceFrameInput`, `BudgetV2FrameData`,
  `SpendeeBalanceDashboard`, `BalanceFrameResolver`, legacy interaction
  coordinator, or `TransactionStore.balanceVisibleDisplayLogEntries`.
- The direct avatar drag path must make no store mutation/notification, B2
  snapshot resolution/preparation, log projection, card/log rebuild or
  merchant-derived diagnostic emission.
- Reuse the existing `SpendeeBalanceTransactionLog` visual leaf only with
  B2-owned precomputed entries; reuse one shared pure ordering/display-entry
  mechanism rather than copying its algorithm.
- Keep recurring ghost rows, date grouping, 96-row progressive window, search,
  type/period, chips, vendor filter, log actions and shared-store
  synchronization behavior.
- Run all Flutter commands only through Ubuntu/proot; APK build is GitHub
  Actions only.
- Do not mark B2P-001 or B2P-011 complete until final APK screenshot and
  remote delivery evidence exist.

## Architecture card and acceptance inventory

| Requirement | Source | Single owner/write path | Acceptance evidence |
| --- | --- | --- | --- |
| AR-01: active B2 query scope | Design data section; B2P-006/007 | `BudgetV2QueryController` owns local selected vendor and reconciles external filter snapshots; `BudgetV2SelectionController` remains primary-avatar owner; dashboard is the only store-ack caller. | Unit reconciliation tests; mount-with-filter, chip-removal and vendor-clear widget tests. |
| AR-02: immutable indexed log data | Design 49-66; B2P-006 | `BudgetV2LogProjectionCache` derives paged `TransactionLogEntry` values from `BudgetV2PreparedSnapshot`; shared pure ordering/header helper is the only projection algorithm. | Cache/query unit tests, 4,096-record direct-frame counters, source contract forbidding legacy B2 log getter. |
| AR-03: exact vendor identity | Final review; B2P-006 | `BudgetV2VendorAggregate.key` is passed unchanged into B2 distribution/legend/selection; no lossy slug is a key. | `ACME Shop` and `ACME-Shop` widget contract with two distinct legend/slice keys and independently selectable states. |
| AR-04: safe diagnostics | Migration guide; design 109-111; B2P-009 | `BudgetV2InteractionDiagnostics` is the only standalone B2 interaction trace owner; vendor ticker has no `DebugConsole` write. | Real vendor-ticker widget test rejects exact and normalized merchant strings and asserts only bounded terminal interaction output. |
| AR-05: visual/user-flow continuity | User/reference; B2P-001 | Existing B2 leaf visual composition is preserved; card selection receives controlled state. | Existing production contracts plus final GitHub APK screenshot comparison. |

---

### Task 6: Build a UI-free local query/projection core (TDD)

**Files:**

- Create: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_query_controller.dart`
- Create: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_log_projection.dart`
- Create: `lib/features/transactions/models/transaction_log_projection.dart`
- Modify: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_snapshot.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `test/spendeetest/budget_v2_snapshot_test.dart`
- Modify: `test/spendeetest/budget_v2_production_snapshot_test.dart`
- Create/Modify: `test/spendeetest/budget_v2_query_controller_test.dart`
- Modify: the existing TransactionStore log tests that cover the extracted
  shared projection helper.

**Interfaces:**

- Consumes: immutable period/type records, recurring ghost source records,
  `TransactionStore.searchQuery`, `activeCategoryIds`, `activeMerchantFilters`,
  and exact `BudgetV2AvatarSnapshot.recordsByVendorKey`.
- Produces:
  ```dart
  @immutable
  class BudgetV2ExternalQueryScope {
    const BudgetV2ExternalQueryScope({
      required this.searchQuery,
      required this.categoryIds,
      required this.merchantKeys,
    });
  }

  @immutable
  class BudgetV2LogQuery {
    const BudgetV2LogQuery({
      required this.avatarKey,
      required this.scope,
      this.selectedVendorKey,
      this.rowLimit = TransactionStore.visibleDisplayLogPageSize,
    });
  }

  @immutable
  class BudgetV2LogProjection {
    const BudgetV2LogProjection({
      required this.entries,
      required this.visibleRowCount,
      required this.totalRowCount,
    });
    final List<TransactionLogEntry> entries;
    final int visibleRowCount;
    final int totalRowCount;
    bool get hasMore => visibleRowCount < totalRowCount;
  }
  ```
- `BudgetV2LogProjectionCache.resolve(snapshot: ..., query: ...)` must return
  an immutable projection keyed by prepared source revision/query, use the
  exact vendor key for indexed lookup, and never read `TransactionStore` or a
  widget.
- `BudgetV2QueryController.reconcileExternalScope(...)` must preserve an
  acknowledged local avatar/vendor, adopt a one-category external filter on
  B2 entry, and clear stale local vendor/avatar state when an externally
  changed chip no longer matches the acknowledgement.

- [ ] **Step 1: Write the failing core tests**

  Add individual tests with real model records/ghosts:

  ```dart
  test('BudgetV2 projection uses exact selected-vendor index and active scope', () {
    final projection = cache.resolve(
      snapshot: prepared,
      query: BudgetV2LogQuery(
        avatarKey: food.key,
        selectedVendorKey: 'ACME-Shop',
        scope: const BudgetV2ExternalQueryScope(
          searchQuery: 'acme',
          categoryIds: <int>{6},
          merchantKeys: <String>{'ACME-Shop'},
        ),
      ),
    );
    expect(projection.entries.where((entry) => !entry.isHeader)
        .map((entry) => entry.record?.id), <int>[302]);
  });

  test('BudgetV2 query reconciliation adopts an external category and clears a removed vendor', () {
    final controller = BudgetV2QueryController(...);
    controller.reconcileExternalScope(foodScope);
    expect(controller.externalAvatarKey, food.key);
    controller.selectVendor('ACME-Shop');
    controller.acknowledgeVendor(<String>{'ACME-Shop'});
    controller.reconcileExternalScope(foodScope.withoutMerchants());
    expect(controller.selectedVendorKey, isNull);
  });
  ```

- [ ] **Step 2: Run RED inside Ubuntu/proot**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/budget_v2_snapshot_test.dart test/spendeetest/budget_v2_production_snapshot_test.dart test/spendeetest/budget_v2_query_controller_test.dart'
  ```

  Expected: failures because the query controller/projection interfaces do not
  yet exist and the old source does not support scope-owned log projection.

- [ ] **Step 3: Extract the shared pure log projection before using it in B2**

  Move the date-key ordering, bounded row-window and header generation from
  `TransactionStore` private helpers into
  `models/transaction_log_projection.dart`. The public helper must accept
  `Iterable<TransactionLogEntry>` and a row limit, sort by date/time/sortId,
  insert date headers once, and return immutable entries/counts. Update the
  existing legacy store path to call this helper; do not create a second B2
  sorting/header implementation.

- [ ] **Step 4: Implement immutable B2 source/query projection**

  Extend `BudgetV2SnapshotSource` with immutable raw period ghost data and a
  revision token that changes for type, period, normalized search, sorted
  category ids and sorted exact merchant keys. Add one explicit store adapter
  for unfiltered B2 period ghosts if needed; it may expose source data but must
  not invoke any `balanceVisibleDisplay...` getter/prewarm path. Keep
  `BudgetV2PreparedSnapshot` immutable and preserve exact `vendor.key`/
  `recordsByVendorKey` values. Implement `BudgetV2LogProjectionCache` outside
  the snapshot object, filtering prepared avatar records/ghosts by
  `BudgetV2LogQuery`, using `recordsForVendor(selectedVendorKey)` for a vendor
  lookup, then passing entries to the shared projection helper.

- [ ] **Step 5: Implement query reconciliation**

  Implement `BudgetV2QueryController` as a UI-free controller. It must store
  only local vendor selection and acknowledged external scope; return explicit
  reconciliation instructions rather than mutating widgets or stores. A
  matching acknowledged store callback keeps local selection; an unrelated
  external category/merchant change either adopts a matching single category
  avatar or clears the stale local selection. Search changes update scope but
  never create a new store write.

- [ ] **Step 6: Run GREEN and affected legacy regression tests**

  Run the RED command plus the exact affected TransactionStore log tests.
  Expected: all pass; add a 97+ row case proving `hasMore` and the next page
  retain correct headers/row ordering without calling the legacy Balance log.

- [ ] **Step 7: Commit**

  ```sh
  git add lib/features/transactions/models/transaction_log_projection.dart lib/features/transactions/state/transaction_store.dart lib/features/transactions/widgets/experimental/budget_v2/budget_v2_query_controller.dart lib/features/transactions/widgets/experimental/budget_v2/budget_v2_log_projection.dart lib/features/transactions/widgets/experimental/budget_v2/budget_v2_snapshot.dart test/spendeetest
  git commit -m "feat(budget-v2): own scoped log projection"
  ```

### Task 7: Wire controlled B2 query state, exact vendor keys and safe traces (TDD)

**Files:**

- Modify: `lib/features/transactions/widgets/experimental/budget_v2/spendee_budget_v2_dashboard.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify: `test/spendeetest/budget_v2_interaction_diagnostics_test.dart`
- Modify: `docs/superpowers/checklists/2026-07-30-budget-v2-clean-room-performance.md`

**Interfaces:**

- Consumes: Task 6 `BudgetV2QueryController`, `BudgetV2LogProjectionCache`,
  `BudgetV2LogProjection`, and exact `BudgetV2VendorDistributionEntry.key`.
- Produces: dashboard-owned `entries`, `hasMore` and `onLoadMore` passed into
  `SpendeeBalanceTransactionLog.fromEntries`; controlled
  `selectedVendorKey` passed from the dashboard through snapshot region to
  `SpendeeBudgetV2MotherCard`.
- `SpendeeBudgetV2MotherCard` retains only page/limit-edit presentation state;
  it must no longer be the source of truth for vendor selection.

- [ ] **Step 1: Write failing production-route contracts**

  Add separate widget tests that:

  ```dart
  testWidgets('BudgetV2 enters with an existing Food filter using Food card and local log', ...);
  testWidgets('BudgetV2 merchant chip removal clears the controlled vendor legend highlight', ...);
  testWidgets('BudgetV2 keeps ACME Shop and ACME-Shop separately keyed and selectable', ...);
  testWidgets('BudgetV2 vendor ticker emits no raw or normalized merchant diagnostic', ...);
  ```

  The last test must tap/tick through at least two vendors and reject both
  `ACME Shop` and `acme-shop` anywhere in `DebugConsole.entries`; it must not
  merely inspect a static helper. The entry-with-existing-category test must
  assert the selected avatar/mother card and displayed record IDs agree before
  and after the store acknowledgement.

- [ ] **Step 2: Run RED inside Ubuntu/proot**

  Run:

  ```sh
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart test/spendeetest/budget_v2_interaction_diagnostics_test.dart'
  ```

  Expected: old dashboard uses `balanceVisibleDisplayLogEntries`, vendor state
  remains internal/collides, and the ticker exposes raw keys.

- [ ] **Step 3: Make dashboard query data local before store acknowledgement**

  In `SpendeeBudgetV2Dashboard`, resolve `BudgetV2LogProjectionCache` from the
  prepared snapshot and controller state; pass its entries/counts/pagination to
  the log leaf. Remove every B2 use of `balanceVisibleDisplayLogEntries`,
  `hasMoreBalanceVisibleDisplayLogEntries` and
  `loadMoreBalanceVisibleDisplayLogEntries`. On avatar/vendor/chip intent,
  update the corresponding local controller state and rebuild the narrow B2
  region first; then issue only the existing lightweight shared-store
  acknowledgement. Reconcile store notifications back into the controller so
  an external filter action cannot leave card, legend and log divergent.

- [ ] **Step 4: Make vendor selection controlled and exact**

  Add `selectedVendorKey` to the mother-card public input and propagate it to
  its vendor overview. Replace `_vendorDistributionKey(...)` use in both
  prepared and compatibility distribution factories with the exact immutable
  vendor identity (`vendor.key` or the exact rollup name); delete the lossy
  slug helper. Keep only transient ticker index/page/limit UI state in the
  card. Use exact keys in donut selection, `indexWhere`, legend `ValueKey`s
  and dashboard/store vendor acknowledgement.

- [ ] **Step 5: Remove standalone vendor ticker tracing**

  Delete the `DebugConsole.log` call inside `_tickVendorSelection`; do not
  replace it with a per-step sanitized log. Retain `HapticFeedback` and visual
  selection behavior. Ensure any standalone B2 trace is only the bounded
  `BudgetV2InteractionDiagnostics` terminal record; existing legacy chart
  diagnostics remain disabled by `BudgetV2DiagnosticsScope` only in B2.

- [ ] **Step 6: Run GREEN, direct-frame performance and source contracts**

  Run the Task 7 RED command, then the 4,096-record standalone swipe,
  selection/limit/persistence, carousel, Balance log/store and mode-host tests.
  Add a source contract asserting the dashboard contains no
  `balanceVisibleDisplayLogEntries` token and that direct physical frames make
  zero query-cache resolves/projections/store notifications. Inspect the
  reference screenshot again and update B2P-006/007/009 only if every stated
  acceptance condition is proven.

- [ ] **Step 7: Commit**

  ```sh
  git add lib/features/transactions/widgets/experimental/budget_v2/spendee_budget_v2_dashboard.dart lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart test/spendeetest docs/superpowers/checklists/2026-07-30-budget-v2-clean-room-performance.md
  git commit -m "fix(budget-v2): synchronize local query and vendor state"
  ```

### Task 8: Independent integration/performance re-review

**Files:**

- Modify: `.superpowers/sdd/task-6-report.md`
- Modify: `docs/superpowers/checklists/2026-07-30-budget-v2-clean-room-performance.md`

- [ ] **Step 1: Re-read the migration guide, mandatory screenshot, original
  design and this remediation plan.**
- [ ] **Step 2: Run the full relevant suite and `flutter analyze` in Ubuntu/proot.**
  Record exact counts/times/output, not an inference from earlier runs.
- [ ] **Step 3: Generate a review package from `a0703fb` to the remediation
  head and have a fresh read-only reviewer inspect query ownership, all source
  tokens, precise vendor identities, vendor logging and direct-frame counters.**
- [ ] **Step 4: Resolve every Critical/Important issue and repeat review until
  both spec compliance and code quality are APPROVED.**
- [ ] **Step 5: Commit evidence/checklist only after clean review.**

## Plan self-review

- **Spec coverage:** Task 6 covers the missing immutable active-scope snapshot
  and indexed log ownership; Task 7 covers the user-visible filter state,
  vendor identity and trace requirements; Task 8 supplies independent
  performance/source review. B2P-001 and B2P-011 are intentionally reserved
  for final APK verification/delivery.
- **Shared mechanisms:** the plan extracts a single transaction-log projection
  engine instead of duplicating legacy sorting/header logic; the existing
  selection controller remains the sole primary-selection lifecycle owner.
- **Placeholder scan/type consistency:** every new public core and its
  consuming dashboard inputs are named above; Flutter commands use the
  required Ubuntu/proot path.
