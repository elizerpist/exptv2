# Pulse jel-szabálytábla és történetépítés

- **Állapot:** tervezési szerződés, 2026-07-23
- **Kérés forrása:** „mi a következő lépés a tervezésben?” → „tervezd meg”
- **Munkafelület:** `docs/prototypes/pulse_engine_panel_mockup.html`
**Elsőbbség:** a `2026-07-23-pulse-adatellenorzes-design.md` szabályai elsőbbséget élveznek a régebbi, általános adatminőségi vagy `−20` levonási elvekkel szemben.

Ez célállapot-terv. A jelenlegi HTML szerepkiosztása addig változatlan, amíg egy külön végrehajtási lépés ezt a jel-szabálytáblát be nem építi.

## Cél

Minden HF-jelről ugyanazzal a pontossággal lehessen válaszolni ezekre a kérdésekre:

1. Miből számol?
2. Mikor nem számolható vagy mikor vár?
3. Milyen valós változás indítja el?
4. Indíthat-e önálló helyzetet, vagy csak alátámaszt?
5. Miért erősebb vagy gyengébb egy másik helyzetnél?
6. Melyik mondatrészt írhatja?
7. Mikor ismételhet újra?

A cél nem 21 különálló kis motor. Egyetlen, átlátható motor készül, amelyben minden jel ugyanazt a szerződést követi.

## A négyrétegű motor

~~~text
ellenőrzött kiinduló adatok
  → nyers jel
  → összetartozó helyzet
  → fontossági sorrend
  → mondatrészekből épített felső üzenet
  → megjelenés és ismétlés
~~~

### 1. Kiinduló adatok ellenőrzése

Ez nem pontozás. Minden számítás az alábbi négy állapot egyikét kapja:

| Állapot | Jelentés | Következmény |
| --- | --- | --- |
| `számolható` | Minden szükséges bemenet megvan, a képlet értelmezhető. | A jel továbbmehet. |
| `korai becslés` | A bemenetek megvannak, de kevés még a megfigyelés egy önálló előrejelzéshez. | A felületen látszik, de nem indít önálló helyzetet és nem kap pontszámot. |
| `várakozik` | Egy szükséges bemenet ideiglenesen hiányzik. | Csak az érintett jel áll meg, pontszám nélkül. |
| `nem alkalmazható` | A képletnek nincs értelmes értéke, például nincs bevétel az arányszámhoz. | Nem készül jel; ez nem hibaüzenet. |

Kötelező szabályok:

- Hiányzó összeg vagy dátum csak azt a számítást állítja meg, amely azt a tételt használná.
- Hiányzó kategória csak HF-002, HF-012 és HF-020 esetén állítja meg a számítást.
- A teljes költés, az egyenleg, a fix kiadás és a pénzáramlás ettől tovább számolható, ha az összeg és dátum megvan.
- A várt, de még meg nem érkezett bevétel nem adathiba: HF-007 a tényállást, az esedékességet és a beérkezés hiányát számolja.
- A korai becslés nem kap rejtett levonást. Több adat vagy kapcsolódó, tényalapú jel kell hozzá, mielőtt önálló helyzetet indíthat.

### 2. Nyers jel

Minden HF ugyanazt a szerződést adja vissza:

~~~text
jelazonosító
cél és időszak
számolhatóság
zóna és irány
valós változás
helyzetkulcs
helyzetindítási jog
mondatszerep
fontossági alapérték vagy bizonyító szerep
helyzetazonosító
~~~

A helyzetindítás és a mondatszerep külön fogalom. Egy közeli fix kiadás például elindíthat pénzáramlási helyzetet, de egy tágabb hónap végi helyzetben inkább az „és még 42 000 Ft fix kiadás várható” okmondatot írja.

### 3. Összetartozó helyzet

Azonos `helyzetkulcs` nélkül jelek nem adódhatnak össze.

