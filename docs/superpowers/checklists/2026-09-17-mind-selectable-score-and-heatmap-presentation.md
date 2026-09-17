# Mind selectable score and heatmap presentation — acceptance checklist

**Status convention:** `TODO`, `IN PROGRESS`, `DONE`. A row is `DONE` only
when its stated verification has passed. Until every functional row is
`DONE`, **BUILD GATE = CLOSED**: no APK build, CI dispatch, or build-triggering
push is permitted.

**Approved product sources**

- User feature specification, 2026-09-17 (authoritative behaviour and UX).
- `f332b7128db300f5b0d38065eb0a124dc5bbf56b:docs/prototypes/stats_fastfood_2025_sim.html`
  (exact HTML Expense mathematics and Fastfood reference data).
- `origin/spendeetest:balance_latest_layout.html`, B3M-MY3 section
  (heatmap presentation only; its `annualHeatLevels` fixture is explicitly
  non-semantic).
- `/storage/emulated/0/spendee/mind score Reference .png` (already accepted
  expanded Mind Header chart; strict no-regression visual reference).
- Current application source at `eb9afc919f62e071c4d361cb9ccf3e495c047b3e`.

**Preflight record**

| Field | Result |
| --- | --- |
| Application branch | `fix/mind-year-heatmap-calendar-direction-fluvi-20260913` |
| Local / remote starting SHA | `eb9afc919f62e071c4d361cb9ccf3e495c047b3e` |
| Tracked worktree changes | none |
| Existing untracked files | diagnostic `.tmp-*`, `index.scip`, and `test/features/dashboard/presentation/failures/`; preserve untouched |
| Structuring Apps | `/data/data/com.termux/files/home/.codex/skills/structuring-apps/SKILL.md` (local skill; no version metadata) |
| Design approval | the supplied specification is explicit approval; user requested inline implementation without another approval gate |

## Architecture / ownership gate

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | One semantic Expense score authority; user §4, §15 | `mind_behavioral_score_projection.dart`, live projection, Core | All Expense modes are one projection pipeline; Header/chart never contain financial formulas | boundary and unit tests; source review | DONE |
| ARC-02 | Separate finance settings ownership; user §4 | new Mind score settings controller/domain | Header tuner renders state but does not own score semantics | controller and tuner tests | DONE |
| ARC-03 | Separate heatmap presentation ownership; user §4, §24 | new heatmap presentation settings controller/domain | Palette/layout/footer preferences are not Query state and do not become painter state | controller and widget tests | DONE |
| ARC-04 | Canonical Query / two-ended amount filter unchanged; user §7, §31 | existing Query range and Core preview lane | No extra threshold/filter or duplicated membership source | query and live-preview regression tests | DONE |
| ARC-05 | Existing shared Header controller/ticker; user §30–31 | `DashboardHeaderVisualController`, current Mind policy | No ticker/controller is added; chart visual architecture stays intact | widget/boundary tests and source review | DONE |
| ARC-06 | One annual heatmap projection authority; user §23, §27 | `MindYearHeatmapFrame` and prepared membership | Palette/layout/footer are projections over the existing immutable frame/read model | identity and no-I/O tests | DONE |
| ARC-07 | Protected Time/Avatar/LogBox ownership; user §31 | protected existing controllers | No changes to their physics/controllers or renderer ownership | diff audit and protected suites | DONE |

