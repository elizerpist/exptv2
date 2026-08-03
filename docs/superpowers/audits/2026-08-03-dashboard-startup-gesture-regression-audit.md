# Dashboard startup and gesture regression audit

## Scope

Device FLOW evidence from 2026-08-03 and the `a526738` milestone state were
compared with `c20ce0c`. This is a regression audit; it does not change the
carousel physics preset.

## Runtime and cache audit

1. **Critical — semantic event storm from viewport bootstrap.**
   `CenteredCarouselController` changes logical selection from a physical
   `ScrollController` offset as soon as a cyclic viewport attaches. Its
   initial physical offset is zero while the virtual anchor is 100000.
   `TimeRefinementRail` forwards each resulting callback through
   `previewChildLogicalIndex`, causing SummaryPill and LogBox projection work
   every 20–60 ms. The supplied logs show this as presentation generations
   21–250 without a user gesture.
2. **Critical — state-owner mismatch before first mount.**
   `DashboardTimeNavigationController` starts its `timeCarousel` at logical
   index zero even when the canonical selected child is another day. The
   first viewport and later silent re-centering therefore start from different
   logical sources.
3. **High — fallback prefetch race after direction change.**
   `prefetchLogForRailTarget` checks only whether an active bundle serves a
   child. During a new-direction finite bundle load that test permits legacy
   target prefetch, so a callback storm can issue child reads before the
   matching deck is available.
4. **No CPU/isolate issue found.** Native Room reads are asynchronous; DTO
   decode and projection are bounded by 31/12 finite children. The immediate
   failure is excessive control-flow publication, not a computation that
   needs an isolate.

## Widget/render audit

1. `TimeRefinementRail` is mounted while visually hidden. Its 200001-slot
   cyclic `ListView` must therefore have a semantic-bootstrap gate; opacity
   and `IgnorePointer` do not prevent controller callbacks.
2. The existing Header/rail/LogBox rebuild boundaries are not the source of
   the state corruption. The event storm enters below those boundaries and
   repeatedly updates the independently listenable Summary/LogBox owners.
3. No new clip, shadow, `RepaintBoundary`, physics or animation tuning is
   justified. The required fix is an ownership boundary: non-user scroll
   positioning must never write navigation semantics.

## Required fix and evidence

Keep physical centering in the centered-carousel controller, but arm semantic
preview/settle callbacks only for an explicit rail drag or tile tap. Seed the
carousel logical index from `DashboardTimeNavigationController` before mount;
block finite-parent fallback prefetch while the matching bundle is loading.
The DBR-01 through DBR-05 checklist rows are the acceptance gate.
