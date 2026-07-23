# Pulse Panel – teljes magyar feliratozás

## Cél

A `docs/prototypes/pulse_engine_panel_mockup.html` minden, embernek szóló felirata legyen érthető, köznyelvi magyar. A felület ne használjon angol chipet, angol állapotnevet vagy magyarázat nélküli technikai zsargont.

## Határ

Fordítandó:

- minden statikus cím, bekezdés, chip, gomb, vezérlőfelirat, diagramfelirat, táblázatfejléc, képaláírás, súgó és akadálymentesítési felirat;
- a JavaScriptből felépített panelek, forgatókönyvek és kártyák minden látható szövege;
- a megjelenített állapotok és a számításmagyarázatok.

Változatlan:

- a `Pulse` terméknév;
- HF-azonosítók, számok és pénznemek;
- HTML-, CSS- és JavaScript-azonosítók, osztálynevek, `data-*` attribútumok és függvénynevek, mert ezek belső működési részletek.

## Nyelvi szabályok

- A felirat a felhasználónak mondja el, mi történik; ne a belső rendszer nevét ismételje.
- Röviden, magyar mondatszerkezettel írjon: például „Megjelenik”, „Még vár”, „Kiválasztva”, „Nem jelenik meg”.
- Ha egy műszaki fogalom elkerülhetetlen, a köznyelvi jelentése szerepeljen helyette vagy mellette: „azonos helyzet”, „biztos adat”, „következő újraszámítás”.
- A pontszám magyarázata ugyanaz maradjon: csak az érvényes, kész és friss helyzetek hasonlíthatók össze; a legtöbb pontot kapó jelenik meg.

## Elfogadási feltételek

1. A teljes látható panel és minden dinamikus állapota magyar.
2. A chip- és állapotfeliratok köznyelviek, nem belső rendszerkifejezések.
3. A működő interakciók, forgatókönyv-váltás és nyitás/zárás nem sérülnek.
4. A most hozzáadott alsó PNG-flowchart érintetlen marad.
5. Egy automatikus ellenőrzés védi a kulcsfontosságú angol, embernek szóló feliratok visszakerülését.
