# LogBox Ledger Result and Search Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a committed Ledger result amount and a visual-only SearchPill to
the existing LogBox chrome without changing SummaryPill, query, or scroll
ownership.

**Architecture:** Reuse `DashboardVisibleFrameStore` as the one prepared
result source. Extend the current `DashboardLogBoxHeader` above the one stable
viewport and make its fixed chrome height a central dashboard metric.

**Tech Stack:** Flutter, Dart, `flutter_test`, Ubuntu proot Flutter SDK,
GitHub Actions human diagnostic APK.

## Global Constraints

- Preserve SummaryPill and its duplicate amount.
- Do not add a query state, formatter, scrollable, scroll controller, or
  `TextPainter` render-path work.
- Use existing design tokens and background-only result text; only SearchPill
  gets a surface.
- Preserve committed virtual geometry and controller/physics identity.
- Search is a disabled presentation scaffold, not a false editable control.

---

### Task 1: Establish red Ledger header contracts

**Files:**
- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`

**Interfaces:** Consumes `DashboardVisibleFrameStore`, `DashboardLogBoxViewport`,
and `CoreDashboard`; produces failing keys and order contracts for
`dashboard-logbox-result-amount`, `dashboard-logbox-entry-count`, and
`dashboard-logbox-search-pill`.

- [x] **Step 1: Add widget assertions for amount/count/SearchPill order,
  SearchPill semantics/surface, atomic frame replacement, and stable scroll
  surface placement.**

```dart
expect(result.top, lessThan(count.top));
expect(count.bottom, lessThan(search.top));
expect(search.bottom, lessThan(scrollView.top));
expect(find.ancestor(of: resultAmount, matching: find.byType(FluviRoundedBox)), findsNothing);
```

- [x] **Step 2: Add the CoreDashboard collapsed/expanded movement and existing
  SummaryPill presence contract.**

```dart
expect(find.byKey(const ValueKey('dashboard-summary-shell-transform')), findsOneWidget);
expect(collapsedSearch.top - collapsedResult.top, closeTo(expandedSearch.top - expandedResult.top, .01));
expect(expandedResult.top, greaterThan(collapsedResult.top));
```

- [x] **Step 3: Run the focused tests and observe failure because the result
  and SearchPill do not exist.**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/main-export-ci-fix && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart test/features/dashboard/presentation/core_dashboard_test.dart test/core/design/dashboard_geometry_resolver_test.dart'
```

### Task 2: Centralize Ledger top chrome geometry and tokens

**Files:**
- Modify: `lib/core/design/dashboard_layout_metrics.dart`
- Modify: `lib/core/design/dashboard_mode_palette.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`

**Interfaces:** Consumes `DashboardLayoutMetrics.logBoxHeaderHeight`; produces
a viewport header height that exactly matches the fixed Ledger result/search
block plus optional existing Query facet height.

- [x] **Step 1: Change only the fixed `referenceLogBoxHeaderHeight` and keep a
  legacy 24px count-header constant in the reclaimed Zone2 formula.**

```dart
static const referenceLogBoxCountHeaderHeight = 24.0;
static const referenceLogBoxHeaderHeight = 122.0;
static const reclaimedCoreVerticalSpace =
    previousOpenRailToCollapseHandleGap - referenceOpenRailToCollapseHandleGap +
    previousLogBoxHeaderHeight - referenceLogBoxCountHeaderHeight;
```

- [x] **Step 2: Add Ledger-header component dimensions and visual text tokens
  beside the current LogBox tokens.**

```dart
static const ledgerResultTopInset = DashboardLayoutMetrics.reference.standardGap;
static const ledgerResultAmountHeight = 26.0;
static const ledgerResultCountHeight = 17.0;
static const ledgerSearchPillHeight = 46.0;
```

- [x] **Step 3: Make `_headerHeight` use `widget.bounds.height`, plus only the
  existing conditional Query facet height.**

```dart
double get _headerHeight =>
    widget.bounds.height +
    (_hasQueryFacets ? DashboardQueryFacetChips.height : 0);
```

### Task 3: Render the atomic Ledger result and visual-only SearchPill

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`

**Interfaces:** Consumes immutable `DashboardVisibleFrame`; produces plain
result/count semantics and a disabled `DashboardLogBoxSearchPill` surface.

- [x] **Step 1: Render result and count from one `ValueListenableBuilder` of
  `DashboardVisibleFrameStore`, never from materialized rows.**

```dart
ValueListenableBuilder<DashboardVisibleFrame?>(
  valueListenable: visibleFrames,
  builder: (context, frame, _) => _DashboardLedgerResultSummary(frame: frame),
)
```

- [x] **Step 2: Use only plain `SizedBox`/`Text` layout for the result and
  central `FluviRoundedBox` tokens for the distinct SearchPill.**

```dart
Semantics(
  button: true,
  enabled: false,
  label: 'Keresés a tranzakciókban. A keresés hamarosan elérhető.',
  child: ExcludeSemantics(child: DashboardLogBoxSearchPill()),
)
```

- [x] **Step 3: Keep existing active facet chips after SearchPill and before
  the scroll surface. Do not add any input/controller/query callback.**

### Task 4: Green, regression, visual evidence, and delivery

**Files:**
- Modify: focused tests and only relevant Ledger golden fixture if needed.
- Modify: `docs/superpowers/specs/2026-08-24-logbox-ledger-result-search-design.md`

**Interfaces:** Consumes passing Tasks 1–3; produces verified architecture and
the requested delivery commit.

- [x] **Step 1: Run the red tests after Task 1, implement Tasks 2–3, and rerun
  focused widget/geometry tests to green.**
- [x] **Step 2: Run LogBox stable-render, vertical-scroll, Query, core-mode,
  boundary, analyzer, and the repository curated Flutter suite in Ubuntu
  proot.**
- [x] **Step 3: Inspect the changed collapsed/expanded Ledger visuals and
  update only directly related golden evidence.**
- [x] **Step 4: Re-read the acceptance checklist, mark truthful statuses,
  commit `feat(logbox): add ledger result summary and search pill`, push, and
  complete the required human APK delivery loop.**
