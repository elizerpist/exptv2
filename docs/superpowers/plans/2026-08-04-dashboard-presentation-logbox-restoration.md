# Dashboard Presentation and LogBox Restoration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the audited LogBox presentation and make amount, count, title,
rows, direction, query identity and revision switch through one deterministic
visible presentation target without regressing the latest rail milestone.

**Architecture:** `DashboardTimeNavigationController` and the direction
controller remain intent owners. `CurrentQueryController` remains the only
committed query/watch owner. `DashboardPresentationStore` becomes the single
keyed immutable snapshot cache and visible-target resolver; a small derived
LogBox adapter projects the active snapshot into immutable day/row view models.
The rail remains the existing centered-carousel engine and is not changed.

**Tech Stack:** Dart/Flutter, existing Room method/event-channel bridge,
`ChangeNotifier`/`ListenableBuilder`, package:test, Flutter widget tests and
GitHub Actions APK/profile verification.

## Global Constraints

- Baseline is `5429aae44ee72a262be50e08a5a4676916d41f55` on the new feature branch; never rewrite that commit.
- Preserve the current rail physics, gesture ownership, mapping, item extent, snap and crossing semantics.
- Do not cherry-pick the complete `fd3b22c` LogBox commit or restore its removed query/rail/controller ownership.
- Do not add or run golden tests.
- Preview motion performs zero repository reads, native reads, watch subscriptions, paging requests or programmatic scrolls.
- UI receives immutable view models only; query, cache, paging and epoch guards stay outside widgets.
- Build only once after all tests and analysis are complete; push only the final branch state.

## Architecture Map

| Responsibility | Single owner | Read/write boundary |
| --- | --- | --- |
| Rail intent, child preview and semantic navigation | `DashboardTimeNavigationController` | publishes navigation state; never reads storage |
| Direction intent | `TransactionDirectionController` | publishes direction; never formats metrics |
| Committed scope, watch, latest-wins and repository reads | `CurrentQueryController` | sole committed query write path |
| Keyed immutable snapshot cache and active visible selection | `DashboardPresentationStore` | `put` keyed snapshots; `activateForTarget` atomically selects one |
| Visible identity and invalidation | `DashboardVisiblePresentationTarget` plus store epoch | target query key, direction, plane, rail-open state and epoch |
| Child metric/page warming | query/application prewarm coordinator | bounded data-only cache warming outside rail ticks |
| Amount transition | `_SummaryAmountCrossfade` | animation generation + query key + presentation epoch guards |
| LogBox derived state | `DashboardLogViewportState` adapter/projector | pure immutable projection from one active snapshot |
| LogBox paging | dedicated committed-only coordinator | cursor/query/revision guarded; no preview reads |
| LogBox rendering | `DashboardLogBoxViewport` and sliver row widgets | rendering and entry intent only |
| Shared visual policy | `FluviVisualTokens`, `DashboardLogBoxTokens`, category catalog | no feature-local raw colors/radii/icon maps |

## Execution Tasks

### Task 1: Baseline and root-cause evidence

**Files:**
- Inspect: `lib/features/dashboard/query/application/dashboard_presentation_store.dart`
- Inspect: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Inspect: `lib/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart`
- Inspect: `lib/features/dashboard/presentation/core_dashboard.dart`
- Reference: `4f66a8d:lib/features/dashboard/logbox/`
- Update: `docs/superpowers/checklists/2026-08-04-dashboard-presentation-logbox-restoration.md`

- [x] Confirm the baseline hash and rail diff against `85f41ab`.
- [x] Trace every current store publish from navigation, summary metrics and query results.
- [x] Record that the current dashboard mounts only `DashboardLogBoxHeader`, while the old branch mounted the full viewport/coordinator.
- [ ] Reproduce the existing parent-close, plane-change and direction state transitions with current unit tests before changing production code.
- [ ] Run only targeted non-golden baseline tests in Ubuntu proot and save output under an untracked temporary log.

### Task 2: Write the RED regression suite first

**Files:**
- Test: `test/features/dashboard/query/application/dashboard_presentation_store_test.dart`
- Test: `test/features/dashboard/application/dashboard_summary_amount_controller_test.dart`
- Test: `test/features/dashboard/application/dashboard_core_controller_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_header_test.dart`
- Create test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [x] Add a same-key visible-target test proving fresh parent cache suppresses a stale/loading publish.
- [x] Add rail-close parent restoration, zero-result child restoration and delayed-child rejection tests.
- [x] Add delayed amount completion rejection coverage through the latest-wins animation suite.
- [x] Add month child/mother parity and direction-atomicity tests.
- [x] Add cached-year no-placeholder and cold-year outgoing-snapshot consistency tests. (Store-level cold retention is green; the remaining title/field widget assertion is documented as a risk.)
- [x] Add immediate preview `07-01 → 07-02` LogBox count/group/row test with zero I/O at the adapter/store boundary.
- [x] Add direct widget stable viewport identity/build-count test. (State/Scrollable identity and 1000-row lazy build coverage are green.)
- [ ] Run every new test and verify it fails for the intended missing behavior before production edits.

### Task 3: Centralize visible target and presentation epoch

