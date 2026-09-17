# Mind temporal heatmaps, fixed footer, and score-atomicity implementation plan

**Goal:** Extend the resident Mind heatmap projection from Year to Sum and
Month without introducing another filter/query authority; make the compact
palette/range footer physically stable for every TimePlane; prove and repair
the Header-score publication gap only at its first failing Core boundary.

**Approved design:** The user's 2026-09-17 product prompt is the design
authority. B3M-MYS/MYM define composition only. No new visual alternative,
financial formula, prototype fixture value or Day heatmap is introduced.

## Phases

1. **Forensics first:** add a mounted no-settle Year frame RED recording the
   Summary-painted target, heatmap identity and score identity; separately
   test held range preview. Add bounded diagnostics only if the existing
   identities/counters cannot identify the first boundary.
2. **One temporal coordinator:** generalize the Core-owned resident heatmap
   admission/publication transaction to a typed Sum/Year/Month payload and
   publish behavioral score from that same accepted target transaction if the
   RED proves the current asymmetry. Preserve existing range preview semantics.
3. **Stable layout lanes:** put the legend and one compactMind range footer
   outside the temporal-content switch. Extract five resolver-owned legend
   samples; extend every Year card/4×3 solver to a six-row display envelope.
   The approved alternative for the constrained 4×3 presentation is a
   structural 50px Mind-body extension, not a hidden inner scroll or a
   smaller-cell workaround. Apply that envelope only while Mind + Year + 4×3
   is actually selected: an initial all-Mind extension demonstrably starved
   the normal Year LogBox admission lane. The mode geometry resolver remains
   the sole physical owner, and ordinary 2×6/3×4/Sum/Month/Day geometry stays
   unchanged.
4. **Month projection/presentation:** build a compact immutable selected-month
   daily frame with six display rows, real local calendar slots, active-day
   count and filtered total. Use the shared palette/legend/footer.
5. **Sum projection/presentation:** build compact all-time year/month buckets
   from the admitted prepared membership, prove no prepared-window truncation,
   render B3M-MYS composition and keep a single scroll owner.
6. **Validation/delivery:** run no-settle temporal/range/focus/latest-wins
   matrix, performance counters, protected suites/analyzer/diff. Open the
   build gate only after every checklist row is genuinely `DONE`, then commit,
   push, obtain exact human APK, regenerate exact-source SCIP and separately
   journal factual evidence.

## File/ownership map

- `dashboard_core_controller.dart`: only semantic coordinator, prepared-base
  admission, liveness identity and score target publication owner.
- `mind_*heatmap*_projection.dart`: immutable bucket/projection math only;
  no Flutter/repository dependency.
- `mind_year_heatmap_palette_resolver.dart`: renamed only if necessary, still
  the one palette + legend sample authority.
- `mind_year_heatmap_viewport.dart` and new temporal viewport widgets:
  immutable frame presentation only; no Query or finance calculations.
- `mind_dashboard_core_surface.dart`: stable `Expanded + legend + range`
  topology; intent forwarding only.
- `core_dashboard.dart` + `dashboard_motion_host.dart` +
  `dashboard_geometry_resolver.dart`: mode-scoped physical envelope resolver;
  the selected four-column layout contributes 50px only at the committed Mind
  Year target, never through Query state or a widget-local layout override.
- `mind_year_heatmap_presentation_settings.dart`: one palette preference and
  presentation options only; never financial/filter state.
- Existing Core, projection, viewport, surface, score/Header and Query tests:
  RED before production implementation and production-parent frame contracts.

## Non-negotiable protections

Keep Query ownership and canonical amount commit timing, 1/2/5 snapping,
Time/Avatar physics/controllers, LogBox paging/renderer, Budget state,
Fastfood fixture, approved score math, Header chart geometry/fade/line/endpoint
and the single Header ticker. No debounce, cooldown, remount, key churn,
rendered-row aggregation, repository/Room/index work on pointer/paint/ticker
paths, or unbounded preview-value cache.
