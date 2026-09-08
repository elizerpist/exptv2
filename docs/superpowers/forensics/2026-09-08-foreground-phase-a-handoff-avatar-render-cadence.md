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

## Follow-up — close the profile artifact gap without faking physical evidence

The first online delivery's A–J profile matrix passed, but inspection of every
exported JSON found no `avatar`, `budget_avatar`, or `BUDGET_AVATAR` event.
`I_first_fling` is a Time-rail flight, so its FrameTiming cannot substantiate
an Avatar acceptance or Avatar presentation claim.

The follow-up adds `K_avatar_first_target` to the same production-composition
matrix. It mounts a new `FluviApp`/`CoreDashboard`, reaches Budget through the
real Header gesture, and flings `budget-target-avatar-carousel`; it does not
call a test-only focus, cache, scene or presentation preinstaller. A bounded
observer reads only the existing Core `budgetAvatarTargetPainted` notifier and
diagnostic events produced by the existing Avatar rail. The exported evidence
requires:

- a real Avatar motion-lane claim and semantic crossing;
- an accepted preview and exact readable Phase-A LogBox paint;
- the final exact paint's query/revision to match the current visible frame;
- an actual `BUDGET_PROGRESS_PAINTED` acknowledgement for an exact-painted
  Avatar target; and
- exactly one first-target terminal pipeline summary, including explicit
  coalescing when the first crossed target is superseded in the same fling.

The A–K widget-test timeout and finite driver watchdog are extended to keep
the expanded deterministic matrix from racing report upload. This does not
alter production gesture, scheduler, cache or physics behavior. Local
report-contract, boundary, Avatar-rail and app-shell tests pass. The online
artifact and its real output remain required before this profile evidence can
be marked complete; emulator FrameTiming remains non-physical and cannot close
AVP-04/AVP-10 or physical acceptance.

## Follow-up — initial cold LogBox paint is also Phase-A-gated

The first A–K profile attempt (`34259701012`) reached the new Avatar scenario
but failed its final report audit because `I_first_fling` contained one
`visiblePayloadWithoutDrawable`. This is not a DPR diagnosis or a reason to
weaken the audit. During normal app startup `FluviAppShell` mounts the real
`CoreDashboard` at `renderCriticalWarmup` behind its opaque readiness surface.
The stable LogBox surface receives the non-empty initial Time payload before
its first exact-width `timePreview` bank has finished; its layout callback
correctly starts the warmup, but its same-frame `CustomPaint` also attempted to
paint the unreadable payload.

The production-shell FPA-17 test supplies a real populated prepared index and
the physical device metrics used by the profile. It was red on `c2a9046f` with
`visiblePayloadWithoutDrawable=1`. The repair threads the existing
`DashboardInteractionReadiness` state through the existing one Core,
viewport, and render surface. Only while that startup readiness state is
active, a non-empty target without a complete exact Phase-A bank:

- remains on the same stable surface and still reports attach/layout so the
  exact-width warmup starts;
- suppresses presentation and extent acknowledgement, as well as the actual
  `CustomPaint`, for that one unready viewport; and
- emits one bounded `LOGBOX_INITIAL_PHASE_A_PAINT_DEFERRED` diagnostic.

When the cache notifies exact completion, the same surface resumes its normal
paint and acknowledgement path. The green regression proves an exact live
Time resource, two actual row paints, one defer event, and no unreadable
payload counter. It does not create a cache, store, LogBox, overlay, retry, or
general cold-publication exception; later direct-manipulation cold targets
remain protected by the existing Time/Avatar Phase-A contracts. An online A–K
profile rerun is still required before this profile-derived invariant can be
closed.

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
- The later initial-readiness repair repeated that validation: format and
  analyzer passed; its production-shell regression, app shell, LogBox
  viewport/query-preview/continuity, Core, Avatar rail, dashboard application,
  fast, and protected Mind/Slider tests all passed. Its full presentation run
  again ended at `595` passing and `19` inherited failures; generated golden
  failure images were discarded.
- Physical performance: still unproven. New device/profile data must establish
  first-target latency split, actual Header/progress pixel timing and whether
  a measured render isolation is warranted.
