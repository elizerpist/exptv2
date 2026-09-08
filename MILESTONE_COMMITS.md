# Milestone commits

## 2026-09-09 — Foreground Phase-A direct-manipulation performance milestone

- Behavioural milestone:
  `e8b73e3e939104164e55b09caf592f84ee59fb14` —
  `fix(dashboard): classify Avatar Phase-A rich fallback correctly`.
- Parent: `b7f168dfee250a2435852e43d2499eee24ca1fb8`.
- Status: **PHYSICALLY ACCEPTED BY THE USER ON ANDROID AS THE BEST-KNOWN
  DIRECT-MANIPULATION PERFORMANCE BASELINE.**
- Physically accepted behavior:
  - Avatar carousel movement is smooth;
  - Time carousel movement is smooth;
  - the current result has the best overall physical interaction performance
    achieved so far.
- This is human physical evidence, not an inferred FPS value and not a claim
  that every correctness edge case is complete.
- Known open defects explicitly excluded from acceptance:
  1. the first Avatar fling loads its data slightly late, while subsequent
     flings become fast;
  2. the refreshed e8 Time trace proves an out-of-prepared-window temporal
     target split and a user-marked target jump;
  3. after that invalid temporal state, Avatar Phase-A admission may throw and
     reject every crossed target while retaining the previous Budget progress;
  4. the healthy primary Avatar flight aged out of the rolling diagnostic
     window and requires a retained flight record.
- Permanent regression policy:
  - no later change may make Avatar or Time physical motion worse;
  - no performance pass may be obtained by dropping semantic targets or data
    publications;
  - preserve stable carousel controller, ScrollPosition and physics identities;
  - preserve one Core, one visible-frame store, one prepared-scene cache, one
    LogBox viewport and one LogBox render surface;
  - preserve exact painter-readable Phase A, latest-wins stale safety and
    target-correlated Header/progress/LogBox paint;
  - preserve zero repository/index/query/TextPainter/rich-scene work at direct
    semantic crossings;
  - preserve dashboard geometry, z-order, clipping and hit-test ownership;
  - preserve Mind/Slider behavior;
  - compare every future candidate physically and diagnostically against e8.
- Rollback anchor: `e8b73e3e939104164e55b09caf592f84ee59fb14`.
- A later candidate must not replace e8 as the preferred milestone until:
  - deterministic correctness gates pass;
  - same-device physical behavior is equal or better;
  - accepted-target counts are not reduced;
  - the user explicitly accepts the later APK.

## 2026-08-30 — Home interaction performance physical baseline

- Functional checkpoint: `dfa90b6741108f824244dbc11a3d73a6c5174472` —
  **milestone: preserve accepted home performance baseline**.
- Status: **PHYSICALLY ACCEPTED BY THE USER ON ANDROID** for Avatar fling,
  time fling, general navigation, and collapse/expand responsiveness. This is
  human physical evidence, not an inferred FPS value or an APK-release claim.
- Focused source verification at the checkpoint:
  `flutter test test/features/dashboard/presentation/dashboard_budget_distribution_drawable_readiness_test.dart --reporter expanded`
  passed **9/9**. An earlier combined widget invocation did not terminate and
  is deliberately not recorded as green evidence.
- Rollback anchor: `dfa90b6741108f824244dbc11a3d73a6c5174472`. If a later
  post-checkpoint commit must be abandoned, the authorized recovery command is
  `git reset --hard dfa90b6741108f824244dbc11a3d73a6c5174472`; it was **not
  executed** while recording this milestone.
- Open defects intentionally excluded from this checkpoint:
  1. a gray rectangular slab during the intermediate collapse/expand swipe
     around the Rhythm/bar-chart region;
  2. Mind's canonical amount-range lifecycle can remain loading and fail to
     mount the intended shared slider.
- Regression policy: subsequent work is limited to proving and repairing
  those two owners. It must not retune fling physics, broad warmup/cache
  policy, Header fidelity, or accepted direct-manipulation pacing without
  specific evidence and before/after comparison.

## 2026-08-26 — Dynamic LogBox geometry generation candidate

- The dashboard permits a stepped presentation row-height preference without
  weakening the committed-geometry contract: every change compiles and
  atomically replaces a complete manifest for the same query/revision.
- The stable Flutter vertical `ScrollController` and `ScrollPosition` remain
  the only scroll owner. The viewport reprojects the same logical page-local
  fraction into the replacement geometry and clamps it; data, query and
  prepared text ownership do not reset.
- LogBox corner/shadow changes remain paint-style inputs; they do not mutate
  the vertical manifest. This is an implementation invariant, not a selected
  height or cosmetic product default.
- Status: **MILESTONE CANDIDATE — AWAITING HUMAN PHYSICAL ANDROID VALIDATION.**

## 2026-08-23 — Seamless continuous Header palette material milestone

- Behavioural milestone: `5187d0e199e586a4bf292a9a9ea39851b8b01e5a` —
  **fix(header): remove palette barriers from animated material**.
- Parent: `ac000c02ee19b61a663f120fc690679853717687`.
- Continuous palette authority, ABI v3 and direct 2-/3-stop canonical sampling
  remain intact. Animated effects now use seam-decoupled source-UV material
  transport with distribution-preserving coordinate bounds; palette colours
  remain one continuous material and no generic seam highlight owns a colour.
- Static Cool is unchanged and the Header retains one shared animation clock.
- Status: **MILESTONE CANDIDATE — AWAITING HUMAN PHYSICAL ANDROID ACCEPTANCE.**
- This Header visual milestone is additive and does not supersede any permanent
  Dashboard interaction regression boundary recorded below.

