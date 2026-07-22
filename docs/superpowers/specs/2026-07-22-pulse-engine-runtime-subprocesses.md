# Pulse Engine Runtime — Részfolyamat-specifikáció

**Cél:** A Pulse motor működése egyértelmű legyen a mockupban és később a
Flutter implementációban is: mikor fut, mit enged be, miből lesz story, miért
nyer egy story, és melyik source melyik mondatrészt írja.

**Kapcsolódó források:**

- docs/superpowers/specs/2026-07-13-hidden-forecast-pulse-design.md
- docs/superpowers/specs/2026-07-22-pulse-engine-decision-trace-design.md
- docs/prototypes/pulse_engine_panel_mockup.html

## Alapelv

A Pulse nem trigger-queue és nem notification lista. Minden releváns esemény
után a motor újraszámolja a jelenlegi igazságot, majd legfeljebb egy aktuális
storyt ad a headernek. A többi signal nem vész el: forming, waiting,
suppressed, resolved vagy diagnostics állapotban látható marad a panelben.

~~~text
adatváltozás
  -> local recalculation
  -> raw signal state
  -> eligibility gate
  -> story formation
  -> priority selection
  -> copy composition
  -> one header delivery
  -> lifecycle persistence
~~~

## 1. Újraszámolási folyamat

### Indító események

- új, módosított vagy törölt tranzakció;
- recurring ghost aktiválása, esedékessé válása vagy feloldódása;
- budget, limit, saving goal vagy kategória módosítása;
- dátumváltás, app open vagy resume;
- kategorizálatlanság késleltetett állapotának újraértékelése.

### Bemenet

A jelenlegi lokális financial state: tranzakciók, kategóriák, limitek,
recurring ghostok, balance, income, score line, kontroll score, rolling
aggregátumok és a korábbi signal/story fingerprint-ek.

### Kimenet

Egy friss calculation frame. Ez még nem header pulse; csak a következő
folyamatok közös, aktuális bemenete.

### Foreground és background szabály

Foregroundban a megfelelő story a következő lokális újraszámolás után
versenyezhet a headerért. Backgroundban a motor tárolhatja az új állapotot, de
nem játszik le egymás után több header üzenetet; a delivery app open/resume
alkalmával dől el.

## 2. Raw signal-képzési folyamat

### Cél

Minden detector egy nyers, strukturált signal állapotot ad vissza, nem kész
mondatot.

### Kötelező signal mezők

~~~text
sourceId
domain
target
sourceType
severity
direction
value
moneyImpact
urgencyDays
confidence
transition
fingerprint
lifecycleState
~~~

### Példák

- HF-001: month-end expense forecast átlépte a budget limitet.
- HF-005: activated és pending recurring költség materialis fix loadot ad.
- HF-007: expected income ghost due vagy overdue, de még nem activated.
- HF-021: kategorizálatlan tételek késleltetve, csoportosítva rontják a
  forecast bizalmát.

A raw signal csak azt mondja meg, mi igaz most. Nem dönti el, hogy ez
megjelenik-e, és nem gyárt header copyt.

## 3. Eligibility és lifecycle gate

### Cél

Elválasztani azt, hogy egy jel igaz-e, attól, hogy most hasznos-e a usernek.

### Kapu sorrendje

1. A signal current-e, vagy stale/resolved?
2. Érvényes-e a user mute, cooldown vagy target override?
3. Ugyanaz a fingerprint korábban shown vagy dismissed volt-e?
4. Elég magas-e a confidence?
5. Megvan-e a saját delay, due-window vagy threshold feltétele?
6. A signal egy erősebb, ugyanazon targethez tartozó state által superseded-e?

### Kimeneti állapotok

| Állapot | Jelentés | Headerbe mehet? |
| --- | --- | --- |
| observing | figyelt, de még nem meaningful | nem |
| waiting | részben igaz, delayre vagy több evidence-re vár | nem |
| eligible | current, releváns, versenyezhet | igen, storyn keresztül |
| muted | user policy blokkolja | nem |
| superseded | ugyanazon target frissebb/erősebb state-je felülírta | nem |
| resolved | már nem igaz | nem, de recovery alapja lehet |
| suppressed | ready story része vagy önálló ready story, de nem nyert | nem most |
| shown | ugyanazzal a fingerprinttel már látszott | nem ismétel |