## Score settings and common semantics

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCR-01 | Expense algorithm setting with exactly 3 values; user §5 | score settings domain/controller; existing Header tuner | `htmlCentered`, `htmlTrailing`, `causalTrailing` are selectable; default causal trailing | pure controller + tuner tests | DONE |
| SCR-02 | Causal history setting with exactly 2 values; user §6 | score settings domain/controller; tuner | `selectedScopeStart` and `fullFilteredHistory`; default full history | pure controller + tuner tests | DONE |
| SCR-03 | Inactive causal-origin UI outside causal mode; user §6, §14 | tuner section | Origin selector is visibly inactive/disabled for both HTML choices and does not alter their math | widget tests | DONE |
| SCR-04 | No Query/list/Summary mutation when settings change; user §5 | Core settings listener/publication | Only score frame/header palette/chart republish from resident input | production-parent test | DONE |
| SCR-05 | Common canonical membership; user §7 | score projection input | Direction, time/focus facets, inclusive range and refinements are reused exactly | range/focus intersection tests | DONE |
| SCR-06 | Daily points / Day never hourly; user §11–12 | score target resolver | Day resolves a daily point; no hourly branch exists | domain and integration tests | DONE |
| SCR-07 | Atomic score/header/chart/color provenance; user §26 | score identity/live publication | Settings revision is carried in immutable publication identity; stale mode frame cannot return | live projection/production-parent rapid-switch tests | DONE |
| SCR-08 | Income no-regression; user §14 | existing Income branch | Income formula/no-signal stays unchanged and does not alter saved Expense selection | existing + new regression tests | DONE |

## Expense mathematical modes

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MAT-01 | Common chronological daily-series preparation | score domain/prepared daily index | Amount range is applied before daily aggregation; no raw-row work on preview | unit/profile tests | DONE |
| MAT-02 | HTML centered scope-wide sparse/dense decision; user §8 | score domain | First-to-last active evaluation series; single `focusScopeDays` decision | numerical tests | DONE |
| MAT-03 | HTML centered sparse formula; user §8.2 | score domain | Whole-scope active-day max, real active dates, latest meaningful resolver | numerical tests | DONE |
| MAT-04 | HTML centered dense formula; user §8.3 | score domain | Centered ±15 window, constant HTML EMA period, whole-series maxima, 50/50 pressure | exact HTML-port comparison | DONE |
| MAT-05 | HTML centered intentional non-causality | tests/docs | Tests document and prove centered/whole-max future dependency | numerical regression | DONE |
| MAT-06 | HTML trailing shared scope-wide math; user §9 | score domain | Same as HTML centered except `[d-30,d]` signals | numerical tests | DONE |
| MAT-07 | HTML trailing remaining non-causality | tests/docs | Tests prove whole-series normalisation/classification/period can still depend on future | numerical regression | DONE |
| MAT-08 | Causal forward daily series; user §10 | score domain | One forward series, never per-target `_expensePoint()` reconstruction | source boundary + numerical tests | DONE |
| MAT-09 | Causal trailing signals; user §10.1 | score domain | Every signal uses only `[d-30,d]` | numerical tests | DONE |
| MAT-10 | Causal cumulative sparse→dense transition; user §10.2, §10.5 | score domain | First 12 active days sparse; 13th becomes dense permanently | numerical tests | DONE |
| MAT-11 | Causal dynamic forward EMA; user §10.3 | score domain | Period/alpha comes from cumulative state at d; no restart | numerical tests | DONE |
| MAT-12 | Causal past-only normalisation; user §10.4 | score domain | Running references read no future input; score is future-invariant | numerical tests | DONE |
| MAT-13 | Scope-start causal origin; user §11 | score target/scope resolver | SUM/year/month start at defined analytic origin; Day uses containing month | numerical and target tests | DONE |
| MAT-14 | Full-filter-history causal origin; user §12 | score target/scope resolver | Warm from earliest matching non-time filter data, slice current scope | view-invariance tests | DONE |
| MAT-15 | Header latest point equals chart terminal point; user §13E | live projection | Header and chart use exact same score series frame | live projection tests | DONE |
| MAT-16 | Exact 2027 Fastfood HTML-centered baseline; user §3, §13A | score tests/fixture | 100 rows / 645,560 HUF matches exact HTML `categorySeries`, terminal about 85 and improving shape | test-only HTML port + numerical assertion | DONE |
| MAT-17 | Existing 2027 Fastfood data immutable; user §3 | Android demo fixture | No generation/seed mutation in this task | diff check and fixture test | DONE |

