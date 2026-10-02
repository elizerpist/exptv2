# Mind SUM card-window and Balance default repair checklist

Status values: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

## Mandatory visual sources

- Latest installed Android evidence:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261002-065937.png`
  - SUM-A shows only the first two rows of both years, with the third row
    falling below the temporal-content window.
- SUM references re-inspected for this repair:
  - `/storage/emulated/0/spendee/source of truth/suma.png`
  - `/storage/emulated/0/spendee/source of truth/sumb.png`

## Architecture card

| Concern | Existing owner | Repair decision |
| --- | --- | --- |
| SUM-A/SUM-B window allocation | `MindSumReferenceSurface` | Keep one shared 4×3 grid geometry, and make its explicit year-window height independent of Android's screen-level safe-area padding. |
| SUM-A/SUM-B cells | `_SumMonthGrid` | Keep one renderer and one 12-cell data path; do not add a style-local second grid or widget-local scrolling state. |
| Balance startup presentation | `BalancePresentationSettings` → `BalanceFourSectionLayout` → `DashboardPresentationPreferences` restore boundary | Make the canonical defaults choose the existing unified mother card and existing four-section layout; retain an already-persisted explicit user choice. The shared layout owns a capacity gate so a transient too-small dashboard frame retains its safe legacy body instead of clipping four live cards. |

## Acceptance checklist

| ID | Requirement / source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUMWINDOW-01 | Latest screenshot + `suma.png` | `mind_sum_reference_surface.dart` | SUM-A uses the real Mind content window: every year shows its 12 4×3 cells, fully above the fixed footer, without a down-offset or a clipped third row. | safe-area RenderBox regression test | DONE |
| SUMWINDOW-02 | User instruction + `sumb.png` | `mind_sum_reference_surface.dart` | SUM-B uses the same content-window contract: both mother cards, their identity cards, and all 12 cells remain wholly visible above the footer. | safe-area RenderBox regression test | DONE |
| BALDEFAULT-01 | User instruction | `balance_presentation_settings.dart` | A fresh controller defaults to `unifiedCard` and `fourSectionTetris`, so it renders one continuous Balance mother card with four child-card slots. | settings + surface/widget assertions | DONE |
| BALDEFAULT-02 | User instruction (“inicializálás után”) | preferences model/store + Core restore | Missing native preference uses the new default, while an explicitly persisted choice still restores intact. | focused preference/restore tests | DONE |
| SAFE-01 | Architecture gate | affected owners only | No duplicate grid/gesture/Query pipeline; Balance choice remains presentation-only. | source inspection + existing focused regressions | DONE |
| VIS-01 | Latest screenshot + source references | final installed Android app | Compare SUM-A and SUM-B against the phone safe-area on the exact delivered APK; all three rows must be visibly present. | fresh installed screenshot | NOT DONE |
| REL-01 | User delivery instruction | branch/release | App-code commit pushed; exact GitHub Human APK succeeds, is downloaded to `/storage/emulated/0/Download/fluvi`, and SHA-256 is recorded. | GitHub Actions + local hash | NOT DONE |

## Implementation invariant

The two SUM styles must lay all twelve cells only inside their explicit
width-derived 4×3 grid window. The embedded grid is not a screen-level
scrollable, so it must never borrow `MediaQuery` safe-area padding that
belongs to the surrounding phone viewport. More years remain owned by the
existing outer history scroll, but each rendered year remains a complete
12-cell unit.

## Verification evidence before release

- `SUMWINDOW-01/02` was RED with a 24 px `MediaQuery` top safe-area inset:
  December lay 24 px below the explicit grid window. It is GREEN after the
  embedded grid explicitly opts out of primary scrolling and inherited
  padding.
- Focused Mind, presentation-preference and Balance-settings suite: 22 tests
  passed.
- `BALDEFAULT-01/02` surface-focused run: 2 tests passed.
- `TET-03` was RED before the central capacity gate existed; it now proves the
  full four-child layout stays active for the normal 378×440 card body but
  cannot mount into a 164×80 transient body. The exact CI regression
  (`dashboard_rebuild_isolation_test.dart`) is GREEN after the gate.
- The CI-equivalent fast suite is GREEN: 434 tests passed.
- Targeted analysis of all seven changed code/test targets: no issues.
- Full analysis reports one pre-existing unrelated info-level import warning in
  `test/features/dashboard/application/dashboard_balance_daily_insights_projection_test.dart`;
  it is outside this change and is not modified here.
