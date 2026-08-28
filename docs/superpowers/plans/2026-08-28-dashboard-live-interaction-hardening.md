# Plan — dashboard live-interaction hardening

## Baseline and invariants

- Work only in the existing linked `separated-core-modes` worktree; do not
  switch/reset/stash. Baseline is `731cda5b` after the palette prototype.
- Drive `Fluvi Logs` revision 47 and `MILESTONE_COMMITS.md` are preflight
  inputs. Compare old code through `git show`, not checkout.
- Maintain one LogBox `ScrollController`/`ScrollPosition`, prepared caches,
  current Budget scope semantics, current scope-aware Spending Rhythm and
  category-palette prototype.

## Execution sequence

1. **Forensics + RED tests.** Add real selector pointer fling, reset-owner,
   held-publication, category/partner composition, amount-rect, SUM-polar and
   SearchPill tests. Record current failure evidence before production edits.
2. **Reset/motion.** Replace mounted-selector broadcast cancellation with a
   reset-command owner token, and replace fragile global motion bookkeeping
   with owner-safe leases only where source proves it is required.
3. **Live frame/facets.** Introduce coordinator/frame and directional
   composable facet state. Extract the legacy prepared membership derivation
   into effective-projection derivation. Migrate temporal, avatar, category,
   partner acceptance to synchronous generations; split critical first
   prepared publication from optional rich-scene installation.
4. **Visual regressions.** Remove focus-publication coupling from partner
   swipe; give amount crossfade its invariant slot; fix SUM polar mapping and
   repaint inputs for every active health-scale style.
5. **Search and presentation.** Implement SearchPill using the same facets,
   then tuner settings for facet style and placement plus one chrome-layout
   authority.
6. **Verification/delivery.** Re-read this checklist, run targeted/protected
   proot test suites, `flutter analyze`, `git diff --check`, review diffs,
   commit focused buildable changes, push, monitor the exact SHA’s normal human
   Android APK job, download it to `/storage/emulated/0/Download/fluvi`, and
   record SHA-256. Complete physical Android matrix before claiming DONE.

## Test-first file map

- Summary: existing `dashboard_summary_auto_reset_controller_test.dart`,
  summary experiment/widget tests, and CenteredCarousel pointer tests.
- Interaction/facets: new focused coordinator/projection tests beside
  `dashboard_ephemeral_focus_controller_test.dart` and
  `dashboard_ephemeral_focus_deriver_test.dart`; migrate old semantic tests.
- Partner/category: existing Core focus and partner swipe tests with a
  `Completer` publication gate; no wall-clock waits.
- Amount/ring: summary amount widget geometry tests and pure
  `BudgetProgressRingGeometry`/painter tests.
- Search/pills: LogBox header, prepared filter, facet chip, chrome layout and
  semantics widget tests.

## Review checkpoints

After steps 2, 3/4, and 5: inspect `git diff --check`, run the affected tests,
and re-check `REG-01`. Do not merge unrelated prototype changes into the
feature diff and do not report physical acceptance based only on tests.
