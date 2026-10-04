# Mind + Balance presentation refinement — acceptance checklist

**Scope.** Current `feature/balance-wave-defaults` worktree, starting at
`6a2b605973ead90e216de2071eea071e895ce27b` (the documentation descendant of
the last delivered application commit). This is a presentation-only change:
all Mind range previews and Balance scope totals remain resident projections.

| ID | Requirement / source | Existing owner or target code | Acceptance evidence | Status |
| --- | --- | --- | --- | --- |
| MMD-01 | Mind Month `Összesen` uses the exact first-SUM-year header amount typography and baseline | `mind_sum_year_band_header.dart`, `mind_temporal_heatmap_viewports.dart` | shared `MindSumScopeTotalHeader`; Mind viewport regression test | DONE |
| MNS-01 | Replace Month `30 nap` / active-day metadata with a no-spend-days metric; show the same global metric in SUM and Year, never Day | Mind temporal / year frame + viewport headers | projection and viewport tests | DONE |
| MYA-01 | Add selectable white mother-card monthly-total alternative to Hidden / Inline / gray Veil | `MindYearMonthlyAmountPresentation`, prefs, tuner, `mind_year_heatmap_viewport.dart` | settings persistence and overlay behavior tests | DONE |
| MYA-02 | White mode presents all live filtered month totals, absorbs close taps, and retains no day-cell detail interaction | same | range-preview overlay widget test | DONE |
| BSC-01 | Month and Year’s two right slots become one identical `Megtakarítás` card with percentage ring above amount | `balance_dashboard_core_surface.dart` | scope widget and golden/layout tests | DONE |
| BSC-02 | Savings card uses the existing Budget 3D chrome, a real colored retention arc, and a readable centered percentage | Balance savings projection + Budget avatar chrome | savings-card widget test and inspected goldens | DONE |
| BMR-01 | Balance Month lower card is settings-selectable: income-vs-expense or resident daily-spending rhythm | Balance settings, tuner, alternative scope presentation, shared rhythm primitive | settings and 28–31-bar widget tests | DONE |
| BHG-01 | Balance Header is settings-selectable: existing line or red/green income-vs-expense partition with percentages | Balance settings, tuner, header surface | partition widget/tuner tests and shared geometry source check | DONE |
| BHG-02 | Header partition height is user-adjustable through the existing Balance presentation authority | same | settings/controller and tuner test | DONE |
| ARC-01 | No second financial query, aggregation owner, amount range, or settings controller | all changes | source audit + resident-projection and boundary tests | DONE |
| REG-01 | Mind Day/SUM/Year heatmap and Balance/Budget existing modes remain live and visually intact outside listed presentation choices | focused tests + analyze | 434-test fast suite, Balance surface suite, analyzer | DONE |
| REL-01 | Formatting, focused tests, analyzer, one final remote Human APK build/download for the exact app SHA | repository / GitHub Actions | command and artifact evidence | DONE — `271445da`; Actions `37184131561`; verified Human APK downloaded |

## Architecture decisions recorded before implementation

1. The Mind metric reads only the immutable/resident filtered frames. `no-spend`
   is derived from visible calendar days minus range-approved daily points;
   it never scans transactions in a widget.
2. The white alternative is an annual, all-twelve-month overlay mode, sharing
   the gray veil’s trigger/close contract but replacing the heatmap body with
   a white mother-card surface.
3. Balance daily rhythm consumes the already prepared
   `BalanceAlternativeMonthlySpendPresentation.points`; it does not create a
   second Balance projection.
4. New Balance display choices belong to `BalancePresentationSettings` and
   `BalancePresentationController`. Existing Budget avatar artwork/progress
   chrome is reused for savings rather than implementing a second ring.
5. The new Header partition shares the Budget partition lane’s geometry token;
   it only changes the data source and makes height presentation-configurable.
