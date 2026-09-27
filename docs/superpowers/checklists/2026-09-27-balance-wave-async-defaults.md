# Balance asynchronous wave/defaults acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BWA-01 | User §§0, 3, 8, 23 | wave motion core | Existing seam is diagnosed; phase 0/1 geometry and tangent are continuous after the change. | Pure continuity tests and source audit. | DONE |
| BWA-02 | User §§4–7, 17–18 | wave motion core | One shared clock; deterministic card-ID profile, morph and cadence variation; center/side never changes identity. | Pure profile/geometry tests. | DONE |
| BWA-03 | User §§9–11, 20 | wave renderer | Tick is paint-only, all decoration is rounded-clipped, shadow exterior remains uncut, copy/tile above wave, outline above decoration. | Widget/layer/bounds tests and source boundary test. | DONE |
| BWA-04 | User §§12–14, 21 | Balance settings/tuner | Background toggle/opacity, wave opacity and animation controls are co-located and independently preserve values. | Settings and tuner/widget tests. | DONE |
| BWA-05 | User §§1–2, 15–16, 22 | Balance defaults/Header tuning | Time labels default hidden; Balance veil defaults enabled/white; all setters retain user override behavior. | Model/controller tests. | DONE |
| BWA-06 | User §24 | carousel integration | Outer geometry, controller ownership, physics and selected semantics do not change. | Existing canonical/carousel boundary tests. | DONE |
| BWA-07 | User §25 | delivery | Focused tests/analyze, GitHub human APK and local hash evidence complete. | Commands, Actions run and filesystem. | DONE — Actions run 36280839490 human job succeeded for `a393f95e`; local APK SHA-256 is `c72d05c573646bffdeab3e28fe007c2fb180137b5c27ffa95f9b315564c3be07`. |
