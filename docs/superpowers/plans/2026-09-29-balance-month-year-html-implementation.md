# Balance Havi 2 + Éves HTML-reference implementation plan

> **For agentic workers:** execute inline. The user explicitly authorized implementation without a further approval gate.

**Goal:** Replace the unified alternative Balance Month and Year bodies with live-data renderers whose layout tokens are derived from `html-prototypes/balance-extended-sheet-baseline/index.html`, and add a user-selectable mother-card visibility setting.

**Architecture:** `DashboardBalanceLinkedPresentation` remains the sole immutable financial read model. A scope-specific alternative presentation adapter translates its existing `cashflow`, `closings`, `retention`, and `momentum` values into render DTOs; widgets never aggregate ledger entries. A single HTML-derived visual-token module owns every shared conversion, color, radius, padding, and child-card inset used by the Month/Year alternative renderers.

**Tech stack:** Flutter, immutable Dashboard Balance projections, `CustomPainter`, existing `BalancePresentationSettings`, Flutter unit/widget/golden tests.

## Global constraints

- Reference: `html-prototypes/balance-extended-sheet-baseline/index.html`, screens **Havi 2** and **Éves** only.
- The reference is code, not a raster: values are read from its CSS.
- HTML physical-to-logical conversion is `26.73 physical px = 12 logical px` (`2.2275 px/logical`).
- Preserve the existing `12` logical outer inset, `3` logical half gutter, `70/30`, `60/40`, and Year Card 4/5 split.
- No repository access, Query change, raw-ledger scan, or new projection may be caused by this presentation feature.
- Default mother-card visibility is on; user can toggle it off and reset restores on.
- Month and Year contain live data in every visible child surface; no `Card N` placeholder text is mounted.

## Balance Month/Year alternative architecture card

### Scope and sources

- User requirement: implement Havi 2 and Éves alternative Balance content surfaces from HTML, with live values and mother-card visibility.
- Accepted reference: `html-prototypes/balance-extended-sheet-baseline/index.html`.
- Existing renderer: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`.
- Existing financial read model: `lib/features/dashboard/application/dashboard_balance_primary_projection.dart` and linked `closings`/`retention` DTOs.

### Single source and write path

- Visual source: HTML CSS values, centralised in `balance_alternative_visual_tokens.dart`.
- Financial source: `DashboardBalanceLinkedPresentation`; it remains immutable and read-only in UI.
- Setting source/write path: `BalancePresentationSettings` / `BalancePresentationController.setAlternativeMotherCardVisible`.
- Errors/retry: none; no I/O is introduced.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Mother-card visibility | `BalancePresentationController` | Dashboard | One typed controller setter increments revision |
| Year chart variant | Existing Year card-local UI owner | Widget lifetime | Does not change financial data |
| Drawn Month/Year values | Immutable alternative scope DTO | One linked presentation publication | Rebuilt only from existing linked DTO values |
| Carousel/summary selection | Existing owners | Unchanged | Alternative renderers never write it |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Scope routing | `BalanceAlternativeScopePresentation` | Extend it from the linked presentation | Month/Year adapter tests use canonical DTO fixtures |
| 5-slot geometry | `BalanceFiveSectionLayout` | Reuse without changing ratios | Existing geometry tests plus Month/Year mounted rect tests |
| Child card visual values | HTML CSS | New single token module | Token test verifies direct CSS-derived logical values |
| Money formatter | `DashboardPreparedFormatter` | Reuse | No feature-local money formatter |
| Settings publication | `BalancePresentationController` | Extend one existing owner | Boundary test asserts one setter and tuner forwarding |

### Layer flow

`BalanceDashboardCoreSurface` → `BalanceAlternativeScopePresentation.fromLinked` → immutable Month/Year render DTO → Flutter renderer. No repository or Query boundary participates.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ALT-M-01 | HTML Havi 2 | Scope adapter + Month body | Live daily spend, no-spend count, savings ratio, income/expense strip | Unit + widget test | DONE |
| ALT-M-02 | HTML Havi 2 CSS | Visual tokens + Month renderer | Padding, card ratios, typography, colors, border/radius use converted CSS tokens | Token/rect/widget test | DONE |
| ALT-Y-01 | HTML Éves | Scope adapter + Year body | Live closing bars/line, small live metrics and yearly income/expense chart | Unit + widget test | DONE |
| ALT-Y-02 | HTML Éves CSS | Visual tokens + Year renderer | No Year `Card N` placeholder mounts; all five slots receive live content | Widget test | DONE |
| ALT-S-01 | User request | Settings/tuner | Mother card is typed, defaults visible, toggles, resets, and leaves data unchanged | Unit/widget/boundary test | DONE |
| ALT-B-01 | Structuring-apps | Boundary suite | UI does not access repository/Query/raw ledger; one setting write path | Boundary test | DONE |
| ALT-R-01 | Existing behavior | Surface host | Sum/Day and carousel/detail behavior remain routed as before | Existing/focused regression tests | DONE |
| ALT-V-01 | HTML source | Goldens/screenshot | Month and Year representative rendered surfaces compare against updated approved goldens | Golden test/manual source comparison | DONE — `balance_alternative_havi2_cards.png` and `balance_alternative_eves_cards.png` captured and inspected; physical acceptance remains user-only |

## Task 1: Record HTML-derived visual system and pure data adapters

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_scope_presentation_test.dart`

