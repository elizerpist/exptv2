# Dashboard vertical round-trip and rail-restoration design

## Architecture card

- **Runtime base:** `adbb2d052be3e56f4e10d872ff9ca6f459d25224`.
- **Performance freeze:** `DashboardMotionKernel`, `TimeRefinementRail`,
  `CenteredCarousel`, `CenteredCarouselController`,
  `CenterSnapScrollPhysics`, `DashboardPresentationController`,
  `DashboardVisibleFrameStore`, and the `PreparedDashboardIndex` navigation
  hot path are read-only.
- **Vertical root owner:** `CommittedLogViewportCache` owns one pinned page-0
  model per exact committed scope. It is separate from the bounded local LRU
  page bank, cursor metadata, and geometry.
- **Render-domain owner:** `DashboardLogBoxRenderSurface` resolves exactly one
  explicit domain from the visible frame and passes that immutable decision to
  paint, hit-test, semantics, and diagnostics. The rail cache remains the
  sole owner of rail-preview resources.
- **Scope-reset owner:** `DashboardLogBoxViewport` retains its single
  `ScrollController`; it resets its existing position exactly once when an
  exact *committed* scope identity changes. Preview frames cannot reset it.
- **Acquisition owner:** `ExplicitCommittedPagingController` remains the only
  repository/keyset owner. Page zero must therefore never require reverse I/O.

## Root-cause evidence

`CommittedLogViewportCache._retainVisibleWindow()` currently iterates every
entry in `_pages`; it does not exclude ordinal zero. A deep scroll can evict
page zero while `_CommittedPageGeometry` keeps ordinal zero's actual height.
On the reverse path the viewport maps the top offset to ordinal zero, but
`pageForOrdinal(0)` returns null. The painter reports `VERTICAL_CACHE_MISS`
and paints nothing. The nearest retained page's `previousStartCursor` is null
for page zero, so `ExplicitCommittedPagingController.loadPreviousPage()`
returns without an I/O request. This proves the top gap is a root-page
ownership error, not a geometry or physics issue.

The painter's `_usesCommittedViewport` predicate currently checks vertical
activation, query/revision, and width but not `DashboardVisibleMode`. A
preview rail frame that shares a query/revision with an active committed cache
can enter the committed vertical painter. Its rail scene thereby becomes
dependent on unrelated vertical LRU state. The stable vertical controller also
survives an exact committed scope change without resetting its pixels, which
can place a new scope at an obsolete deep offset.

`VERTICAL_END_REACHED` is emitted whenever `_nextCursor == null` at the end of
any cache commit. A backwards reloaded page after forward completion satisfies
that global condition and produces duplicate terminal events. It is not a
forward-frontier transition.

## Chosen model

`CommittedLogViewportCache` stores page zero in a dedicated pinned-root slot.
Its row VM cost is at most `pageSize`; it does not count against the five-page
local LRU bound and is never evicted. `pageForOrdinal(0)` and root diagnostics
read that slot. The root may borrow the already-ready rail scene for its
visuals; this dependency is one way only. Rail preview paint never reads a
committed page.

The render domain is a small shared enum:

`preview frame -> railPreview`

`committed frame + exact active vertical identity -> committedVertical`

`otherwise -> railPreview`

The resolved value is the only painter selector, so painting, semantics and
hit testing cannot diverge. A committed identity is `(queryKey,
coreRevision, generation)`. On a changed identity the existing controller
jumps once to its canonical top after the frame boundary; it is neither
recreated nor reset during rail preview crossing.

The forward ready-frontier flow remains unchanged. Terminal reporting becomes
generation-scoped and fires only once when the *forward* contiguous frontier
first reaches total rows with a null next cursor. Backward local reloads do
not alter forward cursor, ordinal, frontier, or terminal state.

## State flow

```text
committed scope seed
  -> pinned root page (ordinal 0) + ready geometry
  -> forward pages prepare/commit
  -> local visible ± neighbor LRU rotation
  -> reverse visible demand
  -> root served directly, or local page keyset reload

visible frame preview      -> railPreview domain only
visible committed identity -> one explicit vertical scope reset, then
                              committedVertical only after vertical activation
```

## Verification

Test-first regressions cover root-page pinning, top geometry, no page-zero
reverse I/O, one-shot end reached, domain selection, stable-controller scope
reset, 658/1000 top-bottom-top round trips, and a rail refinement after a deep
vertical interaction. Existing 10k/50k/100k cache tests prove heavy-page and
text-layout bounds. No golden test is added; the physical capture remains the
final device validation.
