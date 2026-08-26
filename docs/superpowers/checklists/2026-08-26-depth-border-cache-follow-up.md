# Dashboard depth, border and cache-parity follow-up acceptance checklist

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| D3D-01 | User Task A | Header depth composition | Reference3D preserves the authored Header fill/gradient; only depth/border vary. | `dashboard_corner_roundness_scope_test.dart` Header material regression | DONE |
| D3D-02 | User Task B | LogBox custom painter | Fill, contour, dark depth and white foot use identical swipe `dx`; snapback has no ghost. | `dashboard_logbox_partner_swipe_gesture_test.dart` material-lease/swipe regression | DONE |
| DBR-01 | User Task C | Border profile/controller | SearchPill's current `#E2E8F0`, 1px, in-bounds BoxDecoration border is centralized. | `dashboard_border_profile_test.dart` source-contract unit test | DONE |
| DBR-02 | User Task C | Tuner/scopes/surfaces | Header, income, expense, summary, search, Balance, Mind, Budget and LogBox have independent toggles with default-compatible values. | Border profile, tuner and surface regression tests | DONE |
| DBR-03 | User Task C | All surface renderers | Borders are paint-only, follow selected radii, and compose once with all four shadow modes. | Bounds/matrix/LogBox swipe tests | DONE |
| BUD-01 | User Task D | Budget geometry/surface | Unified selected avatar maximum painted extent has positive top-card clearance and no lower collision. | `budget_dashboard_core_surface_test.dart` geometry regression | DONE |
| BUD-02 | User Task D | Budget Split | Split avatar geometry/controller/preview behavior is unchanged. | Budget avatar/surface/pager regression suite | DONE |
| PAL-01 | User Task E | Amount palette model | Income and expense each expose current Fluvi, Fluvi category, Spendee Budget and Spendee Balance source options with pinned provenance. | `dashboard_logbox_amount_palette_test.dart` source-contract tests | DONE |
| PAL-02 | User Task E | LogBox paint binding/tuner | Independent selections affect only transaction amount foreground, with no query, geometry or scroll reset. | Prepared-row identity and palette-controller tests | DONE |
| VPT-01 | User Task F | Ledger/layout geometry | The handle-to-count gap equals exactly half its baseline metric. | `dashboard_geometry_resolver_test.dart` metric regression | DONE |
| VPT-02 | User Task F | LogBox viewport | The reclaimed exact delta increases viewport height while outer envelope and row-height selection remain unchanged. | Geometry/viewport regression tests | DONE |
| NAV-01 | User Task G + Fluvi Logs r39 | Diagnostics/control | Legacy, Segmented and BudgetAvatar emit comparable target/key/cache/publication traces for equivalent targets. | Presentation canonical-candidate, zero-I/O and ephemeral-focus tests | DONE |
| NAV-02 | User Task G | Transition/cache owner | Cache-hit Segmented/BudgetAvatar crossings use the Legacy canonical key/cache owner, make no repository call, and publish without settle wait. | `dashboard_presentation_controller_test.dart`, zero-I/O and focus regressions | DONE |
| NAV-03 | User Task G | Miss/stale behavior | Rapid A→B→C→D remains free-running, bounded/coalesced and stale-safe across years/months/days. | Segmented widget fling, scene-window, coalescer and stale-generation regression tests | DONE |
| REG-01 | User protected boundaries | Dashboard | Summary variants, body order, rail policies, corners, shadow styles, row-height behavior, SearchPill and Budget preview parity remain intact. | 330-test relevant dashboard/motion regression run | DONE |
| DOC-01 | User Documentation | Active docs/checklist | Root causes, source values, defaults, geometry deltas and trace evidence are recorded without declaring cosmetic winners. | Plan/spec/checklist review | DONE |
| DEL-01 | User delivery + AGENTS | GitHub/action APK | One focused app commit is pushed; exact human diagnostic Android APK is downloaded and SHA-256 verified. | Git/Actions/download evidence | NOT DONE |
