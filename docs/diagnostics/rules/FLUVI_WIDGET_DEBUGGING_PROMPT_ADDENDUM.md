# FLUVI — LOCKSCREEN ÉS ANDROID-WIDGET DEBUGGING

## Állandó promptírási kiegészítés

Verzió: 1.3 · Kelt: 2026-11-27

Teljes helyettesítő kiegészítés a FLUVI_PROMPT_WRITER_RULES 2.2 mellé.
A korábbi 1.2-es példányt váltsa fel. Az 1.3-as változat a cáfolható
hipotézisek és az eltérő modelldiagnózisok kezelését alkalmazza a natív
renderelésre. Megőrzi a natív hatásvizsgálatot, a fixture-szerződést és
a célzott/teljes validációt; új renderer- vagy CI-implementációt nem állít késznek.
A felelősségi határ minden alábbi
„vizsgáld”, „auditáld” és „bizonyítsd” előírásra érvényes: a diagnosztikai
elemzés a prompt writeré; a coding agent csak a konkrétan előírt tervet hajtja végre.

Ez a dokumentum a `FLUVI_PROMPT_WRITER_RULES` című alap-szabályzat kiegészítése. A projekt assetei között az alap-szabályzat mellett kell tárolni, és minden coding-agent prompt előtt mindkettőt teljes egészében el kell olvasni. A widget-specifikus technikai ellenőrzések az érintett felületekre vonatkoznak.

A dashboard-debugging szabályai és elfogadott mérföldkövei érvényben maradnak. Ez a kiegészítés ugyanazt a bizonyítékalapú workflow-t alkalmazza a lockscreen megjelenítésre és a kezdőképernyős Android-widgetre, a megfelelő natív és widget-host ellenőrzésekkel.

Ez tartós munkaszabály, nem egy javítás implementációs promptja, nem bizonyított diagnózis, és nem egy adott commithoz rögzített architektúra. A branch, source SHA, APK, aktuális osztálynevek, renderelési technológia és hibastátusz minden munkakörben újra ellenőrzendő. A jelenleg ismert megoldásokat sem szabad változatlan adottságként kezelni.

## 1. Hatály és szerepek

A kiegészítés alkalmazandó, ha a feladat érinti:

- a Fluvi lockscreen-kártya vagy orb megjelenését, eltűnését, animációját, adatát vagy életciklusát;
- a kezdőképernyős Android-widget animációját, frissítését, konfigurációját vagy teljesítményét;
- az ezek által ténylegesen közösen használt adat-, material-, shader-, képkocka-, konfigurációs vagy publikációs útvonalat.

Külön kell azonosítani a lockscreen megoldást és a launcher által hosztolt Android-widgetet. A felhasználó mindkettőt nevezheti „widgetnek”; ebből nem következik azonos API, process, renderer, órajel vagy lifecycle. Az aktuális megvalósítást a source alapján kell megállapítani.

A prompt writer diagnosztizál és promptot ír; alkalmazáskódot nem implementál. A GitHub repositoryban kizárólag a közös naplót módosítja: `docs/FLUVI_ENGINEERING_JOURNAL.md`. A felhasználó által külön kért szabályzati asset elkészítése nem alkalmazáskód-módosítás.

A diagnózis, az aktuális kód alapos elemzése, a lehetséges lag- és bugforrások feltárása, az oksági következtetés, a megoldás kiválasztása és az esetleges refaktor megtervezése KIZÁRÓLAG A PROMPT WRITER FELADATA. A coding agentre nem adható nyitott „tárd fel az eltűnés késését”, „keresd meg a lag okát”, „válassz jobb renderert” vagy „próbálkozz, amíg jó” feladat.

A coding agent a reviewer által megadott technikai tervet implementálja, az előírt reprodukciót/mérést/tesztet végrehajtja, majd raw evidence-et, commitot és az előírt artifactot szállít. A tervnek ellentmondó tényeket jelenti; új diagnózist és új runtime-javítási irányt nem választ. Saját magának nem adhat fizikai elfogadást.

Az alap-szabályzat két feladattípusa itt is kötelező:

- **IMPLEMENTATION:** a reviewer megadja a konkrét kódhibát, exact source-helyeket, módosítandó kódrészletet, választott megoldást/pszeudokódot, állapot- és szálhatárokat, regressziós feltételeket. A source-ból igazolt részhiba és a teljes telefonos tünet oksági magyarázata külön bizonyítási állítás.
- **EVIDENCE_COLLECTION:** a reviewer konkrét hipotézishez rendelt minimális kísérletet ír elő, pontos mérőhelyekkel, órákkal, correlation ID-kkel, kontrollal, cáfolási feltételekkel és visszaadandó artifacttal. Az agent végrehajtja; az eredményt a reviewer értelmezi és ő írja meg a következő javítási tervet.

Ha az ok továbbra sem tiszta, a reviewer maga kéri a hiányzó célzott debug logot vagy felhasználói mérést, és megindokolja, mely döntést teszi lehetővé. A már meglévő log újrakérése és az általános „több diagnosztika kell” nem helyettesítheti a source-auditot. Az agent mechanikus implementációs szabadságára és az eltérések visszaadására az alap-szabályzat 0. része irányadó.

## 2. A négy hibaterület elkülönítése

Az induló felhasználói problémafelvetés négy külön vizsgálati területet tartalmaz:

| Azonosító | Jelenség | Mit kell külön bizonyítani? |
| --- | --- | --- |
| W-SHOW | Ébresztéskor későn jelenik meg a lockscreen-widget. | Melyik megfigyelt szakasz késik, és mikor jelenik meg először a kívánt tartalom, majd annak élő animációja? |
| W-HIDE | Feloldáskor későn tűnik el a lockscreen-widget. | Mikor érkezik meg az alkalmazás számára a releváns jel, mikor születik döntés, és mikor szűnik meg a látható megjelenítés? |
| W-LOCK-ANIM | Hibás a lockscreen-widget animációja. | Mi az elvárt és tényleges látvány; forma-, szín-, fázis-, frissítési, lifecycle- vagy időzítési eltérés történik-e? |
| W-HOME-ANIM | Hibás a kezdőképernyős Android-widget animációja. | A tartalom előállítása, átadása, host oldali megjelenítése vagy életciklusa mely ponton tér el az elvárt működéstől? |

