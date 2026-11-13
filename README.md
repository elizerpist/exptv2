# Fluvi R06 Human APK

[APK közvetlen letöltése](https://media.githubusercontent.com/media/elizerpist/exptv2/artifacts/r06-human-93161f4e/fluvi_HUMAN_DIAGNOSTIC_93161f4e_VM.apk)

A felhasználó kérésére fizikai telefonos teszteléshez kiadott **Human diagnosztikai APK**, helyben a VM-en fordítva, **profile** módban.

Forrás: `93161f4ea304a3fb18a7a4dc2336bdab678de4b1`.
Tartalom: az R06 késői steady-publikálás javítása és a `FluviOrbOwnership` diagnosztika. A buildben a demo, a fizikai és a képernyőn megjelenő diagnosztika engedélyezett; a build célja `human_diagnostic`.

**Ismert automatikus teszthiba:** a natív szolgáltatásmérés második ismétlése a 24. ciklusnál megállt. Az első ismétlés mind a 30 ciklust teljesítette. Mind az 50 alacsonyabb szintű Android-teszt (köztük a három új R06-regresszió), valamint a 7+7 segédteszt sikeres. A normál GitHub delivery workflow nem futott; ezt az APK-t a VM építette. Az automatikus hibát a fizikai teszteléshez történő kiadás nem minősíti sikeresnek.

Mérés: https://github.com/elizerpist/exptv2/actions/runs/43347794272
Részletes napló: https://github.com/elizerpist/exptv2/blob/7794203575a2886533809a46e885a503f9a2667a/docs/FLUVI_ENGINEERING_JOURNAL.md

Telefonos próba: ugyanazok az ORB-beállítások, hideg/meleg ébresztés, 10 lezárás/feloldás és 60 másodperc látható animáció. Tulajdonlási napló: `adb logcat -d -v threadtime -s FluviOrbOwnership:I`.

PHYSICAL VALIDATION — PENDING, USER ONLY.

APK mérete: 120,131,794 bájt. SHA256: `7b6cd9f216051559b45f8ea5ae7a78c72ffd59f38422bae4167554c0d5924673`. A ZIP-integritás, az APK-aláírás és a teljes forrásazonosító mindhárom ABI-ban ellenőrizve.

Az APK Git LFS-ben tárolt változatlan buildtermék; ez az ág nem módosítja az alkalmazás forráságát.
