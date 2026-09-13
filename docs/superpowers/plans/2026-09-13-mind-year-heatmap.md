# Mind Year Heatmap implementation plan

1. Freeze the approved journal baseline and generate a graph matching the clean
   feature worktree. Inspect current owners rather than inferring runtime flow
   from graph edges.
2. Add pure annual projection RED tests: exact local dates, twelve months,
   global normalization, degenerate/empty states, filter identity, and a
   source-row-touch counter proving amount previews do not revisit annual rows.
3. Add widget/production-parent RED tests for Year-only visibility, 3x4
   structure, held-pointer live recolor, final-value flushing, stale-generation
   rejection, fixed footer/scroll behavior, parent gesture arbitration and
   narrow labels.
4. Add one immutable active-identity annual projection to the existing Core
   Mind amount-preview path. It is built from the resident non-amount prepared
   membership seed, holds per-day sorted contributions and prefix sums, and
   creates a visible frame by reading at most 366 day buckets.
5. Publish the heatmap through a single scoped `ValueListenable`; replace the
   projection atomically when non-amount identity changes and reject stale
   coalesced generations.
6. Implement the Mind-only Year surface as a structural `Column`: an expanded,
   clipped monthly grid viewport and an independent compact range footer. Give
   the viewport a narrow host gesture opt-out rather than changing dashboard
   stacks or global pager geometry.
7. Make all RED tests green; run focused owner, query, avatar/time regression
   and analyzer checks. Run the representative large-fixture profile and record
   preview distribution, source-row/repository/index counts and FrameTiming.
8. Re-read this checklist, update every status from evidence, append only the
   coding-agent journal evidence, create atomic commits, push, deliver the
   online human APK, regenerate final-source SCIP, and report remaining
   user-only validation honestly.
