# Merchant Category Propagation Design

## Goal

When the user assigns a category to a transaction, every transaction with the same original merchant should use that category. Future transactions from the same original merchant should inherit the known category automatically.

The merchant identity is the original `transactions.merchant` value, not `userAssignedName`. This matches the existing automatic merchant rename behavior, which also propagates by original merchant.

## Chosen Approach

Use the existing `transactions` table as the source of truth. Do not add a separate merchant-category rules table in this iteration.

The native repository will enforce the rule so it applies consistently to all transaction creation paths:

- Manual transaction edits from Flutter.
- Push parser-created transactions.
- Any future native transaction import path that calls the same repository methods.

## Behavior

When a transaction is updated with a non-null category:

- Validate the category as the repository already does.
- Save the edited transaction fields.
- If the category changed, update every row where the trimmed `merchant` equals the edited transaction's original merchant key.
- The original merchant key is the existing row's trimmed `merchant` before the edit. This avoids changing the grouping key accidentally if the editor also changes the visible merchant text.
- Merchant matching is exact after trimming leading and trailing whitespace.
- `userAssignedName` remains independent and continues to propagate through the existing rename-by-original-merchant flow.

When a new transaction is created without an explicit category:

- Look up the most recent existing transaction with the same original `merchant` and a non-null `transactionCategoryID`.
- If found, use that category.
- If not found, keep the transaction uncategorized.

When a new transaction is created with an explicit category:

- Use the explicit category.
- The inserted row then becomes category memory for later transactions with the same original merchant.

## Scope

In scope:

- Add DAO queries for category propagation by original merchant.
- Update manual transaction edit behavior to propagate category changes.
- Update transaction creation to inherit category when category is omitted.
- Update push parser transaction creation to use inherited merchant category.
- Add focused tests for store/repository behavior where practical.
- Add debug logs around propagation and inheritance.

Out of scope:

- A new merchant-category mapping table.
- A merchant rules management UI.
- Merchant aliasing or fuzzy matching.
- Regex-based merchant normalization.
- Category propagation by `userAssignedName`.

## Edge Cases

- If every transaction for a merchant is deleted, category memory for that merchant is lost. This is acceptable for this iteration.
- If a category is deleted, existing category delete constraints and behavior remain unchanged.
- If the edited transaction changes merchant text and category in one save, propagation targets the original merchant group of the existing row.
- Income and expense are not separated for propagation. The user requirement is merchant-level consistency: same original merchant means same category.

## Testing

Tests should cover:

- Updating one transaction category updates all transactions with the same original merchant.
- Updating one merchant does not affect another merchant.
- New transactions without category inherit a known category from the same original merchant.
- New transactions stay uncategorized when no category memory exists.
- Push parser-created transactions inherit the merchant category when possible.

## Implementation Notes

The existing native path already validates categories in `ExpenseRepository.addTransaction` and `ExpenseRepository.updateTransaction`. The new behavior should be implemented near those methods and backed by DAO queries, not by Flutter-side list mutation.

Flutter should still reload after save as it does today, so the visible log reflects the propagated category changes.
