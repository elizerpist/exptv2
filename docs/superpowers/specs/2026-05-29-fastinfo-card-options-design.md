# FastInfo Card Options Redesign

## Goal

Redesign the FastInfo settings submenu into a live configuration surface for the header FastInfo area. The user can choose from a large pool of placeholder information cards and drop any card into any of the six FastInfo slots. The feature is about layout, selection, and interaction only; no card performs real transaction calculations in this phase.

## Current Context

FastInfo currently uses `FastInfoConfig` with three pill slots and three box slots. `FastInfoPanel` renders the real header FastInfo layout, but `TransactionHomePage` currently passes `FastInfoConfig.defaults()` directly. `FastInfoOptionsPanel` is a static settings list that shows slots and a short list of available elements without interaction.

## User Experience

The FastInfo settings submenu is split into two vertical halves:

1. Preview half: a live FastInfo preview that visually matches the real header FastInfo area above the header card. It has three pill slots and three box slots with the same spacing, rounded shapes, shadows, and empty-slot treatment as the real FastInfo layout.
2. Card pool half: a compact scrollable pool of draggable placeholder cards. The pool contains more cards than slots so the user can choose.

Every card can be dropped into any pill or box slot. Once a card is assigned to a slot, it disappears from the free card pool. Clearing a slot removes the card from the preview and returns it to the free card pool. Dropping onto an occupied slot replaces the previous card and returns the previous card to the pool.

Each change updates the FastInfo config immediately. The settings preview and the real header FastInfo should use the same config state, so changes made in settings are reflected in the real FastInfo without waiting for a restart.

## Card Rendering

Cards are not typed as pill-only or box-only. The slot type controls the rendering:

- Pill slot: render the card as a compact, fast-read value. It should show the shortest useful text, such as `184k`, `+12%`, `2 db`, or `OK`.
- Box slot: render the same card as a richer mini-card with title, value, subtitle or extra text, and an optional placeholder visual such as a progress bar, sparkline, status marker, ring, or mini bar chart.

The card definition should support at least:

- `id`
- `title`
- `pillValue`
- `boxValue`
- `boxSubtitle`
- `visualType`

The visual types are placeholders and may include `progress`, `sparkline`, `bar`, `ring`, `status`, `trend`, and `plain`.

## Placeholder Card Pool

The first implementation includes all proposed placeholder cards. They use static sample values only.

Kolteskontroll:
- Mai koltes
- Heti koltes
- Havi koltes
- Megtakaritas
- Egyenleg
- Havi limit allapot
- Koltesi trend
- Legutobbi tranzakcio
- Mai maradek keret
- Heti maradek keret
- Honapbol hatralevo napok
- Napi ajanlott maximum
- Mai koltes az ajanlott maxhoz kepest
- Havi keret egesi sebesseg
- Varhato ho vegi koltes
- Tulkoltes kockazat
- Leggyorsabban fogyo kategorialimit
- Limit feletti kategoriak szama

Tranzakciofigyeles:
- Utolso automatikusan rogzitett tranzakcio
- Utolso kezzel rogzitett tranzakcio
- Ma rogzitett tranzakciok szama
- Fuggoben levo feldolgozas
- Legutobbi push forrasapp
- Sikertelen parse-ok
- Ismeretlen kereskedok szama
- Uj kereskedo ma
- Leggyakoribb kereskedo
- Legdragabb kereskedo ebben a honapban

Szokas es trend:
- Atlagos napi koltes
- Hetvegi vs hetkoznapi koltes
- Mai nap az atlaghoz kepest
- Ez a het az elozo hethez kepest
- Ez a honap az elozo honaphoz kepest
- Kiadasi tempo
- Havi anomalia
- Szokatlan nagy tetel
- Sporolasi sorozat
- No-spend napok szama

Kategoria insight:
- Top kategoria ma
- Top kategoria heten
- Top kategoria honapban
- Legnagyobb novekedo kategoria
- Legjobban csokkeno kategoria
- Kategoria limit kozeleben
- Kategoria limit tullepve
- Ures vagy kategorizalatlan tranzakciok
- Kedvenc kategoria shortcut
- Kategoria, amire ma meg nem koltottel

Ismetlodo kiadasok:
- Kovetkezo ismetlodo kiadas
- Kovetkezo 7 nap fix kiadasai
- Mai esedekes fix kiadas
- Havi fix koltseg osszesen
- Fix koltseg aranya a havi keretbol
- Mar levont fix kiadasok
- Meg varhato fix kiadasok
- Elmaradt ismetlodo feldolgozas
- Legnagyobb fix kiadas
- Fix koltsegek utan marado keret

Cashflow es biztonsag:
- Biztonsagi tartalek
- Minimum egyenleg figyelmeztetes
- Keszpenz vs kartyas arany
- Bevetel ebben a honapban
- Kiadas/bevetel arany
- Netto havi cashflow
- Ho vegi becsult maradek
- Megtakaritasi cel haladas
- Havi megtakaritasi rata
- Puffer napok szama

Rendszer es adatminoseg:
- Figyelt app allapota
- Notification listener allapota
- Utolso sikeres szinkron
- Utolso backup
- Adatbazis sorok szama
- Hianyos tranzakciok
- Duplikatumgyanus tetelek
- Parse pontossag
- Import/export statusz
- Debug riasztasok

## Data Flow

The card pool is a static catalog in Flutter for now. `FastInfoConfig` should continue to serialize the six assigned slots through the native bridge. To keep compatibility, slot serialization can still store the resolved slot data, but assigned cards should use stable catalog IDs so future real data providers can replace placeholder values without changing saved configs.

The shell should own the active FastInfo config or otherwise share it between settings and the home header. `SettingsPage` needs a callback for FastInfo changes, similar to the existing theme callback. `TransactionHomePage` should receive the current config and pass it to `FastInfoPanel` instead of using `FastInfoConfig.defaults()`.

## Error Handling

If saving a changed FastInfo config fails, the settings UI should keep the local change visible during the interaction but expose the store error through existing settings error handling patterns. The MVP should avoid blocking drag and drop on transient save failures.

If a saved config references an unknown card ID, the slot should still render from serialized label/value fields when available. If no useful fields are available, render it as an empty slot.

## Tests

Add focused widget/model coverage for:

- card catalog contains more than six placeholder cards and all IDs are unique
- a card assigned to a slot is excluded from the free pool
- clearing a slot returns the card to the pool
- dropping onto an occupied slot replaces the slot and frees the previous card
- pill and box renderers display different information for the same card
- `TransactionHomePage` uses injected FastInfo config rather than defaults
- settings updates invoke the FastInfo update callback immediately

The Flutter toolchain currently fails in this Termux shell with a Dart TLS alignment error, so local test execution may need the known working Flutter environment.
