# Zero-lag live semantic ticks — superseding acceptance checklist

Date: 2026-08-30

Status: automated implementation and affected verification complete; build
and physical validation pending

Physical-failure reference: `0fe4d8e2f75ecb59f50530e05f2e98101a84f459`, profile `HUMAN_DIAGNOSTIC`

## Supersession notice

The newest user-only physical evidence invalidates the `M3`, `A1`, and `T1`
`DONE` declarations in
`docs/superpowers/checklists/2026-08-30-physical-feedback-round.md`.
Those declarations accepted internally published or settle-only state as live
data. The current contract requires a complete, exact and renderable visible
snapshot for every semantic tick while motion is active. The historical
milestone remains untouched and is not a device-pass claim for current HEAD.

## Architecture card

### Scope and authoritative inputs

- User requirement: `FLUVI — ZERO-LAG LIVE DATA ON EVERY SEMANTIC TICK`.
- Physical logs: `Fluvi logs slider`, `Fluvi logs avatar fling`, and
  `Fluvi logs time fling` from session `fluvi-1788110402702421`.
- Rejected behavior: commits `753eae63dfa8e14d735e3ef551b885c2c5048f2f`
  and `b39c9e4d3ace7dce29f5d7f207bddbfac4d05b76`.
- Behavioral control: the current Classic SummaryPill child-rail path and
  historical commit `2bccd108f312d7d7443d64ec33941804749c166c`.
- Final UI remains the Segmented SummaryPill.

### Existing engines and owners to reuse

| Concern | Existing owner | Required extension |
| --- | --- | --- |
| Raw carousel physics and crossings | `CenteredCarouselController` | None; geometry, velocity, friction, haptics and tick positions are protected. |
| Live interaction ordering | `DashboardLiveInteractionCoordinator` | Carry a complete typed semantic identity rather than a partial target hint. |
| Prepared data | `PreparedDashboardIndex` and focus membership/hotset owners | Arm complete finite time/avatar live roots before input; reuse row resources for continuous Mind ranges. |
| Visible state | `DashboardVisibleFrameStore` | Publish one complete live generation across navigation, amount, count and LogBox lanes. |
| LogBox physical resources | `DashboardLogBoxPreparedSceneCache` and `CommittedLogViewportCache` | Select a complete pre-armed root synchronously; never start layout from a tick. |
| Canonical state | existing navigation, Query and focus controllers | Promote the already-visible latest live target once at settle/release. |
| Budget projections | `DashboardBudgetPresentationController` and prepared Budget snapshots | Bind to the same live identity; never retain a partition from another target. |

### Single write path and publication invariant

One accepted semantic target resolves to one immutable live semantic identity,
one complete RAM-derived snapshot and one atomic visible commit. All affected
leaves are staged before any listener is notified. Separate rebuild lanes may
remain, but they must cross one generation barrier. Canonical promotion may
change ownership metadata only; it must not create the first visible data
change.

### Reuse and non-duplication decision

No second Query authority, navigation controller, transaction-list renderer,
cache universe, scroll controller or motion engine will be added. The repair
extends the existing live-interaction, visible-frame and prepared-scene owners.
Classic contributes its prepare-before-input and same-frame-coalesced publish
boundary; its layout is not copied.

### Layer flow

`raw motion -> semantic crossing -> prepared live-root lookup -> stage complete
identity/frame/resources -> atomic visible generation -> existing Summary,
LogBox and Budget renderers -> metadata-only settle promotion`

### Invalidation and bounds

- A live snapshot is valid only for its core revision, prepared-index identity,
  canonical base Query, direction, time/focus/range target and layout profile.
- Stale generations are rejected before staging or activation.
- Time and Avatar hotsets are finite and bounded by their semantic catalogs and
  the prepared-scene cache's row/byte limits.
- Mind retains exact amount-sorted membership and reuses row resources by
  immutable row content identity; only the bounded first visible root is
  assembled for an arbitrary range.
- No unbounded ledger copy, candidate list or scene bank is permitted.

