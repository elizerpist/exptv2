#!/usr/bin/env bash
set -euo pipefail

# Canonical PR correctness owners. Long density, trace and emulator work lives
# in the nightly/profile lanes; do not grow this list by duplicating an
# invariant already owned below.
flutter test \
  test/boundary/query_menu_boundary_test.dart \
  test/boundary/dashboard_interaction_performance_boundary_test.dart \
  test/boundary/dashboard_motion_data_isolation_boundary_test.dart \
  test/boundary/dashboard_single_data_runtime_boundary_test.dart \
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
  test/shared/presentation/fluvi_slide_up_sheet_test.dart
