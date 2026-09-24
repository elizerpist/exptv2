# Spendee ranked overview, Latest presentation, and Header mode icon plan

## Scope and ownership

This integrated delivery has three presentation-only units that share existing
owners rather than creating new ones.

1. `balance_linked_detail_card.dart` owns the bounded Top Category / Top
   Partner master renderer.  It will retain `_RankedDetailState` as the local
   selection/back authority while replacing only its unselected scrollable
   master list with one shared fixed five-rank overview.
2. `BalancePresentationSettings` is the existing session-only Balance
   presentation owner.  It will own the selected Latest card presentation;
   `_BalanceUpperCarousel` retains its one existing controller and merely
   renders the setting.
3. `DashboardCoreModeHost` remains the sole mode transition owner.  A local
   asset-backed Header action sends its existing forward switch command; Header
   vertical expansion remains intact and its horizontal switch command is
   removed.
4. `DashboardHeaderVisualTuning` is already the one dashboard-lifetime owner
   for mode-local foreground channels. It will gain independent icon foreground
   for all three modes and independently enabled/colorized chart-underlay veils
   for the two chart modes. `DashboardHeaderVisualFrame` remains the single
   immutable rendering transport; the shared trend painter stays geometry-only.

## Reference inputs

- Spendee ranked and FastInfo source:
  `spendeetest@144d78c30dc4cc5e9f230903fd6274c98e62e118`,
  `lib/features/transactions/widgets/experimental/balance/spendee_balance_cards.dart`.
- FastInfo manifest and dashboard context:
  `spendee_balance_b3ma3_manifest.dart`, `spendee_balance_dashboard.dart` in
  that same read-only worktree.
- User-supplied Header SVG source is bundled locally under
  `assets/fluvi/header_mode_icons/`; no remote asset URL is retained.

## Implementation order

1. Add acceptance tests for the fixed ranked overview, the two Latest
   presentations/settings, and Header action/gesture behaviour.  Run them to
   capture RED evidence.
2. Implement the read-only/render-only Latest setting and the reference-named
   local visual token.  Thread it through the existing upper carousel without
   recreating its controller.
3. Replace only the unselected ranked master body with a bounded shared leader
   plus follower renderer; preserve local detail state, ranking input order and
   stale-selection clearing.
4. Add bundled SVG assets and a small Header action primitive.  Route action
   intent through the host's existing `DashboardCoreModeController`; keep only
   vertical Header expansion input.
5. Add RED tests for the icon and chart-veil channels, then extend the existing
   mode-visual state, frame transport, tuner controls and chart adapters. The
   existing `DashboardHeaderForegroundColor` catalog is the one reused colour
   authority; no new palette or controller is introduced.
6. Run focused and protected tests, inspect rendered bounds/semantics, then
   format/analyze/diff-check.  Commit atomically, push, verify an exact-source
   online APK and regenerate SCIP in its separate tooling commit.

## Explicit exclusions

- No repository, Query, projection, financial math, Summary, theme, or
  carousel-physics work.
- No Spendee dimension selector or its state.
- No category/partner secondary detail redesign.
- No change to the fixed Balance rail geometry, shared `CenteredCarousel`, or
  Header material/palette/foreground algorithms.
- No external runtime asset dependency.
