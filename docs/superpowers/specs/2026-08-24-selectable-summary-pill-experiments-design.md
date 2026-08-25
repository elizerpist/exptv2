# Selectable SummaryPill experiments

## Scope and source evidence

The user-approved task makes the pre-`92b73600` SummaryPill the runtime
control (`Legacy`), alongside two non-final experiments (`Segmented` and
`Swipe mode`). SearchPill remains and the withdrawn Ledger amount does not
return. `MILESTONE_COMMITS.md` protects the single vertical Scrollable,
prepared-index/scene-window pipeline, immutable committed geometry, and child
rail interaction.

The source comparison establishes the current latency regression:

- The working child rail calls `DashboardPresentationController.semanticCrossed`
  on every discrete rail crossing. Its `_onSemanticCrossed` resolves an already
  prepared frame from `PreparedDashboardIndex` and publishes a preview frame
  before settle; `DashboardNavigationController.retainChild` later makes the
  same selected child a metadata-only promotion.
- `SummaryPillPrimaryControls` in `92b73600` calls `_settleAxis`/
  `_settleMother` only from `CenteredCarousel.onSelectionSettled`. Those call
  `DashboardCoreController.navigatePlaneTarget`/`navigateParentOffset`, which
  first await budget/scene readiness in
  `_commitTimeNavigationWithBudgetDistributionReadiness` before canonical
  structural publication. No discrete crossing drives a prepared-frame preview.

Thus the new variants must use a bounded, discrete candidate preparation and
prepared-frame promotion adapter, not the settle-then-prepare lifecycle.

For the implementation, direct DAY crossings reuse the installed child
catalog's prepared-frame publication path, while YEAR/MONTH crossings first
activate the same retained adjacent-parent hotset used by Legacy. Both begin
at a discrete carousel crossing rather than after settle; no per-pixel query
work is introduced. A hierarchy fling captures its canonical temporal origin
at motion start, so every generated carousel offset remains absolute to that
one gesture even if a prepared DAY crossing synchronously publishes a newer
navigation state.

Swipe mode exposes exactly one actionable navigation semantic node with
increase and decrease actions while its horizontal carousel owns the visible
navigation surface; its visible year/month/day fields retain their independent
vertical semantics.

## Architecture card

### Single source and write path

| State | Owner | Publication rule |
| --- | --- | --- |
| Canonical Sum/Year/Month/legacy child-day state | `DashboardNavigationController` | Existing presentation/core readiness-gated commit only |
| Prepared frames and LogBox geometry | `PreparedDashboardIndex` / visible-frame and committed-viewport owners | Existing immutable prepared-frame promotion |
| Variant selection | one injected dashboard presentation experiment owner | Presentation only; never resets the query |
| Ballistic preview | local `CenteredCarouselController` | bounded discrete candidates only; never performs query work per pixel |

### Reuse decision

`CenteredCarousel` retains its orientation support with horizontal default.
The Legacy renderer is restored from `c5d0f0f5`; it does not consume the
92b73600 primary-control widget. The variants share only the carousel engine,
canonical temporal adapters, prepared amount leaf, visual tokens, and an
explicit prepared-selection bridge.

## Acceptance checklist

| ID | Source | Area | Acceptance | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LGC-01 | User / c5 baseline | Legacy renderer | pre-92b73600 gesture, mother/child rail and amount contract restored | baseline contract/widget tests and three-mode goldens | DONE |
| VAR-01 | User | host/menu | three selectable variants share canonical query state without resets | menu widget test and host ownership inspection | DONE |
| SEG-01 | User | segmented renderer | fixed zones, visibility and four levels, no child rail | widget, semantics, and narrow/text-scale tests | DONE |
| SWP-01 | User | swipe renderer | horizontal cyclic mode plus vertical sections, no mode column | widget/gesture and actionable semantics tests | DONE |
| DAY-01 | User | temporal adapter | DAY is the existing legacy child-day query, with valid calendar projection | controller and prepared-frame tests | DONE |
| PRP-01 | User / child rail | candidate bridge | discrete candidate preparation/promotion matches child-rail architecture; bounded and stale-safe | prepared-child and retained-parent-hotset tests | DONE |
| ARC-01 | MILESTONE | dashboard ownership | vertical owner, viewport and geometry identities remain stable | boundary/viewport/scene-window tests | DONE |
| DOC-01 | User | documentation | experiments remain explicitly non-final | docs review | DONE |
| DEL-01 | Global workflow | delivery | verified commit/push/human APK | CI/artifact evidence | NOT DONE |

## Explicit deferrals

No permanent winner, no four-axis business model, no daily Budget/Mind
semantics, no Header redesign, no Ledger/SearchPill redesign, and no broad
motion-engine rewrite are introduced.

## 2026-08-25 follow-up: preview parity and body-order experiment

The three SummaryPill variants remain comparison-only. This follow-up does not
select a temporal model or a dashboard-body order as the product default.

- A Budget avatar's discrete preview crossing now enters the existing
  `DashboardBudgetLogboxDrilldownCoordinator` focus path immediately. At
  `FOCUS_DERIVED_SCOPE_READY`, the existing
  `DashboardCoreController._focusPublicationGeneration` publishes the exact
  prepared scalar to the SummaryPill amount lane without waiting for scene
  preparation. Count and LogBox remain a later atomic complete-frame/scene
  publication; they use the same target query/revision and cannot receive a
  stale focus completion. A provisional focus stores its base identity until
  scene commit, so the next aggregate or base-query tick invalidates its
  generation and immediately republishes the prepared base amount rather
  than permitting an old focus scene to win late. Settlement therefore reuses
  the current prepared target instead of restoring an aggregate amount or
  issuing a second query.
- Swipe Mode no longer places an invisible horizontal carousel under
  hit-testable hierarchy tracks. Its horizontal `CenteredCarousel` now owns
  the navigation surface and builds the vertical hierarchy tracks inside its
  selected item, so Flutter's gesture arena resolves horizontal mode intent
  versus vertical field intent. The single exposed semantic node keeps its
  increase/decrease actions.
- `Legacy` retains its real physical child rail. `Segmented` and `Swipe mode`
  reserve no physical rail even when their canonical DAY projection uses the
  retained legacy child-day state. The central resolver transfers exactly
  `railHeight + railToCollapseHandleGap` into the mode-content lower card;
  it does not consume a normal body gap, handler, Ledger header, or navigation
  reservation. The handler remains the body/Ledger boundary.
- Budget and Balance keep their upper card height; their lower card receives
  the reclaimed height. Mind's unified envelope receives it. In the two
  experimental variants, both Budget distribution donuts derive their useful
  square from actual padded lower-card constraints (while the Partner rhythm
  footer keeps its authored minimum height), retaining aspect ratio and
  existing padding rather than using a hardcoded scale transform.
- The Header tuner now owns a dashboard-lifetime, session-only ordered list of
  `Direction`, `Summary`, and `ModeContent`. The `DashboardGeometryResolver`
  places all six validated permutations through one component cursor. This is
  presentation-only: it does not alter direction, time, Budget target, query,
  viewport, or any business semantics.

SearchPill remains in Ledger and the withdrawn standalone Ledger amount remains
absent. The fixed top Header remains outside the reorderable body blocks.
