# Restore Balance Child Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the approved Balance Havi/Éves child-card topology and their pre-existing chart content within the current shared Mother Card height; keep Budget unified by default and give Mind the same settled lower action-row padding as Budget.

**Architecture:** `DashboardContentCardHeightPolicy` stays the sole outer-height owner. `BalanceExtendedSheetLayout` is the sole owner of the Havi/Éves child rectangles. Existing Balance renderers continue to render direct typography and flexible charts into those rectangles. `DashboardGeometryResolver` owns the common Mother Card-to-action-row spacing. Budget's controller remains the unified-card state owner.

**Tech Stack:** Flutter/Dart, `flutter_test`, golden tests, Android screenshots, GitHub Actions.

## Global constraints

- Work only in this existing Fluvi recovery worktree on `feature/balance-wave-defaults`; do not create, delete, or merge worktrees.
- Preserve `test/features/dashboard/presentation/failures/`, which was already untracked.
- Keep the present shared Mother Card size and its height policy unchanged.
- Treat `html-prototypes/balance-extended-sheet-baseline/index.html` as the approved layout: a 70%×60% left card, two 30%×30% right cards, then a 100%×40% bottom card.
- Keep direct text/padding and the existing flexible chart renderers; do not restore a card-wide `FittedBox`.
- Run Flutter analysis/tests through Ubuntu proot. Use GitHub Actions, not Termux, for the APK.
- No parallel agent work: the production changes share the same geometry and golden baselines.

## Task 1: Restore Balance's sole child-rectangle grammar

**Files:**

- Modify: `test/features/dashboard/presentation/balance_extended_sheet_layout_test.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/balance_extended_sheet_layout.dart`

- [ ] Replace the current square-body test contract with:

```dart
expect(layout.card3, const Rect.fromLTWH(0, 0, 700, 600));
expect(layout.card4, const Rect.fromLTWH(700, 0, 300, 300));
expect(layout.card5, const Rect.fromLTWH(700, 300, 300, 300));
expect(layout.combined, const Rect.fromLTWH(0, 600, 1000, 400));
```

Add translated-body assertions that Card 4 ends where Card 5 begins and that the combined card covers the body's full width.

- [ ] Run the focused layout test through Ubuntu and observe it fail because current Card 4 owns the whole 60% top area and Cards 5/combined split the lower area.

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_extended_sheet_layout_test.dart'
```

- [ ] Restore the unit's one rectangle grammar:

```dart
final halfRightHeight = topHeight / 2;
return BalanceExtendedSheetLayout._(
  card3: Rect.fromLTWH(bodyRect.left, bodyRect.top, card3Width, topHeight),
  card4: Rect.fromLTWH(
    bodyRect.left + card3Width,
    bodyRect.top,
    rightWidth,
    halfRightHeight,
  ),
  card5: Rect.fromLTWH(
    bodyRect.left + card3Width,
    bodyRect.top + halfRightHeight,
    rightWidth,
    halfRightHeight,
  ),
  combined: Rect.fromLTWH(
    bodyRect.left,
    bodyRect.top + topHeight,
    bodyRect.width,
    bottomHeight,
  ),
);
```

- [ ] Re-run the focused layout test and inspect the production diff. This task must not modify the shared height policy.

## Task 2: Verify Havi/Éves child content and update only their golden evidence

**Files:**

- Modify: `test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart` only if a geometry-specific assertion is missing.
- Modify: `test/goldens/balance_alternative_havi2_cards.png`
- Modify: `test/goldens/balance_alternative_eves_cards.png`

- [ ] Run the existing extended-card widget/golden suite without baseline updates. Confirm the two golden mismatches are caused by Task 1's restored child-slot geometry, not an overflow or text-rendering failure.

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart'
```

- [ ] Keep the existing pre-computed chart series, labels, direct typography, and card-local padding. Do not make a renderer change merely to make the old incorrect golden pass. If the result reports a real overflow, trace the specific card and add the smallest renderer adjustment with a new failing widget assertion first.

