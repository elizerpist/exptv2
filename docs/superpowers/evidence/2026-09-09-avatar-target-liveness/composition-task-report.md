# Additional physical Avatar composition scenarios

Status: seven composition tests passed together, including the revised visible open-day surface. The eighth, controlled resource-replacement race passed against the repair and reproduced the exact earlier-1-painted/final-8-miss mismatch against the unchanged baseline. Root's final application/fast/analyzer gates cover the final baseline-compatible precondition and lint-only edits.

Scope: written-plan Task 3 gaps, user prompt §§10.1, 10.5 and 10.11; acceptance checklist AVL-02, AVL-08, AVL-13 and AVL-14. This task edits only `test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart` and this report/evidence. The original cold, persistent-20-cycle, and sparse scenarios are retained; one existing single-line conditional received the requested braces lint fix.

The existing real CoreDashboard, Core, Budget presentation, centered carousel, scene cache, exact binder, paint callbacks and repository fixture remain the sole owners. New test helpers issue actual timestamped pointers and inspect those owners. The eighth scenario additionally uses the existing public warmup/cache preparation APIs to arrange a controlled resource-identity loss. No second gesture engine, synthetic acceptance callback, manually installed painter, binder override, production layout change, or production source edit was introduced. The approximately 800-line test file remains one composition-test responsibility: its original three scenarios, five required additional scenarios and their local pointer/assertion helper. It contains no replacement runtime workflow or resource policy.

## Requirement evidence

| Requirement | Acceptance and verification | Status |
|---|---|---|
| AVL-02 / §10.1 | From startup, physically drag the persistent 58-pixel cyclic rail through final targets 3→2→1→0→8→7→6 with no Time input. Require exact nonempty actual paint and canonical scope after each final. | DONE — month and visible day |
| AVL-08 / §10.5 | The natural cold same-pointer case paints 1 then crosses directly to final 8 and requires a real nonempty exact binder miss followed by exact paint/canonical 8. A separate controlled real-resource replacement arranges the same earlier-1/final-8 race in both source versions. | DONE — current green and exact baseline mismatch red |
| AVL-13 / §10.10 | At every final: physical center, selected handle, focus, visible query/categories, canonical paging/navigation, actual Header/progress handles and values, actual nonempty LogBox paint, exact cache readiness, pending candidate zero, and request/terminal accounting agree. | DONE — combined seven-test run |
| AVL-14 / §10.11 | Complete the entire Avatar sequence first. Perform one real same-month Summary Time gesture, then repeat the entire sequence on the same owners; final 6, scope/query, readiness and pending count match the first result. | DONE — owner and outcome assertions passed |

The Time control intentionally compares complete Avatar outcomes before and after the Time interaction. Time is allowed to clear transient category focus by design; requiring the intermediate Time state to retain category 6 would test an unsupported behavior. The control uses the actual Summary Time recognizer, asserts its motion lane and nonzero rendered translation, returns within the same month, and then repeats the full Avatar sequence. It also checks the same CoreDashboard State, Avatar controller, ScrollPosition, physics creation count, and prepared scene cache.

## Genuine baseline red

The current test file was executed by absolute path while the process cwd was the unchanged baseline worktree `fluvi-e8-milestone-time-window-avatar-first-load-codex-20260909` at `b2865023` (runtime source equivalent to `aa61242`). No test or production file was copied into that worktree.

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-e8-milestone-time-window-avatar-first-load-codex-20260909 && /home/flutteruser/flutter/bin/flutter test --no-pub /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-avatar-target-liveness-codex-20260909/test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart --name "scenario=day|scenario=month$" --reporter expanded'
```

Result: **0 passed, 2 failed**, saved in `composition-baseline-sequence-day.log`. Both physical rails settled at target 3 while the visible scope remained the nonempty aggregate. Focused targets 1, 2 and 3 each hit the actual binder with `resourcesReady=false phaseAReady=false`, then `reason=exactLocalHotsetUnavailable`; the final trace has `latestSemanticTargetHandle=-`. This is a behavioral resource-starvation red, not a failure caused only by a new diagnostic field absent from the baseline.

## Exact earlier-painted/final-cold baseline race

The eighth scenario keeps the full nine-handle catalog and eight-category Budget bank. It uses the existing public hotset request to naturally prepare a small aggregate/1/2 horizon through the real attached cache. Target 1 is selected by a real pointer, actually paints, settles and becomes canonical. The same cache then prepares a one-payload window using that exact currently visible target-1 payload through `prepareLiveInteractionResourceWindow`; its ordinary atomic Avatar-lane replacement changes resource identity while preserving the readable current visual. No attachment, binder or return value is replaced.

While idle, requesting all eight hotset categories creates pending plans. A second real pointer immediately claims the existing Avatar recognizer and moves directly to final 8 before a display frame can warm the remaining horizon. Both source versions must reach the real nonempty target-8 root/binder miss. The repaired version must then paint and canonicalize 8 without another gesture, with all final identity and terminal-accounting assertions intact.

This is controlled resource-identity/coverage-loss setup for the required final-target race. It does not claim to prove that a manual lane replacement was the cause of the supplied physical failure. The separate startup baseline red proves naturally missing hotset resources without this intervention.

Exact baseline command (same absolute current test path and baseline cwd as above):

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-e8-milestone-time-window-avatar-first-load-codex-20260909 && /home/flutteruser/flutter/bin/flutter test --no-pub /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-avatar-target-liveness-codex-20260909/test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart --name "AVL retained painted" --reporter expanded'
```

