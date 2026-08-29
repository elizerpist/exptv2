# Dashboard Phase A Physical Motion Repair Design

## Goal

Repair the Budget dashboard's collapse, edge, and cross-control regressions
without changing its cache-independent latest-wins live-interaction model.
The Category Header palette feature remains out of scope until the Android
physical acceptance gate below is passed.

## Starting evidence

- Baseline is `separated-core-modes` at
  `b1ec0798a2608d3a8b9a4c81a023f936255d7c86`; Fluvi Logs revision 49 was read.
- `Screenshot_20260828-191823.png` contains the reported neutral rectangle
  over the Partner Card2 interior.
- `git show 2cbd20c7..6544b714` identifies the relevant new composition:
  `BudgetDashboardCoreSurface` opts Card2 into
  `clipOpaqueContentDuringReveal`; `DashboardCoreModeCascadeCard` then forces
  opaque content above zero progress and clips its whole child by a progress
  height.
- `BudgetDistributionPager` uses `PageView.clipBehavior: Clip.none`, while
  every virtual Category/Partner item paints its own `BudgetDistributionPageCard`
  physical shell. This is a layer-path hypothesis, not accepted proof.

## Ownership to preserve

`CoreDashboard` owns one `BudgetDistributionPageController` and therefore one
`PageController`; its virtual parity is the only Card2 semantic owner.
`BudgetDistributionPager` owns horizontal paging. `DashboardExpansionController`
and `DashboardMotionHost` own the one master vertical progress.
`DashboardHeaderVisualController` owns the one Header ticker. The
live-interaction coordinator, prepared frames, stable LogBox scroll owner and
latest-wins generation gates remain unchanged.

Vertical motion must never navigate or re-create the Card2 PageView. Avatar
ballistic motion can signal maintenance priority but cannot lock Summary direct
input.

## Chosen layer model

After a distinctive-color actual-composition raster test proves the present
path, Card2 will be one coherent moving authored object:

```text
master cascade transform and opacity
  -> one Card2 shadow / border / rounded surface
       -> one rounded interior clip
            -> stable PageView and stable PageController
                 -> active Category or Partner content
```

The physical shell moves outside PageView's lazy children. Page children retain
content and their own list-scroll behavior, but never own competing Card2
shadow/border geometry. The PageView viewport is clipped to the Card2 interior.
The budget-only reveal clip is not deleted blindly: the raster test selects the
smallest correct replacement, never an overlay, bitmap snapshot, second
controller, or secondary animation.

## Input, performance, and Header rules

A real WidgetTester Avatar ballistic test must locate the exact Summary input
rejector. The repair will cancel only Summary reset-owned work and will not
wait for, cancel, or shorten Avatar ballistics. Per-fling counters distinguish
raw pixels, semantic crossings, prepared publication, scene preparation and
resource work; semantic crossings stay fully deterministic.

Header tests retain controller, renderer/backend/program, and physical shell
identity during controlled size changes. Size and uniforms may update; shader
or material construction, a new ticker, a fallback surface, or a progress
threshold remount may not occur.

## Phase A — Collapse: automated evidence

The pre-fix Partner diagnostic rendered `#37474f` (the intentionally distinct
dashboard background) at an active Card2 interior point where the Partner
content supplied `#e91e63`. The source was the progress-height
`_DashboardCascadeRevealClip`, not a neutral Partner/Category physical
surface. In the same pre-fix controlled sequence, the conditional insertion of
that `ClipRect` changed the persistent PageView's attached `ScrollPosition`
identity as progress crossed below `1.0`.

The repaired composition has no progress-dependent wrapper around PageView:
the cascade transforms/fades the whole Card2 shell, and the shell's one
rounded `ClipRRect` contains the overflow-transparent PageView. Controlled
Partner and Category 1.00→0.00→1.00 sequences now retain parity, the one
PageController, its one attached ScrollPosition, and emit no page semantic
change. The controlled raster point remains the selected page color in both
parities.

### Header resource identity

Header visual-engine and fragment-backend focused suites pass with their
existing retained ticker/program identity contracts. The controlled resize
sequence uses `320×120 → 320×114 → 320×106 → 320×96 → 320×84 → 320×96 →
320×120`; it retains the same `DashboardHeaderVisualController.tickerIdentity`
and `DashboardHeaderFragmentBackend.backendIdentity`, with zero program or
shader creations in the injected retained backend. Size therefore remains a
paint/uniform input, not a resource owner. This is automated resource evidence
only; it is not an Android shimmer acceptance result.

## Phase A — Collapse: final automated ownership findings

`BUDGET_DISTRIBUTION_PAGE_CHANGED` is not emitted during the controlled
vertical sequence. The semantic page therefore did not mutate. The concrete
failure was visual/lifecycle ownership: the conditional
`_DashboardCascadeRevealClip` inserted a `ClipRect` around an already-attached
PageView once progress became less than `1`. That changed the attached
`ScrollPosition` identity and clipped the active interior away, exposing the
dashboard background (`#37474f`) beneath it. It was not a grey Card2 material
and is not hidden by a replacement cover.

The repaired hierarchy is:

```text
Positioned → IgnorePointer → Opacity(master) → Transform.scale(master)
  → one BudgetDistributionCardShell
    → shadow/border/rounded physical surface
    → one matching ClipRRect
      → stable PageView (overflow-transparent)
        → RepaintBoundary → active Category or Partner content
```

The PageView has no physical shell and no competing rectangular viewport clip;
the outer rounded shell is the sole interior clip owner. Controlled Partner and
Category raster sequences retain their selected content colour, parity,
`PageController`, and attached `ScrollPosition` at every listed progress value.
The 208dp production-card Partner allocation also keeps its readable 105dp
floor before the Rhythm plot takes optional space; 217dp still yields the
protected 110dp donut and 40dp Rhythm plot.

## Phase A — Motion: cross-control and Avatar cost boundary

`CoreDashboard` maps Avatar activity only to
`DashboardMotionLane.budgetAvatar`; `_DashboardSummaryRegion` maps a Summary
pointer-down only to cancellation of its own auto-reset controller/registry,
then starts its own summary lane. `foregroundInputMotion` is used for
preparation/paging priority and no `IgnorePointer`, gesture gate, or
`if (motionActive) return` was found on the Summary direct-input path.

The real widget test records an Avatar fling of raw `2600 px/s` (effective
`1716 px/s`, five semantic-step cap, 1024ms snap) still active when a raw
`-2500 px/s` Summary fling begins. Summary crossings occur immediately; a
subsequent Avatar drag produces a new preview before either prior motion has
settled. Existing live-focus tests retain prepared foreground publication and
latest-wins behaviour. Existing Core mode navigation also proves the Avatar
fling does not rebuild the dashboard root. This bounds per-pixel work to the
retained carousel movement while preserving discrete semantic crossings; it is
not a substitute for the requested device frame-timeline capture.

## Gate

No production palette-source or `category_palette_variation_lab.html` work
starts before all Phase A tests and real-device Android acceptance pass.
