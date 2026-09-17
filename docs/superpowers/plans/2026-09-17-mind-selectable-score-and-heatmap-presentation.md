# Implementation plan: selectable Mind score and heatmap presentation

**Execution mode:** inline. The score domain, live publication identity,
prepared aggregate admission, tuner controls, and MonthCard rendering share
the same Core/viewport boundaries; parallel edits would create avoidable
conflicts. The user explicitly requested direct implementation without another
approval request.

**Acceptance checklist:**
`docs/superpowers/checklists/2026-09-17-mind-selectable-score-and-heatmap-presentation.md`.
That document is the build gate. No production build, CI dispatch, or
build-triggering push occurs before every functional row is verified `DONE`.

## Current source map

- Score input/algorithms: `lib/features/dashboard/mind/domain/mind_behavioral_score_projection.dart`.
  Current `_expensePoint` evaluates each target independently from its local
  31-day window; this is the rejected Fastfood terminal-zero mechanism.
- Score frame/stale publication: `mind_behavioral_score_live_projection.dart`.
- Resident prepared membership and range domain: `dashboard_focus_membership_seed.dart`,
  `mind_year_heatmap_projection.dart`, and `dashboard_core_controller.dart`.
- Year presentation: `mind_year_heatmap_viewport.dart` plus
  `mind_dashboard_core_surface.dart` / `dashboard_core_mode_host.dart`.
- Existing Header tuner: `dashboard_header_visual_tuner.dart`, composed by
  `core_dashboard.dart`; Header visual tuning remains visual-only.

## Design decisions

1. Add immutable Mind score settings and a small notifier/controller outside
   Header visual tuning. Its state has algorithm, causal origin, and monotonically
   increasing revision. The Core listens and republish/rebuilds only the score
   projection from already-resident prepared input. Score identity contains this
   revision/settings semantics so stale frames cannot cross modes.
2. Replace only Expense calculation with one forward/scope-series evaluator.
   Income retains its existing branch unchanged. The projection builds daily
   amount lookup data once; every range operation reads day-local sorted prefix
   sums. The three algorithms share daily aggregation and output point model.
3. HTML modes evaluate the requested analytic scope as one series, including
   the scope-wide sparse/dense decision, one EMA, and whole-series maxima.
   The centered mode uses ±15 days; trailing uses 30 days before the current
   day. These variants deliberately retain documented future dependency where
   their original whole-series definition requires it.
4. Causal mode builds forward from the selected origin. Sparse applies through
   active day 12, dense permanently begins at 13, dynamic EMA uses only state
   known at each day, and normalisation uses running maxima. Full-history warmup
   starts at earliest matching non-time-filter data; scope-start follows the
   specified Day/Month/Year/Sum origins.
5. Add immutable heatmap presentation settings separately: Fluvi/B3M palette,
   3×4/2×6 layout, net footer, direction total footer. The viewport reads this
   presentation state; it never changes Query or the heatmap data frame.
6. Attach full-month income and expense totals to a compact, revision/year-safe
   prepared read model at base admission. It is independent of focused/range
   heatmap membership and is published with the selected year frame; widgets
   read only the immutable 12-element aggregate.
7. Extract B3M colors into a pure palette resolver. Non-empty real intensity
   quantizes with `round(clamp(intensity, 0, 1) * 4)`. Empty remains the current
   neutral treatment. The static HTML `annualHeatLevels` array is never used.
8. Generalize the existing one `ListView` to a parameterized column count.
   Preserve the ScrollController identity and calendar geometry; calculate each
   annual row’s height from its months plus enabled footer rows.

## TDD execution sequence

1. Add failing pure settings/domain tests for enum defaults, identity provenance,
   and palette/layout setting isolation.
2. Add failing numerical test fixture for the exact 100-row 2027 Fastfood
   semantic set, plus a test-only literal port of the HTML `categorySeries()`.
3. Implement shared daily-series machinery, then HTML centered until the exact
   reference comparison passes. Add trailing tests/implementation, then causal
   tests/implementation and both history origins. Retain/re-run Income tests.
4. Bind settings to Core/live projection and write failing then passing tests
   for immediate score/chart/palette coherence and slider latest-wins.
5. Add failing heatmap palette resolver tests, implement B3M, retain exact
   Fluvi resolver output.
6. Add failing geometry and presentation-setting tests, generalize viewport for
   two/three columns, then implement compact prepared monthly aggregates and
   footer rows under tests.
7. Wire the two controller-backed Mind sections into the existing Header tuner;
   validate disabled causal-origin state and all controls without a new panel.
8. Run cross-combination, production-parent, protected, analyzer, diff, and
   performance suites. Update the checklist per exact evidence. Only then print
   the required all-DONE build-gate table and begin commit/push/online delivery.

## No-touch boundaries

- Time/Avatar ScrollControllers, ScrollPositions, and physics.
- Query ownership and existing visible-scope range maximum / 1-2-5 snapping.
- LogBox scene/render ownership.
- Existing 2027 Fastfood seed and eight-anchor Mind Header score scale.
- Existing accepted Header chart geometry/reveal/ticker/painter design.
- Budget state/palette and the single shared Header visual controller.
