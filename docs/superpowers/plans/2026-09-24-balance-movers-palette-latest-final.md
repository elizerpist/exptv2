# Balance Movers, exact palettes and Latest correction — Implementation Plan

> **Execution:** Inline. The three requested units share the linked Balance
> projection, finite carousel mapping and focused fixture set. Parallel edits
> would conflict; no second controller, query path, cache or palette engine is
> permitted.

**Goal:** Deliver Movers, all 33 exact Balance Header palette combinations,
and the corrected two-row/time-aware Latest presentation in one final build.

**Architecture:** Core projects bounded immutable Balance data exactly once per
linked identity; presentation only selects or renders it. Header tuning keeps
family × variant state in its existing dashboard-lifetime controller and reads
predeclared exact anchor arrays through the existing sampler.

## Tasks

1. Add failing pure projection tests for Movers bounded top-five construction
   and explicit latest local minutes/presentation identity. Run each against
   the unmodified `c5895c2b` source and record the missing-contract failures.
2. Make the smallest application-layer additions: import/bind the Movers
   projection to `DashboardBalanceLinkedPresentation`; cap its retained
   rendered movers and compute trends only for that cap; add
   `localTimeMinutes` to `DashboardBalanceScopedTransaction` and its
   identity. Make the pure tests green.
3. Add failing mounted Balance tests for an 11th Movers topic/local detail and
   for exactly two selected Latest rows plus date/time lower metadata. Extend
   finite topic/indicator/detail mappings and use local renderer state only.
   Make these tests green without modifying `CenteredCarousel`.
4. Add failing Header state/catalog/tuner/policy tests for 11 × 3 exact arrays,
   variant preservation and user selection. Add the explicit variant enum,
   immutable catalog dimensions and controller/tuner mutation. Make tests
   green; retain existing interpolation and all unrelated Header settings.
5. Run focused Balance/Header/Core/protected motion guards, fast suite,
   analyzer, format and diff check. Re-read this checklist before the sole app
   commit and final online human APK workflow.
6. Regenerate SCIP on tooling from the final application SHA, then write a
   journal-only evidence commit. Do not trigger a second app build from docs.

## Final delivery invariant

No APK/CI claim is final until all `MOV-*`, `PAL-*`, `LATEST-*`, `REG-01`, and
`DEL-01` items above are `DONE`; `PHYS-01` remains explicitly user-only.
