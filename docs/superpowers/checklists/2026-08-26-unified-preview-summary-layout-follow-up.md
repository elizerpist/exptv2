# Unified preview and Summary-layout follow-up acceptance checklist

**Reference inputs:** user specification in this turn; Fluvi Logs Drive document
`13jUTJW6sg-gaG7Zt3EofLxPauSvoKOqLpqss8dAR_rU`, revision **40**
(2026-08-26 17:23:30Z); Android screenshots
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260826-193721.png` and
`Screenshot_20260826-192737.png`; current `separated-core-modes` source.

| ID | Source / evidence | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| UPV-01 | User Task A; Logs r40 temporal control | presentation/cache | Each accepted temporal crossing publishes one target epoch to chart and LogBox without settlement or I/O on cache hit. | temporal preview/cache and widget fling tests | PARTIAL — chart cache-hit binding is now allowed during foreground motion; full device trace remains required. |
| UPV-02 | User Task A; Logs r40 avatar trace | avatar drilldown/visible-frame store | Each accepted avatar crossing publishes the same category/aggregate preview epoch to chart and LogBox while physical motion continues. | multi-crossing avatar fling, slow-backend and aggregate-restore tests | PARTIAL — active-resource scene hit now synchronously rotates the focused LogBox during the crossing; device multi-cross evidence remains required. |
| UPV-03 | User Task A | stale/coalescing | Focus/scene completion cannot overwrite a newer epoch; duplicate work is coalesced and bounded. | out-of-order/stale/cache-bounds tests | PARTIAL — existing stale-generation/coalescing suites are green; full dashboard run pending. |
| SRCH-01 | User Task B; inspected screenshots | LogBox viewport/Search parent | No larger dark or clipped decorated envelope remains around SearchPill; the exact pill material remains unchanged. | Search background pixel/structure and geometry tests | PARTIAL — enclosing header ClipRect removed and structure test green; Android visual check pending. |
| SUM-01 | User Task C | Segmented mode selector | Physical downward gesture maps SUM→YEAR→MONTH→DAY; enum/query hierarchy stays unchanged. | direction and query-key tests | DONE |
| SUM-02 | User Task D | Summary presentation settings | Separators are independently paint-toggleable, defaulting to current visible behavior with invariant geometry. | settings/painter geometry tests | DONE |
| SUM-03 | User Task E | Summary mode selector renderer/tuner | Current, icon+label, and large-icon layouts preserve semantics/geometry; large visual icon is at least the current LogBox avatar metric. | widget/semantics/layout tests | PARTIAL — source/widget metrics are green; Android visual verification pending. |
| SUM-04 | User Task F | hierarchy selector renderer | Dynamic Trio is one value idle, three continuous grow/shrink values during motion, strictly clipped to current Summary RRect and uses existing crossings. | fractional-scale/clip/crossing tests | PARTIAL — pure fractional geometry, widget idle/motion count and RRect clip tests are green; physical clipping/feel pending. |
| BORD-01 | User Task G | budget layout/settings | Avatars→Chart and Chart→Avatars are independent from Split/Unified, preserve data, preserve Split surface ownership, and retain one Unified shell. | four-matrix/layout-state tests | PARTIAL — all four structural combinations and one Unified shell are tested; device layout check pending. |
| BORD-02 | User Task G; prior BUD-01 | Budget selected chrome geometry | Maximum selected avatar extent has positive relevant card clearance and no chart collision in both Unified orders. | max-envelope geometry tests | PARTIAL — layout reserves the 40px selected-shell tail and preserves the existing 20px Unified top offset; animated artwork envelope needs device confirmation. |
| SET-01 | User Task H | centralized controllers/tuner | New Summary/Budget settings default to current behavior, reset/persist according to existing architecture, and do not mutate one another. | controller/tuner independence tests | DONE — current dashboard visual settings are dashboard-lifetime (not persisted), and the new controllers follow that convention. |
| REG-01 | User protected architecture | dashboard regression suites | Existing Summary variants, cache policy, custom-painted LogBox, scroll identities, shadows/borders/corners, palette/height and Budget semantics remain intact. | targeted suites, analyzer, boundary verifier | PARTIAL — targeted suites/analyzer green, one independently reproduced baseline test failure excluded. |
| DOC-01 | User Documentation | active docs | Trace root cause, preview ownership, Search wrapper, defaults, metrics and manual Android checklist are factual. | plan/checklist/diff review | PARTIAL |
| DEL-01 | User delivery + AGENTS | git/GitHub Actions | One focused production commit is pushed and its human diagnostic APK is downloaded and SHA-256 verified. | exact Actions run and local artifact | NOT DONE |

## Latest trace evidence before edits

- **Temporal control:** at about `19:44:14` in revision 40,
  `VERTICAL_PREVIEW_ROOT_ARM_STARTED` → `VERTICAL_PREVIEW_ROOT_ARMED` →
  `LOGBOX_SCENE_SELECTED` occur in the same preview sequence for successive
  temporal targets.
- **Avatar divergence:** at `17:53:45.64`,
  `BUDGET_TARGET_SELECTION_CHANGED` and
  `BUDGET_DISTRIBUTION_SELECTION_BOUND` precede
  `BUDGET_LOGBOX_DRILLDOWN_REQUESTED` / `CATEGORY_FOCUS_REQUESTED`
  (`preparedMembershipHit=true`); `SCENE_WINDOW_PREPARE` still takes about
  32–48 ms before `FOCUS_PUBLICATION_COMPLETED`. The chart therefore changes
  ahead of the visible LogBox. Later rapid traces at about `19:44:04–09` show
  the same pattern over target handles 8→5, 4→2, and aggregate→8.

No physical Android validation has been performed for this follow-up.

## Implementation evidence

- **Avatar preview convergence:** `BudgetTargetAvatarRail` remains the single
  accepted-crossing producer: it synchronously updates
  `DashboardBudgetPresentationController` (the chart target) and invokes
  `DashboardBudgetLogboxDrilldownCoordinator`. `DashboardCoreController` now
  permits that foreground category scene to install during motion. When an
  exact focused payload is already richly projected and all of its rows/text
  layouts exist in the active immutable LogBox bank,
  `DashboardLogBoxPreparedSceneCache.stageWindowFromActiveResources` stages
  the focused window without a `TextPainter`, repository call or generic scene
  prepare, then the normal stale-guarded atomic publication rotates it. A
  compact payload deliberately falls through to the existing cooperative scene
  owner rather than materializing on the fling stack; a miss never blocks the
  carousel. A stale active-resource stage is explicitly released before a
  newer target may stage.
- **Temporal chart parity:** `_onBudgetDistributionVisibleFrame` first calls
  `publishIfReadyForTimeScope` even while foreground input is active. Only a
  miss is deferred, so a prepared chart and the matching visible LogBox frame
  bind in the same interaction turn.
- **SearchPill envelope:** at normal dashboard height the oversized LogBox
  header no longer clips the SearchPill's own physical depth, so outer pixels
  are the page background plus only the pill's selected depth. When the entire
  header is genuinely shorter than its structural extent, one keyed structural
  clip contains the complete oversized header before the scroll lane; the
  SearchPill's own `FluviRoundedBox`, border, radius and selected depth remain
  unchanged.
- **Summary direction:** the existing `CenteredCarousel` physical mapping was
  verified by widget fling to already produce downward
  `SUM → YEAR → MONTH → DAY`. The semantic enum/query order was intentionally
  not reversed.
- **Summary settings:** `DashboardSummaryPresentationSettings` is centralized
  and dashboard-lifetime like the existing visual controllers. Defaults are
  separators on, Current mode layout, Current time-fling style. Dynamic Trio
  is a clipped, semantics-excluded overlay driven by the same controller's
  fractional logical index; `SummaryDynamicTrioGeometry` pins its continuous
  0.68–1.0 scale model.
- **Budget ordering:** `BudgetSectionOrder` defaults to
  `avatarsThenChart`. `chartThenAvatars` moves only the existing structural
  cascade slots and reserves a 40px mode-content tail for the selected 112px
  avatar input shell. Split remains shell-free; Unified remains exactly one
  shared outer card.
- **Inherited baseline failure:** `core_dashboard_test.dart`, test
  `keeps the SummaryPill amount while rendering Ledger count and SearchPill`,
  fails unchanged at baseline `e0eaeb0` and after this work because it creates
  the Balance mode then expects the Budget pager. It is not task-created.
- **Additional inherited verification failures:** baseline `e0eaeb0` also
  reproduces the six `core_dashboard_geometry_golden_test.dart` image diffs
  (for example Balance expanded: 4.84%, 17,783 pixels) and the first
  `dashboard_scroll_milestone_test.dart` case (`Bad state: No element` at
  line 155). These were observed before this change in a detached baseline
  worktree and are not updated or hidden by this delivery.

## Fresh automated verification before delivery

- Ubuntu/proot focused Flutter run: **213 tests passed**. It includes the
  geometry resolver, visible-frame/cache, focused scene staging, avatar rail,
  Budget surface/pager/preview, tuner, LogBox viewport and prepared scene
  cache, Summary presentation/experiment/motion, temporal presentation and
  CenteredCarousel suites.
- Ubuntu/proot `flutter analyze`: **No issues found** (100.3s).
- `git diff --check` is clean. The two Android screenshots above were re-read
  immediately before delivery; the remaining visual/gesture matrix is still a
  human physical-device checklist, not a claimed completed validation.
