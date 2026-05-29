# FastInfo Card Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a draggable FastInfo options editor with a live six-slot preview, a large placeholder card pool, slot clearing, and shared settings/home FastInfo state.

**Architecture:** Add a static card catalog beside the FastInfo settings model, keep `FastInfoConfig` as the six-slot persistence contract, and make the existing `FastInfoPanel` render slot-specific pill and box designs from catalog IDs. Replace the static options list with a stateful drag-and-drop editor, then lift the active FastInfo config into `ExptShell` so settings changes affect the real header FastInfo immediately.

**Tech Stack:** Flutter/Dart widgets, `Draggable`/`DragTarget`, existing `NativeBridge` settings channel, existing Flutter widget tests.

---

## File Structure

- Create `lib/features/settings/models/fast_info_card_catalog.dart`: static placeholder card definitions, visual type enum, lookup helpers, default card IDs.
- Modify `lib/features/settings/models/fast_info_config.dart`: keep six-slot config, add catalog-aware slot construction and optional serialized render fields.
- Modify `lib/features/transactions/widgets/header_card/fast_info_panel.dart`: render catalog-aware pills/boxes, add optional drag target and clear controls for settings preview, keep the real header passive by default.
- Create `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`: small placeholder visual widgets for progress, sparkline, bar, ring, status, trend, and plain displays.
- Replace `lib/features/settings/widgets/options/fast_info_options_panel.dart`: stateful split-screen editor with preview half and draggable card pool half.
- Modify `lib/features/settings/settings_page.dart`: pass an `onFastInfoConfigChanged` callback and update FastInfo through `SettingsStore` immediately.
- Modify `lib/features/shell/expt_shell.dart`: own active `FastInfoConfig`, load it with settings, pass it to home and settings.
- Modify `lib/features/transactions/transaction_home_page.dart`: accept injected `FastInfoConfig` and pass it into `FastInfoPanel`.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`: align native default FastInfo IDs/fields with the new catalog while preserving generic map persistence.
- Add tests in `test/settings/fast_info_card_catalog_test.dart`, `test/settings/fast_info_options_panel_test.dart`, `test/settings/settings_page_test.dart`, and `test/transactions/fast_info_panel_test.dart`; adjust the header and settings tests named in Tasks 4 and 5.

### Task 1: Catalog Model And Serialization

**Files:**
- Create: `lib/features/settings/models/fast_info_card_catalog.dart`
- Modify: `lib/features/settings/models/fast_info_config.dart`
- Test: `test/settings/fast_info_card_catalog_test.dart`

- [ ] **Step 1: Write catalog and config tests**

Create `test/settings/fast_info_card_catalog_test.dart`:

```dart
import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains many unique selectable cards', () {
    expect(fastInfoCardCatalog.length, greaterThan(60));
    expect(fastInfoCardCatalog.map((card) => card.id).toSet().length, fastInfoCardCatalog.length);
    expect(fastInfoCardById('havi_koltes')?.title, 'Havi költés');
    expect(fastInfoCardById('debug_riasztasok')?.visualType, FastInfoVisualType.status);
  });

  test('slot created from a card keeps pill and box render data', () {
    final card = fastInfoCardById('havi_koltes')!;

    final pill = FastInfoSlot.fromCard(card, FastInfoSlotType.pill);
    final box = FastInfoSlot.fromCard(card, FastInfoSlotType.box);

    expect(pill.id, 'havi_koltes');
    expect(pill.type, FastInfoSlotType.pill);
    expect(pill.value, card.pillValue);
    expect(pill.boxValue, card.boxValue);
    expect(box.type, FastInfoSlotType.box);
    expect(box.value, card.boxValue);
    expect(box.pillValue, card.pillValue);
    expect(box.visualType, FastInfoVisualType.progress);
  });

  test('slot serializes and deserializes optional render fields', () {
    final slot = FastInfoSlot.fromCard(fastInfoCardById('koltesi_trend')!, FastInfoSlotType.box);
    final restored = FastInfoSlot.fromMap(slot.toMap());

    expect(restored.id, slot.id);
    expect(restored.label, slot.label);
    expect(restored.pillValue, slot.pillValue);
    expect(restored.boxValue, slot.boxValue);
    expect(restored.boxSubtitle, slot.boxSubtitle);
    expect(restored.visualType, slot.visualType);
    expect(restored.type, FastInfoSlotType.box);
  });

  test('defaults use catalog cards and preserve six fixed slots', () {
    final config = FastInfoConfig.defaults();

    expect(config.pills.length, 3);
    expect(config.boxes.length, 3);
    expect(config.pills[0]?.id, 'havi_koltes');
    expect(config.pills[1]?.id, 'mai_maradek_keret');
    expect(config.pills[2]?.id, 'koltesi_trend');
    expect(config.boxes[0]?.id, 'mai_koltes');
    expect(config.boxes[1]?.id, 'havi_limit_allapot');
    expect(config.boxes[2]?.id, 'kovetkezo_ismetlo_kiadas');
  });
}
```

- [ ] **Step 2: Run the new test and verify it fails**

Run:

```bash
flutter test test/settings/fast_info_card_catalog_test.dart
```

Expected: fails because `fast_info_card_catalog.dart`, `FastInfoVisualType`, `FastInfoSlot.fromCard`, and the new optional slot fields do not exist.

- [ ] **Step 3: Add the card catalog**

Create `lib/features/settings/models/fast_info_card_catalog.dart` with this structure and the full static pool:

```dart
import 'fast_info_config.dart';

enum FastInfoVisualType {
  progress('progress'),
  sparkline('sparkline'),
  bar('bar'),
  ring('ring'),
  status('status'),
  trend('trend'),
  plain('plain');

  const FastInfoVisualType(this.nativeValue);
  final String nativeValue;

  static FastInfoVisualType fromAny(Object? value) {
    return FastInfoVisualType.values.firstWhere(
      (type) => type.nativeValue == value?.toString(),
      orElse: () => FastInfoVisualType.plain,
    );
  }
}

class FastInfoCardDefinition {
  const FastInfoCardDefinition({
    required this.id,
    required this.title,
    required this.pillValue,
    required this.boxValue,
    required this.boxSubtitle,
    required this.visualType,
    this.progress,
  });

  final String id;
  final String title;
  final String pillValue;
  final String boxValue;
  final String boxSubtitle;
  final FastInfoVisualType visualType;
  final double? progress;
}

const defaultFastInfoPillCardIds = <String>[
  'havi_koltes',
  'mai_maradek_keret',
  'koltesi_trend',
];

const defaultFastInfoBoxCardIds = <String>[
  'mai_koltes',
  'havi_limit_allapot',
  'kovetkezo_ismetlo_kiadas',
];

