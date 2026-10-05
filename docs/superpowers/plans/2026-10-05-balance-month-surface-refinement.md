# Balance Monthly Surface Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Balance Month `Költés` child-card match the supplied volumetric 3D-wave reference while tightening the adjacent Savings, income/expense and Year bar-card layouts without changing financial semantics.

**Architecture:** The existing immutable Balance Month presentation remains the sole data owner. `FluviTopographicWaveChart` continues to receive already-prepared daily values, but its renderer changes from thin independent contours to one cached local-depth surface: a `FragmentProgram` material pass with a cached Canvas vertex-lit mesh fallback. The Month card continues to compose its established Savings and income/expense primitives; those primitives receive layout-only changes and reuse the authored Budget 3D selection chrome.

**Tech Stack:** Flutter `CustomPainter`, `dart:ui` FragmentProgram/FragmentShader, Canvas `Vertices`, existing `flutter_shaders_ui`, existing Budget avatar chrome, widget/golden/boundary tests.

## Global Constraints

- Preserve Balance/Mind/Budget calculations, filters, time navigation and Header behavior.
- The explicitly restored Balance Header line chart remains unchanged; the Android reference is a source of truth for the Month body and lower comparison card, not a request to alter that Header again.
- Do not add a data source, repository read, query/index owner or presentation-settings owner.
- Keep all four Month spending renderer choices; only the three additive wave choices use the new terrain material.
- Use the supplied SVG `/storage/emulated/0/spendee/asset/fluvi_3d_wave_chart_asset.svg` and latest screenshot `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261005-021521.png` as visual inputs.
- Do not run a local APK build; final Human APK build and download must be through GitHub Actions.
- Keep the pre-existing untracked `test/**/failures/` directories untouched.

## Balance Monthly Surface Refinement architecture card

### Scope and sources

- User requirement: latest Android screenshot plus the 3D material repair prompt in the conversation.
- Accepted reference paths: SVG and screenshot above.
- Existing implementation paths:
  - `lib/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart`
  - `lib/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart`
  - `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`
  - `lib/core/categories/presentation/budget_category_avatar_artwork.dart`

### Single source and write path

- Financial source of truth: existing immutable `BalanceAlternativeMonthPresentation.dailySpend` and `incomeExpense` values.
- Read model: `BalanceAlternativeDailySpendCard` maps its prepared daily points into `FluviTopographicWaveDatum`.
- Only presentation write path: the existing `BalancePresentationSettings` monthly chart renderer selector; no new setting is required.
- Error/retry owner: shader load is local render capability only; it falls back to the deterministic cached Canvas mesh without financial or persistent state changes.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Daily financial values | Existing Balance projection | Existing time/range publication | Immutable prepared values rebuild card |
| Selected chart datum | `FluviTopographicWaveChart`/supplied selected index | Widget interaction | UI-only; no persistence/domain write |
| Terrain geometry and mesh | Chart geometry cache | Values/size revision | Recomputed only on values or size change |
| Shader program/image resource | Chart render state | Mounted shader style | One local capability resource; Canvas fallback if unavailable |
| Savings/income-expense layout | Existing card primitives | Build/layout | Rendering only; no state owner |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Prepared monthly financial series | `BalanceAlternativeMonthPresentation` | Amount/range/filter semantics | Consume unchanged | Boundary test has no repository/query import |
| Savings 3D circle | `BudgetCategoryAvatarSelectionChrome` | Authored 3D shell/progress ring | Reuse, do not recreate | Existing key/widget test |
| Monthly chart renderer state | `BalancePresentationSettings` | Four user choices and persistence | Consume unchanged | Existing settings tests |
| 3D terrain geometry | `FluviTopographicWaveTerrain` | Spline, material foot, contours, marker coordinates | Extend the existing neutral chart geometry owner | Geometry and golden tests |

### Layer flow

`Balance projection → BalanceAlternativeMonthPresentation → DailySpendCard → FluviTopographicWaveChart → cached terrain/one painter/shader-or-mesh renderer`

### Verification

- Domain/unit: spline and local material-foot geometry, zero/sparse/edge-spike data.
- Widget: no insight card, centered Savings layout, Budget chrome switch disc, text alignment and yearly bar width.
- Screenshot/reference: deterministic new card goldens at actual Month-card and narrow-phone constraints, inspected against SVG/screenshot.
- Performance: source/boundary check for one painter, no repository/query import; cache identity behavior; no per-contour widgets.

