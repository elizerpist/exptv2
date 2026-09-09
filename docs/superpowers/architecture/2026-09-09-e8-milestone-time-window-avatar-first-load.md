# Architecture card — e8 Time prepared-window transition and Avatar temporal base

## Non-negotiable e8 baseline

`e8b73e3e939104164e55b09caf592f84ee59fb14` is the permanent user-accepted
direct-manipulation performance floor. Its physical smoothness is protected,
but it is not described as fully correct: an out-of-window Time crossing can
split temporal authority and poison a later Avatar focus admission.

## Existing owners retained

| Concern | Existing owner | Required repair boundary |
| --- | --- | --- |
| Immutable prepared index/window | `DashboardDataRuntime` | Build a bounded alternate `DashboardIndexRequestTemplate` with `prepareQuery`; install only through its existing `commitPreparedQuery` boundary. |
| Semantic navigation and carousel metadata | `DashboardPresentationController` / `DashboardNavigationController` | Retain a read-only candidate and original Summary order while a rebase is pending; do not use canonical fallback as a partial commit. |
| Visible authority and interaction order | `DashboardVisibleFrameStore` | Keep the old exact frame visible until the latest candidate has the new immutable index and exact Phase-A painter resource. |
| Painter-readable resource | `DashboardLogBoxPreparedSceneCache` | Reuse the typed `timePreview` lane and `bindLiveInteractionReadablePhaseA`; no second cache or LogBox. |
| Financial presentation | Existing `DashboardBudgetPresentationController` and prepared bundle | Publish only against the same installed index/navigation target as Summary and LogBox. |
| Avatar focus derivation | `DashboardEphemeralFocusDeriver` / Core focus coordinator | Derive only from a base index that represents the visible temporal scope; pending Time rebase invalidates stale Time continuations rather than deriving against a split base. |
| Diagnostics | Existing `FluviDiagnosticLogger` and rail flight recorder | Retain bounded high-value flight summaries and coalesce repetitive layout events; diagnostics do not become authority. |

## Required direct-Time transaction

```text
direct Summary pointer / crossing
  -> claim existing summaryTime interaction order
  -> current prepared index contains target?
       yes: existing exact timePreview Phase-A bind -> visible publication
       no: retain only newest window-rebase candidate and old exact visual
             -> DashboardDataRuntime.prepareQuery(new bounded symmetric window)
             -> prepare exact target through existing timePreview lane
             -> verify original order and newest generation
             -> atomically install index + navigation + financial bundle
             -> exact visible frame / paint acknowledgement
  -> optional rich scene and settle only after exact paint
```

No intermediate operation may alter canonical navigation, Budget analysis or
the visible query while its matching prepared index and painter-readable target
are absent. A superseded candidate receives an explicit terminal outcome and
cannot later install its window.

## Why a new owner is forbidden

`DashboardDataRuntime.prepareQuery` already produces a complete immutable
index without publishing it, and `commitPreparedQuery` owns the data-side
commit. `DashboardPresentationController` already owns exact frame
coalescing/order, while the prepared-scene cache owns the actual row resource.
A feature-local window cache or Time-specific visible store would duplicate
these authority boundaries and reintroduce mixed identities.

## Avatar after a Time transition

Avatar pointer intent remains a foreground claim. It may supersede a pending
Time rebase, retain the last exact compatible visual, and wait only behind the
same coherent base. It may not call `DashboardEphemeralFocusDeriver` with a
navigation scope absent from its base prepared index. The aggregate target is
an independently protected branch because it uses base-restoration logic.

## Intentionally unchanged

- Avatar and Time `CenteredCarouselController`, `ScrollPosition`, physics,
  snap, extent, spacing and semantic threshold;
- dashboard layout, Stack order, clips, hit cells, Header and LogBox design;
- financial/query semantics, database/Room/Kotlin layers;
- Mind RangeSlider and its production path;
- one Core, visible-frame store, prepared-scene cache, viewport and render
  surface.
