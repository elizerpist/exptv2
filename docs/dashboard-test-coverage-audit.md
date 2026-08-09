# Dashboard test coverage audit

Audit base: `245ab81dee09f09d5d627f6f5a27a8559cb748dd`.

This is the accepted audit carried forward into the rail-critical continuity
work. It deliberately assigns one primary owner to each production invariant;
test count is not treated as a quality signal.

## Inventory and timing

The pre-consolidation audit measured 44 dashboard test files, 245 visible test
cases and roughly 230.7 seconds of dashboard wall time. The most expensive
files were `dashboard_rail_density_trace_test.dart` (175.7 s),
`dashboard_scene_window_rotation_test.dart` (82.4 s), `core_dashboard_test.dart`
(48.1 s), `dashboard_ready_first_fling_parity_test.dart` (44.8 s),
`dashboard_rebuild_isolation_test.dart` (38.0 s),
`dashboard_logbox_viewport_test.dart` (19.2 s),
`dashboard_presentation_controller_test.dart` (14 s),
`dashboard_rail_flight_recorder_widget_test.dart` (11 s),
`dashboard_scene_cache_scale_gate_test.dart` (11 s), and
`dashboard_interaction_diagnostics_test.dart` (10 s).

After the changes in this audit, static discovery reports 43 dashboard test
files and 214 direct `test`/`testWidgets` declarations. The curated fast
script completed in 37 seconds locally (78 dynamically expanded tests); CI
wall time is recorded separately because it includes setup and native jobs.

| File | Primary test name(s) / protected invariant | Generation | Disposition |
| --- | --- | --- | --- |
| `application/dashboard_core_metrics_test.dart` | physical report metric shape | Current | KEEP fast |
| `application/dashboard_expansion_controller_test.dart` | expansion state machine | Current | KEEP fast |
| `application/dashboard_interaction_diagnostics_test.dart` | diagnostics wire protocol and hot-path I/O rejection | Current | KEEP fast |
| `application/dashboard_interaction_readiness_test.dart` | bootstrap readiness transitions | Current | KEEP fast |
| `application/dashboard_performance_counters_test.dart` | counter semantics | Current | KEEP fast |
| `application/dashboard_rail_flight_recorder_test.dart` | recorder event state machine | Current | KEEP fast |
| `application/dashboard_render_readiness_diagnostics_test.dart` | readiness diagnostic state machine | Current | KEEP fast |
| `application/dashboard_scene_window_rotation_test.dart` | full query coverage; cancel; atomic revision bundle; no sibling rebase | Current | KEEP fast, reduced to 4 authoritative tests |
| `application/transaction_direction_controller_test.dart` | direction selection state machine | Current | KEEP fast |
| `logbox/application/committed_log_viewport_cache_test.dart` | I9/I10 committed page cache and drawable root | Current | KEEP fast |
| `logbox/application/committed_vertical_demand_planner_test.dart` | keyset demand bounds | Current | KEEP fast |
| `logbox/application/dashboard_logbox_render_domain_test.dart` | I2/I9 preview versus committed ownership | Current | KEEP fast |
| `logbox/application/dashboard_logbox_render_extent_snapshot_test.dart` | payload/drawable/paint report schema | Current | KEEP fast |
| `motion/dashboard_display_frame_coalescer_test.dart` | latest display-frame coalescing | Current | KEEP fast |
| `motion/dashboard_motion_kernel_test.dart` | motion state machine | Current | KEEP fast |
| `motion/dashboard_semantic_catalog_test.dart` | semantic catalog bounds | Current | KEEP fast |
| `presentation/core_dashboard_test.dart` | app shell and layout integration | Current | MOVE_TO_NIGHTLY |
| `presentation/dashboard_amount_update_policy_test.dart` | amount leaf update policy | Current | KEEP fast |
| `presentation/dashboard_logbox_prepared_scene_cache_test.dart` | I6/I7/I11 atomic staging, cancellation, manifest and text preparation | Current | KEEP fast |
| `presentation/dashboard_logbox_stable_render_surface_test.dart` | stable render surface identity | Current | KEEP fast |
| `presentation/dashboard_logbox_viewport_test.dart` | I3/I9/I10 vertical reset, demand and page boundaries | Current | KEEP fast |
| `presentation/dashboard_rail_density_trace_test.dart` | exhaustive density/velocity trace matrix | Current | MOVE_TO_NIGHTLY; A-J owns profile timing |
| `presentation/dashboard_rebuild_isolation_test.dart` | I12 widget identity contract | Current | KEEP fast, reduced from 4 stress tests to 1 contract |
| `presentation/dashboard_scene_cache_scale_gate_test.dart` | large-data bounded-preview scale | Current | MOVE_TO_NIGHTLY |
| `presentation/dashboard_visible_scene_continuity_test.dart` | I4/I5/I8 populated frame drawability through cancellation | Current | KEEP fast; authoritative continuity owner |
| `presentation/summary_navigation_motion_controller_test.dart` | summary motion controller | Current | KEEP fast |
| `presentation/summary_navigation_motion_region_test.dart` | gesture-region ownership | Current | KEEP fast |
| `presentation/summary_pill_presentation_widget_test.dart` | SummaryPill labels/order/plane UI | Current | KEEP fast |
| `presentation/summary_pill_transition_red_test.dart` | SummaryPill transition regression | Current | KEEP fast |
| `runtime/dashboard_data_runtime_test.dart` | revision/runtime lifecycle | Current | KEEP fast |
| `runtime/dashboard_motion_density_invariance_test.dart` | bounded data model versus motion | Current | MOVE_TO_NIGHTLY |
| `runtime/dashboard_navigation_zero_io_acceptance_test.dart` | I1/I14 navigation never I/O | Current | KEEP fast |
| `runtime/dashboard_presentation_controller_test.dart` | navigation state machine and I12 controller identity | Current | KEEP fast |
| `runtime/explicit_committed_paging_controller_test.dart` | I9 paging coordinator | Current | KEEP fast |
| `runtime/method_channel_dashboard_data_runtime_repository_test.dart` | native bridge contract | Current | KEEP fast |
| `runtime/prepared_dashboard_index_binary_codec_test.dart` | index wire roundtrip | Current | KEEP fast |
| `runtime/prepared_dashboard_index_test.dart` | prepared-index completeness | Current | KEEP fast |
| `time_navigation/dashboard_temporal_anchor_test.dart` | canonical temporal anchor | Current | KEEP fast |
| `time_navigation/dashboard_time_navigation_controller_test.dart` | parent/plane navigation | Current | KEEP fast |
| `time_navigation/summary_navigation_presentation_test.dart` | SummaryPill state derivation | Current | KEEP fast |
| `time_navigation/time_navigation_domain_test.dart` | time-domain value semantics | Current | KEEP fast |
| `visible/dashboard_visible_frame_store_test.dart` | visible-frame publication | Current | KEEP fast |
| `visible/dashboard_visible_frame_test.dart` | visible-frame immutable identity | Current | KEEP fast |

