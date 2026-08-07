# Dashboard LogBox scene cache and profile diagnostics acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCN-01 | §§1, 25 | Git refs/frozen files | dab4347 milestone ref/tag exists; frozen component hashes have no diff | `git rev-parse`, SHA-256, path diff | DONE |
| SCN-02 | §§2–3 | LogBox cache/painter | screenshot symptom and exact once-only cache lifecycle are documented and reproduced | source trace + regression test | DONE |
| SCN-03 | §§4–5 | logbox application/presentation | one canonical PreparedLogBoxScene cache owns exact-width bounded scenes | unit tests and source inspection | NOT DONE |
| SCN-04 | §§5–6 | core coordinator/cache | current and immediately reachable catalog windows rotate before parent commit | navigation/widget tests | NOT DONE |
| SCN-05 | §§2, 7, 21 | painter/cache | row avatar, text, amount, time, and header are atomic; no post-ready text/critical miss | 100-crossing tests | NOT DONE |
| SCN-06 | §§8, 22 | rail hot path | no crossing layout/format/projection/I/O and O(1) scene lookup | regression counters/tests | NOT DONE |
| SCN-07 | §§9–12, 23 | fixtures/index/cache | 700/10k/50k/100k matrix, explicit retained/staging bounds and memory metrics | deterministic scale suite/report | NOT DONE |
| SCN-08 | §§13–17 | diagnostics policy/logger/shell | debug plus explicit profile diagnostic builds receive live bounded events and status; release is off | unit/widget tests | NOT DONE |
| SCN-09 | §§18–20 | debug console | report is readable onscreen; refresh/copy has disabled/progress/success/error states | widget tests | NOT DONE |
| SCN-10 | §§15, 20 | CI/workflow | profile diagnostic APK uses all required Dart defines | workflow source + successful run | NOT DONE |
| SCN-11 | §§13, 24 | all modified areas | no physics tuning, hidden-widget warmup, unlimited cache, database replacement, or golden test | diff/test inventory | NOT DONE |
| SCN-12 | §16, §25 | build delivery | online profile APK downloaded, SHA-256 and ZIP integrity verified | GitHub Action + local checks | NOT DONE |
| SCN-13 | §25 | physical device | profile APK reaches ready, usable console, no bootstrap-current miss | physical report | BLOCKED |