| Helyzetkulcs | Összetartozó jelek |
| --- | --- |
| `havi-keret/{hónap}` | HF-001, HF-003, HF-004, HF-013 és releváns fix kiadás vagy várt bevétel |
| `kategória/{kategória}/{hónap}` | HF-002 és HF-012 |
| `éves-kategória/{kategória}/{év}` | HF-020 |
| `havi-pénzáramlás/{hónap}` | HF-005, HF-006, HF-007, HF-009, HF-010, HF-011 |
| `pontszám/{időszak}` | HF-014, csak háttérmagyarázatként |
| `adatállapot/{hónap}` | HF-021, önállóan |

HF-021 nem lehet pénzügyi helyzet alátámasztása, nem írhat pénzügyi óvatossági mondatrészt, és nem csökkenthet pénzügyi pontszámot.

## Fontossági sorrend

Pontszámot csak számolható, új vagy érdemben megváltozott, kész helyzet kap:

~~~text
fontosság = legfeljebb 100(
  vezető jel alapértéke
  + pénzben érdemi hatás: +15
  + 3 napon belüli esedékesség: +10
  + ugyanahhoz a helyzethez tartozó, számolható alátámasztás: +10
)
~~~

Nem része a képletnek:

- hiányzó vagy részleges adat;
- korai becslés;
- elutasított vagy már megmutatott azonos helyzet;
- némítás, ismétlési szünet vagy háttérben lévő alkalmazás;
- csoportbeállítás, amíg annak pontos képlete nincs kiírva.

Ezek kapuk, nem levonások. A „miért erősebb?” válasz így mindig a vezető jelből, a pénzben érdemi hatásból, az időzítésből és a kapcsolódó bizonyítékból áll.

### A pénzben érdemi hatás pontos feltétele

| Vezető jel típusa | Akkor kap `+15`-öt, ha |
| --- | --- |
| Havi vagy éves keret: HF-001, HF-002, HF-020 | a keret fölé várható vagy tényleges eltérés legalább `max(10 000 Ft, a keret 10%-a)` |
| Fix teher vagy közeli fix kiadás: HF-005, HF-006 | az érintett összeg legalább `30 000 Ft`, vagy a havi bevétel legalább 10%-a, ha az kisebb küszöböt ad |
| Hiányzó várt bevétel: HF-007 | a késő vagy hiányzó összeg legalább `30 000 Ft` |
| Bevétel–kiadás arány vagy megtakarítási cél: HF-009, HF-010 | a zónaátlépés mögötti várható havi hiány legalább `10 000 Ft` |
| Tartalék: HF-011 | nem kap külön `+15`-öt; a tartalékzóna már az alapértékben fejezi ki a súlyosságot |
| Költési trend: HF-012, HF-013 | nem kap külön `+15`-öt; a saját 10 000 Ft-os belépési feltétel már megakadályozza a kettős számítást |
| Adatállapot: HF-021 | soha nem kap pénzügyi `+15`-öt |

Minden küszöb látható, alapértelmezett érték. Későbbi felhasználói beállítás csak a saját küszöbét módosíthatja; a választott érték és az ebből eredő `+15` a döntési nyomvonalon egyszerre látszik.

### Javuló helyzet

Javulás csak akkor indíthat felső üzenetet, ha a korábban megmutatott, legalább 65 alapértékű kockázat valóban megoldódott vagy jobb zónába került. A javuló helyzet a megoldó jel normál alapértékével indul, nem kap automatikus jutalompontot, és nem jelenik meg pusztán azért, mert egy állapot továbbra is jó.

### Alapértékek és helyzetindítás

| Jel | Alapérték | Helyzetet indíthat? | Megjegyzés |
| --- | ---: | --- | --- |
| HF-001 | 85, tényleges túllépésnél 100 | igen | Hó végi keretkockázat vezetője. |
| HF-002 | 65, tényleges kategóriatúllépésnél 85 | csak súlyos zónában | Egyébként HF-001 bizonyítéka. |
| HF-003 | nincs önálló | nem V1-ben | Csak segítő, napi költési tanács. |
| HF-004 | 45 | csak erősebb havi jel hiányában | Heti ütem, többnyire bizonyíték. |
| HF-005 | 70 | igen, pénzben érdemi tehernél | Fix teher, gyakran okmondat. |
| HF-006 | 70 | igen, jelentős és közeli tételnél | Három napon belül +10 időzítést kap. |
| HF-007 | 80 | igen | Hiányzó vagy megérkezett várt bevétel. |
| HF-008 | nincs | nem | V1-ben későbbre halasztott. |
| HF-009 | 60 | igen | Csak pozitív havi bevételnél. |
| HF-010 | 55 | igen | Csak érvényes megtakarítási cél és HF-001 mellett. |
| HF-011 | 65, nem pozitív egyenlegnél 100 | igen | Tartaléknapok vagy tényleges negatív helyzet. |
| HF-012 | 40 | csak új, pénzben nagy kategóriánál | Egyébként kategóriahelyzet bizonyítéka. |
| HF-013 | 45 | csak erősebb havi jel hiányában | Teljes 30 napos változó költési trend. |
| HF-014 | nincs | nem | Meglévő pontszám mozgásának háttérmagyarázata. |
| HF-015 | nincs | nem | Erősebb zóna felülírása. |
| HF-016–HF-019 | nincs | nem | Motor- és felületmagyarázat. |
| HF-020 | 65, tényleges éves túllépésnél 85 | csak súlyos zónában | Éves kategóriahelyzet. |
| HF-021 | 35 | igen, saját helyzetben | Késleltetett adatállapot; pénzügyi jelet nem módosít. |

A táblázatban szereplő alapérték csak akkor kerül a képletbe, ha az adott jel valóban elindítja a helyzetet. Alátámasztó jel sosem adja hozzá a saját alapértékét; a teljes helyzet legfeljebb egyszer kapja meg a `+10` kapcsolódó bizonyítékot.

### Döntetlen

Azonos fontosságnál ebben a sorrendben dönt:

1. közelebbi, valódi esedékesség;
2. ténylegesen magasabb zóna vagy pénzben nagyobb eltérés;
3. frissebb helyzetazonosító;
4. állandó HF-azonosító szerinti sorrend.

A döntési nyomvonalnak ki kell írnia, ha döntetlen oldódott fel.

## Teljes jel-szabálytábla

### Keretnyomás

| Jel | Számítás és szükséges bemenet | Mikor vár vagy nem alkalmazható | Érdemi változás | Mondatszerep |
| --- | --- | --- | --- | --- |
| HF-001 Hó végi kiadás | változó költési ütem + aktív és várható fix tételek, havi keret | összeg/dátum hiányzik; korai becslésnél csak panel | keret alatti → figyelő/szoros/túllépett, vagy vissza keret alá | fő mondat; HF-002/HF-004/HF-005/HF-007 bizonyíthatja |
| HF-002 Havi kategóriakeret | kategorizált költés / havi kategóriakeret | nincs kategória vagy nincs pozitív kategóriakeret | 75%, 90%, 100% zónaváltás vagy visszalépés | súlyos esetben fő mondat, egyébként bizonyíték |
| HF-003 Napi biztonságos költés | hátralévő havi keret / hátralévő napok | nincs havi keret vagy nincs hátralévő nap | beállított, alapból 20%-os napi határromlás | segítő részlet, önálló napi üzenet nem |
| HF-004 Heti költési ütem | havi keret / a hónap napjai × 7, összevetve heti változó költéssel | összeg/dátum vagy havi keret hiányzik; a hét elején korai becslés | legalább 15%-os ütemkülönbség zónát vált | bizonyíték; kivételesen vezető |
| HF-012 Kategóriaugrás | aktuális kategória 30 napja − előző 30 nap | nincs kategória; nincs két összevethető 30 napos időszak | meglévő kategóriánál legalább 10 000 Ft és 30%, új kategóriánál legalább 10 000 Ft | kategóriahelyzet bizonyítéka; új, nagy kategóriánál vezető |
| HF-013 Teljes költési trend | aktuális 30 napos változó költés − előző 30 nap | nincs két összevethető 30 napos időszak | legalább ±15% és ±10 000 Ft | havi helyzet bizonyítéka; önálló csak erősebb jel hiányában |
| HF-014 Pontszám iránya | meglévő pontszámvonal, újraszámítás nélkül | nincs pontszámvonal | legalább 8 pont mozgás vagy zónaváltás | háttérmagyarázat; nem talál ki okot |
| HF-015 Erősebb zóna | azonos cél aktuális zónái | nincs több aktív zóna | például 75% → 90% | motorlogika; nincs mondat |
| HF-020 Éves kategóriakeret | év elejétől kategóriára költött összeg / éves ütem | nincs kategória vagy éves keret | figyelő/súlyos/túllépett zónaváltás | súlyos esetben fő mondat, egyébként bizonyíték |

