# Dashboard vertical round-trip and rail-restoration acceptance checklist

## Architecture card

- **Single source / write paths:** `CommittedLogViewportCache` owns page/root,
  geometry and terminal state; `ExplicitCommittedPagingController` owns
  repository/cursor advancement; the render surface owns domain selection; the
  viewport owns the stable controller's scope reset.
- **Reuse decision:** retain the existing committed cache, controller and
  stable render surface. This fixes their lifecycle contracts rather than
  creating a second pagination or rendering mechanism.
- **Layer flow:** UI scroll intent -> viewport demand -> paging controller ->
  repository -> immutable page -> committed cache -> explicit render domain ->
  painter. No UI code performs repository work.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VRT-01 | §§1, 35, 37 | frozen rail/physics sources | Rail, physics, controller ownership and PreparedIndex hot path have no diff | SHA-256 + git diff | DONE |
| VRT-02 | §§3–7, 21, 32–33 | committed viewport cache | Exact committed page zero is a pinned root, never evicted, preserved at top with canonical geometry and zero reverse page-zero I/O | cache + controller regression tests | DONE |
| VRT-03 | §§18–20, 39 | committed viewport cache | End reached emits once per generation on a terminal forward transition; backward reload cannot change frontier state | cache diagnostic test | DONE |
| VRT-04 | §§8–10, 16–17, 30 | render surface/domain | Preview is always `railPreview`; committed vertical is selected only with an exact active committed identity; paint/hit/semantics agree | surface tests + inspection | DONE |
| VRT-05 | §§11–12, 28–29, 34 | stable viewport | Structural committed scope reset jumps the same controller once to top; preview crossings never reset it | widget test + identity check | DONE |
| VRT-06 | §§23–27, 40–41 | cache/controller/viewport | 658 and 1000 full round trips keep bounded heavy cache, zero blanks/misses, correct first/last rows and stable controller | real paging widget/controller tests | DONE |
| VRT-07 | §§13–17, 27, 41 | rail scene + vertical cache boundary | Deep vertical state followed by rail refinement has non-empty prepared rail preview; vertical LRU cannot mask it | render-domain regression | DONE |
| VRT-08 | §§40–43 | cache/test harness | 10k/50k/100k heavy rows/layouts remain bounded; no golden, timeout, paint-time layout/paging or full-list retention | existing scale suite + source audit | DONE |
| VRT-09 | §§42, 45 | verification/delivery | Focused/full non-golden suite, analysis, GitHub profile build and downloaded APK verify cleanly | proot + Actions + SHA/ZIP | PARTIAL — local suite and analysis pass; remote profile build/APK pending |
| VRT-10 | §42 | physical validation | Capture proves root page present, zero vertical/rail misses, one terminal event and stable identities on a device | user physical report | BLOCKED |

## Current verification evidence

- Full non-golden Flutter suite: **332/332 passed**.
- Flutter analysis (Ubuntu proot): **No issues found**.
- `git diff --check`: clean.
- The frozen-file SHA-256 values match the baseline and their base-commit diff
  is empty. Remote profile APK and physical capture remain outstanding.
