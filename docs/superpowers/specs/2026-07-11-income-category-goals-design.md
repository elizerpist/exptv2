# Bevételi Célok Design

Date: 2026-07-11
Project: exptv2

## Cél

A bevételi oldal ne kiadási értelemben vett limiteket használjon. Bevételi oldalon ugyanaz a tárolási és szerkesztési infrastruktúra új szemantikát kap:

- kiadási kategória: keret / limit, ahol a magas kihasználtság veszély;
- kiadási `Budget`: kategória nélküli összkiadási keret;
- bevételi overview cél: `Összbevételi cél`;
- bevételi kategória: bevételi cél, ahol a magas teljesülés jó.

Ez a változás a backheader expandált, lefelé swipe-pal előhívható kategória/cél felületére vonatkozik, különösen a center badge circle progressre és az alatta/expandált részen megjelenő rövid státuszfeliratra.

## Forráskód Kontextus

A meglévő implementáció már képes külön `transactionType` szerint tárolni cél/limit adatot:

- `lib/features/transactions/models/category_limit.dart`
- `lib/features/transactions/models/transaction_category.dart`
- `lib/features/transactions/models/category_budget_bar_data.dart`
- `lib/features/transactions/data/limit_manager.dart`
- `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`

A tárolás továbbra is használhatja a meglévő `category_limits` modellt:

```text
Overview income goal:
targetType = overview
targetId = 0
transactionType = income
window = monthly | yearly | all_time
periodKey = active period key

Income category goal:
targetType = category
targetId = income category id
transactionType = income
window = monthly | yearly | all_time
periodKey = active period key
```

Fontos: a storage neve maradhat technikai kompatibilitásból `CategoryLimit`, de a UI-ban és a domain copyban bevételi oldalon nem "limitként", hanem "bevételi célként" kell megjelenni.

## Termékmodell

### Kiadás

Kiadási kategóriánál a jelenlegi logika marad:

```text
spent = aktív időszak kiadása az adott kategóriában
limit = beállított kategórialimit
progress = spent / limit
```

Értelmezés:

- limit alatt: rendben;
- limit közelében: figyelmeztetés;
- limit felett: túllépés.

### Bevétel

Bevételi oldalon két célfajta van:

```text
Összbevételi cél = kategória nélküli teljes bevételi cél
Bevételi kategória cél = adott bevételi kategória célja
```

Az összbevételi cél a kiadási `Budget` bevételi párja. Nem megtakarítás, mert nem a bevétel és kiadás különbségét számolja, hanem csak azt, hogy az aktív időszak teljes bevétele elérte-e a beállított célösszeget.

Összbevételi cél:

```text
totalIncome = aktív időszak összes bevétele
goal = beállított összbevételi cél
progress = totalIncome / goal
```

Bevételi kategória cél:

```text
earned = aktív időszak bevétele az adott kategóriában
goal = beállított bevételi cél
progress = earned / goal
```

Értelmezés:

- cél alatt: még hiányzik valamennyi;
- cél elérve: cél megvan;
- cél felett: plusz bevétel.

Bevételnél tilos a kiadási "túllépés = rossz" logikát használni. Ha a bevétel meghaladja a célt, az sikeres állapot.

### Bevételi Oldali Swipe Lista

Az expandált backheader bevételi oldali sorrendje:

```text
1. Összbevételi cél
2. Bevételi kategória célok
```

`Megtakarítás` nem szerepel külön célként ebben a feature-ben. A megtakarítás más logika lenne, mert `bevétel - kiadás` alapú, ezért most nem része a bevételi backheader cél-listának.

## Circle Progress

A center badge circle progress bevételi oldalon is megmarad. Jelentése:

```text
actualIncome / goal
```

Matek:

```text
actualIncome = összbevételi célnál totalIncome, kategória célnál earned
rawProgress = actualIncome / goal
ringProgress = clamp(rawProgress, 0, 1)
missing = max(goal - actualIncome, 0)
surplus = max(actualIncome - goal, 0)
```

Ha nincs beállított cél:

```text
goal <= 0 vagy hasLimit == false
```

akkor nincs érdemi progress. Ilyenkor a circle ne mutasson hamis 0%-os bukást; a progress fill legyen rejtve, és legfeljebb a meglévő halvány track jelenhet meg, ha az adott backheader design ezt minden badge-nél mutatja.

## Circle Színezés

A kategória ikon/disc maradjon kategóriaszínű, mert az az identitás.

A progress ring bevételnél ne használja a kiadási warning/danger küszöböket:

- cél alatt: kategóriaszínű progress;
- cél elérve vagy cél felett: siker/zöld progress;
- nincs cél: nincs progress fill.

Kiadási oldalon változatlanul marad:

- 75% körül figyelmeztetés;
- 90% felett veszély;
- limit felett piros/túllépett állapot.

## Amount Sor

A backheader aktív cél/kategória amount sora marad egyszerű.

Összbevételi cél:

```text
420k / 600k cél
```

Bevételi kategória cél nélkül:

```text
420k
```

Bevételi kategória céllal:

```text
420k / 600k cél
```

Ha az összbevételi célnél nincs cél beállítva:

```text
420k
```

Ez a sor a jelenlegi `BackheaderBudgetItem.amountText` szemantikájának bevételi oldali copy-váltása. A kiadási oldalon továbbra is a meglévő `spent / limit` jelleg marad.

## Expandált Státuszfelirat

A bevételi cél rövid státuszfelirata pontosan ugyanarra a UI helyre kerüljön, ahol kiadási oldalon most az `X maradt` szöveg van a lefelé swipe-pal expandált backheader felületen.

Kapcsolódó jelenlegi hook:

```text
CategoryBudgetStage.centerRemainingText
BackheaderStyleSurface.centerRemainingText
ValueKey('backheader-center-remaining-amount')
```

Bevételi oldalon a felirat legyen rövid, magyarázat nélküli, és ugyanazt a formattert használja összbevételi célra és kategória célra:

```text
actualIncome < goal:
  X hiányzik

actualIncome == goal:
  Cél megvan

actualIncome > goal:
  +X plusz

nincs cél:
  Nincs cél
```

Összbevételi cél példa:

```text
Összbevételi cél
420k / 600k cél
180k hiányzik
```

Kategória cél példák:

```text
Fizetés
420k / 600k cél
180k hiányzik
```

```text
Fizetés
600k / 600k cél
Cél megvan
```

```text
Fizetés
750k / 600k cél
+150k plusz
```

Ez a felirat csak az expandált backheader információs slotban jelenik meg. A kompakt header ne kapjon új szöveges magyarázatot.

## Editor Copy

Amikor a user bevételi overview célt szerkeszt:

- a cím `Összbevételi cél`;
- a slider/input az aktív időszak teljes bevételi célját állítja;
- mentés után a tárolás technikailag `targetType=overview`, `transactionType=income` rekord lehet.

Amikor a user bevételi kategóriát szerkeszt:

- a cím ne "Limit" legyen, hanem `Bevételi cél`;
- a slider/input ugyanazt az összeget állítja, de goal szemantikával;
- mentés után a tárolás technikailag ugyanúgy `category_limits` rekord lehet;
- az alert/túllépés szóhasználat ne jelenjen meg bevételi kategóriánál.

Javasolt rövid UI copyk:

```text
Összbevételi cél
Bevételi cél
Cél összege
Nincs cél
Cél megvan
X hiányzik
+X plusz
```

Tiltott / nem használt copy ebben a feature-ben:

```text
Megtakarítás
Megtakarítási cél
```

## Adat- és Domain Határ

A meglévő `CategoryLimit` adattípus megtartható perzisztencia DTO-ként, de a számítási/UI rétegben célszerű bevételi célokhoz külön szemantikai helper vagy view model:

```text
IncomeCategoryGoalView
```

Minimális elvárás, hogy a view modelből egyértelműen kinyerhető legyen összbevételi célra és kategória célra is:

```text
actualIncome
goal
hasGoal
rawProgress
ringProgress
missing
surplus
statusText
progressColor
```

Nem kötelező új adatbázistábla. A lényeg az, hogy a UI és a számítás ne hívja bevételi oldalon limitnek azt, ami terméklogikailag cél.

## Érintett Viselkedések

### Backheader Center Badge

Bevételi overview vagy bevételi kategória aktív állapotban:

- a circle progress az `actualIncome / goal` arányt mutatja;
- a progress 100%-nál telik be;
- 100% felett nem nő tovább, hanem sikerállapot marad;
- nincs piros warning csak azért, mert a bevétel magas.

### Swipe és Aktív Elem

A bevételi kategóriák továbbra is ugyanúgy részei az expandált backheader swipe listának, de előttük szerepel az `Összbevételi cél`. `Megtakarítás` nem kerül be ebbe a listába.

### Summary Window

A cél ugyanúgy időablakhoz kötött, mint a jelenlegi limitek:

- havi cél;
- éves cél;
- összesített cél.

