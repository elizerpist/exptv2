# Center Badge Polish Checklist

Source:
- User feedback on 2026-07-06 after commit `d339020`: the belt is much better, but every tick makes the logo jump/flash and the release spin can stutter after a fast swipe/release.
- User requirement: an incoming side badge must not grow visually larger than the focused badge; when it snaps into focus it must not abruptly shrink and then show the circle progress bar.
- User requirement: tapping the center-badge backheader background must not open the limit sheet; only tapping the actual badge may open/adjust the badge behavior.
- User requirement: move the header card budget trigger chip from the left side to the right side.
- User feedback on 2026-07-06 after commit `01ae71d`: icons still flash on some ticks; the circle progress bar grows separately from the badge and looks like an extra padded ring.
- User requirement: the circle progress bar must be the badge border, not a separate larger ring around the badge.
- Workflow requirement: keep work in small checklist-backed steps; do not make a partial commit/build.

Root-cause notes:
- The current wheel renders active and preview badges with different widget trees: `_CenterActiveBadge` has a 78 px ring canvas plus a 58 px inner badge, while `_CenterPreviewBadge` is a solid circle that can grow to the full slot size. At tick, the same item changes renderer, key shape, and ring visibility.
- The release path calls `widget.onActiveItemChanged` on every inertia tick, which can trigger the expensive home rebuild seen in earlier logs and makes fast throws stutter.
- The whole `backheader-experimental-surface` currently has `onTap: () => _tap(current)`, so empty center-badge background taps can open the limit sheet.
- `header-budget-trigger-chip` is positioned with `left: 30`.
- Follow-up root-cause hypothesis: `_CenterBadgeVisual` still paints the progress ring in a larger padded `Positioned.fill` canvas while the badge fill is a smaller `Container`, so the ring grows as a separate outer object instead of as the badge border.
- Follow-up root-cause hypothesis: preview widgets use slot-based child keys such as `backheader-center-preview-next-1`; when an item crosses a tick boundary the same logical item is rebuilt under a different preview/active subtree, which can recreate the icon subtree for a single frame and show a flash.
- Follow-up RED verification: `centerBadgeBudget progress ring is the badge border` failed with active ring `70x70` vs active fill `58x58`.
- Follow-up RED verification: `centerBadgeBudget badge icons do not use async placeholders` failed because the center badge icon subtree contained `FutureBuilder<String>`, which can show the generic placeholder icon for a frame when rebuilt.
- Follow-up GREEN verification: both new targeted tests passed; full `centerBadgeBudget` targeted run passed 21/21; full `category_budget_stage_test.dart` passed 64/64.
- Follow-up final verification: `flutter analyze` passed with `No issues found`; full `flutter test --reporter compact` passed 584/584; `git diff --check` passed.
- RED verification: centerBadgeBudget targeted run failed before production changes on missing `backheader-center-preview-fill-next-1`, background tap calling `onItemTap`, and drag/fling firing external selection before settle; header layout targeted run failed with right margin `324.0` instead of `30.0`.
- GREEN verification: centerBadgeBudget targeted run passed 19/19; full `category_budget_stage_test.dart` passed 62/62; full `header_layout_test.dart` passed 19/19; `flutter analyze` passed with `No issues found`; `git diff --check` passed; full `flutter test --reporter compact` passed 582/582.

| ID | Source Instruction | Intended Code Area | Acceptance Condition | Verification Method | Status |
| --- | --- | --- | --- | --- | --- |
| CBP-01 | "minden ticknél ugrik/villan a logo" | `_CenterBadgeWheel` and badge visual widgets | Active and preview slots use one consistent visual structure so an item crossing center does not switch from a solid preview circle to a different active ring widget. | Widget test inspects incoming/focused badge geometry and key renderer continuity; targeted center badge tests pass. | DONE |
| CBP-02 | "animáció megakad... gyors swipe gyors release" | Center belt inertia tick propagation | Fast release keeps local belt movement smooth and does not fire expensive external active callbacks on every inertia tick; final active item is flushed after spin. | Widget test asserts fling updates external selection only after settle while debug logs still show inertia ticks. | DONE |
| CBP-03 | "grow során a max méret annyi legyen, amennyi a fókuszban lévő badge mérete" | Center badge sizing/rendering | Incoming badge's visible colored center never exceeds the focused badge's visible center; the ring canvas can scale to the active slot but the fill does not overshoot. | Widget test compares active button visible size to incoming near-center visible size. | DONE |
| CBP-04 | "circle progress bar" must not pop in abruptly | Center badge preview ring rendering | Preview slots use the same ring canvas/progress painter structure, so a centered incoming item does not gain a new ring widget only after the tick. | Widget test verifies preview contains a center progress ring before it becomes active. | DONE |
| CBP-05 | "ha a user a backgroundra tappel, ne triggerelje a limitshettet, csak ha a badgere tappel" | `CategoryBudgetStage` center backheader tap handling and center badge tap | Center-badge surface background taps do not call `onItemTap`; tapping `backheader-center-budget-button` still calls `onItemTap` for the current badge. | Widget test taps background vs badge and checks callback count. | DONE |
| CBP-06 | "header card chip gombját ... jobb oldalra" | `TransactionHeaderCard` | `header-budget-trigger-chip` is right-aligned with the existing 30 px margin instead of left-aligned. | Header layout widget test compares chip right margin. | DONE |
| CBP-07 | Local verification and single final workflow | Tests, analyze, git/build workflow | All CBP items are DONE before one final commit/push/build; no partial commit/build. | `flutter analyze`, targeted tests, full relevant tests, GitHub Actions result, APK hash if built. | DONE |
| CBP-08 | "minden ticknél villannak az ikonok, de nem mindig" | `_CenterBadgeVisual` icon subtree | Center badge category icons avoid the async stroke-rewrite `FutureBuilder` path that can briefly render a generic placeholder icon when a tick rebuilds the badge subtree. | RED/GREEN widget test verifies active and preview center badge icons do not contain `FutureBuilder<String>`. | DONE |
| CBP-09 | "circle progress bar border... legyen a badge borderje" | `_CenterBadgeVisual` ring/fill composition and painter | Progress ring uses the same diameter as the badge fill border, not a larger padded outer canvas; it scales exactly with the badge fill. | RED/GREEN widget test compares preview/active ring CustomPaint size to badge fill size. | DONE |
| CBP-10 | Follow-up verification without partial build | Tests, analyze, git/build workflow | CBP-08 and CBP-09 are DONE before commit/build; no partial commit/build. | Targeted widget tests, relevant suite, `flutter analyze`, full `flutter test`, `git diff --check`, final commit/push/build if requested/needed. | DONE |
