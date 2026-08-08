# Human Diagnostic APK Delivery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to
> implement this plan task-by-task. The user requires inline execution; do not
> delegate work.

**Goal:** Deliver a normal human-operated profile APK from `dba08d6` without
changing Dashboard runtime behavior, while retaining the automated A–J harness
as a distinct CI-only product.

**Architecture:** Centralize compile-time build identity in diagnostics. The
normal app shell reports it, while the Actions workflow creates independent
human and automated artifacts with hard naming and entrypoint boundaries.

**Tech Stack:** Flutter/Dart compile-time defines, GitHub Actions YAML,
`package:flutter_test` source-boundary tests.

## Global constraints

- Base: `dba08d6f1d87b1723c09a59596f4d44a79c0b8de`.
- No Dashboard, LogBox, vertical paging, rail, physics or controller changes.
- No golden test; human APK must use default `lib/main.dart`, not
  `integration_test` or `test_driver`.
- Build a human product even if the emulator profile quality gate fails.

### Task 1: Product-boundary regressions (RED)

**Files:**

- Create: `test/boundary/human_diagnostic_apk_delivery_boundary_test.dart`
- Create: `test/core/diagnostics/fluvi_build_identity_test.dart`

- [x] Assert the existing workflow incorrectly couples the human build to the
  profile gate and has ambiguous artifact behavior.
- [x] Assert known build-purpose values resolve correctly and an invalid human
  build configuration fails.
- [x] Run focused tests and record the expected RED failure.

### Task 2: Canonical build identity and human boundary (GREEN)

**Files:**

- Create: `lib/core/diagnostics/fluvi_build_identity.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`

- [x] Add immutable human/automated identity resolution and fail-fast human
  autorun invariant.
- [x] Call the invariant from the normal app entrypoint and expose identity in
  physical report and onscreen status.
- [x] Run focused tests until GREEN.

### Task 3: Separate CI products (GREEN)

**Files:**

- Create: `scripts/build-human-diagnostic-apk.sh`
- Modify: `.github/workflows/fluvi-core.yml`
- Modify: `test/boundary/human_diagnostic_apk_delivery_boundary_test.dart`

- [x] Build `fluvi_HUMAN_DIAGNOSTIC_<sha>.apk` from the default app entrypoint
  after only core and Flutter tests.
- [x] Pass automated-purpose identity only to the integration harness and
  archive it under `fluvi_AUTOMATED_TEST_HARNESS_<sha>.apk`.
- [x] Add a static workflow assertion that rejects integration/test-driver
  targets in the human build script.

### Task 4: Verify and deliver

- [x] Prove the runtime freeze with an empty diff against `dba08d6`.
- [x] Run focused and full non-golden tests plus analysis in Ubuntu proot.
- [ ] Push the branch, confirm independent Actions graph, download only the
  human artifact, and verify SHA-256 plus APK ZIP integrity.
