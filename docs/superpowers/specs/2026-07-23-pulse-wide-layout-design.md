# Pulse széles munkafal – terv

- **Állapot:** végrehajtásra jóváhagyott felületi terv, 2026-07-23
- **Kérés forrása:** „ez most egy nagyon magas html lett, nem lehet rendesen átlátni, úgy csoportosítsd, hogy horizontálisan is terjedjen”
- **Érintett felület:** `docs/prototypes/pulse_engine_panel_mockup.html`
- **Megőrzendő referencia:** a háromcsoportos rail, minden HF-kártya, a döntési nyomvonal és az alsó PNG.

## Cél

A Pulse teljes magasságát ne az okozza, hogy ugyanazon csoport sok, egymás alá
tördelt kártyából áll. A felület egy széles, böngészhető munkafal legyen:
a kapcsolódó kártyák egy sorban, oldalirányban olvashatók; a felhasználó nem
veszít el tartalmat és nem kap új menürendszert.

## Vizsgált elrendezések

1. **Tartalom rövidítése vagy elrejtése.** Nem megfelelő: a Pulse célja pont az,
   hogy minden jel és út megérthető maradjon.
2. **Csak többoszlopos rács asztalon.** Nem megfelelő önmagában: a jelenlegi
   mobilos szabály egyetlen oszlopra tördel, ezért újra nagyon magas lesz.
3. **Vízszintes munkafal, rögzített olvasható kártyaszélességekkel.** Választott
   megoldás: egy sorban több kártya látszik, a többi vízszintesen görgethető;
   a mobilos nézet sem változtatja őket egymás alá.

## Felületi szerkezet

### Folyamatábra

A 01–09 folyamatlépés egy időrendi, oldalirányban görgethető sáv. A kártyák
közötti irányjel jobbra mutat, ezért az olvasási irány egyértelmű marad.
Minden lépés megőrzi a saját várakozó, elvetett, összeállító és megjelenítő
ágait.

### Csoportmunkafal

A három rail-csoport ugyanazt a szerkezetet tartja meg:

1. működési összefoglaló;
2. előrejelzések és számítások;
3. triggerkártyák;
4. történet és közös motorfolyamat;
5. beállítások.

Az 1–3. és a közös motorlépések egy-egy vízszintes kártyasávot kapnak.
Széles képernyőn a 4. és 5. blokk két oszlopban, egymás mellett látszik.
Keskeny képernyőn ez a két rövid blokk visszakerülhet egymás alá, de a hosszú
kártyasávok nem törnek egyetlen oszlopba.

### Olvashatóság és mobil

- A sávoknak saját vízszintes görgetésük van; a teljes oldal nem csúszik ki.
- A kártyák legkisebb szélessége kb. 250–300 px, így a grafikonok és vezérlők
  nem nyomódnak össze.
- A sávok görgetése finoman a kártyák elejére igazodik.
- Telefonon is legalább egy teljes, olvasható kártya és a következő kártya
  kezdete látszik, jelezve az oldalirányú folytatást.

## Változatlan viselkedés

- Pontosan három rail-gomb marad: Keretnyomás, Pénzáramlási nyomás,
  Adatpontosság.
- Az aktív csoport, billentyűzetes rail-navigáció, HF-tulajdonjog, csúszkák,
  döntési nyomvonal, egyetlen felső üzenet és a PNG magyarázat nem változik.
- A `balance_latest_layout.html` nem része a feladatnak.

## Ellenőrzés

Egy új statikus teszt ellenőrzi a munkafal-sávok jelölőit, a folyamatábra
balról jobbra irányát, a három csoport teljes sávlefedettségét és a történet /
beállítás kétsávos asztali elhelyezését. A meglévő Pulse-regressziós tesztek
igazolják, hogy a tartalom és viselkedés változatlan maradt. A szerver HTTP
válaszát is ellenőrizni kell.
