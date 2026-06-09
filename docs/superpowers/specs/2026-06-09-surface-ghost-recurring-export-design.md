# Surface, Ghost, Recurring And Export Design

## Goal
Keep the current `main` behavior intact while adjusting surface styling, simplifying ghost logbox design, adding date/time recurring controls, expanding category menu theming, and integrating only the Google export/sign-in pieces from `feature/google-sheets-sync`.

## Non-Negotiables
- `main` is the source of truth. Do not raw-merge `feature/google-sheets-sync`, because it is based on older code and would remove current push log, parser, notification, ghost, and settings behavior.
- Google functionality is cherry-picked by feature: export panel, CSV export, Google auth, Sheets sync controller/API/store, dependencies, manifest/build additions required by sign-in and file sharing.
- Existing parser, push log, notification listener, recurring transaction linking, merchant/category propagation, neumorph split, and ghost list behavior must not be reverted.

## Surface Model
The app keeps component-level surface control instead of a global design profile.

Button surface controls:
- Normal: flat/no press surface.
- Neutral-inset: flat at rest, pressed/inset on interaction. This restores the earlier bottom-nav neutral inward effect.
- Neumorph: raised at rest, inset on interaction.

Button surface applies to bottom nav items, header buttons, icon buttons, search filter capsules, category avatars, transaction avatars, ghost avatars, and ghost badges.

Logbox surface controls:
- Normal: flat card with border where appropriate.
- Neumorph: inset content card.

Logbox surface applies to transaction logboxes, ghost logboxes, content cards, category cards, and recurring rule cards where they behave like cards.

Category menu gets independent options:
- Menu background color: white, gray, dark gray.
- Menu background surface: normal or neumorph.
- Category card color: white, gray, dark gray.
- Category card surface: normal or neumorph.

## Ghost Logbox
The detailed ghost settings submenu is removed from the settings UI. Existing stored `ghostLogboxSettings` may still load for compatibility, but rendering uses the fixed design and the current button/logbox surface choices.

Every ghost logbox renders:
- `Varhato` label.
- A trigger icon: clock for time/date trigger, notification icon for push trigger. If trigger type cannot be known yet, default to clock.
- Avatar ghost badge.
- Gray merchant text and gray amount text.
- Reduced opacity for background/avatar/text.
- Normal logbox surface: dashed border.
- Neumorph logbox surface: no dashed border, no normal border.

Ghost rows stay pinned at the top of the monthly list. Display entries include date headers for the pinned ghost group. The same date can appear again later in the normal chronological section, so a June 6 ghost pinned above the list can have a June 6 header, and normal June 6 transactions can still appear under their own June 6 header in chronological order.

## Recurring Rules
Date/time trigger rules replace the raw expected day text field with the existing transaction date/time picker UI. The rule still persists a day-of-month-compatible value for native compatibility, and adds/uses an expected time where native support is added.

Push trigger rule form changes:
- Left pill: date picker pill for the expected date/day.
- Right pill: app selector pill.
- When an app is selected, its icon appears in the app pill.
- Push trigger does not require a time picker because it may arrive anytime that day.

Recurring ghost records already contain `date`, `time`, and `triggerMillis`, so the list UI can display the chosen time once native projection stores it.

## Category Menu Interaction
Opening the category menu must not disable manual downward dragging of the header card/FastInfo surface. The category overlay stays below the header interaction zone and must not consume gestures intended for the header.

The header category button must not show a distinct white top glow. Neumorph shadows for buttons and avatars should use black/gray shadow tones, not blue/cyan shadow tones.

## Google Export And Sign-In
Add export settings from the Google sync branch without replacing current settings pages:
- CSV save/share options.
- Google Sheets connect/sync/open/disconnect actions.
- Google sign-in uses `google_sign_in` and official Google visual branding on the sign-in/connect button.
- Sync writes transaction export rows to year sheets.
- App entry may restore existing sync state, but must not block app startup.

## Verification
Local Flutter and Android JVM builds are not expected to run on this Termux environment. Local verification uses static checks and git checks. Full analyzer, Flutter tests, Android unit tests, APK build, and release publication run through GitHub Actions after push.
