# Balance wave/defaults acceptance checklist

| ID | Source/reference | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BWD-01 | User §§2–5, 11–12 | `balance_presentation_settings.dart`, tuner | Existing tint/border/wave controls remain independent, preserve stored opacity, and expose exact labels/keys. | 306-test focused controller/widget suite. | DONE |
| BWD-02 | User §6 | carousel state/painter | One shared ambient phase animates only the wave; ON/OFF, static reduced motion, and selection-continuity hold without geometry changes. | `BWD WAVE` painter/geometry widget test. | DONE |
| BWD-03 | User §§7–8 | content-card host | Optional content colored border uses the same selected carousel accent resolver and independent opacity; off retains current neutral baseline. | `BWD Content` paint/independence widget test. | DONE |
| BWD-04 | User §9 | shared ranked resolver | Category/partner page one remain layout twins; rank 1 fixed, 2–5 equal/bounded growth, bottom slack reduced. | `BVC-RANK-STRETCH` shared-layout geometry test. | DONE |
| BWD-05 | User §10 | existing default model owners | All listed startup values seed their requested defaults and normal controller overrides still work. | Default model/controller tests in the focused suite. | DONE |
| BWD-06 | User §§1, 14 | carousel/shared-motion boundaries | No change to outer bounds, focus scale, physics, selection, ranking/data or page order. | Canonical geometry, material and boundary tests. | DONE |
| BWD-07 | Reference `/storage/emulated/0/spendee/reference/carousel2.png` | carousel mini-card renderer | Static default preserves accepted mini-card grammar, tint, outline, wave, icon/title layout. | Direct reference inspection and unchanged `BCL-03` canonical golden. | DONE |
| BWD-08 | User delivery rules | GitHub Actions/APK | Production code commit pushed; exact human job succeeds; normal APK is downloaded, opened/hashed. | Actions run `36275680770`, `build-human-diagnostic-apk` job `108498700651` successful for `ba559a29`; local `fluvi_HUMAN_DIAGNOSTIC_ba559a2.apk` SHA-256 `607331f368a34f8d3613542327a77c18a45bc08489667aa7ef6f88bfb1910276`. | DONE |
