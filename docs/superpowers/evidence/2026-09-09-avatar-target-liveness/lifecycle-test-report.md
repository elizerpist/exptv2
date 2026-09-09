# Avatar candidate lifecycle tests

Scope: the additional application/cache lifecycle tests in `test/features/dashboard/application/dashboard_avatar_candidate_lifecycle_test.dart`. These supplement the persistent production-composition proof; they do not claim physical rail or paint verification.

## Architecture gate

The production `DashboardCoreController` remains the only candidate, focus generation, and canonical-publication owner. The actual `DashboardLogBoxPreparedSceneCache` owns and binds resources. Reuse the existing external data fixture in `test/support/avatar_target_liveness_fixture.dart` and existing coordinator attachment contracts. The only new helper is test-local preparation scheduling, holding real cache operations through completion gates; no production behavior, binder result, or visible frame is replaced. The feature architecture and boundary tests remain owned by the parent implementation task.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| AVL-L01 | user-prompt.txt §§9.1,10.4 | lifecycle test / real Core + cache | Empty broad required hotset still schedules one exact nonempty current target and binds it without another index read | Focused application/cache test | DONE |
| AVL-L02 | user-prompt.txt §§9.2,10.9 | lifecycle test / candidate order | Target 8 becomes readable before older held preparation is released, retains original interaction order, and stale completion cannot replace it | Focused application/cache test with distinct completion gates | DONE |
| AVL-L03 | user-prompt.txt §§9.2,10.9 | lifecycle test / pointer cancellation | New pointer resolves pending candidate once with cancelledByNewPointer and old completion changes no visible authority | Focused application/cache test | DONE |
| AVL-L04 | user-prompt.txt §9.2 | lifecycle test / disposal | Disposal resolves pending candidate once with disposed and releases pending ownership | Focused application/cache test | DONE |
| AVL-L05 | user-prompt.txt §§9.2,10.4 | lifecycle test / failed preparation | Failure and cancellation of exact preparation resolve explicitly, once, with no unresolved candidate | Parameterized application/cache tests | DONE |
| AVL-L06 | user-prompt.txt §10.8 | lifecycle test / canonical install | Older deferred canonical publication cannot overwrite a newer accepted live/canonical target | Focused application/cache test | DONE |
| AVL-L07 | user-prompt.txt §§9.2,10.9 | lifecycle test / current-target reuse | Returning to current target 1 retires held target 8 before its completion, then preserves final live/canonical target 1 | Focused application/cache regression; observed initial red, integration verification recorded separately | DONE |
| AVL-L08 | user-prompt.txt §§9.2,10.4 | lifecycle test / foreground rejection | Category and aggregate Avatar requests rejected by existing Time foreground ownership each return false with one staleRejected terminal and create no candidate or Avatar preparation | Focused application/cache test added; execution pending | DONE |
| AVL-L09 | user-prompt.txt §9.2 | lifecycle test / disposed request | Category and aggregate requests made after Core disposal each return false with one disposed terminal and create no candidate or Avatar preparation | Focused application/cache test added; execution pending | DONE |

## Verification record

The initial run produced six passes and one intended behavior failure. Target 8 could not complete while target 1 remained held at the real cache checkpoint:

```text
Expected: true
  Actual: <false>
The latest exact target must receive foreground priority without waiting for the superseded target preparation to finish.
```

Root preserved this output in `latest-target-priority-red.log`. Source tracing found that `liveInteractionResource` tasks cannot supersede equal-priority tasks inside the shared cache. Root changed the existing Avatar candidate supersession boundary to call the existing lane cancellation capability before starting replacement work. The shared cache scheduler was not changed by this subtask.

After that production change, the unchanged seven-test suite passed in eight seconds:

```text
00:08 +7: All tests passed!
```

Command, executed inside Ubuntu proot:

```sh
/home/flutteruser/flutter/bin/flutter test --no-pub test/features/dashboard/application/dashboard_avatar_candidate_lifecycle_test.dart --reporter expanded
```

The six initially green cases prove behavior already present in the current implementation, which included Root's initial exact-target preparation fix. They are not represented as independently reproduced baseline failures. The strong target-8 foreground-priority case has an observed red-to-green transition.

The canonical test holds the older accepted target's actual deferred install behind the motion lane, accepts target 8 into the same owner, then releases the idle boundary and asserts that only target 8 publishes canonically. `installPreparedIndex(isEphemeralFocusPublication: true)` publishes synchronously before its first asynchronous rich-scene preparation, so this test does not invent an I/O-delayed canonical publication boundary.

Preparation gates sit inside the real cache's `yieldToBackground` checkpoint after resource/token acquisition. Thus old completion exercises actual cancellation tokens, resource retention, and binder ownership. Callback checks cover false terminal outcomes only; accepted paint terminal accounting belongs to the production-composition/coordinator tests.

Focused analysis initially found one braces style lint in the helper. After adding those braces, final focused analysis exited zero:

```text
Analyzing dashboard_avatar_candidate_lifecycle_test.dart...
No issues found! (ran in 9.8s)
```

Command: `/home/flutteruser/flutter/bin/flutter analyze --no-pub test/features/dashboard/application/dashboard_avatar_candidate_lifecycle_test.dart`, executed inside Ubuntu proot. At that verification checkpoint, the only test-source edit after the seven-test green run was the braces-only lint correction. Full feature integration and physical paint evidence remain part of the parent task's verification.

## Additional terminal guards — execution pending

The expanded suite includes the return-to-current regression and two new guard tests. The Time-foreground test calls the existing `beginSegmentedSummaryMotion`, then requests category 8 and aggregate 0 through the actual public Avatar APIs. The disposal test disposes Core before those same requests. Source inspection confirms that the disposed guard returns before reading disposed child state, so the latter does not invent an unsupported scene/cache interaction. Both cases require the exact typed false terminal once for each request, zero pending candidates, and zero Avatar resource preparations.

These two new tests have not been run by this subtask. Existing early returns omit the callback, so failure is expected from source inspection; it is not yet an observed red. No production source was changed for these test additions. The prior seven-test green is not a verification claim for the expanded file.

## Final integrated lifecycle verification

The root observed both admission tests fail with empty terminal lists on the pre-guard implementation (`terminal-admission-guards-red.log`). The category and aggregate entry points now reuse one existing-owner admission classifier: Time foreground is staleRejected and disposal is disposed. The ten-test suite, including current1→held8→current1 canonical replacement, passes on the integrated production changes (`lifecycle-final-green.log`). The return-to-current test additionally exposed no-content-change publication returning false for an accepted new order; category and aggregate now share the existing Avatar admission rule.

AVL-L07, AVL-L08 and AVL-L09 are DONE by the final ten-test run. Actual gesture/paint evidence remains in the separate production-composition report.
