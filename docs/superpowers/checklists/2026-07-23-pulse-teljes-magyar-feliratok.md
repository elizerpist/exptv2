# Pulse Panel – teljes magyar feliratozás: elfogadási lista

| ID | Követelmény forrása | Terület | Elfogadási feltétel | Ellenőrzés | Állapot |
| --- | --- | --- | --- | --- | --- |
| PMF-001 | Felhasználó: „az összes idegen szót írd át magyarra” | Statikus HTML | Minden látható cím, leírás, gomb, chip és vezérlő magyar | Magyar felirat teszt + statikus látható-szöveg audit | DONE |
| PMF-002 | Felhasználó: „a chipeket” | Állapotchipek | Az állapotok köznyelvi magyar neveket kapnak | Állapot- és szerepkódok magyar megjelenítési leképezése + teszt | DONE |
| PMF-003 | Felhasználó: „összes technikai kifejezést” | Magyarázó folyamat és pontozás | A belső rendszerzsargon helyett érthető magyar magyarázat látható | Magyar folyamatábra- és pontozási szerződés tesztje | DONE |
| PMF-004 | Felhasználó: teljes HTML | JavaScriptből generált feliratok | Minden forgatókönyv és kibontott panel magyar szöveget jelenít meg | Dinamikus angol fordulatokat tiltó teszt + megjelenítési leképezések | DONE |
| PMF-005 | Meglévő Pulse működés | Interakciók | A fordítás nem töri meg a meglévő Pulse teszteket és a script elemzését | 5 Node teszt + beágyazott script elemzése | DONE |
| PMF-006 | Korábbi jóváhagyott PNG | Alsó flowchart | A PNG és a hozzá tartozó köznyelvi szöveg változatlanul elérhető | PNG teszt + HTML/PNG HTTP 200 | DONE |

## Végrehajtási bizonyíték

- A fordítási teszt először a „User score” látható angol felirat miatt hibázott, majd zöld lett.
- A rejtett, már nem használt régi felületet eltávolítottuk; nem volt hozzá működő JavaScript-hivatkozás.
- Sikeres végső futás: magyar felirat, PNG, szemantikus folyamat, döntési nyomvonal, csoportválasztó és beágyazott script.