## Acceptance inventory

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| REF-01 | Classic behavioral control | `time_refinement_rail.dart`, current Classic presentation controllers | Existing DAY/MONTH/YEAR immediate child behavior remains unchanged and is covered as a control. | Focused Classic widget/controller tests and code inspection. | DONE |
| LIVE-01 | Complete live identity | `dashboard_live_interaction_coordinator.dart`, visible-frame domain | One typed immutable identity covers source, interaction/tick generation, direction, Query keys, temporal/focus/range target, revision/epochs and prepared-index identity. | Unit identity/stale-generation tests. | DONE |
| LIVE-02 | Atomic visible publication | `dashboard_visible_frame_store.dart`, presentation controller | Navigation, amount, count and LogBox lanes expose one generation; normal interaction has `mixedProjectionCount=0`. | Store tests plus production-parent consistency assertions. | DONE |
| LIVE-03 | Metadata-only settle | Core navigation/focus/query promotion | Settle/release promotes the latest visible target once and produces `settleVisualDeltaCount=0`. | One-frame crossing tests followed by settle identity/digest assertions. | DONE |
| TIME-01 | Segmented DAY/MONTH/YEAR ticks | Core temporal candidate path and prepared revision bundle | Every crossing publishes exact Summary, amount/count, LogBox and time-sensitive Budget data by the next frame; no wait for settle. | Controlled one-frame tests for DAY, MONTH, YEAR, both directions and multiple crossings. | DONE |
| TIME-02 | Time live-root readiness | Summary/scene hotset owners | Every reachable active component target has a complete renderable first LogBox root before input. Crossing starts zero repository/native/index/scene/text-layout work and has zero cache misses. | Cache-operation counters and retained-root tests. | DONE |
| LEVEL-01 | Segmented level selector | `summary_pill_experiments.dart`, Core level candidate path | Each SUM/YEAR/MONTH/DAY level tick publishes complete exact data within one frame, with no stale crossfade or cooldown. | Primary-selector one-frame widget tests in both directions. | DONE |
| AV-01 | Complete Avatar tick | drilldown coordinator, focus hotset, Budget presentation | Every target crossing publishes exact focus, rows, Summary, Header, limit, partition, distribution and Rhythm under one identity; `partitionRetainedFromPreviousTarget=false`. | Eight-crossing prepared-hotset tests and production-parent identity checks. | DONE |
| AV-02 | Avatar settle | Core focus promotion | No repository/index/foreground-scene work at tick; settle performs at most one canonical promotion and no visible change. | Operation counters and before/after visual digest assertions. | DONE |
| MIND-01 | Drawable live rows | Mind preview, visible-frame store, LogBox caches/viewport | A non-empty range has payload rows, equal drawable root rows and painted rows before `onChangeEnd`; zero text/rail-cache misses. | Real `DashboardLogBoxViewport` one-frame widget tests. | DONE |
| MIND-02 | Stable interactive control | amount domain/range control | Domain remains stable, slider Element/State remains mounted, no loading flash, latest same-vsync value wins and one canonical release commit occurs. | Existing and expanded controller/widget tests. | DONE |
| PERF-01 | Hot-path work limits | typed interaction metrics and existing counters | Per tick/update: zero repository/native/index/foreground-scene/TextPainter work; no controller/position/physics replacement and no tick reduction. | Deterministic counter tests and bounded summaries. | DONE |
| PERF-02 | Render timing observability | flight/drag summary recorders | Accepted snapshots equal semantic ticks; late-over-one-frame, mixed identity, drawable miss, text miss and scene miss counts are zero. | Recorder unit tests and profile handoff logs. | DONE |
| MEM-01 | Bounded resource ownership | prepared index/scene/row caches | Finite target banks and arbitrary-range first-root reuse remain within explicit row/byte/count limits with revision/layout eviction. | Cache bound/eviction tests and reported estimates. | DONE |
| REG-01 | Protected mechanics | centered carousel, controllers, ScrollPosition, palettes, diagnostics, collapse | Physics, identities, 1000-row console, Header color, collapse regression, Query independence and Budget persistence remain unchanged. | Existing focused regression groups and diff inspection. | DONE |
| DOC-01 | Auditable record | this checklist and superseding decision record | Ten required causal decisions, commands and honest results are recorded without editing `MILESTONE_COMMITS.md`. | Final checklist reread. | DONE |
| BUILD-01 | Exact committed artifact | Git/GitHub Actions | Tested committed SHA is pushed; profile human-diagnostic APK for that SHA is downloaded and SHA-256 verified. | GitHub run identity, local artifact and hash. | NOT DONE |
| DEVICE-01 | User-only physical gate | handed-off APK | User tests Classic control, Segmented time/level, Avatar and Mind. Agent makes no device-pass claim. | User feedback in a later round. | BLOCKED |

