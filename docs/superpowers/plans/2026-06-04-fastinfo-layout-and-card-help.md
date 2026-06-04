# FastInfo Layout and Card Help Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persisted `3 pill + 3 box` / `6 box` FastInfo layout selector and tappable, annotated Hungarian help sheets for all 18 FastInfo cards.

**Architecture:** Keep the existing two fixed three-slot lists as the single persisted card arrangement and add only a presentation-mode enum. Extract the real pill and box surfaces so the live panel, settings preview, and annotated help sheet render the same components. Store explanatory content in a focused help metadata model; the settings panel opens a scrollable modal sheet using deterministic preview metrics.

**Tech Stack:** Flutter/Dart, Material widgets, `CustomPainter`, Flutter widget tests, Android Kotlin `SharedPreferences`, existing GitHub Actions Android workflow.

---

## File Map

**Create:**

- `lib/features/transactions/widgets/header_card/fast_info_card_surfaces.dart`
  - Owns reusable pill and box surfaces, drop targets, clear actions, tap actions, and stable keys.
- `lib/features/settings/models/fast_info_card_help.dart`
  - Owns help anchors, callouts, structured Hungarian help content, and the complete 18-card help map.
- `lib/features/settings/widgets/options/fast_info_annotated_preview.dart`
  - Composes real pill/box surfaces with positioned callout labels and connector-arrow painting.
- `lib/features/settings/widgets/options/fast_info_card_help_sheet.dart`
  - Owns modal presentation and the scrollable detailed help content.
- `test/settings/fast_info_card_help_test.dart`
  - Verifies complete structured help metadata for all 18 canonical cards.
- `test/settings/fast_info_card_help_sheet_test.dart`
  - Verifies real previews, annotations, Hungarian content, dismissal, and overflow behavior.

**Modify:**

- `lib/features/settings/models/fast_info_config.dart`
  - Adds persisted layout mode and `copyWith` while retaining fixed slot lists.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
  - Preserves and normalizes `layoutMode` in saved FastInfo JSON.
- `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
  - Selects mixed or two-row box rendering and exposes settings-only card taps.
- `lib/features/settings/widgets/options/fast_info_options_panel.dart`
  - Adds the selector, opens help from pool/preview taps, and preserves mode during assignment/clear.
- `test/settings/fast_info_card_catalog_test.dart`
  - Verifies layout defaults, round trips, and lossless mode switching.
- `test/settings/settings_bridge_test.dart`
  - Verifies the layout mode travels through the platform bridge.
- `test/transactions/fast_info_panel_test.dart`
  - Verifies both layouts, upper-box keys, tap callbacks, and overflow.
- `test/settings/fast_info_options_panel_test.dart`
  - Verifies selector behavior, help entry points, clear precedence, and unchanged drag behavior.
- `test/settings/settings_page_test.dart`
  - Verifies the FastInfo submenu still fits above bottom navigation with the selector.

Do not modify or add the unrelated untracked `.superpowers/` directory.

---

### Task 1: Persist the FastInfo Layout Mode

**Files:**
- Modify: `lib/features/settings/models/fast_info_config.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `test/settings/fast_info_card_catalog_test.dart`
- Modify: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Write failing model tests for defaulting, round-trip, and lossless switching**

Add these tests to `test/settings/fast_info_card_catalog_test.dart`:

```dart
test('layout mode defaults to mixed and unknown values migrate to mixed', () {
  expect(FastInfoConfig.defaults().layoutMode, FastInfoLayoutMode.mixed);
  expect(
    FastInfoConfig.fromMap(const <String, Object?>{
      'layoutMode': 'unknown',
      'pills': <Object?>[],
      'boxes': <Object?>[],
    }).layoutMode,
    FastInfoLayoutMode.mixed,
  );
});

test('six box mode round-trips without changing slot membership', () {
  final original = FastInfoConfig.defaults().copyWith(
    layoutMode: FastInfoLayoutMode.sixBoxes,
  );
  final restored = FastInfoConfig.fromMap(original.toMap());

  expect(restored.layoutMode, FastInfoLayoutMode.sixBoxes);
  expect(
    restored.pills.map((slot) => slot?.id),
    original.pills.map((slot) => slot?.id),
  );
  expect(
    restored.boxes.map((slot) => slot?.id),
    original.boxes.map((slot) => slot?.id),
  );
});
```

