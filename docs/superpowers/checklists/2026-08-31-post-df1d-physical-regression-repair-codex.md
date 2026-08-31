# Post-df1d physical regression repair — acceptance checklist

Source of truth: user request **FLUVI — POST-df1d PHYSICAL REGRESSION REPAIR** (2026-08-31), current local source `df1d4a3ca9ca83565260a6f7618ab3786ca5650e`, and the three current Google Docs captures reviewed on 2026-08-31.

This checklist is deliberately an execution contract. A passing analyzer or APK is not sufficient: every row must be `DONE`, or the user must explicitly defer it.

| ID | Source / evidence | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MIND-01 | User §9.1; `Fluvi logs slider` seq 2964–3060; `QueryAmountRangeControl._schedulePreview` | `query_amount_range_control.dart`, shared display-frame scheduler | Amount preview is published before the matching next paint, with latest-value coalescing; no post-frame-only boundary | Scheduler-order widget test and production Dashboard/LogBox drag test while pointer remains down | DONE |
| MIND-02 | User §9.2; slider range-cache/unmount log evidence | Mind range binding and `mind_dashboard_core_surface.dart` | Amount-only canonical reconciliation retains the domain, element/recognizer and local values; no loading/unmount | Delayed-commit production-parent test; counters | DONE |
| MIND-03 | User §9.3–9.4; release-time `QUERY_APPLY → INDEX_BUILD` logs | `CoreDashboard` Mind commit + visible-frame/LogBox lane | The latest exact preview remains authoritative through one async canonical commit; release causes no first visible delta | Slow/fast/reverse pointer-down tests plus delayed canonical completion | PARTIAL — the exact-paint waiter now retries after a first non-drawable matching extent and the production LogBox test is green; the full requested cardinality/mode matrix is not yet automated. |
| MIND-04 | User §9.5/§14 | Mind controller and range control tests | 20 immediate next-frame interactions, both thumbs/directions, empty and populated range cases | Focused tests without `pumpAndSettle` before the live assertion | DONE |
| TIME-01 | User §10.1–10.2; time-log lacks pointer verdicts | Segmented summary wiring, centered carousel and Core lifecycle | New pointer interrupts ballistic/settling motion immediately; background work cannot gate it; every pointer has a typed acceptance/rejection record | Production-parent immediate re-entry tests and bounded diagnostics | DONE |
| TIME-02 | User §10.3; current selector emits then assigns settle target | `_HierarchyValueSelectorState`, `DashboardCoreController` | Emitted, accepted and painted targets are distinct; only accepted/painted target may settle | Typed synchronous acceptance test including rejected/stale target | PARTIAL — a non-level crossing is now held as a preview until the exact LogBox paint acknowledgement, then promotes canonical navigation; broader stale/revision rejection cases are still incomplete. |
| TIME-03 | User §10.4–10.5 | Segmented selector/Core target settlement | `2025 → 2024 → 2025` and fast reversals settle to latest painted exact target with zero release delta | Production-parent reversal and 20 re-entry tests | PARTIAL — the production-parent test now proves paint-gated canonical promotion and parent-changing exact-scene restoration; complete DAY/MONTH/YEAR, empty and rapid-reversal coverage is still incomplete. |
| AV-01 | User §11.1; avatar log has aggregate-only diagnostics | Avatar rail / coordinator / render diagnostics | Direct, ballistic, settling, interrupted, cancelled and superseded counters are split, including Budget/LogBox matching paint | Focused tests + bounded interaction summary | PARTIAL — the retained accepted/painted owner and exact LogBox-paint gate are now shared with the Core; independent Budget raster acknowledgement and the full terminal-phase matrix are not yet present. |
| AV-02 | User §11.2–11.5; physical Avatar fling | Avatar rail → drilldown → Core live focus lane | Every direct and ballistic crossing atomically publishes target, Budget and exact LogBox before settle; stale revision cannot win | Production Budget parent test with active ballistic crossing and interruption | PARTIAL — a direct pointer now preempts stale focus, ballistic live publication is tested before settle, and settle cannot first promote an unpainted target; complete revision/mode/empty-target physical parity remains unproven. |
| ID-01 | User §12/§14 | shared visible-frame/live-interaction identity | Relevant visible layers share revision, query/refinement, source/phase/generation and presentation epoch; mixed projections are rejected | visible-frame and production-parent identity assertions | PARTIAL — navigation-only committed promotion preserves the exact payload/visible identity and the cache restores the matching painted scene; Avatar still lacks independent Budget raster evidence for every identity field. |
| PERF-01 | User §14 | Core interaction paths | No repository/native/index/foreground scene/text layout work during a prepared move; no artificial cooldown | Counters in all focused regression tests | DONE |
| DIAG-01 | User §13 | Mind/Summary/Avatar bounded diagnostics | Bounded numeric summaries contain required lifecycle/paint evidence; no per-vsync formatted log spam | Code review and diagnostic tests | DONE |
| VALID-01 | User §18–20 | test/analyze/commit/build workflow | All relevant automated validation is recorded honestly; exact committed source profile APK is built only after validation | command log, final source SHA, online build status | PARTIAL — online profile human-diagnostic build is intentionally after the functional commit and push |

