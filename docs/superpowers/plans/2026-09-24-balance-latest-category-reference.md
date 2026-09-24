# Plan — Balance Latest + Category Reference Redesign

## Scope and reference

The user-approved local PNG at
`/storage/emulated/0/spendee/reference/last_transacrion.png` is the visual
authority for the Category local secondary detail only. It was inspected at
941 × 1672 px, SHA-256
`803cd2f17f81e21a26a0d1b6462361b16f9313a7d156f2ca7f21570dcfc11f4b`.
It establishes a fixed, native Flutter composition: local back affordance;
rounded-square category avatar; category name; a purple MEDIÁN pill and large
median amount; two compact metric pills; divider; four-band transaction-size
distribution and labels. Its values are mock content and will not be encoded.

## Ownership and implementation shape

1. Keep `DashboardBalanceLinkedProjection` as the sole production data builder.
   Pass existing admitted category color/icon identifiers through the immutable
   latest-transaction DTO only if source inspection confirms a missing field.
   Widgets never acquire category data.
2. Keep `BalanceDashboardCoreSurface` and the existing `CenteredCarousel` as
   sole upper-rail/controller/position/physics owners. Special-case only the
   compact Latest visual hierarchy.
3. Replace only the bounded Latest lower-card `ListView.separated` with a
   non-scroll fixed composition for its maximum five immutable rows.
4. Keep `_RankedDetailState` as the local selected-entity owner. Feed its
   selected rank item's existing category visual metadata to a no-scroll
   Category detail. Do not add Core or Query state.
5. Preserve existing `CategoryVisualBadge`, distribution math and low-sample
   semantics. Use `roundedMedianAmountMinor` rather than recomputing a median.

## Validated sequence

1. Record source/reference audit and create RED tests for DTO, compact Latest,
   lower Latest, and category median/reference semantics.
2. Implement the smallest projection/renderer changes, taking each focused
   test GREEN before continuing.
3. Run production-parent bounds, retained local-detail state, carousel and
   protected Balance/Header regressions, then fast suite/analyzer/format/diff.
4. Re-read the checklist and reference before app commit. Only then push the
   final app SHA for the single required online APK build, regenerate matching
   SCIP on tooling, and write a journal-only evidence commit.

## Execution mode

Inline. The three visual changes share the same DTO, lower-card renderer,
fixtures and acceptance bounds; splitting them would create conflicting edits
without reducing elapsed work.

## Local validation evidence

- RED established the missing latest visual metadata, missing compact carousel
  hierarchy, scrollable/divided latest detail, and scrollable total/share-based
  category face before production edits.
- Focused Balance projection/detail/surface suite: 44 tests passed.
- Core ephemeral focus suite: 109 tests passed.
- Core Dashboard/mode-host/rebuild-isolation suite: 50 tests passed.
- Shared CenteredCarousel, Mind Header and Budget avatar guards: 118 tests
  passed.
- `./scripts/test-fluvi-fast.sh`: 432 tests passed.
- Full analyzer reported no issues. The final application build, APK and
  exact-source graph remain delivery work and are deliberately not claimed by
  this plan.