Ezek a kiinduló tünetcsoportok nem örökösen nyitott hibák. Státuszukat az aktuális felhasználói teszt, a tesztelt build és a napló alapján kell megadni.

Kötelező szabályok:

- A „késik” fizikai megfigyelés; önmagában nem bizonyít timer-, Binder-, GPU-, cache- vagy main-thread hibát.
- A „bugos animáció” önmagában nem bizonyít FPS-problémát. A konkrét eltérést rögzíteni kell.
- A két felület hasonló hibája nem bizonyít közös root cause-t.
- Egy közös producer vagy asset létezése nem bizonyít közös megjelenítési útvonalat.
- Az egyik felület javulása nem minősíti javítottnak a másikat.
- Minden körben nevezd meg az elsődleges hibaterületet és azokat a felületeket, amelyeket regresszió ellen védeni kell.

### 2/A. ORB-hipotézisek és megkülönböztető evidence

Az alap-szabályzat 2/A–2/D része itt is kötelező. Az alábbiak lehetséges
vizsgálati irányok, nem előre kijelölt root cause-ok. Csak az aktuális
source és tünet alapján releváns sorokat bontsd ki H… hipotézisekké.

| Megfigyelés | Nyitva maradó mechanizmusok példái | Szükséges megkülönböztetés |
| --- | --- | --- |
| A kép elkészült, a látható ORB késik | Nem aktuális a kép; késik a show jel, authorization, main queue, attach vagy megjelenítés | Content/generation azonosság; jogosultság; sorba állítás és futás; attach/draw/commit; külön a fizikai végpont |
| Hide-döntés után még látható | Késik a helyi visszavonás; egy régi completion újra mutat; a fizikai végpont nincs megfigyelve | Ugyanazon wake/attach/lease eseményei, visszavonás és minden késői show/reattach; korrelált képi evidence |
| A normál widget jó, a lockscreen színe/animációja hibás | Eltérő konfiguráció, régi csomag, elmaradt frissítés, eltérő consumer vagy animációs életciklus | Mindkét route pontos konfigurációja és content identity-je, producer/publikáció/fogyasztás, tényleges képi output és animáció |
| Android/OEM-frissítés óta nincs ORB | Megváltozott jogosultság, service-állapot, megfigyelt ablakok, lifecycle vagy platformviselkedés | Valós eszköz- és buildazonosság, jelenlegi runtime megfigyelés, route-onkénti elutasítási ok; az emulátor eltéréseinek jelölése |

A „producer kész” nem bizonyítja, hogy az aktuális fogyasztó megkapta,
elfogadta és megjelenítette a helyes tartalmat. Az aktuális header,
launcher-widget, Fluvi lockscreen route és – ha a felhasználó kérte – külső
widgethost külön evidence-lánc; működésükből ne következtess automatikusan
egymásra. A korábbi Android-verzió mérföldköve hasznos történelmi referencia,
de az új OS alatti mechanizmust és állapotot újra igazolni kell.

Modellváltáskor ugyanazt a frozen capture-t, alkalmazási SHA-t, route-ot,
készülék/OS-konfigurációt, capture-módot, eseményazonosságokat és a teljes
H… előzményt add át. Egy eltérő Astra/Sol/Terra-válasz önmagában nem indok
új cache-re, rendererre, timeoutnövelésre vagy authorization-policyra.
A reviewer előbb a tényeltérést oldja fel, majd szükség esetén konkrét
elkülönítő kísérletet ír elő. Érvénytelen fixture vagy hiányzó idővégpont
esetén az eredmény INCONCLUSIVE, nem automatikusan renderer- vagy OEM-hiba.

A felhasználó által előírt késleltetési cél – például a fizikai ébresztéstől
az első helyes ORB-képig legfeljebb 10 ms – nem lazítható önkényesen.
Ha a rendelkezésre álló mérés csak app-callbacktől draw-ig tart, azt külön
részszakaszként jelentsd; a teljes cél teljesülése UNPROVEN/UNOBSERVED marad.
A mérhetőség korlátját és az esetleges platformkorlátot külön bizonyítsd.
A gyorsulás nem oldja fel a feloldás utáni helyes eltűnés és a vizuális
helyesség követelményét.

## 3. Az alap-workflow minden bizonyítási kapuja érvényes

A sorrend:

1. Reviewer: minden prompt előtt az aktuális alap-szabályzat, jelen kiegészítés, közös napló és releváns milestone-ok teljes elolvasása.
2. Reviewer: exact tesztelt alkalmazás/build és az aktuális Git-állapot feloldása.
3. Reviewer: teljes friss evidence, agent-jelentés, commit body és actual diff audit.
4. Reviewer: érintett current source, teljes releváns tesztek és transzitív consumerfelület alapos vizsgálata; kitöltött R… hatás-/tesztmátrix és a fixture teljes állapotszerződése.
5. Reviewer: saját diagnózis, PROVEN / UNPROVEN / MISSING EVIDENCE, rangsorolt hipotézisek és hurokelkerülési audit.
6. Reviewer: konkrét javítási terv, vagy bizonyítékhiánynál teljesen meghatározott mérési kísérlet; angol handoff az alap-szabályzat 21 részes formájában.
7. Coding agent: asset-/naplóolvasás, exact állapotellenőrzés, az előírt reproducer/red teszt vagy instrumentáció végrehajtása.
8. IMPLEMENTATION ágon coding agent: kizárólag az előírt teljes javítási egység és az ellenőrzött környezetben végrehajtható gyors/célzott validáció; az R… sorok és a teljes CI belépési feltételeinek tényleges ellenőrzése. EVIDENCE_COLLECTION ágon coding agent: raw evidence visszaadása, majd reviewer-elemzés és külön javítási handoff.
9. Coding agent: az előírt correctness-, teljesítmény- és regressziós ellenőrzések; eltérésnél konkrét evidence-visszaadás, önálló új runtime-irány nélkül.
10. Coding agent: atomikus commitok, teljes commit body, szükséges CI, exact-source APK és delivery-evidence; teljes completion report és napló.
11. Reviewer: az eredmények és új commitok ellenőrzése, saját következtetés és naplófrissítés. Felhasználó: fizikai visszateszt és elfogadás.

