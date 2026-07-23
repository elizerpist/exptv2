# Pulse – bemeneti adatok ellenőrzése: elfogadási lista

| ID | Követelmény forrása | Terület | Elfogadási feltétel | Ellenőrzés | Állapot |
| --- | --- | --- | --- | --- | --- |
| PAE-001 | Felhasználó: „erre súlyozott pontot adtál” | Pontozási folyamat | A `bizonytalan adat −20` nem szerepel sem képletben, sem magyarázatban; az adat állapota pontozás előtti ellenőrzés | Új adatellenőrzés-teszt + folyamatábra teszt | DONE |
| PAE-002 | Felhasználó: „egy matematikai műveletekre épülő app hogy adhat bizonytalan adatot” | Bemeneti szabályok | Hiányzó összeg, dátum és kategória külön, determinisztikus hatással szerepel | Új adatellenőrzés-teszt | DONE |
| PAE-003 | Jóváhagyott Pulse-prototípus: `docs/prototypes/pulse_engine_panel_mockup.html` | Hatókör | Kategóriahiány csak HF-002/HF-012/HF-020-at állít meg; teljes költés és pénzáramlás nem kap büntetést | Új adatellenőrzés-teszt + kézi forrásellenőrzés | DONE |
| PAE-004 | Jóváhagyott Pulse-prototípus | HF-021 | A HF-021 saját adatpontossági jel; nem módosítója pénzügyi jel pontszámának | Új adatellenőrzés-teszt + döntési nyomvonal teszt | DONE |
| PAE-005 | Felhasználó: tiszta működési magyarázat | Döntési nyomvonal és csoportfelület | Mindhárom döntési példa és az adatpontossági felület konkrét, magyar okot és következményt mutat | Célzott tesztek + kézi forrásellenőrzés | DONE |
| PAE-006 | Meglévő Pulse működés és PNG | Regresszió | A csoportválasztó, az alsó PNG, a dinamikus forgatókönyvek és a script működése sértetlen | Teljes Node-tesztkészlet + JavaScript elemzés + HTTP 200 | DONE |

## Végrehajtási bizonyíték

- Az új teszt először a régi „bizonytalan adat” feliratot találta meg, ezért a változtatás előtt a várt okból hibázott.
- A `pulse_data_input_rules_test.js` külön ellenőrzi a hiányzó összeg/dátum, a kategóriahiány és a HF-021 szabályát, valamint azt, hogy a Kockázat, Javulás és Adatpontosság példa is saját adatellenőrzést kap.
- A teljes Pulse-tesztkészlet, a beágyazott JavaScript elemzése és a HTML/PNG HTTP-ellenőrzése zöld.
- Független átvizsgálás: kritikus és fontos hibát nem talált; a mindhárom példát fedő tesztet a jelzett kisebb hiány alapján bővítettük.
