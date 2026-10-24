# Shared Mother Card motion evidence

Historical reference: `2e809f2a5538f9ab637aa882da9231bc697f083e`.

`old-geometry.json` records a historical pure-math oracle independent of the
replacement production motion policy. Viewport: 412 × 892; default body order;
no physical rail. Both unstretched and 48-unit stretched layouts are included.
Progress means normalized master separation, not elapsed wall time or a
second easing curve.

The content rectangles are deterministic authored layout envelopes, not
pixel-detected chart ink. Budget uses its actual lower cascade card envelope
(`lower.top + zone2.height * lower.scale`). Balance uses its old analytical
parent transform on the canonical focused body allocation: the joined card body
minus the existing 12-unit outer inset at each vertical edge. Mind uses the transformed unified
subheader envelope. `visibleContentBottom` clips that envelope to the old
physical bottom. In Mind a negative body-minus-unclipped-content gap indicates
that the old shrinking body cuts into its larger content allocation; it does
not demonstrate good containment.

The `old-budget-*` PNGs are actual production material renders from the
existing exported detachment fixture, with no supplied Budget controller.
They show Header/body material and corners; they do not show actual Budget
avatars/chart. `old-mind-*` uses the existing Mind detachment fixture with its
query control, without a supplied data heatmap. These material baselines must
not be described as visual verification of populated analytical content.

Evidence capture is explicit through
`dashboard_mother_card_evidence_test.dart` and
`--dart-define=MOTHER_CARD_EVIDENCE=old` or `new`. Raster extraction runs through
`WidgetTester.runAsync`; no screenshot is synthesized from geometry data.

`old-balance-*` uses the actual rich month fixture and frozen historical
production renderer, geometry and focused layouts. Those temporary Dart
snapshots were removed after the successful capture. The 50% historical
Balance image was inspected: the analytical content ends around y=469 while
the material continues to approximately y=570, consistent with the deterministic
canonical envelope y=471.582 (layout padding includes more than chart ink).

`dashboard_mother_card_real_content_evidence_test.dart` captures live full
CoreDashboard surfaces with bootstrapped controllers, year scope, and the
accepted interactive content. It is opt-in through MOTHER_CARD_REAL_EVIDENCE.
The ledger is empty; charts and avatars are real widgets with empty data.
`baseline-real-real-*` is an integration-stage capture before the shared physical
rewrite, already containing the first Balance selector refactor and using the
default test font. It is not an exact all-mode `2e809f2` reference and must not
be used for pixel-parity claims against `new-real-*` (which explicitly loads
Inter). Exact historical comparisons use the separate `old-*` fixtures.

`old-populated-budget-*` and `new-populated-budget-*` render the same nonempty
prepared two-category distribution (Food 60%, Rent 40%) through the real Budget
surface and stable presentation, drawable, avatar-rail and page controllers.
The fixture constructors come from the existing distribution pager regression
fixture. The historical render used two temporary frozen production Dart
sources; those were removed after capture. Expanded old/new images are byte
identical after the final lower-boundary fade was introduced. Final 35%, 50%,
and 65% populated frames were inspected: the donut now fades smoothly before
the corrected physical edge. The paint-only fade extent is four existing
Mother Card gaps multiplied by separation; the lower transform and its own
opacity are unchanged.

`new-mind-*` supplies twelve nonempty monthly contributions to the actual year
heatmap. `new-balance-focused-*` supplies the rich month projection and enables
the accepted focused perspective selector so its upper/lower cascade can be
reviewed. These populated scenes complement the full empty-ledger dashboard
captures. The latter preserve real controller topology and controls geometry,
but cannot independently establish meaningful chart clipping quality.

The earlier focused captures are retained as timing history. They demonstrate
the former failure: the selector entered the Header before the lower analytical
content reached its visual region.

## Phase 1 — unified Header cleanup

`phase1-header-*` is a 32-frame rendered Flutter capture from the cleanup
branch. Each of Budget, Balance, focused Balance, and Mind has the same
dynamic plum Header frame at 0%, 5%, 20%, 35%, 50%, 65%, 80%, and 100%
master separation. It is generated with:

```sh
flutter test --dart-define=MOTHER_CARD_EVIDENCE=phase1-header \
  test/features/dashboard/presentation/dashboard_mother_card_evidence_test.dart
```

The inspected 0% contact frames have one continuous Header/Card boundary;
the 20–80% frames have a white Mother Card surface with only the Header's
soft physical shadow in the detached gap. There is no Header-colour wash,
white one-pixel visual inset, or default Header outline. The images are
actual `RenderRepaintBoundary` captures with the Header visual engine active.

## Phase 2 — upper avatar cascade retiming

`phase2-avatar-populated-budget-*` and `phase2-avatar-balance-focused-*` are
actual Flutter captures at 0%, 20%, 35%, 50%, 65%, 80%, and 100% master
separation. The Budget capture prepares the production vector atlas and uses a
nonempty two-category avatar rail; the Balance capture uses the focused Month
perspective selector and analytical chart.

The shared presentation adapter maps normalized separation as `f(s) = s³`.
It changes only the upper avatar/perspective lane. The shared Mother Card and
the lower analytical transform continue to consume the original master cascade.
The inspected 35% and 50% captures show lower content behind visible avatars;
the 65% capture shows the avatar layer entering the foreground Header's
occlusion. The two moments are distinct in both Budget and focused Balance.