Result: **0 passed, 1 failed** in 14 seconds, `composition-resource-replacement-baseline-red.log`. The trace first records actual nonempty `LOGBOX_TARGET_PAINTED targetHandle=1` and canonical publication 1. The second real pointer starts with selected handle 1, requests target 8 and reaches `LIVE_ROOT_MISS resourcesReady=false phaseAReady=false`, then `exactLocalHotsetUnavailable`. It physically settles at 8. The bounded failure snapshot explicitly reports **physicalHandle=8, selectedHandle=1, canonical category=1, cached=2, pending=6**; the latest paint notifier is null after the new request, while the earlier actual target-1 paint remains in the trace. This is the required baseline mismatch, independent of newer diagnostic fields absent in aa61242.

The repaired eighth scenario passed in 7 seconds (`composition-resource-replacement-race-green.log`). Its original stronger current-only first-1 helper was subsequently replaced with equivalent actual-paint/canonical/no-motion preconditions using fields present in both source versions; final-8 validation remains unchanged. The final analyzer-requested null-aware set-element lint was also fixed. Root's final fast suite covers that final source.

## Open-day viewport diagnosis

The first valid current-source focused run (`composition-sequence-run.log`) passed the closed-month exact sequence and earlier-1/final-8 case, but the open-day sequence failed at its first final target 3. The next run (`composition-day-time-diagnostic.log`) passed the closed-month paired Time control and reproduced that day failure with geometry diagnostics.

At the standard 412×892 test surface, the expanded day rail leaves the outer LogBox only 119 pixels high (`Rect.fromLTRB(17, 773, 395, 892)`). After the focused category chip appears, the actual inner vertical scroll viewport has **viewportDimension=0**. The exact target-3 cache entry is readable, `payloadRowCount=1`, `cacheReadableRows=1`, and committed ready rows are 1, but the painter cannot paint inside a zero-height viewport; actual `drawableRowCount=0 paintedRowCount=0` remains correctly rejected. The baseline remains aggregate and has a 31-pixel inner viewport because it never publishes the focused chip.

The day test therefore uses the existing `pumpDashboardSurface(surfaceSize:)` API with 412×1200. It retains the full real composition and unchanged production geometry, asserts actual vertical viewport dimension is positive, and asserts pending hotset plans still exist before the first Avatar pointer. This preserves cold-start liveness testing without claiming that zero drawable pixels prove a binder failure. The original failing logs are retained; the day scenario remains active and unskipped.

## Commands and limits

All Flutter/Dart verification uses Ubuntu proot. No Termux-host Flutter binary, local APK build, commit, push, or physical acceptance claim was made by this task.

- Initial compile-only error (`composition-sequence-first-run.log`): removed an unsupported `timeStamp` named argument from `WidgetTester.startGesture`; move/up samples retain their real timestamps. This is not counted as a behavioral red.
- Current focused run: `flutter test --no-pub test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart --name "AVL physical startup|AVL earlier target" --reporter expanded` — **2 passed, 1 failed**, with the real day geometry issue above (`composition-sequence-run.log`).
- Paired Time and day diagnostics: `flutter test --no-pub test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart --name "scenario=day|scenario=monthTimeControl" --reporter expanded` — **1 passed, 1 failed**, paired Time control passed (`composition-day-time-diagnostic.log`).
- Combined composition: `flutter test --no-pub test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart --reporter expanded` — **7 passed** in 2m03s, recorded in `composition-final-green.log`. Includes original cold, 40-flights/20-cycle and sparse scenarios plus all four new scenarios at that point.
- Controlled resource replacement: `flutter test --no-pub test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart --name "AVL retained painted" --reporter expanded` — **1 passed** against current source; **1 intended behavioral failure** against the baseline using the command above.
- Ubuntu Dart `format test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart` — completed after the final baseline-compatible precondition and requested lint fix. Root owns final full analyzer, full eight-scenario fast suite and scoped diff check.

Additional race setup attempts are not product reds. The one-category visual catalog experiment (`composition-catalog-race-first-run.log`) was inconsistent with the unchanged dense eight-category Budget bank and was replaced with the full original catalog. Priming only category 1 after mount did not cancel the already queued all-category plans; the first partial-hotset attempt stopped at an incorrect pending-plan expectation. A replacement two-category semantic warm horizon was correctly installed, but its mandatory nonempty aggregate prepared all eight source rows, so target 8's exact binder legitimately succeeded (`composition-partial-hotset-race-attempt3.log`). The test retains its strict binder-miss precondition; those setup results do not establish the required baseline mismatch.

AA61242 AVATAR CORRECTNESS — PHYSICALLY REJECTED BASELINE

AA61242 / E8 AVATAR MOTION — PRESERVED BY THIS TEST TASK

NEW AVATAR CANDIDATE — PHYSICAL VALIDATION PENDING, USER ONLY