- [ ] Regenerate only the two changed goldens, inspect them at full resolution, then re-run the same suite.

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test --update-goldens test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart'
```

The Havi frame must show daily spending at left, no-spend and savings stacked at right, then the full-width income/expense card. The Éves frame must show closing balance at left, positive closing and annual savings stacked at right, then full-width annual income/expense bars.

## Task 3: Anchor seamless Mind spacing to the canonical Mother Card lower edge

**Files:**

- Modify: `test/core/design/dashboard_geometry_resolver_test.dart`
- Modify: `lib/core/design/dashboard_geometry_resolver.dart`

- [ ] Add a test that resolves settled `DashboardModeSpec.mind` with `seamlessHeaderContent: true` and settled `DashboardModeSpec.budget` with matching metrics. Compute the lower padding from each `headerBounds.bottom + canonicalMotherCardContentHeight` to its action row; assert the results agree and equal `metrics.standardGap`.

- [ ] Run that focused test through Ubuntu and observe the failure caused by Mind currently using `fullModeContentFlowHeight`.

- [ ] Change only the pre-existing seamless anchor to:

```dart
final seamlessActionTop =
    headerBounds.bottom +
    canonicalMotherCardContentHeight * headerExpansionProgress +
    metrics.standardGap;
```

No Mind-specific constant or second height source may be introduced.

- [ ] Re-run the geometry suite and inspect affected calls to ensure the summary/rail retain their existing action-relative placement.

## Task 4: Lock the boundaries and Budget's initialized state

**Files:**

- Modify: `test/boundary/balance_alternative_extended_sheet_boundary_test.dart`
- Modify: `docs/superpowers/checklists/2026-09-29-restore-balance-child-layout.md`

- [ ] Add a source-boundary assertion for `final halfRightHeight = topHeight / 2;`, full-width `combined`, and absence of the obsolete `bottomWidth` split. Keep the existing assertion that Balance has no local outer-height token.

- [ ] Run that boundary test with the focused Budget layout test. The Budget test must continue to demonstrate its `BudgetContentCardStyleController` starts at `BudgetContentLayout.unifiedCard`; no Budget production code change is expected.

- [ ] Update only the objectively verified RBL entries. Leave device and APK statuses open until their required evidence exists.

## Task 5: Re-read requirements, verify, publish, and deliver the APK

**Files:**

- Modify: `docs/superpowers/checklists/2026-09-29-restore-balance-child-layout.md`

- [ ] Re-read the HTML source and the four relevant Android screenshots before final visual comparison. Capture and inspect fresh Havi, Éves, Mind, and Budget device screenshots after the normal APK is available.

- [ ] Run static analysis and the focused regression matrix in Ubuntu:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter analyze'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/fluvi-balance-carousel-recovery && /home/flutteruser/flutter/bin/flutter test test/core/design/dashboard_geometry_resolver_test.dart test/boundary/balance_alternative_extended_sheet_boundary_test.dart test/features/dashboard/presentation/balance_extended_sheet_layout_test.dart test/features/dashboard/presentation/balance_alternative_extended_sheet_cards_test.dart test/features/dashboard/presentation/budget_content_layout_test.dart test/features/dashboard/presentation/budget_dashboard_core_surface_test.dart'
```

- [ ] Run `git diff --check`, inspect the status, commit only the files for this task, and push `feature/balance-wave-defaults`.

- [ ] Monitor the `build-human-diagnostic-apk` job for the exact pushed SHA. When it succeeds, download its normal human APK under a new descriptive filename in `/storage/emulated/0/Download/fluvi`, verify it with `unzip -t` and `sha256sum`, then update the checklist honestly.

## Plan self-review

- Every RBL requirement has an owner and a verification method.
- The outer height remains centralized; the layout grammar and lower action anchor each have one owner.
- The Havi/Éves renderer is preserved unless test evidence identifies a real independent overflow.
- The work is sequential and shares source/golden state, so inline execution is the correct mode.

