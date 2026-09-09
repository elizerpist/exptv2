# a047e216 actual profile verification

Source: a047e216803d3ac01d97b4d5ffd03842a1579db3, first attempt of run 34351134148, profile job 102466312702.

## Scoped K result: PASSED

The unchanged raw `dashboard_profile_K_avatar_first_target.json` (`avatar_first_target` key) passes the exact committed `DashboardProfileReport.validateRequiredScenarioMetrics` and `validateAvatarFirstTargetEvidence`. The verifier additionally requires exactly four actual flights. The separate `dashboard_profile_dashboard_avatar_final_target_evidence.json` passes `validateAvatarFinalTargetEvidence` after renderer capture. The imported report owner was byte-compared with `git show a047e216:integration_test/support/dashboard_profile_report.dart` before this report.

- Four final targets: 3, 0, 3, 0. All physical/desired/semantic/painted/selected/focus/Header/progress/LogBox identities agree per flight; category/query and canonical checks pass.
- Actual final Phase A rows: 0, 0, 0, 0. Actual Rich B rows: 2, 3, 2, 3. Each exact-empty flag is false. Every paint Core revision and visible Core revision is 2.
- Each flight has eight requests and eight `acceptedExactNonEmptyPainted` terminals; pending candidates, generic coordinator rejections, and Time interactions are zero.
- Independent post-renderer final snapshot: target 0, Phase A 0, Rich B 3, empty false, revision 2 = 2, requests 8 = terminals 8, pending 0, identities/canonical state coherent.
- All eight fixture categories are nonempty and disjoint: 1:5, 2:11, 3:7, 4:2, 5:4, 6:10, 7:18, 8:37; aggregate has 94 rows. Actual painted target handles include every 0 through 8.
- Overall exact renderer paint count is 32; literal Phase A subset is 27. `exact_renderer_all_nonempty_painted` is true and legacy `exact_phase_a_all_readable` is false. This actual run directly demonstrates rich-only final paints and the need for the corrected renderer predicate; it does not reconstruct counters absent from the older 174ad841 artifact.

Validation command (exit 0):

`proot-distro login ubuntu -- bash -lc '/home/flutteruser/flutter/bin/cache/dart-sdk/bin/dart /data/data/com.termux/files/home/.codex/tmp/avatar-profile-a047e216/validate_actual_k.dart /data/data/com.termux/files/home/.codex/tmp/avatar-profile-a047e216/artifact > /data/data/com.termux/files/home/.codex/tmp/avatar-profile-a047e216/validation-result.json'`

## Whole A–K suite: INCOMPLETE despite CI job success

The job metadata reports success, but the raw app log at 13:04:53.891 UTC reports `TimeoutException after 0:25:00.000000: Test timed out after 25 minutes.` At 13:04:55.247 it reports `25:01 +1 -1: Some tests failed.` The driver then prints `All tests passed.` at 13:04:56.449 and exits successfully. Therefore GitHub's green job is not proof of a complete passing A–K suite.

K was ready at 12:42:55.250 UTC, long before the timeout. B/C/D/E each consumed about 4 minutes 18 seconds from STABLE to READY. H was ready at 13:02:17.354. J started at 13:02:17.357 but did not emit PREPARED, STABLE, or READY before the global test timeout. The artifact contains I/K/A–H, but lacks J and whole-suite comparison/final summary outputs. This establishes the timeout boundary and incomplete result, not the underlying cause of slow later scenarios. The stack trace is the test_api timeout handler, not a failing application frame.

Host exit snapshot reports 11,988 MiB (about 11.7 GiB) available memory, zero swap used, and memory-pressure averages 0.00; this snapshot does not establish an OOM cause. Full host/kernel/Android diagnostics remain intact. No rerun, cancellation, source change, or timeout change was performed.

## Provenance and files

Artifact 10105257349: `dashboard-profile-results-a047e216803d3ac01d97b4d5ffd03842a1579db3`, 1,233,318 bytes. Local archive SHA-256 `7c44a62dedbb82fc416b99dc32a1fe5958037db99fed35c81f6f65fc8e8d561f` exactly matches the API digest. All 21 extracted files are unchanged; `artifact-file-sha256.json` records their hashes.

- `dashboard-profile-results.zip`: original archive.
- `artifact/`: complete original extraction, including host/kernel/Android diagnostics.
- `artifact-status.json`, `profile-job-status.json`: API provenance.
- `profile-current.log`: full raw profile job log.
- `profile-scenario-timeline.log`: derived concise marker/timeout timeline.
- `validate_actual_k.dart`, `validation-result.json`: strict scoped K verifier and result.
- `test-flutter.log`: actual prerequisite analyzer success (20.0 seconds) and 383 tests passed.

The parent owns disposition of the wider timeout/driver false-green boundary and final delivery claims. K evidence is valid; whole-suite completion is not established.
