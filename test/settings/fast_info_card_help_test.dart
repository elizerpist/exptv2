import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_card_help.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every canonical FastInfo card has complete Hungarian help', () {
    expect(
      fastInfoCardHelpById.keys.toSet(),
      fastInfoCardCatalog.map((card) => card.id).toSet(),
    );

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
      expect(
        help.pillCallouts.map((item) => item.anchor).toSet().length,
        help.pillCallouts.length,
      );
      expect(
        help.boxCallouts.map((item) => item.anchor).toSet().length,
        help.boxCallouts.length,
      );
    }
  });
}
