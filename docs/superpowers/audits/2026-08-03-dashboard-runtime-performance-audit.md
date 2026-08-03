# Flutter Runtime Performance Audit

## Runtime Performance Score

7 / 10

## Runtime Performance Maturity Level

Level 3 — Optimized Runtime

## Audit scope and method

- Inspected `pubspec.yaml` and recursively scanned all 100 authored Dart files
  under `lib/`; generated Dart files are absent from the reviewed set.
- Read the dashboard controller, finite-bundle, MethodChannel decode, LogBox
  projection/paging, query-cache and diagnostics paths directly.
- This is a static audit. There is no Android device connected, so it makes no
  p50/p90/p99 or isolate-offload claim from assumed timings.

## Key Runtime Strengths

- A finite parent read is one MethodChannel call (`readDashboardParentPreviewBundle`),
  then one immutable whole-bundle publication. `DashboardParentDisplayBundleController`
  deduplicates same-parent in-flight reads and its LRU is bounded and pins the
  active complete bundle.
- View-model formatting is performed by `DashboardLogViewModelProjector` while
  a snapshot is created, not by a LogBox row build or scroll callback.
- There are no authored uses of `jsonDecode`, crypto, image codec decoding,
  `Future.delayed(Duration.zero)` as pseudo-offloading, `scheduleMicrotask`,
  `Stream.periodic`, `Timer.periodic`, or uncontrolled large `Future.wait`.
- The legacy LogBox sort/group fallback is on page binding, not a rail-preview
  tick. Finite bundle lookup itself is a map lookup.

## Detected CPU Bottlenecks

### Bottleneck 1 — parent payload DTO decode and projection

**Severity:** MEDIUM (measurement required before optimization)

**Problem**

`MethodChannelDashboardLedgerRepository.readParentDisplayBundle` walks the
entire returned parent payload and its nested day groups on the UI isolate
(`lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart:67-128`).
Every populated child immediately invokes `DashboardLogPreviewSnapshot.populated`,
which projects all row view models (`dashboard_parent_display_bundle.dart:18-27`;
`dashboard_log_view_models.dart:54-119`).

**Impact**

The number of finite children is capped at 31 (MONTH) or 12 (YEAR), and each
request uses `pageSize: 1`/`maxDayGroups: 7`, so this is not proof of a frame
budget breach. A child day can nevertheless contain many rows; decode plus
formatting could therefore occupy more than 4 ms on the UI isolate on a real
device.

**Recommendation**

Add profile-only numeric spans around MethodChannel decode and complete-bundle
projection. Keep it on the UI isolate unless a recorded span exceeds the frame
budget. If that happens, extract serializable DTO decode/projection into a pure
`Isolate.run` function; do not pass `ChangeNotifier`, `BuildContext`, or the
cache controller across an isolate boundary.

### Bottleneck 2 — legacy committed-result grouping

**Severity:** LOW

**Problem**

`DashboardLogPageCoordinator._groupLegacyEntries` groups all legacy entries
and sorts their dates (`dashboard_log_page_coordinator.dart:295-324`).

**Impact**

It is only used when the native result lacks `dayGroups`; it is not on the
finite-preview crossing path. Its input bound is not encoded at this Dart
boundary.

**Recommendation**

Leave the working fallback unchanged for this regression. Trace committed-page
projection separately and only move this pure fallback if a real profile shows
it contributes material UI-isolate time.

## Async Workflow Issues

- `DashboardCoreController` intentionally starts the current finite-bundle
  request without awaiting it, preserving shell responsiveness. The current
  implementation has no staged startup coordinator, adjacent prewarm, or
  motion-aware deferral; those are functional gaps, not a reason to serialize
  the current shell behind I/O.
- The prior child-by-child summary warming path remains in
  `DashboardSummaryMetricsController`. It must not race a finite parent deck;
  the follow-up controller integration test will prove the finite route makes
  no child fallback read.

## Memoization Opportunities

- `DashboardParentDisplayBundle` correctly stores both decoded groups and
  projected view groups. Preview must reuse those list identities rather than
  invoke `DashboardLogViewModelProjector` again at settle.
- The legacy `DashboardSummaryMetricsController` still owns a child-summary
  LRU. A finite parent display selection needs one derived metrics source so
  the bundle remains the sole preview cache for amount/count/LogBox.

## Caching Opportunities

- The new whole-bundle LRU has capacity 4 and active-bundle pinning. It is an
  appropriate bounded cache for finite parent preview data.
- No HTTP repository is present in this project, so HTTP-response caching is
  not applicable to this dashboard audit.

## Event Loop Risks

- No recursive microtask, manual frame-rate stream, fast periodic timer, or
  high-fanout `Future.wait` was found in authored Dart source.
- Debug event publication is frame-coalesced when a listener exists. The
  backing list still uses `removeAt(0)` and is addressed by the diagnostic
  logger work item, rather than treating it as a data-query issue.

## Technical Debt Indicators

- No `Isolate.run`/`compute` is currently used. That is acceptable because no
  measured high-severity CPU operation was found; introducing an isolate before
  trace evidence would add serialization and latency risk.
- `FluviDiagnosticLogger.allText` formats all buffered events when the dialog
  asks for it. It is already absent from the closed-panel log path, but the
  ring-buffer and open-panel refresh semantics need the requested dedicated
  regression coverage.

## Strategic Recommendations

1. Implement profile-only numeric trace spans and frame timing first; use them
   to decide whether DTO decode/projection merits isolate work.
2. Complete the finite-bundle integration so a current complete deck suppresses
   all legacy child fallback reads, then stage current/adjacent warmup without
   blocking the interactive shell.
3. Preserve precomputed view-model identities through preview-to-committed
   promotion and parent swap; do not recompute groups or format values on rail
   crossings.
