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

  test(
    'simple help copy explains purpose, calculation, and fixed exclusions',
    () {
      for (final help in fastInfoCardHelpById.values) {
        final joined = <String>[
          help.purpose,
          help.details,
          ...help.calculation,
          help.comparison,
          help.missingData,
        ].join(' ');
        expect(joined, contains('Ez azt mutatja'));
        expect(joined, contains('Így számol'));
      }

      for (final id in <String>[
        'mai_koltes',
        'heti_koltes',
        'havi_koltes',
        'koltesi_trend',
        'top_kategoria_heten',
        'legnagyobb_novekedo_kategoria',
      ]) {
        final help = fastInfoCardHelpById[id]!;
        final joined = <String>[
          help.purpose,
          help.details,
          ...help.calculation,
          help.comparison,
          help.missingData,
        ].join(' ').toLowerCase();
        expect(joined, contains('fixek nélkül'), reason: id);
      }
    },
  );
}
