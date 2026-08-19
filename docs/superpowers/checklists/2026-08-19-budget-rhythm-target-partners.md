# Budget rhythm, target-aware partners, and core-layout acceptance checklist

## Architecture card

- **Sources:** user request 2026-08-19; `MILESTONE_COMMITS.md`; current
  Budget Card2 production implementation.
- **Single sources:** layout positions remain `DashboardLayoutMetrics` plus
  `DashboardGeometryResolver`; selected Budget target remains
  `DashboardBudgetPresentationController`; navigation remains the owner of
  rhythm granularity while `FluviClock` owns its real-world rolling endpoint;
  exact data stays in prepared native snapshots and their versioned codecs.
- **Read flow:** prepared snapshot → immutable RAM projector/controller →
  Card2 renderer.  UI only renders frames and forwards existing intents.
- **Reuse:** extend the existing Budget limit native grouped-day scan, existing
  partner grouped-day scan, exact Card2 drawable owner, common page surface,
  shared clay-donut generator, current category colour catalog and current
  aggregate visual.  No new carousel, pager, time, selection, SVG, database
  or renderer owner is introduced.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BRP-01 | User §A/B | central layout metrics/resolver | Open-rail handle gap is dedicated; count lane is smaller; reclaim equals 9 px and becomes central Zone2/body height. | RED→GREEN resolver and core-mode tests. | DONE |
| BRP-02 | User §A/B | central geometry | Open-rail actual LogBox content top is unchanged; Balance/Budget/Mind inherit exactly the same Zone2 delta. | Resolver equations/tests. | DONE |
| BRP-03 | User §C/8.2 | prepared Budget limit snapshot | Exact revision rhythm preserves sparse target-handle day points from the existing bounded grouped native acquisition and codec. | Dart codec plus GitHub `test-core` Room/core and bridge test jobs green. | DONE |
| BRP-04 | User §C/8.3–8.5 | rhythm controller/widget | RAM-only selected target/anchor projection makes 7/6/5 end-inclusive bars, correct zero/max normalization and authoritative target gradient. | Focused projection/widget tests green. | DONE |
| BRP-05 | User §C/8.6 | shared Card2 layout/category page | Donut is smaller, rhythm sits beneath it, right list dimensions/density are retained. | Category Card2 widget test green. | DONE |
| BRP-06 | User §C/8.7–8.9 | prepared partner snapshot/projector/visual bank | Category contribution data is compact/exact; aggregate remains unchanged; category target gets filtered positive partner entries and denominator; colour policy is retained. | Dart codec/projector/visual tests plus GitHub `test-core` Room/core and bridge test jobs green. | DONE |
| BRP-07 | User §C/8.8 | Card2 drawable owner | Aggregate and category-target partner SVG frames pre-generate/prewarm with the existing shared source before publish; avatar/page tick is lookup-only. | Visual-bank generation-count test green. | DONE |
| BRP-08 | User §9/10 | presentation boundaries | Partner stays read-only; existing category commands, pager and protected rail/logbox ownership remain intact. | Card/pager and CoreDashboard regression tests green. | DONE |
| BRP-09 | User §13/15 | delivery | Focused tests/analyze/codec checks, focused commits, push, successful normal APK job, downloaded APK hash. | `Fluvi Verification` 32256531614 SUCCESS; human APK SHA-256 verified locally and against release metadata. | DONE |

## Local-clock rhythm and pill-render follow-up

The prepared exact-revision rhythm snapshot remains the data authority. This
follow-up changes only its rolling-window clock authority and the local Flutter
bar constraints; it must not add a repository, bridge, SQL, SVG or pager path.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BRC-01 | User root cause A | `core/time`, rhythm controller/projector | The endpoint is the injected local clock calendar date, never the Dashboard temporal anchor; month/year/sum produce 7/6/5 current rolling buckets. | RED→GREEN projector/controller tests with 2026-08-19 and a conflicting July navigation anchor. | DONE |
| BRC-02 | User §8.3–8.4 | rhythm controller/projector | Local Y/M/D maps deliberately to the prepared epoch-day identity and one cancellable next-midnight refresh keeps an open app current. | Local-calendar and deterministic rollover tests. | DONE |
| BRC-03 | User root causes B/C | `budget_rhythm_bar_chart.dart` | Every positive fill has the same explicit 11 px width as its centered neutral track; zero keeps only the neutral pill. | RED→GREEN widget geometry/decoration tests. | DONE |
| BRC-04 | User §8.8/§12 | existing rhythm colour/diagnostics owners | Category and aggregate gradients remain authoritative; diagnostics report clock window, non-zero count and maximum. | Controller unit test plus source inspection. | DONE |
| BRC-05 | User §13–15 | focused suites/delivery | Protected Card2, prepared snapshot/codec and pager tests remain green; normal human APK for the pushed SHA is downloaded. | Proot Flutter tests/analyze plus Actions artifact hash. | PARTIAL — local focused verification is green; push/build/download pending. |
