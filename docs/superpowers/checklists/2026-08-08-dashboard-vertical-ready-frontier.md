# Dashboard vertical ready-frontier acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VFR-01 | §§0, 36–37 | frozen rail files | All frozen rail/physics hashes and diffs remain unchanged from 3e61da2 | SHA-256 + `git diff` | DONE |
| VFR-02 | §§1–5, 16–17 | committed viewport geometry | Total count is informational; extent is built only from the contiguous drawable prefix | cache + widget regression | DONE |
| VFR-03 | §§4, 7–8, 18–19, 41 | controller/cache | Every page request reaches committed/frontier-advanced or explicit rejected/failed terminal state with reason | controller unit tests + diagnostics | DONE |
| VFR-04 | §§9–13, 32–36 | demand coordinator/cache | Bounded forward/backward drawable windows, keyset dedupe, atomic target-safe retention and rail priority | cache/controller scale tests | DONE |
| VFR-05 | §§14–15, 20–21 | LogBox render surface | Page zero reuses rail preview; page 1+ is fully prepared before paint; normal scroll has zero cache misses or blank rows | widget/render tests | DONE |
| VFR-06 | §§22–26, 38–40 | diagnostics/logger/debug console | General O(1) ring, frozen capture ring, transition-only aggregation and capture controls/report are available in profile | logger/widget tests | DONE |
| VFR-07 | §§27–34, 42–43 | paged cache/controller/widget | 658 and 1k cross page zero to final row; 10k/50k/100k traverse monotonically with bounded heavy caches | end-to-end widget + deterministic harness | DONE |
| VFR-08 | §§42–44 | all modified files | No full list materialization, paint-time layout/paging, target-before-ready eviction, golden or rail change | source/diff inventory | DONE |
| VFR-09 | §45 | verification | Targeted and full non-golden Flutter tests/analyze, GitHub profile gate and diagnostic APK delivery pass | Ubuntu proot + Actions + APK checks | PARTIAL — targeted 35/35, full non-golden 325/325 and analyze PASS; GitHub profile build/APK pending |
| VFR-10 | §§39, 42, 45 | physical device | Capture proves no phantom extent/disappearing rows and rail parity on device | user physical capture report | BLOCKED |
