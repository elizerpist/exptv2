# Open-rail parent transition implementation plan

## Goal

Fix the parent–child ownership race when SummaryPill parent navigation occurs
while the child rail is open, preserving the existing rail physics and cache
preview path.

## Constraints

* Do not change `ScrollPhysics`, fling constants, simulation, item extent,
  velocity mapping, snap behavior or gesture ownership.
* Keep the existing navigation controller as the sole rail state owner.
* Do not add a second query/cache owner or a golden test.
* Keep a cold target fully outgoing and coherent until the complete target
  bundle is ready.
* One final commit/build/push after the complete implementation and
  verification, per user workflow.

## Work items

1. Add failing tests for open-rail cached parent transition, ordinal clamping,
   stale settle after close, rapid latest-wins navigation and zero-I/O cached
   navigation.
2. Extend the time-navigation change model with an explicit open-rail parent
   transition and deck identity/revision. Add an atomic structural transition
   that rebases the existing carousel without recreating it.
3. Add a core orchestration path that resolves/validates a complete parent
   display bundle, selects the retained child snapshot, and publishes the
   target parent/child presentation before changing live query ownership.
4. Route SummaryPill commits through that path when the rail is open. Keep the
   existing closed-rail parent navigation path intact.
5. Add captured presentation/deck identity guards to preview and settle
   callbacks, including callbacks delivered after rail close.
6. Add latest-wins invalidation for pending open-rail parent transitions and
   reject late bundle/live results without visual mutation.
7. Make seed readiness explicit for bundle request/registration/publication and
   invalidate pre-seed revision-0 work after seed commit.
8. Add structured diagnostics/counters for parent/deck/expected/snapshot keys,
   accepted/rejected callbacks, atomic publishes and cached-navigation I/O.
9. Run targeted tests, relevant non-golden dashboard suite and analyze; update
   the checklist honestly.
10. Commit once, push the feature branch, trigger the online build, and
    download the resulting APK only after all checks are green.

## Verification gates

* Cached July 27 → June 27 is visible after one pump with one coherent target.
* July 31 → June clamps to June 30; March 31 → February clamps to February
  28/29.
* No old callback mutates state after close or parent replacement.
* Cached transitions have zero repository/native reads before visible publish.
* Cold transitions have no mixed keys, dash or false zero.
* Rail controller/position/physics identity and existing preview tests pass.
* No golden tests are added.
