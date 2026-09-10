# Avatar fling pacing — forensic checkpoint

## Scope and immutable evidence

- Tested physical source: `33ee878b070345c336bb73df2b087d9a63c87c5a`.
- Frozen source log: `docs/superpowers/evidence/2026-09-09-avatar-fling-pacing/drive-fluvi-logs-avatar-fling-1FF1BnHJ-20260909T201350Z.txt`.
- Drive document: `Fluvi logs avatar fling`
  (`1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`). Its two overlapping
  `LIVE_TAIL` copies are one session (`fluvi-1788984775790141`), not two
  runs. Deduplicate only by diagnostic sequence: union `1875..2877`, 1,003
  unique entries, 997 duplicate copies. The frozen byte length is 678,635 and
  its SHA-256 is
  `93a932cb9bb41a9bde04a9177797392f0110933017296aa03f511cf03fe86cd7`.

## Observations, not causal conclusions

- The retained settled flights accepted and painted all sampled Avatar targets.
  The direct per-tick counters were zero for repository requests, index builds,
  scene preparation and canonical persistence commits.
- The first retained flight reports build P95 `24,638µs`, raster P95
  `14,272µs`, total-span P95 `31,689µs`, and inter-tick P95 `82,996µs`.
  This establishes variable rendered frames, not their responsible subtree.
- In the same trace, target selection to Budget distribution publication is
  typically tens to hundreds of microseconds and distribution reports a cache
  hit. This excludes neither Header, selected progress chrome, LogBox, nor the
  wider framework/raster pipeline; it excludes blaming that narrow synchronous
  data publication without contrary evidence.
- The floating diagnostic button opens a dialog. No evidence says that its UI
  listener was open during the flight, so logger UI notification is not a
  proven contributor.

## Source audit and preserved ownership

The current write path is unchanged:

`BudgetTargetAvatarRail -> DashboardBudgetLogboxDrilldownCoordinator -> DashboardCoreController -> DashboardBudgetPresentationController -> DashboardVisibleFrameStore`.

The examined source has one shared carousel controller, one `ScrollPosition`,
and the existing `budgetAvatarPreview` resource lane. This checkpoint does not
touch the Carousel physics/velocity/controller identity, ScrollPosition,
geometry, Time, Mind, visual design, caches, stores or publication authority.

The newest diagnostic additions only reuse existing bounded owners:

- `DashboardCoreController` emits one accepted-target correlation record around
  its existing Phase-A publication, Phase-B staging, and synchronous semantic
  callback.
- `DashboardRenderPhaseProbe` measures the existing Budget Header amount
  subtree only in debug/`FLUVI_PHYSICAL_RAIL_DIAGNOSTICS` mode.
- The selected Avatar progress `CustomPainter` reports the duration of its
  existing `paint` call through the already-present paint acknowledgement.

The records join by existing `targetHandle`, interaction/focus generation and
visible-frame identity. They do not schedule work, retain new data, or assert
that a correlation is causality.

## Deterministic evidence

The real `CoreDashboard` test was extended test-first. It failed on the tested
head because the Header and progress records lacked subtree paint duration
fields; it passes after the diagnostic-only implementation. The complete
persistent scenario also passed locally in Ubuntu proot:

```text
AVL persistent real CoreDashboard nonempty Avatar final-target liveness
without Time scenario=persistent20cycles
01:09 +1: All tests passed!
```

That scenario drives 20 forward and 20 reverse 2,400px/s flights through the
real parent, preserves the controller/position/physics identities, verifies
each exact final Budget/Header/progress/LogBox target, and keeps the bounded
candidate/cache limits. It is correctness and ownership evidence, not Android
frame-pacing evidence.

## Next admissible decision

Obtain one fresh physical diagnostic capture from this checkpoint. For each
selected target, compare `phaseAPublishMicros`, `budgetFanoutMicros`,
`headerSubtreePaintMicros`, `progressChromePaintMicros`, existing LogBox
counter deltas, and `FrameTiming` distributions. Only then choose a RED causal
gate and the smallest responsible-owner repair.

**PHYSICAL VALIDATION PENDING — USER ONLY**
