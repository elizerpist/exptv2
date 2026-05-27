# Exptv2 Header And Category Management Design

## Goal

Implement the `expt0926` Stage0 header card and complete category management slice in `exptv2`: header card with category button, slide expansion behavior without FastInfo, category picker menu, add category menu, modify category menu, category cards, shared color slot manager, shared icon slot manager, and Kotlin-backed category CRUD.

## Source Behavior From expt0926

The header card is based on `backheader-stage0.js`:

- Header occupies the top 204 px of the screen.
- Background is light gray by default (`#f1f5f9`) with bottom-left and bottom-right radius 24.
- Header shadow uses black shadow, 4 px vertical offset, 0.15 opacity, 8 blur, Android elevation 12.
- `ExpenseTracker` label is at top 45, left 30, 14 px, 600 weight, `#1e293b`.
- Yellow chip is at top 75, left 30, 45x35, `#fbbf24`, radius 8, white border.
- Balance block is at top 129, left 30, right 90. It shows uppercase `Egyenleg`, then total balance and an eye toggle.
- Category button is at top 140, right 25, 48x48, radius 24, primary turquoise `#06b6d4`, shadow, and three white horizontal bars.
- Center arrow is 30x30, overlaps card bottom at top 189, turquoise, radius 15.

The category menu is based on `categorymenu.js`:

- Normal category menu starts at about y=286 and extends to the bottom-nav line.
- It has a white background, 30 px top radii, 1 px `#e2e8f0` border, no bottom border.
- Header height is 54 px and contains back button left, title centered, add button right.
- Menu title defaults to `Válassz kategóriát`.
- Add button opens category creation.
- Back/down arrow closes the menu.
- Categories are filtered by active transaction tab: income shows `bevétel`, expense shows `kiadás`.

Category cards are based on `categorycard.js`:

- Two-column grid with 20 px horizontal padding and 15 px vertical gap.
- Card width is roughly 48%.
- Card background is `#f8fafc`, radius 18, 20 px padding, top padding 85, bottom padding 18.
- Card border is `#e2e8f0`, 1 px.
- Card shadow uses black, 4 px vertical offset, 0.12 opacity, 6 blur, elevation 4.
- Icon circle is absolutely positioned at top 15, centered, 65x65, radius 32.5, category color slot background.
- Name is 15 px, weight 700, `#1e293b`, centered.
- Count text is 12 px, `#64748b`, centered, `<n> tranzakció`.
- Delete control is 24x24 at top 5, right 5. Red translucent if deletable, gray translucent if blocked by transaction count.
- Card tap applies a category filter. Icon tap/long press opens modify category.

Add and modify category menus are based on `addnewcategorymenu.js` and `modifycategorymenu.js`:

- They cover the same vertical range as the category menu, with y=286 start and bottom-nav line end.
- White background, 30 px top radius, 1 px border, no bottom border.
- Header height 50 px with back arrow and centered title.
- Title is `Új bevételi kategória` or `Új kiadási kategória`; modify uses `Kategória módosítása`.
- Content has 20 px horizontal padding, 30 px top padding.
- Name input label is `Kategória neve`; field is gray100, 25 px radius, 1 px gray200 border.
- Color/icon selector is one grid that switches between colors and icons via horizontal swipe.
- Color grid uses the exact 21 color slots from `SlotManager.colorConfig`.
- Icon grid uses 21 slots, but Flutter uses local asset icons through a new icon slot manager instead of the original React hardcoded SVG icon code.
- Preview pill uses white card, 25 px radius, 70 px min height, border gray200, small shadow, a 46 px colored circle, and the category name.

## Flutter Architecture

Flutter keeps the UI and interaction state. Kotlin remains the source of truth for persistence.

New Dart modules:

- `lib/features/transactions/slots/category_color_manager.dart`
  - Owns slot-to-color mapping for slots 0-20.
  - Replaces direct color lookup from `AppColors.slotColorHexes` for category UI.
- `lib/features/transactions/slots/category_icon_manager.dart`
  - Owns 21 icon slot asset paths.
  - Returns asset path by `iconSlot`.
  - No React hardcoded icons are copied.
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
  - Recreates Stage0 header card.
  - Owns local expand/collapse visual state and exposes category button callback.
- `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
  - Stack overlay for picker/add/modify states.
- `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
  - Header row plus category grid.
- `lib/features/transactions/widgets/category_menu/category_card.dart`
  - Individual category card design.
- `lib/features/transactions/widgets/category_menu/category_editor_panel.dart`
  - Shared add/modify menu body.
- `lib/features/transactions/widgets/category_menu/category_slot_grid.dart`
  - Swipeable color/icon grid.
- `lib/features/transactions/widgets/category_menu/category_preview_pill.dart`
  - Category preview pill.

The existing `TransactionHomePage` composes the header card above the transaction body and controls the category overlay state. The existing transaction type pills remain below the header card. FastInfo is intentionally omitted.

## Kotlin Architecture

The existing Room `transaction_categories` table already contains the cloned expt0926 fields. It will be extended with CRUD operations:

- Add category: validates non-empty name, normalizes type (`income`/`expense` to Hungarian), assigns next `transactionCategoryID`, stores slot values, and returns the inserted row.
- Update category: validates id and name, preserves existing type unless a new type is provided, updates slot fields and limit fields.
- Delete category: blocked if any transaction references that category; otherwise deletes the category.
- Category counts: returns transaction count by category id.

New MethodChannel methods on the existing `pushparser/methods` channel:

- `expenseAddCategory`
- `expenseUpdateCategory`
- `expenseDeleteCategory`
- `expenseCategoryCounts`

## Data Flow

1. `TransactionStore.start()` loads bootstrap data: categories and transactions.
2. Category counts are computed in Dart from loaded transactions for UI and also available from Kotlin for direct refresh.
3. Header category button opens `CategoryMenuOverlay` in picker mode.
4. Category card tap calls `TransactionStore.setCategoryFilter(category)` and closes the picker.
5. Add button opens editor in create mode.
6. Editor save calls `TransactionStore.addCategory()`, which calls Kotlin and reloads bootstrap.
7. Icon tap/long press on an existing category opens editor in modify mode.
8. Modify save calls `TransactionStore.updateCategory()` and reloads bootstrap.
9. Delete button calls `TransactionStore.deleteCategory()`; Kotlin blocks deletion if referenced by any transaction.

## Testing

- Dart model/store tests cover category CRUD payloads, category filtering, counts, and slot manager output.
- Widget tests cover header rendering, category button, picker menu, category card design basics, add category form, modify category form, delete blocked/enabled states, and category filter behavior.
- Kotlin build is verified only through GitHub Actions online APK build, per user instruction.

## Explicit Scope

Included:

- Header card Stage0 visual clone with expand slide behavior.
- Category picker menu.
- Add category menu.
- Modify category menu.
- Category card grid.
- Central color manager.
- Central icon asset manager.
- Kotlin category CRUD.
- GitHub online APK build after push.

Excluded for this slice:

- FastInfo.
- Stage1 budget bars and Stage2 diagrams.
- React hardcoded icon port.
- Budget limit editing UI.
- Local Android Gradle build on phone/proot.
