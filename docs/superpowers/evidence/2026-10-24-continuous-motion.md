# Mind and Balance continuous Mother Card motion

## Root causes

Mind previously revealed a stationary joined shell by clipping its content;
it did not resolve a separate continuous physical-card trajectory. Balance
restricted its four-section subtree to an expanded-only epsilon condition
(`zone2Opacity >= .999` and `collapseProgress <= .001`). Leaving that condition
switched to the legacy carousel/detail subtree and changed physical topology.
Narrow-body capacity also selected that fallback.

## Architecture and motion

`MindUnifiedMotherCardGeometry` derives Mind's physical envelope from its own
unified geometry and uses the existing zone-two shift/scale for independent
content motion. It does not require Budget's lower-card cascade.

`BalanceUnifiedMotherCardGeometry` resolves Balance's physical target from its
existing lower-card cascade. `_BalanceContentMotion` clips and transforms the
same live analytical scope subtree throughout forward and reverse movement.
The scope adapter caches the existing immutable prepared presentation; collapse
frames do not request financial projections or database work. Compact screens
scale the same authored canvas instead of mounting another family.

`DashboardJoinedMotherCardMaterial` shares material responsibilities only:
joined Header/body fill, perimeter, contact borders and body depth. One union
fill prevents a fractional-pixel internal seam at contact. The opening is
transparent. Master separation progress crossfades joined/body depth and
progressively enables the foreground Header shadow and border. Header remains
above the moving content. No animation controller was added. Budget application
code, global motion tokens and financial calculations are unchanged.

## Legacy removal and retained settings

The old Balance carousel renderer, ambient wave ticker/diagnostics, linked
detail host, primary-card host and obsolete indicator wrapper are removed.
The obsolete outer-layout, separate-content-card, carousel membership,
decoration, wave speed, visibility and Header time-label settings are removed.
Header line-chart time labels are unconditionally disabled.

SUM/YEAR/MONTH/DAY current/focused options, perspectives, child-card preference,
daily calculation and current Header options retain their persisted enum
mapping. Persistence tests verify that retired keys cannot reactivate the
legacy renderer or erase supported choices. Budget avatar navigation and the
shared CenteredCarousel implementation remain in place.

Historical tests of removed renderers were replaced by canonical geometry,
state identity, responsive scope, retained metric, persistence and tuner tests.
Host tests now assert the persistent Mother Card and analytical sections.
Legacy SUM fixture tests explicitly select Current instead of assuming a
changed default. No production defaults changed for those fixtures.

## Visual evidence

Inspected new rendered images for expanded, first swipe frame, early separation,
half collapse, near collapse and collapsed states across Mind and Balance.
Also inspected real Mind Year heatmap expanded/half states and the reactive
Header-color bridge. Month heatmap images and state-preservation assertions
cover the corresponding temporal path. The HTTP companion is
`http://127.0.0.1:49986/mind-balance-continuous-motion/`, served from the project's
single html-prototypes root, with links to canonical test goldens.

Geometry tests sample 1,000 progress points across viewport, rail, stretch and
corner settings. Widget tests retain element/state identity across interrupted
and reverse collapse, verify relative content movement and disable hidden
transformed interaction targets. Per-scope current/focused combinations are
covered at normal and narrow phone sizes.

## Validation and delivery

- Full proot Flutter analyze: no issues (104.4 seconds).
- Flutter/core boundary script: passed.
- Initial curated correctness run: 957 passed, one golden mismatch. Inspection
  measured exactly 47 differing pixels at the two outermost columns of the
  daily dashboard crop, within its first 25 rows. The new physical material
  clips its Header bridge to the body border; analytical pixels are unchanged.
  Only that golden is refreshed; no financial/chart design token is changed.
- Updated host and Mind temporal regression run: 52 passed.
- Refreshed daily MotherCard golden: targeted update and separate verification
  passed (one test each).
- Closing Budget YEAR golden/semantics checks: 3 passed.
- Closing Budget composition/header/state checks: 4 passed.
- Year heatmap, day heatmap and four-section layout regressions also passed
  in the earlier combined runs; their failures belonged to the now-corrected
  host fixtures or the four explicitly-selected legacy SUM fixtures.

The exact pushed SHA must pass GitHub's native and Flutter verification before
its normal human diagnostic APK can be published. Delivery uses the normal
lib/main.dart entrypoint, not the automated profile harness, and downloads to
/storage/emulated/0/Download/fluvi. The final delivery message records its hash.

No physical-device interaction or performance measurement was performed during
this recovery turn. Golden/state/geometry checks provide the visual and local
regression evidence; the online profile lane is separate from the human APK.

## Files

The staged implementation inventory below excludes unrelated historical local
failure/evidence files. A = added, M = modified, D = deleted.

