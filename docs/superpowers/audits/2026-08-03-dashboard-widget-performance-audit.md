# Flutter Widget Performance Audit

## Performance Score

7 / 10

## Performance Maturity Level

Level 3 — Optimized UI

## Audit scope and method

- Traced the application root through `FluviAppShell`, `CoreDashboard`,
  `DashboardMotionHost`, summary, rail and LogBox presentation trees.
- Recursively scanned all authored widgets in `lib/`, then read the dashboard
  header/rail/LogBox/row/SVG paths directly.
- This is static source evidence. Device raster timings are explicitly pending;
  no raster percentile is inferred from code.

## Key Performance Strengths

- `CoreDashboard` keeps `_DashboardLogBoxRegion` as a stable widget instance;
  its internal `ListenableBuilder` listens only to `controller.logBox`
  (`core_dashboard.dart:223-227,256-278`). Rail preview does not need to
  rebuild the lazy LogBox subtree.
- LogBox rows use `SliverFixedExtentList.builder` with a fixed item extent,
  disabled automatic keep-alives and per-row repaint boundaries
  (`dashboard_day_log_group.dart:64-75`). This keeps a busy day lazy and gives
  O(1) row-position calculation.
- The LogBox outer area already has a targeted repaint boundary and a stable
  viewport key (`dashboard_log_area.dart:24-67,94-125`). Row data is
  preformatted in application code rather than computed in `build`.
- The rail is a lazy `ListView.builder`; its item renderer has a repaint
  boundary, so a moving item does not automatically repaint all rail siblings.

## Critical Performance Issues

### Issue 1 — dynamically changing rail opacity in every visible carousel item

**Severity:** MEDIUM; profile trace required to quantify raster cost

**Problem**

Each visible physical rail item is rendered as
`RepaintBoundary -> Opacity(opacity: metrics.opacity) -> Transform.scale`
inside `ListView.builder` (`centered_carousel.dart:225-230`). Its opacity
changes during a fling.

**Impact**

Dynamic partial opacity can require compositing/offscreen work on each visible
item during the interaction. The existing boundary contains repaint scope, but
it also creates per-item layers. The net raster effect is device dependent.

**Recommendation**

Record UI/raster frame timing around the exact rail matrix before changing this
composition. Do not add another boundary and do not change fling physics. If
profiling proves this is a raster hot path, replace only the opacity renderer
with an equivalent compositing-safe leaf implementation and add a focused
widget identity test.

### Issue 2 — rounded clip plus shadow on each visible LogBox day group

**Severity:** MEDIUM; profile trace required to quantify raster cost

**Problem**

Every visible day group uses `SliverClipRRect(Clip.antiAlias)` around a
`DecoratedSliver` that has both radius and card shadow
(`dashboard_day_log_group.dart:56-75`).

**Impact**

The cost is per visible day group rather than per row, and the custom sliver
preserves laziness. It is therefore not a reason to remove the intended card
appearance without measurement, but it is the correct raster candidate for the
empty/9-row profile matrix.

**Recommendation**

Keep the current visual hierarchy until the numeric profile identifies it as a
raster contributor. Any revision must retain lazy rows and must be covered by
the same LogBox shell/scroll-controller identity regression.

## Technical Debt Indicators

- `DashboardSummaryPill` is 906 lines. It owns valid animation lifecycle but
  needs counter-based tests proving identical preview/settle input produces no
  amount animation or outer header rebuild.
- Several dashboard transition leaves use animated `Opacity` (`core_dashboard.dart`,
  `summary_pill_text_transition.dart`). The text-only transitions are small;
  the large rail/card cases are trace candidates, not blanket `FadeTransition`
  rewrites.
- No `IntrinsicHeight`, `IntrinsicWidth`, dynamic `ListView(children: ...)`,
  `shrinkWrap` list, `BackdropFilter`, or network image decode was found in the
  dashboard scrolling hot path.

## Strategic Performance Recommendations

1. Add rebuild/identity counters for 100 preview events and promotion: header,
   rail, visible rows, LogBox bind and scroll-controller identity.
2. Add profile-only UI/raster frame timing and use the controlled empty/9-row
   matrix before changing opacity, clipping or shadows.
3. Preserve the existing narrow listener boundaries: dashboard geometry owns
   layout motion, summary owns navigation presentation, and LogBox owns its
   own data-state rebuilds.
