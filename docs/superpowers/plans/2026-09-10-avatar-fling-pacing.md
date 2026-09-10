# Avatar-only correctness-preserving fling pacing — execution plan

**Scope:** Repair the physically observed uneven Avatar fling without undoing
the restored exact Budget/Header/progress/LogBox publication at
`33ee878b070345c336bb73df2b087d9a63c87c5a`.

**Architecture boundary:** The existing authority remains
`BudgetTargetAvatarRail -> DashboardBudgetLogboxDrilldownCoordinator ->
DashboardCoreController -> DashboardBudgetPresentationController ->
DashboardVisibleFrameStore`. No new selection, cache, controller, physics,
scroll position, layout or Time/Mind path may be introduced or changed.

## Evidence already established

- The frozen Drive session has one session ID and two overlapping retained
  exports. Deduplication is by diagnostic sequence, not by timestamp or
  concatenation; its union is `1875..2877`, with `997` duplicated retained
  records.
- The tested human profile identifies source SHA `33ee878b070345c336bb73df2b087d9a63c87c5a`.
- Every retained in-flight motion summary reports zero repository requests,
  index builds, scene preparations and canonical persistence commits at its
  ticks. The post-settle scene maintenance therefore is excluded as a root
  cause unless new timing evidence proves otherwise.
- The profile shows all sampled targets accepted and exactly painted, while
  frame build P95 reaches `24,638us`, total-span P95 `31,689us`, and
  inter-target gaps are variable. It does **not** identify which synchronous
  subscriber consumes the budget.
- The debug floating button has no diagnostic logger listener; only an open
  `DebugConsoleDialog` subscribes. Logger UI notification cannot be asserted
  causal without a trace showing that dialog was open.

## Sequential implementation checkpoints

1. **RED: production-composition correlation test**
   - Extend the existing persistent real `CoreDashboard` Avatar test rather
     than creating a test-only shell.
   - Require each accepted non-empty Avatar target to carry one bounded
     correlation record that splits: semantic crossing → Core phase-A
     publication → synchronous Budget notification fan-out → paint request.
   - Verify the record preserves the physical target identity and contains no
     repository/index/scene/canonical work claim. Watch it fail on the tested
     head because this record does not yet exist.

2. **GREEN: low-overhead, diagnostic-gated timing points**
   - Reuse the existing `FLUVI_PHYSICAL_RAIL_DIAGNOSTICS` / debug gated
     diagnostic logger ring. Do not add an unbounded trace sink.
   - In the existing Core-to-Budget callback boundary, timestamp only the
     existing synchronous call and the existing Budget notifier fan-out.
   - Add no state owner and schedule no work from instrumentation. Include
     bounded counters/identity so traces distinguish stale and accepted
     targets.

   **Checkpoint result:** done test-first. The real `CoreDashboard` test first
   failed because there was no correlation/duration record. It now proves the
   existing Core callback record plus two renderer boundaries: the exact
   Header amount subtree paint and selected progress `CustomPainter.paint`.
   The two render measurements are created only for debug or
   `FLUVI_PHYSICAL_RAIL_DIAGNOSTICS`; a normal release retains no new timing
   work on this path.

3. **Reproduce and classify**
   - Run cold, warm and mixed-resource nine-target sequences, then 20 forward
     and 20 reverse flights using the production parent and real target
     sequence `3 -> 2 -> 1 -> 0 -> 8 -> 7 -> 6`.
   - Classify each large gap as physical cadence, Core preparation, synchronous
     Budget fan-out, render/layout/raster, or asynchronous readiness. Treat
     correlation as non-causal until a deterministic comparison changes only
   the implicated boundary.

   **Checkpoint result:** the persistent production-parent 20-forward/20-
   reverse composition run now completes locally. Classification remains open
   until the fresh Android profile supplies per-target timing values.

4. **RED: causal pacing gate**
   - Add a focused threshold/ordering regression that fails because the proven
     first latency boundary presently occurs in the motion-critical path.
   - It must keep final target exactness, stale-completion rejection, one
     pending candidate, controller/ScrollPosition identity, and the protected
     e8b73e3 motion contract as assertions.

5. **GREEN: smallest responsible-owner repair**
   - Change only the proven owner. Any non-critical work deferred from a
     crossing must publish the exact final semantic target at the existing
     motion-idle/settle owner; Header, progress and LogBox correctness may not
     be deferred or substituted.
   - Re-run the composition tests, targeted ownership tests, and Flutter
     analysis inside Ubuntu proot.

6. **Delivery and physical hand-off**
   - Update the checklist and forensic report with all distributions and
     inherited/environment failures separately.
   - Commit on a new branch, push the exact SHA, follow the GitHub human APK
     job, download the exact normal `lib/main.dart` APK to
     `/storage/emulated/0/Download/fluvi`, hash it, and generate matching SCIP
     evidence.
   - Final status remains `PHYSICAL VALIDATION PENDING — USER ONLY` until the
     user confirms the device sequence.

## Verification commands

All Flutter validation runs through Ubuntu proot:

```sh
proot-distro login ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-avatar-target-liveness-codex-20260909 && \
   /home/flutteruser/flutter/bin/flutter test --no-pub test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart'
```

The pre-existing 20-cycle baseline was started twice during recovery but the
terminal host detached before a final exit status was captured. It is not
recorded as passing evidence and will be rerun through a retained terminal
session after the red/green checkpoints.
