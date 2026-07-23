# Pulse széles munkafal megvalósítási terv

> **Végrehajtás:** a terv feladatonként, teszt-előbb sorrendben készül.

**Cél:** A Pulse mockup hosszú függőleges kártyahalmait széles, oldalirányban böngészhető munkafallá alakítani a tartalom és a működés megtartásával.

**Érintett fájlok:**

- `docs/prototypes/pulse_engine_panel_mockup.html` – CSS-osztályok és a dinamikusan készülő sávok jelölői.
- `docs/prototypes/pulse_wide_layout_test.js` – új, célzott statikus szerződés.
- `docs/superpowers/checklists/2026-07-23-pulse-wide-layout.md` – elfogadási állapot.

## 1. A munkafal-szerződés

- [x] Hozz létre egy statikus Node-tesztet, amely még hibázik a `data-horizontal-lane` jelölők és a széles csoportelrendezés hiánya miatt.
- [x] Futtasd a tesztet; a hiba oka kizárólag a még hiányzó munkafal legyen.

## 2. Folyamatábra és ismétlődő kártyasávok

- [x] Jelöld a 01–09 folyamatábrát és a csoportok működési, előrejelzési, trigger- és motorlépés-listáját vízszintes sávként.
- [x] Adj közös CSS-szabályt: oldalirányú görgetés, olvasható minimális kártyaszélesség, kártyakezdéshez igazodás és nem zsugorodó kártyák.
- [x] A függőleges folyamatnyilat cseréld jobbra mutató jelre.

## 3. Csoportszintű széles elrendezés

- [x] A `group-panel` legyen kétsávos rács széles képernyőn: a történet és a beállítás egymás mellett, a hosszú sávok teljes szélességben.
- [x] 640 px alatt se írja felül a mobil CSS a hosszú sávokat egyetlen oszlopra.
- [x] Ne változtass JavaScript-vezérlést, HF-tartalmat vagy rail-szerkezetet.

## 4. Ellenőrzés és rögzítés

- [x] Futtasd az új széles-elrendezés tesztet, majd az összes meglévő Pulse statikus tesztet.
- [x] Ellenőrizd a HTML-szintaxist, a whitespace-et és a futó szerver HTTP 200 válaszát.
- [x] Frissítsd az elfogadási lista minden állapotát kizárólag bizonyított DONE-ra.
- [ ] A célzott fájlokat külön commitban rögzítsd; ne érintsd a Balance fájlt vagy a többi munkafa-módosítást.