- [x] Write failing adapter tests for Month daily expense deltas, zero-expense day count, retention ratio, current/previous month delta, and Year closings payload.
- [x] Run the focused test to prove missing adapter APIs fail.
- [x] Add immutable DTOs and `fromLinked` adapter; only copy values from `cashflow`, `closings`, `retention`, and `momentum`.
- [x] Add token values converted from Havi 2/Éves CSS and test the conversion-derived constants.
- [x] Rerun focused tests green.

## Task 2: Add the typed mother-card setting and its UI bridge

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `test/features/dashboard/presentation/balance_presentation_settings_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `test/boundary/balance_presentation_settings_boundary_test.dart`

- [x] Write failing default/reset/setter/widget/boundary tests.
- [x] Run the focused tests red.
- [x] Add `alternativeMotherCardVisible`, one controller setter, equality/copy/hash participation, and a Unified Balance tuner control.
- [x] Rerun focused tests green.

## Task 3: Implement HTML-derived Month Havi 2 child cards

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/balance_alternative_month_card.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_month_card_test.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [x] Write failing widget/rect tests for the live Month surfaces, daily-line painter data, plain no-spend count, purple retention ring, and live strip.
- [x] Run the focused test red.
- [x] Implement child cards using only the shared tokens and immutable Month DTO.
- [x] Route Month through its own extended-sheet scaffold and preserve source geometry.
- [x] Capture and inspect `balance_alternative_havi2_cards.png`.

## Task 4: Implement HTML-derived Year Éves child cards

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/balance_alternative_year_card.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/balance_alternative_year_card_test.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [x] Write failing widget/rect tests for positive/negative monthly closing bars, cumulative net line, live Year small cards, and live 12-group income/expense chart.
- [x] Run the focused test red.
- [x] Implement Card 3/4/5 and combined bottom card from the Year DTO with source-derived visual tokens; do not mount placeholder text.
- [x] Route Year through the new renderer and rerun green.
- [x] Capture and inspect `balance_alternative_eves_cards.png`.

## Task 5: Wire mother visibility, validate boundaries, commit and deliver

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart`
- Test: `test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart`

- [x] Write a failing widget test that toggles the outer mother surface without changing body geometry or linked presentation identity.
- [x] Run red, implement the settled unified outer-surface gate, then rerun green.
- [x] Run focused test suites, goldens, boundary tests, format, static analysis, and source-reference inspection.
- [ ] Commit/push the canonical HTML prototype first, then production code.
- [ ] Monitor the GitHub human diagnostic APK job for the production SHA and download the normal APK to `/storage/emulated/0/Download/fluvi`.
