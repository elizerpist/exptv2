# Shared Mother Card cascade implementation

Base: `2e809f2a5538f9ab637aa882da9231bc697f083e` on the existing
`refactor/mind-balance-continuous-mother-card` branch. No reset or content redesign.

## Cause and architecture

Mind previously anchored both body and content to `zone2Shift`, and mainly
reduced the body's height. Budget/Balance interpolated an attached rectangle
toward an already moving, large-height target. Balance also transformed and
faded its focused perspective selectors together with the lower charts.

`DashboardUnifiedMotherCardMotion` now owns the physical rectangle, clipping
rectangle, content reference envelope, radii, opacity and depth progression for
all three modes. The three previous geometry classes are thin adapters. The
resolver exposes the same read-only `HeaderCascadeMotion` result and geometry
for unified Mind while preserving its structural composition and nullable
`lowerCardMotion`. The existing master progress remains the sole animation
owner. There are no new timers, controllers or per-frame layout measurements.

The physical top follows the actual lower cascade, translated back by the
existing upper-lane height and closing structural gap. It no longer interpolates
an attached rectangle toward a moving target. Horizontal bounds use the
cascade's inset and scale. The bottom follows a separately moving canonical
analytical canvas, rather than the larger `modeContentBounds` envelope. Its
reference origin retains the accepted lower analytical anchor and its lower
slide. Consequently top and bottom have distinct continuous trajectories;
the physical body both translates and compresses. The existing authored
trailing inset scales with the content. No Summary Pill coordinate is used.

Mind receives that same physical rectangle and a separate scaled/sliding
content reference. Its mounted heatmaps, sliders and scrollables remain in
place in the widget tree. Balance retains its accepted lower-content matrix.
Its focused selector adapts the upper cascade to the full preserved analytical
origin, adding the existing upper displacement to that origin. An explicit
35/50% regression prevents the chart from overtaking the selector. It uses the
compensated matrix
`A^-1 * L^-1 * U * A`, including compact-canvas offsets; lower and upper opacity
are applied separately. A stable opacity render object paints directly at full
opacity to preserve the exact expanded avatar-gradient raster.

Budget's existing upper and lower cascade transforms, avatar overflow and
PageView are unchanged. A stable physical-body viewport now clips actual
content to the corrected surface in unified mode. Split mode keeps the same
subtree with clipping disabled. Earlier clipping of Budget's lower allocation
is an intentional consequence of keeping its accepted content trajectory while
raising the physical bottom. A paint-only trailing mask fades ink through four
existing gap units times master separation before the clip boundary; it adds no
time track. The stable mask render object paints directly at expansion and
retains its shader layer through reverse motion. A pixel-alpha regression checks
the soft edge, containment, reverse restoration and persistent child identity.
The populated 60/40 donut was actually rendered and inspected at 35/50/65%; its
boundary is soft, with no hard horizontal color slice. See the measured
allocation fractions and rendered evidence below.

## Measured improvement and visual evidence

See [measurements.md](measurements.md) for the complete mode-by-mode table.
At 35/50/65% collapse, Balance's physical bottom moves from
585.841/570.262/545.830 to 530.527/482.269/419.835 logical pixels. Its accepted
content bottom stays 519.380/471.582/409.663. The trailing gap falls from
66.461/98.681/136.168 to 11.148/10.688/10.172: 83.2/89.2/92.5% less empty material.
The Summary tops remain 542.650/482.500/422.350. The corrected material is above
them at all three measured states.

These are deterministic layout-envelope measurements, not pixel detection of
chart ink. Actual Flutter frames were rendered separately. Exact old/new rich
Balance expanded images are byte-identical. Rich Balance intermediate frames
show its original chart position with the trailing material removed; populated
Mind intermediate frames show independent upward heatmap movement with its
range slider retained. The evidence README distinguishes exact historical
scenes, live-controller scenes and fixtures with empty ledgers.

The HTTP companion remains in its sole canonical folder:
`html-prototypes/mind-balance-continuous-motion/`. Its diagram explains the
four tracks; linked PNGs are actual Flutter evidence, not the diagram itself.

## Files and regression ownership

- `dashboard_geometry_resolver.dart`, `dashboard_layout_frame.dart`: expose
  canonical read-only cascade inputs without altering structural layout.
- `dashboard_unified_mother_card_motion.dart`: shared physical policy and clip.
- Three `*_unified_mother_card_geometry.dart`: thin physical adapters and
  mode-specific content reference/matrix.
- `budget_dashboard_core_surface.dart`: stable unified clipping around the
  original interactive cascade cards.
- `balance_dashboard_core_surface.dart`, four focused layouts and
  `balance_focused_cascade.dart`: independent selector cascade with stable state.
- Existing geometry and detachment tests: new geometry contract and 35/65%
  intermediate golden coverage; existing expanded references retained.
- `balance_focused_cascade_test.dart`: nine selector/scale/opacity/state/reverse
  regressions across scopes and variants, including compact coordinates.
- `dashboard_mother_card_content_clip_test.dart`: actual rendered alpha at the
  trailing edge, containment, reverse and subtree identity.
- `dashboard_mother_card_comparison_test.dart`: independent historical oracle,
  actual mode-adapter equality and normalized shared timing at eleven points.
- Opt-in evidence tests: eight rendered states per mode, rich analytical
  fixtures, actual live dashboard controllers and material comparisons.
- `scripts/test-fluvi-fast.sh`: includes the new parity and selector tests in CI.

## Verification and delivery

All commands run inside Ubuntu/proot with `/home/flutteruser/flutter/bin/flutter`.
No APK was built on the phone.

- Full `flutter analyze`: **No issues found** (103.7 seconds). Initial analyzer
  findings in new test/helper code were corrected before this clean run.
- Three geometry suites plus comparison: **75 passed**.
- Updated detachment/golden suites: **45 passed**. Only affected intermediate
  PNGs changed, plus new 35/65% references; expanded/collapsed references stayed
  unchanged.
- Final selector, paint-alpha, Budget detachment/state and Balance surface
  suites: **49 passed** against the final source. This includes all four
  existing Budget temporal configurations and selector reverse/state cases.
- Comparison-specific suite: **3 passed**, independently rerun after adding
  explicit Summary exclusion and trailing-gap assertions.
- Opt-in capture runs rendered final rich scenes at eight states each, including
  populated Budget, Mind and focused/nonfocused Balance. See README for exact
  fixtures, hashes and limits.

The wider `scripts/test-fluvi-fast.sh` regression and exact-commit GitHub CI are
also monitored before final delivery. The normal human APK delivery receipt,
including exact production SHA and downloaded file SHA-256, is reported with
the handoff; automated profile/harness APKs are not substitutes.