## Evidence baseline

- Slider retained range: seq `1481..2135`; 54 preview frames, 50 preview
  extents with non-empty payload but `drawableRowCount=0` and
  `paintedRowCount=0`, plus 50 text-layout and 50 rail-critical cache misses.
- Avatar retained range: seq `2162..2818`; 23 target crossings all report
  `canonicalFocusPublished=false`, `indexPublished=false`, and
  `partitionRetained=true`; five flights each publish canonically at settle.
- Time retained range: seq `2162..2819`; two eight-tick flights both report
  zero transient navigation/query/index/scene work and one settle commit.
- The Avatar and time documents overlap one session; event identity is
  deduplicated by session plus sequence, not by copied document text.

## Decision record

### D01 — Why time ticks became settle-only

Question: Why does a Segmented component crossing not update live data?

Evidence inspected: `753eae63`, current
`navigateExperimentalTemporalComponentCandidate`, `b39c9e4d`, and the two
`TM|FLIGHT_SUMMARY` events.

Conclusion: Confirmed. The crossing callback only increments cadence counters;
the first semantic publication is explicitly deferred to settle.

Decision: Replace the rejected counter-only contract with a strict prepared
live-root activation and complete one-frame publication; settle becomes a
promotion/no-op boundary.

Status: confirmed; implementation DONE.

### D02 — Why Avatar ticks became partial

Question: Why can the selected Avatar/Header change while rows and diagrams do
not?

Evidence inspected: current drilldown early return, `previewTargetHandle`, 23
`AV|TARGET_PREVIEW_BOUND` events.

Conclusion: Confirmed. The physical handle path bypasses focus/index/LogBox
publication and deliberately retains the previous partition.

Decision: Use the prepared focus hotset to activate and publish a complete
target snapshot atomically; remove the partial early-return product path.

Status: confirmed; implementation DONE.

### D03 — Why Mind previews were not drawable

Question: Why can `MIND|PREVIEW_FRAME published=true` produce no visible rows?

Evidence inspected: `publishPreparedInteractionPreview`, viewport preview-root
arming and slider log seq `1481..2135`.

Conclusion: Confirmed. Compact payload lanes publish first; exact-width rich
row/text scene resources are armed asynchronously only after publication, so
the rail-preview painter correctly fails closed.

Decision: Reuse stable row resources and synchronously select a complete
pre-armed first root before atomic preview publication.

Status: confirmed; implementation DONE.

### D04 — Classic boundary

Question: Which Classic behavior is reusable without restoring its UI?

Evidence inspected: Classic `TimeRefinementRail`, historical `2bccd108`, and
the old live-preview-bundle design.

Conclusion: Confirmed. Classic prepares an immutable bounded preview before
input and coalesces only same-frame samples, then atomically publishes full
visible data. Its layout is unrelated.

Decision: Reuse the preparation/publication boundary, not the Classic widget
layout or an additional controller.

Status: confirmed.

### D05 — Shared live snapshot owner

Question: Can the requirement be met without a new state authority?

Evidence inspected: `DashboardLiveInteractionCoordinator`,
`DashboardVisibleFrameStore`, presentation lanes and prepared-scene cache.

Conclusion: Confirmed. Existing owners already cover intent ordering, atomic
visible data and physical row resources; their partial contracts need one
shared identity/generation barrier.

Decision: Extend these owners; do not add a second Query, navigation or list
system.

Status: confirmed; implementation DONE.

### D06 — Time targets are armed before crossing

Question: How can a DAY/MONTH/YEAR crossing publish without foreground scene
work?

Evidence inspected: retained rail-window coverage, active-bank coverage,
`_adjacentPlanePublicationSceneHotset`, production-parent one-frame tests and
scene prepare counters.

Conclusion: Confirmed. The complete finite active component window can be
prepared while idle. A crossing needs only retained/active coverage adoption,
prepared-frame selection and visible publication.

Decision: Arm the full active component window, accept crossings only through
`_publishPreparedSegmentedTemporalTarget`, and treat a live-root miss as an
explicit invariant failure rather than silently leaving old data visible.

Status: confirmed; implementation DONE.

