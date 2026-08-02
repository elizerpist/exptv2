# Dashboard LogBox Header Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first, count-only LogBox header directly below the dashboard handler without changing query, rail, or amount behavior.

**Architecture:** Extend the central dashboard geometry with a LogBox header bounds. Render a presentation-only `DashboardLogBoxHeader` that listens to the existing immutable amount presentation and emits deduplicated debug telemetry. No detailed ledger/list state is introduced.

**Tech Stack:** Flutter widgets, `ChangeNotifier`/`ListenableBuilder`, existing dashboard geometry resolver, Flutter widget/golden tests.

## Global Constraints

- Read `SummaryAmountPresentation.entryCount`; do not call or mutate `CurrentQueryController`.
- Header contains only the top count caption in this slice.
- Use semantic Fluvi tokens and central bounds resolution.
- Debug telemetry must be value-change-only, never frame/pointer-path logging.
- The handler stays above the LogBox header in the dashboard stack.

---

### Task 1: Lock down geometry, visual count, and debug behavior with tests

**Files:**
- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Modify: `test/features/dashboard/presentation/core_dashboard_test.dart`
- Create: `test/features/dashboard/presentation/dashboard_logbox_header_test.dart`

- [x] **Step 1: Write failing geometry/widget tests**

Assert `logBoxHeaderBounds.top == collapseHandleBounds.bottom`, expected 28 px
height, handler hit target remains present, and the initial header reads
`0 tranzakció listázva`.

- [x] **Step 2: Run the focused tests and verify they fail because the bounds/widget do not exist**

Run:
`flutter test test/core/design/dashboard_geometry_resolver_test.dart test/features/dashboard/presentation/core_dashboard_test.dart test/features/dashboard/presentation/dashboard_logbox_header_test.dart`

- [x] **Step 3: Add a failing immediate-presentation/log test**

Drive a fake amount presentation from count 0 to count 4 and assert immediate
caption replacement plus one D11 diagnostic carrying `entryCount=4`; publish
the same presentation again and assert no second D11 record.

### Task 2: Add the presentation-only LogBox header and central bounds

**Files:**
- Modify: `lib/core/design/dashboard_layout_metrics.dart`
- Modify: `lib/core/design/dashboard_layout_frame.dart`
- Modify: `lib/core/design/dashboard_geometry_resolver.dart`
- Modify: `lib/core/design/dashboard_mode_palette.dart`
- Create: `lib/features/dashboard/presentation/widgets/dashboard_logbox_header.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`

- [x] **Step 1: Extend the metric/frame/resolver**

Add a 28 px `logBoxHeaderHeight` metric and expose `logBoxHeaderBounds` directly
after `collapseHandleBounds` for every expansion/rail state.

- [x] **Step 2: Implement the header leaf**

Use `ListenableBuilder`, `RepaintBoundary`, semantic caption token, and
transparent centered text. Maintain only a logging-dedupe signature in widget
state.

- [x] **Step 3: Compose it below the rail and below the handler's z-order**

Place the header after the rail but before `DashboardCollapseHandle`, wiring
the existing summary amount controller/presentation builder.

- [x] **Step 4: Run the focused tests and verify they pass**

Run the Task 1 test command in the Ubuntu Flutter environment.

### Task 3: Regression and visual evidence

**Files:**
- Modify if needed: `test/features/dashboard/presentation/core_dashboard_golden_test.dart`
- Update only if required: `test/goldens/core_dashboard_*.png`

- [x] **Step 1: Regenerate/read affected core dashboard goldens**

Run the golden update only if the focused golden test proves the baseline has
changed; inspect the resulting image for transparent header placement and no
list content.

- [x] **Step 2: Run focused presentation/query/rail regression tests**

Run the LogBox, core dashboard, summary amount, summary pill, rail, and
boundary tests in Ubuntu proot.

- [x] **Step 3: Complete the acceptance checklist and commit**

Re-read `docs/superpowers/specs/2026-08-02-dashboard-logbox-header-design.md`,
mark evidence-backed items DONE, and commit the tested implementation.