A dashboardra vonatkozó konkrét widget-/controllerneveket nem kell a natív pipeline-ba képzelni. Az alap-szabályzat általános bizonyítási követelményeit az itt meghatározott natív és host oldali megfelelőkkel kell teljesíteni. A ténylegesen nem érintett alrendszeri pont `N/A — indoklás` megjelölést kapjon. Ez nem jogosít fel releváns audit kihagyására.

Ha a root cause nincs bizonyítva, a reviewer nem adhat nyitott diagnosztikai feladatot az agentnek. Ő maga tervezi meg a különbséget eldöntő reprodukciót vagy mérést, az agent pedig kizárólag végrehajtja azt. A következtetés és a javítás kiválasztása a reviewerhez tér vissza. Valószínű ötletet tilos kész diagnózisnak nevezni.

Megdőlt hipotézis vagy terven kívüli hiba esetén az érintett ágon nincs újabb találgató runtime-módosítás; exact source/log/test evidence és reviewer-döntés kell. A már engedélyezett, független munka folytatható. Ez nem automatikus felhasználói engedélykérés. A tesztelhető APK szállítását végig kell vinni, amíg a terv végrehajtható; külső buildblokk, hiányzó kapu vagy diagnosztikai APK nem nevezhető kész, igazolt javításnak.

## 4. Exact build és környezet

Minden vizsgálat rögzítse:

- repository, tesztelt branch/ref, teljes alkalmazási SHA, parent SHA;
- aktuális local/remote HEAD, integration branch és dirty/clean worktree;
- APK neve, build mode, beágyazott source identity és rendelkezésre álló hash;
- készülékmodell, Android/API, OEM rendszerverzió; kezdőképernyős widgetnél launcher és releváns verzió;
- process- és service-session, capture ID, widgetpéldány/hostazonosság, ha elérhető;
- lockscreen mód, animációs mód, adatvédelmi mód, widgetméret és releváns konfiguráció;
- foreground/background beállítások, engedélyek és szolgáltatásállapot, ha érintettek;
- első indítás, első ébresztés, ismételt ébresztés, process-újraindítás vagy hosszabb alvás utáni állapot.

A legutóbbi branch HEAD, egy naplócommit és a telefonra telepített APK source SHA-ja külön fogalom. A dokumentációs child commit nem válik automatikusan új alkalmazási baseline-ná. A lockscreen-teszt buildazonossága nem bizonyítja magától egy másik időpontban megfigyelt launcher-widget buildazonosságát.

Hiányzó identityt jelölj hiányzóként; ne töltsd ki emlékezetből vagy a legújabb GitHub-commit alapján.

## 5. Teljes logaudit és megismételhető evidence

A Google Docs mellett a felhasználó által bemásolt vagy fájlként exportált natív capture, Android-log, profiler-trace, releváns CI-artifact és vizuális felvétel is lehet bizonyíték. A formátumtól függetlenül a teljes releváns anyagot kell vizsgálni; snippet vagy összefoglaló nem elég.

Minden felhasznált snapshothoz rögzítsd a forrást, exportidőt, elérhető módosítási időt, méretet, SHA-256-ot, buildet, sessiont, capture módot, retained tartományt és ismert hiányokat. Változó logból a javítási körhöz változatlan másolat kell.

Kötelező:

- session/capture/build szerinti elkülönítés;
- sequence- és tartalomütközések, duplikációk, retention gapek és truncation auditja;
- felhasználói marker és runtime event külön kezelése;
- az egy ébresztési cikluson belüli összes attach/hide/reattach epizód megtartása;
- első sikeres rajzolás elkülönítése egy későbbi, rajzolás nélkül eltávolított attach-tól;
- a tényleges látható visszavonás és az utána történő detached cleanup elkülönítése;
- korábbi build logjának `HISTORICAL EVIDENCE` jelölése.

Egy későbbi attach nem írhatja felül a ciklus korábbi első élő képkockáját a kimutatásban. A korábbi sikeres rajzolás viszont nem fedheti el a későbbi hibás reattach-ot vagy megszakadást. Mindkettőt láthatóvá kell tenni.

## 6. Órák, megfigyelhetőség és fizikai megjelenés

Minden időbélyegnél azonosítani kell az órát és a mérés helyét. Wall-clock, uptime, elapsed realtime, frame timestamp és videó-idővonal nem keverhető automatikusan. Mélyalvást átfogó összehasonlításnál külön ellenőrizni kell az időalap jelentését. Eltérő időalapok között csak dokumentált és ellenőrzött korrelációval szabad számolni.

Külön fogalmak:

- rendszeroldali esemény kezdete;
- esemény alkalmazásoldali fogadása;
- feldolgozás és döntés;
- ablakművelet hívása és visszatérése;
- view attach, draw, shader draw és aktuális material draw;
- frame-commit visszajelzés;
- a felhasználó számára ténylegesen látható megjelenés vagy eltűnés.

Az `addView`/`removeView` visszatérése, egy draw callback vagy frame-commit visszajelzés önmagában nem azonos a fizikai képernyőn megfigyelt végponttal. Az esemény jelentését a mérőhely és az alkalmazott API aktuális szerződése alapján ellenőrizni kell.

A nem megfigyelt végpont értéke `UNOBSERVED`, nem nulla. Hiányzó kezdőpont mellett a teljes end-to-end késés nem nevezhető mértnek. Az „első callbacktől első draw-ig” mérés nem nevezhető automatikusan „ébresztéstől megjelenésig” mérésnek.

