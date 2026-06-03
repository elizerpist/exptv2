# Notification System Completion Design

## Goal

Finish the expense notification system so the app emits the same domain events through all required surfaces:

- internal notification cards in the notifications tab
- Android phone notifications
- Android lockscreen notifications

The required triggers are:

- limit usage reaches or exceeds 75%
- limit usage reaches or exceeds 100%
- a new transaction is created
- a recurring ghost transaction is activated

Limit threshold alerts are transaction-driven. Every new transaction that leaves an active limit at or above a threshold emits a fresh alert for that threshold. The alert message must include how much remains before the limit, or how much the limit has been exceeded.

## Existing Context

The app already has a native `notification_cards` table, Dart notification models, a notifications page, and native recurring activation logic. Recurring ghost activation currently creates an internal card through `RecurringNotificationCardFactory.activationCard(...)`, and `RecurringNotificationHelper` sends a phone notification for processed recurring transactions.

Missing behavior:

- manual transaction creation does not create notification cards
- manual transaction creation does not send phone or lockscreen notifications
- limit threshold alerts are not emitted
- recurring activation only has a narrow phone notification path and does not use a general notification emitter
- debug logs do not show enough notification trigger and delivery detail

## Architecture

Add a native notification emission layer in Kotlin, owned by the expense repository layer. This layer should be responsible for creating the internal `NotificationCardEntity` rows and sending Android notifications using a shared channel.

The repository remains the source of truth for transaction, recurring, and limit state. This keeps trigger evaluation native-side, so recurring alarm processing can emit notifications even when Flutter UI is not active.

Primary units:

- `ExpenseNotificationEmitter`
  - inserts internal cards
  - sends phone/lockscreen notifications
  - logs trigger and delivery timing
- `ExpenseNotificationCardFactory`
  - builds card entities for transaction-created, limit-75, limit-100, and recurring-activated events
- limit evaluation helper
  - evaluates active limits affected by a transaction
  - computes spent amount, usage ratio, remaining amount, and overage
  - returns one alert candidate per active threshold per affected limit

`RecurringNotificationHelper` should either be replaced or reduced to a compatibility wrapper around the new emitter.

## Trigger Flow

### New Transaction

After `ExpenseRepository.addTransaction(...)` inserts the transaction:

1. Load the category.
2. Emit a `transaction_created` internal card.
3. Send a phone/lockscreen notification for the created transaction.
4. If the transaction is an expense, evaluate active expense limits for the transaction date.
5. Emit `limit_75` and/or `limit_100` alerts for each active limit that is at or above the threshold after the new transaction.

Updating an existing transaction is not part of this scope unless explicitly requested later.

### Recurring Ghost Activation

After a ghost creates a real transaction:

1. Preserve the existing recurring activation card behavior.
2. Send phone/lockscreen notification through the shared emitter.
3. Evaluate active expense limits for the activated transaction if it is an expense.
4. Emit limit threshold alerts using the same logic as manual transactions.

### Limit Thresholds

For every newly inserted expense transaction, evaluate active limits in the transaction period:

- category limit where `targetType = category` and `targetId = transaction.categoryId`
- overview expense budget where `targetType = overview`, `targetId = 0`, and `transactionType = expense`

Only active limits should produce alerts:

- `hasLimit = true`
- `alertActive = true`
- `limitAmount > 0`

The alert threshold behavior:

- usage `< 75%`: no alert
- usage `>= 75%` and `< 100%`: emit `limit_75`
- usage `>= 100%`: emit `limit_100`

Every new transaction can emit a new alert if the limit is already over the threshold. There is no period-level dedupe. Within one transaction, do not emit the same threshold twice for the same limit.

## Message Semantics

Limit alert messages must include the limit name and remaining state:

- if remaining amount is positive: `X Ft maradt a limitből`
- if exactly at limit: `Elérted a limitet, 0 Ft maradt`
- if over limit: `X Ft-tal túllépted a limitet`

Transaction-created messages include merchant/display name, category, amount, and type.

Recurring activation messages keep their current meaning but route through the shared emitter.

## Notification Types

Add native and Dart support for these internal card types:

- `transaction_created`
- `limit_75`
- `limit_100`

Keep existing types:

- `recurring_transaction_alert`
- `budget_alert`
- `spending_limit`
- `monthly_budget_alert`
- `system`

Unknown native types still fall back to `system`.

## Android Delivery

Use an Android notification channel for expense alerts. The channel should be visible on the lockscreen by default, subject to Android/user settings.

Phone and lockscreen delivery are the same Android notification object with:

- small icon
- title
- message
- big text style
- default priority for transaction/recurring events
- high priority or default-high equivalent for 100% limit alerts
- auto cancel
- unique notification id per emitted event

On Android 13+, if `POST_NOTIFICATIONS` is not granted, the emitter still creates internal cards and logs that native delivery was skipped.

## Debug Logging

Add logs for:

- transaction notification emission requested/completed
- recurring activation notification emission requested/completed
- limit evaluation start with transaction id/category/amount/date
- per-limit evaluation result with spent, limit, ratio, remaining, threshold
- Android delivery skipped because notification permission is missing
- internal card insert id/type
- Android notify id/type

Use the existing debug log style with `[Notification]` and `[Perf]` prefixes.

## Testing

Add or update tests for:

- Dart notification model parses `transaction_created`, `limit_75`, and `limit_100`
- notification cards still group and render with new types
- native bridge can load the new card types
- native notification card factory builds expected cards
- transaction insertion emits transaction card and limit cards
- recurring activation emits recurring card and limit cards
- notification permission denial does not prevent internal card creation

The implementation should keep existing notification tests passing.

## Out Of Scope

- user-configurable notification preferences
- editing existing transactions triggering retroactive alerts
- deduping repeated alerts within a period
- deep links from notification tap into specific transaction or card
- replacing the notifications tab design
