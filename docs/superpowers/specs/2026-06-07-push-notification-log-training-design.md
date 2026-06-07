# Push Notification Log and Training Design

## Summary

Add a push notification log under Settings > Megfigyelni kívánt alkalmazás. The feature lists every captured push event with lazy rendering, filters, transaction-link status, and a bottom-sheet training flow that can create a transaction from a selected message.

The design follows the existing Settings UI patterns:

- `SettingsSubmenuShell` style header with back button and centered title.
- `SettingsSection` and `SettingsOptionItem` for the entry point.
- `NotificationParserRuleEditor` training language for sample text, token chips, and preview.
- Transaction log lazy-list behavior as the performance baseline.

The approved visual mockup is the browser companion screen `push-log-ui-v4.html` from the brainstorming session.

## Entry Point

In the existing `Megfigyelni kívánt alkalmazás` submenu, add a new top section:

- Section title: `PushParser napló`
- Row title: `Elkapott push üzenetek`
- Row subtitle: `Év, hónap, app, szöveg és log kapcsolat szerint szűrhető`
- Right side: total captured message count badge and chevron

The same section can include a `Parser állapot` row showing active parser and capture status:

- Active parser profile count.
- Notification Listener active/inactive state.
- If Android capture permissions are missing, the UI indicates that the user must enable them in system settings. The app must not imply it can enable Android notification listener permission automatically.

## Push Log Screen

Opening `Elkapott push üzenetek` navigates to a new Settings submenu screen titled `Elkapott push üzenetek`.

The screen uses a lazy list and must not load all events into Flutter at once. It follows the transaction log pattern: append pages on scroll, stable row heights where practical, limited cache extent, and no eager rendering of thousands of records.

Top filters:

- Year selector.
- Month selector.
- Search field for app, merchant, amount, or message text.
- Status chips:
  - `Összes`
  - `Van tranzakció`
  - `Nincs hozzárendelt log`
  - `Rendszer`

Each push logbox shows:

- App label, falling back to package name.
- Event timestamp.
- Capture source badge, for example `NL` or `ACC`.
- A short preview of the notification text.
- Status indicator.

Status text is final:

- `Van tranzakció`
- `Nincs hozzárendelt log`
- `Rendszer`

The status is based on data, not guessed cause. If an event has a linked live transaction, show `Van tranzakció`. If not, show `Nincs hozzárendelt log`. Do not distinguish whether the missing link is caused by deletion, parser failure, old data, import, or another reason.

## Event Detail Sheet

Tapping a push row opens a bottom sheet, not a full detail page.

For an event with no linked transaction, the sheet includes:

- App/status title: `<app> · nincs hozzárendelt log`
- Timestamp, source, and event id.
- Full normalized message text.
- Training mode chips: `Összeg` and `Bolt`.
- Token chips generated from the event message.
- Preview box with amount, merchant, and transaction type.

Final actions:

- Primary: `Tanítás és log létrehozása`
- Secondary: `Rendszerüzenetként jelölés`
- Secondary: `Bezárás`

There is no separate `Log létrehozása` button.

For an event with a linked live transaction:

- Do not show the create/training CTA.
- Show the linked transaction reference and allow opening or inspecting the linked log if supported by the surrounding navigation.
- Always allow closing the sheet.

## Data Model

Raw messages remain in the existing `notification_events` store and are not deleted through this UI.

Add list/status support to notification events:

- A manual status field is needed for user classification such as `system`.
- System-marked events remain stored, but move out of the `Nincs hozzárendelt log` filter.

Add an optional source notification link to transactions:

- `sourceNotificationEventId`

When a transaction is created from a push event, store the event id in `sourceNotificationEventId`. The push log status is computed by checking for a live transaction with that source event id.

The UI must not duplicate the full raw message in the transaction row. The notification event remains the source of truth for raw message content.

## Native API

Add a paged notification-event API. It returns a page object, not an unbounded list.

Inputs:

- `limit`
- `offset`
- `year`
- `month`
- `query`
- `status`
- Optional app/package filter

