# Temporal Budget preview and geometry follow-up acceptance checklist

**Sources:** current user specification; `Fluvi Logs` Drive document
`13jUTJW6sg-gaG7Zt3EofLxPauSvoKOqLpqss8dAR_rU` revision **42**;
read-only `spendeetest` HEAD `144d78c30dc4cc5e9f230903fd6274c98e62e118`;
current `separated-core-modes` HEAD `aacccac9040436a6085a57a7d6a46fd9ed92ec4a`;
inspected Android screenshot
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260826-193721.png`.

| ID | Source requirement | Code owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| TP-01 | Task A / r42 | Visible frame + Budget presentation | Every prepared YEAR/MONTH/DAY crossing emits one preview epoch to Header, selected avatar/progress, partition, pie/distribution, rhythm and LogBox before settle. | visible-frame rhythm + drawable-hotset cache-hit tests; physical fling still required | PARTIAL |
| TP-02 | Task A | Budget target state | Time crossings retain selected aggregate/category/partner handle; only period projection changes. | existing Budget presentation identity tests; mixed real fling still required | PARTIAL |
| TP-03 | Task A | distribution/rhythm cache | Prepared temporal path uses zero repository I/O; heavyweight drawable/SVG work is bounded, secondary, coalesced and cannot block/overwrite preview. | deferred-miss and prepared-hotset cache-hit tests | PARTIAL |
| TP-04 | Task A | Avatar control | Existing Avatar crossing chart/LogBox parity and stale guards remain immediate. | rapid avatar regression tests | NOT DONE |
| LG-01 | Task B | central LogBox geometry | Current resolved handle→count gap is exactly halved again; the exact delta is added to viewport with outer envelope, row height and scroll identity unchanged. | metric + resolver tests | DONE |
| LG-02 | Task L | SearchPill layout resolver | Show is baseline; Hide removes paint/hit/semantics and gives pill+exclusive margins exactly to viewport, additively with LG-01, without query mutation. | viewport show/hide identity test; query preservation remains covered by existing owner | PARTIAL |
| BN-01 | Tasks C/D | BNB-03 canonical path | Rounded is baseline; Straight reaches both screen edges; FAB geometry/location remains unchanged. | path + FAB structural tests | DONE |
| BN-02 | Task D | same BNB-03 path | Off paints none; thin neutral-grey contour paints once and follows the real FAB contour in all shape×border combinations. | painter code/path source and shape×border widget test | PARTIAL |
| HP-01 | Task E | Header partition geometry | Partition bar uses equal left/right owning insets, is wider only by prior right excess, and collides with no Header control. | Header bounds test | DONE |
| HP-02 | Task F | Header settings | Partition height slider is paint/layout-local: 0%=baseline, 50%=1.5×, 100%=2× on the same centerline and Header envelope. | scalar + widget centerline/bounds tests | DONE |
| HT-01 | Task G / Spendee source | Budget Header | Title/value use BudgetV2 authored x/y/size/weight/line-height/spacing; actual category/partner/aggregate name and Fluvi financial semantics persist. | source-contract/Header widget test | PARTIAL |
| HT-02 | Task H | Header settings | White/Black setting changes only title and actual/limit foreground using exact tokens; default reproduces current HEAD. | presentation-profile + widget foreground test | DONE |
| DT-01 | Task I | Dynamic Trio | Neighbors remain only after a ballistic final settle for one bounded 2–3s cooldown; no-ballistic release collapses immediately. | ballistic cooldown + non-ballistic widget tests | DONE |
| DT-02 | Task I | Dynamic Trio state | New motion cancels old timer; setting/reset/plane replacement/dispose collapse/cancel immediately; query and crossing ownership do not change. | timer/semantic tests | NOT DONE |
| UB-01 | Task J | Unified budget surface | Unified avatars-first/chart-second has positive authored gap below lower page dots without changing outer card, avatar clearance or chart geometry. | 4px bounds regression | DONE |
| PD-01 | Task K | Partner distribution surface | Partner diameter is exactly current resolved baseline ×0.90, centered, while its reclaimed vertical space grows rhythm plot one-for-one. | 150→135 widget test; rhythm plot matrix remains | PARTIAL |
| PD-02 | Task K | Category distribution surface | Category pie and all Partner financial/selection semantics are unchanged. | existing Category 150px regression plus Partner interaction tests | PARTIAL |
| ST-01 | Settings/Tuner | Central presentation owners | BottomNav, Header and SearchPill fields have current defaults, reset independently and do not mutate existing visual settings. | controller/tuner tests | NOT DONE |
| RG-01 | Protected invariants | Dashboard architecture | Existing Summary variants/direction/separators/layouts, Split/Unified/order, surfaces, custom LogBox/paging/cache and controller identity stay intact. | focused suites + boundary tests | NOT DONE |
| DOC-01 | Documentation | active docs | Evidence records r42 traces, root cause, actual CURRENT metrics, source paths, defaults and honest Android checklist. | plan/checklist review | DONE |
| DEL-01 | Delivery | git/Actions | One focused commit is pushed, exact human APK succeeds/downloads and SHA-256 is recorded. | GitHub Actions + file hash | NOT DONE |

## Working trace comparison

- **Temporal LogBox control (r42):** at `19:44:14.02` the day `2026-07-18`
  preview has `VERTICAL_PREVIEW_ROOT_ARM_STARTED` → `...ARMED` →
  `BUDGET_HEADER_VALUE_BOUND`/`BUDGET_PROGRESS_BOUND` →
  `LOGBOX_SCENE_SELECTED`; equivalent crossed days follow at `.13` and `.23`.
- **Broken temporal Budget visual route:** those preview events do not carry
  distribution/rhythm/partition publication. Current
  `CoreDashboard._onBudgetDistributionVisibleFrame` accepts only a cached
  `publishIfReadyForTimeScope`; a miss returns during
  `foregroundInputMotion`. `DashboardCoreController._scheduleBudgetDistributionWarmup`
  also holds miss preparation until that lane is idle. This is the proven
  selection-vs-drawable cache gate, not animation delay.
- **Avatar control:** `BUDGET_TARGET_SELECTION_CHANGED` is synchronous from
  `BudgetTargetAvatarRail` and immediately triggers header/progress/rhythm/
  selected-distribution state. Its cache work is secondary; it remains the
  responsiveness control.

## Implemented ownership and geometry evidence

- **Temporal cache route:** `CoreDashboard` now attaches the existing
  `DashboardCoreController` distribution preparation seam. While idle it asks
  `DashboardBudgetDistributionDrawableController` to warm the exact
  parent+sibling scopes derived from `DashboardVisibleFrame.scope`; while a
  rail is moving `publishIfReadyForTimeScope` remains the O(1) only path.
  The existing miss guard stays intact: Canvas-bank construction is deferred,
  coalesced and cannot block a crossing. `DashboardBudgetRhythmController`
  now takes the same visible frame as its endpoint authority, so a day/month/
  year preview cannot retain a committed-clock rhythm window.
- **Gap:** current baseline was **5.5px**, new `ledgerHeaderTopInset` is
  **2.75px**, reclaimed **2.75px**; `referenceLogBoxHeaderHeight` is now
  **87.75px**. SearchPill's owned shown footprint is **68px**
  (`11 + 46 + 11`), so hidden mode adds exactly 68px to the same viewport,
  and both gains compose to **70.75px**.
- **BottomNav:** `Bnb03BottomNavigationContour` is the sole fill/border path
  owner. Rounded/straight share the FAB circle (`centerY=24`, `radius=48`,
  local crest `-24`) in bar-local coordinates; Straight begins at both screen
  edges.
  Optional contour is one `1px` `FluviVisualTokens.border` (`#E2E8F0`) stroke
  over that same path. Defaults are Rounded + Off.
