# Balance SUM adaptive distribution specification

## Approved source of truth

- Canonical prototype: `html-prototypes/balance-extended-sheet-baseline/index.html` (SUM third row).
- Visual evidence: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-213600.png` (histogram) and `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-202948.png` (cashflow band).
- The prototype is mandatory: the SUM child-card hierarchy, spacing, typography, chart geometry and original Soft rainbow appearance must be reproduced from live app data. The only approved variance is that Flutter child cards retain their established neutral border, rather than the prototype's temporary purple outline.
- The established `DashboardHeaderContentMotherCardBounds` and `BalanceExtendedSheetLayout` geometry are immutable for this change. No SUM Mother Card size or placement may change.

## Architecture card

| Concern | Single owner / flow | Explicitly excluded |
| --- | --- | --- |
| Closed-month membership and robust median/MAD | `DashboardBalanceStabilityProjection` -> `DashboardBalanceStabilityPresentation` | Widgets, adapters, current/open month |
| Adaptive binning and longest positive run | new pure `DashboardBalanceMonthlyNetDistributionProjection`, consuming immutable stability observations | Widgets, ledger queries, fixed-HUF steps |
| Scope mapping | `BalanceAlternativeScopePresentation.fromLinked` maps immutable linked data to immutable SUM presentation | repositories and secondary queries |
| SUM rendering | dedicated `balance_alternative_sum_cards.dart` widgets/custom painters receive immutable presentation only | financial calculation and mutable state |
| Soft-rainbow colors | existing `DashboardBalanceHeaderPaletteCatalog` original Soft rainbow anchors, exposed through alternative visual tokens | copied local palette lists |
| Layout and card chrome | existing `BalanceExtendedSheetLayout`, `_BalanceExtendedSheetFrame`, `BalanceAlternativeHtmlCardSurface` | a SUM-specific mother-height policy or purple child border |

The data path is ledger entries -> linked dashboard projection -> stability projection -> distribution projection -> immutable SUM scope presentation -> render-only Flutter cards. There is one calculation owner for every monthly net and every adaptive bin; the new widgets only turn values into pixels.

## Adaptive histogram contract

1. Each complete calendar month supplied by `DashboardBalanceStabilityPresentation.observations` appears exactly once. The stability projection already excludes the open month.
2. Each bar is a dynamically computed net-value interval, with height equal to its month count.
3. The interval width never comes from a fixed HUF increment.
4. Start with Freedman–Diaconis `2 * IQR / cubeRoot(N)`.
5. Identical values yield one bin; concentrated data is not inflated merely because N is large.
6. If IQR is zero for non-identical values, use MAD; if MAD is zero, derive from that sample's min/max span.
7. Keep regular rendered bins in the approximately 5–11 range when distribution supports it; fewer are valid for concentrated data.
8. Use Tukey/IQR (or MAD fallback) fences for a robust core. Values outside it are separate underflow/overflow bins; all samples remain represented.
9. Regular bins have equal derived widths. Rounding may use a scale-derived nice step only.
10. Zero is an explicit reference and becomes a regular-bin boundary whenever the rendered core crosses zero. It is an external reference if data lies entirely to one side.
11. Bin hue is derived from its financial interval: negative coral/rose, near zero purple, positive blue/turquoise/green via existing original Soft rainbow anchors.
12. Median is a reference marker, not a bin.
13. Median +/- MAD-derived typical range is an overlay, not input to binning.
14. Presentation exposes sample count, median and typical bounds for accessible text and chart callouts.

## SUM visual contract

- Card 3: title/subtitle, adaptive histogram, faint typical-range overlay, zero reference, median vertical marker plus purple median callout, and the two-line purple insight card from the prototype.
- Card 4: `Leghosszabb pozitív széria`, longest strictly-positive consecutive closed-month count, one explicit `hónap` unit, and prototype-style Soft-rainbow mini trend node visual built from that winning sequence.
- Card 5: reuse the existing monthly savings ring and actual retention value.
- Lower combined card: `Cashflow stabilitás`, close-month count chip, red-to-purple-to-green horizontal band, lower/zero/median/upper rules, each monthly net as a dot, and the exact two explanatory legend rows from the prototype. It must use the existing stability presentation, not duplicate its median/MAD logic.
- Empty/insufficient live data states stay informative and preserve the same child geometry; they do not render invented values.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUM-01 | Prototype SUM Card 3 + histogram rules 1–10 | new application distribution projection | Every closed observation assigned once; FD/MAD/core/outlier/zero behaviors follow this spec | focused unit tests | DONE |
| SUM-02 | Histogram rules 11–14 + screenshot 213600 | visual tokens + SUM histogram painter | Original Soft rainbow, typical range, zero, median callout and accessible summary render from live data | unit/widget/golden inspection | DONE |
| SUM-03 | Prototype SUM Card 4 | distribution projection + streak painter | Longest strictly positive chronological run and its mini visual use real observations | unit/widget tests | DONE |
| SUM-04 | Prototype SUM Card 5 | scope adapter + existing ring | Existing savings ring receives actual all-time retention data | adapter/widget test | DONE |
| SUM-05 | Screenshot 202948 + prototype lower card | SUM stability band painter | Existing median/MAD data drives band/rules/dots/legends, without stability label heuristics | unit/widget/golden inspection | DONE |
| SUM-06 | Explicit exception | SUM child shells | Neutral standard child borders; no extra purple child-card outline | widget/source inspection | DONE |
| SUM-07 | Explicit mother-card constraint | scope scaffold/layout | Existing Mother Card bounds and extended-sheet child allocation remain unchanged | geometry/boundary test | DONE |
| SUM-08 | Architecture gate | app/domain/presentation boundaries | One immutable data path; no Flutter in math, no ledger query/math in widgets, no copied palette | boundary tests | DONE |
| SUM-09 | Delivery request | Git/GitHub Actions | Commit, push, successful human APK job, download to `/storage/emulated/0/Download/fluvi`, SHA-256 | git/GitHub/file hash | PARTIAL — awaits commit/push and the online human APK |
