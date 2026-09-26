# Balance carousel, Top kategória detail and BottomNav clamp acceptance checklist

Status legend: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

This checklist records the approved requirements in the 2026-09-26 user
prompt **FLUVI — BALANCE CAROUSEL LAYOUT UNIFICATION + TOP CATEGORY DETAIL
PAGE 2 REWORK + FLAT BOTTOMNAV BODY-SIZE CLAMP**. The supplied reference
images are guidance only; the written prompt is authoritative.

| ID | Source | Owner / intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BCL-01 | §2.1–2.5 | `balance_dashboard_core_surface.dart` | Every Balance carousel item uses one title + visual + two-line-information grammar, including icon-only topics. | Rendered widget keys, focused carousel test and selected-card golden. | DONE |
| BCL-02 | §2.3 | `balance_dashboard_core_surface.dart`, shared prepared formatter | Latest, Top partner and Top kategória use compact money; mover secondary is percentage only. | Pure card-model and widget tests. | DONE |
| BCL-03 | §2.4 | `balance_dashboard_core_surface.dart` | Cashflow, Zárások, momentum, retention and stability use semantic icons without a second layout family. | Widget structure test. | DONE |
| BCL-04 | §2.5 / protected milestone | `balance_dashboard_core_surface.dart`, `CenteredCarousel` consumer | Canonical content does not change carousel controller, scroll position, physics or topic semantics. | Existing rail regression, focused identity test and fast suite. | DONE |
| TCD-01 | §3.1–3.2 | `balance_linked_detail_card.dart` | Page-2 return rhythm equals page-1 title rhythm and hero starts in page-1 leader band. | Mounted geometry test. | DONE |
| TCD-02 | §3.3–3.5 | `balance_linked_detail_card.dart`, category palette resolver | Median and MEDIÁN pill use the selected category colour; median is page-1-leader-aligned on the right; metrics are compact chips below hero. | Mounted styles and rects test. | DONE |
| TCD-03 | §3.6–3.7 | `balance_linked_detail_card.dart` | Segment section consumes the lower card coherently, has no excess bottom dead area, and preserves data semantics at both the large harness and the real ~210px lower-card envelope. | Mounted geometry/distribution tests and both inspected goldens. | DONE |
| FBC-01 | §4.1–4.5 | `dashboard_shell_presentation.dart`, `core_dashboard.dart` | Stretch derives the exact count-safe delta from resolved Dashboard/BottomNav geometry; it is not guessed from FAB artwork pixels. | Pure layout test at reference and device-like viewports. | DONE |
| FBC-02 | §4.1–4.3 | same plus `FluviAppShell` | Count row stays entirely above the rendered BottomNav with its breathing gap; SearchPill meets the physical nav edge. | Pure relationship test plus real app-shell rect regression for both targets. | DONE |
| FBC-03 | §4.4–4.5 | common geometry / `DashboardMotionHost` inputs | Balance, Mind and Budget share the same clamped delta and existing target choice/motion behavior. | Cross-mode geometry regression. | DONE |
| SCOPE-01 | §6 | all touched files | No Query, repository, financial/ranking/median logic, BottomNav behavior or carousel engine changes. | Source boundary test, diff review and focused regressions. | DONE |
| BUILD-01 | user delivery instruction | exact final application SHA | All implementation rows are `DONE`; application SHA `601c3e80…` is pushed; normal Human APK was built online, downloaded to `/storage/emulated/0/Download/fluvi`, hash-checked and its embedded source identity verified. | Actions `36244018984`, APK SHA-256 and ARM64 payload inspection. | DONE |
| PHYSICAL-01 | user delivery instruction | user device | New APK physical validation. | User-only verification. | NOT DONE |

## Architecture card

- **State / write path:** No new state. `DashboardBalanceLinkedPresentation`
  remains the immutable data input. `DashboardFlatBottomNavStretchLayout`
  remains the one pure shell-to-dashboard geometry bridge.
- **Shared mechanisms reused:** existing `CenteredCarousel` remains the sole
  rail/gesture/physics owner; `BalanceCategoryVisualBadge` and the category
  avatar palette resolver remain the only category-visual authority; the
  prepared formatter becomes the one compact-HUF formatter if no existing
  shared formatter is suitable.
- **Rendering boundary:** Balance widgets only map immutable presentation data
  to a local visual model. They perform no repository, Query, prepared-index,
  or projection work.
- **Visual proof:** the two reference files remain at
  `/storage/emulated/0/spendee/reference/balancecarousel.png` and
  `/storage/emulated/0/spendee/reference/topcategory.png`; they were inspected
  before implementation and were rechecked before final visual handoff. The
  production-height category-detail golden additionally guards the resolved
  210px lower-card envelope.
