# Budget Header palette domain and continuous material acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BHP-01 | User / current binding audit | Budget Header policy | Positive-limit Budget no longer samples white→one endpoint; it samples a canonical 10-slot target palette window | RED/GREEN sampler + policy tests and FLOW snapshot | DONE |
| BHP-02 | User | palette catalog | Each of 21 canonical `color_01…color_21` identities deterministically exposes exactly ten distinct-ish slots; canonical identity is in the middle-late identity zone | catalog unit test | DONE |
| BHP-03 | User | palette generator | Lead-in is pale, middle is canonical, tail is richer/slightly shifted without generic rainbow substitution | perceptual/checkpoint tests | DONE |
| BHP-04 | User / Color Lab window contract | window sampler | Progress and live width emit clamped A/B/start/end; no positive limit retains full canonical gradient | sampler/policy unit tests | DONE |
| BHP-05 | User | real Budget binding | Target, TimeRail preview and optimistic limit changes update the live palette window without persistence/I/O or effect restart | policy/presentation boundary tests | PARTIAL — live target/effective-limit binding is covered; final TimeRail/device verification remains pending |
| BHP-06 | User | Header tuner | Existing card has independently collapsible `Header animáció` and `Kategória színskálák` sections | widget test | DONE |
| BHP-07 | User | palette tuner preview | Category colour-scale section lists all 21 source identities and exactly ten swatches per identity | widget/catalog test | DONE |
| BHP-08 | User | tuner geometry | Internal scrolling preserves Header visibility and `placement.top >= headerBottom + gap` | existing + widget placement test | DONE |
| BHP-09 | User | diagnostic owner | Bounded palette/render/effect/debug FLOW events expose id, slots, positions, A/B, mode and render target without frame spam | logger/policy tests | DONE |
| BHP-10 | User / screenshots | Deep Drift shader + skeleton | Default material is continuous/density-led, with directional drift and depth blending; rotation is secondary | deterministic shader/source contract + screenshot/device review | PARTIAL — source/math contract is verified; device visual review remains pending |
| BHP-11 | Protected architecture | Header visual renderer | Per-fragment renderer remains normal path at all visual-quality values; no coarse field, low-DPR buffer or mesh path is selected normally | backend tests + shader inspection | DONE |
| BHP-12 | Protected architecture | motion/data boundaries | Palette/tuner/effect changes do not alter prepared data, query, rail/TimeRail, bridge or physics owners | boundary tests + physics diff | PARTIAL — no physics diff and narrow Header tests pass; full physical interaction/CI evidence remains pending |
| BHP-13 | User delivery | normal APK | Exact pushed normal `lib/main.dart` human APK is downloaded after CI success | Actions + file/hash | NOT DONE |
| BHP-14 | User physical acceptance | Android device | User verifies crisp Header, palette previews/live updates, Depth Drift material, Header visibility and Dashboard interactions | manual device evidence | NOT DONE |
