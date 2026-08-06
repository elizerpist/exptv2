# Dashboard rail/presentation isolation implementation plan

Date: 2026-08-06

Execution mode: one agent, inline. The diagnostic and targeted presentation
changes share the same gesture/publish/widget state and are sequential; the
user also explicitly prohibited delegation.

Design:
`docs/superpowers/specs/2026-08-06-dashboard-rail-presentation-isolation-design.md`

Acceptance gate:
`docs/superpowers/checklists/2026-08-06-dashboard-rail-presentation-isolation.md`

Root-cause audit:
`docs/dashboard/dashboard-rail-presentation-isolation-root-cause.md`

## 1. Freeze and verify the milestone

- Record exact source/milestone commits, branches, tag and SHA-256 inventory.
- Run the full 237-test non-golden baseline and Flutter analyze in Ubuntu.
- Preserve all untracked user artifacts.
- Record current A–J zero-navigation-I/O counters and density timing gap.

## 2. Add diagnostic contracts test-first

- Add RED tests for disabled no-op behavior, bounded ring capacity, stable
  gesture IDs and aggregate sample percentiles.
- Add RED controller/widget tests for gesture/release/ballistic/metrics/
  activity/settle typed events and identity snapshots.
- Add RED presentation tests for apply start/end timing and counter deltas.
- Implement the minimum optional observer hooks without changing controller,
  ScrollPosition or physics behavior.

## 3. Build the deterministic 30-run harness

- Add fixed-cadence pointer scripts and immutable density fixtures.
- Cover the required month/day and year/month pair matrix in both directions.
- Serialize only post-settle aggregates into the profile report.
- Run the pre-fix harness and preserve the machine-readable evidence.

## 4. Prove the first divergence

- Compare release velocity, ballistic input, simulation geometry, activity
  sequence, metrics/endpoint and render timings in order.
- Correlate the first divergence with concrete listener/build/layout/paint
  timestamps and counters.
- Update the root-cause document with the proven cause before behavior edits.

## 5. Write the causal regression test

- Encode the failing paired trace at the smallest responsible boundary.
- Add O(1) apply, no root/Summary/rail/SVG rebuild, activity continuity,
  layout stability and immediate-repeat assertions as applicable.
- Run focused RED tests in Ubuntu and capture the expected failure.

## 6. Apply the targeted isolation

- Keep `DashboardVisibleFrame` atomic and expose constant-time identity-based
  leaf lanes only where the trace proves fanout.
- If LogBox structure is causal, retain one State/controller/lazy viewport and
  switch it to a preflattened immutable item reference with stable IDs.
- Keep rail subtree independent from all prepared content lanes.
- Do not alter physics/spec constants, gesture thresholds, scroll commands or
  semantic crossing rules.

## 7. Verify deterministic invariants

- Run O(1) apply, 2% velocity, half-extent/one-child endpoint, zero
  interruption/metric change, first/tenth, 0/2/9-day, 0/94-month and rapid
  repeat tests.
- Run 100-crossing rebuild/identity/no-data-work tests.
- Re-run the same 30-run matrix and compare pre/post evidence.

## 8. Profile and release gate

- Run all ten requested profile scenarios with verbose FLOW disabled.
- Report apply/UI/raster percentiles, endpoint/velocity parity, allocation/GC,
  rebuilds, metrics and activities.
- Run the full non-golden suite and analyze in Ubuntu; run architecture and
  native boundary checks relevant to unchanged data acquisition.
- Recompute source hashes and inspect the semantic diff for prohibited tuning.
- Update every checklist status honestly; any FAIL remains not merge-ready.

## 9. Commit, push and online build

- Commit the coherent result on the work branch and push it.
- Run GitHub Actions tests/profile/APK build because local Termux APK builds
  are unsupported.
- Download the successful APK to `/storage/emulated/0/Download/fluvi` only
  after the checklist is complete, and record its SHA-256.
- Produce the requested 18-part factual report and exact physical-device
  validation steps.
