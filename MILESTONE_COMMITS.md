# Milestone commits

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

## 2026-08-03 — Summary scope metrics consistency

- `85f41ab` — **Atomikus SummaryPill + LogBox metrika:** az összeg és a
  tranzakciószám ugyanabból a kanonikus scope-metrics snapshotból érkezik.
  Nyitott railnél mindkettő az aktuális child preview-t követi, teljes child
  indexben a hiányzó naptári bucket valódi nulla, és nincs mother-count
  fallback vagy preview-query.
- Ellenőrzés: 222 Flutter teszt, célzott motion/golden tesztek, tiszta
  Room/core/native bridge GitHub pipeline és a letöltött
  `fluvi_b4745eb.apk` SHA-256 értéke:
  `484277fbcbf5f756487dcca09fc7ca387a3469d789c4196b2b3ef21547c5166b`.
