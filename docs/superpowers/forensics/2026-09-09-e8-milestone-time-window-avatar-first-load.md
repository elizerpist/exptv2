# E8 MILESTONE — ACCEPTED PERFORMANCE, OPEN CORRECTNESS EDGES

## Provenance and preflight

- Application baseline: `e8b73e3e939104164e55b09caf592f84ee59fb14`
  (`fix/foreground-phase-a-handoff-avatar-render-cadence-codex-20260908`),
  parent `b7f168dfee250a2435852e43d2499eee24ca1fb8`.
- Tooling baseline: `6926e79b716bcf70bbe51c9c44316faf522a8f39`.
  Its checked manifest names the exact application baseline, parent and
  source ref, with raw index SHA-256
  `40a217e32fa8ad22362853d2fbf96b067b592552f6af10dd7bd9955a77308d0c`.
- The graph reports 429 Dart documents, 9,842 repository-defined symbols,
  69,136 repository-local references, 20,860 edges, and 16 changed-impact
  records. It is CURRENT for e8 source navigation, not runtime proof.
- `git fetch --all --prune` confirmed the application and tooling refs before
  the new worktree was created. The original e8 worktree contains only its
  pre-existing untracked `index.scip`; the repair worktree began clean.
- No standalone persisted completion report was found under
  `docs/superpowers`. The auditable e8 record is its commit body plus the
  2026-09-08 forensics, checklist, plan, specification, architecture card,
  evidence manifest, and CI/profile artifacts.

## E8 milestone audit

The e8 diff from b7 changes only the rich-fallback diagnostic classification
in the prepared LogBox cache/render/viewport path and its focused test. It
prevents an optional rich Time scene beside an exact Avatar Phase-A fallback
from being counted as a critical failure. It does not alter cache authority,
data models, carousel physics, Mind/Slider, geometry, or layout.

Earlier commits contained by the e8 tree delivered the foreground handoff,
exact Time Phase-A/latest-wins handling, Avatar Header/progress paint probes,
and startup readiness. The 2026-09-08 checklist still records first Avatar
pipeline and measured render isolation as partial and profile/delivery
evidence as incomplete. The user has now physically accepted e8 motion quality
on Android, but not the open correctness edges below.

`MILESTONE_COMMITS.md` records e8 separately as the permanent user-accepted
motion/performance floor and rollback anchor. It intentionally does not
describe e8 as a defect-free release.

## Immutable log freeze

The byte-faithful base64 exports and CRLF-normalized readable copies are in
`docs/superpowers/evidence/2026-09-09-e8-milestone-time-window-avatar-first-load/`.
See its manifest for exact Drive timestamps, sizes, hashes, LIVE_TAIL headers,
deduplication, and normalization explanation.

- Avatar: Drive `1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`, session
  `fluvi-1788906284239925`, build `profile/e8b73e3e9391`, raw SHA-256
  `84061dead63d3c0395525e771dd6eb76119353695238c656ade7f21c01c4f683`.
  Its two snapshots retain 6205–7205 after deduplication (2,000 raw copies,
  1,001 unique events, 999 exact duplicates, zero differing duplicates).
- Time: Drive `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`, same session/build,
  raw SHA-256
  `63ab463909c311f63d24cacb2fcf0bd1fecb08d417dfb816949d3ccdd563eb59`.
  Its snapshots retain 17335–18335 with the same copy/deduplication counts.
- The documents are ordered portions of one e8 run but have a retention gap
  from 7206 through 17334. No mechanism is inferred for that gap.
- The healthy first Avatar flight is absent: its marker survives, but no
  `AV|FLING_STARTED`, `AV|PREVIEW_REQUESTED`,
  `BUDGET_AVATAR_MOTION_SUMMARY`, or
  `AVATAR_FIRST_TARGET_PIPELINE_SUMMARY` survives. Layer/geometry noise
  occupies 470 of 1,001 retained Avatar events.

