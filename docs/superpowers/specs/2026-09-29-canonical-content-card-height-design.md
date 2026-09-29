# Canonical Dashboard Content Card Height Design

## Approved objective

At the settled expanded endpoint, every Dashboard content Mother Card has one
and only one physical height. The current Balance SUM Mother Card at the
active viewport and shell configuration is the authority. Mind, every Balance
scope (SUM, Havi, Éves, Nap), and every Budget composition must use the same
outer bounds. This explicitly supersedes the previous Havi/Éves decision that
extended the outer card to the HTML prototype's 1187px Mother Card height.

The canonical Havi/Éves HTML prototype remains authoritative for the inner
card grammar, typography, spacing, padding, colours, and charts. Where the
fixed SUM body leaves less vertical space, only flexible plot/drawing regions
may contract. Text, CSS-derived padding, card-wide scale, and FittedBox
fallback at the reference viewport are not permitted.

## Evidence and references

- Canonical outer-height authority: current Balance SUM device state,
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-081112.png`.
- Mismatching Mind state,
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-081318.png`.
- Mismatching Havi and Éves states,
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-061344.png`
  and `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-061349.png`.
- Inner Havi/Éves reference:
  `html-prototypes/balance-extended-sheet-baseline/index.html`.
- Current owners:
  `lib/core/design/dashboard_geometry_resolver.dart`,
  `lib/features/dashboard/presentation/core_dashboard.dart`, and
  `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`.

## Root cause

`DashboardHeaderContentMotherCardBounds` is already shared by the settled
Mind, Balance, and unified Budget renderers, but it receives a
mode-dependent `subheaderEnvelopeBounds`. That means it cannot enforce a
shared height.

Three separate inputs make the envelope different today:

1. `CoreDashboard` passes Balance Havi/Éves
   `principalModeContentExtraHeight` into `DashboardGeometryResolver`.
2. Budget's chart-then-avatar composition passes
   `BudgetSectionOrder.chartThenAvatarsExtraModeContentHeight`.
3. Mind passes a reveal factor to the shared Mother Card bounds resolver while
   the settled Balance and Budget paths use its default full reveal.

Budget additionally defaults to `BudgetContentLayout.split` and renders
`BudgetDistributionPageDots` / `DashboardPlaceholderDots` in every
composition.

## Architecture card

### Single source and write path

| Concern | Owner | Single write path |
| --- | --- | --- |
| Settled outer Mother Card height | a new neutral policy adjacent to `DashboardGeometryResolver` | derived once from the Balance SUM baseline geometry for the active metrics and shell state |
| Mother Card bounds | `DashboardHeaderContentMotherCardBounds` | every renderer consumes the policy-derived canonical bounds |
| Mode-specific inner placement | existing Balance, Budget, and Mind layout adapters | consumes the fixed outer body rectangle; may not alter the outer height |
| Budget initial composition | `BudgetContentCardStyleController` | constructor default is `unifiedCard` |
| Budget page-dot presence | Budget surface renderer | no Budget dots subtree is constructed |

The policy is presentation-only. It owns no financial, navigation, query,
selection, persistence, cache, or animation-controller state.

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision |
| --- | --- | --- | --- |
| Outer Mother Card bounds | `DashboardHeaderContentMotherCardBounds` | all modes have the same settled outer height | extend the existing shared bounds/geometry path; do not create per-mode offsets |
| Geometry frame creation | `DashboardGeometryResolver` | content envelope is derived centrally | remove mode-specific outer-height expansion from Core inputs |
| Havi/Éves card rectangles | `BalanceExtendedSheetLayout` | 70/30 and 60/40 inner card grammar | retain it; give it the fixed canonical body rectangle |
| Budget composition selection | `BudgetContentCardStyleController` | one session-default write path | change its existing default rather than adding initialization code in a widget |

### State and dependency boundary

`CoreDashboard` supplies immutable geometry to `DashboardMotionHost`;
`DashboardMotionHost` resolves the frame through `DashboardGeometryResolver`;
Mind, Balance, and Budget are rendering leaves. No new state or I/O path is
introduced. Budget's existing user-selected layout and section-order
controllers continue to work, but cannot request a different outer height.

## Chosen behavior

1. Resolve one canonical expanded content-envelope height from the same
   metrics, rail state, and shell state used by Balance SUM. Every stable
   content Mother Card uses that exact height and lower edge.
2. Delete the Balance Havi/Éves outer-height exception and prevent Budget
   section ordering from expanding the global content envelope.
3. Use the same full settled reveal in the shared outer-bounds calculation;
   transition opacity/position remains mode-owned and does not alter the
   settled target geometry.
4. Preserve Havi/Éves HTML padding, typography, and inner 70/30 + 60/40
   grammar. The direct renderer reallocates only flexible chart canvas space
   inside a fixed card; it never scales the complete card.
5. Change Budget's controller default to the large unified Mother Card and
   remove the Budget dots subtree and its tests. The old split selection may
   remain as a tuner choice, but its content envelope is still canonical.

## Verification

- A geometry/unit test proves the canonical policy equals the Balance SUM
  baseline and is invariant across Mind, every Balance scope, both Budget
  layouts, and both Budget orders.
- Widget tests compare real Mother Card rectangles at the reference viewport;
  their bottom edges must match within 0.01 logical px in the settled state.
- Havi and Éves widget/golden tests prove source typography and padding remain
  direct-rendered with no card-wide `FittedBox`, while both plots fit inside
  the fixed SUM-height Mother Card.
- Budget tests prove a fresh controller initializes to `unifiedCard` and no
  `dashboard-core-mode-budget-dots`, `BudgetDistributionPageDots`, or Budget
  placeholder dots are mounted.
- Final device screenshots cover Balance SUM, Havi, Éves, Mind, and Budget;
  their Mother Card top/bottom frame must match the SUM frame at the same
  screen state. Flutter tests/analysis run in Ubuntu proot. The production
  APK is built on GitHub Actions, downloaded to `/storage/emulated/0/Download/fluvi`,
  and SHA-256 verified.
