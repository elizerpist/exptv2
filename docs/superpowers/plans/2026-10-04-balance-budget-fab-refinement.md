# Balance / Budget / FAB refinement acceptance checklist

Reference inspected: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261004-154337.png`.

## Architecture card

| Concern | Single owner / extension | State and write path | Boundary |
| --- | --- | --- | --- |
| Balance Month/Year savings ring | `BalanceAlternativeSavingsRingCard` | Existing immutable `BalanceAlternativeSavingsPresentation`; no new state | Render-only card receives prepared scalar totals. |
| Balance simple income/expense lane | `BalanceHeaderIncomeExpensePartition` plus `DashboardPartitionLaneGeometry` tokens | Existing resident Balance totals and existing `BalancePresentationSettings.headerGraphPresentation` | Header renderer receives published totals only; no query/repository path. |
| Budget partition height | `DashboardBudgetHeaderPresentationProfile` | Existing controller `setPartitionHeightPercent` | Geometry only; Budget allocation data stays in the prepared partition. |
| FAB direction visual | `Bnb03BottomNavigation` | Existing `TransactionDirectionController` and `FluviGlobalAppearance.directionColorProfile` | Shell listens to existing owners; FAB owns no selection/persistence. |
| Direction gradient / FAB color resolver | `FluviDirectionColorPaletteCatalog` | Global presentation controller's existing direction-profile write path | The same semantic gradient drives the active direction pill and FAB. |

## Acceptance checklist

| ID | Requirement source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BAL-SAV-01 | User + latest screenshot | `balance_alternative_extended_sheet_cards.dart` | Month Savings ring uses available card space more fully while title, amount and percentage stay readable. | Shared-card geometry test + updated visual golden inspection. | DONE |
| BAL-SAV-02 | User + latest screenshot | `balance_alternative_extended_sheet_cards.dart` | Year Savings uses the same enlarged ring treatment. | Shared component golden + geometry test. | DONE |
| BAL-PART-01 | User | `balance_header_income_expense_partition.dart` | Simple Balance income/expense lane has the Budget limit lane's neutral empty track and an app softened-dark fill. | Widget decoration/token contract test. | DONE |
| BUD-PART-01 | User | `dashboard_budget_header_presentation.dart` | Height slider extends below the former 7px minimum to its authored 3.5px lower endpoint while the 7px baseline remains at 0%; upper sizing stays bounded. | Profile geometry unit test. | DONE |
| FAB-ASSET-01 | User | `assets/fluvi/actions/`, `pubspec.yaml` | Both supplied RGBA PNGs are copied byte-for-byte and declared through the existing Flutter asset directory. | SHA-256/file existence + widget asset test. | DONE |
| FAB-DIR-01 | User | `bnb03_bottom_navigation.dart`, `fluvi_app_shell.dart` | Income selection shows the income PNG; expense selection shows the expense PNG. | Widget test. | DONE |
| FAB-DIR-02 | User | `FluviDirectionColorPaletteCatalog` consumer in BNB-03 | The inner FAB has the active pill's left/middle/right colors in the same diagonal orientation; outer ring uses the middle color. | Resolver/painter test for income, expense and profile change. | DONE |
| FAB-DIR-03 | User | `fluvi_app_shell.dart` | Direction change reaches the FAB through the existing transaction-direction controller; no new source of truth. | Boundary test + source inspection. | DONE |
| ARC-01 | Global AGENTS.md | affected presentation files | No UI repository/query work; one existing state owner per setting and one central direction-color token resolver. | Fail-closed boundary/import test. | DONE |
| REG-01 | User | affected tests | Existing Budget progress, direction-pill, BNB/FAB, and Balance card behavior remains green. | Focused suites + 434-test fast suite. | DONE |
| DEL-01 | Global AGENTS.md | GitHub Actions | Application commit is pushed; exact online Human APK is downloaded and SHA-256 checked. | Run `37209966301`, release `fluvi-human-diagnostic-953d7fe`, local artifact checksum and ZIP inspection. | DONE |

## Reference re-read checkpoint

Before final build/commit, re-open the screenshot above and re-check every row.

## Follow-up acceptance checklist — 2026-10-04

### Architecture card

| Concern | Single owner / extension | State and write path | Boundary |
| --- | --- | --- | --- |
| FAB icon presentation | `FluviGlobalAppearance` + `DashboardHeaderVisualController` | One global presentation enum, updated through the existing `_setGlobalAppearance` path | BNB-03 renders supplied state only; it cannot own transaction direction or persistence. |
| Header partition size/position | `BalancePresentationSettings` plus a shared `BalanceHeaderPartitionGeometry` resolver | Existing Balance presentation controller writes both bar presentations; glass keeps its existing persisted vertical position | Both renderers consume resident Balance totals only. |
| Month/Year outer child-card gutters | `BalanceExtendedSheetLayout` | Pure layout-derived edge insets; no mutable state | The layout remains the sole owner of 70/30 slots and inter-card seam. |
| Savings ring footprint and label safety | `BalanceAlternativeSavingsRingCard` | Render-only from existing savings presentation | One shared Month/Year component; percentage is not rescaled down. |
| Balance header saturation default | `DashboardBalanceHeaderColorState.defaults` | Existing header tuning default and existing palette-variant selection path | Existing user changes still flow through `DashboardHeaderVisualController`. |

| ID | Requirement source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FAB-VIS-01 | User follow-up | `fluvi_global_appearance.dart`, header tuner | Options exposes mutually exclusive **Fehér bolt ikon** / **Artwork** FAB rendering choice through the existing global appearance owner. | RED→GREEN settings/controller widget + equality/default test. | DONE |
| FAB-VIS-02 | User follow-up | `bnb03_bottom_navigation.dart`, `fluvi_app_shell.dart` | Artwork uses a white inner FAB core and a direction-derived colored ring; legacy uses the former white store glyph and its legacy colored core. Both respond live to direction and profile. | RED→GREEN BNB visual resolver/widget test. | DONE |
| BAL-SIMPLE-02 | User follow-up | Balance tuner, settings, header renderers | Simple income/expense bar exposes and consumes the same Bar size and Vertical position controls as the glass bar; there is no duplicate geometry setting. | RED→GREEN controller/tuner/render geometry tests. | DONE |
| BAL-POS-02 | User correction | shared Balance header partition geometry | At vertical position 0, the lower edge of either Balance bar is exactly the expanded Header's safe bottom—the same lower baseline as Budget's header partition—not merely the old chart bottom. | RED→GREEN pure geometry + mounted bounds test. | DONE |
| BAL-CARD-01 | User + inspected screenshot | `BalanceExtendedSheetLayout` / section slot | Month/Year child surfaces touch the Mother Card's left and right content edges; only internal card seams remain. | RED→GREEN allocation-edge widget test + updated Month/Year goldens. | DONE |
| BAL-SAV-03 | User + inspected screenshot | `BalanceAlternativeSavingsRingCard` | Month/Year decorative Budget 3D ring is larger, the percentage font does not grow or shrink, and `100%`/three-digit percentages remain within the ring. | RED→GREEN sizing/overflow test + updated goldens. | DONE |
| BAL-DEFAULT-01 | User follow-up | `dashboard_header_balance_color_scale.dart` | Fresh Balance header color state defaults to **Telítettebb** / `saturated`; existing persisted selections are not remapped. | RED→GREEN default-state test. | DONE |
| ARC-02 | Global AGENTS.md | affected sources | No duplicate state owner, geometry resolver, query/repository access, or copied direction palette. | Extended fail-closed boundary test. | DONE |
| DEL-02 | Global AGENTS.md | GitHub Actions | One final production application commit is pushed and its exact Human APK is downloaded and hash-verified. | Run `37217684866`, release `fluvi-human-diagnostic-bf491ca`, SHA-256 `71e890905966b57268dffa9dd1d071c1d5130d79fe3a8112149e30e394f65c59`, ZIP inspection, embedded `bf491ca486b1a1c5169181dce3e219048a94cb03`. | DONE |

## Follow-up acceptance checklist — 2026-10-04 / Balance isolation and visual density

### Architecture card

| Concern | Single owner / extension | State and write path | Boundary |
| --- | --- | --- | --- |
| Budget Header colour fill | `DashboardCoreModeHeaderScaffold` physical shell | Budget selects zero visual inset through the existing Header primitive | No alternate Budget Header paint stack or colour source. |
| Artwork FAB physical shell | `Bnb03BottomNavigation` | Existing `FluviFabIconPresentation` and transaction-direction controller | Artwork has no coloured ring/core; legacy retains its existing shell. |
| Mind SUM default | `MindYearHeatmapPresentationSettings` and existing preference codec | Defaults and missing-preference fallback select `sumA`; explicit persisted values remain intact | No second Mind presentation owner or migration of a valid user choice. |
| Balance financial source during LogBox focus | `DashboardCoreController` | Existing unfiltered prepared base index feeds Header and linked Balance content | Focus remains a transaction-list concern; no repository/query work or focus-owned Balance presentation. |
| Balance density tokens | `BalanceAlternativeHtmlTokens` | Stateless render geometry for Cashflow/rhythm/annual closings | Existing prepared Balance data and temporal semantics remain unchanged. |

| ID | Requirement source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BUD-HDR-02 | User follow-up | `budget_dashboard_core_surface.dart`, Header primitive | Budget Header has no exposed white visual inset/outline and its colour fills its authored bounds like Balance. | Mounted Budget visual-inset test. | DONE |
| FAB-ART-03 | User follow-up | `bnb03_bottom_navigation.dart` | In Artwork mode there is no coloured ring or inner core; the selected PNG occupies the former visible ring footprint. Legacy white-store mode remains unchanged. | BNB geometry/layer test + inspected golden. | DONE |
| MIND-SUM-DEFAULT-01 | User follow-up | Mind settings and preference codec | Fresh/unpersisted Mind SUM starts as SUM-A, while explicitly stored styles round-trip unchanged. | Settings + preferences tests. | DONE |
| BAL-FOCUS-01 | User follow-up | `DashboardCoreController` Balance publication | Category or partner transaction-list focus never clears or narrows Balance Header or linked Balance content. | Focused prepared-core category/partner regression. | DONE |
| BAL-DENSITY-01 | User follow-up | Balance alternative SUM/Day tokens | Cashflow stability and comparison rhythm use the available horizontal card space without changing data/semantics. | Mounted geometry tests + inspected goldens. | DONE |
| BAL-YEAR-01 | User follow-up | annual-closings painter/legend tokens | Year bars are materially wider and month labels slightly larger while remaining non-overlapping. | Token/painter test + inspected annual golden. | DONE |
| ARC-03 | Global AGENTS.md | affected sources | The follow-up uses existing setting/controller/token owners and introduces no repository/query paths or duplicate UI engines. | Source inspection + focused analysis/tests. | DONE |
| DEL-03 | Global AGENTS.md | GitHub Actions | One app commit is pushed and the exact online Human APK is downloaded, hashed and identity-checked. | Actions `37225041605`; release `fluvi-human-diagnostic-41ed1fd`; SHA-256 `4ab40b86eb1e0f6b07426081188bc011b8f3488bac2a3753faeb585471336a5d`; ZIP and embedded commit inspection. | DONE |
