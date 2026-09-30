# Balance Napi 4 – élő napi koordinátarendszer

## Források és hatókör

- Kötelező vizuális forrás: `html-prototypes/balance-extended-sheet-baseline/index.html`, a `Napi 4` képernyő (`.screen-wrap--napi-4`, `dailyMomentumNapi4CoordinateSvg`, `daily-impact-vertical-card`, `daily-momentum-rhythm-plot`).
- Referencia-screenshot: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260930-100144.png`.
- A koordináta-tér részletes vizuális referencia: `/storage/emulated/0/spendee/source of truth/kordinata.png`.
- Matematikai források: `docs/superpowers/specs/2026-09-30-balance-momentum-daily-design.md` és `docs/superpowers/specs/2026-09-30-daily-impact-design.md`.
- A fenti HTML az explicit source of truth: a Napi Balance belső child-cardok kompozíciója, távolságai, tipográfiája, színei, rajzolt formái és állapotai azzal azonosak. A külső Mother Card mérete változatlan marad.

## Elfogadási checklist

| ID | Követelmény forrása | Kódterület | Elfogadási feltétel | Ellenőrzés | Állapot |
| --- | --- | --- | --- | --- | --- |
| N4-01 | Napi 4 HTML / screenshot | `balance_dashboard_core_surface.dart` | A Day scope a közös meglévő extended-sheet Mother Cardon Card 3 + jobb oldali összevont Card 4/5 + alsó combined Card kompozíciót rajzolja. | Widget/boundary teszt és Napi 4 golden. | DONE |
| N4-02 | Napi 4 HTML source of truth | új napi card-renderer | A koordinátakártya a négy kvadránsos, rétegzett célfelületet, gyűrűket, tengelyeket, ikonokat, markert és calloutot kódból, bitmap nélkül, a HTML 500×400 logikai koordinátájával rajzolja. | Paint/widget teszt, ellenőrzött Napi 4 golden. | DONE |
| N4-03 | napi momentum spec §1–7 | új közös napi projection | A kiválasztott D napra Current=D−29…D és Reference=D−59…D−30 összesítő készül; bevétel változás felfelé, kiadás változás jobbra mutat; a kvadráns megnevezése a dokumentált előjelekből jön. | Determinisztikus domain teszt. | DONE |
| N4-04 | napi momentum spec §2 | új közös napi projection | Nyitott D napnál kizárólag a Current D és Reference D−30 terminális nap azonos logical-as-of percig számol; minden egyéb nap teljes. | Határidős domain teszt. | DONE |
| N4-05 | napi momentum spec §8–10 | új közös napi projection / ritmus renderer | A 60 napos ritmus ugyanazon 60 egymást követő napi 30×30 eredményből áll, mint amelyből a koordináta utolsó pontja készül; bal 30 lila, jobb 30 türkiz, Napi 4-ben nincs kiemelt utolsó cella. | Azonos mintapontokat ellenőrző domain/widget teszt. | DONE |
| N4-06 | napi momentum spec §8 | új közös napi projection | A tengely-normalizálás az összes megjelenített 60 eredményből, előjelmegőrzéssel jön; a renderer nem aggregál újra. | Domain teszt. | DONE |
| N4-07 | daily impact spec §1–7 | új közös napi projection | A Napi hatás kizárólag kiadásból számol: previous7=D−7…D−1, current7=D−6…D, `(previous7-current7)/previous7*100`; a nyitott D rögzített tranzakciói azonnal hatnak. | Domain teszt. | DONE |
| N4-08 | daily impact spec §8–12 | új közös napi projection / impact renderer | A skála csak impact(D−30)…impact(D−1) valid abszolút értékeinek p95-e, 5%-ra felfelé kerekítve, minimum ±10%; az aktuális hatás nem módosítja. A marker clampelhető, a valós százalék nem. | Domain teszt. | DONE |
| N4-09 | felhasználói kiegészítés | impact renderer | Negatív (romló) Napi hatásnál a százalék-pill korall/piros; pozitívnál a HTML zöld tónusa. | Widget teszt. | DONE |
| N4-10 | Napi 4 HTML source of truth | impact renderer | Az 5 szintes függőleges skála, cím, info-jel, szöveg, alsó két érték és CTA a HTML elrendezésével azonos. A `Mai nettó` és `Ref. átlag` tényleges napi nettó, illetve az előző 7 teljes nap átlagos napi nettója; ezek kontextusok, nem a hatás százalék bemenetei. | Widget/golden teszt. | DONE |
| N4-11 | napi specs §7, §13 | projection / UI | Hiányzó előzmény vagy nullás previous7 esetén nincs gyártott százalék vagy hamis grafikon; az app egyértelmű unavailable állapotot ad. | Domain és widget teszt. | DONE |
| N4-12 | architektúra gate | linked projection / alternative adapter | Egyetlen tiszta napi idősor-projection szolgálja ki a koordinátát, ritmust és Napi hatást; UI csak immutable presentationt renderel, repositoryt nem ér el. | Kódvizsgálat és boundary teszt. | DONE |
| N4-13 | user explicit | `BalanceExtendedSheetLayout` használat | Mother Card magasság, külső inset és közös Child geometria nem változik; nincs lila gyermekkeret. | Layout boundary és golden. | DONE |
| N4-14 | delivery | tesztek, commit, Actions | Célzott tesztek és analyze Ubuntu prootban zöldek; commit/push után a pontos SHA-hoz tartozó emberi APK letöltve `/storage/emulated/0/Download/fluvi` alá SHA-256-tal. | Parancskimenet, Actions, fájl-hash. | PARTIAL |

## Adatszerződés és matematika

### Egyetlen napi idősor

`DashboardBalanceDailyInsightsProjection` az income és expense resident ledger sorokból egyetlen epoch-day indexelt, immutable napi idősor-payloadot készít. Ez a közös domain core; a koordináta, az alsó ritmus és a Napi hatás nem számol külön UI-oldali aggregátumot.

Az új state nincs külön írható állapotban: a meglévő `DayScope` kiválasztott D dátuma az egyetlen választó. A dátumnavigációval minden D-re új, tényleges gördülő ablak épül.

### Koordináta és ritmus

Az adott D kiválasztott eredménye:

```text
currentIncome  = sum(income,  D-29..D)
referenceIncome = sum(income, D-59..D-30)
currentExpense = sum(expense, D-29..D)
referenceExpense = sum(expense, D-59..D-30)

