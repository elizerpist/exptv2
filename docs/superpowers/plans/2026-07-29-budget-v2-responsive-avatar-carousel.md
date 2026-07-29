# Budget V2 responsive avatar-carousel remediation plan

## Decision

The standard Budget screen is the implementation reference. Its category rail
keeps every crossed tick local, cancels a prior pending publication when a new
gesture begins, snaps the local rail, then publishes only the final category
filter after a 360ms idle boundary. Budget V2 will use that same lifecycle.

The existing V2 implementation is replaced at the rail boundary rather than
accumulating more flags in `SpendeeBalanceTickingViewport`. It hard-codes a
`378px` viewport and a `189px` anchor, while the latest Android screenshot is
narrower than that viewport; this is the direct source of the horizontal
offset. Its immediate settled callback also synchronously reaches
`TransactionStore.applyBudgetV2AvatarFilter`, whose `notifyListeners()`
triggers a measured 51–289ms balance-frame rebuild.

## Acceptance mapping

- [x] BUDGETV2-037 — responsive, actual-viewport centre.
- [x] BUDGETV2-038 — isolated V2 avatar-carousel owner.
- [x] BUDGETV2-039 — interaction epochs, exact-tick circle, no stale settle.
- [x] BUDGETV2-040 — port normal Budget idle category-filter publication.
- [x] BUDGETV2-041 — concise interaction diagnostics only.

## Work sequence

1. Add RED widget/production-host regressions for the real viewport centre,
   an interrupted/restarted drag, exact tick selection, and one final idle
   filter publication.
2. Create `spendee_budget_v2_avatar_carousel.dart`. It owns a
   `SpendeeCenterCarouselController`, drag, snap/cancel animation, interaction
   serial, five visible slots, responsive `LayoutBuilder` centring, and a
   builder callback for the V2 Fluvi disc.
3. Turn `SpendeeBudgetV2AvatarBelt` into a thin visual adapter. It supplies
   the V2 disc/long-press widgets and never owns physics or a fixed width.
4. Rewire `SpendeeBalanceDashboard` to cancel/schedule final filter
   publication with the normal Budget's idle delay. Direct drag never rebuilds
   the dashboard or store during movement; chart-originated remote requests
   retain their existing stepped previews.
5. Run targeted tests and scoped analysis in Ubuntu proot, inspect the
   rendered mobile geometry, update the checklist/evidence honestly, then
   commit, push, trigger GitHub Actions, and download the debug APK.