Update `updates FastInfo config through native bridge` in `test/settings/settings_bridge_test.dart` so the input uses `layoutMode: FastInfoLayoutMode.sixBoxes` and asserts:

```dart
expect(updated.layoutMode, FastInfoLayoutMode.sixBoxes);
expect(payload['layoutMode'], 'sixBoxes');
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
flutter test test/settings/fast_info_card_catalog_test.dart test/settings/settings_bridge_test.dart
```

Expected: FAIL because `FastInfoLayoutMode`, `FastInfoConfig.layoutMode`, and `copyWith` do not exist.

- [ ] **Step 3: Add the layout enum, persistence, and copyWith**

In `lib/features/settings/models/fast_info_config.dart`, add:

```dart
enum FastInfoLayoutMode {
  mixed('mixed'),
  sixBoxes('sixBoxes');

  const FastInfoLayoutMode(this.nativeValue);
  final String nativeValue;

  static FastInfoLayoutMode fromAny(Object? value) {
    return value?.toString() == FastInfoLayoutMode.sixBoxes.nativeValue
        ? FastInfoLayoutMode.sixBoxes
        : FastInfoLayoutMode.mixed;
  }
}
```

Extend `FastInfoConfig` without making existing constructor call sites specify a mode:

```dart
class FastInfoConfig {
  FastInfoConfig({
    required List<FastInfoSlot?> pills,
    required List<FastInfoSlot?> boxes,
    this.layoutMode = FastInfoLayoutMode.mixed,
  }) : pills = _fixed(pills),
       boxes = _fixed(boxes);

  final List<FastInfoSlot?> pills;
  final List<FastInfoSlot?> boxes;
  final FastInfoLayoutMode layoutMode;

  FastInfoConfig copyWith({
    List<FastInfoSlot?>? pills,
    List<FastInfoSlot?>? boxes,
    FastInfoLayoutMode? layoutMode,
  }) {
    return FastInfoConfig(
      pills: pills ?? this.pills,
      boxes: boxes ?? this.boxes,
      layoutMode: layoutMode ?? this.layoutMode,
    );
  }
}
```

Pass `layoutMode: FastInfoLayoutMode.fromAny(map['layoutMode'])` from `fromMap`, and include `'layoutMode': layoutMode.nativeValue` in `toMap`. Defaults remain `mixed` through the optional constructor parameter.

- [ ] **Step 4: Preserve the field in Android settings normalization**

In `ExpenseSettingsStore.updateFastInfoConfig`, add the normalized field:

```kotlin
val normalized = mapOf(
    "layoutMode" to normalizeFastInfoLayoutMode(args["layoutMode"]),
    "pills" to fixedSlots(args["pills"]),
    "boxes" to fixedSlots(args["boxes"]),
)
```

Add:

```kotlin
private fun normalizeFastInfoLayoutMode(value: Any?): String {
    return if (value?.toString() == "sixBoxes") "sixBoxes" else "mixed"
}
```

Include `"layoutMode" to "mixed"` in `defaultFastInfoConfig()`.

- [ ] **Step 5: Run the focused tests and verify they pass**

Run:

```bash
flutter test test/settings/fast_info_card_catalog_test.dart test/settings/settings_bridge_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit the persisted layout model**

```bash
git add lib/features/settings/models/fast_info_config.dart \
  android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt \
  test/settings/fast_info_card_catalog_test.dart \
  test/settings/settings_bridge_test.dart
git commit -m "Add persisted FastInfo layout mode"
```

---

### Task 2: Extract Shared Card Surfaces and Render Both Layouts

**Files:**
- Create: `lib/features/transactions/widgets/header_card/fast_info_card_surfaces.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
- Modify: `test/transactions/fast_info_panel_test.dart`

- [ ] **Step 1: Write failing panel tests for the six-box layout and settings-only taps**

Add `import 'package:exptv2/features/transactions/state/fast_info_metrics_resolver.dart';`
to `test/transactions/fast_info_panel_test.dart`, then add these tests:

