# Design — Avatar Phase-A publication and Budget target coherence

## Goal

Restore useful Avatar semantic publication without returning to the prior accepted-but-unpaintable rail-preview state.

## Proven boundary

At 5ba6c01, `_requestEphemeralFocus` derives a valid focused index, then `_bindBudgetAvatarLivePhaseA` returns false when `budgetAvatarLiveRootReady` is false. That flag requires both the resource bank and the unrelated complete fixed hotset. The method therefore never calls the exact painter binder for the valid local target. The caller returns false before visible publication, live interaction acceptance, and the Budget target callback. There is no replay from `_primeBudgetAvatarLiveRowResources` after its resource becomes ready.

## Chosen design

1. Separate exact resource availability from aggregate prewarm status. The latter remains a diagnostic/prewarm value only.
2. For a warm exact resource, bind the exact payload immediately through the existing `DashboardLogBoxPreparedSceneCache` lane and publish with the already-issued input order.
3. For a cold resource, retain one latest-wins immutable controller-owned pending candidate and complete its original future only after the existing resource completion revalidates and accepts it.
4. Reuse the existing accepted publication sequence so Budget’s existing callback promotes the same target as the visible LogBox.
5. Keep exact empty as ready without fake row resources; retain aggregate semantics.
6. At the quick-edit boundary, ensure a visual/semantic target mismatch cannot initiate a wrong-target edit; preserve the existing fail-closed ring rendering guard.

## Non-goals

No Time, Mind/Slider, query semantics, controller ownership, cache capacity, layout, Avatar physics, or carousel lifecycle redesign.