Az aktív SummaryPill/window határozza meg, melyik célrekord és melyik tranzakciós összeg számít.

## Nem Cél

Ez a design nem változtatja meg:

- a kiadási kategórialimitek viselkedését;
- a kiadási warning/danger színeket;
- a `category_limits` storage alapidentitását;
- a backheader swipe mechanikáját;
- a stat menü bevétel score modelljét;
- megtakarítási cél számítást.

## Elfogadási Checklist

| ID | Forrás | Érintett terület | Elfogadási feltétel | Verifikáció | Státusz |
| --- | --- | --- | --- | --- | --- |
| ICG-01 | User: "a bevételi categóriák legyenek bevétwli célok limit helyett" | Domain copy + editor | Bevételi kategóriánál a UI `Bevételi cél` szemantikát használ, nem kiadási limitet | Widget teszt + code inspection | NOT DONE |
| ICG-02 | User: "láthatsz egy circle progress bart, mit mutasson, és hogy?" | Center badge progress | Bevételi overview és kategória circle progress `actualIncome / goal`, 100% felett clampelt teljes kör | Unit/widget teszt | NOT DONE |
| ICG-03 | Brainstorm döntés | Center badge color | Bevételi cél 100% felett sikerállapot, nem warning/danger/piros | Widget golden vagy painter teszt + code inspection | NOT DONE |
| ICG-04 | User: "a ciecle az jó" | Backheader visual | A meglévő circle progress vizuális forma megmarad, csak a bevételi szemantika változik | Screenshot/golden vagy widget inspection | NOT DONE |
| ICG-05 | User: "fekirat egysuerű legyen" | Expandált státuszfelirat | Bevételi státusz csak `X hiányzik`, `Cél megvan`, `+X plusz`, `Nincs cél` lehet | Unit teszt státusz formatterre | NOT DONE |
| ICG-06 | User: "ott kell lennie, ahol a kiadásnál még az x maradt szövegnek" | `centerRemainingText` slot | Bevételi státusz ugyanabban a `backheader-center-remaining-amount` helyen jelenik meg, mint kiadásnál az `X maradt` | Widget teszt ValueKey alapján | NOT DONE |
| ICG-07 | Meglévő modell | Storage compatibility | Nem kell új tábla; a meglévő `category_limits` rekord használható `transactionType=income` mellett | Repository/unit teszt | NOT DONE |
| ICG-08 | Scope boundary | Expense regression | Kiadási limit viselkedés, színek és `X maradt` felirat nem változik | Regression widget/unit teszt | NOT DONE |
| ICG-09 | User: "akkor legyen összbevételi cél" | Bevételi overview cél | A kiadási `Budget` bevételi párja `Összbevételi cél`, `targetType=overview`, `transactionType=income` | Widget/unit + code inspection | NOT DONE |
| ICG-10 | User: "nem kellmegtakarítás külön csak az amit mondtam" | Bevételi swipe lista | Bevételi oldalon nincs külön `Megtakarítás` cél; a lista `Összbevételi cél` + bevételi kategória célok | Widget teszt + code inspection | NOT DONE |

## Tesztelési Irány

Targetált tesztek:

- formatter/unit teszt a bevételi cél státuszszövegekre;
- `LimitManager` vagy új helper unit teszt `actualIncome / goal`, `missing`, `surplus`, `ringProgress` értékekre;
- unit/widget teszt az `Összbevételi cél` overview elemre;
- widget teszt a `backheader-center-remaining-amount` kulcsra bevételi kategóriával;
- widget teszt arra, hogy bevételi cél 100% felett nem kap kiadási piros danger színt;
- widget teszt arra, hogy bevételi oldalon nincs külön megtakarítási cél elem;
- regressziós teszt arra, hogy kiadási kategóriánál a jelenlegi limitlogika változatlan marad.

## Implementációs Döntés

A perzisztencia modell neve maradhat `CategoryLimit`, de az UI/domain rétegben be kell vezetni egy vékony szemantikai adaptert. A megvalósítás ne a meglévő `CategoryBudgetBarData.isOverLimit` és kiadási warning getterek újrahasznosításával döntse el a bevételi cél állapotát.

Kötelező döntés:

```text
BudgetTargetPresentation vagy IncomeCategoryGoalView
```

Ez a réteg választja szét:

- kiadási limit állapot: maradt / túllépve / warning / danger;
- bevételi cél állapot: hiányzik / cél megvan / plusz.

Ennek oka, hogy így kisebb az esélye annak, hogy később egy kiadási `isOverLimit` vagy warning szín véletlenül bevételi célra is lefusson.