## Live performance and slider behaviour

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LIV-01 | All three modes update live during range drag; user §15 | Core preview lane / score projection | Heatmap, score, chart and palette update with latest preview | integration test | DONE |
| LIV-02 | No canonical Query commit per pointer tick | existing range control/Core | Existing display-frame coalescer/commit boundary remains | query + widget regression | DONE |
| LIV-03 | Pointer hot path has no Room/repository/raw-row/index/scene/TextPainter work | prepared projections/Core | Resident daily indexes only; bounded day-domain traversal if necessary | counters/profile tests | DONE |
| LIV-04 | Measure all modes; user §15, §32 | score work counter/profile test | p50/p95/max, buckets, source rows, repo/index calls reported | focused profile evidence | DONE |
| LIV-05 | Existing visible-scope adaptive range/nice snap unchanged | existing range authority/control | No regression in max/snap or slider hit-test owner | protected range tests | DONE |

## Heatmap presentation settings

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HMP-01 | Palette selector; user §16 | presentation settings controller/tuner | Exactly `fluvi` and `b3mMy3`; default Fluvi | pure/controller + tuner tests | DONE |
| HMP-02 | Fluvi palette no-regression; user §17 | palette resolver | Current empty/min/interpolated/max/equal colors remain exact | pure palette tests | DONE |
| HMP-03 | B3M levels L0–L4; user §18 | palette resolver | Exact rgba values and L3/L4 white foreground decision are represented | pure palette tests | DONE |
| HMP-04 | Real intensity mapping, not fake HTML fixture; user §18 | palette resolver | Empty stays neutral; nonempty uses `round(clamp(intensity)*4)` | semantic/day tests | DONE |
| HMP-05 | Live palette switch no data mutation; user §16, §27 | viewport/painter | Same `MindYearHeatmapFrame` identity; immediate repaint; no Query/I/O | widget/identity tests | DONE |
| HMP-06 | Layout selector; user §19 | presentation settings controller/tuner | Exactly `threeColumns` / `twoColumns`; default three | controller + tuner tests | DONE |
| HMP-07 | 3×4 layout regression; user §19.1 | viewport layout | 12 unique months, 3 columns/4 rows, current geometry/gaps retained | widget geometry tests | DONE |
| HMP-08 | 2×6 full-width layout; user §19.2 | viewport layout | 2 columns/6 rows, `width=(content-rowGap)/2`, larger cells | widget geometry tests | DONE |
| HMP-09 | Calendar geometry / one scroll owner | viewport | Mon–Sun, 4/5/6 rows, Feb 29; same ScrollController through layout change with safe offset clamp | widget tests | DONE |

## Monthly footer presentation

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FTR-01 | Independent net-close toggle; user §20 | presentation settings/tuner | `Zárás = full month income - full month expense`; no reserved row when off | widget/aggregate tests | DONE |
| FTR-02 | Independent active-direction toggle; user §21 | presentation settings/tuner | `Bevétel`/`Kiadás` full month amount tracks active direction | widget/aggregate tests | DONE |
| FTR-03 | Both enabled; user §22 | MonthCard layout | Deterministic order: Zárás then direction total; card height includes only enabled rows | widget tests | DONE |
| FTR-04 | Full-month aggregate authority; user §23 | prepared-base/frame aggregate read model | Bounded immutable 12-month income/expense data; no focus/range/painted-cell dependency | domain/core tests | DONE |
| FTR-05 | Footer liveness and independence | Core/frame/viewport | Focus/partner/range does not change values; year/direction does; no build/paint I/O | integration/profile tests | DONE |

## Tuner, visual baseline, and integration

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| UI-01 | All controls in existing Header tuner; user §4, §25 | `DashboardHeaderVisualTuner` composition | Mind Score and Mind Heatmap sections appear in same tuner; no new page/dialog/panel | widget test/source review | DONE |
| UI-02 | Existing Mind Header color-window control unchanged | visual tuning/score policy | Existing independent 8-anchor score color policy and tuner slider remain unchanged | header policy regression | DONE |
| UI-03 | Accepted chart visual no-regression; user §30 | existing chart/surface | Upper-left text, bounds, line, endpoint, guide, fade, expanded clip, one ticker unchanged | direct source + golden/boundary tests; reference reread | DONE |
| UI-04 | Score setting atomicity | Core/live policy/chart | New setting cannot publish old score/chart/palette combination | rapid mode integration test | DONE |
| UI-05 | Cross-combination matrix; user §29 | production parent/viewport | Four specified combinations and rapid sequence converge coherently | integration tests | DONE |

