# Dashboard Expanded Geometry Reorder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move expanded action and summary geometry above shared mode content while preserving collapsed and downstream layout.

**Architecture:** Rewire `DashboardLayoutMetrics` as the sole expanded-anchor graph. Preserve `DashboardGeometryResolver` as the collapsed-anchor/interpolation owner and render every mode from the same `DashboardLayoutFrame`.

**Tech Stack:** Flutter, Dart, `flutter_test`, Ubuntu proot Flutter SDK, GitHub Actions.

## Global Constraints

- Collapsed action, summary, and rail anchors stay `219`, `282`, and `352`.
- Expanded rail stays at `695`; handler and LogBox do not compensate.
- Reuse existing dimensions and `standardGap`; add no production reference pixels.
- Do not change curves, controller ownership, cascade timing, or motion state.
- Do not regenerate unrelated goldens or run a local APK build.

---

### Task 1: Establish red geometry contracts

**Files:**
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Modify: `test/core/design/header_cascade_motion_test.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`

**Interfaces:** Consumes `DashboardLayoutMetrics.reference` and
`DashboardGeometryResolver.resolve`; produces failing expanded-order,
dependency, motion-endpoint, and interaction assertions.

- [x] **Step 1: Write the failing expanded resolver assertions.**

```dart
expect(frame.actionBounds.top, 241);
expect(frame.summaryBounds.top, 304);
expect(frame.subheaderOneBounds.top, 374);
expect(frame.zone2Bounds.top, 457);
expect(frame.railBounds.top, 695);
```

- [x] **Step 2: Run the focused test and verify a geometry expectation fails.**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && /home/flutteruser/flutter/bin/flutter test test/core/design/dashboard_geometry_resolver_test.dart'
```

Expected: failure because current action is `562` and current subheader one is
`241`.

- [x] **Step 3: Add cascade endpoint expectations `374` and `457`, plus a
widget contract that action and summary are positioned, ordered, and tappable
at the expanded endpoint.**

### Task 2: Rewire the shared expanded metric graph

**Files:**
- Modify: `lib/core/design/dashboard_layout_metrics.dart`
- Modify: `lib/core/design/dashboard_geometry_resolver.dart`

**Interfaces:** Consumes Task 1 contracts; produces centralized expanded
anchors while retaining collapsed interpolation anchors.

- [x] **Step 1: Implement only these metric relationships.**

```dart
double get actionTop => headerTop + headerExpandedHeight + standardGap;
double get summaryTop => actionTop + actionHeight + standardGap;
double get subheaderOneTop => summaryTop + summaryHeight + standardGap;
double get zone2Top => subheaderOneTop + subheaderOneHeight + standardGap;
double get railTop =>
    zone2Top + zone2CardHeight + dotGap + dotHeight + standardGap;
```

- [x] **Step 2: Preserve centered indicator and collapsed anchors.**

```dart
final collapsedActionTop =
    metrics.headerTop + metrics.headerCollapsedHeight + metrics.standardGap;
final collapsedSummaryTop =
    collapsedActionTop + metrics.actionHeight + metrics.standardGap;
final collapsedRailTop =
    collapsedSummaryTop + metrics.summaryHeight + metrics.standardGap;
```

- [x] **Step 3: Make frame gesture metadata match the actual header surface.**

```dart
headerGestureBounds: bounds(metrics.headerTop, headerHeight),
```

- [x] **Step 4: Run resolver and cascade tests; expect pass.**

### Task 3: Prove parity, input safety, and responsive dependency direction

**Files:**
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_core_mode_host_test.dart`
- Test: `test/boundary/dashboard_core_mode_boundary_test.dart`

**Interfaces:** Consumes the shared graph; produces evidence that mode content
is shared, Zone2 only moves downstream, and controls win hit tests.

- [x] **Step 1: Add the changed height propagation contract.**

```dart
expect(taller.actionBounds.top, baseline.actionBounds.top);
expect(taller.summaryBounds.top, baseline.summaryBounds.top);
expect(taller.railBounds.top, baseline.railBounds.top + 23);
expect(taller.collapseHandleBounds.top, baseline.collapseHandleBounds.top + 23);
expect(taller.logBoxHeaderBounds.top, baseline.logBoxHeaderBounds.top + 23);
```

- [x] **Step 2: Assert web and half-scale derived values.**

```dart
expect(metrics.forWebContentOrigin.actionTop, 189);
expect(metrics.forWebContentOrigin.subheaderOneTop, 322);
expect(halfViewportFrame.railBounds.top, 347.5);
```

- [x] **Step 3: Run core dashboard, mode-host, and boundary tests; expect pass.**

### Task 4: Verify and deliver

**Files:**
- Modify: `docs/superpowers/specs/2026-08-24-dashboard-expanded-geometry-reorder-design.md`

**Interfaces:** Consumes passing Tasks 1–3; produces a truthful completed
checklist, pushed commit, successful GitHub human APK, and local APK hash.

- [x] **Step 1: Re-read and update the acceptance checklist after verification.**
- [x] **Step 2: Run targeted, dashboard regression, boundary, and analyzer checks in Ubuntu proot.**
- [x] **Step 3: Inspect Stack/bounds and endpoint visuals without regenerating unrelated goldens.**
- [x] **Step 4: Commit the verified source and docs, then push
`separated-core-modes`.**
- [x] **Step 5: Monitor the exact-SHA human diagnostic APK, download the normal
`lib/main.dart` APK to `/storage/emulated/0/Download/fluvi`, and record
SHA-256.**