```dart
testWidgets('six box mode renders upper slots as a distinct box row', (tester) async {
  final config = FastInfoConfig.defaults().copyWith(
    layoutMode: FastInfoLayoutMode.sixBoxes,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FastInfoPanel(
          config: config,
          metrics: FastInfoMetricsResolver.preview(),
        ),
      ),
    ),
  );

  expect(find.byKey(const ValueKey('fastinfo-pill-slot-0')), findsNothing);
  expect(find.byKey(const ValueKey('fastinfo-upper-box-slot-0')), findsOneWidget);
  expect(find.byKey(const ValueKey('fastinfo-box-slot-0')), findsOneWidget);
  expect(
    tester.getTopLeft(find.byKey(const ValueKey('fastinfo-upper-box-slot-0'))).dy,
    lessThan(tester.getTopLeft(find.byKey(const ValueKey('fastinfo-box-slot-0'))).dy),
  );
  expect(tester.takeException(), isNull);
});

testWidgets('assigned card tap reports canonical card id', (tester) async {
  String? tappedId;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FastInfoPanel(
          config: FastInfoConfig.defaults(),
          metrics: FastInfoMetricsResolver.preview(),
          onCardTap: (id) => tappedId = id,
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('fastinfo-pill-slot-0')));
  expect(tappedId, 'havi_koltes');
});
```

Extend the existing width loop to render both `FastInfoLayoutMode.values` and assert no exception for each mode at `320` and `600` widths.

- [ ] **Step 2: Run the panel test and verify it fails**

Run:

```bash
flutter test test/transactions/fast_info_panel_test.dart
```

Expected: FAIL because upper box keys and `onCardTap` do not exist.

- [ ] **Step 3: Extract reusable pill and box surfaces**

Move `_DropReadyFrame`, `_FastInfoPill`, and `_FastInfoBox` from `fast_info_panel.dart` into the new `fast_info_card_surfaces.dart`. Expose them as `FastInfoPillCard` and `FastInfoBoxCard`.

Use a required `keyPrefix` so existing lower-row keys remain stable and upper/help surfaces cannot collide:

```dart
typedef FastInfoCardDropCallback = void Function(int index, String cardId);

class FastInfoBoxCard extends StatelessWidget {
  const FastInfoBoxCard({
    super.key,
    required this.keyPrefix,
    required this.slot,
    required this.metric,
    required this.index,
    this.onDropCard,
    this.onClear,
    this.onTap,
  });

  final String keyPrefix;
  final FastInfoSlot? slot;
  final FastInfoMetricResult? metric;
  final int index;
  final FastInfoCardDropCallback? onDropCard;
  final ValueChanged<int>? onClear;
  final VoidCallback? onTap;
}
```

Generate keys consistently:

```dart
ValueKey('$keyPrefix-slot-$index')
ValueKey('$keyPrefix-drop-$index')
ValueKey('$keyPrefix-drop-frame-$index')
ValueKey('$keyPrefix-clear-$index')
```

Wrap only a non-null slot surface in `InkWell(onTap: onTap)`. Keep the clear `IconButton` above the tappable surface in the stack so tapping clear wins the gesture and does not open help. Implement the same API and key-prefix behavior for `FastInfoPillCard`.

- [ ] **Step 4: Select the upper renderer from layout mode**

Refactor `FastInfoPanel` to keep the existing `328` height and expose:

```dart
final ValueChanged<String>? onCardTap;
```

Render the upper position using `pillTop`:

```dart
config.layoutMode == FastInfoLayoutMode.mixed
    ? _pillColumn()
    : _boxRow(
        slots: config.pills,
        keyPrefix: 'fastinfo-upper-box',
        onDropCard: onDropPillCard,
        onClear: onClearPillSlot,
      )
```

Render the lower row with `keyPrefix: 'fastinfo-box'`. For upper boxes, pass `slot?.asType(FastInfoSlotType.box)` to the shared box surface. For every assigned surface, pass `onTap: () => onCardTap?.call(slot.id)` only when `onCardTap` is non-null.

Keep existing public callbacks `onDropPillCard`, `onDropBoxCard`, `onClearPillSlot`, and `onClearBoxSlot`, so the logical upper slots remain backed by `pills` in both modes.

- [ ] **Step 5: Run the panel test and verify it passes**

Run:

```bash
flutter test test/transactions/fast_info_panel_test.dart
```

Expected: PASS with both layouts overflow-free.

- [ ] **Step 6: Commit the shared surfaces and dual layout renderer**

```bash
git add lib/features/transactions/widgets/header_card/fast_info_card_surfaces.dart \
  lib/features/transactions/widgets/header_card/fast_info_panel.dart \
  test/transactions/fast_info_panel_test.dart
git commit -m "Render selectable FastInfo layouts"
```

---

### Task 3: Add Complete Structured Help Metadata