## Delivery and validation gate

| ID | Requirement / source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VAL-01 | Mathematical focused suite | score tests | All mode/origin/Fastfood/Income numerical tests green | Ubuntu Flutter command | DONE |
| VAL-02 | Heatmap focused suite | domain/viewport/tuner tests | Palette/layout/footer/scroll/frame tests green | Ubuntu Flutter command | DONE |
| VAL-03 | Production-parent and live suite | Core tests | direction/time/focus/range/settings latest-wins tests green | Ubuntu Flutter command | DONE |
| VAL-04 | Protected regressions | existing protected suites | Query range, header chart/color, Mind Year, Time/Avatar tests green | Ubuntu Flutter command | DONE |
| VAL-05 | Analyzer and whitespace | changed Dart/tests | `flutter analyze` and `git diff --check` pass | Ubuntu / Git commands | DONE |
| VAL-06 | Profile evidence | focused performance harness | Score/mode/range costs and prohibited-work counters meet contract; inherited null FrameTiming remains honestly classified | profile command | DONE |
| VAL-07 | Build-gate table | this document + delivery log | Every functional row `DONE` and focused tests green before build/push | explicit pre-delivery table | DONE |
| VAL-08 | Commit/push/CI/APK after gate only | GitHub delivery | Application commit/push, matching CI human APK, downloaded file and SHA | Git/GitHub/sha256 evidence | DONE |
| VAL-09 | Matching SCIP after final application source | tooling branch | Manifest source head equals final app SHA; tooling artifacts separate | tooling tests/hash | DONE |

## Build-gate snapshot

| Feature | Status |
| --- | --- |
| HTML centered | DONE |
| HTML trailing | DONE |
| Causal trailing | DONE |
| Scope-start origin | DONE |
| Full-history origin | DONE |
| Fastfood numerical regression | DONE |
| Heatmap Fluvi palette | DONE |
| Heatmap B3M palette | DONE |
| 3×4 layout | DONE |
| 2×6 layout | DONE |
| Net footer | DONE |
| Direction-total footer | DONE |
| Both footers | DONE |
| Slider/live integration | DONE |
| Income regression | DONE |
| Header/chart atomicity | DONE |
| Heatmap publication regression | DONE |
| Performance bounds | DONE |
| Analyzer | DONE |
| Focused tests | DONE |

**BUILD GATE = OPEN — 2026-09-17, before application commit/push.**

## Validation evidence used to open the gate

PASS

```text
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test --reporter compact test/features/dashboard/mind/domain/mind_behavioral_score_projection_test.dart test/features/dashboard/mind/domain/mind_behavioral_score_chart_series_test.dart test/features/dashboard/mind/domain/mind_behavioral_score_live_projection_test.dart test/features/dashboard/mind/domain/mind_expense_score_algorithms_test.dart test/features/dashboard/mind/domain/mind_presentation_settings_test.dart'
```

`+39 All tests passed`; includes exact HTML-centered 2027 Fastfood parity
(100 rows, 645,560 HUF, terminal rounded 85), all algorithms, causal origins,
Income, and stale setting provenance.

PASS

```text
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test --reporter compact test/features/dashboard/mind/domain/mind_year_heatmap_projection_test.dart test/features/dashboard/mind/domain/mind_year_heatmap_live_projection_test.dart test/features/dashboard/mind/domain/mind_year_heatmap_monthly_aggregates_test.dart test/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver_test.dart test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart'
```

Focused domain/widget/tuner suite passed; individually verified evidence is
`+17` heatmap domain/palette, `+10` viewport, and `+14` tuner tests.

PASS

```text
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test --reporter compact test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart'
```

`+83 All tests passed`; includes Time/Avatar, focus, direction, slider,
score-setting, full-month footer authority and cross-combination coverage.

PASS

```text
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test --reporter compact test/features/dashboard/query/domain/query_amount_range_test.dart test/features/dashboard/query/presentation/query_amount_range_control_test.dart test/features/dashboard/presentation/dashboard_header_mind_score_color_test.dart test/features/dashboard/presentation/mind_header_score_chart_test.dart test/features/dashboard/presentation/mind_header_score_chart_boundary_test.dart test/features/dashboard/presentation/mind_header_score_chart_golden_test.dart'
```