### Fontos szabályok

- Egy magas score nem tehet eligible-gé waiting, muted vagy same-fingerprint
  signal-t.
- HF-003 csak meaningful daily-ceiling zónaváltáskor vagy erősebb parent story
  evidence-eként haladhat tovább.
- HF-021 csak a saját delay és count/money threshold után lehet eligible.
- HF-015 a 75%-os állapotot a 90%-osra cserélheti; nem külön header-story.
- HF-008 V1-ben deferred, ezért nem válhat eligible header source-szá.

## 4. Story formation folyamat

### Cél

A rokon eligible signalokból egy közös, emberileg hasznos állítás jöjjön
létre, ne tíz egymás utáni értesítés.

### Kapcsolódási kulcs

A composer elsődlegesen domain és target szerint kapcsol:

~~~text
budget_pressure + ugyanaz a monthly target
cashflow_pressure + upcoming cashflow period
fixed_load + month-end / same cashflow period
behavior_shift + az általa magyarázott budget vagy cashflow target
data_quality + az érintett forecast mint caveat
~~~

### Evidence szabályok

| Evidence | Story állapot |
| --- | --- |
| 1 critical signal | ready |
| 1 high confidence + material signal | ready |
| 2 related medium signal | ready |
| 3 related low signal | ready |
| jelentős, korábbi important risket feloldó recovery | ready |
| delay + threshold utáni data quality | ready |
| ettől gyengébb vagy nem rokon signalok | forming vagy külön marad |

### Tiltott összekapcsolás

Kis, egymástól független signalok nem adódnak össze. Például egy
kategorizálatlan tétel és egy unrelated score mozgás nem lesz automatikusan
ugyanaz a story.

### Story állapotok

~~~text
forming -> ready -> selected -> delivered -> shown
                       |
                       -> suppressed
~~~

A suppressed story nem queue-ban várakozik. A következő recalculationkor ismét
a jelenlegi state-ből épül fel, és csak akkor nyerhet, ha még current és
releváns.

## 5. Priority-score folyamat

### Cél

A ready storyk közül egyetlen, legfontosabb current story kiválasztása.

### Elkülönített fogalmak

- **Base weight:** egy domináns detector eredendő súlya.
- **Evidence:** azt igazolja, hogy a story összeállhat; nem vak pontösszeg.
- **Modifier:** story-szintű, látható korrekció.
- **Priority:** a story összehasonlítására szolgáló végső 0..100 érték.

### Alapsúlyok

~~~text
actual over-limit / 100%+            100
month-end forecast over limit         85
missing expected income               80
fixed cost due in 7 days              70
critical balance buffer               65
category limit forecast               65
expense/income ratio warning          60
saving goal at risk                   55
weekly pace / rolling trend / score   45
category spike                        40
uncategorized status                  35
daily safe spend advice               30
positive/win                          20
~~~

### Pontszámképlet

~~~text
priority = clamp(0..100,
  dominant eligible base weight
  +15 material money impact
  +10 due within 3 days
  +10 related evidence in the same story
  -20 low confidence
  -30 recently dismissed similar story
)
~~~

A módosító csak akkor szerepel, ha a panelben névvel, értékkel és okkal
látszik. A rokon support source-ok nem adják hozzá vakon saját base weightjüket,
mert akkor sok kicsi, független jel le tudna győzni egy critical state-et.

### Tie-break

Azonos priority esetén:

1. korábbi, valódi due state;
2. frissebb, materialisan changed fingerprint;
3. stabil source ID szerinti döntés.

A panelnek meg kell mondania, ha tie-break döntött.

## 6. Story-copy composition folyamat

### Cél

A header egy összefüggő gondolatot kapjon, ne HF-kódokat vagy egymásra dobált
trigger szövegeket.

### Mondatrészek

