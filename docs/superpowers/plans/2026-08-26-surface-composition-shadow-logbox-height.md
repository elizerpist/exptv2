# Surface composition, shadow and LogBox-height implementation plan

## Goal

Turn the current Card2 boolean into a Split/Unified Budget composition,
introduce central three-state shadows, make LogBox row height a committed
geometry setting, and decouple the seven existing corner families into
independent presentation controls.

## Constraints and evidence

- Baseline is `65031792…`; no changes to the accepted temporal, preview,
  body-order, Segmented reclaim, SearchPill, or protected LogBox query path.
- Existing `DashboardCornerProfile` already owns family endpoints and safety;
  only state projection changes.
- Current LogBox uses `DashboardLogBoxTokens.rowHeight` in manifest, painter,
  hit testing and extent calculation. A visual transform is prohibited.
- Soft shadow source is read-only `spendeetest`: large card
  `Color(0x14524B93), offset (0,9), blur 19`; hero
  `Color(0x3DC359B8), (0,16), 34` plus `Color(0x1F50459C), (0,6), 14`; small
  controls use the dashboard's blurred `black 10%, (0,5), 12` family.

## Implementation sequence

1. Add focused failing model/profile/geometry tests for the four requirements.
2. Refactor the existing Budget style controller to the two-value composition
   enum; add a central envelope-backed Unified shell and retain the pager in
   place so controllers survive.
3. Add central family-aware shadow style/profile and thread resolved shadows to
   current shape leaves and the LogBox CustomPainter.
4. Replace the global corner scalar with one immutable seven-position model;
   keep existing family endpoint formulas and scopes.
5. Add a stepped LogBox height controller/profile. Compile a fresh complete
   vertical manifest per height step, publish it atomically to the same
   committed viewport cache, and re-anchor/clamp the stable position. Thread
   the profile through every paint/hit/extent consumer.
6. Extend the existing hamburger tuner with accessible, grouped controls.
7. Update experiment/customization documentation and checklist status only
   after evidence is obtained.
8. Run targeted and protected Flutter suites in Ubuntu proot, analyze, review
   the diff, commit, push and deliver the CI-built normal human APK.

## Test gates

Every production step follows failing focused tests. The initial known
`dashboard_scroll_milestone_test.dart` diagnostic failure is independently
recorded before it is excluded; no other failure is presumed inherited.
