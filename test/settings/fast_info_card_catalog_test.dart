import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedIds = <String>{
    'mai_koltes',
    'heti_koltes',
    'havi_koltes',
    'megtakaritas',
    'koltesi_trend',
    'legutobbi_tranzakcio',
    'varhato_ho_vegi_koltes',
    'leggyorsabban_fogyo_kategorialimit',
    'leggyakoribb_kereskedo',
    'atlagos_napi_koltes',
    'no_spend_napok_szama',
    'top_kategoria_heten',
    'legnagyobb_novekedo_kategoria',
    'kovetkezo_ismetlo_kiadas',
    'havi_fix_koltseg_osszesen',
    'bevetel_ebben_a_honapban',
    'kiadas_bevetel_arany',
  };

  test('catalog exposes exactly the approved canonical cards', () {
    expect(fastInfoCardCatalog.map((card) => card.id).toSet(), expectedIds);
    expect(fastInfoCardCatalog, hasLength(17));
    expect(fastInfoCardById('debug_riasztasok'), isNull);
  });

  test('slot created from a card persists identity only', () {
    final card = fastInfoCardById('havi_koltes')!;

    final pill = FastInfoSlot.fromCard(card, FastInfoSlotType.pill);
    final box = FastInfoSlot.fromCard(card, FastInfoSlotType.box);

    expect(pill.id, 'havi_koltes');
    expect(pill.label, 'Havi költés');
    expect(pill.type, FastInfoSlotType.pill);
    expect(pill.value, isEmpty);
    expect(pill.pillValue, isNull);
    expect(box.type, FastInfoSlotType.box);
    expect(box.value, isEmpty);
    expect(box.boxValue, isNull);
    expect(box.visualType, FastInfoVisualType.plain);
  });

  test('slot deserializes optional legacy render fields', () {
    final restored = FastInfoSlot.fromMap(const <String, Object?>{
      'id': 'havi_koltes',
      'label': 'Régi havi költés',
      'value': '184k',
      'pillValue': '184k',
      'boxValue': '184k / 250k',
      'boxSubtitle': 'Régi alcím',
      'progress': 0.74,
      'visualType': 'progress',
      'type': 'box',
    });

    expect(restored.id, 'havi_koltes');
    expect(restored.label, 'Régi havi költés');
    expect(restored.pillValue, '184k');
    expect(restored.boxValue, '184k / 250k');
    expect(restored.boxSubtitle, 'Régi alcím');
    expect(restored.progress, 0.74);
    expect(restored.visualType, FastInfoVisualType.progress);
    expect(restored.type, FastInfoSlotType.box);
  });

  test(
    'config maps merged ids, removes deleted ids, and globally deduplicates',
    () {
      final config = FastInfoConfig.fromMap({
        'pills': [
          {'id': 'havi_limit_allapot', 'type': 'pill'},
          {'id': 'mai_koltes', 'type': 'pill'},
          {'id': 'debug_riasztasok', 'type': 'pill'},
        ],
        'boxes': [
          {'id': 'havi_koltes', 'type': 'box'},
          {'id': 'puffer_napok_szama', 'type': 'box'},
          {'id': 'top_kategoria_honapban', 'type': 'box'},
        ],
      });

      expect(config.pills.map((slot) => slot?.id).toList(), [
        'havi_koltes',
        'mai_koltes',
        null,
      ]);
      expect(config.boxes.map((slot) => slot?.id).toList(), [
        null,
        'atlagos_napi_koltes',
        'top_kategoria_heten',
      ]);
    },
  );

  test('defaults use six unique canonical cards in fixed slots', () {
    final config = FastInfoConfig.defaults();

    expect(config.pills.map((slot) => slot?.id).toList(), [
      'havi_koltes',
      'koltesi_trend',
      'kiadas_bevetel_arany',
    ]);
    expect(config.boxes.map((slot) => slot?.id).toList(), [
      'mai_koltes',
      'heti_koltes',
      'kovetkezo_ismetlo_kiadas',
    ]);
    expect({
      for (final slot in [...config.pills, ...config.boxes]) slot?.id,
    }, hasLength(6));
  });

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

  test('row presentations round-trip independently from slot membership', () {
    final original = FastInfoConfig.defaults().copyWith(
      upperRowPresentation: FastInfoRowPresentation.box,
      lowerRowPresentation: FastInfoRowPresentation.pill,
    );
    final restored = FastInfoConfig.fromMap(original.toMap());

    expect(restored.layoutMode, FastInfoLayoutMode.mixed);
    expect(restored.upperRowPresentation, FastInfoRowPresentation.box);
    expect(restored.lowerRowPresentation, FastInfoRowPresentation.pill);
    expect(restored.pills.map((slot) => slot?.id), [
      'havi_koltes',
      'koltesi_trend',
      'kiadas_bevetel_arany',
    ]);
    expect(restored.boxes.map((slot) => slot?.id), [
      'mai_koltes',
      'heti_koltes',
      'kovetkezo_ismetlo_kiadas',
    ]);
    expect(original.toMap()['layoutMode'], 'mixed');
    expect(original.toMap()['upperRowPresentation'], 'box');
    expect(original.toMap()['lowerRowPresentation'], 'pill');
  });
}
