# 2026-07-09 Post-Build Design Bugs Checklist

Scope: collect user-reported design regressions after the `686f02a` build. No fixes should be implemented until the user says the checklist is complete and coding may start.

## Items

### PBD-001 - Category sheet bottom/nav layering and real screen bottom

- Source instruction: "a kategória sheet nem fedi a bottom navot, a bottom nav fedi a sheetet, nem ezt kértem, statisztika esetében a hottom nav tetejét észleli a screen aljának, nem a valódi screen alját"
- Intended code area: category sheet presentation/layout; app shell bottom navigation layering; stats category sheet bottom/inset calculation.
- Acceptance condition: the category sheet uses the real screen bottom as its bottom boundary in both main menu and stats, and the bottom navigation must not truncate, redefine, or sit above the sheet as the active covering layer.
- Verification method: inspect implementation for bottom inset/safe-area calculations; run targeted widget/layout tests for main and stats category sheet geometry; verify with Android screenshot or device run that the sheet extends to the real screen bottom and the bottom nav does not visually cover the sheet.
- Status: DONE
- Verification evidence: moved the shared category picker into the shell overlay through `CategoryMenuSheetRequest`, so the main and stats sheets use the real screen bottom instead of the tab body bottom; kept the app chrome behind the sheet layer; added/passed geometry regressions in `test/widget_test.dart` for main category sheet, stats category sheet, and add-category editor stacking; verified with full `flutter test` (`+672: All tests passed!`), `flutter analyze` (`No issues found!`), and `git diff --check`.

### PBD-002 - Mentok skin belongs to theme/magnet strip, not backheader, and must not override stats strip

- Source instruction: "a mentős skin nem a backheader része, oda tetted, ez a téma része, és egy mágnescsík skin, tehát ha a user a statisztikába lép, az már a statisztika custom mágnes csíkot mutassa, jelenleg mindent felülír"
- Intended code area: theme settings/options; magnet strip skin model/rendering; backheader style options; stats custom magnet strip selection/rendering.
- Acceptance condition: the Mentok/ambulance skin is removed from backheader style selection and represented as a theme-level magnet strip skin option; entering statistics shows the statistics-specific custom magnet strip instead of being globally overridden by the Mentok skin.
- Verification method: inspect settings/model wiring to confirm Mentok is not a backheader option; run targeted widget tests for theme/magnet strip options and stats magnet strip rendering; verify manually or via screenshot that stats keeps its custom magnet strip when the Mentok theme/magnet skin is selected elsewhere.
- Status: DONE
- Verification evidence: removed the legacy `BackheaderStyle.ambulanceSkin` option and migrated legacy settings to `MagnetType.ambulanceSkin`; added the settings option as `Mentők mágnescsík`; changed header rendering to apply the ambulance skin from `magnetType`; kept stats custom magnet gradients ahead of the ambulance fallback; verified no stale backheader ambulance symbols with `rg`, and covered with settings/header/stats widget tests in the full `flutter test` run (`+672: All tests passed!`).

### PBD-003 - Add transaction save button bottom placement failed

- Source instruction: "az addnewtransaction ... sheettel kapcsolatban ... egyik sem sikerült" referring back to: "új tranzakció sheeten a mentés gomb túl fent van, kötvetlen a safety zone tetején legyen (mint a kategory sheet beállítás gombja)"
- Intended code area: add-new-transaction sheet footer/action layout; safe-area/bottom inset handling.
- Acceptance condition: the add-new-transaction sheet save button is fixed directly above the bottom safety zone, matching the category sheet action button vertical placement.
- Verification method: inspect layout code for fixed footer outside scroll content; run targeted widget/layout test for footer bottom position; verify with Android screenshot that the save button is not too high and sits directly above the safety zone.
- Status: DONE
- Verification evidence: moved the add-transaction save action into a fixed footer keyed as `transaction-save-footer`, with the scroll/body area constrained above it and bottom placement tied to the safety-zone offset; added a widget geometry regression in `test/widget_test.dart`; verified with full `flutter test` (`+672: All tests passed!`) and `flutter analyze` (`No issues found!`).

### PBD-004 - Recurring sheet add-rule button and scroll area layout failed

- Source instruction: "az addnewrecurring transaction sheettel kapcsolatban ... egyik sem sikerült" referring back to: "a recurring sheetben a szabály hozzáadása a scroll része. ne legyen az, ez is a safety zone tetején legyen konstans. felette a scroll areát úgy igazítsd, hogy ne fedje az alsó gomb"
- Intended code area: recurring transaction sheet footer/action layout; scroll area constraints; safe-area/bottom inset handling.
- Acceptance condition: the recurring sheet add-rule button is a fixed footer directly above the bottom safety zone, not part of the scroll content; the scroll area ends above the fixed footer and cannot be covered by it.
- Verification method: inspect layout code for fixed footer and adjusted scroll padding/constraints; run targeted widget/layout test for footer placement and scroll extent; verify with Android screenshot that the button is constant and the scroll content does not run underneath it.
- Status: DONE
- Verification evidence: moved the recurring add/save action into a fixed footer keyed as `recurring-manager-footer`, kept the scroll area above the fixed footer, and retained bottom scroll padding so content cannot hide beneath the button; added a widget geometry regression in `test/widget_test.dart`; verified with full `flutter test` (`+672: All tests passed!`) and `flutter analyze` (`No issues found!`).

### PBD-005 - Category neumorphism behavior failed

- Source instruction: "milyen neumorphismal kapcsolódó utasítás volt?" followed by "nem sikerültek. oldd meg, írd fel, és kódolj, győződj meg hogy biztos implementálod"
- Intended code area: shared category sheet/card rendering; category card press/tap/long-press behavior; category design settings model and UI; main and stats category menu integration.
- Acceptance condition: the category sheet itself is never neumorphic; category cards may use neumorphism only through the shared normal/on logic; selected multi-filter cards remain visually pressed/on until the user applies filtering; the whole card responds to tap and long press, not only the avatar; highlighted cards show border only with no veil/overlay; main and stats use the same category card neumorphism/color settings; obsolete category-specific design/shadow settings are absent.
- Verification method: add focused widget tests for shared category card/sheet behavior and settings visibility; run targeted category/settings tests; inspect production code for removed obsolete settings and no separate main/stats card variants.
- Status: DONE
- Verification evidence: added failing regression tests for raised neumorph category card shadows and persistent border-only selected category state; confirmed RED in `flutter test test/transactions/category_menu_test.dart`; implemented shared `categoryNeutralShadow` and `CategoryActiveBorder`; removed unused category active background/veil parameter from main and stats category sheet wiring; verified with focused category/settings tests, full `flutter test` (`+672: All tests passed!`), `flutter analyze` (`No issues found!`), `git diff --check`, and `rg` inspection for stale category active background/shadow settings.
