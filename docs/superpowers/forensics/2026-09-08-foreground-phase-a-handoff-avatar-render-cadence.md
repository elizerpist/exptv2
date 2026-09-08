# Forensics — foreground Phase-A handoff and Avatar render cadence

## Previous work reused, protected and corrected

`fc35c1b` corrected Avatar's cold Phase-A admission: it retains one latest
Avatar candidate, keeps its original visible-frame interaction order, binds
the exact `budgetAvatarPreview` resource, and resumes on the real completion
boundary. Its automated tests prove that transaction and its protected
Mind/Slider boundaries. It did not prove physical Avatar frame cadence or a
Budget-progress pixel acknowledgement: prior AVP-04 was `PARTIAL`, AVP-10 was
`NOT DONE`.

The fresh retained Time session proves a different defect. At Summary pointer
acceptance, `priorMotionLanes=budgetAvatar`; after Summary preemption,
`motionLanes=budgetAvatar`. The Time resource request begins roughly 600 ms
after the later Avatar settle, while non-empty Time targets have already been
published and rejected by the renderer. That is a foreground ownership and
Time painter-readiness gap, not evidence to rewrite the repaired Avatar
transaction or carousel physics.

## Evidence limits

The supplied Avatar and Time logs are two independent sessions. The primary
Avatar fling is outside the retained Avatar document; detailed cadence is not
inferred from it. The retained Time session contains a short Avatar flight
with device FrameTiming and demonstrates post-store render cost, but not the
exact root cause of the first pointer-to-crossing delay.

## Rejected hypotheses at this stage

- Budget progress arithmetic is not the first 100 ms bottleneck: its model
  bind follows the retained semantic preview in roughly 3 ms.
- Database/index/scene preparation at Avatar or Time semantic ticks is not
  supported by the trace counters.
- Header collapse is not established as the Time data cause; it predates the
  unhealthy flight in the retained trace.
- Unequal semantic tick intervals alone do not establish a physics defect.

## Reproduced failing boundary

The baseline-compatible control uses real `DashboardCoreController`, visible
store, presentation controller and `DashboardLogBoxPreparedSceneCache` owners.
It starts `budgetAvatar` motion, begins its live resource work, then calls
`noteSummaryDirectPointerDown()` before Avatar `ScrollEnd`. On unmodified
`fc35c1b` it fails the assertion that the Time resource has begun preparation:

```text
Expected: true
Actual: <false>
Time resource preparation must start on the foreground pointer, not after the old Avatar ScrollEnd.
```

This is the deterministic source-level reproduction of the retained device
ordering, not an inference from changing semantic cadence. It passed after the
repair. The test's old-source control deliberately uses only APIs that existed
on `fc35c1b`; it does not depend on a new test-only hook.

## Root cause and repair

`noteSummaryDirectPointerDown()` previously interrupted the Time rail's own
motion kernel but neither removed `budgetAvatar` from `_activeMotionLanes` nor
revoked its foreground cache work. Consequently a new Time semantic candidate
could be accepted while it had no exact `timePreview` readable resource.
`_publishPreparedSegmentedTemporalTarget()` logged that miss but still
published the non-empty semantic frame, leaving the single renderer with the
unreadable 13 px preview payload.

The repair introduces a deliberately small `_DashboardForegroundDirectProducer`
coordination state in the Core controller. A raw pointer claims the latest
producer before arena completion. The claim:

- invalidates obsolete logical callbacks / deferred candidates;
- revokes only the obsolete typed live-resource lease;
- clears only the obsolete producer motion lane;
- preserves the already valid visual frame until the incoming exact resource
  is available; and
- never recreates the physical carousel controller or changes its physics.

Time now binds the existing `timePreview` typed Phase-A resource before it can
publish a non-empty target. Its cold path retains one original-order,
latest-wins candidate, requests the exact cache window immediately, and
promotes only from that cache completion boundary. Superseded candidates get
an explicit terminal diagnostic; the final exact paint occurs before settle in
the production-parent regression.

The cache investigation also exposed a separate exactness bug: a same semantic
key could reuse a live bank whose surface width/device-pixel ratio no longer
matched. The cache now asks `hasLiveInteractionResourceWindow` rather than the
weaker candidate-window predicate before reuse. The new same-key, changed-
metrics regression fails on the old condition and passes with the exact live
window check.

## Avatar measurements and deliberately withheld optimization

The repair adds bounded acknowledgements at the actual Header and
Budget-progress visual boundaries, plus a first-Avatar pipeline summary from
pointer acceptance through resource bind, store, LogBox paint and raster. The
renderer callbacks reject stale immutable target generations. The diagnostic
switch is disabled in normal release builds; the established human/profile APK
scripts enable it explicitly.

No Avatar layout, repaint-boundary, shader or physics change was made. The
retained evidence establishes a post-store cost but does not yet identify one
specific invalidation as the device culprit. Implementing a speculative
render-isolation change would have violated the measured-only constraint.

## Source and test impact audit

| Shared owner | Current role and protected consumer | Repair / regression coverage |
| --- | --- | --- |
| `DashboardCoreController` | Owns lanes, semantic scheduling and the existing Avatar candidate transaction. | Typed foreground handoff; Avatar→Time and Time→Avatar persistent-owner tests; stale `ScrollEnd` cannot re-arm Avatar. |
| `DashboardLogBoxPreparedSceneCache` | Sole Phase-A row resource authority for `budgetAvatarPreview` and `timePreview`. | Lane-only cancellation plus exact live-window reuse test; no second cache. |
| `DashboardPresentationController` | Keeps Time semantic/navigation ownership. | Receives the preserved interaction order for the exact Time bind; no new visible authority. |
| `DashboardVisibleFrameStore` | Sole ordering and visible-frame authority. | Cold Time retains its prior valid frame; no blank/13 px non-empty publication. |
| `DashboardBudgetPresentationController` | Existing atomic Budget Header/progress owner. | Model vsync correlation and stale-safe Header paint acknowledgement only. |
| Avatar rail / Header renderers | Existing physical and paint owners. | Bounded Header/progress build/paint/raster diagnostics; no geometry/physics changes. |
| Mind/Slider | Protected unrelated presentation and query behavior. | No production source diff; protected range/query tests passed. |

The current-source audit found no new `Future.delayed`, repository read, index
build, canonical query commit, rich-scene preparation or `TextPainter`
construction in the Time/Avatar semantic bind path. Existing cache preparation
continues to own expensive work outside that exact binder boundary.

## Validation classification

- Atomic implementation commits are `f39091d2` (handoff/Time Phase A) and
  `5b43a647` (Avatar paint diagnostics). Delivery and final-SHA graph evidence
  deliberately remain outside those source commits until the online build has
  completed.
- Deterministic correctness: repaired Time foreground handoff, exact Phase-A
  admission, latest-wins coalescing, collapse independence, reverse takeover,
  Avatar preservation and Budget-progress actual-paint acknowledgement are
  proven by production-parent tests.
- Local static/automated validation: analyzer, broad application and fast
  suites, focused tests, protected Mind/Slider and carousel physics tests
  passed. The full presentation suite's 19 failures are exactly baseline
  failures on `fc35c1b`; no unrelated golden update was made.
- Physical performance: still unproven. New device/profile data must establish
  first-target latency split, actual Header/progress pixel timing and whether
  a measured render isolation is warranted.
