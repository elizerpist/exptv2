# Implementation plan: Alternative Balance phase 2

1. Add failing pure tests for a sealed scope adapter and five-slot geometry.
2. Add pure `BalanceFiveSectionLayout` and the immutable scope-specific
   alternative presentation adapter over existing `cashflow.periodPairs`.
3. Add failing widget tests for SUM/YEAR Card 3, YEAR's fixed twelve groups,
   SUM plot-only overflow, and untouched Month/Day four-slot routing.
4. Implement the one reusable Card 3 bar renderer with stable SUM scrolling
   and the reference-owned tokens measured from `barchart.png`.
5. Route the settled alternative body by canonical `LedgerTimeScope`, rendering
   five slots only for SUM/YEAR and preserving the existing four-slot scaffold
   for MONTH/DAY.
6. Add/refresh focused goldens, run all scoped tests, format, analyze, inspect
   the reference again, update the checklist, commit/push, monitor the exact
   human APK workflow, download and hash the APK.