**Files:**
- Create: `lib/features/settings/models/fast_info_card_help.dart`
- Create: `test/settings/fast_info_card_help_test.dart`

- [ ] **Step 1: Write the failing completeness test**

Create `test/settings/fast_info_card_help_test.dart`:

```dart
import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_card_help.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every canonical FastInfo card has complete Hungarian help', () {
    expect(fastInfoCardHelpById.keys.toSet(), fastInfoCardCatalog.map((card) => card.id).toSet());

    for (final card in fastInfoCardCatalog) {
      final help = fastInfoCardHelpById[card.id];
      expect(help, isNotNull, reason: card.id);
      expect(help!.purpose.trim(), isNotEmpty, reason: card.id);
      expect(help.details.trim(), isNotEmpty, reason: card.id);
      expect(help.missingData.trim(), isNotEmpty, reason: card.id);
      expect(help.pillCallouts, isNotEmpty, reason: card.id);
      expect(help.boxCallouts, isNotEmpty, reason: card.id);
      expect(
        help.boxCallouts.map((item) => item.anchor).toSet(),
        containsAll(<FastInfoHelpAnchor>{
          FastInfoHelpAnchor.primaryValue,
          FastInfoHelpAnchor.secondaryValues,
        }),
        reason: card.id,
      );
    }
  });

  test('callout anchors are unique inside each preview', () {
    for (final help in fastInfoCardHelpById.values) {
      expect(help.pillCallouts.map((item) => item.anchor).toSet().length, help.pillCallouts.length);
      expect(help.boxCallouts.map((item) => item.anchor).toSet().length, help.boxCallouts.length);
    }
  });
}
```

- [ ] **Step 2: Run the metadata test and verify it fails**

Run:

```bash
flutter test test/settings/fast_info_card_help_test.dart
```

Expected: FAIL because `fast_info_card_help.dart` does not exist.

- [ ] **Step 3: Define the focused help model**

Create `lib/features/settings/models/fast_info_card_help.dart` with:

```dart
enum FastInfoHelpAnchor {
  pillValue,
  pillTrend,
  title,
  primaryValue,
  secondaryValues,
  avatar,
  trend,
  visual,
}

class FastInfoHelpCallout {
  const FastInfoHelpCallout(this.anchor, this.label);
  final FastInfoHelpAnchor anchor;
  final String label;
}

class FastInfoCardHelp {
  const FastInfoCardHelp({
    required this.purpose,
    required this.details,
    required this.calculation,
    required this.comparison,
    required this.missingData,
    required this.pillCallouts,
    required this.boxCallouts,
  });

  final String purpose;
  final String details;
  final List<String> calculation;
  final String comparison;
  final String missingData;
  final List<FastInfoHelpCallout> pillCallouts;
  final List<FastInfoHelpCallout> boxCallouts;
}
```

Add small const helpers to avoid repeating only truly shared callouts:

```dart
const _pillValue = FastInfoHelpCallout(
  FastInfoHelpAnchor.pillValue,
  'A kártya legfontosabb rövid értéke',
);
const _title = FastInfoHelpCallout(
  FastInfoHelpAnchor.title,
  'Megmutatja, melyik FastInfo adatot látod',
);
```

- [ ] **Step 4: Populate all 18 help entries with the approved Hungarian content**

Create a const map named `fastInfoCardHelpById` with one `FastInfoCardHelp` entry for every ID in the table below. Use the exact calculation and missing-data rules from `docs/superpowers/specs/2026-06-04-fastinfo-layout-and-card-help-design.md`, with these card-specific primary callouts:

