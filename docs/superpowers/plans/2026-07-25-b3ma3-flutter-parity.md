# B3M-A3 Flutter Balance parity implementation plan

> **Execution rule:** This plan is executed immediately, without a separate
> approval gate, because the user explicitly supplied the frozen specification
> and instructed Codex to plan and then implement it without waiting.

**Goal:** Port the frozen
`[data-stage2-alternative="today-time-rail-permanent"]` B3M-A3 screen into the
Flutter Új Spendee dashboard as a first-class Balance mode, with production
data, exact interactions, visual evidence, tests, online APK build, and APK
delivery.

**Frozen sources:**

- `balance_latest_layout.html`
- SHA-256:
  `7940542ec918633de295b252c1c333e8f9a9df65f3a96680d269ca5335310d8f`
- `docs/prototypes/color_lab.html`, from which the exact page clones the
  `strict-mother-child` shell and shared Fluvi brand/navigation
- `docs/superpowers/checklists/2026-07-25-b3ma3-flutter-parity.md`
  (`B3MA3-PARITY-R5`)

The checklist is the acceptance registry. Its stable IDs, source instruction,
target area, acceptance condition, verification method, and status are
normative. No checklist row may be reported complete without the evidence it
requires.

## Architectural approach

Keep Budget and Mind on their existing three-stage controller and render tree.
Add Balance as a separate, explicitly selected dashboard branch with its own
two-endpoint collapse controller. Put the exact B3M-A3 visual implementation in
a dedicated `experimental/balance/` package so old Spendee decoration cannot
leak into it. The package receives the canonical `TransactionStore`; a pure
resolver creates one immutable render frame from the current type, summary
window/reference, query, categories, merchants, recurring ghosts, limits, and
transactions. The header, FastInfo carousels, detail carousel, action row,
summary/search/time rail, and grouped lazy log all consume that same frame.

Use Flutter-native layout and painters with constants transcribed from the full
base + `time-rail-compact` + `permanent` selector cascade. Use the existing
controller behavior only where the checklist explicitly names it: center
carousel inertia, summary gesture/ticker behavior, canonical store filtering,
merchant rename/reset, edit/delete, and lazy log loading. Keep HTML-derived
pixels in B3M-A3 widgets, not in old generic cards.

## Requirement coverage map

| Plan task | Checklist IDs | Primary code area | Acceptance evidence |
| --- | --- | --- | --- |
| 1. Freeze and inventory | A3-GLOBAL-001…009 | checklist, parity manifest | source hashes, selector→widget→property map |
| 2. Canonical data frame | A3-DATA-001…004, A3-CARD-003…006, A3-RAIL-003…004 | `balance_frame.dart`, `transaction_store.dart` | resolver/store unit tests, invalidation tests |
| 3. Motion and carousel controllers | A3-MOTION-001…003, A3-RAIL-001…002/005, A3-FAST-001, A3-CARD-001, A3-MONTH-002, A3-SEARCH-003 | `balance_controller.dart` | controller/gesture tests including reduced motion |
| 4. Exact header/FastInfo/detail UI | A3-HEADER-001…002, A3-FAST-001…002, A3-CARD-001…006 | Balance widgets/painters | widget/golden tests and expanded/collapsed overlays |
| 5. Actions, summary, search, rail | A3-ACTION-001…002, A3-MONTH-001…002, A3-SEARCH-001…004, A3-RAIL-001…005 | Balance content widgets | geometry/state/gesture tests and state screenshots |
| 6. Grouped lazy transaction log | A3-TXN-001…005 | `balance_transaction_log.dart`, store windowing | interaction tests, 500+/10k performance test |
| 7. Mode/surface/brand/shell integration | A3-MODE-001…003, A3-SHELL-001…003, A3-HEADER-001…002, A3-NAV-001 | dashboard, home page, shell/nav/FAB | routing/mode/surface/brand/nav tests and screenshots |
| 8. Full visual verification | A3-GLOBAL-003…008 and all visual rows | evidence scripts/files, checklist | HTML/app captures, side-by-side, 50% overlay |
| 9. Delivery | all rows | Git/GitHub Actions | clean scoped commit, branch push, green CI, APK checksum |

