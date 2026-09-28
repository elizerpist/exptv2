# Mind square 4×3 + Balance unified/Tetris acceptance checklist

Status legend: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

The three supplied specifications are explicit implementation approval. Visual
references remain mandatory inputs: the four-section composition is based on
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260928-082420.png`.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MIND-SQ-01 | Prompt 1 §§1–3 | Mind Year settings/controller/tuner | `MindYearFourColumnCellStyle` is one canonical setting, defaults/reset to `fillHeight`, and is user-selectable. | focused settings/tuner tests | DONE |
| MIND-SQ-02 | Prompt 1 §§4–14 | Four-column fit + viewport | Fill mode stays vertically filled; square mode has true square cells, calculated lower free region, and one relocated selector with short-viewport top fallback. | pure geometry + mounted-rect test | DONE |
| MIND-SQ-03 | Prompt 1 §§15–18 | MonthGroup layout binding | 3×4 has neither Zárás nor Scope and no footer height; 2×6 retains Scope only; MonthCard-border default remains off. | focused viewport/golden tests | DONE |
| MIND-SQ-04 | Prompt 1 §§21–32 | painter/hit geometry + boundary | Painter and taps share the same width/height geometry; preferences/layout changes do no data/Query/slider work. | focused viewport regressions | DONE |
| BAL-UNI-01 | Prompt 2 §§1–3,22–23 | Balance settings/controller/tuner | One Balance-only `separateCards`/`unifiedCard` setting defaults/resets to separate and is user-selectable. | focused settings/tuner tests | DONE |
| BAL-UNI-02 | Prompt 2 §§4–15,25–26 | Balance core surface + shared seam | Fully expanded unified mode has a one-surface Header→body silhouette, Budget-derived seam, one outer border/shadow, subtle live Header bridge, and no redundant full detail shell. | resolved-property + golden/widget test | DONE |
| BAL-UNI-03 | Prompt 2 §§16–19,27 | Balance core surface | Carousel, visibility, selection, indicators, details and data/controller owners remain intact in both styles. | Balance core/regression tests | DONE |
| TET-01 | Prompt 3 §§1–3,22–23 | Balance settings/controller/tuner | Unified-only subordinate body-layout setting defaults/resets to current carousel/detail, stays retained while separate is selected. | focused settings/tuner tests | DONE |
| TET-02 | Prompt 3 §§4–16,28–31 | pure four-section resolver + scaffold | Header-excluded body partitions exactly 60/40 and 70/30/50/50; four neutral centered labels only, with visual gutter insets only. | pure + mounted rect + golden test | DONE |
| TET-03 | Prompt 3 §§17–26,32–35 | Balance body switch | Tetris replaces carousel/detail/dots without changing unified outer/downstream geometry; returning restores the selected topic and no financial/Query work occurs. | Balance core/boundary regressions | DONE |
| REG-01 | all prompts | existing defaults and surfaces | Existing Mind and Balance defaults, card visibility, wave, carousel mechanics, Direction/Summary/count/nav geometry remain intact. | focused suites, fast suite, analyzer, diff check | DONE |
| DEL-01 | user delivery instruction | GitHub Actions / APK | Production commit is pushed; exact human APK from its successful run is downloaded to `/storage/emulated/0/Download/fluvi` and SHA-256 verified. | GitHub Actions + file/hash | NOT DONE |

`PHYSICAL VALIDATION: PENDING — USER ONLY`

Verification evidence: focused Mind suite (50 tests), Balance core suite (34
tests), settings/tuner/geometry suite (31 tests), project fast suite (434
tests), `dart format --set-exit-if-changed`, `git diff --check`, and
`flutter analyze --no-pub --no-fatal-infos` all passed before delivery.
