#!/usr/bin/env bash
set -euo pipefail

# Canonical PR correctness owners. Long density, trace and emulator work lives
# in the nightly/profile lanes; do not grow this list by duplicating an
# invariant already owned below.
flutter test \
  test/boundary/dashboard_interaction_performance_boundary_test.dart \
  test/boundary/dashboard_motion_data_isolation_boundary_test.dart \
  test/boundary/dashboard_single_data_runtime_boundary_test.dart \
  test/features/dashboard/runtime/dashboard_navigation_zero_io_acceptance_test.dart \
  test/features/dashboard/runtime/dashboard_presentation_controller_test.dart \
  test/features/dashboard/application/dashboard_scene_window_rotation_test.dart \
  test/features/dashboard/application/dashboard_interaction_diagnostics_test.dart \
  test/features/dashboard/logbox/application/dashboard_logbox_render_domain_test.dart \
  test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart \
  test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart \
  test/features/dashboard/presentation/dashboard_visible_scene_continuity_test.dart \
  test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart \
  test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart
