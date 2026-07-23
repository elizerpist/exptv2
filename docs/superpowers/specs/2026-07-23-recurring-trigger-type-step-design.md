# Recurring Trigger Type — 0. lépés

## Cél

A Query-row Q3 bevételi tranzakciós sheetje és a Q4 Push-trigger `Alapadatok` képernyője közé kerüljön vissza a korábban eltávolított trigger-típus választó. Ez a wizard 0. lépése, nem számozza át a meglévő Q4–Q12 Push-trigger lépéseket.

## Jóváhagyott kialakítás

- A képernyő címe: `Q3A · Recurring wizard · Trigger típusa`.
- A külső azonosító: `data-screen="alt-recurring-trigger-type"`.
- A wizard-azonosító: `data-recurring-wizard-screen="trigger-type"` és `data-recurring-trigger-step="0"`.
- A képernyő Q3 és Q4 között jelenik meg: `Q1A → Q2 → Q3 → Q3A → Q4 → … → Q12 → Q13 → Q14 → Q15`.
- Pontosan egy, edge-to-edge `recurring-wizard-sheet` van benne. Ugyanazt a Q2 token-alapú geometriát használja, mint a kilenc Push-lépés: `height: var(--query-inline-category-sheet-h)` (`570px`), `left/right/bottom: 0`, `26px 26px 0 0` felső sarok.
- A sheet tartalma `0. lépés a 9-ből` jelöléssel két egyválasztós lehetőséget ad: `Push alapú` és `Idő alapú`.
- A Push alapú opció az alapértelmezett. A két opció a meglévő `data-recurring-wizard-choice-group` / `data-recurring-wizard-selectable` inicializálót használja, ezért kattintáskor csak a saját sheetjén változik a `selected` és az `aria-pressed` állapot.
- A `Tovább` CTA a statikus, egymás mellé tett prototípusban a Q4–Q12 Push-flow jelképes folytatását jelöli; nem épül vissza a korábbi négyképernyős időtrigger-ág és nem készül runtime router.
- Q4–Q12 változatlanul az 1–9 Push-trigger lépést jelentik. A zöld sikerpanel továbbra sem Query-row képernyő.

## Nem cél

- Nem számozzuk át Q4–Q12-t.
- Nem építünk külön időtrigger részfolyamatot.
- Nem módosítjuk Q2, Q3 vagy Q13–Q15 tartalmát.

## Elfogadási checklist

| ID | Forrás | Kódterület | Elfogadási feltétel | Ellenőrzés | Státusz |
| --- | --- | --- | --- | --- | --- |
| RTS-001 | User: `q4 és q3 közé kell egy screen` | `docs/prototypes/color_lab.html` Query-row markup | A Q3A egyszer, közvetlenül Q3 és Q4 között szerepel; a Query row 16 képernyőoszlopos. | Statikus sorrend-/darabszám-assertion és forrásvizsgálat. | DONE |
| RTS-002 | User: `egy ugyanilyen sheetet tartalmazó screen` | Recurring wizard markup/CSS | A Q3A pontosan egy Q2-geometriájú, 570px magas `recurring-wizard-sheet`-et tartalmaz, beágyazott sheet nélkül. | DOM/CSS assertion. | DONE |
| RTS-003 | User: `user választ, hogy push vagy időtrigger legyen` | Q3A markup + meglévő initializer | Két, egymást kizáró, hozzáférhető `Push alapú` / `Idő alapú` vezérlő van; Push az alapállapot; kattintás `selected` és `aria-pressed` állapotot szinkronizál. | Red–green statikus szerződés és izolált click smoke. | DONE |
| RTS-004 | User: `ez a 0. lépés` | Q3A markup és teszt | A Q3A `0. lépés a 9-ből` kijelzést és `data-recurring-trigger-step="0"` attribútumot kap; Q4–Q12 megőrzi `data-recurring-push-step="1"…"9"` értékeit. | Sorrend-/tartalom-assertion. | DONE |
| RTS-005 | Korábbi jóváhagyott Push wizard szerződés | Q4–Q12 markup és static test | A Q4–Q12 kilenc Push-lépése, egyedi sheetjei és a Q12 `Létrehozás` CTA változatlanul megmaradnak; az időtrigger-ágnak nincs rejtett fallback markupja. | Meglévő statikus teszt és célzott no-match keresés. | DONE |

## Ellenőrzési terv

Írjunk előbb hibázó statikus szerződést a Q3A-ra és a 16 oszlopos sorrendre. A forrásmódosítás után fusson a teljes Color Lab statikus teszt, az inline JavaScript-parse, egy izolált click smoke és `git diff --check`. A végső renderelt screenshot-összevetés külön, helyi böngészős rendererrel szükséges, ha elérhető.

## Megfigyelt ellenőrzési bizonyíték — 2026-07-23

- A hibázó static-test szerződés a hiányzó Q3A miatt `34 !== 35` eredménnyel bukott; a sheet beszúrása után `node docs/prototypes/color_lab_static_test.js` zöld lett.
- A statikus szerződés igazolja a 16 Query-row oszlopot, a Q3 → Q3A → Q4 sorrendet, a Q3A egyetlen Q2-inline sheetjét, a két triggeropciót és a 0. lépés progressz-sávját.
- Az inline script `new Function(...)` parse-on átment. Az izolált click smoke-ban az `Idő alapú` kiválasztása törölte a kezdetben kijelölt `Push alapú` vezérlő `selected` és `aria-pressed` állapotát.
- A végső szerkezeti ellenőrzés tíz recurring wizard shellt, pontosan egy `data-recurring-trigger-step="0"` markert, kilenc `data-recurring-push-step="1"`…`"9"` markert és nulla `data-recurring-push-step="0"` találatot igazolt.
- A futó Color Lab szerver HTTP smoke-ja a `http://127.0.0.1:4174/color_lab.html` útvonalon a Q3A markupot is elérte.