## Task 1: Freeze the complete visual and behavior manifest

**Files:**

- Add:
  `docs/superpowers/evidence/2026-07-25-b3ma3-parity-manifest.md`
- Update:
  `docs/superpowers/checklists/2026-07-25-b3ma3-flutter-parity.md`

1. Recompute and record the frozen main HTML hash before implementation.
2. Record the current `color_lab.html` hash because the main document clones
   its brand/navigation shell at runtime.
3. Inventory the exact DOM hierarchy: 5 FastInfo cards, 4 detail pages, 2
   actions, month summary, search/filter, permanent year rail and handle,
   grouped transaction log, brand, hero, and bottom navigation.
4. Transcribe the final computed cascade for every rendered selector, including
   base, compact, and permanent overrides. Include geometry, text, gradients,
   borders, every shadow, opacity, transforms, typography, clipping, z-order,
   chart mapping, and SVG source/factory.
5. Map every selector/factory to a Flutter widget, painter, exact-spec constant,
   behavior source, test, screenshot state, and checklist ID.
6. Leave status as `NOT DONE` until the corresponding implementation and visual
   evidence exist.

## Task 2: Build one canonical Balance render frame

**Files:**

- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_frame.dart`
- Modify:
  `lib/features/transactions/state/transaction_store.dart`
- Test:
  `test/spendeetest/balance_frame_test.dart`
- Test:
  `test/transactions/transaction_store_test.dart`

1. Write failing tests for a deterministic live-data frame covering balance,
   reserve/ratio, all five FastInfo boxes, all four detail cards, variable
   day/week/month budget dimensions, merchant year/month/all dimensions,
   30-day daily series, summary text, available year scopes, categories,
   merchants, grouped log rows, and recurring-ghost on/off results.
2. Run the tests in Ubuntu proot and confirm they fail for missing production
   code.
3. Implement immutable frame/value models and a pure resolver. Never call a
   preview/sample data path.
4. Resolve every calculation from `TransactionStore` live records, categories,
   limits, recurring ghost records, `fastInfoMetrics`, and canonical filter
   state. Make pending ghosts opt-in per card without duplicating an activated
   or already-generated transaction.
5. Derive time-rail choices only from records matching the active
   type/query/category/merchant dimension; select the nearest valid period if
   the current period vanishes.
6. Implement real display-log windowing: a bounded initial window, group-safe
   page expansion, total count, filter-reset behavior, and cached immutable
   slices. Preserve 360px cache extent and 320px prefetch trigger at widget
   level.
7. Run focused tests until green; run existing store regression tests and
   document any unrelated pre-existing failure separately.

## Task 3: Implement exact Balance motion primitives

**Files:**

- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_controller.dart`
- Test:
  `test/spendeetest/balance_controller_test.dart`
- Test:
  `test/spendeetest/balance_gesture_test.dart`

1. Write failing tests for exactly two stable states, 180px collapse distance,
   50% snap, reversible drag, click/keyboard toggle, and no Budget/Mind stage1
   stop.
2. Test the exact curves:
   hero `126→104`, insight progress `(p-.03)/.62`, detail progress
   `(p-.16)/.62`, hero-stat fade `(p-.08)/.52`, and post-stack `0→-132`.
3. Implement a `ChangeNotifier`/animation-controller adapter that updates only
   repaint/layout boundaries needed by the active motion, never rebuilding the
   transaction log per animation tick.
4. Adapt `SpendeeCenterCarouselController` for infinite FastInfo, detail, and
   year carousels with the same step, inertia, release, and haptic semantics
   already used by Budget.
5. Implement summary horizontal follow (`0.1×`, clamp ±18px, 60px threshold,
   160ms ease-out-cubic settle), vertical scope cycling, and search vertical
   ticker isolation.
6. Honor platform reduced-motion settings and keep all horizontal/vertical
   gesture arenas isolated.
7. Run controller and gesture tests until green, then run the existing
   Budget/Mind controller regression tests.

## Task 4: Render the exact hero, FastInfo belt, and detail carousel

**Files:**

- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_exact_spec.dart`
- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_header.dart`
- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_fast_info.dart`
- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_details.dart`
- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_painters.dart`
- Test:
  `test/spendeetest/balance_header_test.dart`
- Test:
  `test/spendeetest/balance_cards_test.dart`

1. Write failing widget tests for the authored 412px design grid and all exact
   component keys/content.
2. Implement the `#F8FAFC` shell and hero at y=104, sides=16, expanded
   height=126, collapsed height=104, radius=24, exact four-stop gradient,
   layered shadows/specks, amount, reserve meter, ratio and collapse
   transforms.
3. Implement the 104px, 3-up, 9px/6px-gapped infinite FastInfo belt with no
   dots. Reproduce each distinct internal hierarchy; do not collapse them into
   a generic text card.
4. Implement the 176px detail carousel and 6px pagination row with the four
   distinct pages: variable budget/progress, top categories, top merchants,
   average daily/30-day chart.
5. Implement exact painters for progress and daily chart, including the
   documented plot bounds and data→pixel transform. Render Lucide SVG masks
   and the approved action/card assets without Material-icon substitutions.
6. Implement independent per-card ghost toggles that recompute the same frame
   dimension.
7. Verify all focused tests and capture deterministic component goldens at the
   reference viewport.

## Task 5: Render actions, summary, search, and permanent time rail

**Files:**

- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_post_content.dart`
- Test:
  `test/spendeetest/balance_post_content_test.dart`

1. Write failing tests for the 42px exclusive action pair, 59px month summary,
   39px `1fr + 40px` search row, 79px permanent rail, year choice derivation,
   and exact semantics.
2. Render the action grid with 4px side margins, 10px gap, 16px radii, exact
   active/inactive gradients, opacity .9, and 50/48px adaptive layered wallet
   and bag SVG art.
3. Implement mutually exclusive active state and the 420ms
   `.9→1.12→.98→1` pulse; repeated active taps replay it; reduced motion skips
   decorative animation while preserving state.
4. Render and bind the exact summary pill. Tap resets current month,
   double-tap invokes the existing picker, horizontal swipes shift periods,
   and vertical swipes cycle month/year/all.
5. Render the exact search field/capsules/filter button. Query and capsules use
   canonical store APIs; vertical scope swipe uses the same ticker behavior;
   filter invokes only the supplied callback and opens no invented menu.
6. Render the permanent year/month rail and 92×21 collapse handle. Options,
   active choice, infinite carousel, 5px dots, 50% snap, labels, keyboard, and
   semantics follow the reference/controller tests.
7. Run focused widget/interaction tests and capture all specified active,
   inactive, swipe, ticker, and pulse states.

## Task 6: Render the grouped, interactive, lazy transaction log

**Files:**

- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_transaction_log.dart`
- Test:
  `test/spendeetest/balance_transaction_log_test.dart`
- Test:
  `test/spendeetest/balance_performance_test.dart`

1. Write failing tests for shared day cards, 18px radius, 50px rows, exact
   `31px / 1fr / auto / 22px` grid, row separators, 22px pencil button,
   category avatar filter, isolated edit tap, and canonical content formatting.
2. Implement a `ListView.builder`/sliver-based day-group renderer with 360px
   cache extent and a 320px load-more threshold. Never build the complete
   500+/10k record list up front.
3. Port row-follow drag behavior only: left merchant fastfilter, right
   confirmed delete, clipping, cancellation, and hit-test isolation.
4. Expose the existing edit callback and merchant bulk rename/reset entrypoint.
   Preserve the old business APIs while using only exact B3M-A3 decoration.
5. Test filter/edit/delete/rename/reset and day-boundary-safe page expansion.
6. Instrument builds and assert that collapse/carousel frames do not rebuild
   log rows, and that initial construction stays bounded for 500+ and 10k
   records.

## Task 7: Integrate Balance mode, surfaces, brand, and shell navigation

**Files:**

- Add:
  `lib/features/transactions/widgets/experimental/balance/balance_dashboard.dart`