`+28 All tests passed`; includes adaptive range/snap, the accepted expanded
chart golden/boundary evidence, chart fade/reveal, and Header color policy.

PASS

```text
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test --reporter compact test/features/dashboard/mind/domain/mind_expense_score_performance_test.dart'
```

`+1 All tests passed`; all algorithms use resident daily buckets and report
zero source-row/repository/index work during preview. Automated timings are
not physical-device acceptance.

PASS

```text
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter analyze lib/features/dashboard/application/dashboard_core_controller.dart lib/features/dashboard/mind/domain/mind_behavioral_score_settings.dart lib/features/dashboard/mind/domain/mind_behavioral_score_live_projection.dart lib/features/dashboard/mind/domain/mind_behavioral_score_projection.dart lib/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart lib/features/dashboard/mind/domain/mind_year_heatmap_projection.dart lib/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver.dart lib/features/dashboard/mind/presentation/mind_year_heatmap_viewport.dart lib/features/dashboard/presentation/core_dashboard.dart lib/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart test/features/dashboard/mind/domain/mind_behavioral_score_chart_series_test.dart test/features/dashboard/mind/domain/mind_behavioral_score_live_projection_test.dart test/features/dashboard/mind/domain/mind_behavioral_score_projection_test.dart test/features/dashboard/mind/domain/mind_expense_score_algorithms_test.dart test/features/dashboard/mind/domain/mind_expense_score_performance_test.dart test/features/dashboard/mind/domain/mind_presentation_settings_test.dart test/features/dashboard/mind/domain/mind_year_heatmap_monthly_aggregates_test.dart test/features/dashboard/mind/presentation/mind_year_heatmap_palette_resolver_test.dart test/features/dashboard/mind/presentation/mind_year_heatmap_viewport_test.dart test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart'
```

`No issues found` (23 items, 15.6s).

PASS

```text
git diff --check
```

No whitespace errors.

KNOWN INHERITED LIMITATION

`frame_timing_headroom` remains historically invalid (`null`) in the inherited
full-suite profile evidence. It was not weakened or reported as green here.

## Post-gate delivery evidence

PASS

```text
git push origin fix/mind-year-heatmap-calendar-direction-fluvi-20260913
```

Application commit `2c7a9e69196267db0d14e153892ff2f192c13978` pushed to the
required branch. GitHub Actions run
`https://github.com/elizerpist/exptv2/actions/runs/35227140478` completed its
`test-flutter`, `test-core`, and `build-human-diagnostic-apk` jobs successfully.

PASS

```text
gh release view fluvi-human-diagnostic-2c7a9e6 --json targetCommitish,assets
sha256sum /storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_2c7a9e6.apk
strings /storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_2c7a9e6.apk | rg -F 2c7a9e69196267db0d14e153892ff2f192c13978
```

The 82,924,849-byte normal human diagnostic APK is present at
`/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_2c7a9e6.apk`.
Its release target and embedded build identity are
`2c7a9e69196267db0d14e153892ff2f192c13978`; local and release SHA-256 are
`6007dbef8134f5cf08c4e8220f32febbd620dd435ceae438f03a347e4ba4633e`.

PASS

```text
dart pub global run scip_dart ./
dart run tools/codegraph/bin/fluvi_codegraph.dart generate ...
cd tools/codegraph && dart test --reporter compact
```

The exact-source index manifest records application source head
`2c7a9e69196267db0d14e153892ff2f192c13978`, parent
`eb9afc919f62e071c4d361cb9ccf3e495c047b3e`, `scip_dart` 1.6.2, and raw index
SHA-256 `bf9e1ea1af3f10d0051be061a124646e6c16c95949c06e55e8d0a4f79242d369`.
The separate tooling commit is `bf4e831e68ea5dd634b867ef328fafc26a6c0173` on
`tooling/scip-codegraph-v1`; its 15 tooling tests and provenance query passed.

PHYSICAL VALIDATION

PENDING — USER ONLY
