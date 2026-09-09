# Complete profile handoff — AVL-16b

Authority: the approved Task 4 follow-up, architecture ownership update, and acceptance item AVL-16b, all inventoried before editing. This change is confined to the existing profile collector, pure report owner, host driver, bounded shell runner, and focused tests. No production `lib/` or `android/` change is included.

## Observed failure and SDK boundary

The unchanged a047e216 first-attempt artifact contains valid K evidence and reports I/K/A–H, but lacks J and whole-suite completion. The app log reports the 25-minute `test_api` timeout at 13:04:53 UTC, followed by `Some tests failed`; the SDK host driver then prints `All tests passed` and exits successfully. Actual K verification remains valid independently of this incomplete wider suite.

Local Flutter SDK source inspection establishes the handoff boundary:

- `/home/flutteruser/flutter/packages/integration_test/lib/integration_test.dart:50–52`: teardown completes `allTestsPassed` from `failureMethodsDetails.isEmpty`.
- The same file, lines 88–91: `reportTestException` records Flutter `Failure` entries. The observed `test_api` timeout was not represented in the SDK's successful response.
- `/home/flutteruser/flutter/packages/integration_test/lib/integration_test_driver.dart:76–81`: the SDK prints success, awaits `responseDataCallback`, then calls `exit(0)`. A thrown callback error prevents that success exit.
- The same driver, lines 83–87: with `writeResponseOnFailure: true`, it also awaits the callback on reported failure before `exit(1)`.

The fix therefore validates completion inside the existing awaited callback, after writing diagnostics. It does not patch the SDK or infer suite completion from its success flag.

## Existing owners and final behavior

`DashboardProfileReport.validateCompleteSuite` is the single pure owner of the full response contract. It requires all eleven named A–K scenario reports and a versioned completion map with `all_assertions_passed == true` and the exact scenario-key set. Null, partial, malformed, duplicate-key, unknown-schema, missing-report, and invalid-completion responses throw. It reuses the existing required-metric, Avatar K, post-renderer final-target, and motion-isolation validators; no parallel validation engine or relaxed threshold was introduced.

The integration collector has one completion-marker write, after every existing scenario and suite assertion, including optional physical-frame validation. The host driver first writes `dashboard_profile_complete_response.json`, preserving even null or malformed payloads; it then writes the existing individual map reports and finally invokes the shared validator unconditionally. Thus a false SDK success cannot admit a missing marker or partial report set, and diagnostics are available before rejection.

The focused boundary tests verify persistence before the guard, the shared owner import, completion placement after the existing assertions, and the parsed timeout ordering across collector/SDK/shell/workflow. They check positive finite increasing budgets and that shell kill grace fits inside the workflow budget, rather than copying the selected timeout literals.

## Finite suite budget

The actual a047 log has K ready at 12:42:55 after a 12:40:36 start. B/C/D/E each take about 4m18 from STABLE to READY. J starts approximately 22m23 into the test and must still run nine warmup flings and the measured tenth fling. Its `_prepareScenario` warmup loop is unchanged. This observed work does not fit the previous 25-minute whole-suite budget reliably.

The approved finite limits are now: test 35 minutes, SDK response 38 minutes, shell 40 minutes with 30-second kill grace, existing workflow 60 minutes. These are whole-suite execution/reporting margins. Every per-flight, identity, memory, motion-isolation, frame/performance threshold, fixture count, and fling count remains unchanged. No retry or reduced coverage was added.

## Behavioral red and green

All Flutter/Dart commands ran inside Ubuntu proot in the existing worktree. No local APK build, commit, push, cancellation, or CI rerun was performed.

1. Tests were added before the validation implementation. A no-validation admission seam preserved the old SDK-success admission behavior for the initial assertion-based red. The focused command was:

   `flutter test --no-pub test/performance/dashboard_profile_report_test.dart test/boundary/dashboard_avatar_profile_boundary_test.dart --reporter failures-only`

   Result: **63 passed, 33 failed**, with behavioral assertions failing rather than compilation errors. Evidence: `profile-suite-completion-red.log`.

2. A separate pure Dart check reconstructed the response only by removing the `dashboard_profile_` filename prefix from the unchanged original artifact's JSON filenames. Against the initial admission seam it failed with `REGRESSION: incomplete actual a047 response was admitted.` Evidence: `profile-suite-actual-a047-red.log`. It did not add J, fabricate a completion marker, or edit any artifact value.

3. The same actual-artifact check after implementation rejects the response with `Dashboard profile J_tenth_fling must be a report map.` Evidence: `profile-suite-actual-a047-rejection.json`. The raw a047 K and separate post-renderer snapshot still pass their original strict validators. All 21 artifact files were rehashed and match the retained manifest.

4. The focused command after implementation passes **96 tests**, including all original rich-renderer/empty/stale/pending/terminal negative cases. The final run also includes the reviewed timeout-order boundary refinement. Evidence: `profile-suite-completion-green.log`.

5. Final `dart format --output=none --set-exit-if-changed` checks all five changed Dart files with **0 changes**, exit 0. Final `flutter analyze --no-pub` on those same five paths reports **No issues found** (9.6 seconds), exit 0; output: `profile-suite-completion-analyze.log`. `bash -n scripts/run-dashboard-profile.sh` and `git diff --check` pass; `git diff --exit-code -- lib android` exits 0 with no production delta.

The actual artifact verifier is retained at `~/.codex/tmp/avatar-profile-a047e216/validate_actual_suite.dart`; its inputs remain in the untouched `artifact/build/` directory. The existing K revalidation output is `validation-after-suite-guard.json` in that same directory's parent.

## Remaining evidence

AVL-16b remains **PARTIAL** until a fresh exact-SHA CI attempt produces the complete eleven-scenario response, completion marker, all existing suite assertions, and strict driver success. The parent owns the final commit/push, CI evidence, human APK, and regenerated SCIP/graph delivery. The a047 whole-suite timeout is retained as a failure of completion even though its K evidence is valid.
