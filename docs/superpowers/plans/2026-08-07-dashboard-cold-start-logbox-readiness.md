# Dashboard cold-start LogBox readiness implementation plan

Date: 2026-08-07

Execution mode: one agent, inline. Readiness ownership, the mounted surface,
resource preparation and render diagnostics share one sequential lifecycle;
delegation would create conflicting edits and the user explicitly prohibited
subagents.

Design:
`docs/superpowers/specs/2026-08-07-dashboard-cold-start-logbox-readiness-design.md`

Acceptance gate:
`docs/superpowers/checklists/2026-08-07-dashboard-cold-start-logbox-readiness.md`

## 1. Preserve and close the evidence gap

- Preserve the milestone branch/commit/tag and frozen SHA-256 inventory.
- Retain baseline full tests/analyze and the pre-fix density traces.
- Document why the previous “first fling” fixture was already warm and why a
  deterministic release velocity cannot detect real pointer starvation.
- Inventory every first-use/cache/render path after the old bootstrap gate.

## 2. Add RED architecture and readiness tests

- Assert one `DashboardInteractionReadiness` owner and reject the old bootstrap
  controller as a parallel lifecycle source.
- Assert phase ordering and prevent `ready` before a valid prepared frame,
  resource preparation and first normal LogBox presented-frame acknowledgement.
- Assert all dashboard navigation intents are disabled before `ready`.
- Fail closed on hidden/offstage/IndexedStack/full-child prewarm and physics
  file changes.

## 3. Add RED stable-surface and resource tests

- Assert empty/populated/24-row/94-entry frames retain one LogBox State,
  controller and render-object identity.
- Assert payload density cannot create N transaction row widgets, sliver
  children, semantics subtrees or repaint layers.
- Assert category LogBox paint has no vector decode or per-row tint saveLayer
  and all required bounded resources exist before `ready`.
- Preserve tap semantics, floating header, explicit paging and visual geometry
  through non-golden widget assertions/direct inspection.

## 4. Replace bootstrap with interaction readiness

- Implement the immutable readiness snapshot and single lifecycle controller.
- Move index/bootstrap and canonical asset preparation under the same owner.
- Mount exactly one normal `CoreDashboard` during `renderCriticalWarmup`, keep
  spinner overlay and interaction gate closed, then await the current LogBox
  surface's presented-frame acknowledgement.
- Remove `DashboardBootstrapController` and update retry/disposal tests.

## 5. Implement the stable bounded LogBox renderer

- Extend prepared row/payload geometry only where worker-side preparation can
  eliminate interaction work.
- Replace the empty/populated structural sliver switch and per-row widget tree
  with one stable bounded render surface and reusable text painters.
- Paint only viewport-visible prepared slots plus bounded overscan; retain one
  vertical controller and explicit near-end page behavior.
- Add bounded hit-testing/semantics without recreating a full child tree.

## 6. Prepare rail-critical render resources

- Extend the existing vector atlas with bounded DPR-aware category icon and
  badge rasters; do not introduce a second asset cache.
- Prepare/pin current device-scale resources before readiness and eliminate
  per-row tint saveLayer from the LogBox renderer.
- Record resource byte estimates and reject post-ready critical misses.

## 7. Add diagnostics and true cold-first regression gates

- Add focused bounded readiness/first-use/cache/LogBox-presentation events and
  integrate them with the existing motion flight IDs.
- Correct the fixture so “first fling” occurs immediately after readiness with
  no pre-measurement rail/payload warmup.
- Add first/tenth and empty/populated matrices plus a physical-device report
  export path; never stdout-log the motion hot path.

## 8. Verify, profile and deliver

- Run focused tests after every RED/GREEN step, then full non-golden tests,
  analyze, architecture boundaries and `git diff --check` in Ubuntu proot.
- Recompute frozen hashes and scan for prohibited physics/debounce/prewarm/
  golden patterns.
- Commit/push the branch and milestone/tag, run exact-commit GitHub tests,
  profile and APK workflows, then download the APK to
  `/storage/emulated/0/Download/fluvi`.
- Keep physical-device acceptance `BLOCKED` until the exported device report
  confirms first/tenth parity; do not label the branch merge-ready otherwise.
