# Balance asynchronous wave and Header defaults design

## Architecture card

**State owner:** `BalancePresentationController` remains the only writer for
Balance carousel appearance and Header chart-label preferences. The existing
`DashboardHeaderVisualController` remains the only owner for the Balance
Header veil preference.

**Shared mechanism:** a new pure `BalanceCarouselWaveMotion` core resolves an
authored, identity-stable profile and normalized cubic geometry from one
carousel clock value. `_BalanceUpperCarouselState` remains the sole ticker
owner. Cards are render adapters only: they supply their immutable card ID and
accent color to the shared core.

**Paint boundary:** the outer `DecoratedBox` owns the exterior shadow. Its
child `ClipRRect` owns the shared rounded interior clip. The inner stack paints
neutral surface, optional tint, wave, card copy/tile, then outline. A
`RepaintBoundary` and `CustomPainter(repaint: clock)` limit animation work to
the decorative layer rather than rebuilding card layout, text, icons, data or
carousel geometry per frame.

## Proven starting conditions

- Current branch/HEAD: `feature/balance-wave-defaults` /
  `51ae47e54206605c7d31a788f057779fcbaa9baf`; clean tree.
- One 6-second `_wavePhaseController.repeat()` is carousel-owned. The three
  visible cards currently consume the same phase and the same path metrics.
- The old horizontal drift is `sin(phase * 2π * .7)`: phase 0 and phase 1 do
  not have the same position, so `repeat()` causes a proven 1→0 reset seam.
- Frame-performance jank is unproven: no frame trace exists. Source inspection
  does prove per-tick `AnimatedBuilder`/painter/`Path` allocation, but no
  data/query work and no per-card controller.

## Design decisions

1. Use one periodic clock. Every motion term uses an integral-cycle sine/cosine
   expression, so position and derivative at phase 0 and 1 are equal.
2. Derive a stable FNV-style hash from `card.id`, select one of three authored
   broad profile families, and apply bounded identity-derived shape/cadence
   variations. No runtime random state, index, selection state or build state
   contributes to geometry.
3. Retain the approved base profile as one family; alter only subtle control
   points/amplitude distribution for the other families. All profiles remain
   lower-card, soft, broad and clipped by the current card radius.
4. Add `balanceCarouselBackgroundOpacity` to the existing immutable settings
   owner. The existing tint toggle gates its stored alpha; wave/border and
   geometry remain independent.
5. Seed Balance time labels as hidden and the Balance-specific Header veil as
   enabled/white. Existing setters remain unchanged.

## Non-goals

No carousel physics, dimensions, focus scaling, selection, financial/ranking
data, lower-card layout, BottomNav, Mind or Budget behavior changes.
