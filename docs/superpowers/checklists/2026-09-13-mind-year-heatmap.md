# Mind Year Heatmap acceptance checklist

Source of truth: user feature request and 2026-09-13 approved realtime
contract in `docs/FLUVI_ENGINEERING_JOURNAL.md`.

| ID | Requirement source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MYH-01 | Scope/visibility | Mind surface + mode host | Only Mind with Year plane renders the annual surface; Sum/Month/Day do not. | Production widget test | DONE |
| MYH-02 | Main content | Mind Year surface | Exactly 12 month cards form a 3-column, 4-row grid in one vertical viewport. | Widget structure test | DONE |
| MYH-03 | Calendar correctness | Annual projection | Local calendar has 365/366 valid cells, Feb. 29 only in leap years, and all 12 months exist when empty. | Model tests | DONE |
| MYH-04 | Filter equality | Core-owned annual projection | Direction, selected year, category/partner, search/other non-amount refinements and active amount range match the one canonical filter chain. | Model/controller tests | DONE |
| MYH-05 | Realtime invariant | Annual projection | Projection rebuilds only for upstream non-amount identity/data revision; slider previews read zero source rows and inspect at most annual day buckets. | Work-count test + profile | PARTIAL — Android profile pending |
| MYH-06 | One authority/stale safety | Core controller | Existing Mind preview/canonical authority remains sole range authority; a generation rejects stale scheduled publication. | Lifecycle tests | DONE |
| MYH-07 | Terminal value | Shared range control + heatmap bridge | A pending coalesced callback cannot lose the final finger range; thumb, compact labels, heatmap and canonical range converge. | Race widget test | DONE |
| MYH-08 | Normalization | Annual projection + paint tokens | One global filtered-year min/max spans all months; empty, non-empty minimum and named equal-range intensity differ deterministically. | Model/widget tests | DONE |
| MYH-09 | Live paint | Mind surface | Pointer-held range drag changes tile color before release; rapid reversals publish latest value. | Pointer widget test | DONE |
| MYH-10 | Structural layout | Mind surface | Scrollable cards are in `Expanded`; compact footer is outside viewport, fixed, clipped and interactive. | Layout/scroll test | DONE |
| MYH-11 | Gesture ownership | Mode host + Mind viewport | Child annual scroll wins in its bounds, horizontal slider wins in footer, parent expansion retains its intended non-viewport area. | Production-parent gesture test | DONE |
| MYH-12 | Rebuild containment | Scoped listenables | Amount-only preview invalidates live tiles, not static chrome/header/navigation/transaction list. | Rebuild counter test + profile | PARTIAL — Android profile pending |
| MYH-13 | Narrow layout | Month card/footer | Hungarian `Szeptember` and compact amounts fit supported narrow width without overflow. | Narrow widget test | DONE |
| MYH-14 | Regression scope | Existing dashboard/query paths | Query Menu visual contract and Avatar/Time ownership/physics remain unchanged. | Focused regressions + source inspection | DONE |
| MYH-15 | Delivery evidence | GitHub + SCIP | Application commit/push, online human APK, final matching SCIP, and implementation journal entry exist. | Remote/artifact/provenance checks | NOT DONE |
| MYH-16 | Physical acceptance | Android user test | Device smoothness and visual acceptance are evaluated only by the user. | User test | PENDING — USER ONLY |
| MYH-17 | CI run 34754754958 profile failure | Profile B evidence collector | Every physical Mind slider preview event remains available to B's validation even if the bounded global diagnostic tail later evicts it; the collector must retain the event's zero-work scope. | Existing failed profile as RED evidence; local harness compilation; final dispatched Android profile | PARTIAL — online profile pending |
| MYH-18 | CI run 34759432562 B frame-timing failure | Mind MonthCard dynamic tile field | A range-preview repaints each visible month’s plain day-cell field through one bounded paint primitive, without nested per-day scrollables or per-day semantic/widget trees; static MonthCard chrome remains outside that live field. The existing 12 ms FrameTiming gate remains unchanged. | RED widget structure test; focused widget/analyzer; final Android B profile | PARTIAL — local structural test and analyzer pass; Android profile pending |
