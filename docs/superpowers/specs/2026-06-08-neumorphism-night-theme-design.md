# Neumorphism And Night Theme Design

## Context

The app already has selectable theme colors and a shared `ExpenseSurface`
primitive for neutral, inset, and raised neumorphic surfaces. The current
settings expose separate button and content surface options, which creates too
many combinations and currently allows double tap feedback: the new shadow
animation and the old Flutter veil/ripple/highlight can both fire on the same
tap.

This design replaces the manual surface choices with two profiles and adds two
night palettes. It keeps the existing color options, activates the pink app
color in day mode, and applies neumorphism consistently across the home screen,
transaction sheets, recurring sheets, limit editor, category menu, and category
editor.

## Decisions

- Use a profile-based model: `designProfile` is `normal` or `neumorphism`.
- Use a separate night axis: `nightMode` is `off`, `cyan`, or `amber`.
- Keep the app color axis for day mode: `appColor` is `turquoise` or `pink`.
- Hide the old manual `buttonSurfaceStyle` and `contentSurfaceStyle` choices
  from the theme menu.
- Read old saved surface style values for compatibility, but resolve visible UI
  behavior from `designProfile`.
- Implement night colors as independent palettes. Night mode does not inherit
  the day `turquoise` or `pink` app color.

## Settings Model

`AppThemeSettings` gains:

- `designProfile`: default `normal`.
- `nightMode`: default `off`.
- `appColor`: default `turquoise`.

The existing `theme` value can be migrated into `appColor` for day mode. The
current `AppTheme.dark` path becomes obsolete for user-facing selection because
night mode has two explicit variants: `cyan` and `amber`.

Kotlin persistence in `ExpenseSettingsStore` stores and returns the new values.
Missing values must fall back to the defaults so existing installs keep the
original visual state.

Legacy migration rules:

- if `designProfile` is missing and both legacy surface style values are
  `neutralNeutral`, resolve `designProfile` as `normal`;
- if `designProfile` is missing and either legacy surface style value is
  non-neutral, resolve `designProfile` as `neumorphism`;
- if `nightMode` is missing and legacy `theme` is `Sötét`, resolve
  `nightMode` as `cyan`;
- otherwise missing `nightMode` resolves to `off`;
- legacy `Pink` and `Türkiz` theme values resolve to `appColor` in day mode.

## Theme Tokens

`ExpenseTheme` becomes the central source for role-based colors and surface
decisions. It should expose colors such as:

- `accent`, `accentDark`, `accentLight`, `activeBackground`.
- `appBackground`, `headerCard`, `logBox`, `fieldSurface`.
- `textPrimary`, `textSecondary`, `textMuted`, `border`.
- role-specific shadow colors for light and night neumorphism.

Day mode uses the selected app color:

- `turquoise`: existing `AppColors.primary` family.
- `pink`: pink family replacing app-level primary blue roles.

Night mode ignores `appColor`:

- `night cyan`: deep navy background, dark blue-gray surfaces, cyan accent.
- `night amber`: warm near-black background, warm brown surfaces, amber accent.

Category slot colors remain category colors. They are not globally replaced by
pink or night accents.

## Surface Rules

`normal` profile:

- All app interactions remain visually normal.
- `ExpenseSurface` press effects are inactive.
- Flutter `InkWell`/`InkResponse` highlight, splash, ripple, and existing veil
  behavior remain active.

`neumorphism` profile:

- Shadow/offset press effects are active.
- Flutter highlight, splash, and ripple are disabled or made transparent on
  controls using neumorphic press feedback.
- The slide-up focus veil can remain as panel background focus treatment, but it
  must not act as a button tap animation.

Component surface mapping in `neumorphism`:

- `insetInset`: transaction logbox body, search pill, summary pill, add/edit
  transaction input pills, recurring input pills, limit editor input pills,
  date/time pills, category menu card body, add/edit category name input,
  add/edit category preview log body.
- `raisedInset`: FAB, income/expense type pills, category button, header card
  down-arrow button, transaction logbox avatars, category card avatars, add
  category button, save buttons, backheader colored bars, color slots, icon
  slots.
- `neutralInset`: bottom nav at rest.
- forced inset: active bottom nav item, selected color slot, and selected icon
  slot. These stay inset while active or selected, not only during tap.

## Home Screen Behavior

The home screen uses the role-based theme and profile resolver for:

- income/expense type pills,
- summary pill,
- search pill,
- transaction logboxes,
- logbox avatars,
- header surface,
- header category button,
- header expand/down-arrow button,
- FAB,
- bottom nav.

The active bottom nav item must remain inset for as long as the user is on that
tab. Inactive nav items use the neutral-to-inset interaction in neumorphism.