| Slot | Funkció | Lehetséges source |
| --- | --- | --- |
| Headline | fő, jelenlegi igazság | domináns risk, recovery vagy data-quality source |
| Evidence | legfeljebb két konkrét bizonyíték | limit, ratio, trend, category, buffer, goal |
| Time/cause | miért most, mi esedékes | due window, fixed load, missing income, transition |
| Confidence caveat | értelmezési korlát | HF-021, low confidence, early period |
| Recovery | mi oldott meg egy fontos korábbi risket | resolved state, ghost income arrival, improved buffer |

### Source-role szabályok

| HF source | Copy szerep |
| --- | --- |
| HF-001 | headline lehet; month-end forecast claim |
| HF-002, HF-004, HF-012, HF-013, HF-020 | evidence vagy context |
| HF-003 | coach detail; nem napi standalone spam |
| HF-005, HF-006 | time/cause vagy evidence |
| HF-007 | headline vagy recovery |
| HF-009, HF-010, HF-011 | headline lehet, ha domináns eligible risk |
| HF-014 | context; csak meglévő score movementet ír le |
| HF-021 | confidence caveat vagy saját data-quality headline |
| HF-008 | nincs V1 copy |
| HF-015 | supersede motorlogika, nincs copy |
| HF-016–HF-019 | engine diagnostics, nincs user-facing pénzügyi copy |

### Példa

~~~text
[Headline · HF-001] A hónap vége szoros lesz.
[Evidence · HF-002] 3 keret túlfutás felé tart,
[Time/cause · HF-005] és még 42 000 Ft fix kiadás várható.
~~~

A copy mapnak azt is láthatóvá kell tennie, ha egy signal kimaradt, például
redundáns, waiting, superseded, low confidence vagy suppressed okból.

## 7. Header delivery folyamat

### Cél

A kiválasztott story egyszer, érthetően és nem inboxként jelenjen meg.

### Feltételek

A story akkor jut deliveryig, ha:

1. ready;
2. selected;
3. foregroundban megjeleníthető, vagy resume után is current;
4. nincs same-fingerprint repeat;
5. nem blokkolja cooldown vagy user-defined delivery policy.

### Kimenet

~~~text
selected -> delivered -> shown
~~~

A header a selected story headline-ját és a rövid, source-mapelt detailt kapja.
A panelben minden nem nyertes jel és story továbbra is diagnosztikaként
elérhető.

## 8. Persistence, resolve és retrigger folyamat

### Tárolandó state

A motor state-et és fingerprintet tárol, nem régi renderelt sentence textet.

~~~text
sourceId + target + periodKey + condition + direction + thresholdZone
~~~

### Újramegjelenési szabály

- Ugyanaz a shown vagy dismissed fingerprint nem ismétel.
- A materially changed fingerprint újra versenyezhet.
- A resolved state később újra eligible lehet, ha egy új transition újra
  igaz állapotot hoz létre.
- Ugyanazon target erősebb zónája supersede-eli a korábbi, el nem avult
  gyengébb zónát.

## 9. A mockupban látható Decision Trace

A HTML-ben három determinisztikus forgatókönyv mutatja ugyanezt a kilenc
részfolyamatot:

1. **Risk:** HF-001 + HF-002 + HF-005 közös month-end story; egy kisebb,
   ready cashflow story suppressed.
2. **Recovery:** korábbi risk resolved, ghost income arrived; a recovery csak
   meaningful transitionként jelenik meg.
3. **Data quality:** HF-021 a késleltetés és csoportosítás után saját,
   nem sürgős app-state storyt ad.

Mindegyik nézeten ugyanaz a teljes trace látszik: event, signalok,
eligibility, evidence, score ledger, candidate-verseny, lifecycle és
mondatrészek.

## Nem cél

- A mockup nem állítja, hogy a Flutter runtime már implementálva van.
- A mockup nem számol új score-t vagy új pénzügyi formulát a meglévő
  source registeren kívül.
- A mockup nem változtatja meg a Budget pressure, Cashflow pressure és Data
  quality háromgombos railt.
