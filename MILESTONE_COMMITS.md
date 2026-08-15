# Milestone commits

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