Fizikai szinkronizációt igénylő állításhoz megfelelő vizuális evidence és időkorreláció kell. Ha nincs, az alkalmazásból megfigyelt szakaszról adj következtetést, a hiányzó szakaszt pedig nevezd meg. Önkényes levonással, timestamp-áthelyezéssel vagy markerátnevezéssel tilos javulást előállítani.

## 7. W-SHOW — megjelenési késés auditja

Az aktuális source alapján térképezd fel a tényleges útvonalat. A következők vizsgálandó mérési határok, nem előre bizonyított soros végrehajtási sorrend:

- ébresztési/display/keyguard jel és callback-fogadás;
- inspection igény, sorba állítás, munkakezdés;
- ablak-/nodelekérés, freshness feltételek, cache-művelet, feldolgozás;
- jogosultság/visibility eligibility meghatározása és eredménypublikáció;
- worker → main handoff, main queue wait, main feldolgozás;
- előkészítés, material/resource-readiness, attach-döntés és WindowManager-művelet;
- első root draw, első helyes tartalom, első live animációs draw;
- fizikai láthatóság, ha ténylegesen megfigyelhető.

Külön mérd a sorban várakozást és az aktív munkát. Egy platformhívás teljes ideje nem bontja magától külön távoli ütemezésre, cache missre és prefetchre a késést. Egymással átfedő szakaszokat ne adj össze soros end-to-end időként.

Különítsd el az első hideg megjelenést az ismételt ébresztéstől. Az offscreen előkészítés sikere nem bizonyítja a látható renderer teljes készenlétét. Egy statikus vagy bootstrap képkocka nem számolható első élő animált képkockának.

Vizsgáld meg, hogy egy retry lecserélése, törlése vagy egy új esemény elveszíthet-e még teljesítetlen munkát/frissességi kötelezettséget. Ellenőrizd a munkát ütemező és teljesítő ownert. Ezt lehetséges vizsgálati irányként kezeld, amíg az aktuális buildben nincs rá bizonyíték.

## 8. W-HIDE — eltűnési késés auditja

Külön rögzítsd:

- az elérhető feloldási/hide jel eredetét és alkalmazásoldali fogadását;
- a hide-döntés és visibility-authority váltás időpontját;
- a függő show/inspection/preparation eredmények érvénytelenítését;
- a helyi vizuális visszavonás, ablakeltávolítás és cleanup időpontjait;
- a fizikai eltűnést, ha ténylegesen megfigyelt végpont.

Kötelező ellenőrizni, hogy hosszú inspection, nodelekérés, material-előkészítés, soros queue, lock vagy diagnosztikai munka késlelteti-e a visszavonást. A késés oka csak source és runtime/reproducer bizonyítékkal nevezhető meg.

Kötelező contractok:

- A már érvénytelen megjelenítési jogosultságra érkező késői eredmény nem jelenítheti meg újra az overlayt.
- Feloldás utáni reattach nem tekinthető elfogadható teljesítménykompromisszumnak.
- A cleanup mérése nem helyettesítheti a ténylegesen látható root visszavonásának mérését.
- A gyors hide nem ronthatja el a következő legitim lock/wake ciklus megjelenését.
- Nem lehet a feloldási vagy érintési viselkedést blokkolni a widget kedvéért.

## 9. Natív ownership, lifecycle, rétegek és határok

Az aktuális megvalósításhoz illeszkedően azonosítsd:

- service-, window-, retained-view- és renderer-ownereket;
- worker/main/renderer szálhatárokat és a megosztott állapot védelmét;
- service-session, wake-, interaction-, visibility-, attach- és content-generation jelentését;
- queue, retry, cancellation, freshness-acknowledgement és stale-result szabályokat;
- listener/callback regisztrációt, eltávolítást, újraregisztrációt és dispose-t;
- material, shader, buffer, bitmap, frame package és cache tulajdonosát és élettartamát.

Ne hozz létre egy meglévő mellé második visibility-authorityt, animációs órát, queue-t vagy renderert pusztán egy tünet elfedésére. Új ownerhez bizonyított architekturális szükséglet és hatásvizsgálat kell. A stabil identity megőrzésének helyes határát source alapján határozd meg; legitim detach/dispose tilalmát ne vezesd le a stabilitási elvből.

A réteg- és bounds-audit natív megfelelői:

- ablak típusa, parentje, displaye, z-orderje és valódi láthatósága;
- window/view méretek, insets, clip, alpha, transform és paint-terület;
- érintési/fókusz/semantics viselkedés, ahol releváns;
- saját overlay és idegen rendszerablak azonosításának helyessége;
- valóban ugyanaz a root/attach/content-generation tartozik-e a döntéshez és a rajzoláshoz.

A bizonytalan vagy hiányos rendszermegfigyelést ne alakítsd pozitív megjelenítési bizonyítékká a gyorsulás kedvéért. A meglévő visibility- és adatvédelmi szerződést meg kell őrizni.

## 10. Animáció: helyesség és teljesítmény külön kapu

Mindkét felülethez rögzítsd az elvárt referenciát: alkalmazásbeli animáció, elfogadott videó/kép, specifikáció vagy fizikailag elfogadott build. Ha nincs egyértelmű referencia, az eltérés típusát előbb tisztázni kell.

Külön vizsgálandó:

- forma, mintázat, skála, kontúr, élsimítás és átlátszóság;
- paletta és konfiguráció helyessége;
- sebesség, időalap, fázisfolytonosság, loop-varrat és újraindulás;
- kimaradó, ismételt vagy nem megfelelő sorrendű képkockák;
- rövid akadás, tartós megállás, villogás és átmeneti statikus állapot;
- adat-/beállításváltozás terjedése a ténylegesen megjelenített tartalomig;
- ébresztés, attach, detach, visszatérés és több widgetpéldány hatása.

