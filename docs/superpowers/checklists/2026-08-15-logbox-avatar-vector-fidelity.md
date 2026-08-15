# LogBox Avatar Vector Fidelity Checklist

## Architecture card

### Scope and sources

- User correction (2026-08-15): the pixelated visual element is the LogBox
  transaction avatar, not the dashboard direction wallet/bag artwork.
- Physical evidence: the supplied visual report; currently available
  screenshots do not expose materialized LogBox rows, so the source path is
  inspected alongside the device finding.
- Existing owners:
  - `PreparedVectorAssetAtlas` owns bounded prepared avatar resources.
  - `DashboardLogBoxRenderSurface` paints visible rows only.
  - `DashboardLogBoxTokens` owns the 34 logical-pixel avatar geometry.

### Single source and write path

| State/resource | Owner | Write path | Publication rule |
| --- | --- | --- | --- |
| Category avatar background and glyph | `PreparedVectorAssetAtlas` | Bootstrap prepares catalog-bounded resources | No resource is row-owned or decoded during paint. |
| Avatar geometry | `DashboardLogBoxTokens` | Existing token source | `avatarSize=34`, `avatarIconSize=18` remain unchanged. |
| Visible-row paint | `DashboardLogBoxRenderSurface` | Existing painter | Paint transforms and draws prepared resources only. |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Avatar resource cache | `PreparedVectorAssetAtlas` | Extend the one existing atlas; no new cache or registry | Atlas lifecycle and render-path tests. |
| Category gradients | `CategoryColorCatalog` | Reuse immutable gradient tokens | Prepared vector badge test uses catalog handles. |
| Avatar geometry/render flow | Existing LogBox tokens/surface painter | Preserve; replace only prepared resource representation | Structural surface test. |

## Acceptance requirements

| ID | Source instruction | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| AV-01 | User visual correction | `prepared_vector_asset_atlas.dart` | A LogBox avatar's badge and glyph are prepared, catalog-bounded `ui.Picture` resources; no avatar component is a `ui.Image` raster sprite. | RED/GREEN atlas structural and lifecycle tests | DONE |
| AV-02 | Existing hot-path contract | `dashboard_logbox_render_surface.dart` | Each visible avatar paint is transform + `drawPicture`; no `drawImage*`, shader creation, SVG parsing, `saveLayer`, or `TextPainter` in the avatar path. | Focused surface structural test | DONE |
| AV-03 | Existing visual geometry | `dashboard_mode_palette.dart` | 34/18 avatar dimensions, color gradients, row layout, and visible-only painter behavior remain unchanged. | Token/diff inspection + focused render test | DONE |
| AV-04 | Resource bounds/ownership | Atlas tests | Resources are built once per catalog entry, are not row-count dependent, and are disposed exactly once by the atlas. | Lifecycle test | DONE |
| AV-05 | Protected Query/scroll systems | Query and milestone suites | Query first paint and protected vertical/horizontal scroll contracts stay green without ownership/physics changes. | Existing focused regression suites | DONE |
| AV-06 | Human delivery | GitHub Actions and normal APK | Pushed production SHA produces/downloads the normal `lib/main.dart` human APK with a verified SHA-256. | CI + artifact SHA | DONE |
| AV-07 | Physical visual acceptance | Normal Android app | A human verifies that full LogBox avatars (badge plus glyph) are sharp at device DPR, while Query first paint and the protected scroll milestone remain visually intact. | Manual Android test with the delivered APK | NOT DONE — awaiting human device verification |

## Verification evidence

- RED: on `d69be6d`, the new structural regression failed because
  `PreparedLogBoxVectorBadge` and the vector badge painter path did not exist;
  the legacy runtime reported two raster surfaces (badge atlas plus group
  surface), not one.
- GREEN: `flutter test test/core/assets/prepared_vector_asset_atlas_test.dart`
  passed 7 tests after the atlas now creates catalog-bounded vector badge
  pictures exactly once and reuses them across DPR-specific group surfaces.
- Focused regressions passed: stable LogBox surface (11), Query preview paint
  (3), dashboard scroll milestone (3), vertical viewport (4), and current
  Query controller (2).
- `./scripts/test-fluvi-fast.sh` passed all 176 tests.
- `./scripts/verify-fluvi-boundaries.sh` passed and full `flutter analyze
  --no-pub` reported no issues.
- GitHub Actions run `31855222157` succeeded for `test-flutter`, `test-core`,
  and `build-human-diagnostic-apk` for production SHA
  `9b311164f5c27151fd7931471b22a9b694044f26`.
- The normal `lib/main.dart` profile artifact was downloaded to
  `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_9b31116.apk`.
  Its 71,996,774-byte SHA-256 is
  `5cb87806d870f1fc0f73d3eb4409c68295a68208e78ee17dd696719641f87fce`,
  matching the published release digest.