### D07 — Avatar targets use a complete hotset plus one row-resource bank

Question: How can aggregate and category targets replace the LogBox and Budget
projection without rebuilding rows at each crossing?

Evidence inspected: prepared focus derivations, focus hotset keys, the base
membership seed, `previewTargetHandle`, category/aggregate production-parent
tests and the eight-crossing controller test.

Conclusion: Confirmed. Focus membership and Budget projections are finite per
target, while row paragraphs are shared by immutable row/layout identity.

Decision: Require both the complete focus hotset and shared row-resource bank
before accepting Avatar input; activate the exact category or aggregate root
before publishing its complete prepared frame. The partial target-only method
was removed.

Status: confirmed; implementation DONE.

### D08 — Arbitrary Mind ranges reuse immutable row resources

Question: How can a continuous range build an exact first root without one
prepared Query scene per possible slider value?

Evidence inspected: amount-sorted resident membership, compact preview
payloads, `_RowLayoutKey`, retained resource leases and the real viewport paint
test.

Conclusion: Confirmed. Membership and ordering depend on the exact range, but
row text/layout resources do not. They can be retained once per revision and
layout profile, then selected into a compact exact root synchronously.

Decision: Retain one live resource bank capped by the existing 8,192 pinned-row
limit; assemble only the exact first live payload, preserve canonical ordering,
and stage it through the production cache/viewport. No alternate renderer or
unbounded scene family was added.

Status: confirmed; implementation DONE.

### D09 — Segmented level lag came from the full navigation path

Question: Why did the Segmented SUM/YEAR/MONTH/DAY selector not have the same
immediate behavior as an armed child component?

Evidence inspected: `navigateExperimentalTemporalSelection`, structural
publication windows and Classic versus Segmented callback ownership.

Conclusion: Confirmed. A level crossing entered the general asynchronous
temporal candidate path instead of selecting an already-renderable structural
root.

Decision: Prepare all four structural first roots from one fixed navigation
state and route level crossings through the same prepared publication owner as
component crossings.

Status: confirmed; implementation DONE.

### D10 — Settle is no longer the first visible publication

Question: Can canonical settle change ownership without producing a second
visible data jump?

Evidence inspected: temporal equality guard, focused-scene install path,
production visible-frame digests and settle counters.

Conclusion: Confirmed. Once the exact tick target is the active visible frame,
the same-target temporal settle is a no-op and Avatar settle promotes the
already-visible focus rather than manufacturing a different preview.

Decision: Preserve the canonical settle seam, but make it idempotent for the
already-visible target and record `settleVisualDeltaCount=0`.

Status: confirmed; implementation DONE.

## Validation log

- PASS — changed-Dart format check: 16 files, 0 changes.
- PASS — full `flutter analyze`: no issues, 130.2 seconds.
- PASS — Summary/Classic/Query/amount-range/Budget-controller group: 98 tests.
- PASS — centered-carousel, live identity, Avatar, scene-window, prepared-cache,
  production LogBox paint and visible-frame group: 210 tests.
- PASS — rolling diagnostic console, bridge, build identity, interaction/render
  diagnostics and centered-carousel diagnostics group: 44 tests.
- PASS — focused production-parent paint assertions cover Mind range, Avatar
  category/aggregate, Segmented component and Segmented level publication after
  exactly one controlled frame, before release/settle.
- PASS — directly affected assertions within the broad Dashboard run, including
  Classic, centered-carousel, collapse, Header palette, Budget, Query, Mind,
  scene/cache and production LogBox paths.
- BASELINE FAILURES PRESERVED — `flutter test test/features/dashboard
  --reporter compact`: 1,072 passed and 19 failed. The failures are outside the
  changed source: Header visual RED/ticker thresholds and six environment-
  dependent Dashboard goldens. An isolated three-file rerun produced 15
  failures both before and after this task with identical failure values: one
  historical shader-ID contract (`expected 14`, `actual 18`), six golden diffs
  (`6.39%`, `7.19%`, `8.37%`, `9.00%`, `25.91%`, `7.19%`) and eight Space
  Fabric ticker contracts. Four additional Header transport timing failures
  appeared only under the 137-file parallel load; the task does not modify
  their tests or Header visual-engine source.
- PENDING — exact committed GitHub profile build and artifact hash.
- PENDING — physical validation by the user only.
