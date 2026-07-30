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
| B2P-006 | Migration: indexed/cached queries + final independent review | snapshot/cache + local log projection | One immutable snapshot prepares the complete active source scope (type, period, search, external category/merchant filters) and per-avatar aggregates/log indexes once per source revision; exact vendor identities remain collision-free; no legacy Balance log query or raw-record double scan occurs during interaction. | Task 9 deep-paging regression materializes 43 cumulative views through 4,096 records while reporting one scan, one order projection, one cached logical query, 4,096 retained logical rows, and zero retained windows. Structural store/B2 regressions prove comma-delimited scopes cannot collide. | DONE |
| B2P-007 | Existing V2 contract + final independent review | dashboard local query state + store adapter | A settled avatar updates a local primary query immediately then makes at most one shared-store acknowledgement; vendor remains a locally owned tertiary selection synchronized deliberately with the store; entering/leaving B2 and removing chips cannot leave avatar/card/legend/log state divergent. | Task 9 real-route same-store deletion-mid-tick contract cancels the obsolete vendor and keeps legend/card/log/store aligned; controller and dashboard cancellation contracts restore committed selection and reject stale generations. | DONE |
| B2P-008 | Existing V2 contract | new limit edit controller | Long-press preview, clear, drag/auto ticks and final persistence work without the legacy coordinator. | Limit-edit and persistence-coordinator lifecycle contracts plus production-route coverage. | DONE |
| B2P-009 | Migration: bounded diagnostics + final independent review | UI-free `budget_v2_interaction_diagnostics.dart` + scoped presentation policy | A bounded, sanitized terminal record contains only source revision/counts/index/commit duration; no standalone B2 direct-frame or vendor-ticker trace is emitted, and no merchant-derived value reaches `DebugConsole`. Legacy raw chart build traces are disabled only inside the standalone B2 context. | Task 9 real 4,096-record route rejects every nonterminal `[BudgetV2...]` entry and retains one bounded terminal interaction; shared carousel writes are context-gated and legacy trace contracts remain green. | DONE |
| B2P-010 | Global Flutter workflow | code/test suite | Targeted tests and full `flutter analyze` run successfully inside Ubuntu proot. | Fresh post-review Task 9 Ubuntu/proot evidence: exact Task 7 command 65/65, query/selection/store suite 63/63, affected 18-file matrix 247/247, and full `flutter analyze`: `No issues found! (ran in 49.5s)`. | DONE |
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
| T7-07 | Task 7 Step 6; reference/behavior preservation | existing B2 visual and interaction components | Ghost rows, 96 paging, search/type/period/chips/log actions/accessibility and approved reference geometry remain intact. | Final 247-test affected matrix, exact 65-test Task 7 suite, full analyzer, and direct final reinspection of the approved screenshot; no geometry tokens were changed. | DONE |
| T7-R01 | Final independent review: bounded diagnostics | standalone dashboard + shared carousel trace policy | Real B2 emits only bounded terminal `BudgetV2InteractionDiagnostics`; raw carousel/dashboard start, cancel, schedule, commit, settle, and interrupt traces remain available only to legacy consumers outside the standalone B2 scope. | Real 4,096-row route checks all `[BudgetV2...]` output is terminal-only; exact Task 7 and legacy carousel suites pass. | DONE |
| T7-R02 | Final independent review: deep paging performance | `BudgetV2LogProjectionCache` + canonical log materializer | Changing the local row limit from 96 through deep pages performs one full source scan/projection per structural source/filter identity, retains one immutable logical result rather than growing window projections, and preserves ghosts/headers/exact keys. | 4,096-row/43-view regression asserts one scan/projection, one cached query, zero retained materialized windows, cumulative canonical headers, and exact row order. | DONE |
| T7-R03 | Final independent review: structural store cache identity | relevant `TransactionStore` filter caches and B2 active summary/log consumers | Exact scopes `{'ACME,Shop'}` and `{'ACME','Shop'}` cannot share a cache entry; sequential scope changes keep B2 summary, chips, and log aligned. | Typed immutable filter-key source inspection, store collision regression, and real B2 summary/chip/log alignment regression. | DONE |
| T7-R04 | Task 9 brief: same-store ticker revision invalidation | standalone dashboard → mother-card controlled vendor ticker | A same-store rename/delete/data revision cancels or rebases in-flight multi-step vendor ticking before an old target can publish; card, log, and store remain aligned. | Real same-store deletion-mid-tick widget regression plus replacement/external-scope ticker matrix. | DONE |
| T7-R05 | Task 9 brief: lifecycle/cost minors | selection controller/dashboard/rail + legacy store log projection | No-drag/cancelled pointers explicitly return selection and the rail's private visual state to the committed target, while an actual restarted drag preserves its residual-motion handoff; the legacy complete display log does not perform a redundant second full sort. | Controller regression rejects stale generations; real routes prove pending Food → no-drag cancellation and an interrupted direct-release → no-drag restart both restore Overview rail/card/log with zero store work, while the existing restarted-drag contract remains green; legacy store records one order projection and one prefix materialization; fresh independent re-review approved the final state. | DONE |

## Completion rule

Every row must be `DONE`, or the user must explicitly defer it. An APK build is
only delivery evidence after the functional, visual and performance rows are
also `DONE`.