incomeChange  = currentIncome - referenceIncome
expenseChange = currentExpense - referenceExpense
```

`incomeChange` a függőleges tengely: pozitív fölfelé. `expenseChange` a vízszintes tengely: pozitív jobbra. Kvadránsok:

```text
(income, -expense): Stabil építkezés
(income, +expense): Növekedés
(-income, -expense): Óvatosság szükséges
(-income, +expense): Figyelem szükséges
```

Nyitott D-nél a D és D−30 napok csak `logicalAsOfLocalTimeMinutes` időpontig érvényes sorokat tartalmazhatnak. A többi nap teljes napi összeggel megy. A 60 elemű ritmus D−59…D végpontokra készülő, ugyanilyen 30×30 eredmények időrendi listája. A koordinátakártya utolsó eleme szó szerint a ritmus utolsó eleme; nincs második aggregáció.

A marker tengelyértékei a 60 látható eredmény abszolút maximumából normalizálódnak, külön income és expense tengelyen, előjel- és nulla-megőrzéssel. A ritmusbar magassága ugyanezen eredmény normalizált kétdimenziós nagysága.

### Napi hatás

Ez szándékosan más mutató, és kizárólag kiadást használ:

```text
previous7 = sum(expense, D-7..D-1)
current7  = sum(expense, D-6..D)
dailyImpactPct = (previous7 - current7) / previous7 * 100
```

Pozitív érték javuló, negatív romló kiadási szint. A daily impact nyitott D-n nem alkalmaz egy perc-cuttoffot: minden addig rögzített D napi tranzakció közvetlenül hat.

A megjelenített vertikális skála kizárólag a D−30…D−1 végpontok érvényes daily impact értékeiből jön:

```text
rawExtent = p95(abs(historicalDailyImpacts))
extent = max(10, ceil(rawExtent / 5) * 5)
```

Az aktuális D nincs a p95-ben. Csak a marker pozíciója clampelhető a csőbe; a pillben és a szövegben a tényleges százalék látszik. `previous7 == 0` esetén unavailable állapot jelenik meg.

A source HTML két alsó szövegslotjának felirata változatlanul `Mai nettó` és `Ref. átlag`. Értékük valós, de nem a daily impact bemenete: `Mai nettó = income(D)-expense(D)`, `Ref. átlag = átlag(income-expense, D−7…D−1)`.

## Vizuális rögzítések

- A child felületek semleges `#e7ebf0` körvonalat használnak, soha nem lila child border-t.
- Koordináta: 500×400 HTML logikai vászon, 480×382 külső panel, rétegzett zöld/kék/piros háttérmezők, valós kétgyűrűs cél, tengelyek és marker; nem PNG, nem előrenderelt canvas asset.
- A jobb kártya egyetlen összevont téglalap a top-right két meglévő slotján. Az 5 skálajel: `+extent`, `+extent/2`, `0`, `-extent/2`, `-extent`.
- Alsó kártya: bal 30 lila, középen 2px lila osztó, jobb 30 türkiz; az Napi 4 prototípushoz hűen az utolsó cellán nincs selected outline.
- Minden cím, label és rajzolt elem a prototype source-pixel → Flutter logikai pixel konverziót használja a már közös `BalanceAlternativeHtmlTokens` tokenforrásból.
