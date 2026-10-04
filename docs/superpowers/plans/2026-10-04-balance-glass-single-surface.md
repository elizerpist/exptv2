# Balance Header single-surface glass repair

Baseline: `d80bf76a0b08107d9ffb510d0f1f88ce530dc9af`; current documentation-only
branch head: `e3beb27d45ba26ee15b9f95f6c3128552fa6864c`.

The Android reference is
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20261004-131449.png`.
It is visual acceptance evidence, not a build-identity proof.

| ID | Requirement source | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BGF-01 | Current user glass prompt | `balance_header_glass_bar.dart` | One complete bar has one physical sample/material owner; income is not a second glass subtree. | `balance_header_glass_material_test.dart`. | DONE |
| BGF-02 | Current user glass prompt | bar material field | 25/75 changes only the material field/mask within the shared body and keeps a continuous sample basis. | `BGF-02` geometry and one-filter test. | DONE |
| BGF-03 | Current user glass prompt | native adapter | Deterministic high-contrast backdrop stays recognizably sampled and filtered, rather than becoming a flat white capsule. | Golden raster manually inspected. | DONE |
| BGF-04 | Current user glass prompt | native defaults | Production native default avoids the former broad `.20 + .22` white wash; highlight is rim/localized. | Config thresholds and golden. | DONE |
| BGF-05 | Current user glass prompt | native tuner/adapter | Every shown native control is consumed; tint colour and opacity visibly affect output. | Native rendered-color test; no-op grouping control removed. | DONE |
| BGF-06 | Current user glass prompt | renderer adapters | Each backend remains inside common geometry but uses its package-native material path rather than one copied white recipe. | All-adapter mount/default tests and source audit. | DONE |
| BGF-07 | Current user screenshot | production Header host | Real low-detail Header-like pastel backdrop preserves translucency, rim and material depth without an opaque white pill. | Header-like pastel golden manually inspected. | DONE |
| BGF-08 | Current user liquid gate | liquid adapter | Exact 1.8.1 API is source-audited; Premium behaviour is tested without speculative scope integration. | Locked package source and `BGF-08` widget coverage. | DONE |
| BGF-09 | Current user prompt | configuration/persistence | Renderer-local track/fill field settings, reset and persisted decode remain compatible. | Config encode/decode/reset tests. | DONE |
| BGF-10 | Current user prompt | Balance Header mount | Collapsed and line-chart modes mount zero glass; ratio/financial semantics and zero data stay exact. | `BGF-10` surface plus ratio tests. | DONE |
| BGF-11 | Current user prompt/milestones | protected controls | Header selector 0.5 gain, shared carousel, Summary and Avatar contracts are unchanged. | Protected suite and unchanged shared-motion diff. | DONE |
| ARC-01 | Global architecture gate | presentation configuration | Existing `BalancePresentationSettings` remains the only persistence/state owner; no financial/query authority changes. | Source audit and existing boundary/Balance suite. | DONE |
| DEL-01 | User delivery instructions | git/CI | One focused application commit descends from `e3beb27`; push, exact Human APK, final matching SCIP and journal-only child commit are delivered. | Git/CI/APK/graph evidence. | DONE |
| PHYS-01 | User prompt | Android device | Device glass appearance is personally accepted by the user. | User feedback only. | BLOCKED — USER ONLY |

## Architecture decision

`BalanceHeaderGlassBar` resolves geometry and financial ratio once.  A selected
renderer owns one clipped physical body and one package/native backdrop/sample
surface.  It receives both track and income material configurations plus the
ratio; it renders the income area as an internal material field/mask, never as
a second filter or `GlassContainer`.  Labels remain a sibling above that body.

For liquid 1.8.1, installed-source inspection establishes that `useOwnLayer`
is a valid per-widget path and that Impeller Premium uses the scene graph; a
global `LiquidGlassScope` is not added unless a failing targeted test proves a
need.  This repair intentionally does not alter the Header backdrop, shared
carousel, financial calculations, query/repository/index work or collapse
geometry.
