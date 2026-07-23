# Pulse – bemeneti adatok ellenőrzése

## Cél

A Pulse ne adjon homályos „bizonytalan adat” súlylevonást. A pontszám előtt, minden érintett számításnál legyen egyértelműen látható, hogy az adat számolható-e, és ha nem, pontosan melyik előrejelzést érinti.

## Kiinduló hiba

A `pulse_engine_panel_mockup.html` folyamatábrájában a `bizonytalan adat −20` csak feliratként létezett. Nem volt mögötte mező, hatókör vagy számítási szabály. Emiatt egy kategorizálatlan tétel akár nem kapcsolódó pénzügyi helyzet fontosságát is homályosan csökkenthette volna.

## Döntés

Az adat állapota **belépési feltétel**, nem általános pontmódosító. A fontossági képletből kikerül a `− bizonytalan adat −20` tag.

### Pontozás előtti adatellenőrzés

| Helyzet | Érintett számítás | Következmény |
| --- | --- | --- |
| Hiányzik az összeg vagy a dátum | Minden olyan jel, amely ezt a tételt használná | Az érintett jel várakozik, nem lesz jelölt és nem kap pontszámot. |
| Hiányzik a kategória | Csak kategóriaalapú jelek: HF-002, HF-012 és HF-020 | Ezek a jelek várakoznak, nem kapnak pontszámot. A teljes költés-, egyenleg- és pénzáramlási számítás változatlanul fut. |
| Várt bevétel még nem érkezett meg | HF-007 és az abból épülő pénzáramlási előrejelzések | Ez nem adathiba: a tény az, hogy a várt bevétel esedékes, de nincs meg. A jel a saját szabályai szerint számolható. |

### HF-021: önálló adatpontossági jel

A HF-021 nem von le pontot egyetlen pénzügyi helyzetből sem. Külön, magyarázó helyzetet jelöl, ha legalább a beállított számú kategorizálatlan tétel legalább 12 órája jelen van. Saját, alacsony fontosságú jelöltként csak akkor jelenhet meg, ha nincs erősebb kész pénzügyi helyzet.

A felület konkrétan kimondja:

- hány tételnek nincs kategóriája;
- melyik számítás marad számolható (teljes költés és pénzáramlás);
- mely kategóriaalapú jelek nem kapnak pontszámot;
- hogy ez nem a tranzakció összegének vagy dátumának bizonytalansága.

## Felületi változások

1. A felső folyamatábra új adatellenőrzési ágat kap a pontozás elé, konkrét mezőkkel és hatással.
2. A képlet csak valódi helyzetmódosítókat tartalmaz; a homályos `−20` eltűnik.
3. A döntési nyomvonal mindhárom példán megmutatja az adatellenőrzés eredményét.
4. Az adatpontossági csoport, a HF-021 kártya és a történet ugyanezt a hatókört ismétli: kategóriahiány nem általános pénzügyi büntetés.

## Elutasított megoldások

- **Egységes −20 levonás:** nem mondja meg, melyik adat rossz, és hibásan érinthet nem kapcsolódó számítást.
- **Általános megbízhatósági szorzó:** matematikailag rendezettnek látszik, de elrejti a felhasználó elől, hogy melyik bemenet hiányzik és mit kell javítania.

## Ellenőrzés

Egy új statikus Node-teszt tiltja a `bizonytalan adat` és `−20` pontlevonás visszakerülését, ellenőrzi a három konkrét szabályt, a HF-021 elkülönítését és a döntési nyomvonal adatokkal feltöltött új szakaszát. A meglévő Pulse tesztek, a beágyazott JavaScript elemzése, valamint a HTML- és PNG-kiszolgálás is zöld kell legyen.