- Modify:
  `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify:
  `lib/features/transactions/transaction_home_page.dart`
- Modify:
  `lib/features/shell/expt_shell.dart`
- Modify:
  `lib/features/shell/widgets/spendee_test_bottom_nav.dart`
- Modify:
  `lib/features/shell/widgets/expt_fab.dart`
- Test:
  `test/spendeetest/spendee_dashboard_interaction_test.dart`
- Test:
  `test/features/shell/widgets/spendee_test_bottom_nav_test.dart`
- Test:
  `test/shell/expt_fab_test.dart`

1. Write failing tests proving the existing Settings → Dashboard design → Új
   Spendee route remains intact and the header menu presents exactly one active
   mode among Balance, Budget, and Mind.
2. Add Balance to the existing mode enum/menu/state lifetime. Preserve Budget
   and Mind state and their three-stage controller.
3. Render `BalanceDashboard` only in Balance mode and publish mode changes to
   the retained shell without recreating the store or unrelated pages.
4. Feed the existing shared `_SpendeeBrandLockup` and logo editor into Balance;
   retain edited logo fills across all three modes.
5. Wrap the exact Balance hero foreground in the existing normal/C2/liquid/
   Acrylic surface selection without changing its measured geometry or
   collapse state. Keep mode and surface selection independent.
6. Add an optional FAB gradient to `ExptFab`/`SpendeeTestBottomNav` and pass
   `140deg #6065f5 0%, #8c5cef 52%, #f25cbf 100%` only while Balance is active.
   Budget/Mind and the stable dashboard retain their existing FAB.
7. Run mode/surface/brand/nav interaction tests and capture every required
   mode/surface state.

## Task 8: Produce exact visual and performance evidence

**Files:**

- Add:
  `tool/b3ma3_capture/README.md`
- Add:
  `tool/b3ma3_capture/compare_b3ma3.sh`
- Add generated evidence under:
  `docs/superpowers/evidence/2026-07-25-b3ma3/`
- Update:
  `docs/superpowers/evidence/2026-07-25-b3ma3-parity-manifest.md`
- Update:
  `docs/superpowers/checklists/2026-07-25-b3ma3-flutter-parity.md`

1. Run all focused Node prototype contracts against the unchanged frozen HTML.
2. Serve the reference at port 8790 and capture the exact selector at the same
   412×892 viewport and deterministic content.
3. Capture the production Flutter Balance widget at the same logical viewport
   for every screenshot-matrix row: expanded/collapsed/transition, action
   states, all FastInfo/detail pages, rail scopes, ghost states, summary/search
   gestures, transaction swipe/edit/filter/lazy states, nav, brand editor, and
   all four header surfaces.
4. Generate side-by-side images and 50% alpha overlays with ImageMagick. Inspect
   each image directly. Any visible mismatch returns the corresponding task to
   implementation and leaves the checklist row `NOT DONE`.
5. Run the 500+/10k performance instrumentation and store the bounded-build
   evidence.
6. Re-read the frozen reference and checklist. Update each row only when its
   acceptance condition, test, screenshot, and overlay are all present.

## Task 9: Verify, review, commit, push, build, and deliver

1. Request an implementation review against the checklist, then correct every
   High/Medium finding with a new failing regression test where applicable.
2. Run targeted Flutter tests, all related regression tests, full
   `flutter analyze`, and the complete `flutter test` suite inside Ubuntu
   proot. Record the exact commands and outputs; distinguish any unchanged
   baseline failure from new regressions.
3. Run `git diff --check`, inspect the scoped diff, and verify that no unrelated
   dirty-worktree file will be staged.
4. Re-read the checklist/reference a final time. Do not call the package
   complete if any row remains `PARTIAL`, `BLOCKED`, or `NOT DONE`.
5. Stage only files owned by this implementation, create one descriptive commit
   on branch `spendeetest`, and push it to `origin`.
6. Dispatch `.github/workflows/android-build.yml` for `spendeetest`, monitor it
   to a terminal result, and correct any in-scope build/test failure before
   redispatching.
7. Download the successful APK artifact/release asset into
   `/storage/emulated/0/Download/spendee`, verify it is a valid APK/ZIP and
   record its SHA-256, commit SHA, workflow run, and final absolute path.
