# Execution plan — foreground Phase-A handoff and Avatar render cadence

## Approved scope

The user supplied an execution-authorized forensic specification. This plan is
executed inline because the Core controller, cache coordinator, visible store,
production-parent regressions and render diagnostics share the same ownership
boundary; splitting those edits would create integration races.

## Ordered work

1. Preserve the verified `fc35` base, freeze both Drive documents, audit its
   commit/diff/milestones and verify the matching SCIP graph.
2. Inspect every direct production and test consumer of motion lanes, Time
   publication, cache binding, visible frames and Budget visuals.
3. Add production-parent red regressions for Avatar-active → Time takeover,
   Time cold exact Phase A, same-vsync coalescing, reverse takeover, collapse
   independence, Avatar first-pipeline evidence and Budget progress paint.
4. Implement the smallest typed shared foreground claim/handoff; retain all
   old renderer/cache/store/controller owners.
5. Implement Time's exact Phase-A admission and event-driven latest-wins
   continuation using the existing `timePreview` cache authority.
6. Run focused red/green tests after each logical production change.
7. Add bounded target-correlated diagnostics; profile actual Avatar
   presentation invalidation and isolate only a proven cost.
8. Validate in Ubuntu proot, audit protected source/diff, commit atomically,
   push, deliver the exact human APK, then regenerate/push a matching SCIP
   graph on the tooling branch.

## Stop conditions

Stop only for the explicit user-listed provenance/evidence/architecture
conditions. A disproved hypothesis or an initial red test is not a stop.

## Execution status before delivery

Completed:

1. Exact application/tooling preflight, frozen Drive evidence, prior-work and
   graph-assisted current-source audit.
2. A baseline-compatible Avatar-active → Summary-pointer red control, proven
   failing on `fc35c1b` and passing on this branch.
3. Typed cross-producer foreground handoff, lane-specific cache lease
   revocation, cold Time exact Phase-A/latest-wins continuation, same-surface
   metrics cache exactness and symmetric reverse takeover.
4. Bounded first-Avatar and Header/Budget-progress actual-paint diagnostics,
   including the pure-model no-binding guard.
5. Focused and broad Ubuntu/proot validation. The 19 full-presentation
   failures were reproduced identically on the exact baseline; no golden was
   regenerated.

Deliberately not implemented:

- An Avatar render-isolation optimization: retained physical evidence proves a
  post-store cost but does not identify which repaint/layout/raster consumer
  is the culprit. The new instrumentation is the bounded evidence needed for
  the next profile run.
- Any Carousel physics, threshold, spacing, velocity or semantic-frequency
  change.

Remaining delivery work:

1. Commit the forensic/checklist evidence. The coherent implementation units
   are already committed as `f39091d2` (foreground Time Phase-A handoff) and
   `5b43a647` (Avatar target-paint diagnostics).
2. Push the application branch; use GitHub Actions for the required profile
   matrix and human diagnostic APK, then download the exact APK to
   `/storage/emulated/0/Download/fluvi` and hash it.
3. Regenerate the SCIP graph from the exact final application SHA on the
   separate tooling branch, run its deterministic verification, and commit/
   push it separately.
4. Keep physical acceptance as `PENDING — USER ONLY` regardless of CI result.
