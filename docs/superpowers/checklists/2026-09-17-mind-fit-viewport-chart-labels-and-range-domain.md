# Mind fit-to-viewport heatmap, score-chart time labels, and range-domain repair — acceptance checklist

**Status convention:** `NOT DONE`, `IN PROGRESS`, `DONE`, `PARTIAL`, or
`BLOCKED`. A requirement is `DONE` only after the stated verification has
passed. Until every functional requirement is `DONE`, **BUILD GATE = CLOSED**:
there is no application push, CI/build dispatch, or APK build.

## Evidence boundaries and references

- Current direct user specification, 2026-09-17 — authoritative product and
  forensic contract.
- Application source: `2c7a9e69196267db0d14e153892ff2f192c13978`; current
  branch head `350730a0b72939b9cdc1c968f785b70e5246ef3e` is documentation
  only.
- Matching navigation graph: tooling `bf4e831e68ea5dd634b867ef328fafc26a6c0173`,
  manifest `source_head=2c7a9e69196267db0d14e153892ff2f192c13978`,
  `scip_dart=1.6.2`, raw SHA-256
  `bf9e1ea1af3f10d0051be061a124646e6c16c95949c06e55e8d0a4f79242d369`.
- Approved chart visual baseline:
  `/storage/emulated/0/spendee/mind score Reference .png`; retained logical
  composition is score `(16,16)` and plot `(16,48,346×60)`.
- B3M layout reference:
  `origin/spendeetest:balance_latest_layout.html`; presentation only. Its
  decorative `annualHeatLevels` remains non-semantic.
- 2027 Fastfood fixture remains immutable. The screenshot's exact running APK
  marker and fresh runtime logs are **MISSING EVIDENCE**.

## Architecture card

| Concern | Single owner / write path | Reused mechanism | Prohibited duplicate |
| --- | --- | --- | --- |
| Mind physical range maximum | `DashboardCoreController` + `CurrentQueryController` scoped amount-domain publication | `QueryAmountRange.domainScope`, admitted Mind prepared base, existing preview binding | all-time fallback for a different visible scope, second range state, pointer I/O |
| Sum list observation | existing canonical query → visible frame → committed LogBox viewport pipeline | existing query keys, cursors, paging and paint provenance | speculative list refresh/re-sort/re-query without a RED |
| 4×3 yearly presentation | `MindYearHeatmapPresentationController` and `MindYearHeatmapViewport` | existing immutable `MindYearHeatmapFrame`, calendar geometry, fixed footer | a second data projection, nested/card scroll controllers |
| Chart label visibility | a new Mind chart *presentation-only* controller/state, owned by `DashboardCoreController` and rendered by the tuner | immutable `MindBehavioralScoreChartSeries` epoch-day domain | score/query settings, second chart/financial series, ticker |

UI remains renderer/intent-only. Core retains the only domain/publication
write path; the heatmap painter and chart widgets receive immutable models and
never read repositories, build indexes, or calculate finance data.

## Requirements

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | Structuring Apps / user §20, §27 | Core + new chart presentation domain | One write path per new state; no Query/score semantic ownership in widgets or tuner | boundary source test + source review | DONE |
| RNG-01 | user §§8–11, 22 | `DashboardCoreController.mindAmountRangeBindingFor` and scoped-domain publication | A visible Mind scope receives only its exact `QueryAmountRange.domainScope` maximum; no broader fallback can render | mounted production-parent RED→GREEN | DONE |
| RNG-02 | user §10 | Core diagnostics/test seam | First failing boundary is identified with scope/domain/generation/rendered maximum evidence before repair | regression test and documented source trace | DONE |
| RNG-03 | user §§11, 22, 28 | current preview/commit path | Year/Sum/category/partner/search transitions and preview/final range retain identity/latest-wins behavior and zero pointer I/O | Core/range/live tests | DONE |
| SUM-01 | user §§1, 12, 23 | existing Core/visible-frame/LogBox pipeline | Deterministically classify the Sum observation using count, query key, payload identity and pagination through all 2027 rows | production-faithful forensic test | DONE |
| SUM-02 | user §§12, 27 | smallest proven LogBox owner, only if needed | A production repair exists only if paging/provenance proves a real divergence; otherwise no list runtime source changes | test result + diff audit | DONE — NO DEFECT |
| H43-01 | user §§13–15, 24 | `MindYearMonthCardLayout`, presentation controller/tuner | Tuner exposes exactly the existing layouts plus selectable `4 × 3` | controller/tuner widget tests | DONE |
| H43-02 | user §§13–15 | `MindYearHeatmapViewport` pure geometry | Four columns × three rows use actual constraints, square cells, actual month row counts, no magic device height | pure geometry + widget tests | DONE |
| H43-03 | user §§13–15, 24 | 4×3 viewport renderer | Reference-phone available annual region has `maxScrollExtent == 0`; no nested or card scroll, all 12 cards fit | constrained widget tests, all footer combinations | DONE |
| H43-04 | user §15, §29 | existing heatmap viewport controller | 2×6/3×4 retain one outer scroll owner; switching preserves controller identity and safely clamps offset | regression widget test | DONE |
| CLB-01 | user §§16–20 | new chart presentation domain/controller; existing tuner | Default hidden, toggle appears in the existing tuner, and does not alter financial score/Query | domain + tuner tests | DONE |
| CLB-02 | user §§17–19, 25 | `MindHeaderScoreChart` semantic overlay | When visible, exactly five labels correspond to start/.25/.5/.75/end of actual series epoch-day domain; no duplicate time model | pure projection + widget tests | DONE |
| CLB-03 | user §§18–19, 21, 25 | chart overlay/clipping | Labels are quiet, IgnorePointer, clipped with expansion, absent collapsed, no axis/ticks/grid and preserve fixed plot geometry/ticker count | widget/boundary/golden regression tests | DONE |
| NRG-01 | user §29 / milestones | protected Core/UI owners | No Time/Avatar physics, Query ownership, LogBox architecture, score math, fixture, snapping, Header engine/ticker, or accepted chart paint regression | protected suites + diff review | DONE |
| PRF-01 | GitHub profile failure `35243573729` | `dashboard_interaction_profile_test.dart` | Direction-tap prewarm asserts the exact visible structural amount domain, never the stored all-time template domain | analyzer + clean GitHub profile lane | IN PROGRESS |
| VAL-01 | user §33 | test suites | Focused amount/range, Sum forensic, Core temporal, LogBox paging, heatmap geometry, chart, tuner and score suites pass | Ubuntu-proot commands + clean GitHub core lane | DONE |
| VAL-02 | user §§28, 33 | diagnostics/profile source review | No pointer repository/Room/index/raw-row work; 4×3 O(12); labels only semantic series/settings work; Sum paging unchanged if no defect | counters/tests/source review | DONE |
| VAL-03 | user §33 | Dart/Git | Changed-target `flutter analyze` and `git diff --check` pass | exact commands | DONE |
| DEL-01 | user §§30, 32, 35 | checklist | Every functional row above is `DONE` before build gate opens | explicit pre-push table | DONE — user-authorized online forensic validation completed the remaining Sum rows |
| DEL-02 | user §§30, 34–35 | Git/CI/tooling | Atomic app commits, push after gate, online human APK, matching SCIP and separate journal/tooling commits | GitHub/APK/tooling evidence | PARTIAL — profile assertion correction needs a clean rerun |