| ID | Pill / primary meaning | Secondary meaning | Visual meaning |
| --- | --- | --- | --- |
| `mai_koltes` | Mai elköltött összeg | Maradék napi plafon és mai tranzakciószám | Napi plafon kihasználtsága; csak havi limit esetén |
| `heti_koltes` | Hétfőtől máig elköltve | Heti keret maradéka és előző hét azonos napjához mért eltérés | A hét hét napjának költése; a jövőbeli napok üresek |
| `havi_koltes` | Aktuális naptári hónap költése | Havi limit állapota és előző hónap azonos napjához mért eltérés | Aktuális, előző és két hónappal korábbi napi költésvonal |
| `megtakaritas` | Aktuális havi megtakarítás | Megtakarítási cél és megtakarítási ráta | Haladás a beállított megtakarítási cél felé |
| `koltesi_trend` | Elmúlt 30 nap költése | Az azt megelőző 30 nap és a kerettempó | Piros felfelé vagy zöld lefelé nyíl; nincs grafikon |
| `legutobbi_tranzakcio` | Legutóbbi tranzakció összege | Kereskedő, kategória és időpont | A kategória színe és ikonja |
| `varhato_ho_vegi_koltes` | Becsült hó végi költés | Becsült maradék és limitkockázat | Hó végi költési előrejelzés |
| `leggyorsabban_fogyo_kategorialimit` | Legmagasabb limithasználatú kategória | Elköltve/limit, limit közelében és limit felett lévő kategóriák | Kategória-avatar és színes limithaladás |
| `leggyakoribb_kereskedo` | Legtöbb tranzakcióval rendelkező kereskedő | Tranzakciószám, majd teljes összeg | A kereskedő leggyakoribb kategóriájának avatarja |
| `atlagos_napi_koltes` | Elmúlt 30 nap napi átlaga | Az egyenlegből fedezhető átlagos költési napok | Elmúlt 30 nap napi költésvonala |
| `no_spend_napok_szama` | Költésmentes napok száma ebben a hónapban | Eltelt havi napok száma | Költésmentes napok aránya az eltelt napokból |
| `top_kategoria_ma` | Mai legnagyobb összegű kategória | Összeg és részesedés a mai költésből | A kategória színe és ikonja |
| `top_kategoria_heten` | Heti leggyakoribb kategória | Heti és havi darabszámok és összegek | A heti top kategória avatarja |
| `legnagyobb_novekedo_kategoria` | Legnagyobbat változó kategória | Elmúlt 30 nap és előző 30 nap összege | Piros növekedés vagy zöld csökkenés és kategória-avatar |
| `kovetkezo_ismetlo_kiadas` | Következő ismétlődő kiadás | Esedékesség és következő 7 nap tételei | Az ismétlődő tétel kategória-avatarja |
| `havi_fix_koltseg_osszesen` | Aktuális havi fix költségek összege | Levont, hátralévő, legnagyobb és keret után maradó összeg | Fix költségek aránya a havi limitből |
| `bevetel_ebben_a_honapban` | Aktuális havi bevétel | Fedezeti napok és előző hónap azonos napjához mért eltérés | Zöld növekedés vagy piros csökkenés |
| `kiadas_bevetel_arany` | Elköltött havi bevétel százaléka | Nettó havi cashflow | Zöld/sárga/piros kiadás-bevétel arány |

Use card-specific `pillTrend`, `avatar`, `trend`, or `visual` callouts only when the deterministic preview metric exposes that region. Keep each preview to at most four callouts so labels stay readable.

- [ ] **Step 5: Run the metadata test and verify it passes**

Run:

```bash
flutter test test/settings/fast_info_card_help_test.dart
```

Expected: PASS for exactly 18 complete entries.

- [ ] **Step 6: Commit the structured help content**

```bash
git add lib/features/settings/models/fast_info_card_help.dart \
  test/settings/fast_info_card_help_test.dart
git commit -m "Add FastInfo card help metadata"
```

---

### Task 4: Build the Real Annotated Preview and Modal Help Sheet

**Files:**
- Create: `lib/features/settings/widgets/options/fast_info_annotated_preview.dart`
- Create: `lib/features/settings/widgets/options/fast_info_card_help_sheet.dart`
- Create: `test/settings/fast_info_card_help_sheet_test.dart`

- [ ] **Step 1: Write failing help-sheet tests**

Create `test/settings/fast_info_card_help_sheet_test.dart` with this helper:

```dart
Future<void> _pumpHelpLauncher(
  WidgetTester tester,
  String cardId, {
  double width = 390,
  double textScale = 1,
}) async {
  final metrics = buildFastInfoPreviewMetrics();
  final card = fastInfoCardById(cardId)!;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 820),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                key: const ValueKey('open-fastinfo-help'),
                onPressed: () => showFastInfoCardHelpSheet(
                  context,
                  card: card,
                  metric: metrics[card.id],
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    ),
  );
}
```

Use it to pump a button which calls `showFastInfoCardHelpSheet(...)` for `mai_koltes`.

Assert the complete interaction:

