# LogBox Search Scaffold Design (Ledger Amount Withdrawn)

> Historical update, 2026-08-24: the standalone background-only Ledger result
> amount described by the original experiment was deliberately withdrawn in
> the following SummaryPill ballistic-controls iteration. It is not accepted
> current architecture. SearchPill and the Ledger transaction count remain;
> SummaryPill is again the only visible transaction/query amount owner.

## Goal

Extend the collapsed dashboard Ledger chrome directly below the existing
collapse handle with the existing transaction count and a separate
non-editable SearchPill. The temporary background-only result amount was
removed because it consumed too much Ledger space; the existing SummaryPill
and its amount remain unchanged.

The user explicitly authorized direct implementation after investigation; this
document records that accepted implementation design rather than imposing an
additional approval wait.

## Sources and accepted reference

- User task and its authoritative textual layout specification.
- [Screenshot_20260824-091339.png](/storage/emulated/0/Pictures/Screenshots/Screenshot_20260824-091339.png): current physical Fluvi style baseline.
- `MILESTONE_COMMITS.md`: protected one-owner vertical scroll, immutable
  committed geometry, readiness, Query, and ballistic contracts.
- Current branch start: `separated-core-modes` at
  `a38c17e8d4bf850b9006b191198d11c9cea2c610`.

## Ledger result architecture card

### Scope and owners

- Dashboard shell and header/collapse geometry:
  `CoreDashboard` + `DashboardLayoutMetrics` + `DashboardGeometryResolver`.
- Stable Ledger chrome and its one `CustomScrollView` owner:
  `DashboardLogBoxViewport` + `DashboardLogBoxHeader`.
- Authoritative Ledger count/list state: `DashboardVisibleFrameStore`,
  publishing one immutable `DashboardVisibleFrame` whose count and LogBox
  share query key and revision. Its already-prepared amount remains owned by
  the SummaryPill presentation.
- Query/data write path:
  controller/runtime/prepared-frame pipeline. No UI write path is added.
- Formatting owner:
  existing prepared `DashboardAmountViewModel.formattedAmount` and
  `DashboardCountViewModel.formattedEntryCount`; no viewport-row aggregation
  or formatter is added.

### State ownership

| State | Owner | Publication rule |
| --- | --- | --- |
| Ledger count/list identity | `DashboardVisibleFrameStore` | One already-validated prepared frame is staged to all visible lanes before listeners receive it. |
| Search presentation | `DashboardLogBoxHeader` | Stateless, disabled visual scaffold; it owns no query/filter state. |
| Vertical scroll/controller/physics | `DashboardLogBoxViewport` | Existing stable state object remains sole owner. |
| Query filters | Current Query controller/runtime | Untouched; existing facets remain below SearchPill when active. |

### Chosen implementation

1. Make the fixed Ledger chrome height an explicit shared dashboard metric so
   its frame bounds and responsive scaling remain authoritative. Preserve the
   historical reclaimed-core-space calculation with a separate legacy count
   header constant.
2. Extend `DashboardLogBoxHeader` in the existing viewport chrome, in order:
   count → SearchPill → active facet chips (when present).
   The parent viewport's existing `Column` places the stable scroll surface,
   including its date headings and LogBoxes, below that chrome.
3. Bind the count from `DashboardVisibleFrameStore` so it comes from the
   exact same prepared result as the currently committed LogBox payload. The
   header has no row traversal, query engine, text layout, cache, controller,
   or asynchronous work.
4. Reuse `FluviRoundedBox`, `FluviVisualTokens`, `DashboardLogBoxTokens`, and
   central `standardGap`. SearchPill alone owns the white rounded surface and
   existing elevation language.
5. The existing Query Menu `_SearchPill` is not reused: it edits an unrelated
   query-menu draft note. The Ledger SearchPill is a disabled semantic scaffold
   until a later task can introduce an approved transaction-search path.

### Layer flow

Prepared result → `DashboardVisibleFrame` → `DashboardVisibleFrameStore` →
`DashboardLogBoxHeader` count leaf and stable LogBox viewport. The amount
lane is rendered only by SummaryPill.

## Geometry and interaction invariants

- The existing collapse handle stays the Ledger-area predecessor; the Ledger
  header's positioned top remains resolver-owned.
- The top chrome expands only inside `DashboardLogBoxViewport`; it reduces the
  existing single scroll viewport instead of adding a scrollable, overlay, or
  controller.
- Header expansion/collapse moves the entire positioned LogBox viewport,
  including new chrome, as one existing geometry-bound unit.
- Active facet chips retain their current behavior and remain between the
  SearchPill and the first date group when present.
- The SummaryPill is not changed by this Ledger rollback and remains the sole
  visible transaction/query amount.

## Verification strategy

- TDD widget contracts for count/SearchPill order, independent SearchPill,
  semantics, and atomic frame-state replacement.
- Core dashboard widget contract for SummaryPill amount presence and
  collapsed/expanded Ledger movement.
- Existing protected LogBox viewport, stable-render, Query, vertical-scroll,
  controller/physics, and boundary suites.
- Targeted Ledger golden/screenshot evidence plus direct inspection.
- Flutter analyzer and the repository's curated Flutter correctness suite.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LRS-01 | Original temporary layout | Ledger header/viewport | Handler → result → count → SearchPill → date/LogBoxes | Historical feature test | WITHDRAWN — replaced by handler → count → SearchPill → date/LogBoxes. |
| LRS-02 | Original temporary result visual | Ledger header | Result is centered background text, with no surface | Historical source inspection | WITHDRAWN — Ledger has no standalone amount surface or text. |
| LRS-03 | SearchPill | Ledger header | Separate white rounded SearchPill with icon and copy | Widget/golden/semantics test | DONE |
| LRS-04 | Authoritative state | Visible frame store/header | Count uses same query/revision as LogBox; SummaryPill retains the prepared amount | Widget/store tests | DONE |
| LRS-05 | Amount ownership | Core dashboard | Existing SummaryPill amount stays intact; Ledger duplicate is absent | Core widget test | DONE |
| LRS-06 | Expansion | Resolver/viewport | New chrome moves with Ledger, no overlay or new scroll owner | Core widget test | DONE |
| LRS-07 | Protected interaction | Viewport | Stable controller/physics/readiness and Query behavior remain | Protected suites | DONE |
| LRS-08 | Accessibility | Ledger header | Count readable; scaffold is disabled, non-editable semantics | Widget semantics test | DONE |
| LRS-09 | Delivery | Tests/CI | Focused checks, analyzer, commit, and required APK delivery | Commands/Actions | DONE — `f01a51ba` human diagnostic build/download SHA-256 verified. |
