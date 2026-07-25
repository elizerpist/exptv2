# Pulse kitöltő munkafal – terv

- **Állapot:** a közvetlen felhasználói kérés alapján végrehajtható, 2026-07-25
- **Kérés forrása:** „rengeteg hely van, töltsd ki a teret, továbbra is nehezen értelmezhető az oldal”
- **Vizsgált referencia:** `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260725-081201.png`
- **Érintett felület:** `docs/prototypes/pulse_engine_panel_mockup.html`
- **Felváltott elv:** a `2026-07-23-pulse-wide-layout-design.md` belső, oldalra görgethető kártyasávjai.

## A képen látható probléma

A Pulse egy keskeny bal oldali oszlopként jelenik meg, miközben a kijelző jobb
oldala üres. A fő információk belső, oldalra húzható sávokba kerültek, ezért
nem látszik egyszerre, hogy a motor melyik része mit követ. Ez nem adat- vagy
motorhiba, hanem az információs elrendezés hibája.

## Választott elrendezés

### 1. Teljes szélességű lap

A Pulse oldalnak nincs 520 vagy 1440 px-es felső szélességi korlátja. A lap a
rendelkezésre álló nézet szélességét használja, belül egységes oldalsó térrel.
Ez a telefonos böngészőben is megakadályozza a keskeny, balra ragadt oszlopot.

### 2. Kitöltő rácsok, nem rejtett sávok

Az egyes kártyacsoportok rácsban töltik ki a rendelkezésre álló szélességet:

| Terület | Széles nézet | Keskeny nézet |
| --- | --- | --- |
| 9 lépéses motorfolyamat | 3 × 3 kártya | 2 oszlop, majd szükség esetén 1 |
| működési összefoglaló és közös motor | 4 oszlop | 2 oszlop |
| előrejelzések | 3 oszlop | 1–2 oszlop |
| triggerkártyák | 4 oszlop | 1–2 olvasható oszlop |
| történet és beállítás | 2 oszlop | egymás alatt |

Nincs a fő információt elrejtő, belső `overflow-x` görgetés. A triggerkártyák
teljes szélességet használnak a saját rácscellájukon belül.

### 3. Ötlépéses értelmező sáv

A részletes 9 kártya fölé egy rövid, teljes szélességű áttekintés kerül:

`Változás → Adatellenőrzés → Helyzet → Fontosság → Felső üzenet`

Ez a felhasználói olvasási sorrend. A 9 kártya ezután ugyanezt bontja ki,
így nem kell a részletekből visszafejteni a motor történetét.

## Változatlan elemek

- A három rail-csoport és a hozzájuk rendelt HF-001–HF-021 jelek.
- HF-008 halasztott állapota, HF-016–HF-019 közös motorjellege.
- Az egyetlen kiválasztott felső üzenet elve, a döntési nyomvonal és a PNG.
- A `balance_latest_layout.html` nem része a feladatnak.

## Ellenőrzés

Egy új, teszt-előbb írt statikus szerződés ellenőrzi a teljes szélességű
lapot, az ötlépéses értelmező sávot és a kitöltő rácsokat. A meglévő Pulse
tesztek őrzik a jeleket, rail-t, döntési nyomvonalat, bemeneti szabályokat és
magyar szöveget. A kiszolgált HTML HTTP 200 válaszát is ellenőrizni kell.