Output:

- `events`
- `totalCount`
- `limit`
- `offset`

Each event row includes:

- Existing notification fields: id, timestamp, source, package name, app label, title, text, big text, sub text, category, key, duplicate marker.
- Derived display text.
- Derived status.
- Linked transaction id when available.

The existing all-events loader must not be used for this screen.

## Training And Creation Flow

Parser profile behavior:

- On Settings/parser load, ensure at least one parser profile exists.
- If there are profiles but all are disabled, enable the selected profile or the first profile.
- This only affects the app parser configuration. Android Notification Listener permission still requires user action.

The `Tanítás és log létrehozása` CTA is enabled only when:

- The user selected an amount token.
- The user selected a merchant token.
- Parser preview is valid.
- The event has no live linked transaction.

On CTA:

1. Set the selected profile sample text to the full selected event text.
2. Update amount and merchant selections/patterns using the same training logic as the existing parser editor.
3. Save the parser profile.
4. Create a transaction using the event timestamp, parsed amount, parsed merchant, selected transaction type, no assigned category, and `sourceNotificationEventId`.
5. Refresh the event row so status becomes `Van tranzakció`.

If transaction creation fails, do not create a partial transaction. Keep the sheet open and show the preview/error state so the user can adjust the selection.

The parser flow must not require category selection. Bank app push parsing covers all spending from the observed app, and those messages can belong to multiple categories. Newly created push transactions start uncategorized. The main transaction screen is responsible for category assignment.

Uncategorized push-created transactions appear in the main transaction log with a gray avatar and a white question-mark icon. When the user categorizes a merchant on the main screen, future transactions with the same merchant should automatically receive that learned category. That merchant-category learning workflow is separate from the parser-training UI.

## System Marking

`Rendszerüzenetként jelölés` marks the event as system/manual ignored. It does not delete the notification event.

After marking:

- The event appears under `Rendszer`.
- The event is excluded from `Nincs hozzárendelt log`.
- The raw message remains available in the all-events view.

## Performance

The feature must support multiple years and thousands of events.

Required behavior:

- Native query uses indexed filters for timestamp and status-relevant fields.
- Flutter store keeps only loaded pages in the list state.
- UI uses builder-based lazy rendering.
- Loading more appends to the current list and does not rebuild all expensive derived data eagerly.
- Filter changes reset pagination.

## Testing

Use TDD.

Native tests:

- Paged notification event query respects `limit` and `offset`.
- Year and month filters return the expected rows.
- Query filter searches app/message fields.
- Status filter returns `Van tranzakció`, `Nincs hozzárendelt log`, and `Rendszer` correctly.
- System-marked events are excluded from `Nincs hozzárendelt log`.
- Creating a transaction from an event stores `sourceNotificationEventId`.
- Creating a transaction from an event does not require or assign a category.

Flutter tests:

- Settings parsed-app submenu shows `Elkapott push üzenetek`.
- Push log screen renders only the page data provided by the store.
- Scroll/load-more appends the next page.
- Push logbox status labels match exact text.
- Detail sheet shows `Tanítás és log létrehozása`, `Rendszerüzenetként jelölés`, and `Bezárás`.
- Detail sheet does not show a separate `Log létrehozása` button.
- Create CTA is disabled until amount and merchant are selected and preview is valid.

Integration behavior tests:

- Valid training creates a transaction and changes event status to `Van tranzakció`.
- Valid training creates an uncategorized transaction.
- Invalid preview blocks creation.
- Already linked event does not show creation CTA.
- System marking removes the event from `Nincs hozzárendelt log`.

## Execution Plan Direction

After this design is approved, create a written implementation plan. The work is large enough for subagent-driven development after the plan exists.

Suggested task split:

- Native Room/schema/API and query tests.
- Flutter model/repository/store pagination.
- Settings entry point and push log list UI.
- Detail sheet and parser-training integration.
- End-to-end behavior tests and review.

Each implementation task should use TDD, then receive spec-compliance review and code-quality review before moving to the next task.
