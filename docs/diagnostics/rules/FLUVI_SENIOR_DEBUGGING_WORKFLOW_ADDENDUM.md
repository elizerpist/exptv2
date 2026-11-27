# Fluvi — senior debugging módszertani kiegészítés

Verzió: **1.0** · Kelt: **2026-11-27**

## 1. Rendeltetés és alkalmazás

Ez új, külön projektasset. A `FLUVI_PROMPT_WRITER_RULES.md` 2.2 és a
`FLUVI_WIDGET_DEBUGGING_PROMPT_ADDENDUM.md` 1.3 mellé alkalmazandó; nem
helyettesíti őket. Későbbi verzióknál az aktuális szabályzatokkal való
összhangot ellenőrizni kell.

A dokumentum hivatalos szakmai források Fluvihez igazított alkalmazása.
Nem Google- vagy Microsoft-minősítés, és nem egy általánosan kötelező
„senior debugging” szabvány. A konkrét Fluvi-előírások projektbeli döntések.

Elsődleges cél: a diagnózis mutassa meg, a felhasználó által jelzett hibából
mekkora részt magyaráz, hol marad bizonytalanság, és milyen beavatkozás
ellenőrizheti ténylegesen a feltételezett okot.

A szerepek változatlanok:

- **Reviewer / prompt writer:** forrás- és evidence-audit, hipotézisek,
  mérési terv, oksági értelmezés és konkrét javítási terv.
- **Coding agent:** az előírt javítás vagy kísérlet végrehajtása, nyers
  eredmények és artifactok átadása; ellenbizonyítéknál visszaadás a reviewernek.
- **Felhasználó:** valós készülékes teszt és az exact APK fizikai elfogadása.

A teljesítményvizsgálati pontokat késésnél, akadásnál vagy animációhibánál,
a bisect-pontokat igazolt regressziónál kell alkalmazni. Más esetben rövid
`N/A — indoklás` elegendő. A kiegészítés nem ír elő minden körre új
teljes rendszertrace-et, teljes CI-t vagy második modell futtatását.

## 2. Hivatalos módszertani alap

