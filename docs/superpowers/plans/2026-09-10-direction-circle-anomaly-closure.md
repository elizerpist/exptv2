# Direction-circle atomicity and retained-anomaly closure implementation plan

> **For agentic workers:** Execute inline in the existing isolated worktree. The
> direction, rail and presentation state share one production-parent harness;
> do not partition their implementation. Use test-first red/green cycles.

**Goal:** Repair the proven direction-domain selected-target rebase split while
preserving the physical `6e962187e90e2a82431b1f91b224d2b52a6e0ba7` floor, then
close every retained physical-log anomaly by evidence rather than event names.

**Authoritative application source:** `0b108b73e8e13b7a3bbd397dd9c98e8bb0db79aa`.
The journal-only descendant `d3795d54751a7cc64aa753b36520def70af9d424` is the
integration parent; it is not a physically tested application build.

**Architecture:** `DashboardBudgetPresentationController` owns financial
selection and the selected limit visual. `BudgetTargetAvatarRail` owns only the
existing physical carousel centre and must rebase it atomically to the proven
direction-domain target authority. `BudgetCategoryAvatarArtwork` remains a
fail-closed renderer: its target-identity guard is evidence, not a repair seam.
The existing Time summary logger owns only flight diagnostics; no Time physics,
controller, ScrollPosition, or semantic publication path is in scope unless a
non-aggregate red test proves it.

**Tech stack:** Flutter/Dart, `flutter_test`, existing production diagnostics,
GitHub Actions Android human diagnostic APK, separate SCIP tooling branch.

## Global constraints

- Do not edit `docs/FLUVI_ENGINEERING_JOURNAL.md`.
- Do not alter Avatar/Time physics, controllers, ScrollPositions, geometry,
  clipping, z-order, databases, caches, stores or query architecture.
- Do not add a second selection authority, controller, cache, store, timer,
  debounce, synthetic Avatar selection, stale retention, or repaint workaround.
- Do not bypass `selectedLimitVisual.targetHandle == selectedTargetHandle`.
- Treat `10121–11662` as a hard same-session retention gap; do not infer an
  event chain through it.
- Graph status is `STALE FOR TESTED HEAD` until a manifest declares
  `source_head == 0b108b73...`; graph results are navigation aids only.

## Acceptance checklist