```dart
expect(find.byKey(const ValueKey('fastinfo-help-sheet-mai_koltes')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-help-pill-mai_koltes')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-help-box-mai_koltes')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-help-pill-arrows-mai_koltes')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-help-box-arrows-mai_koltes')), findsOneWidget);
expect(find.text('Számítás'), findsOneWidget);
expect(find.text('Ha nincs elég adat'), findsOneWidget);
expect(find.textContaining('Napi plafon'), findsWidgets);
expect(tester.takeException(), isNull);
```

Add a parameterized test for every `fastInfoCardCatalog` entry at widths `320` and `600`, plus a large-text pass at width `390` and `textScale: 1.4`. Open the sheet, scroll to the end, and assert `tester.takeException()` is null. Add a close-button test using `fastinfo-help-close`.

- [ ] **Step 2: Run the sheet test and verify it fails**

Run:

```bash
flutter test test/settings/fast_info_card_help_sheet_test.dart
```

Expected: FAIL because the annotated preview and help sheet do not exist.

- [ ] **Step 3: Implement annotated previews with real surfaces and arrows**

In `fast_info_annotated_preview.dart`, create:

```dart
enum FastInfoAnnotatedPreviewType { pill, box }

class FastInfoAnnotatedPreview extends StatelessWidget {
  const FastInfoAnnotatedPreview({
    super.key,
    required this.card,
    required this.metric,
    required this.type,
    required this.callouts,
  });

  final FastInfoCardDefinition card;
  final FastInfoMetricResult? metric;
  final FastInfoAnnotatedPreviewType type;
  final List<FastInfoHelpCallout> callouts;
}
```

Build a fixed-height `LayoutBuilder` + `Stack` diagram. Center a real `FastInfoPillCard` or `FastInfoBoxCard` using a temporary canonical slot. Wrap the real surface in `KeyedSubtree(key: ValueKey('fastinfo-help-${type.name}-${card.id}'))`, use `keyPrefix: 'fastinfo-help-${type.name}-${card.id}-surface'`, and pass no tap/drop/clear callbacks.

Place up to four compact callout labels in stable top-left, top-right, bottom-left, and bottom-right rectangles. Define normalized target points:

```dart
const _anchorOffsets = <FastInfoHelpAnchor, Offset>{
  FastInfoHelpAnchor.pillValue: Offset(.42, .50),
  FastInfoHelpAnchor.pillTrend: Offset(.82, .50),
  FastInfoHelpAnchor.title: Offset(.18, .12),
  FastInfoHelpAnchor.primaryValue: Offset(.28, .28),
  FastInfoHelpAnchor.secondaryValues: Offset(.32, .50),
  FastInfoHelpAnchor.avatar: Offset(.13, .82),
  FastInfoHelpAnchor.trend: Offset(.86, .82),
  FastInfoHelpAnchor.visual: Offset(.58, .82),
};
```

Draw connector lines and triangular arrowheads in `_FastInfoCalloutArrowPainter`. Give the painter these keys through its `CustomPaint`:

```dart
ValueKey('fastinfo-help-${type.name}-arrows-${card.id}')
```

Use `AppColors.primary`, a `1.5` stroke, and ensure paint occurs behind labels but above the preview background. At narrow widths, keep the preview horizontally inset and labels within the same constrained stack; truncate only the callout label after three lines.

- [ ] **Step 4: Implement the scrollable modal sheet**

In `fast_info_card_help_sheet.dart`, expose:

```dart
Future<void> showFastInfoCardHelpSheet(
  BuildContext context, {
  required FastInfoCardDefinition card,
  required FastInfoMetricResult? metric,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.gray100,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: .92,
      child: FastInfoCardHelpSheet(card: card, metric: metric),
    ),
  );
}
```

`FastInfoCardHelpSheet` reads `fastInfoCardHelpById[card.id]`, falls back to generic `Nincs adat` help for an unknown ID, and renders:

1. drag handle, title, and close `IconButton(key: ValueKey('fastinfo-help-close'))`;
2. purpose and detailed explanation;
3. `Pill nézet` annotated real pill preview;
4. `Box nézet` annotated real box preview;
5. `Számítás`, `Összehasonlítás`, and `Ha nincs elég adat` text sections.

Use a `SingleChildScrollView` with bottom safe padding. Give the root `ValueKey('fastinfo-help-sheet-${card.id}')`.

- [ ] **Step 5: Run the help-sheet tests and verify they pass**

Run:

```bash
flutter test test/settings/fast_info_card_help_sheet_test.dart
```