| Forrás | Átvett alapelv |
| --- | --- |
| [S1 — Google SRE: Effective Troubleshooting](https://sre.google/sre-book/effective-troubleshooting/) | Rendszerismeretre épített hipotézisek, kontrollált vizsgálatok, a sikertelen ötletek eredményeinek megőrzése. |
| [S2 — Android Developers: Perfetto Trace Analysis](https://developer.android.com/agents/skills/profilers/android-profiler/analysis/workflows/perfetto-trace-analysis/perfetto_trace_analysis) | Az adatminőség ellenőrzése, a szálállapotok és a megjelenítési út vizsgálata, bizonyíték és következtetés elkülönítése. |
| [S3 — Android Developers: Candidate Investigation Protocol](https://developer.android.com/agents/skills/profilers/android-profiler/analysis/workflows/perfetto-trace-analysis/references/per_candidate_analysis) | A tünet időablakának felbontása, a blokkoló függőségek követése, a magyarázott idő és az adathiány feltüntetése. |
| [S4 — Linux Kernel: Verify bugs and bisect regressions](https://docs.kernel.org/admin-guide/verify-bugs-and-bisect-regressions.html) | Ellenőrzött jó/rossz kiindulópontok, regressziólokalizálás és a talált változtatás ellenőrzése. |

Forrásellenőrzés: 2026-11-27. A forrásokból nem következik egy konkrét
Fluvi-hiba oka. A parancsokat, trace-sémákat, platformképességeket és
jogosultságokat az aktuális környezetben külön kell ellenőrizni.

## 3. Vizsgálati sorrend

Az S1 módszerének Fluvihez igazított menete:

1. **Tünet:** pontos elvárt és tényleges viselkedés, tesztelt build és környezet.
2. **Rendszermodell:** az aktuális kódban végigkövetett adat-, állapot- és vezérlési út.
3. **Reprodukció:** a hibát előhívó helyzet és az összehasonlítható működő kontroll.
4. **Hipotézisek:** a meglévő H… nyilvántartás alapján támogatás, cáfolás és nyitott kérdés.
5. **Elkülönítő vizsgálat:** előre rögzített kimenetekkel, korlátos futással.
6. **Döntés:** konkrét javítás vagy további, pontosan megtervezett mérés.
7. **Visszaellenőrzés:** eredeti tünet, regressziók és fizikai elfogadás külön.

A negatív eredmény is előrelépés, ha érvényes vizsgálatból származik és
kizár egy lehetőséget. A hibás setupból vagy hiányos adatból származó
eredmény viszont `INCONCLUSIVE`, nem cáfolat. Ezt az E…/H…/D… rendszerben
rögzítsd; ne hozz létre párhuzamos, eltérő állapotú nyilvántartást.

## 4. A késés elszámolása

Az S3 alapján a reviewer minden teljesítménydiagnózisnál nevezze meg a
vizsgált időablakot és a megállapítások időbeli hozzájárulását.

Fluvi-specifikus kötelező adatok:

| Adat | Elvárt tartalom |
| --- | --- |
| Vizsgált jelenség | W-SHOW, W-HIDE, W-LOCK-ANIM, W-HOME-ANIM vagy más pontos tünet. |
| Azonosság | SHA/APK, készülék/OS, route, capture/session, releváns generáció. |
| Kezdő- és végpont | Esemény, mérőhely, óra; app-szakasz vagy fizikai végpont. |
| Megfigyelt idő | A két igazolt, összehasonlítható végpont közötti idő. |
| Feltárt mechanizmus | Az időhöz kapcsolt E… bizonyíték és H… besorolás. |
| Magyarázott rész | Mennyi időt és a megfigyelt szakasz mekkora részét magyarázza? |
| Nyitott rész | Mely szakasz megfigyelt, de még nincs okságilag megmagyarázva? |
| Megfigyelési hiány | Mely kezdőpont, végpont vagy köztes szakasz nem mérhető? |

**Szemléltető példa, nem Fluvi-mérési eredmény:** egy 400 ms-os megfigyelt
szakaszban talált 8 ms-os felesleges munka a szakasz 2%-a. Ez önmagában
nem magyarázza a teljes késést. A 392 ms fennmaradó részhez további
magyarázat kell. A 8 ms eltávolítása sem garantál 8 ms végponti gyorsulást,
ha a munka átfed egy másik szükséges művelettel.

Elszámolási szabályok:

- Különítsd el a tényleges munkát, a sorban várakozást, az ütemezési
  várakozást és a másik komponensre várást.
- Különböző szálak vagy egymásba ágyazott szakaszok idejét ne add össze
  automatikusan. Az átfedéseket és a kritikus út függőségeit jelöld.
- A megfigyelt idő lefedése és az oksági magyarázat lefedése külön adat.
  Egy hosszú függvényhívás időtartama még nem mondja meg, miért tartott addig.
- Nem megfigyelt fizikai kezdőpont mellett ne számíts teljes ébresztési
  késést vagy annak százalékos felbontását.
- Ne állíts önkényes kötelező lefedettségi százalékot. A fennmaradó
  bizonytalanságot és annak döntési jelentőségét írd le.

Egy kis részhiba javítható, ha bizonyított és érdemi. A reviewer nevezze
meg a várható haszon bizonyítási határát; a részjavítás ne kapjon „teljes
lag megoldva” státuszt. A felhasználó 10 ms-os célja nem lazítható át a
diagnózisban önkényesen egy könnyebben teljesíthető részszakaszra.

## 5. A várakozási lánc feltárása

Az S3 szerint a vizsgálat kövesse a bizonyított függőségeket szál-,
folyamat- és szükség esetén kernelhatáron át. Egy köztes várakozó vagy
ébresztő azonosítása önmagában nem a teljes ok feltárása.

Fluvi-specifikus ellenőrzés minden releváns függőségi lépésnél:

1. Melyik konkrét művelet teljesítési kötelezettsége maradt függőben?
2. Mire vár, és melyik owner tudja azt teljesíteni?
3. Milyen esemény, kérés-, lock- vagy tranzakcióazonosság köti őket össze?
4. A feltételezett blokkolás időben lefedi-e a vizsgált várakozást?
5. A másik owner dolgozik, futásra vár, vagy maga is egy függőséget vár?

Pusztán két időben egybeeső eseményből ne rajzolj oksági élt. A lánc minden
kapcsolatához kell bizonyíték. Hiányzó kapcsolatnál ott érjen véget a
bizonyított lánc; a folytatás legyen megnevezett hipotézis és mérési feladat.

**Szemléltető eset:** ha a Fluvi main threadje egy szinkron rendszerhívásra
vár, először a hívás és a válaszadó folyamat kapcsolatát kell igazolni.
Egy ugyanakkor aktív rendszerfolyamat önmagában nem bizonyítja, hogy az
blokkolja a Fluvi megjelenését. Ez nem diagnózis a jelenlegi ORB-hibára.

## 6. Trace-minőség és rendszerkörnyezet

Az S2 alapján elemzés előtt ellenőrizd az eseményvesztést és a szükséges
adatfolyamok elérhetőségét. A hiányzó adat nem tekinthető normál értéknek.
A rendelkezésre álló trace alapján külön vizsgálandó a futó, futásra kész
és várakozó szálállapot, valamint megjelenítési hibánál a kompozitor/GPU út.
Egy sleeping állapot önmagában nem bizonyít hibás blokkolást.

Az S3 rendszerkörnyezeti ellenőrzése alapján a kódhibától külön értékeld
a hő miatti lassulást, CPU-korlátozást, ütemezési terhelést és memóriahelyzetet.
Ezek lehetséges vizsgálati irányok, nem a Nothing OS-re előre kimondott okok.

A Fluvi esetében:

- Rögzítsd a capture-módot és a naplózás/tracing mérési többletköltségét.
- Meglévő alkalmas bizonyítékot használj fel; ne kérj új telefonos
  felvételt, ha a kérdés már eldönthető.
- Trace-hiánynál a reviewer nevezze meg, mely döntéshez milyen adat kell,
  és a valós eszközön milyen támogatott módon gyűjthető.
- Rootot, privilegizált hozzáférést vagy egy konkrét trace-adatforrás
  elérhetőségét ne feltételezd. A korlát és az alternatív mérés legyen explicit.
- A rendszertrace sem automatikusan a kijelzőn fizikailag megjelent első
  vagy utolsó képkocka bizonyítéka; a végpont jelentését külön ellenőrizd.

## 7. Regressziólokalizálás és bisect

Az S4 alapján bisection előtt ellenőrizni kell a jó és rossz verziót,
megőrizni az összehasonlítás konfigurációját, és naplózni a besorolásokat.
A nem tesztelhető commit nem automatikusan hibás; indokolt esetben `skip`
szükséges. A talált változtatás visszavonásával végzett kontroll erősítheti
az eredményt, ha az biztonságosan és értelmesen elvégezhető.

Fluvi-specifikus belépési feltételek:

- Ugyanaz a pontos tünet és ugyanaz az elfogadási feltétel.
- Összehasonlítható készülék, OS, beállítások, build mode és diagnosztikai terhelés.
- Ellenőrzött SHA/APK-azonosság mindkét végponton.
- Reprodukálható eredmény; intermittáló hibánál előre meghatározott
  ismétlésszám és besorolási szabály.
- A jó/rossz határ értelmezhető a vizsgált történetben. Több egymást
  váltó javulás és regresszió esetén ne feltételezz egyetlen egyszerű határt.

**Az Android 15-ön elfogadott R41 és egy Android 17-en hibás build önmagában
nem megfelelő alkalmazáskód-bisect pár.** A környezet változása külön
tényező. Előbb azonos környezetben igazolt kontroll kell; ez nem jelent
automatikus felhatalmazást OS-visszaállításra.

A reviewer adja meg a refeket, a konkrét tesztet, a futási korlátot,
a besorolási szabályt és a visszaadandó naplót. A coding agent ezt hajtja
végre. Bizonytalan minta nem kényszeríthető `good` vagy `bad` állapotba.
A bisect egy változtatást lokalizál; annak mechanizmusa további kódauditot
igényelhet. Munkapéldányt és felhasználói adatot romboló visszaállítás nem
része ennek a módszertani utasításnak.

## 8. Beillesztés a meglévő handoffba

Nem kell új promptformátum. Az alap-szabályzat 21 részes angol handoffjában:

| Meglévő rész | Kiegészítés |
| --- | --- |
| 2–5. Állapot, preflight, user evidence, logaudit | Összehasonlítható baseline, tünetablak, trace-lefedettség és környezeti eltérések. |
| 8–10. Forrástények, bizonyítás, diagnózis | Magyarázott és nyitott idő; bizonyított várakozási lánc; H… alternatívák. |
| 13–17. Teszt, implementáció, teljesítmény, sorrend, validáció | Elkülönítő kontroll; várható javulás határa; szükség esetén pontos bisect-terv. |
| 20–21. Jelentés, befejezés | Új evidence és hipotézisváltozás; fennmaradó idő/hiba; fizikai státusz. |

A rövid reviewer-jelentésbe az alábbi blokk illeszthető. A reviewer
töltse ki, ne üres diagnosztikai feladatként adja át a coding agentnek.

```text
VIZSGÁLT TÜNET / ROUTE:
TESZTELT SHA / APK / ESZKÖZ / OS:
BASELINE ÉS ÖSSZEHASONLÍTHATÓSÁG:
MEGFIGYELT IDŐABLAK, ÓRA, VÉGPONTOK:
ADATMINŐSÉG ÉS MÉRÉSI KORLÁT:

E… BIZONYÍTÉKOK:
H… HIPOTÉZISEK ÉS ELLENBIZONYÍTÉKOK:
BIZONYÍTOTT FÜGGŐSÉGI LÁNC:
MAGYARÁZOTT IDŐ / ÁTFEDÉSEK:
MÉG NEM MAGYARÁZOTT VAGY NEM MEGFIGYELT RÉSZ:
RENDSZERKÖRNYEZETI TÉNYEZŐK:

D… KÖVETKEZŐ DÖNTÉS:
IMPLEMENTATION VAGY EVIDENCE_COLLECTION:
KONKRÉT JAVÍTÁS VAGY ELKÜLÖNÍTŐ VIZSGÁLAT:
VÁRHATÓ HASZON ÉS BIZONYÍTÁSI HATÁRA:
KONTROLL / CÁFOLÁS / FUTÁSI KORLÁT:
REGRESSZIÓVIZSGÁLAT / BISECT VAGY N/A:
VISSZAADANDÓ NYERS ARTIFACT:
VÉDETT VISELKEDÉS:

PHYSICAL VALIDATION — PENDING, USER ONLY
```

## 9. Lezárás

A kör akkor ad érdemi eredményt, ha új, ellenőrizhető tényt szolgáltat,
egy hipotézis státuszát indokoltan módosítja, vagy a kijelölt contract
javítását igazolja. A naplóban a kudarc és az eldöntetlen eredmény is maradjon meg.

Külön állítás a kódhiba javítása, a teljes késés magyarázata, az automatizált
ellenőrzés, az APK átadhatósága és a felhasználói elfogadás. Egy részszakasz
gyorsulása vagy CI-siker nem írja felül a fizikai teszt eredményét.

A közös journal és a meglévő assetek felelősségi, regressziós és
delivery-szabályai változatlanul érvényesek. A kiegészítés önmagában nem
igazol új root cause-t, nem rendel el refaktort, és nem ad engedélyt
bizonyítatlan javítások sorozatos kipróbálására.
