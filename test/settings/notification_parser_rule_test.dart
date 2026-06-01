import 'package:exptv2/features/settings/models/notification_parser_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the user sample with non-breaking spaces', () {
    final rule = NotificationParserRule.defaults().copyWith(
      sampleText:
          "🍽️ 1\u00A0085\u00A0Ft összeget fizettél itt: Csepp Bu:fe'.\n"
          "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.",
    );

    final preview = rule.preview;

    expect(preview.isReady, isTrue);
    expect(preview.amountText, '1 085 Ft');
    expect(preview.amountValue, 1085);
    expect(preview.merchant, "Csepp Bu:fe'");
  });

  test('supports custom user patterns without hardcoded bank wording', () {
    final rule = NotificationParserRule.defaults().copyWith(
      sampleText: 'Kártyás vásárlás: Tesco - 12 345 HUF',
      includeKeyword: '',
      amountPattern: r'(?<amount>\d[\d\s]*)\s*HUF',
      merchantPattern: r'vásárlás:\s*(?<merchant>[^-]+)\s*-',
    );

    final preview = rule.preview;

    expect(preview.isReady, isTrue);
    expect(preview.amountText, '12 345 HUF');
    expect(preview.amountValue, 12345);
    expect(preview.merchant, 'Tesco');
  });

  test('treats dotted Hungarian thousands as an integer amount', () {
    final rule = NotificationParserRule.defaults().copyWith(
      sampleText: "🍽️ 1.085 Ft összeget fizettél itt: Csepp Bu:fe'.",
    );

    expect(rule.preview.amountValue, 1085);
  });

  test('reports invalid regex without throwing', () {
    final rule = NotificationParserRule.defaults().copyWith(amountPattern: '[');

    final preview = rule.preview;

    expect(preview.isReady, isFalse);
    expect(preview.errorText, contains('Összeg regex'));
  });
}