## 2026-08-17 — Foreground-input-safe Query and LogBox interaction baseline

- Behavioural milestone:
  `8d559cfbb9c31bbe6d6e89b32cf036be3ed94b91` —
  **fix: keep speculative work behind foreground input**.
- Parent: `79ff00c025d5c0b530c59a0eb8e98c06e1b127ff` —
  **fix: make filtered dashboard interaction immediately ready**.
- Status: **PHYSICALLY ACCEPTED AS THE CURRENT DEVELOPMENT BASELINE ON
  ANDROID.** The user reports that the result is visually good.
- This is the current immediate behavioural source of truth, superseding
  `ef651f0` as the preferred physical-development baseline while retaining all
  older milestones as historical regression boundaries.
- The protected behaviour combines:
  - exact Query facet-presentation binding and prepared Query-chip hotsets;
  - input-fair speculative candidate scheduling, with raw-pointer preemption
    of Query and scene work;
  - same-target prepared Query promotion/join rather than cancellation and
    restart, while the expensive clear-all Expense neighbour remains valid and
    speculative;
  - resource-armed O(1) committed vertical activation, preserved
    `DragStartBehavior.down` first-fling continuity, and Flutter `Scrollable`
    as the sole formal vertical drag/ballistic owner;
  - bounded, resumable scene preparation; stable rail/vertical controller,
    `ScrollPosition`, and physics identities; and zero normal
    rendering/readiness-miss diagnostics.
- Regression policy: all future work, including `separated-core-modes`, must
  preserve this milestone unless a deliberately approved redesign proves an
  equivalent or better physical result. In particular, preserve the existing
  prepared-index, scene-cache, committed-viewport-cache, and serial paging
  owners; immutable virtual committed geometry; independent applied income and
  expense Query state; exact candidate staging; fail-closed cache/readiness
  semantics; and no `TextPainter` creation in the render hot path.
- This record is human physical evidence, not a CI/FPS benchmark.

## 2026-08-15 — Smooth dashboard baseline and LogBox viewport follow-up

- Human physical-device reference baseline:
  `6b9276337948cb7a6fa5ac47ad6c284fb94d2adf`.
- Physical acceptance recorded by the user: **Smooth vertical and horizontal
  scroll. No placeholder bug.** This is human Android evidence, not a
  profiler-derived FPS or CI claim.
- This milestone follow-up preserves the protected `155f18b` interaction
  contract while moving bottom-navigation protection into terminal scroll
  content, keeping immutable scroll geometry authoritative before the first
  vertical gesture, and retaining zero-miss fail-closed rendering behavior.
- Regression policy: future work must preserve the single rail/vertical
  controller, position, and physics identities; immutable geometry during
  resource publication; bounded cache ownership; and prepared Query Apply.
- The normal APK for this follow-up remains subject to its own human device
  verification; automated checks only protect the architectural contract.

## 2026-08-14 — Dashboard vertical + horizontal scroll physically approved

- Behavioural milestone: `155f18b62da6fd894f2992567a6d8dd25042f3a9` —
  **refactor: decouple committed scroll geometry from page readiness**.
- Documentation child: `0e2b3d566975c98607b00d64e7bc4aae4512adc2` —
  **docs: record virtual vertical geometry redesign**.
- Status: **PHYSICALLY VERIFIED ON ANDROID**.
- Explicit acceptance: smooth vertical scroll solved; smooth horizontal scroll
  solved.
- Regression policy: this behavioural milestone is a permanent regression
  boundary. Future feature work must preserve its interaction contracts:
  immutable committed virtual geometry during page-resource publication,
  bounded lazy resources, and stable rail/vertical controller, position and
  physics ownership. This records smooth physical behaviour, not a
  profiler-derived 60 fps claim.

## 2026-08-02 — Dashboard interaction smoothness

- `2bccd10` — **Summary Pill query smooth működés:** a rail és a Summary Pill
  visszajelzése azonnali és folyamatos; a kezdeti index-előmelegítés,
  megszakítható szövegátmenetek és a stale állapotok közvetlen megjelenítése
  megszüntették az indítás utáni, illetve egymás utáni swipe/fling közbeni
  akadásokat.
- Ellenőrzés: Flutter, Room/core és native bridge tesztek, valamint az online
  Android debug build sikeresen lefutottak.

## 2026-08-02 — SummaryPill presentation motion restored

- `6d844dc` — **Elfogadott SummaryPill motion:** minden valódi rail tick a
  mother title és child subtitle közös, kicsi Y-impulzusát adja; a SummaryPill
  horizontális navigációja X+fade átmenettel folytatódik, miközben a rail
  fizika, query útvonal és az azonnali amount frissítés változatlan marad.
- Ellenőrzés: 54 célzott motion/rail/query/gesture/golden teszt, tiszta
  changed-source analyzer, valamint sikeres online Android build és letöltött
  `fluvi_6d844dc.apk`.

## 2026-08-02 — Summary interaction performance regression repaired

- `7daa33d` — **Repaint-path izolálás:** a SummaryPill drag és shell-return
  frame-jei csak a teljes pill paint transformját frissítik; a rail tick csak
  a navigation text Y-impulse lane-jét. A query, az amount és a rail physics
  nem épül újra ezen a hot pathon.
- Ellenőrzés: 27 célzott és 31 védett rail/query/motion/golden teszt,
  Flutter analyzer, valamint sikeres online Flutter/core/bridge/debug-APK
  pipeline. A kiadott `fluvi_7daa33d.apk` SHA-256 értéke ellenőrizve:
  `8dd29831eb5976563e4b42a5a59ec354ac50a90c4e44574c045a5288b5fdb3df`.
