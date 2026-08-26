# Implementation plan: Spendee 3D material, LogBox pencil, Summary hierarchy

1. Add failing profile/controller tests that pin the reference material
   constants and prove existing style values remain unchanged. Promote the
   depth return contract from shadows-only to a border-plus-shadow material
   only if needed by the exact reference composition.
2. Thread the new material through existing dashboard surface leaves and the
   LogBox custom painter without changing radius, bounds or controller state.
3. Add a prepared `pencil.svg` raster/resource and paint the source-locked
   decorative trailing slot in every LogBox row; cover baseline and enlarged
   row heights, semantics and scroll ownership.
4. Apply the shared prepared-amount typography contract and Segmented visual
   hierarchy/badge changes without altering carousel/navigation callbacks.
5. Extend the existing tuner, documentation and protected regression suites;
   run analysis, CI and human APK delivery.