| ID | Source | Intended owner/code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DC-01 | User Part A §§2–5 | evidence + Git history | Journal descendant is preserved; all three raw exports and normalized local reader snapshots are independently identified; no sessions are merged. | metadata, raw SHA-256, range/duplicate audit | DONE |
| DC-02 | User §§9–10 | presentation selection + rail replacement | The existing source/tests explicitly establish whether the new direction's remembered selection or the retained physical centre wins. | full owner/test audit and architecture card | DONE |
| DC-03 | User §11 | production-parent rail/presentation/artwork test | Differing per-direction remembered handles fail before repair; one direction-only switch requires physical = semantic = presentation = visual = built/painted circle. | observed RED test | DONE |
| DC-04 | User §12 | smallest proven rebase seam | A direction replacement reaches exactly one selected target with no Avatar nudge and leaves controller/ScrollPosition/physics identities unchanged. | DC-03 GREEN + protected identity tests | PARTIAL — device profile pending |
| TM-01 | User §13 | current Time/presentation/rail chain | A positive-limit non-aggregate category remains selected across a month-only change and the period/target-identical circle is actually painted. | observed baseline and final regression | DONE |
| TD-01 | User §14 | existing Time diagnostic finalizer | One logical Time flight has one authoritative final summary, or intentionally typed non-final/final summaries; Time production behavior remains untouched. | observed RED/GREEN diagnostic test + source audit | DONE |
| AL-01 | User §15 | source + retained evidence | Every retained anomaly family receives one explicit ledger status: harmful repaired, expected no change, diagnostic repaired, or bounded missing evidence. | full log/source inventory | DONE |
| PF-01 | User §§18–19 | existing profile harness | Direction target/circle equality closes G false green without worsening existing direction/Avatar/Time measured boundaries. | strengthened profile + protected suites | PARTIAL — Android A–K run 34516795061 proved target/circle identity but failed before the asynchronous `DIRECTION_SWITCH_VISIBLE_PUBLISHED` boundary was observed |
| PF-02 | CI runs 34516795061 and 34529101782 evidence | `integration_test/dashboard_interaction_profile_test.dart` | Scenario G captures evidence only after the matching final Expense visible-frame publication; it must neither synthesize a publication nor issue an Avatar input while waiting. | observed RED/GREEN boundary test, focused regression plus Android A–K artifact has `G_direction_while_rail_open` | PARTIAL — run 34529101782 reached G after PF-03, then proved that the strict event was still absent at the profile's 8-second polling horizon while emulator raster frames took 2.4–2.9 seconds; the event gate now has a bounded 20-second profile horizon, with 134 focused tests and analyzer green; Android A–K artifact pending |
| PF-03 | CI run 34526894486 evidence | `integration_test/dashboard_interaction_profile_test.dart` | Each K Avatar fling observes that fling's own Budget Avatar motion start and then one inactive sample; final target correctness remains owned by the existing exact-paint/identity evidence, rather than a timing-sensitive arbitrary idle-frame count. | observed RED boundary test, focused suite/analyzer, Android A–K artifact | PARTIAL — observed RED, 134 focused tests and analyzer green; Android A–K artifact pending |
| DL-01 | User §§20–21 | CI/release/tooling | Atomic commits, exact CI/APK source identity, and matching final SCIP graph or explicit unavailable status. | remote ref, Actions, APK hash, manifest | PARTIAL — human APK and exact-source manifest are present for `2bc25c91`; the A–K profile is red and the tooling branch root analyzer currently includes its nested Dart package without that package's dependencies |
| PH-01 | User §21 | physical device | Exact final APK is physically accepted. | user-only validation | BLOCKED — USER ONLY |

## Architecture card

| State | Existing owner | Required invariant |
| --- | --- | --- |
| Direction intent | `TransactionDirectionController` through `DashboardCoreController` | Direction is authoritative before live interaction acceptance. |
| Remembered financial selection | `DashboardBudgetPresentationController` | The selected handle is direction-specific and is the candidate direction-domain arbitration input. |
| Physical Avatar centre | `BudgetTargetAvatarRail` + existing carousel controller | On domain replacement it must atomically represent the resolved direction target, never a steady divergent handle. |
| Selected limit visual | `DashboardBudgetPresentationController` | Target and period match accepted semantic target/scope. |
| Circle chrome/paint | existing artwork `AnimatedBuilder`/painter | It renders only when physical and visual target identities agree. |
| Time flight telemetry | existing time diagnostic finalizer | A final record must not be reset/re-emitted as a contradictory duplicate. |

No new owner is permitted. The repair must use the existing direction replacement
callback/seam after the selected authority has been independently confirmed.

## PF-02 compact architecture gate

| Gate | Decision |
| --- | --- |
| Existing owner | `integration_test/dashboard_interaction_profile_test.dart` owns profile-only polling and report assembly; `DashboardCoreController._onVisibleFramePublished` remains the only production visible-publication owner. |
| Shared mechanism | Reuse `_diagnosticEventsAfter` and the existing bounded `WidgetTester` polling pattern from `_waitForAvatarExactPaint`; do not create an app-level waiter, state owner, or synthetic diagnostic event. |
| State boundary | The helper observes the existing diagnostic ring and pumps the test binding only. It writes no application, presentation, carousel, or financial state. |
| Focused verification | The profile boundary test must fail without the matching-event wait; `dashboard_profile_report_test.dart` retains the fail-closed count validation; Android A–K validates the actual artifact. |

## PF-03 compact architecture gate