- **Header:** physical partition bounds changed from the asymmetric old host
  layout to `16px / 16px`; baseline thickness is **7px**, slider values are
  0%=7, 50%=10.5, 100%=14. Its local lower inset is respectively
  **4 / 2.25 / 0.5px**, which keeps the bar centerline fixed without changing
  the Header envelope. Header foreground defaults to
  `FluviVisualTokens.textPrimary` (black); white is
  `FluviVisualTokens.textOnAction`. The title remains `header.title`, the
  canonical aggregate/category/partner resolver output, and amount/limit
  formatting remains unchanged.
- **Dynamic Trio:** `_HierarchyValueSelectorState` owns exactly one
  **2500ms** timer. It is armed only on a true ballistic completion; a new
  motion, non-Trio setting, replacement, or dispose cancels it.
- **Unified:** the lower avatars-first chart indicators shift upward by the
  existing `DashboardLayoutMetrics.reference.dotGap`, **4px**, retaining one
  shared outer card.
- **Partner:** `BudgetPartnerDistributionCard` is the only caller with
  `donutScale=.90`; the shared surface gives the reduced fixed donut height
  to its existing `Expanded` rhythm footer. Category leaves `donutScale=1`.

## Read-only Typography reference

`spendeetest/lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart:90-132`
is the source. The header is a `Positioned(top:16,left:20)` column: `Budget`
is white `10`, `w900`, `height:1`; next line follows a `SizedBox(height:7)`
and is white `19`, `w900`, `height:.96`, `letterSpacing:-.76`.

No physical Android validation has yet been performed for this follow-up.

## Inherited baseline failure

`test/features/dashboard/presentation/core_dashboard_test.dart` —
`keeps the SummaryPill amount while rendering Ledger count and SearchPill` —
expects `budget-distribution-pager` while constructing a Balance mode host.
It fails identically at its assertion line 173 on starting SHA
`aacccac9040436a6085a57a7d6a46fd9ed92ec4a` and the changed worktree; it is
not attributed to this delivery.
