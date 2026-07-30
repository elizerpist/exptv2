# Budget V2 clean-room performance refactor — acceptance checklist

## Required evidence

- User source: 2026-07-30 request for a complete maximum-performance refactor
  and explicit approval to proceed without further confirmations.
- Migration source: `docs/migration-guide.md`.
- Visual reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.

| ID | Source instruction/reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| B2P-001 | User + reference screenshot | `budget_v2/`, Budget V2 host route | Reference layout and all existing Budget V2 user flows are preserved: header, five-avatar belt, card pages, type/period/search/filter controls, log and bottom navigation. | Widget contracts passed; inspected the mandatory reference. A fresh screenshot from the final GitHub-built APK is still required for the actual visual comparison. | PARTIAL |
| B2P-002 | Migration: clean feature boundary | `spendee_budget_mode_host.dart`, new `budget_v2/` | The Budget V2 route constructs its own dashboard and never constructs `BalanceFrameInput`, `BudgetV2FrameData`, `SpendeeBalanceDashboard`, `BalanceFrameResolver`, or `_SpendeeLegacyInteractionCoordinator`. | `spendee_budget_v2_contract_test.dart` plus direct host/dashboard source inspection. | DONE |
| B2P-003 | Migration: local/settled/committed ownership | selection controller | Physical offset, settled avatar and committed query have separate owners and one-way transitions. | `budget_v2_selection_controller_core_test.dart` and `budget_v2_selection_controller_test.dart`. | DONE |
| B2P-004 | User: avatar must not stutter | repaint rail + standalone dashboard | Continuous drag repaints only the belt transforms; SVG/icon subtree identity is retained and the real standalone route does not mutate/notify the store or resolve/prepare snapshots on direct frames. | Retained-widget/build-counter contracts plus the 4,096-record production swipe (same mother-card/log identity, zero pre-commit store notifications, zero snapshot resolves/preparations, and zero query-cache resolves/misses/projections). | DONE |
| B2P-005 | Migration: cancellation | selection controller + rail/session hand-off | Every raw pointer-down cancels pending publication/inertia, finalizes an active diagnostic session, and starts a fresh generation; obsolete releases cannot settle or commit. | Selection-controller and real standalone restarted-release contract: exactly one old cancelled one-frame terminal (`commit_count=0`), then a distinct fresh Travel two-frame terminal (`commit_count=1`), one commit trace and one store notification. | DONE |
| B2P-006 | Migration: indexed/cached queries + final independent review | snapshot/cache + local log projection | One immutable snapshot prepares the complete active source scope (type, period, search, external category/merchant filters) and per-avatar aggregates/log indexes once per source revision; exact vendor identities remain collision-free; no legacy Balance log query or raw-record double scan occurs during interaction. | Unit/widget contracts cover active-scope revision, exact `ACME Shop`/`ACME-Shop` identity, local ghost-aware cumulative 96-row projection, structural paging identity, and explicit 4,096-record resolve/miss/projection counters; the source contract rejects all three legacy Balance visible-log APIs. | DONE |
| B2P-007 | Existing V2 contract + final independent review | dashboard local query state + store adapter | A settled avatar updates a local primary query immediately then makes at most one shared-store acknowledgement; vendor remains a locally owned tertiary selection synchronized deliberately with the store; entering/leaving B2 and removing chips cannot leave avatar/card/legend/log state divergent. | Production-route contracts cover existing Food entry/acknowledgement, overview→Food and committed Food/Lidl→pending Travel local coherence, newer local/external vendor ordering, abandoned-primary vendor restoration, external ticker preemption, chip clear, exact selection, and one atomic final primary commit. | DONE |
| B2P-008 | Existing V2 contract | new limit edit controller | Long-press preview, clear, drag/auto ticks and final persistence work without the legacy coordinator. | Limit-edit and persistence-coordinator lifecycle contracts plus production-route coverage. | DONE |
| B2P-009 | Migration: bounded diagnostics + final independent review | UI-free `budget_v2_interaction_diagnostics.dart` + scoped presentation policy | A bounded, sanitized terminal record contains only source revision/counts/index/commit duration; no standalone B2 direct-frame or vendor-ticker trace is emitted, and no merchant-derived value reaches `DebugConsole`. Legacy raw chart build traces are disabled only inside the standalone B2 context. | Bounded-diagnostics unit contract, live two-vendor ticker privacy contract rejecting raw and normalized keys, and 4,096-record production contract rejecting money/vendor fields and `[BudgetV2Chart]` output. | DONE |
| B2P-010 | Global Flutter workflow | code/test suite | Targeted tests and full `flutter analyze` run successfully inside Ubuntu proot. | Fresh final-tree Ubuntu/proot evidence: exact Task 7 command 62/62 (01:18), broader affected matrix 178/178 (01:09), and full `flutter analyze` with no issues (52.7s). | DONE |
| B2P-011 | User: commit, push, build, download | Git/GitHub Actions | Clean feature branch is committed, pushed, GitHub Actions succeeds, and the generated APK is downloaded to Android Downloads with SHA-256 recorded. | Git/GitHub run/artifact/file inspection remains for the feature-delivery sequence. | NOT DONE |

