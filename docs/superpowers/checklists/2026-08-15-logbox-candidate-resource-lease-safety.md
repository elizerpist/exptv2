# LogBox candidate resource lease safety

| ID | Requirement source | Code area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| LSL-01 | User task: creator/borrower lifetime | prepared scene cache | Creator eviction cannot dispose active/retained borrowers; cache tests | DONE |
| LSL-02 | User task: final lease cleanup | prepared scene cache | Final release disposes each layout/header once; no live leases at dispose | DONE |
| LSL-03 | User task: atomic activation / same-key transfer | candidate activation | New lease is retained before old candidate detaches; focused tests | DONE |
| LSL-04 | User task: first railPreview after chip removal | renderer + cache regression | Widget test: 4-row borrower paints without pointer input | DONE |
| LSL-05 | User task: preserve query/scroll/physics architecture | scope boundary | Diff and focused regressions; no renderer/paging/physics changes | DONE |
| LSL-06 | User task: preserve swipe / viewport clipping | existing presentation tests | Focused viewport/swipe regressions, fast suite, and full non-golden suite | DONE |
| LSL-07 | Global delivery rule | GitHub Actions / APK | Commit, push, exact normal APK download and SHA-256 | DONE |
| LSL-08 | Physical Android acceptance | normal `lib/main.dart` APK | Human category-chip removal verification | PARTIAL |

## Evidence

- RED: creator candidate disposal invalidated the active borrower's `TextPainter` resources.
- GREEN: cache-local identity lease ledger owns active, staged, retained, and focus-base lifetimes.
- Physical visual correctness remains pending human Android verification.
- Focused cache and railPreview widget regressions pass after the ledger refactor.
- `./scripts/test-fluvi-fast.sh`, `./scripts/verify-fluvi-boundaries.sh`, and
- Normal human APK downloaded from the successful exact-SHA GitHub Actions job:
  `fluvi_HUMAN_DIAGNOSTIC_1296236.apk`, SHA-256
  `e8fbdce2aae81e254502d5562a9f5d9a578b82332c13c1ed3781cac167a64d5e`.
  the full non-golden Flutter test suite pass; `flutter analyze --no-pub` has no issues.
