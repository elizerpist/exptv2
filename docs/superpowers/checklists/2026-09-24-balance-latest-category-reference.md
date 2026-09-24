# Balance Latest + Category Reference Redesign — Acceptance Checklist

Reference image (visual authority for CAT only):
`/storage/emulated/0/spendee/reference/last_transacrion.png`

- Size: 941 × 1672 px
- SHA-256: `803cd2f17f81e21a26a0d1b6462361b16f9313a7d156f2ca7f21570dcfc11f4b`
- Runtime dependency: forbidden

| ID | Requirement source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| REF-01 | Approved local PNG | Reference audit | Exact PNG is uniquely resolved, hashed, dimensioned, and visually inspected before source edits. | Filesystem metadata + visual inspection | DONE |
| ARCH-01 | Task §§10,16 | Linked presentation / Balance UI | Existing immutable linked-presentation and local lower-card state remain the only data/navigation authorities. | Source review + mounted tests | DONE |
| LDTO-01 | Task §§10,15–16 | `dashboard_balance_primary_projection.dart` | Latest DTO exposes admitted canonical category color/icon metadata without a widget lookup. | Projection RED→GREEN test | DONE |
| LSMALL-01 | Task §§6,15–16 | `balance_dashboard_core_surface.dart` | Latest compact card has precisely topic/title, avatar/title, date hierarchy; it has no amount. | Mounted carousel test | DONE |
| LMAIN-01 | Task §§6,14–16 | `balance_linked_detail_card.dart` | Up to five Latest rows fit together with avatar, partner/title, category/date, and signed right amount; no internal scroll, dividers, or row strips. | Production-parent bounds/widget test | DONE |
| CAT-01 | Approved PNG + Task §§2–4,6,15–16 | `_CategoryInsightDetail` | Native fixed detail follows PNG hierarchy: Back, rounded-square avatar/name, MEDIÁN hero, metric pills, divider, distribution. | Visual source audit + deterministic widget geometry assertions | DONE |
| CAT-02 | Task §§6,15–16 | `_CategoryInsightDetail` | Uses existing median, retains count/active days/four bands, removes total/share/temporal profile/dominant-percent text. | Median-vs-total fixture + widget test | DONE |
| CAT-03 | Task §16E | Category detail | Existing low-sample DAY truthfulness remains; no fabricated distribution. | Focused source/test review | DONE |
| STATE-01 | Task §§14–15 | `_RankedDetailState` | Back is local; replacement with a missing selected entity returns to overview without stale data. | Existing and updated interaction tests | DONE |
| BOUNDS-01 | Task §§14–15 | Balance lower card / carousel | No overflow, target cards contain no internal scroll; carousel controller, position, physics, order and three-visible behavior are unchanged. | Mounted production-parent regressions | DONE |
| PERF-01 | Task §17 | Projection / presentation | No repository, Query, index, scene, timer, ticker, async, or PNG runtime work is added. | Source review + existing no-source-work tests | DONE |
| REG-01 | Task §§13,19 | Protected systems | fef Header work, non-target Balance topics, Mind, Budget, geometry, carousel mechanics and Movers remain untouched. | Diff + focused regression suites | DONE |
| DEL-01 | Task §§19–20 | Delivery | Atomic app commit, separate journal-only commit, exact-source CI/APK, and separate exact-source SCIP are recorded. | Git/CI/APK/graph evidence | NOT DONE |
| PHYS-01 | Task §§20–21 | Device review | Android visual/touch acceptance remains user-only. | User validation | BLOCKED — USER ONLY |
