# Exact-SHA dashboard profile failure

Source: `174ad84156186aab9bd2bad49ecd9ed823ef0a27`, run https://github.com/elizerpist/exptv2/actions/runs/34348237362, profile job `102456663616`.

`test-flutter` passed: `flutter analyze --no-fatal-infos` reported no issues; `./scripts/test-fluvi-fast.sh` reported **369 tests passed** at 2026-09-09 11:59:26 UTC. `test-core` also passed. Raw Flutter log is `test-flutter.log`.

The A–K profile step failed in the first K flight at `_waitForAvatarExactPaint`, integration test line 1344. It did not fail at APK compilation, emulator startup, or the native seed. I completed; K produced only `dashboard_profile_dashboard_avatar_target_completion_evidence.json`. There is no complete K scenario report or post-renderer final report, and `completed_flights` is empty. Four-flight K proof is therefore **NOT COMPLETE**.

Downloaded artifact `10103098626` has the requested name `dashboard-profile-results-174ad84156186aab9bd2bad49ecd9ed823ef0a27` and exact workflow head SHA. Archive size: 633131 bytes. Local archive SHA-256 matches GitHub's digest:

`dae53756a215ce9375fa8a672619f62153870d180d8acfa63eb9d642b6b90744`

Raw completion JSON SHA-256:

`d3357422cb3d9424421a3979c8ee8d875ab32a44bb54ccc29bd9eab2e891284e`

## Untouched actual K snapshot

- Eight nonempty, disjoint category counts: `{1:5, 2:11, 3:7, 4:2, 5:4, 6:10, 7:18, 8:37}`; aggregate 94.
- Physical raw center 12.0, normalized final target **3**.
- Desired, semantic, latest actual painted, selected Budget, focus, Header, progress and LogBox handles are all **3**.
- Expected/focus/visible/canonical category digest: `806dad6f` everywhere.
- Visible/LogBox/canonical query digest: `5daa0d24` everywhere.
- Eight preview requests, eight terminals, all `acceptedExactNonEmptyPainted`.
- Pending candidate, exact-local unavailable, generic coordinator reject and Time interaction counts: all **0**.
- Final row count 7; Header and progress values both equal the expected numerator 2644575 and denominator 3305718.
- Actual last paint metadata: focus generation 9, presentation epoch 2, frame generation 10; Header/progress also paint epoch 2/frame 10.
- `nonempty_preview_painted_count=6`, `final_target_exact_painted=false`, `final_target_identity_equal=false`; other final paint/canonical flags are true.

The committed pure validator was executed on this untouched current-flight map using Ubuntu Dart. It rejected exactly:

`Bad state: Avatar final-target evidence final_target_exact_painted is invalid: false.`

Result is retained in `failure-validation-result.json`; no raw flag was rewritten.

## Source-supported diagnosis and limits

The collector's final predicate at integration test line 1470 requires `paint.hasReadablePhaseAPaint`. The DTO defines that as exact empty or `readablePhaseARowsPainted > 0`; real rich-scene paints have a separate `hasRichPhaseBPaint` property and are excluded. The same narrow predicate also drives `exact_phase_a_all_readable` around lines 897–899 and nonempty painted counts around line 1529.

Core's actual paint acknowledgement requires current query/revision/presentation/frame identity, complete drawable row count and a positive actual painted row count. Its terminal classification accepts actual nonempty rich paint. The observed eight successful paint terminals versus six collector-counted paints, matching final identities, and canonical rich epoch strongly indicate a **collector false negative for rich-only final paint**, rather than the original target-liveness failure. The raw JSON does not export the last Phase-A/rich paint counters, so this classification is a source-supported diagnosis; those unexported counters are not claimed as directly observed raw values. Root is reviewing before any fix.

Separately, the automated harness APK upload warns that no file exists at its full-SHA filename: the rename step uses seven SHA characters while the upload path expects forty. The requested profile evidence artifact did upload successfully. This warning is not the K failure and does not affect the separately delivered human APK.

No source/docs edit, rerun, cancellation, commit, or duplicate human APK download was performed. App HEAD remained `174ad841`. Physical validation remains USER ONLY.