## Canonical invariant owners

| Invariant | Primary owner |
| --- | --- |
| I1 navigation never does DB I/O | `runtime/dashboard_navigation_zero_io_acceptance_test.dart` |
| I2 preview never owns committed query | `logbox/application/dashboard_logbox_render_domain_test.dart` |
| I3 sibling selection resets vertical scroll before presentation | `presentation/dashboard_logbox_viewport_test.dart` |
| I4 rail preview selects a bounded complete scene | `presentation/dashboard_visible_scene_continuity_test.dart` |
| I5 non-empty payload never paints zero rows | `presentation/dashboard_visible_scene_continuity_test.dart` |
| I6 staging never renders | `presentation/dashboard_logbox_prepared_scene_cache_test.dart` |
| I7 cancel never mutates active bank | `presentation/dashboard_logbox_prepared_scene_cache_test.dart` |
| I8 cancel never removes visible rail coverage | `presentation/dashboard_visible_scene_continuity_test.dart` |
| I9 vertical paging uses committed cache only | `logbox/application/committed_log_viewport_cache_test.dart` |
| I10 page zero/root is drawable | `logbox/application/committed_log_viewport_cache_test.dart` |
| I11 stale completion cannot publish | `application/dashboard_scene_window_rotation_test.dart` |
| I12 rail controller/physics/position are stable | `presentation/dashboard_rebuild_isolation_test.dart` |
| I13 no text layout on rail hot path | `presentation/dashboard_logbox_prepared_scene_cache_test.dart` |
| I14 no SQL on navigation hot path | `runtime/dashboard_navigation_zero_io_acceptance_test.dart` |
| I15 dense and sparse rail scopes preserve behavior | nightly density trace plus A-J profile |

## Removed and superseded tests

| Removed file/test | Reason | Canonical replacement |
| --- | --- | --- |
| `presentation/dashboard_ready_first_fling_parity_test.dart` | Two long widget matrices duplicated first/warm physical timing and gesture parity. | A-J profile suite |
| `presentation/dashboard_rail_flight_recorder_widget_test.dart` | One full physical fling duplicated recorder/profile evidence. | A-J profile suite; `application/dashboard_rail_flight_recorder_test.dart` remains the unit owner |
| First three tests in `presentation/dashboard_rebuild_isolation_test.dart` | Repeated the controller/physics stability contract at separate widget layers. | Single retained structural identity contract |
| Sixteen former anchor/coverage scenarios in `application/dashboard_scene_window_rotation_test.dart` | Guarded the old background-window correctness model or repeated cache/continuity tests. | Four retained orchestration/atomic-publication tests and the continuity test |

## Lane ownership

- Fast: analysis, native core, the script at `scripts/test-fluvi-fast.sh`, and the visible-scene continuity test.
- Profile: A-J emulator timing, first/warm parity, rail gesture evidence, memory, and counter smoke gates.
- Nightly: full non-golden Flutter suite, density trace, scale gates, full native suite, A-J, and optional fixed-baseline comparison.