### Pénzáramlási nyomás

| Jel | Számítás és szükséges bemenet | Mikor vár vagy nem alkalmazható | Érdemi változás | Mondatszerep |
| --- | --- | --- | --- | --- |
| HF-005 Fix kiadások terhe | aktív + várakozó ismétlődő kiadások összege és legnagyobb tétele | összeg vagy esedékességi dátum hiányzik | alapból 30 000 Ft-os teherhatár átlépése | fő mondat lehet; gyakrabban ok vagy bizonyíték |
| HF-006 Következő 7 nap kiadása | közeli ismétlődő kiadások darabszáma, összege, legközelebbi dátuma | összeg vagy esedékességi dátum hiányzik | bekerül a 7 napos ablakba; 3 napon belül sürgős | fő mondat lehet, vagy idő/ok mondatrész |
| HF-007 Hiányzó várt bevétel | várt bevétel esedékessége és tényleges beérkezése | nincs rögzített várt bevétel; nem adathiba, ha még nem esedékes | várt → esedékes → lejárt, vagy beérkezik | fő mondat vagy javulási mondatrész |
| HF-008 Bevételi cél kockázata | HF-007 és HF-010 által lefedett helyzet | V1-ben mindig későbbre halasztott | nincs V1-es felső üzenet | nincs |
| HF-009 Bevétel–kiadás arány | havi kiadás / havi bevétel | havi bevétel nem nagyobb nullánál | 70%, 90%, 100% zónaváltás vagy javulás | fő mondat |
| HF-010 Megtakarítási cél | várt bevétel − HF-001 hó végi előrejelzés, elosztva megtakarítási céllal | nincs pozitív megtakarítási cél vagy HF-001 nem számolható | 100% → 75% → 0% zónaváltás vagy javulás | fő mondat |
| HF-011 Egyenlegtartalék | egyenleg / gördülő változó napi költés | napi változó költés nem nagyobb nullánál; nem pozitív egyenleg külön kritikus állapot | 30, 14, 7 napos zónaváltás vagy javulás | fő mondat |

### Adatállapot és motorlogika

| Jel | Számítás és szükséges bemenet | Mikor vár vagy nem alkalmazható | Érdemi változás | Mondatszerep |
| --- | --- | --- | --- | --- |
| HF-021 Kategorizálatlan tételek | kategória nélküli tételek darabszáma, összege, legrégebbi ideje | küszöb alatt vagy a 12 órás késleltetés előtt vár | küszöb + késleltetés teljesül, illetve minden érintett tétel kategóriát kap | saját adatállapot fő mondata és pontos magyarázata; nem pénzügyi kiegészítés |
| HF-016 Fontosság és választás | kész helyzetek alapértéke és látható módosítói | nincs kész helyzet | új nyertes vagy döntetlen | csak felületmagyarázat |
| HF-017 Ismétlés | helyzetazonosító és előző megjelenés | azonos, már mutatott vagy elutasított helyzet | új helyzetazonosító vagy megoldás | csak felületmagyarázat |
| HF-018 Megjelenítés | kiválasztott helyzet + alkalmazás állapota | háttérben tárol, nyitásig vár | alkalmazás megnyitása vagy folytatása | csak felületmagyarázat |
| HF-019 Átláthatóság | jel-, helyzet- és mondatrész-nyomvonal | mindig panelhez kötött | a felhasználó megnyitja a felületet | csak felületmagyarázat |

## Történetépítő szabályok

Egy felső üzenet legfeljebb négy részből állhat:

~~~text
fő állítás
+ legfeljebb két bizonyíték
+ legfeljebb egy idő- vagy okmondat
+ javulás, ha korábban megmutatott fontos helyzet oldódott meg
~~~

| Helyzettípus | Vezető jel | Megengedett alátámasztás | Tiltott összekapcsolás |
| --- | --- | --- | --- |
| Hó végi kerethelyzet | HF-001 | HF-002, HF-004, HF-005, HF-006, HF-007, HF-012, HF-013 | HF-021, nem kapcsolódó pontszámmozgás |
| Kategóriahelyzet | HF-002 vagy HF-012 | a másik kategóriajel, HF-020 azonos kategóriánál | más kategória, HF-021, nem kapcsolódó fix kiadás |
| Pénzáramlási helyzet | HF-005, HF-006, HF-007, HF-009, HF-010 vagy HF-011 | a többi azonos havi pénzáramlási jel | kategóriahiány, nem kapcsolódó költési trend |
| Javulás | megoldott korábbi főjel vagy HF-007 | csak az előző fontos helyzethez kötődő új tény | rutinszerű, változatlan jó állapot |
| Adatállapot | HF-021 | csak a hiányzó kategóriák száma/összege és az érintett HF-ek | bármely pénzügyi kockázat vagy pontlevonás |

| Mondatrész | Szabály |
| --- | --- |
| Fő állítás | A vezető jel jelen idejű, bizonyítható állítása. |
| Bizonyíték | Szám, zóna, keret vagy egy releváns további jel; nem ismétli a fő állítást. |
| Idő vagy ok | Közeli esedékesség, fix teher, várt bevétel hiánya vagy valódi átmenet. |
| Javulás | Csak előzőleg jelentős és már megmutatott kockázat feloldásakor. |
| Adatállapot | Pontosan megmondja, mely számítások várakoznak; sosem állítja, hogy a matematika bizonytalan. |

## Ismétlés, elutasítás és megjelenés

### Helyzetazonosító

~~~text
vezető HF-jel
+ cél
+ időszak
+ zóna
+ irány
+ esedékességi időablak
+ a kimondott bizonyítékok azonosítói
~~~

Azonos helyzetazonosító nem jelenik meg újra. A támogatói jel csak akkor változtat helyzetazonosítót, ha a felső üzenetben is megjelenő bizonyíték vagy a sürgősség megváltozik.

| Kapu | Következmény |
| --- | --- |
| azonos, már megmutatott helyzet | nem kerül versenybe |
| felhasználó által elutasított helyzet | nem kerül versenybe, amíg nincs új helyzetazonosító vagy lejár a beállított szünet |
| némított cél | nem kerül versenybe |
| háttérben lévő alkalmazás | a kiválasztott jelenlegi helyzet tárolható, de megnyitáskor újraszámolás után jelenik meg |
| erősebb, azonos célú zóna | felülírja a korábbit |

Ezek a kapuk nem változtatják meg a pénzügyi fontosságot, ezért nem szerepelnek mínusz pontként.

## Következő megvalósítási sorrend

1. A jel-szabálytábla géppel olvasható adatmodellje, egy rekord minden HF-hez.
2. Felület nélküli számítások és mintaadatok a négy adatállapothoz.
3. Helyzetépítő, amely csak az engedélyezett helyzetkulcsokat kapcsolja össze.
4. Fontossági választó és döntetlen-feloldás.
5. Magyar mondatsablonok és helyzetazonosító-alapú ismétlésvédelem.
6. A Pulse mockup a valódi szabálytáblából épített döntési példákat mutatja, nem párhuzamos kézzel írt adatot.

## Tervezési ellenőrzés

- Egyetlen adatállapot sem kap automatikus negatív pontot.
- Minden pontszámot adó tételnek pénzügyi vagy időbeli oka van.
- Minden HF-nek van számítási hatóköre, várakozási oka, helyzetkulcsa és mondatszerepe.
- A felső üzenet sosem próbálja az adat hiányát pénzügyi kockázatként eladni.
- A három meglévő csoport és az egyetlen aktuális felső üzenet elve megmarad.