## Task 7 dashboard integration architecture card

### Single source and write path

- `BudgetV2SelectionController` remains the sole primary-avatar lifecycle
  owner.
- `BudgetV2QueryController` owns the local exact vendor selection and
  reconciliation of the immutable external store scope.
- `SpendeeBudgetV2Dashboard` maps intents to those controllers, rebuilds from
  the local query, then makes at most one existing lightweight
  `TransactionStore` acknowledgement.
- `BudgetV2LogProjectionCache` is the only Budget V2 log projection path.
- `SpendeeBudgetV2MotherCard` owns only page and limit-edit presentation state;
  vendor selection is a controlled input.

### Task 7 acceptance inventory

| ID | Source instruction/reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| T7-01 | Task 7 Steps 1/3; existing-filter route | standalone dashboard/controller wiring | Entering the real B2 route with one existing category selects the matching avatar/card and projects only its record IDs before and after store acknowledgement. | Named real-route Food contract, including category-chip reset to Overview. | DONE |
| T7-02 | Task 7 Steps 3/4; merchant-chip clear | dashboard/card controlled vendor state | Selecting an exact merchant highlights it and filters the local log; removing its real chip clears controller selection and legend highlight without divergence. | Named real-route merchant-chip clear contract plus external-scope ticker-preemption contract. | DONE |
| T7-03 | Task 7 Step 4; exact identity | distribution factories/dashboard acknowledgement | `ACME Shop` and `ACME-Shop` retain distinct immutable keys, legend identities and independently selectable log projections. | Named production-route exact-key contract and direct removal of the lossy slug helper. | DONE |
| T7-04 | Task 7 Steps 3/6; local paging | dashboard-owned projection | B2 supplies `entries`, `hasMore` and cumulative 96-row `onLoadMore` from `BudgetV2LogProjection`; no B2 `balanceVisibleDisplayLogEntries`, `hasMore...`, or `loadMore...` dependency remains. | Real production route pages 96→120 cumulatively with zero store notifications; query/ghost projection tests and source inspection reject all legacy visible-log tokens. | DONE |
| T7-05 | Task 7 Steps 5/6; privacy | vendor ticker and diagnostics | Ticking across at least two vendors emits no raw or normalized merchant diagnostic; no replacement per-step trace is added. | Named live DebugConsole privacy contract and source inspection. | DONE |
| T7-06 | Task 7 Step 6; physical-frame contract | dashboard interaction path | Direct physical drag frames cause zero query-cache resolves/projections and zero store notifications while retaining the mother card/log elements. | 4,096-record production route reports zero resolve, cache-miss and projection deltas while retaining both elements and making no pre-commit store notification. | DONE |
| T7-07 | Task 7 Step 6; reference/behavior preservation | existing B2 visual and interaction components | Ghost rows, 96 paging, search/type/period/chips/log actions/accessibility and approved reference geometry remain intact. | Final 178-test affected matrix, exact 62-test route suite, full analyzer, and direct final reinspection of the approved screenshot; no geometry tokens were changed. | DONE |

## Completion rule

Every row must be `DONE`, or the user must explicitly defer it. An APK build is
only delivery evidence after the functional, visual and performance rows are
also `DONE`.
