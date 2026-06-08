# Push Transaction Linking and Notification Settings Design

## Goal

Fix the remaining push parser and notification consistency issues:

- A push event that activated a recurring transaction must show `Van tranzakcio`, not `Nincs hozzarendelt log`.
- Push event details must be able to jump to the linked transaction.
- Transaction editing must be able to jump back to the linked push event.
- Push samples such as `Hitel: 80000 Ft` must be usable by recurring push detection and parser training.
- Editing a transaction name or category must propagate by original merchant, but must not trigger push or in-app limit notifications.
- Limit notifications must include the relevant period.
- Settings must expose detailed notification controls instead of the current stub row.
- Backheader color must follow the app background color.

## Chosen Approach

Use a central native link and merchant identity layer.

Notification event status and navigation should not be guessed in Flutter. The native repository will resolve notification links from both existing sources:

- Direct parser-created transactions through `sourceNotificationEventId`.
- Recurring push activations through `recurring_rule_instances.matchedNotificationEventId` and `activatedTransactionId`.

The original transaction merchant remains the stable identity key for category and display-name memory. User-facing merchant renames are stored as display overrides, not as mutations of the original merchant key.

## Notification Event Link Status

A notification event has a linked transaction when either condition is true:

- A live transaction has `sourceNotificationEventId` equal to the event id.
- A recurring rule instance has `matchedNotificationEventId` equal to the event id and a non-null `activatedTransactionId`.

The direct transaction link takes precedence if both exist.

The push log status labels remain:

- `Van tranzakcio`
- `Nincs hozzarendelt log`
- `Rendszer`

The status does not distinguish whether an unlinked event failed parsing, was manually ignored, had a deleted transaction, or has no transaction for another reason.

For new recurring push activations, the created transaction should also store `sourceNotificationEventId = event.id`. This keeps future navigation simple while the recurring instance link still supports older data.

## Push Event to Transaction Navigation

The push event detail sheet adds a primary action when a linked transaction exists:

- `Ugras a tranzakciohoz`

Behavior:

- Close the push event sheet.
- Switch to the Home tab.
- Load the linked transaction by id.
- Open the existing edit transaction sheet for that transaction.

If the linked transaction was deleted between list loading and button tap, the app should refresh the event and show it as `Nincs hozzarendelt log`.

The training/create controls remain hidden for linked events.

## Transaction to Push Event Navigation

The edit transaction sheet adds an action when the transaction has a linked notification event:

- `Ugras az uzenethez`

Behavior:

- Resolve the linked notification event from `sourceNotificationEventId` or recurring rule instance data.
- Close the edit transaction sheet.
- Open the push event detail sheet for that event.

If no linked event can be resolved when the editor opens, the button is hidden. If resolution fails after a visible button tap because data changed, show a short error and leave the editor open. The app must not create synthetic events.

## Push Parser and Recurring Merchant Detection

The parser/training flow must support messages where the merchant appears before a colon, for example:

```text
Hitel: 80000 Ft
```

Rules:

- Tokenization must preserve the merchant token `Hitel` and the amount token `80000 Ft`.
- The parser preview must allow the user to select either merchant or amount from the available chips.
- Matching is case-insensitive for recurring push rule detection.
- A trailing colon after the merchant candidate must not prevent a match.
- Existing patterns such as `itt: nyiro` must keep working.

Recurring push rules that have the name `hitel` should recognize `Hitel: 80000 Ft` as a candidate message when the amount and package/profile checks also match.

## Merchant Name Propagation

The original merchant is the canonical grouping key. It is the existing row's raw `merchant` value before the edit, trimmed for matching.

When the user edits a transaction display name in the current edit card:

- Do not overwrite the raw merchant key.
- Store the edited display name in `userAssignedName`.
- Update every transaction with the same original merchant key to the same `userAssignedName`.
- If the edited display name equals the original merchant, clear the override for that merchant group.

Future transactions inherit the display override:

- When a new transaction is inserted with a raw merchant that already has a known `userAssignedName`, copy that value into the new row.
- This applies to manual adds, parser-created transactions, and recurring push-created transactions when a parsed raw merchant is present.

Category propagation stays aligned with the approved merchant-category design:

- Category changes propagate by original merchant.
- Future transactions inherit the known category by original merchant.
- Display name changes and category changes use the same original merchant identity, but remain separate stored values.

