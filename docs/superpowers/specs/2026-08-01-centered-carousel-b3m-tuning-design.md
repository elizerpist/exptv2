# Centered Carousel B3M Tuning Design

## Scope and approved sources

This is a targeted refinement of the existing shared `CenteredCarousel`.
The generated year source, virtual belt/rebase, friction projection, snap,
haptic tick, single highlight, five-item alignment, and dashboard geometry
remain in place.

The visual source is the Balance B3M HTML:

`/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/balance_latest_layout.html`

Relevant source selectors are `.stage2-redesign-time-scope-year-rail` and
`.stage2-redesign-time-scope-year-pill` around lines 4684–4754. Their source
values are: 37px tile height, 8px rail gap, `calc((100% - 32px) / 5)` tile
width, 4px horizontal padding, 0px vertical padding, 1px border, 14px base
radius, and 11px inactive / 15px active text. The active HTML radius is 16px,
but Flutter uses the requested single fixed selector radius of 14px for both
states.

## Architecture

`CenteredCarousel` remains the only owner of slot geometry, viewport packing,
scroll clipping, velocity normalization, target-step selection, and physics.
The time rail remains a generated-data adapter and supplies only the B3M tile
renderer and its B3M-derived `CenteredCarouselSpec` values. Direction controls
and time tiles read the same `AppSelectorMetrics` height/radius tokens.

The engine gains one neutral `viewportTrailingGap` configuration value. This
lets a viewport contain five `(tile width + gap)` slots while excluding the
trailing gap, matching the HTML geometry without changing item slot widths or
copying layout logic into the domain adapter.

## Changes

1. Add centralized B3M selector metrics and a responsive width calculation.
2. Use 37px tile/control height, 14px radius, 8px gap, and a fixed-slot
   `itemExtent = tileWidth + gap`.
3. Keep the existing dashboard outer rail height so the full vertical layout
   does not move, while vertically centering the shorter tile.
4. Remove the selected time tile shadow and keep the rail/list surfaces
   transparent; disable scrollbar and overscroll indicators in the shared
   engine.
5. Use time-rail scale values 1.12 / 0.96 / 0.84 / 0.76 at distances
   0 / 1 / 2 / 3+, preserving the shared continuous interpolation.
6. Update the shared velocity bands to 0.80, 5.00, 10.00, 16.00, and 24.00
   items/s and set the shared preset multiplier to 0.66.
7. Add assert-only release telemetry for velocity, band, friction projection,
   capped target, delta, and estimated snap settling time.

## Verification

Golden tests are intentionally excluded per the current user instruction.
Targeted physics, token, viewport, shape, shadow, widget, and architecture
tests will verify the behavior; the full non-golden Flutter suite, analyzer,
CI APK build, and direct APK download will be run before handoff.
