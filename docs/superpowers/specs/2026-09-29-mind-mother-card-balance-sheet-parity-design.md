# Mind Mother Card and Balance Sheet Parity Design

## Approved source material

- Expected Havi 2 HTML: `html-prototypes/balance-extended-sheet-baseline/index.html`, `Havi 2` canvas.
- Expected Éves HTML: `html-prototypes/balance-extended-sheet-baseline/index.html`, `Éves` canvas.
- Device evidence: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-061327.png` and `Screenshot_20260929-061335.png`.
- Defect evidence: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260929-061344.png` and `Screenshot_20260929-061349.png`.
- Mother-card authority: the existing seamless Mind surface in `mind_dashboard_core_surface.dart`.

## Decision

`DashboardHeaderContentMotherCardBounds` will become the sole geometry resolver
for a settled seamless Header/content mother card. It derives the card from the
Mind contract: Header bounds plus `subheaderEnvelopeBounds`, with the same
reveal factor that Mind already uses. `unifiedSubheaderBounds` is a Mind-only
alias and cannot be the shared input because Budget retains a split subheader
composition. Mind will consume the resolver without a visual change; Balance
and unified Budget will consume it instead of extending their mother card
through the indicator lane. The resulting lower edge is the same semantic
boundary in all three modes.

The Havi 2 and Éves child cards retain the existing `BalanceExtendedSheetLayout`
70/30 and 60/40 allocation, live presentation models, and HTML token owner.
Their incorrect `minimumContentSize` thresholds will be replaced by dimensions
derived from the HTML's 842×1187 mother-card reference and captured
2.2275:1 source-to-logical ratio. At the 412×892 reference viewport, direct
rendering must be selected: a `FittedBox` may remain only for a truly smaller
test/preview host, never for the actual reference allocation.

The direct allocation also requires `95.28` logical pixels of existing
`principalModeContentExtraHeight` at the 412×892 reference metrics. That
extension is resolved in `CoreDashboard` only for the unified, four-section
Balance Havi/Éves scopes, so the Mother Card, child rectangles and downstream
dashboard flow share one geometry source rather than compensating inside card
widgets.

## Boundaries

- UI remains a renderer of the immutable existing Havi/Éves presentations;
  no query, repository, selection, carousel, or time-scope write path changes.
- The new resolver owns only outer mother-card bounds. It owns neither drawing
  nor child allocation. Budget's optional split-mode post-content cascade,
  including its indicator lane, remains downstream of that shared boundary.
- `BalanceExtendedSheetLayout` owns card rectangles; `BalanceAlternativeHtmlTokens`
  remains the only owner of CSS-transcribed typography, padding, radii, and
  colour values.
- Budget's legacy split/cascade transition remains untouched. The shared bounds
  apply only to its settled unified mother card, matching the existing Mind
  endpoint policy.

## Verification

Widget tests first prove that Mind, Balance and settled unified Budget have the
same Header/content mother-card lower-bound rule. Separate Havi and Éves tests
at 412×892 prove source-size text and plot geometry are rendered without a
card-wide `FittedBox` reduction. Focused goldens and the two changed Android
states are the visual evidence; Flutter analysis and boundary tests guard the
centralized ownership.