A magasabb FPS nem bizonyít helyes animációt. Azonos szín nem bizonyít azonos mintázatot. Előállított képkockák száma nem bizonyít megjelenített képkockaszámot. Azonos vizuális család nem követel automatikusan szinkron fázist a két felületen; a fázisazonosságot csak a tényleges termékkövetelmény alapján kérd számon.

A producer számítási idejét, az átadás idejét, a megjelenítési cadence-et és az állapotfrissítés késését külön kell mérni. Újraindulás után és folyamatos futás közben is ellenőrizni kell a működést; néhány sima másodperc nem bizonyít tartós stabilitást.

## 11. Kezdőképernyős Android-widget saját ellenőrzései

Először source alapján állapítsd meg a megjelenítési architektúrát. RemoteViews, képkockasorozat, host oldali animáció vagy más megoldás csak akkor kerülhet tényként a promptba, ha ténylegesen ez van használatban.

Vizsgáld meg:

- konfiguráció/adatváltozás → generálás → publikáció → host frissítés útvonalát;
- widget ID, méret, display és konfiguráció szerinti erőforrás-azonosságot;
- régi generálás késői befejezését és új konfiguráció felülírásának veszélyét;
- generálási/publikációs sor és memória korlátait;
- szükségtelen újragenerálást, ismételt átadást és animáció-újraindítást;
- launcherre visszatérést, átméretezést, példányok létrehozását/törlését és érintett lifecycle-eseteket;
- process/service újraindulást és a foreground/background kapcsolók hatását, ha a source szerint releváns.

Képkockacsomag esetén külön ellenőrizd a képméretet, képkockaszámot, időzítést, sorrendet, loop-folytonosságot és a tényleges memória/átviteli költséget. Nem szabad korábbi emlékezetből hard-code-olni a frame-számot, felbontást vagy limitet.

A host számára elküldött update nem bizonyít fizikai megjelenést. Ha a host belső állapota nem megfigyelhető, ezt jelöld korlátként. A „launcher/OEM limit” állításhoz megfelelő bizonyíték kell; nem lehet automatikus magyarázat minden megakadásra.

## 12. Graph és közös módosítások hatásvizsgálata

Az alap-szabályzat SCIP-provenance követelménye megmarad. Ellenőrizd a source SHA mellett azt is, hogy a graph ténylegesen lefedi-e az érintett nyelvet és szimbólumokat. Egy matching Dart-index nem bizonyítja egy Kotlin service consumerfelületének auditját.

Ha megfelelő graph létezik, tényleges query és current-source ellenőrzés kötelező. Hiányzó, stale vagy részleges graph esetén rögzítsd a korlátot, és végezz explicit source-alapú definíció-, hívó-, consumer- és tesztfeltérképezést; ezt ne nevezd graph-auditnak. A következő implementációs döntésnél maradó bizonytalanságot külön értékeld.

Közös shader, material, konfiguráció, adatprojekció vagy cache módosítása előtt ellenőrizd az alkalmazásbeli Headert/dashboardot, a lockscreen és a launcher-widget tényleges consumereit. A védett regressziós felületet a valós függőségek határozzák meg.

## 13. Instrumentációs és mérési fegyelem

A mérés legyen korlátos és a mért útvonalat a lehető legkevésbé terhelő. Az aktuális diagnosztikáról ellenőrizd:

- mely szálon készül a timestamp, az esemény, a formázás és a redukció;
- van-e soros lock, IO, nagyméretű objektum vagy teljes node-fa feldolgozás a kritikus úton;
- queue kapacitás, overflow, drop-számláló és retention határ;
- immutable eseményazonosság és időbélyeg;
- a freeze/export konzisztenciája és az addig függő események kezelése;
- LIGHT/FULL vagy más capture-mód többletköltsége, ha ilyen módok vannak.

Az aszinkronra tett naplózás nem jelent automatikusan megszüntetett diagnosztikai költséget. Mérni kell a produceroldali munkát és a háttérterhelést is. Tilos korlátlan queue-val vagy észrevétlen evidence-vesztéssel „optimalizálni”.

Csak a diagnózishoz szükséges mezőket rögzítsd. A logger hiánya vagy hibája nem akadályozhatja a működés szempontjából szükséges hide/show/lifecycle lépést. Ezt a contractot forrásból és releváns tesztből ellenőrizd.

## 14. Teljesítmény-összehasonlítás

Baseline és candidate között azonosítsd a készüléket, build mode-ot, konfigurációt, capture-módot, releváns rendszerállapotot és a tesztsorozatot. A különbségeket ne hallgasd el. Eltérő, kontrollálatlan futásokból ne állíts bizonyított gyorsulást.

Külön eredménysor kell:

- hideg első megjelenésre;
- ismételt ébresztésre;
- feloldási eltűnésre;
- lockscreen animációra;
- launcher-widget animációra és frissítési késésre.

Add meg a mintaszámot és az egyedi kísérleteket. Megfelelő mintaszámnál medián és felső percentilis is hasznos; kevés mintán ne állíts stabil p95-öt. Az első ciklus és a kiugró érték nem dobható el azért, mert rontja az eredményt.

A jelentés válassza szét a queue waitet, CPU-munkát, platformhívás idejét, renderelési munkát, átadási időt és fizikai megfigyelést. Memória-, erőforrás- és háttérterhelési következményeket is ellenőrizni kell, ha az optimalizáció érinti őket.

Ne találj ki teljesíthetetlen vagy mérés nélküli „0 ms”, „azonnal”, „fix 60/120 FPS” elfogadási küszöböt. A számszerű cél és mérési mód a tényleges baseline-ra és termékkövetelményre épüljön. A felhasználó által kért érzékelhető javulás fizikailag is ellenőrzendő.

## 15. Reproducer és anti-false-green tesztek

A tesztválasztás a bizonyított hibához igazodjon. A releváns esetekből legyen megindokolt mátrix; nem kell minden javításnál az egész alkalmazás minden állapotát újratesztelni.

