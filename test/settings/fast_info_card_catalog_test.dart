import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains many unique selectable cards', () {
    expect(fastInfoCardCatalog.length, greaterThan(60));
    expect(
      fastInfoCardCatalog.map((card) => card.id).toSet().length,
      fastInfoCardCatalog.length,
    );
    expect(fastInfoCardById('havi_koltes')?.title, 'Havi költés');
    expect(
      fastInfoCardById('debug_riasztasok')?.visualType,
      FastInfoVisualType.status,
    );
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
    final slot = FastInfoSlot.fromCard(
      fastInfoCardById('koltesi_trend')!,
      FastInfoSlotType.box,
    );
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
