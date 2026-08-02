# Milestone commits

## 2026-08-02 — Dashboard interaction smoothness

- `2bccd10` — **Summary Pill query smooth működés:** a rail és a Summary Pill
  visszajelzése azonnali és folyamatos; a kezdeti index-előmelegítés,
  megszakítható szövegátmenetek és a stale állapotok közvetlen megjelenítése
  megszüntették az indítás utáni, illetve egymás utáni swipe/fling közbeni
  akadásokat.
- Ellenőrzés: Flutter, Room/core és native bridge tesztek, valamint az online
  Android debug build sikeresen lefutottak.
