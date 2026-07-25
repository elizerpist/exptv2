# B3M-A3 visual comparison evidence — 2026-07-25

This comparison uses the frozen 412×892 browser references and the current
412×892 Flutter goldens. The side-by-side images place the reference on the
left and Flutter on the right. The overlays blend both inputs at 50%.

| State | 50% overlay | Side by side | AE | RMSE |
| --- | --- | --- | ---: | ---: |
| Expanded | [PNG](screenshots/b3ma3-expanded-overlay-50.png) | [PNG](screenshots/b3ma3-expanded-side-by-side.png) | 168135 (0.457505) | 6746.05 (0.102938) |
| Collapsed | [PNG](screenshots/b3ma3-collapsed-overlay-50.png) | [PNG](screenshots/b3ma3-collapsed-side-by-side.png) | 142213 (0.38697) | 5985.1 (0.0913268) |

AE is ImageMagick's absolute-error pixel count with its normalized value in
parentheses. RMSE is reported as quantum-scaled error with normalized error in
parentheses. Outputs were generated with ImageMagick 7.1.2-24 Q16-HDRI.

## Inspection

The major expanded and collapsed section bands are broadly aligned, especially
the collapsed action, summary, search, rail, transaction-list, and bottom-nav
regions. The overlays nevertheless show repeated internal text and control
offsets, so the geometry is not pixel-identical.

Visible mismatches include the Flutter-only hero menu button, `0%` versus `42%`
reserve, expense versus income selection, month pills versus year pills,
different action gradients/icon treatments, and different transaction dates,
merchants, amounts, and ordering. The expanded detail card also differs in
typography, spacing, and displayed values. These differences account for
substantial nonzero AE/RMSE in both states; this evidence does **not** establish
1:1 visual parity.

The full-frame reference is internally inconsistent with the higher-priority
production requirements: it combines an Income-active action with expense-only
data, a monthly summary with a yearly `2024` rail, and a latest-transaction card
that is older than the first transaction-log row. It also omits the mandatory
Balance/Budget/Mind header menu. A normalized approved reference revision using
one deterministic data/type/scope state is required before a meaningful
whole-screen zero-difference gate can be satisfied.

## Input identity

| Input | SHA-256 |
| --- | --- |
| `b3ma3-reference-expanded.png` | `7b8692790e62df0661165cd28b098c5901f9840e26c27363cb0318e1f9c0309a` |
| `b3ma3-reference-collapsed.png` | `c879ead394cee1d5366ac855b09fbdded2fd378f0dc99c6bb4dc55e643c7df9c` |
| `b3ma3_app_expanded.png` | `315c5fb16528279730e7626e8ead8e8a35634e7848e0c78bcc9e90e28e5f8fd3` |
| `b3ma3_app_collapsed.png` | `62fb2e972fb6b8408ab8cd215a4968ce268927b088598792530d14a2ef92f46e` |

## Reproduction

The Flutter evidence is regenerated and then verified without update with the
`B3MA3_CAPTURE_GOLDENS=true` targeted golden test. Derived images and metrics
use these ImageMagick 7 commands:

```sh
magick "$reference" "$app" -evaluate-sequence mean "$overlay"
magick "$reference" "$app" +append "$side_by_side"
magick compare -metric AE "$reference" "$app" null:
magick compare -metric RMSE "$reference" "$app" null:
```
