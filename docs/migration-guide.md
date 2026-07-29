# Új alkalmazás migrációs útmutató

Ez az útmutató a jelenlegi, több UI- és funkciókísérletet tartalmazó alkalmazásból egy tiszta, új Flutter alkalmazásba való későbbi migráció elveit rögzíti. A cél nem a meglévő forráskód teljes átmásolása, hanem a kiválasztott termékviselkedés, adatmodell és tanulságok kontrollált újraépítése.

## Alapelv: clean-room újraépítés

A jelenlegi alkalmazás a korábbi kísérletek és iterációk története is. Az új alkalmazás specifikációja ezért nem a régi widgetfa vagy állapotkezelés, hanem egy tudatosan elfogadott termék- és interakciós döntés legyen.

Minden jelenlegi funkció kapjon egy állapotot:

| Állapot | Jelentés |
| --- | --- |
| Megtartjuk | A végleges termékbe kerülő, elfogadott viselkedés. |
| Eldobjuk | Kísérlet, duplikáció vagy nem kívánt viselkedés. |
| Később | Értékes, de a kezdeti termékből tudatosan kimaradó funkció. |

Csak a Megtartjuk elemekhez tartozó üzleti szabályokat és elfogadott UI-t szabad átvinni. Régi feature flagek, ideiglenes gesture-patchek és párhuzamos UI-változatok nem költöznek át automatikusan.

## Stabil adatmag az UI előtt

Az új app első stabil rétege legyen UI-független:

- tranzakciók, kategóriák, budgetek és időablakok adatmodellje;
- repository- és lekérdezési réteg;
- adatbázis-séma, verziózott migrációk és konzisztens írások;
- import, export, biztonsági mentés és visszaállítás;
- pénz-, dátum- és lokalizációs formázás.

Ezeket a rétegeket egyetlen képernyőnek sem szabad közvetlenül birtokolnia. Az UI immutable, előkészített view modelleket kérjen tőlük.

## Feature-határok és felelősségek

Az appot feature-ek szerint kell szervezni, például transactions, budget, stats, settings és home egységekre. A core csak közös infrastruktúrát tartalmazzon: navigáció, téma, tárolás, formázás, hibatípusok és diagnosztika.

Egy egységnek legyen egy jól megfogalmazható feladata és publikus szerződése. Ne növekedjen olyan vegyes fájllá, amely egyszerre rajzol chartot, kezel gesztust, számol aggregátumot, ment adatot és birtokol képernyőszintű állapotot.

Nem a sorszám önmagában a probléma: egy 500 soros, egységes carousel kezelhető. Viszont egy több ezer soros, több felelősséget keverő komponens drágán érthető, tesztelhető és módosítható.

## Állapotkezelési szabályok

Az állapot tulajdonosa mindig egyértelmű legyen:

- **Lokális UI-állapot:** fókusz, drag, animáció, átmeneti preview.
- **Feature/képernyő-állapot:** kiválasztott szűrő, megjelenített időablak, betöltési és hibaállapot.
- **Tartós állapot:** felhasználói adat és beállítás a repository/adatbázis rétegben.

Ne kerüljön minden globális store-ba. A közvetlen manipuláció közben a widget vagy annak dedikált koordinátora legyen az egyetlen fizikai állapotgazda; a szülő képernyő csak végleges, jól definiált eseményt kapjon.

### Carousel- és direktmanipulációs minta

Egy belt/carousel három külön állapotot használjon:

1. **physical preview:** a drag és az inertia lokális, olcsó állapota;
2. **settled selection:** a középre snapelt elem;
3. **committed selection:** a repository/filter/chart felé publikált végleges elem.

Az adat- vagy chart-frissítés nem indíthat új fizikai carousel-mozgást, ha a felhasználó épp közvetlenül manipulálja azt. Pointer down eseményre a futó inertia és a várakozó publikálás azonnal megszakítható legyen.

## Renderelés és teljesítmény

Drag közben kizárólag olcsó, lokális vizuális frissítés történjen. A drága lekérdezések, chart-aggregációk és listaépítések csak a megállt, végleges kiválasztás után induljanak, és új interakció esetén megszakíthatók vagy érvényteleníthetők legyenek.

- Előindexelt és cache-elt lekérdezéseket használjunk nagy tranzakcióhalmazhoz.
- A nehéz, tisztán adatjellegű aggregációkat UI-isolaten kívül vagy előre számítva készítsük el; widgetet és platformobjektumot nem viszünk isolate-ba.
- A képernyő helyett csak a ténylegesen érintett részfa épüljön újra.
- Standard Flutter scroll- és gesture-mechanizmus az alapértelmezett; egyedi fizika csak bizonyított UI-igény esetén kerüljön be.
- A release buildben a diagnosztika legyen strukturált, korlátozott és érzékeny pénzügyi adatoktól mentes.

Minden kritikus feature-hez legyen valós adathalmazos teljesítményteszt, például a jelenlegi nagyságrendű tranzakciószámmal. A tesztek ne csak azt ellenőrizzék, hogy a képernyő megjelenik, hanem azt is, hogy egy új pointert az app azonnal tud fogadni, és egy gesztus legfeljebb egy végleges filter publikálását eredményezi.

## Design system és UI-kísérletek

Az új appban legyen közös token-rendszer a színekhez, spacinghez, tipográfiához, surface-ekhez, ikonméretekhez és interakciós állapotokhoz. A közös gombok, listák, szűrők és üres/hiba/betöltési állapotok így nem sok, majdnem azonos változatban jelennek meg.

Az új ötletek külön ui_lab vagy demo route-ban készüljenek. A tényleges feature csak egy elfogadott, végleges változatot használjon. Így a termékút és a kísérleti út nem osztozik instabil állapoton.

## Termékminőség alapjai

Minden feature-re legyen egységes:

- loading, empty, error, offline és jogosultsági viselkedés;
- navigációs és lifecycle-szerződés;
- kis és nagy kijelző, betűméret, billentyűzet, sötét téma, TalkBack és lokalizáció támogatása;
- biztonságos adatkezelés, mentési lehetőség és érzékeny adat nélküli logolás.

## Ellenőrzés és kiadás

Az új appban három tesztszint védje a viselkedést:

1. domain/repository unit tesztek üzleti szabályokra;
2. widget- és integrációs tesztek kritikus gesztusokra és flow-kra;
3. screenshot-referencia és nagy adathalmazos teljesítményteszt a fontos képernyőkre.

Minden feature-csomaghoz legyen elfogadási lista, amely a specifikációt, érintett fájlokat, ellenőrzési módszert és az őszinte státuszt rögzíti. Kiadás előtt a build, a tesztek és a vizuális ellenőrzés együtt szükséges; egyik sem helyettesíti a másikat.

## Migrációs sorrend

Ne az egész régi appot egyetlen lépésben másoljuk át. A javasolt sorrend:

1. funkció-mátrix és elfogadott termékspecifikáció;
2. blank app shell, design tokenek, navigáció és stabil adattárolás;
3. egy kis, teljes vertikális szelet: adat → use case → UI → teszt;
4. kiválasztott Budget-flow a régi kísérleti állapot nélkül;
5. chartok, statisztikák és másodlagos képernyők;
6. import/export, beállítások és kiadási keményítés.

Minden szelet akkor költözik tovább, ha saját tesztekkel, teljesítmény- és vizuális elfogadással rendelkezik. Ez megakadályozza, hogy a jelenlegi app felhalmozott komplexitása automatikusan az új alkalmazás alapjává váljon.
