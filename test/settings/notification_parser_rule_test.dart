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

  test('profile config stores multiple independently enabled profiles', () {
    final config = NotificationParserConfig.fromMap(<String, Object?>{
      'profiles': <Object?>[
        <String, Object?>{
          'id': 'bank-a',
          'name': 'Bank A',
          'enabled': true,
          'appFilterText': r'^Bank A$',
          'sampleText': 'Paid 999 Ft at Corner Shop',
          'includeKeyword': 'Paid',
          'amountPattern': r'(?<amount>\d+)\s*Ft',
          'merchantPattern': r'at\s+(?<merchant>.+)',
        },
        <String, Object?>{
          'id': 'bank-b',
          'name': 'Bank B',
          'enabled': false,
          'appFilterText': r'^Bank B$',
          'sampleText': 'Kártyás vásárlás: Tesco - 12 345 HUF',
          'includeKeyword': '',
          'amountPattern': r'(?<amount>\d[\d\s]*)\s*HUF',
          'merchantPattern': r'vásárlás:\s*(?<merchant>[^-]+)\s*-',
        },
      ],
    });

    expect(config.profiles, hasLength(2));
    expect(config.activeProfiles.map((profile) => profile.id), ['bank-a']);
    expect(config.profiles.last.preview.merchant, 'Tesco');
    expect(config.toMap()['profiles'], isA<List<Object?>>());
  });

  test(
    'learns parser patterns from tapped sample parts without regex editing',
    () {
      final profile = NotificationParserProfile.defaults().copyWith(
        sampleText: 'Kártyás vásárlás: Tesco - 12 345 HUF',
        includeKeyword: '',
      );

      final trained = profile
          .learnAmountFromSelection('12 345 HUF')
          .learnMerchantFromSelection('Tesco');

      expect(trained.amountSelection, '12 345 HUF');
      expect(trained.merchantSelection, 'Tesco');
      expect(trained.preview.isReady, isTrue);
      expect(trained.preview.amountValue, 12345);
      expect(trained.preview.merchant, 'Tesco');
    },
  );

  test(
    'builds one-tap training tokens from amount and merchant candidates',
    () {
      final tokens = NotificationTrainingToken.fromSample(
        'Kártyás vásárlás: Tesco - 12 345 HUF',
      );

      expect(tokens.map((token) => token.text), contains('Tesco'));
      expect(tokens.map((token) => token.text), contains('12 345 HUF'));
    },
  );

  test('reports invalid regex without throwing', () {
    final rule = NotificationParserRule.defaults().copyWith(amountPattern: '[');

    final preview = rule.preview;

    expect(preview.isReady, isFalse);
    expect(preview.errorText, contains('Összeg regex'));
  });
}
