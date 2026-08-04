# Plan: SummaryPill parent-navigation performance

## Sequence

1. Freeze the baseline with backup tag and branch; record the current commit,
   existing child-preview invariants and available diagnostics.
2. Audit parent motion, parent summary lookup, presentation publish, query
   commit, bootstrap and rebuild boundaries. Write the root-cause report before
   production edits.
3. Add failing month/year parent-preview, no-I/O, parent/child cursor, settle
   no-op, rebuild-isolation and bootstrap tests.
4. Add or extend a typed parent presentation index behind
   `DashboardPresentationStore`; keep committed query ownership in
   `CurrentQueryController`.
5. Route SummaryPill tap/fling through the same parent preview API and parent
   motion epoch. Keep the existing carousel/physics owner unchanged.
6. Add parent preview direct/no-op amount/count behavior and narrow selectors;
   prevent Header/root/rail rebuilds.
7. Apply parent/child target normalization and stale-result guards.
8. Make lease cancellation and adjacent prewarm cover parent motion without
   adding preview I/O or parse work.
9. Verify/bootstrap-gate the first valid parent frame and preserve existing
   cold-start behavior.
10. Add compact parent diagnostics and update LogBox/content phase counters.
11. Run targeted tests, then the full golden-free suite and static analysis.
12. Run deterministic stress tests and available profile measurements. Update
   the checklist honestly.
13. Only after all source checks are green: one final commit, push, online CI
   build, APK download and integrity verification.

## Guardrails

- No physics tuning.
- No duplicate motion engine.
- No QueryKey root keys.
- No eager transaction-list projection or child-deck parsing in parent motion.
- No commit-per-step; preserve one final delivery commit as requested.
