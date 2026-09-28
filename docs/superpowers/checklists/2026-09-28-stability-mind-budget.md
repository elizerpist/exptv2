# Stability, Mind Year, and Budget Surface Acceptance Checklist

## Architecture card

### Scope and sources

- User requirements: Cashflow Stability dual view and Balance card membership;
  Mind 4×3 vertical fill/defaults; Budget shared-card/Header connection.
- Accepted references: `/storage/emulated/0/spendee/source of truth/stabil1.png`
  and `/storage/emulated/0/spendee/source of truth/stabil2.png`.
- Existing owners: `BalanceCashflowStabilityCard`, `BalancePresentationSettings`,
  `MindYearHeatmapPresentationSettings`, `MindYearHeatmapViewport`,
  `FluviGlobalAppearance`, and `BudgetContentCardStyleController`.

### Single source and write path

| State | Owner | Lifetime | Only write path |
| --- | --- | --- | --- |
| Stability visual state | `BalanceCashflowStabilityCard` | selected renderer lifetime | local card tap |
| Balance card membership | `BalancePresentationSettings` | dashboard session | `BalancePresentationController` |
| Mind Year layout/chrome | `MindYearHeatmapPresentationSettings` | dashboard session | `MindYearHeatmapPresentationController` |
| Budget common-card/Header connection | `BudgetContentLayout` | dashboard session | `BudgetContentCardStyleController` |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Evidence |
| --- | --- | --- | --- |
| Header/body seamless shape | `MindExpandedSurfaceShape` | Extract/reuse a neutral surface-shape primitive for Budget unified mode | Budget currently has a separate Header while Mind owns the seamless radii/outer surface |
| Balance carousel motion | shared `CenteredCarousel` | Preserve; filter its input items before datasource | no physics copy |
| Mind cell geometry | `_MindYearHeatmapFourColumnFit` + MonthGroup painter | Extend one geometry contract with width and height | one 4×3 renderer uses width-limited square cells |

## Acceptance tracking

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| STAB-REF-01 | Prompt 1 §1 | source refs | both exact reference files exist and were visually inspected | filesystem + native image inspection | DONE |
| STAB-01 | Prompt 1 §§2–16 | stability card | two data-live internal views, stable outer geometry, tap toggle, semantics, reduced motion | widget/golden tests + direct source/reference inspection | DONE — physical validation remains user-only |
| STAB-02 | Prompt 1 §§6–8 | stability projection | existing observation/median/deviation/band math unchanged | projection regression test | DONE |
| STAB-03 | Prompt 1 §11 | stability card | conflicting point tap does not also change selection | widget gesture test | DONE |
| BCV-01 | Prompt 1 §§17–21 | Balance settings/core surface | all canonical card IDs visible by default; settings list is catalog-tied; filter occurs before carousel source | unit/widget tests | DONE |
| BCV-02 | Prompt 1 §§22–29 | Balance selection/core surface | coherent selected visible ID; right then left fallback; one/two-card-safe indicators | widget tests | DONE |
| BCV-03 | Prompt 1 §§31–33 | Balance controller | no query, repository, projection, or physics side effects; reset restores all IDs | boundary/regression test | DONE |
| MIND-ROOT-01 | Prompt 2 §§1–6 | four-column fit | independently calculate `cellWidth` and `cellHeight` from live constraints; no guessed delta | pure resolver test | DONE |
| MIND-GEO-01 | Prompt 2 §§7–11 | MonthGroup/painter/hits | painted rectangles, group heights, and day hit targets use matching width/height geometry | widget/painter geometry test | DONE |
| MIND-GEO-02 | Prompt 2 §§11–12, 22–24 | four-column fit | 4×3 internally fills annual viewport within 0.5 px on tall and short fixtures | pure + golden/physical-size geometry test | DONE |
| MIND-DEF-01 | Prompt 2 §§13–15 | global/Mind settings | seamless Mind and 4×3 Year are canonical, user-changeable defaults | settings/default tests | DONE |
| MIND-DEF-02 | Prompt 2 §§16,19 | Mind settings | MonthCard border defaults off and resets off | setting test | DONE |
| MIND-2X6-01 | Prompt 2 §§17–18,26 | MonthGroup/viewport | 2×6 excludes `Zárás`, retains scope amount, and reclaims the footer row | widget/golden test | DONE |
| BUDGET-01 | Prompt 3 | Budget core surface | selecting `Közös kártya` joins Header and content with Mind-equivalent seamless ownership | widget geometry/surface test | DONE |
| BUDGET-02 | Prompt 3 | shared surface primitive | one shared shape mechanism, no duplicated radius state machine | boundary/direct inspection test | DONE |
| REG-01 | Both prompts | dashboard defaults/geometry | prior accepted defaults, count visibility, carousel physics, Mind data/slider, and Budget semantics remain | serial focused regressions | DONE |
| DEL-01 | Global delivery rule | GitHub Actions/APK | commit, push, successful human APK, local SHA-256 | Actions + local SHA | PARTIAL — initial-mount visibility reconciliation awaits its own production APK |

## Evidence received

- `feature/balance-wave-defaults` at `c7f189c43c06d7336bdf25900954910d2682560a` is a linked isolated worktree and started clean.
- Both exact Stability references now exist and were opened at their native
  941×1672 resolution: `stabil1.png` is the distribution/legend/metrics view;
  `stabil2.png` is the three-color band and interpretation-panel view.
- The current 4×3 resolver proves the width-limited square-cell root cause.
- The pre-change Budget unified-card composition kept Header/body as separate
  surfaces; the new shared seam primitive is the single physical owner in its
  settled unified state.
- The repaired 4×3 fit derives the reference static height (88 logical px)
  from shared constants, resolves separate `cellWidth`/`cellHeight`, and fills
  the direct field with a <= .5 logical-px residual in tall and short fixtures.
- `test/goldens/mind_year_heatmap_4x3_vertical_fill.png` is the focused
  production-size visual evidence; it was generated only after its geometry
  and hit-target tests passed.
- Budget `unifiedCard` now consumes the shared
  `DashboardHeaderContentSeamShape` used by Mind. Split Budget remains a
  separate surface.
- Final serial validation in Ubuntu/proot passed:
  - 94 Balance stability/visibility/settings tests, including the initially
    preconfigured-hidden selected-card reconciliation case;
  - 101 Mind/Budget/default/projection tests;
  - 22 Mind mode-host tests; and
  - 37 CoreDashboard geometry/default tests.
- `flutter analyze --no-pub --no-fatal-infos` completed with `No issues found`;
  `dart format --output=none --set-exit-if-changed` and `git diff --check` are
  clean.
- The Stability source files and their focused goldens were re-opened before
  delivery review. Automated evidence verifies layout state and interaction;
  final physical comparison on the user's device remains `PENDING — USER ONLY`.
- Production commit `1ec27103937cacb7744610de4ae9ed3747582e89` was pushed to
  `feature/balance-wave-defaults`. GitHub Actions run `36380260566` completed
  `test-flutter`, `test-core`, and `build-human-diagnostic-apk` successfully.
  The exact human APK was downloaded to
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_1ec2710.apk`.
  Its local SHA-256 is
  `18e4845a15d197b1ec50257e03da8f17800dd458afeb46e3aa97629ef796c617`, which
  equals the release digest.
- A final independent review then exposed an initial-mount-only visibility
  reconciliation case (the default Cashflow card can already be hidden before
  the surface mounts). The focused red test failed, the central initial
  reconciliation fixed it, and the serial Balance suite passed 94 tests. Its
  production APK delivery is tracked by the current `DEL-01` status.
