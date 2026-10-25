#!/usr/bin/env bash
set -euo pipefail

# Canonical PR correctness owners. Long density, trace and emulator work lives
# in the nightly/profile lanes; do not grow this list by duplicating an
# invariant already owned below.
flutter test \
  test/support/mother_card_raster_comparator_test.dart \
  test/features/dashboard/presentation/dashboard_mother_card_comparison_test.dart \
  test/features/dashboard/presentation/dashboard_mother_card_content_clip_test.dart \
  test/features/dashboard/presentation/balance_focused_cascade_test.dart \
  test/features/dashboard/presentation/mind_unified_mother_card_geometry_test.dart \
  test/features/dashboard/presentation/mind_unified_detachment_test.dart \
  test/features/dashboard/presentation/balance_unified_mother_card_geometry_test.dart \
  test/features/dashboard/presentation/balance_metric_cards_test.dart \
  test/features/dashboard/presentation/balance_dashboard_core_surface_test.dart \
  test/features/dashboard/presentation/balance_four_section_layout_test.dart \
  test/features/dashboard/presentation/dashboard_core_mode_host_test.dart \
  test/boundary/balance_presentation_settings_boundary_test.dart \
  test/features/dashboard/presentation/budget_unified_mother_card_geometry_test.dart \
  test/features/dashboard/presentation/budget_unified_detachment_test.dart \
  test/features/dashboard/presentation/budget_unified_detachment_state_test.dart \
  test/features/dashboard/presentation/budget_distribution_pager_test.dart \
  test/features/dashboard/application/dashboard_balance_daily_month_impact_projection_test.dart \
  test/features/dashboard/presentation/balance_daily_month_impact_test.dart \
  test/features/dashboard/presentation/balance_day_focused_layout_test.dart \
  test/features/dashboard/presentation/balance_day_focused_visuals_test.dart \
  test/features/dashboard/presentation/balance_day_visual_presentation_test.dart \
  test/features/dashboard/presentation/balance_impact_meter_legacy_test.dart \
  test/features/dashboard/presentation/balance_day_performance_horizontal_meter_test.dart \
  test/features/dashboard/presentation/balance_day_performance_index_presentation_test.dart \
  test/features/dashboard/presentation/balance_day_performance_index_view_test.dart \
  test/features/dashboard/presentation/balance_day_ratio_presentation_test.dart \
  test/features/dashboard/presentation/balance_day_ratio_comparison_test.dart \
  test/features/dashboard/presentation/budget_semicircle_semantic_scale_test.dart \
  test/features/dashboard/application/dashboard_presentation_preferences_test.dart \
  test/features/dashboard/presentation/balance_day_momentum_rail_test.dart \
  test/features/dashboard/presentation/balance_day_momentum_rail_geometry_test.dart \
  test/features/dashboard/presentation/balance_day_visual_motion_sync_test.dart \
  test/features/dashboard/presentation/dashboard_temporal_component_carousel_test.dart \
  test/features/dashboard/presentation/summary_pill_experiments_widget_test.dart \
  test/features/dashboard/application/dashboard_balance_daily_insights_projection_test.dart \
  test/features/dashboard/application/dashboard_balance_month_spending_level_projection_test.dart \
  test/features/dashboard/presentation/balance_month_net_margin_test.dart \
  test/features/dashboard/presentation/balance_month_focused_chart_presentation_test.dart \
  test/features/dashboard/presentation/balance_month_focused_layout_test.dart \
  test/features/dashboard/presentation/balance_sum_focused_chart_presentation_test.dart \
  test/features/dashboard/presentation/balance_sum_focused_layout_test.dart \
  test/features/dashboard/presentation/balance_sum_positive_ratio_gauge_test.dart \
  test/features/dashboard/presentation/balance_month_spending_level_gauge_test.dart \
  test/features/dashboard/presentation/balance_year_focused_chart_presentation_test.dart \
  test/features/dashboard/presentation/balance_year_focused_layout_test.dart \
  test/features/dashboard/presentation/fluvi_year_clay_capsule_painter_test.dart \
  test/features/dashboard/application/dashboard_balance_primary_projection_test.dart \
  test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart \
  test/features/dashboard/application/dashboard_balance_header_context_presentation_test.dart \
  test/features/dashboard/presentation/balance_header_income_expense_partition_test.dart \
  test/features/dashboard/presentation/balance_presentation_settings_test.dart \
  test/features/dashboard/presentation/dashboard_presentation_preferences_store_test.dart \
  test/boundary/balance_monthly_topographic_chart_boundary_test.dart \
  test/boundary/balance_monthly_topographic_native_platform_boundary_test.dart \
  test/core/design/fluvi_bounded_curve_test.dart \
  test/features/dashboard/presentation/fluvi_wave_recovery_test.dart \
  test/features/dashboard/presentation/fluvi_wave_shell_test.dart \
  test/features/dashboard/presentation/fluvi_wave_visual_test.dart \
  test/boundary/query_menu_boundary_test.dart \
  test/boundary/dashboard_interaction_performance_boundary_test.dart \
  test/boundary/dashboard_motion_data_isolation_boundary_test.dart \
  test/boundary/dashboard_single_data_runtime_boundary_test.dart \
  test/boundary/dashboard_avatar_target_liveness_boundary_test.dart \
  test/boundary/dashboard_avatar_profile_boundary_test.dart \
  test/features/dashboard/application/dashboard_avatar_resource_window_test.dart \
  test/features/dashboard/application/dashboard_avatar_candidate_lifecycle_test.dart \
  test/features/dashboard/presentation/dashboard_avatar_target_liveness_test.dart \
  test/performance/dashboard_profile_report_test.dart \
  test/features/dashboard/runtime/dashboard_navigation_zero_io_acceptance_test.dart \
  test/features/dashboard/runtime/dashboard_presentation_controller_test.dart \
  test/features/dashboard/application/dashboard_scene_window_rotation_test.dart \
  test/features/dashboard/application/dashboard_interaction_diagnostics_test.dart \
  test/features/dashboard/application/dashboard_core_query_application_test.dart \
  test/features/dashboard/query/application/query_composer_controller_test.dart \
  test/features/dashboard/query/application/query_menu_data_controller_test.dart \
  test/features/dashboard/query/application/saved_query_controller_test.dart \
  test/features/dashboard/query/data/method_channel_query_menu_repository_test.dart \
  test/features/dashboard/query/domain/query_temporal_filter_test.dart \
  test/features/dashboard/query/presentation/query_menu_sheet_test.dart \
  test/features/dashboard/logbox/application/dashboard_logbox_render_domain_test.dart \
  test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart \
  test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart \
  test/features/dashboard/presentation/dashboard_visible_scene_continuity_test.dart \
  test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart \
  test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart \
  test/features/dashboard/presentation/dashboard_query_facet_chips_test.dart \
  test/features/dashboard/time_navigation/domain/dashboard_temporal_availability_test.dart \
  test/features/dashboard/time_navigation/dashboard_time_navigation_controller_test.dart \
  test/features/dashboard/motion/dashboard_semantic_catalog_test.dart \
  test/shared/presentation/fluvi_slide_up_sheet_test.dart \
  test/app/automation_bottom_navigation_test.dart \
  test/features/manual_transactions/creation_selector_sheet_test.dart \
  test/features/automation/presentation/push_profile_wizard_page_test.dart \
  "$@"

# Preserve Budget's authored annual clay baselines after sharing its primitive.
flutter test test/features/dashboard/presentation/budget_secondary_analysis_card_test.dart \
  --plain-name YEAR

# Budget's unified transition preserves the existing PageView/cascade owners.
# The historical DAY header fixture is outside this physical-animation change.
flutter test test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart \
  --name 'Unified Budget composition|BUD-HDR-02|production Budget Card2|Budget avatar/content variants'
