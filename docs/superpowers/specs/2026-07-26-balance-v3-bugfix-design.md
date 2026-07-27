# Balance V3 Bugfix Design

**Canonical acceptance contract:** `docs/superpowers/checklists/bugfix20260726v3.md`.
This document adds no acceptance requirements and does not supersede that
checklist. Every implementation and evidence decision must cite its V3 row.

## Goal

Make every `BUGFIX-20260726V3-001` through `012` demonstrably conform to the
frozen Balance HTML contract without screenshot-based verification.

## Frozen inputs and boundaries

- The reference is `balance_latest_layout.html` with SHA-256
  `ff7a00a7aeae8f636b08611443bd3975aec1303828ae5c80bce253ae1d29a2ed`.
- The only verification surface is the real `SpendeeBalanceDashboard` Balance
  composition at `Size(412, 892)`, under its normal theme/state provider.
- Tests inspect geometry, actual material ancestry, effective input
  decorations, semantics, callbacks, and `BalanceDebugTrace` events.
- Browser screenshots, golden/image assertions, Playwright, and Puppeteer are
  excluded from V3 acceptance.
- No commit, push, remote build, APK download, or `DONE` checklist status is
  allowed while any V3 row remains unresolved.

## Architecture

### Contract source layer

`spendee_balance_b3ma3_manifest.dart` becomes a versioned, typed record of
the V3 selector declarations. Every metric records the HTML selector and
line-range which supplied it. A test-only parser reads the root HTML file,
validates the frozen SHA, extracts the final declaration from each declared
cascade, and reports both the generic `208px` declaration and the final
detail-specific `248px` declaration. The production visual spec consumes the
typed values; widgets never parse HTML or duplicate its literals.

### Production test host

A shared test helper mounts the production Balance route/composition under
the shipping theme and state provider at `412 x 892`. It provides keyed access
to rendered production nodes and helpers for `getRect`, decoration ancestry,
effective `InputDecoration`, semantics, and `BalanceDebugTrace`. It is not a
standalone `Scaffold` or copied card host.

### LogBox

The date shell owns the L2 material; each keyed moving row surface owns its
L3 fill, edge handling, and rounded end geometry. The swipe `Transform` is
outside that whole surface, so the avatar, copy, amount, and the single right
edit control move together. The row uses the exact four-column grid. Merchant
rename remains long-press/keyboard/semantic-only, while the merchant/avatar
subtree has no pencil asset or edit affordance. Avatar icon and hue are
resolved only through the existing central category resolver and slot icon.

### FastInfo and detail cards

The upper belt uses five explicit variant layouts, driven by one FastInfo
visual-style resolver whose hue simultaneously determines icon, border, and
glow. The visible belt is `128px` high and cards are `120px` wide. Detail
pages keep their own D2–D5 grids inside a `248px` page and a `258px` stage;
no generic compact measurement is reused. Card clipping is local to the card,
and page background is exposed through every gap and rounded corner.

### Rail and performance

Rail motion owns a preview selection while dragging. Publishing is deferred
until settle and is deduplicated by scope key. The trace records discarded
scopes and the one final load; recurring-ghost and inactive Stats prewarm work
does not run during a drag. The same trace model records the LogBox window and
load-more event ordering without treating full gesture duration as frame time.

### Gate and evidence

One test mapping enumerates all twelve V3 IDs and their required
production/trace proof. `tool/check_balance_v3_gate.sh` returns non-zero for
an unresolved V3 status and is invoked by CI before release/build steps. The
evidence ledger is updated only after each row's exact passing command and
named production test(s) exist.

## Delivery order

1. Contract parser, manifest, production host, and V3 mapping test.
2. LogBox L1–L8, including the right edit control and swipe tree.
3. FastInfo F1–F6 plus central hue resolution.
4. Detail cards D1–D5 and `248/258` stage correction.
5. Summary/search, rail paint bounds, direct page surfaces, and 14k trace.
6. Gate, CI invocation, full literal re-verification, and evidence ledger.

## Error handling and regression rules

- A changed HTML SHA or final selector declaration fails before a widget
  comparison runs.
- Equal scope keys are ignored after the final publish; stale post-frame
  callbacks verify generation/key before mutating state.
- Cancelled/rejected row actions reset swipe state; reused lazy rows never
  retain a prior offset.
- Tests assert both required controls and forbidden duplicates, especially the
  one right-edge pencil and zero merchant/avatar pencils.

## Design self-review

- No requirement is added beyond the canonical V3 checklist.
- The source of every literal remains the frozen HTML/canonical checklist.
- Delivery order matches the checklist's required TDD sequence.
- The design does not use forbidden screenshot or browser automation methods.
