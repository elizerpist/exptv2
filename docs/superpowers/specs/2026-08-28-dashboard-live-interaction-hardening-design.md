# Dashboard live-interaction hardening — design record

## Scope and evidence

This record implements the accepted dashboard hardening request against
`separated-core-modes` at `731cda5b2b1965e0d2fc8997ddc9ab7ea8e7cbc7`. It
preserves that commit's category-palette prototype and the already accepted
scope-aware Spending Rhythm. The latest inspected **Fluvi Logs** Drive
revision is **47**; `MILESTONE_COMMITS.md` and the current dashboard plans were
read before this design was written.

The forensic controls are `79ce29e9` (segmented mode fling before auto-reset)
and `3127abc` (auto-reset/upper-gesture delivery). They are comparison-only;
neither is checked out or reverted.

Observed source proof:

- Direct selector input currently invalidates reset and broadcasts
  `cancelMountedMotion()` to every registered carousel. A registered canceller
  uses `jumpToIndexSilently`, so the initiating user carousel can cancel its
  own drag/ballistic activity.
- `DashboardEphemeralFocusController` anchors category/partner focus to a
  complete temporal `baseQueryKey` and intentionally refuses automatic
  rebasing. The asynchronous scene-install path publishes that focus only
  after presentation work.
- Logs show prepared category/partner membership derivation in 5/2 ms but a
  Partner publication in 40,038 ms. Interaction acceptance is therefore
  wrongly coupled to a rich-scene completion barrier.
- Partner swipe keeps its row displaced through `awaitingFocusPublication`.
- The Summary amount crossfade introduces a temporary `MediaQuery.width * .32`
  envelope and hard-coded right alignment.
- SearchPill is explicitly a disabled visual scaffold.

## Canonical live state

`DashboardLiveInteractionCoordinator` will own monotonically increasing,
RAM-only interaction generations. It does not duplicate navigation, direction,
Budget target, or committed Query ownership. Instead it snapshots their
already-authoritative values into immutable `DashboardLiveInteractionFrame`:

```
generation, coreRevision, source,
direction, visibleTemporalCandidate, budgetTarget,
committedBaseQueryIdentity, interactiveFacets
```

`DashboardInteractiveFacetState` is directional and orthogonal:

```
categoryId?, partnerId?, normalizedSearch?
```

It supersedes the exact-temporal `DashboardEphemeralFocusAnchor` lifetime
model. A direction/core revision compatibility change may invalidate a facet;
ordinary DAY/MONTH/YEAR/SUM navigation may not. The committed Query Menu
remains the base-query owner. Interactive category/partner dimensions replace
the corresponding effective base dimension, while search intersects the
result.

The coordinator creates typed projections rather than making every consumer
depend on every field:

| Consumer | Required frame fields |
| --- | --- |
| Budget Header/progress/rhythm/distribution | direction, temporal candidate, target |
| Summary amount/LogBox rows and count | direction, temporal candidate, base query, facets |
| query capsules | base query and facets |

An accepted input synchronously creates one frame and facet state, then binds
all lightweight prepared projections. It never awaits a body/scene/cache
future. Rich first-viewport decoration, paging and ready-ahead are asynchronous
augmentation only. Each operation captures `(generation, effectiveProjectionKey,
coreRevision)` and may publish only if all three still match. The stable
LogBox controller and position remain intact.

## Delivered architecture

`DashboardLiveInteractionCoordinator` now owns the immutable accepted frame
and its monotonic generation. Core accepts temporal candidates, Budget avatar
crossings, Category taps, Partner swipes, facet close actions and SearchPill
edits through that one route before any scene work starts. The old focus
anchor now has only direction/core-revision compatibility; changing temporal
scope compositionally rebases the active facets instead of treating them as a
copy of an old `baseQueryKey`.

Prepared membership is the publication-critical path. The first focused
Ledger frame, count and amount are installed immediately; scene augmentation
is unawaited and guarded by frame generation, effective projection key and
core revision. Focused Category/Partner/Search pagination uses the retained
selected ordinal membership through the prepared page reader, so a Search
scope never falls through to a native query that cannot encode its text facet.

