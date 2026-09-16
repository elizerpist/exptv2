# Mind Year retained transient target lifecycle repair architecture card

## Evidence and scope

The current physical failure is a cross-surface identity violation, not empty
data or slow annual projection: an Income/Year 2025 Summary and LogBox remain
visible while a previously renderer-acknowledged Year 2027 target is later
selected by `ensureMindYearHeatmapProjection()` and overwrites the heatmap
with its empty projection.  The frozen `Fluvi mind heatmap` evidence records
that overwrite twice under `cause=summaryVisualTransientYearRetained`.

This repair changes neither Time carousel motion nor query, prepared-base,
LogBox or heatmap-renderer ownership.  It is limited to the authority lifetime
of Core's renderer-acknowledged transient Year target.

## Existing ownership retained

| Concern | Sole owner | This repair may do |
| --- | --- | --- |
| Canonical Year/navigation | `DashboardNavigationController` through `DashboardCoreController` | Establish when a canonical settle supersedes a retained visual target. |
| Transient Summary visual acknowledgement | segmented Summary renderer reports a paint fact; `DashboardCoreController.noteSegmentedSummaryComponentVisualTargetPainted` validates it | Keep a validated target only while its interaction remains unsettled and authoritative. |
| Mind temporal selection/projection installation | `DashboardCoreController.ensureMindYearHeatmapProjection` | Consume exactly the currently eligible Core target, otherwise canonical Year. |
| Prepared annual data and projection | existing bounded prepared-base slot and `MindYearHeatmapLiveProjection` | Remain immutable consumers; no data rebuild, cache or new Year authority. |
| Summary UI and heatmap UI | existing widgets | Render state and forward/report intent only; neither mutates lifecycle ownership. |

## Lifecycle contract

A renderer-acknowledged transient Year `Z/G` may override canonical Year only
while `G` is the current unsettled Summary interaction that owns the visibly
painted target.  When final canonical/presented Year `Y` settles, the retained
renderer acknowledgement is demoted; in particular, an older `Z != Y` can no
longer remain eligible. Later focus, direction or presentation refreshes must
resolve to `Y`, never resurrect `Z`.

The contract intentionally does not change the legitimate 9945 transient
path: a currently painted, still-unsettled target continues to publish from
the resident immutable Mind prepared base without repository, index, scene or
text work.  A held amount-range interaction retains its existing exact held
identity until its own end boundary.

## Structuring Apps boundary rules applied

The governing local skill is `structuring-apps` at
`/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`
(no version metadata).  Its governing rules here are one state owner/write
path, UI as rendering/intent forwarding only, workflow in the controller,
reuse of the existing shared mechanism rather than a parallel authority, and
fail-closed boundary tests.  Accordingly the repair must be a Core lifecycle
eligibility correction and must not add a second Year controller, widget-local
state, cache policy, or renderer-side correction.

## Protected invariants

- Time carousel controller, `ScrollPosition`, physics, fling and pointer
  lifecycle are no-touch without new evidence.
- Canonical query, Mind direction prepared-base bound, LogBox provenance,
  slider zero-I/O hot path and calendar geometry remain unchanged.
- No timer, debounce, remount/key, cache flush, repository/index rebuild or
  full ledger scan is permitted.
- The RED must use the real CoreDashboard/segmented Summary/settle lifecycle:
  retained painted 2027 -> final 2025 -> real later refresh -> no 2027
  resurrection.

## Retained-lifecycle RED-to-GREEN result

Mounted `MYRL-01` initializes the real CoreDashboard, mounts the segmented
Year selector, publishes and renderer-acknowledges transient 2027, then
settles a distinct 2025 target through the real Core settle path.  On the
unmodified parent, its subsequent shared Core refresh failed with expected
2025 / actual 2027.  The first owner was the object-identity-only demotion in
`_settleAcceptedExperimentalTemporalComponentCandidate`: a final 2025 target
is not identical to the retained 2027 object, so that pointer remained
eligible.  The repair demotes the retained visual target on every terminal
Year/Year-plane settle.  It does not affect active transient following before
settle or the independent held-range identity.

## Product-level realtime completion gate

This card's retained-lifecycle correction is not the product completion
claim. The wider Mind Year contract is satisfied only when the existing
renderer acknowledgement path proves, with the mounted real Summary selector
and annual viewport, that every Summary Year which actually paints has the
same Mind identity in that transition and an annual heatmap paint no later
than the following render frame. Coalesced targets which do not paint are not
obligations. A terminal settle must retire obsolete targets without changing
that active transient following path.

The Core remains the sole authority chain: the selector reports a paint fact;
Core validates, derives and publishes the immutable resident-membership
frame; the viewport only paints it. No timer, settle-only fallback, secondary
Year store, query commit, repository/index admission, source-row scan,
scene/text preparation, controller replacement or physics change is an
acceptable implementation. The Time carousel, its controller, ScrollPosition
and physics are protected no-touch surfaces. The frame contract therefore
requires mounted multi-target, final-settle-refresh, held-slider and hot-path
work-bound evidence before this repair series can be reported as complete.