Expected: PASS for all 18 cards at compact and wide widths.

- [ ] **Step 6: Commit the annotated help sheet**

```bash
git add lib/features/settings/widgets/options/fast_info_annotated_preview.dart \
  lib/features/settings/widgets/options/fast_info_card_help_sheet.dart \
  test/settings/fast_info_card_help_sheet_test.dart
git commit -m "Add annotated FastInfo help sheets"
```

---

### Task 5: Wire the Selector, Pool Taps, and Preview Taps

**Files:**
- Modify: `lib/features/settings/widgets/options/fast_info_options_panel.dart`
- Modify: `test/settings/fast_info_options_panel_test.dart`
- Modify: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Write failing settings-panel interaction tests**

Add to `test/settings/fast_info_options_panel_test.dart`:

```dart
Widget _subject({
  required FastInfoConfig config,
  ValueChanged<FastInfoConfig>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 780,
        child: FastInfoOptionsPanel(
          config: config,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
}

testWidgets('layout selector switches preview without changing cards', (tester) async {
  FastInfoConfig? changed;
  await tester.pumpWidget(_subject(
    config: FastInfoConfig.defaults(),
    onChanged: (value) => changed = value,
  ));

  await tester.tap(find.byKey(const ValueKey('fastinfo-layout-six-boxes')));
  await tester.pumpAndSettle();

  expect(changed?.layoutMode, FastInfoLayoutMode.sixBoxes);
  expect(changed?.pills.map((slot) => slot?.id), FastInfoConfig.defaults().pills.map((slot) => slot?.id));
  expect(find.byKey(const ValueKey('fastinfo-upper-box-slot-0')), findsOneWidget);
  expect(find.byKey(const ValueKey('fastinfo-pill-slot-0')), findsNothing);
});

testWidgets('pool and assigned card taps open help', (tester) async {
  await tester.pumpWidget(_subject(config: FastInfoConfig.defaults()));

  await tester.tap(find.byKey(const ValueKey('fastinfo-pool-card-megtakaritas')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('fastinfo-help-sheet-megtakaritas')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('fastinfo-help-close')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('fastinfo-pill-slot-0')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')), findsOneWidget);
});
```

Add this clear-precedence regression:

```dart
testWidgets('clear button does not open card help', (tester) async {
  FastInfoConfig? changed;
  await tester.pumpWidget(_subject(
    config: FastInfoConfig.defaults(),
    onChanged: (value) => changed = value,
  ));

  await tester.tap(find.byKey(const ValueKey('fastinfo-clear-pill-0')));
  await tester.pumpAndSettle();

  expect(changed?.pills[0], isNull);
  expect(find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')), findsNothing);
});
```

Extend the existing drag test to assert `find.byKey(const ValueKey('fastinfo-help-sheet-mai_koltes'))` finds nothing after a successful long-press drag.

In `test/settings/settings_page_test.dart`, after opening FastInfo assert both selector keys exist and the submenu frame still ends at `1200 - AppDimensions.bottomNavHeight`.

- [ ] **Step 2: Run the settings tests and verify they fail**

Run:

```bash
flutter test test/settings/fast_info_options_panel_test.dart test/settings/settings_page_test.dart
```

Expected: FAIL because selector and help callbacks are not wired.

- [ ] **Step 3: Add the compact segmented layout selector**

At the top of `FastInfoOptionsPanel.build`, before the preview host, add a padded `SegmentedButton<FastInfoLayoutMode>`:

```dart
SegmentedButton<FastInfoLayoutMode>(
  key: const ValueKey('fastinfo-layout-selector'),
  segments: const <ButtonSegment<FastInfoLayoutMode>>[
    ButtonSegment(
      value: FastInfoLayoutMode.mixed,
      label: Text('3 pill + 3 box'),
    ),
    ButtonSegment(
      value: FastInfoLayoutMode.sixBoxes,
      label: Text('6 box'),
    ),
  ],
  selected: <FastInfoLayoutMode>{_draft.layoutMode},
  onSelectionChanged: (selection) {
    _emit(_draft.copyWith(layoutMode: selection.single));
  },
  style: const ButtonStyle(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
)
```

Wrap each segment label in a keyed subtree or key the containing selection targets as `fastinfo-layout-mixed` and `fastinfo-layout-six-boxes` so widget tests can tap unambiguously. Keep the selector above the preview and within horizontal `20 px` padding.

