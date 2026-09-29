# Restore Balance Child Layout Design

## Approved objective

Keep the current shared, SUM-derived Mother Card size exactly as it is. Restore
only the former Balance Havi and Éves child-card layout, child content, and
charts. The HTML prototype is the authoritative child-layout reference; it is
not an authority to resize the Mother Card.

Budget must still initialize in its large unified card mode. Mind's action-row
spacing below the Mother Card must use the same lower padding as Budget, so
its Bevétel/Kiadás controls no longer sit higher.

## Sources and evidence

- User-approved requirement in this conversation.
- Current correct Mother Card height: Balance SUM screenshot
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-081112.png`.
- Earlier Havi and Éves app layouts to restore:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-061344.png`
  and `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-061349.png`.
- HTML child-layout reference:
  `html-prototypes/balance-extended-sheet-baseline/index.html`.
- Pre-height-patch child-layout implementation:
  commit `685c53430687af0b173d282edafcb1fec8ef8090`.

The HTML and pre-height-patch `BalanceExtendedSheetLayout` agree on this exact
body grammar:

| Child | Position and size within the content body |
| --- | --- |
| Card 3 | top-left, 70% width x 60% height |
| Card 4 | top-right, 30% width x 30% height |
| Card 5 | middle-right, 30% width x 30% height |
| combined | bottom, 100% width x 40% height |

## Architecture card

### Single sources and write paths

| Concern | Owner | Rule |
| --- | --- | --- |
| Mother Card outer height | `DashboardContentCardHeightPolicy` through `DashboardGeometryResolver` and `DashboardHeaderContentMotherCardBounds` | Preserve unchanged; no Balance renderer may alter it. |
| Havi/Éves child rectangles | `BalanceExtendedSheetLayout` | Restore the HTML/pre-patch 70/30, right-stack, full-bottom grammar. |
| Havi/Éves child rendering | `balance_alternative_extended_sheet_cards.dart` and `balance_alternative_visual_tokens.dart` | Restore only the renderer behavior needed by the former child cards and charts; retain the fixed parent body. |
| Budget initial composition | `BudgetContentCardStyleController` | Existing default remains `BudgetContentLayout.unifiedCard`. |
| Mother-to-action-row lower spacing | shared `DashboardGeometryResolver` | Derive Mind's settled action anchor from the existing canonical Mother Card lower edge, matching Budget. |

No repository, query, financial, navigation, persistence, or gesture ownership
changes. UI remains a geometry consumer; the existing controllers retain all
state ownership.

### Reuse and centralization decision

There is already one shared outer-height policy and one shared Mother Card
bounds resolver, so no feature-local height, padding, or action-row offset is
permitted. `BalanceExtendedSheetLayout` is the one Balance-specific child
layout owner and is restored in place. The existing Budget layout controller
remains the one default-state owner.

## Chosen implementation

1. Restore `BalanceExtendedSheetLayout` to its pre-height-patch child
   rectangle grammar. The fixed canonical body rectangle is still passed in;
   no outer layout is reverted.
2. Restore the matching Havi/Éves child renderer/chart composition from the
   pre-height-patch version, including the HTML-defined fixed Havi
   income/expense strip row. Do not reintroduce a Mother Card height exception
   or a whole-card `FittedBox` fallback.
3. In shared geometry, anchor the settled seamless Mind action row from the
   canonical Mother Card lower edge plus the existing dot-flow tail and standard
   gap. This makes its lower padding equal the settled Budget Mother Card's
   lower padding while preserving the collapsed anchor.
4. Keep Budget's `unifiedCard` constructor default and no-dot behavior.

## Verification

- A failing geometry test first proves the old right-stack/full-bottom child
  rectangle grammar and proves all child rectangles stay inside the current
  fixed body rectangle.
- A focused test first proves the shared Mind and Budget action anchors have
  equal lower padding from their canonical Mother Card bounds.
- Existing focused Balance Havi/Éves card/golden tests, Budget default tests,
  and dashboard geometry tests run in Ubuntu proot.
- Inspect updated Havi and Éves goldens and the actual Android screenshots.
- Commit, push, monitor the exact GitHub human APK job, download the normal
  APK to `/storage/emulated/0/Download/fluvi`, and verify SHA-256.
