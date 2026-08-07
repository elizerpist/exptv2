# Dashboard readiness deadlock and cache-contract acceptance checklist

Date: 2026-08-07

Source: the user's targeted readiness-deadlock and cache-contract repair
instruction, including its physical-device diagnostic JSON.

Base commit: `b30c4e40f5858fcf5b93f05cf61b58ede8677b3c`

Work branch: `fix/dashboard-readiness-deadlock-cache-contract`

Approved design reference:
`docs/superpowers/specs/2026-08-07-dashboard-readiness-deadlock-cache-contract-design.md`

Status vocabulary: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

| ID | Source/reference | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| RDC-01 | §1 | Git/worktree | Target branch starts at the stated base; user-owned untracked diagnostics remain unchanged. | `git status`, `git rev-parse`. | DONE |
| RDC-02 | §2–§5, design state flow | readiness/surface call graph | The documented call graph identifies the exact non-terminating prerequisite and its cause. | Design doc and source inspection. | DONE |
| RDC-03 | §6–§8 | `DashboardInteractionReadiness` | Readiness has explicit, deterministic task state and reaches `ready` without a production timeout. | Unit regression tests. | NOT DONE |
| RDC-04 | §7, §10 | readiness/surface | Only application-side prerequisites gate ready; no paint/layer/semantics/raster/user-event barrier remains. | Source boundary test plus unit tests. | NOT DONE |
| RDC-05 | §9 | atlas/shell/surface | Warmup and renderer use the exact same raster-set instance; bootstrap current viewport records zero category-raster miss. | Identity/key-parity unit/widget test. | NOT DONE |
| RDC-06 | §10 | diagnostics | Each emitted warmup STARTED event has a COMPLETED or FAILED terminal event; no silent pending task exists. | Diagnostics/task-state tests. | NOT DONE |
| RDC-07 | §11, §14 | readiness diagnostics | Structured phase/task/ready/failed timeline includes phase, task, timing, query, revision and generation; a deterministic task failure exposes failed UI. | Unit/widget/export tests. | NOT DONE |
| RDC-08 | §15 A–G | test suite | Cold bootstrap terminates; ready waits for delayed deterministic task; no false readiness. | Focused unit/widget tests. | NOT DONE |
| RDC-09 | §15 H–K | test suite | Warmup failure fails fast; pre-ready rail input is blocked; post-ready input works; first visible frame has no critical cache miss. | Focused widget tests. | NOT DONE |
| RDC-10 | §15 L | existing navigation suite | Rail crossing remains SQL/repository/platform-call free. | Existing focused test. | NOT DONE |
| RDC-11 | §12–§13, §17 | render/rail freeze | Stable bounded CustomPaint remains; rail, carousel, controller, position and physics have no diff. | Diff/stat and boundary tests. | NOT DONE |
| RDC-12 | §12, §18 | test policy | No golden test and no production timeout fallback are introduced. | Source/test scan. | NOT DONE |
| RDC-13 | §16 | delivery | Physical diagnostic APK is built online, downloaded to `/storage/emulated/0/Download/fluvi`, and integrity-checked. | GitHub Actions/artifact/hash. | NOT DONE |
| RDC-14 | global | verification | Focused suite, complete non-golden suite, analysis and `git diff --check` have fresh passing evidence. | Ubuntu-proot command output. | NOT DONE |