## Feature acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BMR-01 | Latest user prompt | `balance_alternative_extended_sheet_cards.dart` | Monthly Savings amount is larger, centred, no separator, and the 3D ring sits lower without changing its readable number scale | Widget geometry/style assertions | DONE |
| BMR-02 | Latest user prompt | `BalanceAlternativeDailySpendCard` | The green `Javuló tendencia` insight and inter-card allocation are removed, giving `Költés` chart the recovered height | Widget test, card golden | DONE |
| BMR-03 | Latest screenshot + user prompt | income/expense strip + tokens | Comparison copy below bar is absent; metrics enlarge; expense metric is right aligned; centre uses Budget 3D selection chrome | Widget geometry/key test, golden | DONE |
| BMR-04 | Latest user prompt | annual tokens/painter | Year income/expense bars are exactly 10% narrower than current `.84` pair fraction and labels remain legible | Token/unit test, annual widget test | DONE |
| BMR-05 | SVG + 3D repair prompt | `fluvi_topographic_wave_chart.dart` | Real daily ridge remains data-exact and smooth; all nonzero styles form one continuous local-depth shaded terrain, not a global fill plus independent lines | Geometry unit and high-contrast golden | DONE |
| BMR-06 | SVG + 3D repair prompt | shader + chart painter | Material uses upper-left/front local lighting; shader path is bounded, uses a cached ridge lookup and has cached vertex-lit fallback | Structural widget test, source boundary test, visual golden | DONE |
| BMR-07 | SVG + user prompt | chart painter | 3–4 distinct filled atmospheric waves remain clearly decorative, behind financial terrain; markers/tooltips represent only data | Zero/sparse/spike/widget tests and visual review | DONE |
| BMR-08 | User constraints | presentation layers | No repository/query/index work or new persistent owner; Header and original `current` chart stay untouched | Existing boundary tests + direct inspection | DONE |
| BMR-09 | User delivery requirement | repository/CI | Focused tests, full fast suite, analysis, format, diff check, push, exact normal Human APK and its hash | Command output + GitHub run/APK | PARTIAL — local verification done; commit, CI and exact APK delivery remain |

---

### Task 1: Establish red evidence for card composition and bar geometry

**Files:**
- Modify: `test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart`
- Modify: `test/features/dashboard/presentation/fluvi_topographic_wave_chart_test.dart`

- [x] Write focused tests requiring no `Javuló tendencia` card, a Budget 3D centre switch, larger Savings amount/ring layout, and the `.756` annual pair fraction.
- [x] Run the focused test files and record expected RED failures against the existing implementation.

### Task 2: Replace contour-only material with a cached local-depth surface

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart`
- Create: `shaders/fluvi_wave_surface.frag`
- Modify: `pubspec.yaml`
- Test: `test/features/dashboard/presentation/fluvi_topographic_wave_chart_test.dart`

- [x] Extend the existing terrain geometry cache with local foot coordinates, a closed surface path, vertex-lit mesh data and non-data atmospheric bodies.
- [x] Load one registered FragmentProgram for the shader renderer and bind cached curve lookup data; use the mesh fallback while unavailable/unsupported.
- [x] Draw the terrain in one painter and renderer surface, then only subtle contours/ridge/marker above it.
- [x] Run new geometry and high-contrast RED→GREEN tests.

### Task 3: Apply Month/Year visual composition changes

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart`

- [x] Remove the insight card and recover chart space.
- [x] Move/centre Savings contents and reuse the Budget shell for the centre comparison control.
- [x] Remove comparison copy, enlarge/right-align values, and narrow Year bar pairs by 10%.
- [x] Run the targeted RED→GREEN widget tests.

### Task 4: Visual and boundary verification

**Files:**
- Modify: existing golden test files and approved golden references only when inspected
- Modify: relevant boundary test if the existing guard needs the shader/material contract

- [x] Generate real-card, narrow-phone, zero, spike and reference-shaped visual evidence.
- [x] Inspect generated images against the SVG and latest screenshot before accepting them.
- [x] Run protected settings, current-chart, Balance card and boundary suites.

### Task 5: Final delivery

- [ ] Re-read this checklist and update every status only from fresh evidence.
- [ ] Format changed Dart/GLSL, run focused analysis, broad analysis, fast suite and diff check.
- [ ] Commit one focused application change, push it, monitor the exact GitHub Human APK job, download the exact APK to `/storage/emulated/0/Download/fluvi`, then verify hash and embedded SHA.
- [ ] Append factual delivery evidence in one separate journal-only `[skip ci]` commit.