const fastInfoCardCatalog = <FastInfoCardDefinition>[
  FastInfoCardDefinition(id: 'mai_koltes', title: 'Mai költés', pillValue: '4.5k', boxValue: '4 500 Ft', boxSubtitle: '2 tranzakció ma', visualType: FastInfoVisualType.bar, progress: 0.22),
  FastInfoCardDefinition(id: 'heti_koltes', title: 'Heti költés', pillValue: '38k', boxValue: '38 200 Ft', boxSubtitle: 'A heti keret 46%-a', visualType: FastInfoVisualType.progress, progress: 0.46),
  FastInfoCardDefinition(id: 'havi_koltes', title: 'Havi költés', pillValue: '184k', boxValue: '184k / 250k', boxSubtitle: 'A havi keret 74%-a', visualType: FastInfoVisualType.progress, progress: 0.74),
  FastInfoCardDefinition(id: 'megtakaritas', title: 'Megtakarítás', pillValue: '156k', boxValue: '156 780 Ft', boxSubtitle: 'Célhoz képest stabil', visualType: FastInfoVisualType.ring, progress: 0.62),
  FastInfoCardDefinition(id: 'egyenleg', title: 'Egyenleg', pillValue: '312k', boxValue: '312 400 Ft', boxSubtitle: 'Becsült aktuális egyenleg', visualType: FastInfoVisualType.plain),
  FastInfoCardDefinition(id: 'havi_limit_allapot', title: 'Havi limit állapot', pillValue: '74%', boxValue: '184k / 250k', boxSubtitle: '66k maradt', visualType: FastInfoVisualType.progress, progress: 0.74),
  FastInfoCardDefinition(id: 'koltesi_trend', title: 'Költési trend', pillValue: '+12%', boxValue: '+12%', boxSubtitle: 'Az előző időszakhoz képest', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'legutobbi_tranzakcio', title: 'Legutóbbi tranzakció', pillValue: '-2.1k', boxValue: '-2 100 Ft', boxSubtitle: 'Kávézó, 12:42', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'mai_maradek_keret', title: 'Mai maradék keret', pillValue: '8.5k', boxValue: '8 500 Ft', boxSubtitle: 'Mai ajánlott keretből', visualType: FastInfoVisualType.progress, progress: 0.68),
  FastInfoCardDefinition(id: 'heti_maradek_keret', title: 'Heti maradék keret', pillValue: '44k', boxValue: '44 800 Ft', boxSubtitle: 'Heti keret maradéka', visualType: FastInfoVisualType.progress, progress: 0.54),
  FastInfoCardDefinition(id: 'honapbol_hatralevo_napok', title: 'Hónapból hátralévő napok', pillValue: '9 nap', boxValue: '9 nap', boxSubtitle: 'A hónap végéig', visualType: FastInfoVisualType.ring, progress: 0.30),
  FastInfoCardDefinition(id: 'napi_ajanlott_maximum', title: 'Napi ajánlott maximum', pillValue: '7.3k', boxValue: '7 300 Ft', boxSubtitle: 'Becsült napi plafon', visualType: FastInfoVisualType.plain),
  FastInfoCardDefinition(id: 'mai_koltes_ajanlotthoz', title: 'Mai költés az ajánlott maxhoz képest', pillValue: '62%', boxValue: '4.5k / 7.3k', boxSubtitle: 'Mai ajánlott keret', visualType: FastInfoVisualType.progress, progress: 0.62),
  FastInfoCardDefinition(id: 'havi_keret_egesi_sebesseg', title: 'Havi keret égési sebesség', pillValue: 'gyors', boxValue: 'Gyors tempó', boxSubtitle: 'A keret a vártnál gyorsabban fogy', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'varhato_ho_vegi_koltes', title: 'Várható hó végi költés', pillValue: '271k', boxValue: '271 000 Ft', boxSubtitle: 'Becsült hó végi összeg', visualType: FastInfoVisualType.sparkline),
  FastInfoCardDefinition(id: 'tulkoltes_kockazat', title: 'Túlköltés kockázat', pillValue: 'közepes', boxValue: 'Közepes', boxSubtitle: 'Figyeld a napi tempót', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'leggyorsabban_fogyo_kategorialimit', title: 'Leggyorsabban fogyó kategórialimit', pillValue: 'Étel', boxValue: 'Étel 88%', boxSubtitle: 'A limit közelében', visualType: FastInfoVisualType.progress, progress: 0.88),
  FastInfoCardDefinition(id: 'limit_feletti_kategoriak_szama', title: 'Limit feletti kategóriák száma', pillValue: '1 db', boxValue: '1 kategória', boxSubtitle: 'Limit felett', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_auto_tranzakcio', title: 'Utolsó automatikusan rögzített tranzakció', pillValue: '-990', boxValue: '-990 Ft', boxSubtitle: 'Automatikus rögzítés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_kezi_tranzakcio', title: 'Utolsó kézzel rögzített tranzakció', pillValue: '-3.2k', boxValue: '-3 200 Ft', boxSubtitle: 'Kézi rögzítés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'ma_rogzitett_tranzakciok_szama', title: 'Ma rögzített tranzakciók száma', pillValue: '5 db', boxValue: '5 tranzakció', boxSubtitle: 'Mai aktivitás', visualType: FastInfoVisualType.bar, progress: 0.50),
  FastInfoCardDefinition(id: 'fuggoben_levo_feldolgozas', title: 'Függőben lévő feldolgozás', pillValue: '0', boxValue: '0 függőben', boxSubtitle: 'Nincs várakozó elem', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'legutobbi_push_forrasapp', title: 'Legutóbbi push forrásapp', pillValue: 'Bank', boxValue: 'Bank app', boxSubtitle: 'Utolsó értesítés forrása', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'sikertelen_parse_ok', title: 'Sikertelen parse-ok', pillValue: '2', boxValue: '2 sikertelen', boxSubtitle: 'Ellenőrzést igényel', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'ismeretlen_kereskedok_szama', title: 'Ismeretlen kereskedők száma', pillValue: '3', boxValue: '3 új név', boxSubtitle: 'Kategorizálásra vár', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'uj_kereskedo_ma', title: 'Új kereskedő ma', pillValue: '1', boxValue: '1 új kereskedő', boxSubtitle: 'Ma először láttuk', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'leggyakoribb_kereskedo', title: 'Leggyakoribb kereskedő', pillValue: 'ABC', boxValue: 'ABC Market', boxSubtitle: 'Legtöbb tranzakció', visualType: FastInfoVisualType.bar, progress: 0.70),
  FastInfoCardDefinition(id: 'legdragabb_kereskedo_honapban', title: 'Legdrágább kereskedő ebben a hónapban', pillValue: 'Bérlet', boxValue: 'Bérlet', boxSubtitle: 'Legnagyobb havi összeg', visualType: FastInfoVisualType.bar, progress: 0.82),
  FastInfoCardDefinition(id: 'atlagos_napi_koltes', title: 'Átlagos napi költés', pillValue: '8.1k', boxValue: '8 100 Ft', boxSubtitle: 'Napi átlag', visualType: FastInfoVisualType.sparkline),
  FastInfoCardDefinition(id: 'hetvegi_vs_hetkoznapi_koltes', title: 'Hétvégi vs hétköznapi költés', pillValue: '34/66', boxValue: '34% / 66%', boxSubtitle: 'Hétvége és hétköznap', visualType: FastInfoVisualType.bar),
  FastInfoCardDefinition(id: 'mai_nap_atlaghoz_kepest', title: 'Mai nap az átlaghoz képest', pillValue: '-18%', boxValue: '-18%', boxSubtitle: 'Ma az átlag alatt', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'ez_a_het_elozo_hethez', title: 'Ez a hét az előző héthez képest', pillValue: '+6%', boxValue: '+6%', boxSubtitle: 'Heti összevetés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'ez_a_honap_elozo_honaphoz', title: 'Ez a hónap az előző hónaphoz képest', pillValue: '-4%', boxValue: '-4%', boxSubtitle: 'Havi összevetés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'kiadasi_tempo', title: 'Kiadási tempó', pillValue: 'normál', boxValue: 'Normál tempó', boxSubtitle: 'A kerethez igazodik', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'havi_anomalia', title: 'Havi anomália', pillValue: 'nincs', boxValue: 'Nincs anomália', boxSubtitle: 'Szokásos mintázat', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'szokatlan_nagy_tetel', title: 'Szokatlan nagy tétel', pillValue: '1', boxValue: '1 nagy tétel', boxSubtitle: 'Ellenőrizhető tranzakció', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'sporolasi_sorozat', title: 'Spórolási sorozat', pillValue: '4 nap', boxValue: '4 nap', boxSubtitle: 'Átlag alatti költés', visualType: FastInfoVisualType.ring, progress: 0.57),
  FastInfoCardDefinition(id: 'no_spend_napok_szama', title: 'No-spend napok száma', pillValue: '3 nap', boxValue: '3 nap', boxSubtitle: 'Költés nélküli napok', visualType: FastInfoVisualType.ring, progress: 0.43),
  FastInfoCardDefinition(id: 'top_kategoria_ma', title: 'Top kategória ma', pillValue: 'Étel', boxValue: 'Étel', boxSubtitle: 'Mai legnagyobb kategória', visualType: FastInfoVisualType.bar, progress: 0.61),
  FastInfoCardDefinition(id: 'top_kategoria_heten', title: 'Top kategória héten', pillValue: 'Bolt', boxValue: 'Bolt', boxSubtitle: 'Heti legnagyobb kategória', visualType: FastInfoVisualType.bar, progress: 0.55),
  FastInfoCardDefinition(id: 'top_kategoria_honapban', title: 'Top kategória hónapban', pillValue: 'Lakhatás', boxValue: 'Lakhatás', boxSubtitle: 'Havi legnagyobb kategória', visualType: FastInfoVisualType.bar, progress: 0.80),
  FastInfoCardDefinition(id: 'legnagyobb_novekedo_kategoria', title: 'Legnagyobb növekedő kategória', pillValue: 'Utazás', boxValue: 'Utazás +22%', boxSubtitle: 'Legnagyobb növekedés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'legjobban_csokkeno_kategoria', title: 'Legjobban csökkenő kategória', pillValue: 'Kávé', boxValue: 'Kávé -15%', boxSubtitle: 'Legnagyobb csökkenés', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'kategoria_limit_kozeleben', title: 'Kategória limit közelében', pillValue: '2 db', boxValue: '2 kategória', boxSubtitle: 'Limit közelében', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kategoria_limit_tullepve', title: 'Kategória limit túllépve', pillValue: '1 db', boxValue: '1 kategória', boxSubtitle: 'Limit felett', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'ures_vagy_kategorizalatlan_tranzakciok', title: 'Üres vagy kategorizálatlan tranzakciók', pillValue: '4 db', boxValue: '4 tranzakció', boxSubtitle: 'Kategóriára vár', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kedvenc_kategoria_shortcut', title: 'Kedvenc kategória shortcut', pillValue: 'Étel', boxValue: 'Étel', boxSubtitle: 'Gyakran használt kategória', visualType: FastInfoVisualType.plain),
  FastInfoCardDefinition(id: 'kategoria_amire_ma_meg_nem_koltottel', title: 'Kategória, amire ma még nem költöttél', pillValue: 'Hobbi', boxValue: 'Hobbi', boxSubtitle: 'Ma még nincs költés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kovetkezo_ismetlo_kiadas', title: 'Következő ismétlődő kiadás', pillValue: 'Lakbér', boxValue: 'Lakbér', boxSubtitle: '3 nap múlva', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'kovetkezo_7_nap_fix_kiadasai', title: 'Következő 7 nap fix kiadásai', pillValue: '42k', boxValue: '42 000 Ft', boxSubtitle: '7 napon belül', visualType: FastInfoVisualType.bar, progress: 0.42),
  FastInfoCardDefinition(id: 'mai_esedekes_fix_kiadas', title: 'Mai esedékes fix kiadás', pillValue: '0', boxValue: 'Nincs ma', boxSubtitle: 'Ma nincs esedékes fix tétel', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'havi_fix_koltseg_osszesen', title: 'Havi fix költség összesen', pillValue: '121k', boxValue: '121 000 Ft', boxSubtitle: 'Fix havi tételek', visualType: FastInfoVisualType.ring, progress: 0.48),
  FastInfoCardDefinition(id: 'fix_koltseg_aranya_havi_keretbol', title: 'Fix költség aránya a havi keretből', pillValue: '48%', boxValue: '48%', boxSubtitle: 'Havi keretből', visualType: FastInfoVisualType.progress, progress: 0.48),
  FastInfoCardDefinition(id: 'mar_levont_fix_kiadasok', title: 'Már levont fix kiadások', pillValue: '79k', boxValue: '79 000 Ft', boxSubtitle: 'Már teljesült fix tételek', visualType: FastInfoVisualType.progress, progress: 0.65),
  FastInfoCardDefinition(id: 'meg_varhato_fix_kiadasok', title: 'Még várható fix kiadások', pillValue: '42k', boxValue: '42 000 Ft', boxSubtitle: 'Hátralévő fix tételek', visualType: FastInfoVisualType.progress, progress: 0.35),
  FastInfoCardDefinition(id: 'elmaradt_ismetlo_feldolgozas', title: 'Elmaradt ismétlődő feldolgozás', pillValue: '0', boxValue: 'Nincs elmaradás', boxSubtitle: 'Minden naprakész', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'legnagyobb_fix_kiadas', title: 'Legnagyobb fix kiadás', pillValue: 'Lakbér', boxValue: 'Lakbér', boxSubtitle: 'Legnagyobb fix tétel', visualType: FastInfoVisualType.bar, progress: 0.78),
  FastInfoCardDefinition(id: 'fix_koltsegek_utan_marado_keret', title: 'Fix költségek után maradó keret', pillValue: '129k', boxValue: '129 000 Ft', boxSubtitle: 'Fix tételek után', visualType: FastInfoVisualType.progress, progress: 0.52),
  FastInfoCardDefinition(id: 'biztonsagi_tartalek', title: 'Biztonsági tartalék', pillValue: '92k', boxValue: '92 000 Ft', boxSubtitle: 'Becsült puffer', visualType: FastInfoVisualType.ring, progress: 0.61),
  FastInfoCardDefinition(id: 'minimum_egyenleg_figyelmeztetes', title: 'Minimum egyenleg figyelmeztetés', pillValue: 'OK', boxValue: 'OK', boxSubtitle: 'Minimum felett', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'keszpenz_vs_kartyas_arany', title: 'Készpénz vs kártyás arány', pillValue: '12/88', boxValue: '12% / 88%', boxSubtitle: 'Készpénz és kártya', visualType: FastInfoVisualType.bar),
  FastInfoCardDefinition(id: 'bevetel_ebben_a_honapban', title: 'Bevétel ebben a hónapban', pillValue: '420k', boxValue: '420 000 Ft', boxSubtitle: 'Havi bevétel', visualType: FastInfoVisualType.bar, progress: 0.84),
  FastInfoCardDefinition(id: 'kiadas_bevetel_arany', title: 'Kiadás/bevétel arány', pillValue: '44%', boxValue: '44%', boxSubtitle: 'Kiadás a bevételhez képest', visualType: FastInfoVisualType.progress, progress: 0.44),
  FastInfoCardDefinition(id: 'netto_havi_cashflow', title: 'Nettó havi cashflow', pillValue: '+236k', boxValue: '+236 000 Ft', boxSubtitle: 'Bevétel mínusz kiadás', visualType: FastInfoVisualType.trend),
  FastInfoCardDefinition(id: 'ho_vegi_becsult_maradek', title: 'Hó végi becsült maradék', pillValue: '149k', boxValue: '149 000 Ft', boxSubtitle: 'Becsült maradék', visualType: FastInfoVisualType.sparkline),
  FastInfoCardDefinition(id: 'megtakaritasi_cel_haladas', title: 'Megtakarítási cél haladás', pillValue: '62%', boxValue: '62%', boxSubtitle: 'Cél teljesülése', visualType: FastInfoVisualType.ring, progress: 0.62),
  FastInfoCardDefinition(id: 'havi_megtakaritasi_rata', title: 'Havi megtakarítási ráta', pillValue: '21%', boxValue: '21%', boxSubtitle: 'Bevételhez képest', visualType: FastInfoVisualType.progress, progress: 0.21),
  FastInfoCardDefinition(id: 'puffer_napok_szama', title: 'Puffer napok száma', pillValue: '11 nap', boxValue: '11 nap', boxSubtitle: 'Tartalék becslés', visualType: FastInfoVisualType.ring, progress: 0.37),
  FastInfoCardDefinition(id: 'figyelt_app_allapota', title: 'Figyelt app állapota', pillValue: 'aktív', boxValue: 'Aktív', boxSubtitle: 'App figyelés bekapcsolva', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'notification_listener_allapota', title: 'Notification listener állapota', pillValue: 'OK', boxValue: 'OK', boxSubtitle: 'Értesítésfigyelő aktív', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_sikeres_szinkron', title: 'Utolsó sikeres szinkron', pillValue: '12:40', boxValue: '12:40', boxSubtitle: 'Legutóbbi sikeres frissítés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'utolso_backup', title: 'Utolsó backup', pillValue: 'tegnap', boxValue: 'Tegnap', boxSubtitle: 'Biztonsági mentés', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'adatbazis_sorok_szama', title: 'Adatbázis sorok száma', pillValue: '1.2k', boxValue: '1 240 sor', boxSubtitle: 'Lokális adatbázis', visualType: FastInfoVisualType.bar, progress: 0.40),
  FastInfoCardDefinition(id: 'hianyos_tranzakciok', title: 'Hiányos tranzakciók', pillValue: '3', boxValue: '3 hiányos', boxSubtitle: 'Ellenőrzést igényel', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'duplikatumgyanus_tetelek', title: 'Duplikátumgyanús tételek', pillValue: '2', boxValue: '2 gyanús', boxSubtitle: 'Lehetséges duplikátumok', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'parse_pontossag', title: 'Parse pontosság', pillValue: '96%', boxValue: '96%', boxSubtitle: 'Becsült feldolgozási arány', visualType: FastInfoVisualType.progress, progress: 0.96),
  FastInfoCardDefinition(id: 'import_export_statusz', title: 'Import/export státusz', pillValue: 'OK', boxValue: 'OK', boxSubtitle: 'Nincs folyamatban lévő művelet', visualType: FastInfoVisualType.status),
  FastInfoCardDefinition(id: 'debug_riasztasok', title: 'Debug riasztások', pillValue: '0', boxValue: '0 riasztás', boxSubtitle: 'Nincs aktív debug jelzés', visualType: FastInfoVisualType.status),
];

FastInfoCardDefinition? fastInfoCardById(String id) {
  for (final card in fastInfoCardCatalog) {
    if (card.id == id) return card;
  }
  return null;
}
```

- [ ] **Step 4: Extend `FastInfoSlot` and defaults**

Modify `lib/features/settings/models/fast_info_config.dart` so it imports the catalog and preserves optional render fields:

```dart
import 'fast_info_card_catalog.dart';
```

Update `FastInfoSlot` with these fields and factories:

```dart
class FastInfoSlot {
  const FastInfoSlot({
    required this.id,
    required this.label,
    required this.value,
    required this.type,
    this.extra,
    this.progress,
    this.pillValue,
    this.boxValue,
    this.boxSubtitle,
    this.visualType = FastInfoVisualType.plain,
  });

  factory FastInfoSlot.fromCard(
    FastInfoCardDefinition card,
    FastInfoSlotType type,
  ) {
    return FastInfoSlot(
      id: card.id,
      label: card.title,
      value: type == FastInfoSlotType.pill ? card.pillValue : card.boxValue,
      type: type,
      extra: card.boxSubtitle,
      progress: card.progress,
      pillValue: card.pillValue,
      boxValue: card.boxValue,
      boxSubtitle: card.boxSubtitle,
      visualType: card.visualType,
    );
  }

  factory FastInfoSlot.fromMap(Map<dynamic, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final catalogCard = fastInfoCardById(id);
    final type = FastInfoSlotType.fromAny(map['type']);
    if (catalogCard != null) {
      final catalogSlot = FastInfoSlot.fromCard(catalogCard, type);
      return FastInfoSlot(
        id: id,
        label: map['label']?.toString() ?? catalogSlot.label,
        value: map['value']?.toString() ?? catalogSlot.value,
        extra: map['extra']?.toString() ?? catalogSlot.extra,
        progress: _double(map['progress']) ?? catalogSlot.progress,
        type: type,
        pillValue: map['pillValue']?.toString() ?? catalogSlot.pillValue,
        boxValue: map['boxValue']?.toString() ?? catalogSlot.boxValue,
        boxSubtitle: map['boxSubtitle']?.toString() ?? catalogSlot.boxSubtitle,
        visualType: FastInfoVisualType.fromAny(map['visualType'] ?? catalogSlot.visualType.nativeValue),
      );
    }
    return FastInfoSlot(
      id: id,
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
      extra: map['extra']?.toString(),
      progress: _double(map['progress']),
      type: type,
      pillValue: map['pillValue']?.toString(),
      boxValue: map['boxValue']?.toString(),
      boxSubtitle: map['boxSubtitle']?.toString(),
      visualType: FastInfoVisualType.fromAny(map['visualType']),
    );
  }

  final String id;
  final String label;
  final String value;
  final String? extra;
  final double? progress;
  final FastInfoSlotType type;
  final String? pillValue;
  final String? boxValue;
  final String? boxSubtitle;
  final FastInfoVisualType visualType;

  FastInfoSlot asType(FastInfoSlotType nextType) {
    final card = fastInfoCardById(id);
    if (card != null) return FastInfoSlot.fromCard(card, nextType);
    return FastInfoSlot(
      id: id,
      label: label,
      value: nextType == FastInfoSlotType.pill
          ? (pillValue ?? value)
          : (boxValue ?? value),
      extra: boxSubtitle ?? extra,
      progress: progress,
      type: nextType,
      pillValue: pillValue,
      boxValue: boxValue,
      boxSubtitle: boxSubtitle,
      visualType: visualType,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'value': value,
      if (extra != null) 'extra': extra,
      if (progress != null) 'progress': progress,
      'type': type.nativeValue,
      if (pillValue != null) 'pillValue': pillValue,
      if (boxValue != null) 'boxValue': boxValue,
      if (boxSubtitle != null) 'boxSubtitle': boxSubtitle,
      'visualType': visualType.nativeValue,
    };
  }
}
```

Update `FastInfoConfig.defaults()` to build from catalog IDs:

```dart
factory FastInfoConfig.defaults() {
  return FastInfoConfig(
    pills: defaultFastInfoPillCardIds
        .map((id) => FastInfoSlot.fromCard(fastInfoCardById(id)!, FastInfoSlotType.pill))
        .toList(),
    boxes: defaultFastInfoBoxCardIds
        .map((id) => FastInfoSlot.fromCard(fastInfoCardById(id)!, FastInfoSlotType.box))
        .toList(),
  );
}
```

- [ ] **Step 5: Run the catalog test**

Run:

```bash
flutter test test/settings/fast_info_card_catalog_test.dart
```

Expected: all four tests pass.

- [ ] **Step 6: Commit catalog work**

```bash
git add lib/features/settings/models/fast_info_card_catalog.dart lib/features/settings/models/fast_info_config.dart test/settings/fast_info_card_catalog_test.dart
git commit -m "feat: add fastinfo card catalog"
```

### Task 2: Slot-Specific FastInfo Rendering

**Files:**
- Create: `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
- Test: `test/transactions/fast_info_panel_test.dart`

- [ ] **Step 1: Write rendering tests**

Create `test/transactions/fast_info_panel_test.dart`:

```dart
import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/transactions/widgets/header_card/fast_info_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('same card renders compact value in pill and richer content in box', (tester) async {
    final card = fastInfoCardById('havi_koltes')!;
    final config = FastInfoConfig(
      pills: [FastInfoSlot.fromCard(card, FastInfoSlotType.pill), null, null],
      boxes: [FastInfoSlot.fromCard(card, FastInfoSlotType.box), null, null],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FastInfoPanel(config: config)),
      ),
    );

    expect(find.text('184k'), findsOneWidget);
    expect(find.text('Havi költés'), findsOneWidget);
    expect(find.text('184k / 250k'), findsOneWidget);
    expect(find.text('A havi keret 74%-a'), findsOneWidget);
    expect(find.byKey(const ValueKey('fastinfo-visual-progress-havi_koltes')), findsOneWidget);
  });

  testWidgets('clear buttons are shown only when callbacks are provided', (tester) async {
    final config = FastInfoConfig.defaults();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FastInfoPanel(config: config))),
    );
    expect(find.byKey(const ValueKey('fastinfo-clear-pill-0')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: config,
            onClearPillSlot: (_) {},
            onClearBoxSlot: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('fastinfo-clear-pill-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('fastinfo-clear-box-0')), findsOneWidget);
  });

  testWidgets('drag target callback receives dropped card id', (tester) async {
    String? dropped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FastInfoPanel(
                config: FastInfoConfig(pills: const [null, null, null], boxes: const [null, null, null]),
                onDropPillCard: (index, cardId) => dropped = '$index:$cardId',
              ),
              Positioned(
                left: 24,
                top: 260,
                child: Draggable<String>(
                  data: 'mai_koltes',
                  feedback: const Material(child: Text('Mai költés')),
                  child: const SizedBox(width: 80, height: 40, child: Text('Drag')),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.text('Drag'), const Offset(80, -180));
    await tester.pumpAndSettle();

    expect(dropped, '0:mai_koltes');
  });
}
```

- [ ] **Step 2: Run rendering tests and verify failure**

Run:

```bash
flutter test test/transactions/fast_info_panel_test.dart
```

Expected: fails because clear/drop callbacks and visual widgets do not exist yet.

- [ ] **Step 3: Create visual widgets**

Create `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/fast_info_card_catalog.dart';
import '../../../settings/models/fast_info_config.dart';

class FastInfoVisual extends StatelessWidget {
  const FastInfoVisual({super.key, required this.slot});

  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return switch (slot.visualType) {
      FastInfoVisualType.progress => _ProgressVisual(slot: slot),
      FastInfoVisualType.sparkline => _SparklineVisual(slot: slot),
      FastInfoVisualType.bar => _BarVisual(slot: slot),
      FastInfoVisualType.ring => _RingVisual(slot: slot),
      FastInfoVisualType.status => _StatusVisual(slot: slot),
      FastInfoVisualType.trend => _TrendVisual(slot: slot),
      FastInfoVisualType.plain => const SizedBox.shrink(),
    };
  }
}

class _ProgressVisual extends StatelessWidget {
  const _ProgressVisual({required this.slot});
  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: ValueKey('fastinfo-visual-progress-${slot.id}'),
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 5,
        value: (slot.progress ?? 0.45).clamp(0.0, 1.0),
        backgroundColor: AppColors.gray200,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

class _SparklineVisual extends StatelessWidget {
  const _SparklineVisual({required this.slot});
  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('fastinfo-visual-sparkline-${slot.id}'),
      height: 16,
      child: CustomPaint(painter: _SparklinePainter()),
    );
  }
}

class _BarVisual extends StatelessWidget {
  const _BarVisual({required this.slot});
  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    final value = (slot.progress ?? 0.5).clamp(0.0, 1.0);
    return Row(
      key: ValueKey('fastinfo-visual-bar-${slot.id}'),
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            height: 6 + index * 2,
            margin: EdgeInsets.only(right: index == 4 ? 0 : 2),
            decoration: BoxDecoration(
              color: index / 5 <= value ? AppColors.primary : AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _RingVisual extends StatelessWidget {
  const _RingVisual({required this.slot});
  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return Align(
      key: ValueKey('fastinfo-visual-ring-${slot.id}'),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          value: (slot.progress ?? 0.5).clamp(0.0, 1.0),
          backgroundColor: AppColors.gray200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _StatusVisual extends StatelessWidget {
  const _StatusVisual({required this.slot});
  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return Align(
      key: ValueKey('fastinfo-visual-status-${slot.id}'),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      ),
    );
  }
}

class _TrendVisual extends StatelessWidget {
  const _TrendVisual({required this.slot});
  final FastInfoSlot slot;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey('fastinfo-visual-trend-${slot.id}'),
      children: const [
        Icon(Icons.trending_up, size: 16, color: AppColors.primary),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.25, size.height * 0.45)
      ..lineTo(size.width * 0.50, size.height * 0.62)
      ..lineTo(size.width * 0.75, size.height * 0.25)
      ..lineTo(size.width, size.height * 0.35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **Step 4: Modify `FastInfoPanel` for slot-specific render and optional editing hooks**

Update the `FastInfoPanel` constructor to include optional callbacks:

```dart
typedef FastInfoCardDropCallback = void Function(int index, String cardId);

class FastInfoPanel extends StatelessWidget {
  const FastInfoPanel({
    super.key,
    required this.config,
    this.backgroundColor = AppColors.gray100,
    this.onDropPillCard,
    this.onDropBoxCard,
    this.onClearPillSlot,
    this.onClearBoxSlot,
  });

  final FastInfoConfig config;
  final Color backgroundColor;
  final FastInfoCardDropCallback? onDropPillCard;
  final FastInfoCardDropCallback? onDropBoxCard;
  final ValueChanged<int>? onClearPillSlot;
  final ValueChanged<int>? onClearBoxSlot;
}
```

Inside the three pill and box loops, pass callbacks to `_FastInfoPill` and `_FastInfoBox`, and give slots stable keys:

```dart
_FastInfoPill(
  slot: config.pills[i],
  index: i,
  onDropCard: onDropPillCard,
  onClear: onClearPillSlot,
)

_FastInfoBox(
  slot: config.boxes[i],
  index: i,
  onDropCard: onDropBoxCard,
  onClear: onClearBoxSlot,
)
```

Add a private wrapper method to each slot widget:

```dart
Widget _wrapDropTarget(Widget child) {
  if (onDropCard == null) return child;
  return DragTarget<String>(
    key: ValueKey('fastinfo-pill-drop-$index'),
    onAcceptWithDetails: (details) => onDropCard!(index, details.data),
    builder: (context, candidateData, rejectedData) {
      return AnimatedScale(
        scale: candidateData.isEmpty ? 1 : 1.03,
        duration: const Duration(milliseconds: 120),
        child: child,
      );
    },
  );
}
```

Use `ValueKey('fastinfo-box-drop-$index')` in the box wrapper. Render pill content as `slot?.pillValue ?? slot?.value`, render box content as `slot?.boxValue ?? slot?.value`, `slot?.boxSubtitle ?? slot?.extra`, and include `FastInfoVisual(slot: slot!)` when slot is non-null.

- [ ] **Step 5: Run rendering tests**

Run:

```bash
flutter test test/transactions/fast_info_panel_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit rendering work**

```bash
git add lib/features/transactions/widgets/header_card/fast_info_panel.dart lib/features/transactions/widgets/header_card/fast_info_visuals.dart test/transactions/fast_info_panel_test.dart
git commit -m "feat: render fastinfo cards by slot type"
```

### Task 3: Drag-And-Drop FastInfo Options Panel

**Files:**
- Modify: `lib/features/settings/widgets/options/fast_info_options_panel.dart`
- Test: `test/settings/fast_info_options_panel_test.dart`

- [ ] **Step 1: Write options panel interaction tests**

Create `test/settings/fast_info_options_panel_test.dart`:

```dart
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/settings/widgets/options/fast_info_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('assigned cards disappear from pool and clear returns them', (tester) async {
    FastInfoConfig? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: FastInfoOptionsPanel(
              config: FastInfoConfig(pills: const [null, null, null], boxes: const [null, null, null]),
              onChanged: (config) => changed = config,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')),
      const Offset(0, -330),
    );
    await tester.pumpAndSettle();

    expect(changed?.pills[0]?.id, 'mai_koltes');
    expect(find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('fastinfo-clear-pill-0')));
    await tester.pumpAndSettle();

    expect(changed?.pills[0], isNull);
    expect(find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')), findsOneWidget);
  });

  testWidgets('dropping onto occupied slot replaces old card and returns old card to pool', (tester) async {
    FastInfoConfig? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: FastInfoOptionsPanel(
              config: FastInfoConfig(pills: const [null, null, null], boxes: const [null, null, null]),
              onChanged: (config) => changed = config,
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')), const Offset(0, -330));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('fastinfo-pool-card-havi_koltes')), const Offset(0, -330));
    await tester.pumpAndSettle();

    expect(changed?.pills[0]?.id, 'havi_koltes');
    expect(find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')), findsOneWidget);
    expect(find.byKey(const ValueKey('fastinfo-pool-card-havi_koltes')), findsNothing);
  });
}
```

- [ ] **Step 2: Run the options tests and verify failure**

Run:

```bash
flutter test test/settings/fast_info_options_panel_test.dart
```

Expected: fails because `FastInfoOptionsPanel` has no `onChanged`, no draggable pool, and no split preview.

- [ ] **Step 3: Replace `FastInfoOptionsPanel` with a stateful split editor**

Change the public API to:

```dart
class FastInfoOptionsPanel extends StatefulWidget {
  const FastInfoOptionsPanel({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final FastInfoConfig config;
  final ValueChanged<FastInfoConfig> onChanged;

  @override
  State<FastInfoOptionsPanel> createState() => _FastInfoOptionsPanelState();
}
```

Use this state shape:

```dart
class _FastInfoOptionsPanelState extends State<FastInfoOptionsPanel> {
  late FastInfoConfig _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.config;
  }

  @override
  void didUpdateWidget(covariant FastInfoOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) _draft = widget.config;
  }

  Set<String> get _assignedIds {
    return <String>{
      for (final slot in _draft.pills) if (slot != null) slot.id,
      for (final slot in _draft.boxes) if (slot != null) slot.id,
    };
  }

  void _assign(FastInfoSlotType type, int index, String cardId) {
    final card = fastInfoCardById(cardId);
    if (card == null) return;
    final pills = List<FastInfoSlot?>.from(_draft.pills);
    final boxes = List<FastInfoSlot?>.from(_draft.boxes);

    for (var i = 0; i < pills.length; i += 1) {
      if (pills[i]?.id == cardId) pills[i] = null;
    }
    for (var i = 0; i < boxes.length; i += 1) {
      if (boxes[i]?.id == cardId) boxes[i] = null;
    }

    if (type == FastInfoSlotType.pill) {
      pills[index] = FastInfoSlot.fromCard(card, FastInfoSlotType.pill);
    } else {
      boxes[index] = FastInfoSlot.fromCard(card, FastInfoSlotType.box);
    }
    _emit(FastInfoConfig(pills: pills, boxes: boxes));
  }

  void _clear(FastInfoSlotType type, int index) {
    final pills = List<FastInfoSlot?>.from(_draft.pills);
    final boxes = List<FastInfoSlot?>.from(_draft.boxes);
    if (type == FastInfoSlotType.pill) {
      pills[index] = null;
    } else {
      boxes[index] = null;
    }
    _emit(FastInfoConfig(pills: pills, boxes: boxes));
  }

  void _emit(FastInfoConfig config) {
    setState(() => _draft = config);
    widget.onChanged(config);
  }
}
```

Build the split UI as:

```dart
@override
Widget build(BuildContext context) {
  final freeCards = fastInfoCardCatalog
      .where((card) => !_assignedIds.contains(card.id))
      .toList(growable: false);

  return Column(
    children: [
      SizedBox(
        height: 320,
        child: FastInfoPanel(
          config: _draft,
          backgroundColor: AppColors.gray100,
          onDropPillCard: (index, cardId) => _assign(FastInfoSlotType.pill, index, cardId),
          onDropBoxCard: (index, cardId) => _assign(FastInfoSlotType.box, index, cardId),
          onClearPillSlot: (index) => _clear(FastInfoSlotType.pill, index),
          onClearBoxSlot: (index) => _clear(FastInfoSlotType.box, index),
        ),
      ),
      Expanded(
        child: GridView.builder(
          key: const ValueKey('fastinfo-card-pool'),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.25,
          ),
          itemCount: freeCards.length,
          itemBuilder: (context, index) => _PoolCard(card: freeCards[index]),
        ),
      ),
    ],
  );
}
```

Implement `_PoolCard` as a compact `LongPressDraggable<String>` with key `ValueKey('fastinfo-pool-card-${card.id}')`, `data: card.id`, a `Material` feedback, title text, and `card.pillValue` as the secondary value.

- [ ] **Step 4: Run the options tests**

Run:

```bash
flutter test test/settings/fast_info_options_panel_test.dart
```

Expected: both tests pass.

- [ ] **Step 5: Commit options editor work**

```bash
git add lib/features/settings/widgets/options/fast_info_options_panel.dart test/settings/fast_info_options_panel_test.dart
git commit -m "feat: add fastinfo drag options editor"
```

### Task 4: Share FastInfo Config Between Settings And Home

**Files:**
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/settings/settings_page_test.dart`
- Test: `test/transactions/header_layout_test.dart`

- [ ] **Step 1: Update settings page tests for immediate FastInfo callback**

Add this test to `test/settings/settings_page_test.dart`:

```dart
testWidgets('FastInfo submenu reports config changes immediately', (tester) async {
  var callbackCount = 0;
  await tester.pumpWidget(buildSubject(onFastInfoConfigChanged: (_) => callbackCount += 1));
  await tester.pumpAndSettle();

  await tester.tap(find.text('FastInfo'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('fastinfo-clear-pill-0')));
  await tester.pumpAndSettle();

  expect(callbackCount, 1);
});
```

Update `buildSubject` in the test file to accept the callback:

```dart
Widget buildSubject({ValueChanged<FastInfoConfig>? onFastInfoConfigChanged}) {
  final bridge = NativeBridge(
    methodChannel: channel,
    eventChannel: const EventChannel('test/settings_page_events'),
  );
  return MaterialApp(
    home: SettingsPage(
      store: EventStore(bridge, realtimeEnabled: false),
      nativeBridge: bridge,
      onFastInfoConfigChanged: onFastInfoConfigChanged,
    ),
  );
}
```

Also add imports for `FastInfoConfig`.

- [ ] **Step 2: Update home/header test for injected config**

Add this test to `test/transactions/header_layout_test.dart`:

```dart
testWidgets('header fastinfo uses injected config instead of defaults', (tester) async {
  final store = TransactionStore(HeaderLayoutRepository());
  final config = FastInfoConfig(
    pills: const [
      FastInfoSlot(
        id: 'custom_pill',
        label: 'Custom pill',
        value: '42',
        type: FastInfoSlotType.pill,
        pillValue: '42',
      ),
      null,
      null,
    ],
    boxes: const [null, null, null],
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 780,
          child: TransactionHomePage(store: store, fastInfoConfig: config),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.drag(find.byKey(const ValueKey('transaction-header-card')), const Offset(0, 190));
  await tester.pumpAndSettle();

  expect(find.text('42'), findsOneWidget);
  expect(find.text('184k'), findsNothing);
});
```

Add imports for `FastInfoConfig` and `FastInfoSlot` if not already present.

- [ ] **Step 3: Run affected tests and verify failure**

Run:

```bash
flutter test test/settings/settings_page_test.dart test/transactions/header_layout_test.dart
```

Expected: fails because `SettingsPage` has no FastInfo callback and `TransactionHomePage` does not accept injected config.

- [ ] **Step 4: Update `SettingsPage` API and submenu wiring**

Add to `SettingsPage`:

```dart
final ValueChanged<FastInfoConfig>? onFastInfoConfigChanged;
```

Add it to the constructor and import `models/fast_info_config.dart` if needed. Add this method in `_SettingsPageState`:

```dart
Future<void> _updateFastInfoConfig(FastInfoConfig config) async {
  await _settingsStore.updateFastInfoConfig(config);
  if (!mounted) return;
  widget.onFastInfoConfigChanged?.call(_settingsStore.fastInfoConfig);
}
```

Change the FastInfo submenu arm to:

```dart
_SettingsMenu.fastInfo => FastInfoOptionsPanel(
    config: _settingsStore.fastInfoConfig,
    onChanged: _updateFastInfoConfig,
  ),
```

- [ ] **Step 5: Lift FastInfo state into `ExptShell` and inject it into home**

In `lib/features/shell/expt_shell.dart`, add:

```dart
FastInfoConfig _fastInfoConfig = FastInfoConfig.defaults();
```

Import `../settings/models/fast_info_config.dart`. Replace `_loadThemeSettings` with:

```dart
Future<void> _loadShellSettings() async {
  final payload = await widget.nativeBridge.expenseLoadSettings();
  if (!mounted) return;
  setState(() {
    _themeSettings = payload.themeSettings;
    _fastInfoConfig = payload.fastInfoConfig;
  });
}
```

Call `unawaited(_loadShellSettings());` in `initState()`. Add:

```dart
void _applyFastInfoConfig(FastInfoConfig config) {
  setState(() => _fastInfoConfig = config);
}
```

Pass `fastInfoConfig: _fastInfoConfig` to `TransactionHomePage`, and pass `onFastInfoConfigChanged: _applyFastInfoConfig` to `SettingsPage`.

- [ ] **Step 6: Inject config into `TransactionHomePage`**

In `lib/features/transactions/transaction_home_page.dart`, add constructor parameter and field:

```dart
this.fastInfoConfig,
```

```dart
final FastInfoConfig? fastInfoConfig;
```

Change the real header FastInfo panel to:

```dart
FastInfoPanel(
  config: widget.fastInfoConfig ?? FastInfoConfig.defaults(),
  backgroundColor: Colors.transparent,
),
```

- [ ] **Step 7: Run affected tests**

Run:

```bash
flutter test test/settings/settings_page_test.dart test/transactions/header_layout_test.dart
```

Expected: affected tests pass.

- [ ] **Step 8: Commit shared state work**

```bash
git add lib/features/settings/settings_page.dart lib/features/shell/expt_shell.dart lib/features/transactions/transaction_home_page.dart test/settings/settings_page_test.dart test/transactions/header_layout_test.dart
git commit -m "feat: sync fastinfo config with home header"
```

### Task 5: Native Defaults And Bridge Compatibility

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Update bridge test for new serialized fields**

In `test/settings/settings_bridge_test.dart`, extend the `updates FastInfo config through native bridge` assertions:

```dart
expect(updated.pills.first?.pillValue, '184k');
expect(updated.pills.first?.visualType, FastInfoVisualType.progress);
final firstPill = (payload['pills'] as List<Object?>).first as Map<dynamic, dynamic>;
expect(firstPill['pillValue'], '184k');
expect(firstPill['boxValue'], '184k / 250k');
expect(firstPill['visualType'], 'progress');
```

Use a config built from catalog:

```dart
final config = FastInfoConfig(
  pills: [
    FastInfoSlot.fromCard(fastInfoCardById('havi_koltes')!, FastInfoSlotType.pill),
    null,
    null,
  ],
  boxes: const [null, null, null],
);
```

Add imports for `fast_info_card_catalog.dart`.

- [ ] **Step 2: Run bridge test and verify failure if imports/defaults are incomplete**

Run:

```bash
flutter test test/settings/settings_bridge_test.dart
```

Expected: passes after Task 1 if Dart serialization is correct; fails only if imports or expected values need adjustment.

- [ ] **Step 3: Update native default FastInfo config**

In `ExpenseSettingsStore.kt`, replace `defaultFastInfoConfig()` entries with new catalog-compatible maps:

```kotlin
private fun defaultFastInfoConfig(): Map<String, Any?> = mapOf(
    "pills" to listOf(
        mapOf("id" to "havi_koltes", "label" to "Havi költés", "value" to "184k", "type" to "pill", "pillValue" to "184k", "boxValue" to "184k / 250k", "boxSubtitle" to "A havi keret 74%-a", "progress" to 0.74, "visualType" to "progress"),
        mapOf("id" to "mai_maradek_keret", "label" to "Mai maradék keret", "value" to "8.5k", "type" to "pill", "pillValue" to "8.5k", "boxValue" to "8 500 Ft", "boxSubtitle" to "Mai ajánlott keretből", "progress" to 0.68, "visualType" to "progress"),
        mapOf("id" to "koltesi_trend", "label" to "Költési trend", "value" to "+12%", "type" to "pill", "pillValue" to "+12%", "boxValue" to "+12%", "boxSubtitle" to "Az előző időszakhoz képest", "visualType" to "trend"),
    ),
    "boxes" to listOf(
        mapOf("id" to "mai_koltes", "label" to "Mai költés", "value" to "4 500 Ft", "type" to "box", "pillValue" to "4.5k", "boxValue" to "4 500 Ft", "boxSubtitle" to "2 tranzakció ma", "progress" to 0.22, "visualType" to "bar"),
        mapOf("id" to "havi_limit_allapot", "label" to "Havi limit állapot", "value" to "184k / 250k", "type" to "box", "pillValue" to "74%", "boxValue" to "184k / 250k", "boxSubtitle" to "66k maradt", "progress" to 0.74, "visualType" to "progress"),
        mapOf("id" to "kovetkezo_ismetlo_kiadas", "label" to "Következő ismétlődő kiadás", "value" to "Lakbér", "type" to "box", "pillValue" to "Lakbér", "boxValue" to "Lakbér", "boxSubtitle" to "3 nap múlva", "visualType" to "status"),
    ),
)
```

- [ ] **Step 4: Run bridge/settings tests**

Run:

```bash
flutter test test/settings/settings_bridge_test.dart test/settings/settings_page_test.dart
```

Expected: tests pass.

- [ ] **Step 5: Commit native compatibility work**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt test/settings/settings_bridge_test.dart
git commit -m "feat: align native fastinfo defaults"
```

### Task 6: Regression Pass And Final Verification

**Files:**
- Modify tests only if failures reveal outdated expectations.

- [ ] **Step 1: Run targeted FastInfo tests**

Run:

```bash
flutter test test/settings/fast_info_card_catalog_test.dart test/settings/fast_info_options_panel_test.dart test/settings/settings_bridge_test.dart test/settings/settings_page_test.dart test/transactions/fast_info_panel_test.dart test/transactions/header_layout_test.dart
```

Expected: all targeted tests pass.

- [ ] **Step 2: Run full Flutter test suite**

Run:

```bash
flutter test
```

Expected: all tests pass. In this Termux shell, Flutter currently fails before tests with `executable's TLS segment is underaligned`; if that still happens, record the failure exactly in the final handoff and run tests in the known working Flutter environment.

- [ ] **Step 3: Check git status**

Run:

```bash
git status --short --branch
```

Expected: clean branch with only committed work.

- [ ] **Step 4: Push branch when implementation is complete**

Run:

```bash
git push -u origin fastinfo
```

Expected: branch `fastinfo` exists on GitHub and is ready for build/CI.