**Files:**
- Create: `lib/features/dashboard/query/domain/dashboard_visible_presentation_target.dart`
- Modify: `lib/features/dashboard/query/application/dashboard_presentation_store.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/application/transaction_direction_controller.dart` only if an existing intent hook is insufficient

- [x] Define immutable target identity: plane, parent key, child key, rail-open flag, direction and epoch.
- [x] Add same-key candidate resolution with revision validation and no cross-key source priority.
- [x] Add one atomic target activation method that selects cache first and publishes at most once.
- [x] Increment epoch for rail open/close, parent, plane and direction changes.
- [x] Reject cross-key/delayed child publications at the store boundary; amount callbacks also carry key/epoch guards.
- [x] Make `CurrentQueryController` and summary metrics cache snapshots without bypassing the target resolver.
- [x] Turn the Task 2 store and controller RED tests GREEN.

### Task 4: Fix amount and metric race semantics

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/time_navigation/presentation/summary_metrics_presentation.dart` only for typed identity accessors if needed

- [x] Bind each amount animation to amount generation, query key and presentation epoch.
- [x] Replace immediately on preview/target changes without ever publishing a null or dash state when a valid same-key snapshot exists.
- [x] Reject delayed post-frame and animation-completion callbacks from old child/direction targets.
- [ ] Keep outgoing complete snapshot only for cold target fallback; cold title/field consistency still needs a dedicated widget test.
- [x] Turn month parity, rail-close, zero-result, cached year navigation and direction tests GREEN.

### Task 5: Restore the pure LogBox projection layer

**Files:**
- Create: `lib/features/dashboard/logbox/application/dashboard_log_view_models.dart`
- Create: `lib/features/dashboard/logbox/application/dashboard_log_viewport_state.dart`
- Create: `lib/features/dashboard/logbox/application/dashboard_log_viewport_adapter.dart`
- Create: `lib/features/dashboard/logbox/presentation/dashboard_log_area.dart`
- Create: `lib/features/dashboard/logbox/presentation/dashboard_day_log_group.dart`
- Create: `lib/features/dashboard/logbox/presentation/dashboard_log_row.dart`
- Modify: `lib/core/design/dashboard_mode_palette.dart` only through existing semantic tokens

- [x] Port the old pure projector and row/day model behavior from `4f66a8d` while using current repository DTOs.
- [x] Preformat names, amounts, times and semantics outside widget build.
- [x] Group rows by local epoch day deterministically and preserve immutable lists.
- [x] Reuse `CategoryVisualBadge`, category resolver/catalog and current LogBox tokens.
- [x] Restore fixed floating count header and clearance sliver without a second count owner.
- [x] Use one stable viewport State and stable entry/day keys; never key the root by QueryKey.
- [x] Turn explicit 1000-row lazy and viewport identity checks GREEN. (The renderer is lazy/stable; broader rebuild-counter instrumentation remains.)

### Task 6: Add committed-only paging and bounded preview page warming

**Files:**
- Create: `lib/features/dashboard/logbox/data/dashboard_log_repository.dart`
- Create: `lib/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart`
- Modify: `lib/features/dashboard/query/application/current_query_controller.dart`
- Modify: `lib/features/dashboard/query/data/dashboard_ledger_repository.dart`
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart` only if cursor typing requires it

- [ ] Add a bounded, deduplicated data-only first-page warm path using the existing `read(..., after: ...)` contract. (Not added; preview remains I/O-free.)
- [x] Keep preview page state cache-only and disable next-page loading while preview is active.
- [x] Enable near-end paging only for the committed query key/revision and deduplicate cursors.
- [x] Reject late page results by query key and visible target.
- [x] Turn preview I/O, paging and stale-page tests GREEN.

### Task 7: Wire isolated LogBox lane into the dashboard

**Files:**
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Create/modify: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Modify: `test/boundary/summary_metrics_boundary_test.dart`

- [x] Give LogBox a stable full-height frame below the fixed handler and preserve viewport identity through collapse frames.
- [x] Listen only to the derived LogBox viewport state; do not let LogBox rebuild the dashboard root, header lane or rail lane.
- [x] Reuse the same active immutable snapshot for SummaryPill amount, count header and rows.
- [ ] Add explicit rebuild counters and controller/scroll-position identity assertions.
- [ ] Turn direct rebuild-boundary instrumentation tests GREEN. (Existing rail determinism tests remain green.)

### Task 8: L0–L6 verification and delivery preparation

**Files:**
- Update: `docs/superpowers/checklists/2026-08-04-dashboard-presentation-logbox-restoration.md`
- Update: `docs/superpowers/plans/2026-08-04-dashboard-presentation-logbox-restoration.md`
- Add non-golden test evidence under existing test directories

- [x] Run each restoration level as a local test milestone; no per-commit APK build.
- [x] Run focused tests, all non-golden Flutter tests (257 passed), `flutter analyze --no-fatal-infos` (exit 0, five non-fatal infos) and `git diff --check` in Ubuntu proot.
- [ ] Run the logger-off deterministic rail/density benchmark and record counters; physical profile values remain explicitly blocked if no profile device is available.
- [x] Re-read this plan/checklist and mark every acceptance item honestly.
- [ ] Only after the remaining PARTIAL items are either instrumented or explicitly accepted, create the final commit, push once, start one GitHub Actions build and download the final Fluvi APK.
