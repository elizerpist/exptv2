# 6adeb42c profile prerequisite failure

Run34356839852, source6adeb42c90f9bef91532c4fe74f37404634ad250, first attempt.

`test-flutter` job102483561182 failed: **416 passed,1failed**. `flutter analyze --no-fatal-infos` passed with no issues(29.9s). The curated suite's single failure is `test/boundary/dashboard_interaction_performance_boundary_test.dart`, `keeps dashboard interaction ownership fail closed`, at lines531–532. It requires the exact old shell literal `--kill-after=30s 30m`; the approved bounded suite fix intentionally uses40m.

This is a stale boundary expectation that the earlier focused report/profile-boundary tests did not cover. It is not a runtime Avatar or full-suite timeout failure. The profile and humanAPK jobs depend on this prerequisite; no new profile evidence can be accepted from this attempt. No source edits, retries, cancellations, or artifact fabrication were performed by this monitoring lane.

Retained files: `test-flutter.log` (fullrawlog), `test-flutter-job-status.json` (API metadata), and the prepared `validate_actual_profile.dart` (not run: no artifact).

Full log SHA256: `331f503a26dff313ed53a6f87176c5935384edfc1ff473edeb5016cda22522e6`.

Final metadata: run completed FAILURE at13:29:53UTC; test-core SUCCESS; test-flutter FAILURE; run-dashboard-profile and build-human-diagnostic-apk both SKIPPED. Raw run/job metadata retained in `run-final-status.json` and `jobs-final-status.json`. Monitoring stopped after this final state.
