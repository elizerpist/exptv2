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
