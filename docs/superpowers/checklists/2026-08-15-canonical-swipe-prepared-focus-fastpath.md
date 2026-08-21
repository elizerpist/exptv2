# Canonical swipe and prepared-focus fast path — acceptance checklist

## Architecture card

The committed directional query remains the sole base-query owner.  A focus is
an ephemeral presentation overlay anchored to one exact base-index identity and
revision.  The prepared index owns immutable category/partner membership
ordinals; the focus owner selects or intersects those ordinals and publishes a
focused presentation without changing the base query.  The LogBox renderer is
the sole visible-row painter.  The swipe controller owns only an active entry
identity, offset and phase; it never owns a second row presentation.

## Requirements

| ID | Source | Intended owner/code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SWP-1 | User: single-instance canonical row translation | `dashboard_logbox_render_surface.dart`, swipe controller | The active entry is painted once at `canonicalX + dx`; no overlay clone or white source body remains. | Focused canonical-renderer regression is green; physical visual check pending. | PARTIAL |
| SWP-2 | User: preserve block morphology | Prepared item/group geometry + renderer | Top/middle/bottom/singleton corner and shadow roles remain frozen while translated. | Segment-role unit tests are green; physical visual check pending. | PARTIAL |
| SWP-3 | User: screen-left, no pointer work | Swipe presentation layer | At `dx=-normalLeft` active segment reaches x=0; pointer updates do not prepare scenes, rows, text or data. | Kinematic/gesture regressions are green; physical tracking check pending. | PARTIAL |
| FOC-1 | User: prepared hit is actually ready | `PreparedDashboardIndex`, focus membership | Category/partner membership is compact and precomputed with the base index. | Packed-ordinal membership and directional-overlay tests are green. | DONE |
| FOC-2 | User: no worker/full scan on focus hit | `DashboardCoreController`, focus derivation | Prepared category/partner/intersection/clear requests have no worker, SQL, base scan, serialization or copied prepared rows. | Controller/deriver diagnostics regressions are green; physical latency trace pending. | PARTIAL |
| FOC-3 | User: preserve base / O(1)-style restore | Focus owner + prepared index publication | Base index/root stays retained; clearing final focus reactivates it without reconstruction or repository access. | Retained index/root scene restore test is green; physical transition check pending. | PARTIAL |
| REG-1 | User: retain interaction milestones | Existing rail/vertical/query-sheet owners | Controller, position and physics identities; virtual geometry; no cache misses; route-sensitive speculative gate remain unchanged. | Focused rail/vertical/query-sheet and fast regressions are green; human regression pass pending. | PARTIAL |
| APK-1 | User: human validation | Normal `lib/main.dart` APK | Exact production APK delivered; physical swipe/focus observations remain pending human verification. | GitHub Actions run `31884643249`, `fluvi_HUMAN_DIAGNOSTIC_18b1494.apk`, SHA-256 `a46a8aa4644cb21a03cba8a0ee48c6e41f16ea5a60ab2bcd64559cc7d5e49c75` | PARTIAL |

## Explicit non-goals

- No rail/vertical physics, paging policy, cache-limit or controller-identity
  change.
- No `Dismissible`, row widgets, raster snapshots, per-move layout/text work,
  or golden test.
- Existing uncommitted profile-metric work is deliberately outside this change.