## Architecture / centralization card

- **Existing reusable core:** `DashboardDisplayFrameCoalescer` already owns one-slot pre-display-frame coalescing. Mind must use it or a small equally shared adapter rather than another local scheduler.
- **Interaction authority:** `DashboardCoreController` owns prepared live projections, visible-frame identity, generation rules and scene activation. Widgets only collect intent and retain local physical gesture state.
- **Presentation owners:** `DashboardPresentationController` owns visible-frame publication; `DashboardLogBoxRenderSurface` owns the actual LogBox paint lane; `DashboardBudgetLogboxDrilldownCoordinator` adapts Avatar handles to the Core focus use case.
- **No duplicated mechanism:** Segmented and Avatar must use the existing core live-publication/generation seam; no widget-local Query, cache or timer/cooldown may be introduced.
- **Known boundary defects to prove:** Mind's `addPostFrameCallback`, Segmented's void crossing callback/early settle ownership, and missing Segmented Core direct-pointer preemption are source-visible. The exact Avatar ballistic drop and Summary physical rejection flag remain evidence-gated until red production-parent tests/instrumentation trace them.

## Automated evidence recorded before the functional commit

- `flutter test test/features/dashboard/presentation/core_dashboard_geometry_golden_test.dart` — FAIL: six golden pixel mismatches. The exact same six failures and pixel counts reproduce at clean `df1d4a3ca9ca83565260a6f7618ab3786ca5650e`, so this is an inherited environment/golden baseline failure rather than a delta from this repair. Reconfirmed after this repair: 6.39%/23,473; 7.19%/26,421; 8.37%/30,756; 9.00%/33,068; 25.91%/95,205; 7.19%/26,421.
- `flutter test test/shared/motion/centered_carousel` — PASS (`CENTERED_CAROUSEL_TEST_EXIT=0`) in Ubuntu proot.
- `flutter analyze` — PASS (`FLUTTER_ANALYZE_EXIT=0`) in Ubuntu proot.
- `dart format --output=none --set-exit-if-changed` for all changed Dart files — PASS.
- `git diff --check` — PASS.

The first functional commit and its human-diagnostic APK were produced from
`e4de8bb5d4c1f206a4e52bcc0867d8224663419e`, but independent review reopened
the rows above. No device conclusion is implied; physical validation remains
user-only.

## Review-reopened architecture card

### Scope and sources

- User requirement: §§9–14 of the post-df1d repair request.
- Existing implementation paths: `DashboardCoreController`,
  `DashboardPresentationController`, `DashboardLogBoxRenderSurface`,
  `BudgetTargetAvatarRail`, and `_HierarchyValueSelectorState`.
- Review evidence: read-only review of `df1d4a3..e4de8bb5` on 2026-08-31.

### Single source and write path

- Mind exact-paint acknowledgement belongs to `DashboardCoreController` and
  must resolve/retry deterministically for the target identity.
- Segmented canonical navigation must not become the owner of an unpainted
  target; the Dashboard coordinator owns accepted/live/presented state.
- Avatar settle must consume the same accepted-and-painted target identity
  published by the coordinator; the rail remains a rendering/input adapter.

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision |
| --- | --- | --- | --- |
| Exact live target acknowledgement | `DashboardCoreController` + LogBox render extent seam | accepted identity becomes settleable only after exact paint | Extend the shared coordinator seam; do not add Avatar-local persistence or polling. |
| Physical carousel interruption | `CenteredCarouselController` | drag/ballistic/snap cancellation | Preserve the one controller; only wire typed target ownership at the existing callbacks. |

### Focused verification

- A delayed Avatar acceptance/paint cannot first commit at settle.
- A non-drawable Mind extent followed by a drawable matching extent resolves exactly once.
- A Segmented candidate interrupted before paint cannot become the next gesture origin or canonical owner.
- A parent-changing painted Segmented target restores its exact retained LogBox scene before RAM-frame restoration and only then may be promoted canonically.