```text
A	docs/superpowers/evidence/2026-10-24-continuous-motion.md
A	docs/superpowers/plans/2026-10-24-mind-balance-continuous-motion.md
M	html-prototypes/fluvi-balance-carousel-recovery-prototypes-index.html
A	html-prototypes/mind-balance-continuous-motion/assets/balance_unified_detachment_collapsed.png
A	html-prototypes/mind-balance-continuous-motion/assets/balance_unified_detachment_early.png
A	html-prototypes/mind-balance-continuous-motion/assets/balance_unified_detachment_expanded.png
A	html-prototypes/mind-balance-continuous-motion/assets/balance_unified_detachment_first_frame.png
A	html-prototypes/mind-balance-continuous-motion/assets/balance_unified_detachment_half.png
A	html-prototypes/mind-balance-continuous-motion/assets/balance_unified_detachment_near_collapsed.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_bridge_expanded.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_bridge_half.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_collapsed.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_early.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_expanded.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_first.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_half.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_month_heatmap_expanded.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_month_heatmap_half.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_near.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_year_heatmap_expanded.png
A	html-prototypes/mind-balance-continuous-motion/assets/mind_unified_detachment_year_heatmap_half.png
A	html-prototypes/mind-balance-continuous-motion/evidence.json
A	html-prototypes/mind-balance-continuous-motion/index.html
D	lib/features/dashboard/presentation/core_modes/balance_carousel_wave_diagnostics.dart
D	lib/features/dashboard/presentation/core_modes/balance_carousel_wave_motion.dart
M	lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart
M	lib/features/dashboard/presentation/core_modes/balance_four_section_layout.dart
D	lib/features/dashboard/presentation/core_modes/balance_insight_indicators.dart
D	lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart
M	lib/features/dashboard/presentation/core_modes/balance_presentation_settings.dart
D	lib/features/dashboard/presentation/core_modes/balance_primary_chart_card.dart
A	lib/features/dashboard/presentation/core_modes/balance_unified_mother_card_geometry.dart
M	lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart
A	lib/features/dashboard/presentation/core_modes/dashboard_joined_mother_card_material.dart
M	lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart
A	lib/features/dashboard/presentation/core_modes/mind_unified_mother_card_geometry.dart
M	scripts/test-fluvi-fast.sh
M	test/boundary/balance_presentation_settings_boundary_test.dart
M	test/features/dashboard/mind/presentation/mind_temporal_heatmap_viewports_test.dart
D	test/features/dashboard/presentation/balance_carousel_wave_diagnostics_test.dart
D	test/features/dashboard/presentation/balance_carousel_wave_motion_test.dart
M	test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart
M	test/features/dashboard/presentation/balance_day_focused_layout_test.dart
M	test/features/dashboard/presentation/balance_four_section_layout_test.dart
D	test/features/dashboard/presentation/balance_linked_detail_card_test.dart
A	test/features/dashboard/presentation/balance_metric_cards_test.dart
M	test/features/dashboard/presentation/balance_month_focused_layout_test.dart
M	test/features/dashboard/presentation/balance_presentation_settings_test.dart
D	test/features/dashboard/presentation/balance_primary_chart_card_test.dart
M	test/features/dashboard/presentation/balance_sum_focused_layout_test.dart
A	test/features/dashboard/presentation/balance_unified_mother_card_geometry_test.dart
M	test/features/dashboard/presentation/balance_year_focused_layout_test.dart
M	test/features/dashboard/presentation/dashboard_core_mode_host_test.dart
M	test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart
M	test/features/dashboard/presentation/dashboard_presentation_preferences_store_test.dart
A	test/features/dashboard/presentation/mind_unified_detachment_test.dart
A	test/features/dashboard/presentation/mind_unified_mother_card_geometry_test.dart
M	test/goldens/balance_day_month_impact_dashboard.png
A	test/goldens/balance_unified_detachment_collapsed.png
A	test/goldens/balance_unified_detachment_early.png
A	test/goldens/balance_unified_detachment_expanded.png
A	test/goldens/balance_unified_detachment_first_frame.png
A	test/goldens/balance_unified_detachment_half.png
A	test/goldens/balance_unified_detachment_near_collapsed.png
A	test/goldens/mind_unified_detachment_bridge_expanded.png
A	test/goldens/mind_unified_detachment_bridge_half.png
A	test/goldens/mind_unified_detachment_collapsed.png
A	test/goldens/mind_unified_detachment_early.png
A	test/goldens/mind_unified_detachment_expanded.png
A	test/goldens/mind_unified_detachment_first.png
A	test/goldens/mind_unified_detachment_half.png
A	test/goldens/mind_unified_detachment_month_heatmap_expanded.png
A	test/goldens/mind_unified_detachment_month_heatmap_half.png
A	test/goldens/mind_unified_detachment_near.png
A	test/goldens/mind_unified_detachment_year_heatmap_expanded.png
A	test/goldens/mind_unified_detachment_year_heatmap_half.png
```
