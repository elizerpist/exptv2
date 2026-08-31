# Execution plan — post-df1d physical regression repair

The user explicitly requested implementation, not a plan-only handoff. This plan is therefore executed inline in this isolated worktree. The workstreams share the visible-frame identity and Dashboard coordinator, so splitting code ownership would create merge conflicts and weaken causal review.

1. **Record baseline and causal evidence.** Complete fresh log review, metadata/diff inspection, current source trace and acceptance checklist. Record what is proven versus still diagnostic-only.
2. **Add red production-path tests.** Start with deterministic timing tests for Mind pre-paint preview, stable amount-domain/bridge behavior, Segmented acceptance/settlement/reversal, Avatar ballistic publication and stale generation rejection. Observe each affected test fail on `df1d4a3` for its named causal reason.
3. **Repair Mind at its shared pre-frame boundary.** Reuse the display-frame coalescer, preserve the interaction-domain snapshot and defer preview removal until exact canonical reconciliation. Keep repository/index/scene work out of pointer moves.
4. **Repair Segmented lifecycle and ownership.** Wire raw direct pointer intent into Core preemption, add a typed synchronous crossing acceptance seam, track accepted/painted targets and settle only to the latter. Add bounded rejection/lifecycle diagnostics.
5. **Repair Avatar phase-aware publication.** Trace the direct and ballistic callback path with the same live focus contract, retain exact ready roots, and expose phase-specific acceptance/paint counters. Fix only the proven failing edge.
6. **Validate, review and hand off.** Format, inspect diffs, run targeted tests then full analysis/regressions in Ubuntu proot. Make evidence-backed focused commits, push, monitor/download the required online human diagnostic APK, and report `TEST-CLEAN / DEVICE-PENDING` only if all automated acceptance rows are `DONE`.
