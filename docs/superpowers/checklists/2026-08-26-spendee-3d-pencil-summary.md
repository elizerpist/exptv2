# Spendee 3D, LogBox pencil and Summary refinement acceptance checklist

Baseline: `separated-core-modes` at
`dad236afe985b9f7350abdbe0cc69a17decf315e`.

Authoritative visual source: read-only `spendeetest` at
`144d78c30dc4cc5e9f230903fd6274c98e62e118`:
`spendee_balance_visual_spec.dart`, `spendee_balance_post_content.dart`,
`spendee_balance_transaction_log.dart`, and `spendee_balance_b3ma3_manifest.dart`.

| ID | Requirement / source | Owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| SD-01 | Spendee Balance Summary/Search | central depth profile | Fourth `spendee3d` style preserves None/Current/Soft and pins `#FEFEFF`, `#1A666FAB`, `#14524B93 y8 b17`, inner `#F0FFFFFF y1`. | Profile regression test | DONE |
| SD-02 | Global surface requirement | Dashboard depth consumers | Header, controls, Summary, Search, cards, Budget layouts and LogBox consume one central Spendee3D material definition with existing radii. | propagation/clip tests | DONE |
| LP-01 | Balance transaction edit source | LogBox custom painter + prepared raster asset | Decorative trailing pencil is `24x24`, `#1A7D8798`, r8, SVG `13x13`, `#7D8798`; no widget/button/semantics/action. | paint/resource/semantics test | DONE |
| LP-02 | Dynamic LogBox height | painter and geometry manifest | Pencil stays `24x24`, is vertically centred and does not alter rows, hit tests or extents. | height/scroll-owner matrix | DONE |
| SM-01 | shared Summary amount | `SummaryPillPreparedAmountSlot` | Larger, one-line, right-aligned prepared amount applies to Legacy and Segmented without moving tracks or changing source. | widget typography/position test | DONE |
| SM-02 | Balance Summary icon badge | Segmented mode carousel renderer | Every mode has one `25x25`, p5, r9, `#F1EFFF` badge with `#7564F5` semantic glyph. | badge/ballistic test | DONE |
| SM-03 | visual hierarchy | Segmented selector text | Year/month/day selected values use semantic secondary grey; amount remains primary. | widget style test | DONE |
| REG-01 | Milestones | all existing owners | Query/preview, rail, row-height, controllers, body order, SearchPill and geometry remain unchanged. | protected suites and diff audit | DONE — excluding two separately reproduced baseline-only harness failures below. |
| DOC-01 | Task documentation | active customization docs | Documents direct source port and non-interactive placeholder; no permanent-style claim. | doc review | DONE |
| DEL-01 | delivery | GitHub Actions / human APK | Pushed production SHA `6bbd4cee51e9760f9ac548ad0f40bfb05add8e8f` has successful human APK downloaded locally and SHA-256 checked: `fluvi_HUMAN_DIAGNOSTIC_6bbd4ce.apk`, `8056fdaa8e69243edcb8307fa7af75343d56ace3ba939ff1740dcfa0a6b16ad1`. | GitHub Actions run `32971134825`, human diagnostic APK job | DONE |
| PHYS-01 | User physical acceptance section | Android device | Compare the 3D material, Search/Summary, pencil, Summary hierarchy and protected interactions against the reference screen. | Manual device validation | PENDING USER VALIDATION |

## Architecture card

- Single visual-depth owner: extend `DashboardShadowProfile`; consumers retain
  `FluviRoundedBox` and custom painter ownership.
- Single pencil visual owner: a prepared LogBox painter raster; no row widget
  or query/state owner.
- Single amount owner: existing prepared amount slot; typography only.
- No new persistence or business-state write path.

## Baseline-only failures deliberately not changed

- At both the starting `dad236afe985b9f7350abdbe0cc69a17decf315e`
  worktree and this change, `core_dashboard_test.dart`'s *keeps the
  SummaryPill amount…* case creates `DashboardModeSpec.balance` but expects
  `budget-distribution-pager`. It therefore fails before this presentation
  work is involved.
- At both the same baseline and this change,
  `dashboard_scroll_milestone_test.dart`'s first direct-LogBox ballistic case
  throws `Bad state: No element` while looking for
  `VERTICAL_INTERACTION_PERF_SUMMARY`. The companion rail/query milestone and
  the focused viewport/scene suites pass. This task does not alter that
  diagnostic harness.