Partner swipe now starts its bounded local snap-back as soon as it accepts the
facet; `awaitingFocusPublication` no longer owns a row transform. Aggregate
Budget avatar crossings clear only the Budget-driven Category dimension while
preserving the orthogonal Partner/Search dimensions.

## Motion ownership

Reset invalidation and programmatic reset motion are typed. A direct user drag
may invalidate the reset command generation and cancel *its reset-owned*
animation. It may never broadcast cancellation to mounted selectors or cancel
the user `ScrollActivity` that initiated the input. Foreground motion uses
owner leases/tokens when needed, so one cancel/dispose cannot leave a global
motion boolean stuck. Background preparation observes foreground activity for
scheduling only; it cannot reject later input.

Partner row displacement is visual-only. A committed swipe synchronously
accepts the Partner facet and starts the current bounded local return animation;
it never waits for a scene future. A below-threshold/cancelled gesture only
returns visually and creates no facet.

## Geometry invariants

Summary amount has exactly one persistent slot envelope and the configured
left/right alignment is passed into both static and crossfade rendering. A
crossfade changes opacity/content only. The legacy Summary row reserves its
stable 20%-of-shell amount lane in every state; this preserves the minimum
320 dp child-label width while avoiding the old motion-only `MediaQuery`
envelope. Segmented Summary keeps its existing fixed amount zone.

SUM uses one Canvas polar function:

```
angleForRatio(r) = -pi / 2 + 2 * pi * clamp(r, 0, 1)
```

The top seam is `danger end | healthy start`: immediately clockwise/right of
12 o'clock is healthy, and danger terminates at 12. The health scale and every
runtime SUM marker consume this same geometry; painting is cheap and does not
parse SVG per tick.

## Search and query-facet presentation

SearchPill owns stable dashboard-lifetime `TextEditingController` and
`FocusNode`. A text intent writes the `normalizedSearch` facet immediately.
The prepared Ledger data supplies partner-display-name OR memo/note matching;
the widget performs no repository I/O. Normalization is central, Unicode-safe,
case-insensitive and whitespace-normalizing; accents remain significant unless
an existing Fluvi normalizer says otherwise.

Facet visuals are presentation-only settings:

- `current` / `solidAvatarColor` (default `current`); solid category/partner
  facets use canonical resolved avatar color at alpha 1 with white label and
  close glyph;
- `bodyTop` / `insideSearchPill` (default `bodyTop`). In-search placement has
  one compact overflow lane plus a usable editable region. When SearchPill is
hidden, active facets deterministically fall back to body top.

Search-only fallback is explicit as well: the body-top strip renders a
closable neutral search capsule when the SearchPill is hidden, so no active
search can become invisible or uncleareable.

One LogBox chrome-layout authority owns the external facet-strip footprint;
changing placement cannot recreate the body scroll controller or position.

## First implementation boundaries

1. Capture RED pointer and race tests plus the cancellation/focus source proof.
2. Repair selector/reset ownership with typed reset command ownership.
3. Install the live-frame + composable facet state and migrate temporal,
   avatar, category and partner acceptance paths to synchronous generations.
4. Decouple Partner return, stabilize amount geometry, and correct SUM polar
   painter binding.
5. Only after those regression suites are green, add SearchPill and query-pill
   style/placement on the same facet path.

No cooldown, busy gate, delayed retry, widget-owned database query, duplicate
temporal/filter store, broad mounted-selector cancellation, or ListView
replacement is permitted.

## Automated evidence and open validation

The focused interaction/facet/search suite (29 tests), SearchPill/LogBox/
Partner widgets (47), and SUM/rhythm/CenteredCarousel protected suite (69)
pass, as do the 11 legacy Summary presentation tests and the direct
multi-crossing reset-cancellation test. `flutter analyze` reports no issues
and `git diff --check` passes.

One pre-existing mirrored Summary test with a 40 px/600 px/s fling fails the
same way on an untouched detached `731cda5b` worktree; it is recorded as an
inherited baseline failure. Physical Android validation remains required:
there was no connected device during this implementation.
