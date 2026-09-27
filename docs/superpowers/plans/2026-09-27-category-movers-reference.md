# Category movers reference-locked implementation plan

**Approval:** the supplied reference-locked specification and the user's
explicit instruction to keep working authorize this plan.  Execute inline:
the projection, formatter, card and default owners are serially coupled, so
parallel edits would increase merge/review risk.

1. **Preflight and ownership audit — complete before edits**
   - Record clean branch/HEAD, inspect `change.png`, the movers projection,
     existing card, outer host, defaults and focused tests.
   - Record that current projection truncates the global impact list before
     the UI can filter it; this is the architectural gap behind the two lists.

2. **Red tests: projection and presentation adapters**
   - Add failing tests for negative/positive bounded ranking, current-sign
     continuity, all window formatting variants, and cumulative fixture
     `[100,0,200] → [100,100,300]`, `[50,0,70] → [50,50,120]`.
   - Run only these tests in Ubuntu/proot and save the red result.

3. **Implement immutable presentation changes**
   - Extend the existing single prepared-membership projection result with
     `topDecreases`/`topIncreases` and retain `movers` for carousel identity.
   - Add pure Hungarian window/scope formatting and cumulative chart values
     outside the painter.  Re-run the focused tests green.

4. **Red tests: defaults and two-page widget contract**
   - Add tests for all five requested defaults plus setters, page-one title,
     copy, real segmented selection/rows/footer, page-two three-tile contract,
     dynamic labels, chart key and back transition.
   - Run targeted tests red before widget/default code.

5. **Implement canonical defaults**
   - Change only the default owners: separator default, explicit body order,
     shell defaults.  Preserve existing setters and controls.  Run focused
     defaults tests green.

6. **Implement the reference card body**
   - Add a single Movers visual-token source.
   - Pass existing stretch height to the card without outer geometry changes.
   - Replace the old axis/bar/four-metric renderers with the reference-locked
     Page 1 and Page 2 skeletons, semantic controls, exactly three tiles,
     prepared stepped cumulative chart, endpoint labels and exact footers.
   - Preserve selected-category invalidation on upstream changes and use
     reference row/list/chart stretch allocation only inside the supplied card
     height.

7. **Verification and visual review**
   - Run focused application/widget/default tests, format changed Dart files,
     then full `flutter analyze` and relevant full dashboard test groups in
     Ubuntu/proot.
   - Reopen `change.png`, inspect the rendered/screenshot evidence if the
     local harness supports it, and update the checklist item-by-item.
   - Request code review, address findings, commit only the scoped changes,
     push, monitor the exact GitHub Actions human APK, download it to
     `/storage/emulated/0/Download/fluvi`, record SHA-256, then report.