| Eset | Ellenőrizendő contract |
| --- | --- |
| Hideg első wake és ismételt wake | A helyes tartalom és élő animáció valóban elindul; az első ciklus nincs elrejtve. |
| Unlock a sorban álló vagy futó inspection alatt | Nincs késői jogosulatlan show vagy reattach. |
| Unlock előkészítés/attach/első draw közben | A megfelelő generáció visszavonása és erőforrás-kezelése történik. |
| Gyors lock–unlock–lock | A régi callback elutasított, az új legitim ciklus működőképes. |
| Retry törlés, csere, kimerülés | A még szükséges munka nem vész el, és nem keletkezik végtelen újrapróbálás. |
| Hiányos/ellentmondó surface megfigyelés | A bizonytalanságot a visibility-contract szerint kezeli; nincs hamis jogosultság. |
| Több attach egy ciklusban | Első live draw és minden visszavonási epizód helyesen azonosított. |
| Animáció hosszabb megfigyelése | Nincs elhallgatott későbbi megállás, villogás vagy fázisugrás. |
| Konfiguráció A→B→C, késői A/B completion | C aktuális állapota nem íródik felül elavult eredménnyel. |
| Host visszatérés/resize/több widgetpéldány | Nem keverednek az identityk és nem indul újra szükségtelenül az animáció. |
| Dispose/új szolgáltatás/session | Nincs orphan callback, hibás visszajelzés vagy bizonyított erőforrásszivárgás. |

**Kötelező előzetes natív hatásmátrix.** A fenti esetekből a reviewer a tényleges módosításhoz kitöltött R… sorokat készít az alap-szabályzat szerint. Az eset neve önmagában nem ellenőrzési terv: kell az exact owner/szimbólum, kiinduló állapot, eseménysorrend, megőrzendő feltétel, utófeltétel, teszt és parancs. Az elérhető cache-hit szinkron callbacket, cache-miss aszinkron callbacket és fallbacket együtt vizsgáld. A választott route/authority beállítása és a callback lehetséges futási ideje közötti sorrendet a forrásban ellenőrizd.

Előkészítést vagy renderer-életciklust érintő módosításnál külön vizsgáld:

- mely erőforrás marad újrahasználható, és mely képkocka-/bufferhasználatot kell lezárni;
- detached vagy érvénytelen lease mellett milyen publikáció tiltott, és hogyan szabadul fel a függő munka;
- a következő jogosult attach valóban aktuális tartalommal indul-e;
- indulhat-e két előkészítési út egyszerre; milyen módokban indokolt külön route vagy fallback;
- a failure/cancel/dispose/stale completion minden ága megőrzi-e a globális erőforráskorlátot.

Ezek vizsgálati kötelezettségek; nem írnak elő minden architektúrára nulla foglaltságot vagy egy konkrét GPU-megoldást. A pontos élettartamot, fence-/buffer-biztonságot és mérhető utófeltételeket a reviewer a current source alapján határozza meg.

**A valós service-fixture szerződése.** A reviewer adja meg az egyes szakaszok setupját, elfogadási predikátumát, állapotot bizonyító API/ownerét, megfigyelési időpontját, akcióját, tényleges outputját és cleanupját. Display-off, keyguard-locked, app-root-withdrawn, accessibility/window metadata és globális idle külön állítások. Egy második lekérdezés új megfigyelés; az előző sikeres minta nem garantálja az érték változatlanságát. Az egyszeri megfigyelés, tartós állapot és akció előtti friss ellenőrzés közül a reviewer válassza a teszt célját valóban igazoló szerződést. A cél megőrzése nélkül tilos az újraellenőrzést elhagyni vagy gyengébb predikátumra cserélni.

A fixture-előfeltétel bukása, a production output hiánya és a cleanup/export hibája külön hibacsoport. A teszt ne fogadjon el másik epizód korábbi sikerét a vizsgált epizód helyett. Assertionjavításnál legyen kontroll, amely a valóban hibás állapotot továbbra is elutasítja; timeoutnövelés vagy sleep önmagában nem javítás.

**Célzott natív kör → teljes delivery.** A prompt nevezze meg a ténylegesen elérhető hostot/runnert, Android/API/emulátor-konfigurációt, app/test buildazonosságot, tesztmetódusokat vagy scriptet, setup/reset feltételeket, futási korlátot és artifactokat. ARM/proot környezetből nem feltételezhető helyi x86_64 Android-emulátor vagy kompatibilis buildtool. A hiányzó gyors távoli útvonal külön megtervezendő feladat; nem állítható késznek.

Ha a repository támogatja, egy exact candidate app/test APK-párjával végezhető a kijelölt, korlátos diagnosztikai sorozat. Forrás-/buildbemenet-változás új megfelelő buildet igényel. Minden sikertelen minta megmarad; a célzott siker csak a kiválasztott contractot igazolja. Nem helyettesíti a teljes kötelező natív/service/regressziós kapukat, és nem jogosít ellenőrzött Human APK kiadására. A teljes futás előtt az alap-szabályzat belépési táblájában szerepeljen minden R… sor eredménye és nyitott hiba.

Tesztbizonyítási szintek:

- Policy/unit teszt: determinisztikus állapot- és sorrendi contract, ha valódi production policyt használ.
- Production integration/instrumentation: a tényleges service/controller/queue/window/render útvonal releváns része.
- Fizikai készülékteszt: a felhasználó számára látható késés, animáció és elfogadhatóság.

Egy unit teszt nem bizonyít teljes WindowManager-, GPU- vagy launcher-viselkedést. Egy mock callback, event count, előre kész cache, offscreen shader-siker vagy későbbi settle nem adhat hamis zöldet az eredeti tünetre. A tesztnek a vizsgált végső állapotot/generációt és a releváns tényleges outputot kell ellenőriznie.

Emulátoros siker és CI-zöld nem jelent fizikai Nothing/OEM készülékes elfogadást. Sikertelen tesztet ne címkézz inherited failure-nek összehasonlító bizonyíték nélkül.

## 16. Scope lock és tiltott látszatjavítások