- [ ] **Step 4: Preserve mode during assignment and clear**

Replace direct `FastInfoConfig(pills: pills, boxes: boxes)` calls in `_assign` and `_clear` with:

```dart
_emit(_draft.copyWith(pills: pills, boxes: boxes));
```

This guarantees layout switching and later drag/drop operations never reset the chosen mode.

- [ ] **Step 5: Open help from pool and preview taps**

Add:

```dart
void _openHelp(String cardId) {
  final card = fastInfoCardById(cardId);
  if (card == null) return;
  showFastInfoCardHelpSheet(
    context,
    card: card,
    metric: _previewMetrics[cardId],
  );
}
```

Pass `onCardTap: _openHelp` to `FastInfoPanel`. Add `VoidCallback onTap` to `_PoolCard`, pass `_openHelp(card.id)`, and wrap `_PoolCardSurface` in a transparent `Material` + `InkWell` without changing its visual decoration. Keep `LongPressDraggable` as the outer interaction so the existing `650 ms` drag still wins after a long press.

- [ ] **Step 6: Run settings interaction tests and verify they pass**

Run:

```bash
flutter test test/settings/fast_info_options_panel_test.dart test/settings/settings_page_test.dart
```

Expected: PASS; short taps open help, clear only clears, and long press still drags.

- [ ] **Step 7: Commit the settings integration**

```bash
git add lib/features/settings/widgets/options/fast_info_options_panel.dart \
  test/settings/fast_info_options_panel_test.dart \
  test/settings/settings_page_test.dart
git commit -m "Wire FastInfo layout selector and card help"
```

---

### Task 6: Verify the Full Feature and Publish the Online Build

**Files:**
- Modify only if verification reveals a feature-scoped defect.

- [ ] **Step 1: Run all targeted FastInfo and settings tests**

Run:

```bash
flutter test \
  test/settings/fast_info_card_catalog_test.dart \
  test/settings/fast_info_card_help_test.dart \
  test/settings/fast_info_card_help_sheet_test.dart \
  test/settings/fast_info_options_panel_test.dart \
  test/settings/settings_bridge_test.dart \
  test/settings/settings_page_test.dart \
  test/transactions/fast_info_panel_test.dart \
  test/transactions/fast_info_metrics_resolver_test.dart \
  test/transactions/header_layout_test.dart
```

Expected: all tests pass with zero failures.

- [ ] **Step 2: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run the full Flutter test suite**

Run:

```bash
flutter test
```

Expected: all tests pass with zero failures.

- [ ] **Step 4: Review the final diff and repository state**

Run:

```bash
git diff --check
git status --short --branch
git diff --stat origin/main...HEAD
git log --oneline origin/main..HEAD
```

Expected: no whitespace errors; only the intended FastInfo files and approved docs/plan commits are ahead of `origin/main`; `.superpowers/` remains untracked and uncommitted.

- [ ] **Step 5: Commit any final feature-scoped verification fixes**

Only if Step 1-4 required changes:

```bash
git add lib/features/settings/models/fast_info_config.dart lib/features/settings/models/fast_info_card_help.dart lib/features/settings/widgets/options/fast_info_options_panel.dart lib/features/settings/widgets/options/fast_info_annotated_preview.dart lib/features/settings/widgets/options/fast_info_card_help_sheet.dart lib/features/transactions/widgets/header_card/fast_info_panel.dart lib/features/transactions/widgets/header_card/fast_info_card_surfaces.dart android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt test/settings/fast_info_card_catalog_test.dart test/settings/fast_info_card_help_test.dart test/settings/fast_info_card_help_sheet_test.dart test/settings/fast_info_options_panel_test.dart test/settings/settings_bridge_test.dart test/settings/settings_page_test.dart test/transactions/fast_info_panel_test.dart
git commit -m "Finalize FastInfo layout and card help"
```

- [ ] **Step 6: Push `main` to GitHub**

Run:

```bash
git push origin main
```

Expected: `main` updates successfully on `origin`.

- [ ] **Step 7: Verify the online Android build and release workflow**

Run:

```bash
gh run list --workflow android-build.yml --branch main --limit 1
run_id="$(gh run list --workflow android-build.yml --branch main --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$run_id" --exit-status
gh release view debug-latest --json tagName,isPrerelease,assets,url
```

Expected: the newest `main` workflow completes successfully and the `debug-latest` prerelease contains the updated debug APK asset.