## Limit Notification Triggering

Manual edits must not emit push or in-app limit notifications.

This includes:

- Category changes.
- Display name changes.
- Other transaction edits made through the edit card.

Limit notifications are emitted only from actual new transaction creation or recurring activation paths. If the user is already over a limit and a new spend is inserted, the app may emit another alert for that new spend. Re-saving or reclassifying old rows must not emit another alert.

The transaction store may still refresh local notification cards after edits so the UI reflects current data, but it must not create new alert cards or Android push notifications for those edits.

## Informative Limit Notification Text

Limit push and in-app messages must include the affected period.

Required period labels:

- Monthly limit: include the month and year, for example `2026 juniusi`.
- Yearly limit: include the year, for example `2026 evi`.
- All-time or total limit: include `osszlimit`.

The existing category or budget label and amount remain in the message. The period label should be visible in both Android push text and in-app notification cards.

## Detailed Notification Settings

Replace the current notification settings stub with a real Settings submenu titled:

- `Ertesitesi beallitasok`

Initial controls:

- `In-app ertesitesek`
- `Android push ertesitesek`
- `Uj tranzakcio ertesitesek`
- `Ismetlodo tranzakcio aktivalas`
- `Limit figyelmeztetesek`
- `Limit tullepes ertesitesek`

The native notification emitter must read these settings before creating an in-app notification card or sending an Android notification.

If in-app notifications are disabled for a type, no notification card is inserted for that type. If Android push is disabled for a type, no Android notification is sent for that type. The two channels are controlled independently.

Changing these settings must not delete existing notification cards.

## Backheader Color

Backheader classic and experimental renderers must use the current theme background color instead of a hardcoded gray.

The color source is the resolved app background color from the active expense theme. If a component is used outside the normal theme context, it may keep a neutral fallback, but normal app screens should pass the active background explicitly.

## Native API and Data Flow

Add or extend native repository operations for:

- Listing notification events with linked transaction ids resolved from direct and recurring links.
- Loading a single notification event by id for jump navigation.
- Loading a transaction by id for jump navigation.
- Resolving a notification event id for a transaction id from direct and recurring links.
- Inheriting `userAssignedName` by original merchant on insert.
- Propagating `userAssignedName` by original merchant on edit.
- Reading notification settings in the notification emitter.

Flutter should call these APIs through stores and shell-level callbacks. Push log widgets should not directly own bottom-nav routing decisions.

## UI Boundaries

The app shell coordinates cross-screen jumps:

- Push log sheet asks the shell to open a transaction.
- Edit transaction sheet asks the shell to open a push event.

The push log page remains responsible for filtering, paging, and event sheet content. The transaction editor remains responsible for editing transaction fields. Neither screen mutates the other screen's navigation state directly.

## Testing

Use TDD for implementation.

Native tests:

- Notification event linked status is true for direct `sourceNotificationEventId`.
- Notification event linked status is true for recurring activated instances.
- Direct links take precedence over recurring links when both exist.
- New recurring push activations store `sourceNotificationEventId`.
- `Hitel: 80000 Ft` can produce merchant `Hitel` and amount `80000 Ft`.
- Recurring rule name `hitel` matches the `Hitel:` merchant form case-insensitively.
- Updating category or display name does not emit a new limit alert.
- New transaction insert still emits eligible limit alerts.
- Display-name propagation updates all rows with the same original merchant.
- Future inserts inherit display-name overrides.
- Notification settings suppress disabled in-app and Android notification channels.

Flutter tests:

- Linked push event sheet shows `Ugras a tranzakciohoz`.
- Unlinked push event sheet does not show `Ugras a tranzakciohoz`.
- Edit transaction sheet shows `Ugras az uzenethez` when a linked event exists.
- Jump callbacks are invoked with the correct ids.
- Notification settings submenu renders the expected toggles.
- Backheader receives and uses the active background color.

## Out of Scope

- A separate notification-transaction link table.
- Fuzzy merchant alias management UI.
- Migrating all old recurring transactions to fill `sourceNotificationEventId`.
- Deleting notification events.
- Changing the existing push log lazy rendering model.
- Reworking the full transaction editor layout beyond the new jump action and corrected save behavior.
