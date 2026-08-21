# Budget Card2 drawable readiness, partner distribution and pager — acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BDP-A1 | User §5–§8A | Card2 drawable readiness | Cold Sum/Year/Month navigation never publishes a blank/non-drawable Card2 frame. | Controller/state tests with cold prewarmer. | DONE |
| BDP-A2 | User §8A | Existing next-plane readiness owner | Supported target distribution bank is renderer-ready before semantic time publication; stale work cannot publish. | Readiness barrier/supersession tests. | DONE |
| BDP-A3 | User §8A4–A7 | Drawable frame/cache | Visible frame has one coherent revision/period identity; last drawable remains only on exceptional prewarm failure; cache is bounded/pinned. | Unit tests. | DONE |
| BDP-B1 | User §8B | Native prepared dashboard data | A sibling exact-revision partner snapshot with one grouped native read and compact versioned codec is provided. | Source audit + Flutter codec/runtime tests; Kotlin source test is queued for x86 CI because Termux AAPT2 cannot start. | DONE |
| BDP-B2 | User §8B1–B9 | Partner projection | Direction/time exact, Query/avatar independent, positive-only deterministic entries and authoritative/deterministic colours. | Projection/runtime tests. | DONE |
| BDP-C1 | User §8C–F | Shared distribution presentation | Category and partner use one Fluvi clay-donut generator, one layout/list primitive and matching geometry. | SVG/widget tests. | DONE |
| BDP-C2 | User §8G–J | Card2 local pager | Stable local PageController, two-dot parity and lazy infinite category↔partner domain. | Widget/controller tests, including 100 forward/backward logical PageView transitions and idle parity rebase. | DONE |
| BDP-C3 | User §8K–N | Gesture/readiness isolation | Both pages ready for time commit; local vertical list/horizontal PageView boundaries preserve avatar, LogBox and mode ownership. | Composite drawable-frame, card/pager and protected rail tests. | DONE |
| BDP-D1 | User §9/§13 | Architecture/performance boundaries | No widget aggregation/backend access; no selection-tick or page-swipe SVG prep/SQL/bridge; native only if required. | Source ownership audit, projection/visual-bank counters, focused Flutter tests and analyzer. | DONE |
| BDP-D2 | User §15 | Delivery | Three focused commits, pushed SHA, successful normal `lib/main.dart` APK and downloaded SHA-256. | GitHub Actions run 32247259743; `fluvi_HUMAN_DIAGNOSTIC_6260415.apk`; SHA-256 `cc629d15b41760ddeeaa7bbe9b2d40c4f4ae4e686e21d731be0076ee2741963b`. | DONE |

Reference: current Fluvi Budget distribution implementation on `2e952260`; read-only Spendee worktree `spendeetest@144d78c30dc4cc5e9f230903fd6274c98e62e118`.