## Source- and graph-assisted impact inventory

The SCIP graph was used to find each definition and its direct source/test
consumers; current e8 source was then read before conclusions.

| Symbol / owner | Source-verified role | Direct consumers / protection |
| --- | --- | --- |
| `DashboardCoreController.navigateExperimentalTemporalComponentCandidate` | Direct Segmented crossing coordinator. It calls `_publishPreparedSegmentedTemporalTarget`; on rejection e8 logs `SUMMARY_COMPONENT_LIVE_ROOT_MISS` and invokes canonical fallback. | `CoreDashboard`; `dashboard_core_ephemeral_focus_test.dart`. This repair's main red test uses the real Core parent. |
| `_publishPreparedSegmentedTemporalTarget` | e8 computes `railInteractionSceneWindowFor(candidate)` before checking the target frame and only claims direct order after frame lookup. | Core's pending Time candidate, exact cache binder, Time paint/settle flow. No new producer/cache may bypass it. |
| `DashboardPresentationController.publishPreparedExperimentalTemporalCandidate` | Existing RAM-only navigation/frame owner; validates prepared target, claims interaction order, queues the exact visible frame. | Core publication path and presentation tests. It must remain the sole visible-frame owner. |
| `DashboardDataRuntime.prepareQuery` / `commitPreparedQuery` | Existing complete prepared-index builder and later runtime commit boundary. | Query candidate flow and Core; it can build a bounded new year window without a second index owner. |
| `DashboardLogBoxPreparedSceneCache.prepareLiveInteractionResourceWindow` | Existing lane-owned Phase-A resource preparation; replacement retains the old lane resource until the new complete bank takes ownership. | `CoreDashboard`, Core tests, cache tests. `timePreview` stays its only Time resource authority. |
| `requestBudgetCategoryFocus` / `DashboardEphemeralFocusDeriver` | Avatar derives from one retained base index and current temporal scope. | Budget drilldown coordinator and Core/LogBox tests. The post-Time exception investigation must preserve this owner rather than catch-and-hide it. |

Relevant graph locations were verified for `DashboardMotionLane`, foreground
claim/preemption, Time publication and settlement, scene-cache resource lanes,
Avatar focus admission, and the LogBox cache. The graph does not establish
runtime ordering, paint completion, scheduler timing, or physical smoothness.

## Current first failing boundary

The new production-parent red test starts at an e8 2014–2038 window and asks
the real Segmented Time path for year 2010. On unmodified e8 it fails before
the intended `preparedFrameUnavailable` diagnostic branch:

```text
StateError: Prepared index has no frame for income|year:2010...
```

The immediate source boundary is
`_publishPreparedSegmentedTemporalTarget` calling
`railInteractionSceneWindowFor(candidate)` before `index.frameForKey` is
checked. That scene-window construction materializes the absent frame. This
proves the missing-frame path must transition to a bounded prepared-window
candidate before any scene-window/frame materialization.

It does not yet prove the exact later Avatar exception instruction. Source
inspection does support the leading hypothesis: canonical fallback can commit
a temporal scope not represented by the retained focus base, while
`DashboardEphemeralFocusDeriver` fails closed for such a base/scope mismatch.
The repair will add bounded typed failure evidence and reproduce the aggregate
target separately before claiming the final Avatar root cause.

## Protected and rejected alternatives

- E8 user-accepted Avatar/Time motion, physics, item geometry, semantic
  thresholds, stable controllers, and ScrollPosition ownership are protected.
- The working in-window Time exact Phase-A/latest-wins contract is protected.
- A missing target must not take e8's canonical compatibility fallback, be
  accepted with `producer=none`, publish a 13 px non-empty surface, or make
  Header collapse a data trigger.
- No second cache, visible-frame store, LogBox, index owner, global `setState`,
  retry timer, broad unbounded year universe, or performance-by-dropping-data
  workaround is permitted.