## Build-gate snapshot

| Functional delivery item | Status |
| --- | --- |
| Amount max RED/root cause | DONE |
| Amount max repair | DONE |
| Amount max regression matrix | DONE |
| Sum forensic classification | DONE — GitHub `test-core` passed the production-faithful native paging assertion |
| Sum repair or no-defect proof | DONE — NO DEFECT; runtime LogBox source intentionally unchanged |
| 4×3 mode | DONE |
| 4×3 zero-scroll fit | DONE |
| 4×3 footer combinations | DONE |
| Chart labels setting | DONE |
| Exactly five dynamic labels | DONE |
| Chart no-regression | DONE |
| Profile exact-visible-domain assertion | IN PROGRESS |
| Protected regressions | DONE |
| Analyzer | DONE |
| Diff check | DONE |
| Performance bounds | DONE |

**BUILD GATE = CLOSED — the clean online profile lane found an authority
assertion that must be rerun after correction.**

## Validation update — 2026-09-17

- `RED AMD-06` is a mounted production-parent regression: with a generic
  all-time facet domain admitted and the exact Year domain deliberately
  withheld, no `RangeSlider` mounts. After the exact resident domain publishes,
  the rendered maximum is the fixture-derived 13,500 Ft. The prior source
  rendered the unrelated 260,000 Ft maximum at that first frame.
- The slider binding is now exact-visible only. Its separate inactive-direction
  prewarm predicate may inspect resident canonical facet data solely to retain
  one-native-lane preparation; it never supplies a visible range value.
- The real native Sum forensic test was compiled and launched. It could not
  create the Robolectric application because this ARM64 Ubuntu proot lacks
  `conscrypt_openjdk_jni-linux-aarch_64`. Before that, AGP's x86-64 AAPT2 also
  could not start. This is environment evidence, not a passing or failing Sum
  semantic assertion. No LogBox production code was changed.
- Passing focused verification includes: 84 full Core production-parent tests;
  149 Query/LogBox/Mind projection and presentation tests; 8 chart
  widget/golden/boundary tests; targeted tuner and 4×3 viewport tests; changed
  target analysis and diff check.
- PASS — GitHub Actions run `35243573729` (manual normal verification for
  the pushed branch): `test-flutter` passed analysis and the curated Flutter
  suite in 2m35s; `test-core` passed clean Room core tests and native dashboard
  bridge tests in 5m26s. The native Sum forensic proves the all-time query
  keeps one identity while its newest 100 rows are the expected 2027 Fastfood
  mirror and later pages enter older years. Therefore the screenshot does not
  prove a list bug and no LogBox production source was changed.
- PASS — human diagnostic APK job from that run produced and published
  `fluvi_HUMAN_DIAGNOSTIC_d3b32d3.apk`; it was downloaded to
  `/storage/emulated/0/Download/fluvi/`, is 83,088,689 bytes, and has
  SHA-256 `e40ecb26705c8a8a3a064ef65e1bd5fc5c69288e2b9fc1a02b84df81e8247da8`.
  The artifact source marker is `d3b32d388623aac09ea2125e2d35b8dec627cc66`;
  its immediately preceding application source is `9a8a7575`.

## Preflight record

| Field | Result |
| --- | --- |
| Branch | `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` |
| Local HEAD | `350730a0b72939b9cdc1c968f785b70e5246ef3e` |
| Parent / application source | `2c7a9e69196267db0d14e153892ff2f192c13978` |
| Remote HEAD after fetch | `350730a0b72939b9cdc1c968f785b70e5246ef3e` |
| Workspace | existing linked worktree, not a submodule |
| Tracked modifications | none |
| Preserved untracked files | existing `.tmp-*`, `index.scip`, and `test/features/dashboard/presentation/failures/`; neither staged nor changed |
| Structuring Apps | `/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md`; local skill, no version metadata |
| Fresh runtime logs / exact screenshot APK marker | MISSING EVIDENCE |
