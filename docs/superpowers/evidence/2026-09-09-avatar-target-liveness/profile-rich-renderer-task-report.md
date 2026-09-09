# Profile exact-renderer correction — AVL-16a

Authority: the approved Task 4 follow-up in `docs/superpowers/plans/2026-09-09-avatar-target-liveness.md`, acceptance item AVL-16a, and parent delegation after actual CI run 34348237362 failed scenario K. This correction changes profile collection and validation only. It does not change production rendering, Core, caches, motion, or rail behavior.

## Finding and evidence boundary

The unchanged 174ad841 actual CI artifact rejects the first final target even though its physical/desired/painted/selected/surface/canonical identities agree, eight requests have eight accepted nonempty terminals, and the pending count is zero. The collector required `hasReadablePhaseAPaint` at three sites and thereby rejected the separate valid rich Phase B paint path. The old final-flight JSON does not contain the raw Phase A/B counters or the paint/visible revision pair. A rich-only paint causing that particular CI failure remains a source-supported diagnosis; this report does not invent those absent fields or relabel the old artifact as valid.

The controlled regression below proves the predicate defect independently: after extracting the existing Phase-A-only predicate without changing its behavior, valid nonempty counters with Phase A = 0 and Rich B = 3 returned false. The test ran and failed an assertion; it was not a compilation failure. Actual next-SHA CI evidence is still required to confirm the runtime renderer counters and all four completed K flights.

## Change and ownership

`DashboardProfileReport.hasExactNonemptyAvatarPaint` is the shared pure predicate for all three collector uses. It requires `exactEmpty == false`, nonnegative counters, and at least one positive actual Phase A or Rich B row count. Target/query/revision identity remains a separate requirement.

Overall collection and validation use `exact_renderer_paint_count`, `exact_renderer_target_handles`, and `exact_renderer_all_nonempty_painted`. Legacy `exact_phase_a_*` metrics report only the actual Phase A subset; a rich-only flight can truthfully report Phase A count zero. The final-flight exporter adds the raw empty flag, both actual row counters, paint Core revision, and visible Core revision. The final validator independently checks these raw values in addition to the existing derived acceptance booleans.

Existing empty-only baseline, earlier-painted/final-pending, stale canonical, mismatched surface/query/target, unresolved candidate, and terminal-accounting negative gates remain in place. Added tests accept positive Phase A and rich-only paint while rejecting empty, zero-row, negative-counter, missing-counter, and stale-revision claims. The rich-only whole-report fixture uses one painted row for its one-row payload. The existing profile boundary test verifies all three collector calls and raw field exports.

Owned source files:

- `integration_test/dashboard_interaction_profile_test.dart`
- `integration_test/support/dashboard_profile_report.dart`
- `test/performance/dashboard_profile_report_test.dart`
- `test/boundary/dashboard_avatar_profile_boundary_test.dart`

## Red and green commands

All commands ran inside Ubuntu proot in `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-avatar-target-liveness-codex-20260909`. Flutter was `/home/flutteruser/flutter/bin/flutter`; Dart was `/home/flutteruser/flutter/bin/cache/dart-sdk/bin/dart`. No local APK build ran.

1. Behavior-preserving extraction, then targeted behavioral red:

   `flutter test --no-pub test/performance/dashboard_profile_report_test.dart --plain-name "Avatar exact renderer accepts a real rich-only nonempty paint" --reporter expanded`

   Result: **0 passed, 1 failed**, expected true, actual false. Full output: `profile-rich-renderer-red.log`.

2. Expanded report/raw-counter/boundary contract before the behavior fix:

   `flutter test --no-pub test/performance/dashboard_profile_report_test.dart test/boundary/dashboard_avatar_profile_boundary_test.dart --reporter failures-only`

   Result: **49 passed, 13 failed**. The failures include rejecting valid rich-only evidence, accepting invalid raw claims, and the missing raw exports. Full output: `profile-rich-contract-red.log`.

3. The same focused command after the predicate, collector, and validator correction:

   Result: **62 passed**, including the final fixture consistency and revision type checks. Full output: `profile-rich-renderer-green.log`.

4. `dart format --output=none --set-exit-if-changed` with the four owned source paths:

   Result: **4 files checked, 0 changed**, exit 0. `git diff --check` also passed.

5. `flutter analyze --no-pub` with the four owned source paths:

   Result: **No issues found** across all four items (22.6 seconds), exit 0. Full output: `profile-rich-renderer-analyze.log`.

## Remaining verification

Local behavioral correction and focused contract verification are complete. AVL-16a remains **PARTIAL** until a fresh exact-SHA profile produces the raw phase/revision fields and passes the strict K report validator with four completed flights, nonempty disjoint targets, zero pending candidates, and complete terminal accounting. The parent owns that commit/push/CI cycle, the exact human APK, and regenerated SCIP/graph evidence. No artifact values were edited and no old failed profile was converted into passing evidence.