Minden prompt nevezze meg a javítható ownereket/fájlokat, a konkrét szimbólumokat, módosítandó kódrészletet és a védett felületeket. A reviewernek le kell írnia az új működési sorrendet és az implementáció módszerét, nem elegendő egy általános teljesítménycél. Előzetes bizonyíték nélkül tilos broad rewrite, új párhuzamos authority vagy a hiba áthelyezése egy másik lifecycle-fázisba.

Refaktor akkor adható ki, ha a reviewer a forrásból megmutatja, miért akadályozza a jelenlegi szerkezet a szükséges contractot, és maga megtervezi az új ownership-, thread-, lifecycle- és adatátadási határokat, a migráció lépéseit és a regressziós bizonyítást. A coding agentre nem bízható az architektúra kiválasztása.

Nem elfogadható teljesítményjavulás:

- a widget vagy animáció kikapcsolásával;
- az animáció önkényes lassításával, statikus képre cserélésével vagy vizuális hűségének lerontásával;
- szükséges adat-/konfigurációfrissítések eldobásával vagy stale tartalom fenntartásával;
- eligibility-, feloldási-, privacy- vagy lifecycle-ellenőrzés megkerülésével;
- az overlay feloldás utáni megtartásával vagy input blokkolásával;
- nagyobb timeouttal, késleltetett megjelenítéssel, debounce/cooldown hozzáadásával a tünet elfedésére;
- korlátlan pollinggal, előkészítéssel, queue-val vagy cache-sel;
- a mérési kezdőpont későbbre mozgatásával, a legrosszabb ciklusok elhagyásával;
- diagnosztikai eventek vagy hibás kísérletek észrevétlen eldobásával.

Létező, indokolt retry, cache, batching vagy bootstrap mechanizmust sem kell automatikusan eltávolítani. Az aktuális szerződését és költségét kell bizonyítani. Ez a kiegészítés nem rendel el konkrét prefetch flaget, globális cache clear-t, új rendertechnikát vagy korlátlan előmelegítést.

Külső widgetalkalmazásra, médialejátszó-trükkre vagy más termékirányra váltás nem része egy teljesítményjavító promptnak, hacsak a felhasználó külön nem kéri.

## 17. Hurokelkerülés és kötelező közös napló

A prompt writer minden új fizikai visszajelzésnél ellenőrzi a GitHub-változásokat és append-only bejegyzést készít a közös naplóba. A coding agent minden alkalmazási commitját és validációs eredményét ehhez a vizsgálati lánchoz köti.

Minden bejegyzés tartalmazza:

1. Tesztelt alkalmazási SHA/build; aktuális branch HEAD és a dokumentációs commitok megkülönböztetése.
2. A konkrét felhasználói megfigyelés, hibaterület és tesztkörülmény.
3. Az előző commit tényleges változása és a megvizsgált diff/source/test kör.
4. Evidence-hivatkozások, capture/session, hash, retained tartomány és hiányok.
5. PROVEN / UNPROVEN / MISSING EVIDENCE.
   E… hivatkozások, H… státuszváltozások és D… döntés; a bizonyítás pontos
   route-, generáció-, mérési és fizikai határa. Modellváltásnál a közös
   evidence-csomag és az esetleges kontextuseltérés is szerepeljen.
6. Megkísérelt javítás vagy instrumentáció, baseline/candidate eredmény és bizonyítási korlát.
7. Elvetett vagy még nyitott hipotézis; miért nem szabad új bizonyíték nélkül ugyanazt megismételni.
8. Reviewer által kijelölt következő konkrét javítás vagy kísérlet, védett viselkedés és fizikai státusz.
9. Feladattípus, reviewer-döntés hivatkozása, pontosan átadott technikai terv és a coding agenttől várt artifact.
10. Tervtől való eltérés vagy ellenbizonyíték esetén a reviewerhez visszaadott döntés; új diagnózist az agent nem írhat tényként a naplóba.

A napló run/source szerinti rövid hibajegyzéke az összes releváns bukást tartalmazza: exact lépés/hiba, fordítás/production/fixture/mérés/infrastruktúra besorolás, evidence és következő reviewer-döntés. Bizonytalan besorolás maradjon bizonytalan. Ne csak az első assertiont kezeld, miközben ugyanabban a futásban másik ismert hiba is maradt. A tervet cáfoló első hiba visszatér a reviewerhez; ugyanazon hibahatár új evidence nélküli ismételt bukása után tilos újabb vak teljes CI. A reviewer meghatározott célzott kísérletet vagy javítást ad; a mechanikus szerződésen belüli korrekció és a független engedélyezett munka folytatható.

Ugyanazt a flagcserét, cache-stratégiát, queue-áthelyezést vagy renderer-átalakítást ne add ki újra új oksági bizonyíték nélkül. A már kipróbált irány újravizsgálása megengedett, ha a prompt világosan megnevezi az új bizonyítékot vagy a korábbi összehasonlítás hibáját.

A prompt writer kizárólag a naplófájlt commitolja a repositoryban. A commit legyen build-trigger nélküli: ellenőrizze a tényleges workflow-triggereket és a megfelelő skip-mechanizmust; használjon `[skip ci]` jelölést, ahol az hatályos; ne indítson workflow-dispatcht. A csak dokumentációs diffet és az eredményt ellenőrizze, párhuzamos változásokat őrizzen meg. Ha új futás indul, azt ne hallgassa el.

Minden coding-agent promptban explicit olvasási utasítás kell az alap-szabályzatra, erre a kiegészítésre és a `docs/FLUVI_ENGINEERING_JOURNAL.md` fájlra. Hiányzó assetnél ne állítsa az agent, hogy elolvasta; a hozzáférési hiányt rendezni kell a rá épülő implementáció előtt.

## 18. Az angol coding-agent prompt kötelező widgettartalma

Az alap-szabályzat 21 részes szerkezete megmarad. Az alábbiak a widget-feladatokban kötelező tartalmi megfeleltetések, nem új, alternatív promptformátum:

| Alap-prompt rész | Widget-specifikus tartalom |
| --- | --- |
| 1. TITLE / TASK INTENT | IMPLEMENTATION vagy EVIDENCE_COLLECTION, reviewer-döntés; W-SHOW/W-HIDE/W-LOCK-ANIM/W-HOME-ANIM scope és védett felületek. |
| 2–3. STATE / PREFLIGHT | Exact installed/tested source, APK, branch, host/készülék, service/widget identity, szabályzatok és napló. |
| 4–6. USER / LOG / AGENT AUDIT | Teljes capture, animációs referencia, epizódok, commitok, actual diff, jelentések és evidence-korlátok. |
| 7. GRAPH / IMPACT | Source- és nyelvi lefedettség, közös producer/material/dashboard consumerfelület; kitöltött R… hatásmátrix a szükséges összefüggő módosításokkal. |
| 8–10. SOURCE / CLASSIFICATION / CAUSAL GATE | A reviewer saját source-auditja, ownerlánc, órák, végpontok, bizonyított first failing boundary vagy konkrét, cáfolható hipotézishez kötött mérési terv. |
| 11–12. SCOPE / LAYERS | Visibility/lifecycle/identity invariánsok, natív ablak- és hosthatárok, no-touch felületek. |
| 13–14. RED TESTS / IMPLEMENTATION | Exact kódrészlet és cserekoncepció/pszeudokód; R… soronként lifecycle-, sync/async-, fallback- és erőforrásfeltételek; fixture setup/megfigyelés/output/cleanup, negatív kontroll; mérési feladatban csak kijelölt instrumentáció. |
| 15. PERFORMANCE | Külön show/hide/lockscreen-animation/home-widget mérés, cold/warm, baseline/candidate, diagnosztikai költség. |
| 16–18. ORDER / VALIDATION / COMMITS | Kicsi validált egységek egy teljes előre megtervezett repairen belül; gyors/célzott/teljes ellenőrzés külön; CI-belépési tábla, exact PASS/FAIL/NOT RUN; minden hibacsoport és reviewer-visszaadási pont; teljes commit body és naplókapcsolat. |
| 19–21. DELIVERY / REPORT / DONE | Diagnosztikai futás és végső delivery külön; teljes kötelező kapuk, exact-source APK/hash, graph státusz, mátrixeredmények és hibajegyzék a completion reportban; user-only fizikai elfogadás. |

A prompt kötelező preflight-mondata, az aktuális assetelérhetőségek megadásával:

> Before execution, read the complete current FLUVI_PROMPT_WRITER_RULES, FLUVI_WIDGET_DEBUGGING_PROMPT_ADDENDUM.md, docs/FLUVI_ENGINEERING_JOURNAL.md, and relevant MILESTONE_COMMITS.md entries using the versions and access paths supplied in this handoff. Explicitly report missing material. The prompt writer owns diagnosis, causal interpretation, the repair concept and any refactor decision. Implement only the specified technical contract or execute only the specified evidence-collection experiment; do not select a new root cause or repair strategy. If source, logs or tests contradict the plan, preserve and report exact evidence and return the affected decision to the reviewer. Continue independent authorized work. Follow the supplied risk-to-test matrix and the verified focused-validation route. Record every relevant failure and every diagnostic repetition. Start full delivery only after the specified entry conditions; diagnostic selection does not satisfy full required gates. Do not repeat a rejected repair without new evidence and a reviewer decision. Resolve the exact physically tested application source separately from documentation-only HEAD commits. Preserve the dashboard contracts and verify the specified native lockscreen and launcher-widget boundaries.

Ez a preflight-részlet önmagában nem teljes coding-agent prompt. A prompt writer továbbra is egyetlen angol, copy-ready, bizonyítékokra épülő teljes handoffot ad.

## 19. Completion report és befejezési feltételek

Az alap-szabályzat teljes completion reportján túl külön eredménytábla kell a scope-ba tartozó négy hibaterületre. Mindegyik sor jelölje:

- baseline és final alkalmazási SHA/build;
- vizsgálati és fizikai státusz;
- mintaszám, mérési kezdő-/végpontok és időalap;
- mért eredmény és regressziós összehasonlítás;
- tényleges output/evidence és annak korlátai;
- fennmaradó hiba vagy nem vizsgált felület.

A report tartalmazza az R… kockázati sorok tényleges ellenőrzését, a fixture előfeltételeit, a gyors/célzott/teljes futások külön eredményét, a teljes CI belépési tábláját és minden hibacsoport naplóhivatkozását. A diagnosztikai útvonal tervét, implementálását és sikeres kipróbálását külön státuszként jelölje.

A report külön tartalmazza a reviewer átadott diagnózisát és tervét, valamint az agent által ténylegesen mért új tényeket, eltéréseket és artifactokat. A következő oksági következtetést a reviewer végzi. EVIDENCE_COLLECTION lezárásakor a kijelölt evidence átadása történt meg; ebből nem következik javított alkalmazás vagy lezárt fizikai hiba.

Külön kell közölni a javítás implementálását, automatizált igazolását, az artifact elkészültét és a fizikai elfogadást. A „kész”, „smooth” vagy „latency fixed” nem lehet egyetlen teszt zöld státuszának átnevezése.

Az implementációs szállítás akkor tekinthető ellenőrzötten átadottnak, ha az érintett contractok tesztjei, a védett regressziós ellenőrzések és a releváns delivery-feltételek teljesültek; a kimaradt vagy sikertelen ellenőrzések pontosan meg vannak nevezve; a napló és a teljes report elérhető.

A fizikai hibát csak a felhasználó exact APK-ra adott visszajelzése zárhatja le. Addig a végső fizikai státusz szó szerint:

`PHYSICAL VALIDATION — PENDING, USER ONLY`

Új elfogadott lockscreen- vagy launcher-widget mérföldkő csak explicit fizikai elfogadás után rögzíthető, pontosan megnevezett viselkedésre és ismert korlátokra. Egy animáció elfogadása nem foglalja magában automatikusan a megjelenési és eltűnési késés elfogadását.
