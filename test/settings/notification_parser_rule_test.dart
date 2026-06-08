import 'package:exptv2/features/settings/models/notification_parser_rule.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
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
          'transactionType': 'income',
        },
      ],
    });

    expect(config.profiles, hasLength(2));
    expect(config.activeProfiles.map((profile) => profile.id), ['bank-a']);
    expect(config.profiles.last.preview.merchant, 'Tesco');
    expect(config.profiles.last.transactionType, TransactionType.income);
    expect(config.toMap()['profiles'], isA<List<Object?>>());
  });

  test('income parser profiles keep positive transaction direction', () {
    final rule = NotificationParserRule.defaults().copyWith(
      sampleText: 'Jóváírás: Munkabér + 250 000 HUF',
      includeKeyword: '',
      merchantPattern: r'Jóváírás:\s*(?<merchant>[^+]+)\s*\+',
      transactionType: TransactionType.income,
    );

    final preview = rule.preview;

    expect(rule.transactionType, TransactionType.income);
    expect(rule.toMap()['transactionType'], 'income');
    expect(preview.transactionType, TransactionType.income);
    expect(preview.amountValue, 250000);
    expect(preview.merchant, 'Munkabér');
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

  test(
    'builds tokens for all words and amounts in two-amount wallet messages',
    () {
      final tokens = NotificationTrainingToken.fromSample(
        "🍽️ 3\u00A0085\u00A0Ft összeget fizettél itt: nyírő.\n"
        "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.",
      ).map((token) => token.text).toList();

      expect(tokens, contains('3 085 Ft'));
      expect(tokens, contains('71 795,87 Ft'));
      expect(tokens, contains('itt'));
      expect(tokens, contains('nyírő'));
    },
  );

  test(
    'learns selected paid amount instead of wallet balance from user sample',
    () {
      final profile = NotificationParserProfile.defaults().copyWith(
        sampleText:
            "🍽️ 3\u00A0085\u00A0Ft összeget fizettél itt: nyírő.\n"
            "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.",
        includeKeyword: 'fizettél',
      );

      final trained = profile
          .learnAmountFromSelection('3 085 Ft')
          .learnMerchantFromSelection('nyírő');

      expect(trained.preview.isReady, isTrue);
      expect(trained.preview.amountText, '3 085 Ft');
      expect(trained.preview.amountValue, 3085);
      expect(trained.preview.merchant, 'nyírő');
    },
  );

  test('can learn the second amount when the user selects it', () {
    final profile = NotificationParserProfile.defaults().copyWith(
      sampleText:
          "🍽️ 3\u00A0085\u00A0Ft összeget fizettél itt: nyírő.\n"
          "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.",
      includeKeyword: 'fizettél',
    );

    final trained = profile
        .learnAmountFromSelection('71 795,87 Ft')
        .learnMerchantFromSelection('nyírő');

    expect(trained.preview.isReady, isTrue);
    expect(trained.preview.amountText, '71 795,87 Ft');
    expect(trained.preview.amountValue, 71795.87);
    expect(trained.preview.merchant, 'nyírő');
  });

  test('reports invalid regex without throwing', () {
    final rule = NotificationParserRule.defaults().copyWith(amountPattern: '[');

    final preview = rule.preview;

    expect(preview.isReady, isFalse);
    expect(preview.errorText, contains('Összeg regex'));
  });
}