The search pill text wrapper must have transparent fill in neumorphism so the
inner text field does not visibly differ from the inset parent surface.

The transaction logbox body becomes the single transaction edit tap target. A
tap anywhere on the logbox body opens the edit transaction card and triggers the
same inset body animation. The merchant name no longer opens a separate rename
dialog. The avatar remains the exception: tapping it triggers category filter
with raised-to-inset avatar feedback.

## Transaction, Recurring, And Limit Sheets

The add transaction, edit transaction, and recurring manager sheets receive
profile-aware field and button surfaces:

- name, amount, category selector, date, time, recurring fields, and all other
  pill-like inputs use inset surfaces in neumorphism.
- save buttons use raised-to-inset primary surfaces in neumorphism.
- normal profile keeps the existing Material field and button feedback.

Limit editor text input pills use inset surfaces in neumorphism. Limit editor
save actions use raised-to-inset surfaces.

The same no-double-trigger rule applies to these controls.

## Category Menu And Category Editor

The category menu card body uses an inset surface in neumorphism. Tapping the
card selects the category and animates the card body. The category card avatar
uses a raised surface and long press opens edit category with raised-to-inset
feedback.

Opening edit category from a long press must not close or slide down the
category menu behind it. The category editor appears over the category menu so
the context remains visible.

The category editor/add category sheet must sit above the bottom navigation.
If the home overlay layer cannot guarantee this, category editor opening should
route through the shell sheet host, matching add/edit transaction sheet
ownership.

In add/edit category:

- the name field is an inset pill in neumorphism,
- the color and icon slots are raised by default,
- tapping a slot animates raised-to-inset,
- the selected slot remains inset until selection changes,
- selected neumorphic slots do not use a border as their selected state,
- normal profile keeps the current selected border treatment,
- the preview log body is inset,
- the preview avatar is raised.

## Backheader

Backheader colored bars use raised surfaces in neumorphism. Tap and swipe
interactions animate raised-to-inset and return to raised unless the existing
backheader active state explicitly requires a selected visual. The existing
budget/category behavior remains unchanged.

## Pink Day App Color

The pink app color replaces app-level primary blue roles in day mode. This
includes FABs, primary buttons, active bottom nav color, selected/highlighted
pill outlines or fills, focus borders, filters, primary shadows, and other
app-highlight uses of the current primary color family.

The rollout should replace direct app-level `AppColors.primary`,
`primaryDark`, `primaryLight`, and `primaryActiveBackground` references in the
affected UI with role-based `ExpenseTheme` tokens. Category slot colors and
semantic income/expense colors are not replaced.

## Night Palettes

Night cyan:

- background: deep navy,
- card/log/input surfaces: dark blue-gray,
- accent: cyan,
- text: cool light gray,
- shadows: dark navy lowlights and muted cool highlights.

Night amber:

- background: warm near-black,
- card/log/input surfaces: dark warm brown,
- accent: amber,
- text: warm light gray,
- shadows: black lowlights and muted warm highlights.

Both night palettes use their own highlights and buttons. The day `appColor`
setting has no effect while night mode is active.

## Testing

The implementation should use focused red/green tests before code changes in
each phase:

- settings parsing, defaults, map serialization, and Kotlin persistence for
  `designProfile`, `nightMode`, and `appColor`,
- `ExpenseTheme` token resolution for turquoise day, pink day, night cyan, and
  night amber,
- normal profile resolves no neumorphic press effects and keeps Material tap
  feedback,
- neumorphism profile disables Material double feedback and uses shadow press
  feedback,
- active bottom nav item remains inset while active,
- selected color and icon slots remain inset while selected,
- search text wrapper is transparent in neumorphism,
- logbox body tap opens edit transaction and the merchant name no longer opens
  the rename dialog,
- logbox avatar still triggers category filtering,
- category edit sheet remains above the category menu and bottom nav,
- add/edit transaction, recurring, limit, and category editor fields use the
  expected profile-aware surface roles.

Full local verification should run the relevant Flutter tests. Local Flutter
APK builds are not expected in this Termux Android ARM64 environment. After
implementation, changes should be committed on a new branch and pushed to the
GitHub remote so GitHub Actions can build the APK. The final deliverable should
include the APK download link from the online build rather than a local
artifact.

## Existing Worktree Changes

The current worktree has unrelated local modifications in:

- `test/settings/settings_page_test.dart`
- `test/transactions/calendar_menu_widgets_test.dart`
- `test/transactions/calendar_render_builder_test.dart`

These files are treated as pre-existing user or prior-agent changes. This
design does not require reverting or overwriting them.
