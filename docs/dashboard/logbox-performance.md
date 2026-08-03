# Dashboard LogBox performance evidence

## Method

`test/features/dashboard/logbox/dashboard_log_render_budget_test.dart` creates
one complete local-day group with 100, 500 and 1000 immutable rows, projects
the UI view models once, then pumps a 378 × 260 logical-pixel viewport. It
asserts that row zero exists and the final row does not, which proves the
`SliverFixedExtentList` does not build the full day merely because the group
is visible.

The test-renderer output on 2026-08-03 was:

| Rows in one day | View-model projection | First viewport pump |
| ---: | ---: | ---: |
| 100 | 34 ms | 1256 ms |
| 500 | 4 ms | 254 ms |
| 1000 | 9 ms | 151 ms |

The first measurement includes Flutter test-engine warm-up and is not a
device-frame budget. The following measurements show that projection scales
with data mapping, while the viewport still builds only nearby rows. The test
does not claim device raster p50/p95 values: APK/profile collection is owned
by the online Android build because this Termux ARM64 environment cannot run a
local Flutter APK build.

## Structural limits

- first-page query cache: at most 36 scopes and at most 1000 decoded rows;
- page cache: at most 30 pages and at most 1000 decoded rows;
- `CustomScrollView.cacheExtent`: 360 logical pixels, copied from the audited
  Spendee Balance implementation;
- no hidden/offstage widget list or `IndexedStack` cache exists;
- row model formatting, name fallback and local time formatting occur at page
  bind/append, not in a scrolling build.

## Hot-path evidence

- `dashboard_core_controller_test.dart` executes 100 rail preview ticks with
  zero dashboard-query watch requests and zero dashboard-root notifications.
- `dashboard_log_page_coordinator_test.dart` confirms preview does not bind or
  query a LogBox page; a resolved target may prefetch once but cannot change
  visible LogBox state before the normal settled-scope commit.
- `dashboard_log_area_test.dart` verifies a dense 100-row day builds only the
  viewport-near rows.
