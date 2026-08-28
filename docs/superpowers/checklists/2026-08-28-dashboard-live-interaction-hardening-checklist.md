# Dashboard live-interaction hardening — acceptance checklist

Baseline: `separated-core-modes`, local/remote `731cda5b2b1965e0d2fc8997ddc9ab7ea8e7cbc7`; Drive **Fluvi Logs revision 47**; current category-palette prototype preserved. Status is intentionally `NOT DONE` until code and evidence exist.

| ID | Requirement/source | Intended area | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| LIV-01 | One coherent interaction provenance generation | dashboard application/visible frame | Temporal, avatar, category, partner and search use one immutable generation; deterministic race tests | DONE |
| LIV-02 | Orthogonal Category/Partner/Search facets, not baseQueryKey anchors | focus/query derivation | Facets survive temporal changes, compose with base Query, and stale completions cannot restore them | DONE |
| LIV-03 | Immediate semantics, async scene augmentation | Core/LogBox publication | No semantic interaction awaits scene/paging; fake withheld 40-second gate cannot block input | DONE |
| SUMM-01 | Restore multi-tick Mode fling | Summary/CenteredCarousel caller | Real high-velocity pointer fling emits at least two crossings; controller/position/physics stable | DONE |
| SUMM-02 | User motion cannot self-cancel | auto-reset registry/Core | Direct input invalidates only reset-owned animation; actual user activity remains alive | DONE |
| SUMM-03 | No neighbor-control cooldown | Core motion leases | New Year/Month/Mode input is accepted while old scene future is unresolved | DONE |
| AVAT-01 | Avatar tick atomically drives Budget and Ledger category overlay | avatar drilldown/Core | Each crossing shares target, temporal scope and generation; aggregate clears category immediately | DONE |
| CAT-01 | LogBox category-avatar tap filters immediately | LogBox facet intent | Pill, membership and Summary amount bind same generation; immediate close wins stale future | DONE |
| PART-01 | Partner swipe never freezes | partner swipe/facet intent | Commit filters synchronously and bounded snap-back finishes with withheld publication future | DONE |
| AMNT-01 | Amount has invariant left/right geometry | Summary amount slot | Idle/preview/crossfade/settle retain configured anchor; no motion-only width/right alignment | DONE |
| RING-01 | SUM scale and marker use correct polar mapping | Budget ring geometry/painter | 0=top, increases clockwise; green begins right of top, red ends at seam; changing ratios repaint | DONE |
| RING-02 | Existing SUM styles all respect mapping | Budget presentation settings | Colored style indicator and scale share mapping; no per-tick SVG parse | DONE |
| SRCH-01 | Real editable live SearchPill | LogBox header/facet owner | Stable controller/focus; live Partner OR memo match; blur retains text/filter | DONE |
| SRCH-02 | Prepared, latest-wins search | Ledger prepared derivation | No widget/keystroke Room I/O; s→sp→spa→spar race leaves only spar authoritative | DONE |
| PILL-01 | Query-pill style setting | tuner/facet chips | Default current baseline; solid canonical accent alpha 1, white text/close; semantics unchanged | DONE |
| PILL-02 | Query-pill placement setting | tuner/header chrome layout | bodyTop baseline; inside SearchPill no duplicate/overflow; hidden SearchPill falls back bodyTop | DONE |
| REG-01 | Preserve protected dashboard behavior | Budget/LogBox/Summary/Rhythm | One LogBox controller/position, caches, vertical/horizontal gestures, auto-reset, Spending Rhythm remain covered by regression tests | DONE |
| DOC-01 | Focused architecture plan/checklist and source proof | docs | This checklist/design/plan updated with exact evidence and result statuses | DONE |
| VER-01 | Automated verification | tests/analyzer/diff/CI | Focused + protected test suites, proot analyze, diff check, required remote Android human APK evidence | PARTIAL |
| PHY-01 | Physical Android matrix | Android device | All prompt regression/search interactions physically verified; no unperformed checks claimed | NOT DONE |

## Verification evidence and honest open items

- PASS — live interaction/facet/search suite: 29 tests.
- PASS — SearchPill/facet-chip/LogBox viewport/Partner swipe suite: 47 tests.
- PASS — SUM ring, Spending Rhythm and CenteredCarousel protected suite: 69 tests.
- PASS — legacy Summary amount presentation suite: 11 tests.
- PASS — direct Mode multi-crossing regression with active auto-reset
  invalidation: 1 test.
- PASS — `flutter analyze` in the required Ubuntu proot: no issues.
- PASS — `git diff --check`.
- INHERITED — `summary_pill_experiments_widget_test.dart`,
  `mirrored Segmented fields retain their own rendered hit Rects and flings`,
  fails at its first 40 px / 600 px/s Mode fling on both this worktree and an
  untouched detached `731cda5b` worktree. It does not exercise the new direct
  input callback. The new physical high-velocity multi-crossing regression
  passes.
- NOT DONE — physical Android matrix: `adb devices` found no connected device.
- PENDING — push-specific online human APK build/download/sha256.
