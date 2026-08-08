# Human diagnostic APK delivery acceptance checklist

## Architecture card

- **Runtime freeze:** all Dashboard, LogBox, rail and physics runtime sources
  remain byte-identical to `dba08d6`.
- **Build-policy owner:** one compile-time `FluviBuildPurpose` resolver owns
  human-versus-automated diagnostic identity. The app shell only projects that
  immutable identity; it owns no test orchestration.
- **Product boundary:** the human build uses the normal `lib/main.dart`
  entrypoint. The A–J target stays an Actions-only integration-test harness.
- **Workflow ownership:** the human APK depends only on core and Flutter test
  jobs; the automated profile gate remains an independent quality signal.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HAD-01 | §§1–8, 17 | workflow | Human profile build has no integration-test target and is independent of the profile gate | workflow boundary test + Actions graph | DONE locally; Actions pending |
| HAD-02 | §§3, 9–11, 14 | workflow | Automated harness APK is clearly named and never published as the human release | workflow boundary test | DONE locally; Actions pending |
| HAD-03 | §§12–13, 16 | build identity + shell | Human diagnostics show profile/HUMAN_DIAGNOSTIC/app/commit; invalid automated flags in a human build fail fast | unit + widget test | DONE |
| HAD-04 | §§5, 15, 18 | normal app entrypoint | Normal app entrypoint contains no autorun/test driver and remains idle without user input | source boundary + smoke test | DONE |
| HAD-05 | §§2, 17, 20–21 | runtime freeze | No Dashboard/rail/physics/LogBox runtime diff from `dba08d6` | git diff + SHA | DONE |
| HAD-06 | §22 | verification | Non-golden focused/full tests, analysis, Actions human APK, SHA and ZIP integrity pass | proot + Actions | PARTIAL — 337/337 tests and analysis pass; Actions pending |
| HAD-07 | §19 | physical validation | Human device capture validates the dba08d6 runtime | user report | BLOCKED |

## Current verification evidence

- Human-product boundary test first failed on the old workflow, then passed.
- Focused build-identity, normal-app idle and existing interaction-boundary
  tests pass.
- Full non-golden Flutter suite: **337/337 passed**.
- Flutter analysis (Ubuntu proot): **No issues found**.
- Dashboard, rail, physics, LogBox and shared-motion source diff from
  `dba08d6` is empty; only workflow, entrypoint integrity and diagnostic
  metadata changed.