| Gate | Decision |
| --- | --- |
| Existing owner | The integration profile harness owns the wait. `DashboardCoreController` remains the sole owner of the Budget Avatar motion-lane state. |
| Shared mechanism | Reuse the existing bounded `WidgetTester` polling and `isMotionLaneActive` query. Do not add a timer, application listener, or production-state acknowledgement. |
| State boundary | The helper observes one fling-local start/idle transition and writes no application, carousel, presentation, or financial state. The existing exact-paint evidence still proves the final rendered target. |
| Focused verification | A source-boundary test must distinguish a fling-local observation from the prior suite-global latch; Android A–K is the acceptance evidence. |

## Execution tasks

### Task 1 — Evidence and source contract

1. Read the journal, milestones, prior plan/forensics, current source and
   actual `9516875...`/`0b108...` diffs.
2. Freeze the three current Drive exports; record both raw export hash and
   LF-normalized reader-snapshot hash, ranges, duplicate counts and the gap.
3. Audit `DashboardBudgetPresentationController`,
   `BudgetTargetAvatarRail._replaceItems`, artwork identity guard, current
   production-parent tests and G profile scenario.
4. State the resolved arbitration rule before changing application source. If
   no existing test/architecture contract resolves it, stop and ask instead of
   selecting a product semantic by implementation convenience.

### Task 2 — Direction-circle TDD repair

1. Add a real production-parent widget/composition test with two valid
   direction-specific remembered handles (`A != B`) and the existing rail,
   presentation, artwork and paint acknowledgement.
2. Run it on `0b108...`; it must fail because the rail preserves the prior
   physical centre while the new direction presentation restores B.
3. Implement the minimum rebase at the established authority boundary.
4. Re-run the exact test green, then repeated cold/warm/alternating switches
   and protected Avatar/Time identity suites.
5. Commit only this root-cause repair and its tests after fresh verification.

### Task 3 — Time non-aggregate and diagnostic finalization TDD gates

1. Add the category X, month A → B, no-Avatar-event production-parent test.
2. Run it first on the repaired direction head. If it is green, make no Time
   production change; retain it as anti-false-green coverage.
3. Add a Time finalization diagnostic test for a single flow's summary
   lifecycle; run it red against current duplicate summary behavior.
4. Repair only the summary lifecycle/typing owner and prove Time semantic and
   physics source paths unchanged by protected tests and diff review.
5. Commit diagnostic lifecycle work separately from direction behavior.

### Task 4 — Retained anomaly ledger and profile closure

1. For each retained `REJECTED`, `DEFERRED`, `MISS`, `OVER_BUDGET`, mismatch,
   settle/paint rejection and `USER_MARK` family, trace source owner and match
   it to a current/superseded/background target.
2. Mark expected guards as `PROVEN-EXPECTED — NO CHANGE`; add a focused test
   only where source proof alone cannot ensure the bounded/latest-wins contract.
3. Keep `mind_slider_no_live_list` separate unless a shared root cause is
   proven; never make a direction-circle patch carry unrelated Mind behavior.
4. Strengthen profile scenario G to require distinct remembered direction
   targets, actual circle-paint identity, and the matching final
   `DIRECTION_SWITCH_VISIBLE_PUBLISHED` event before it snapshots evidence.

### Task 5 — Delivery

1. Run formatter, all focused tests, protected Avatar/Time/presentation and
   boundary suites, analyzer, fast/profile suite and the strengthened A–K job.
2. Push exact application commits, wait for their human diagnostic APK, save it
   under `/storage/emulated/0/Download/fluvi`, and verify byte size/hash/source
   identity.
3. Generate SCIP on the separate tooling workflow for the final application
   SHA; otherwise report `GRAPH STALE/UNAVAILABLE FOR FINAL HEAD`.
4. Re-read this checklist before handoff. Only rows actually evidenced as done
   may be marked DONE; `PH-01` remains `PENDING — USER ONLY`.

## Plan self-review

- The direction selection decision is explicitly gated on existing product
  contract evidence; the known identity split is not mistaken for permission to
  guess target precedence.
- Direction behavior, Time diagnostics and unrelated anomaly families are
  atomic units; no broad refactor is authorized.
- The existing identity guard, carousel controller and ScrollPosition are
  protected acceptance evidence rather than implementation shortcuts.
