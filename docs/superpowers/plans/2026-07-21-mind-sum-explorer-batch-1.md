# Mind SUM Explorer Batch 1 Plan

## Goal

Replace only Mind `SUM` Stage1 and Stage2 with a query-scoped temporal explorer:

1. Stage1 is a Budget-style grow/shrink year rail.
2. Stage2 is the selected year's scrollable 12-month heatmap grid.
3. The Mind header background tap opens a dedicated SUM customizer for rail and heatmap surfaces.

## Design Decisions

- Reuse `SpendeeCenterCarouselController` release physics rather than introducing another snapping model.
- Keep a separate Mind carousel state and animation controller so an interrupted Budget animation cannot alter the selected year.
- Build a selected-year `StatsRenderFrame` through the existing Mind adapter with `StatsSummaryScope.yearly`; this preserves the active type, search, category selection, vendor filters, and current date semantics.
- Derive year-card monthly volume bars from that selected-year frame. Empty months are omitted, so the card contains at most twelve bars.
- Use the existing stats calendar's category heat-color rule for the selected-year monthly cards.
- Do not mutate the Summary Pill or store query when a user changes the year rail. The rail is a child navigator within the all-time parent scope.

## Work Sequence

1. Add adapter tests for query-scoped selected-year frames and real monthly bar inputs.
2. Add dashboard state/configuration for the Mind SUM rail, selected year, stage2 surfaces, opacity, and modal customizer.
3. Implement the separate Mind carousel gesture and release lifecycle using the established Budget controller behavior.
4. Replace only Mind SUM Stage1 with the year-card rail, preserving YEAR/MONTH Stage1.
5. Replace only Mind SUM Stage2 with an outer optional surface and 3-column scrollable month heatmap cards.
6. Add widget tests for SUM-only rendering, selector controls, and month day labels/scrolling.
7. Run targeted tests, full relevant tests, formatter, and `flutter analyze` through Ubuntu proot.
8. Re-read the checklist, mark verifiable items honestly, then commit and push only the scoped files.

## Verification Commands

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_mind_stats_adapter_test.dart test/spendeetest/spendee_dashboard_interaction_test.dart'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter analyze lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart lib/features/transactions/widgets/experimental/spendee_mind_stats_adapter.dart'
```
