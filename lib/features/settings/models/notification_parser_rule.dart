class NotificationParserRule {
  const NotificationParserRule({
    required this.enabled,
    required this.sampleText,
    required this.includeKeyword,
    required this.amountPattern,
    required this.merchantPattern,
  });

  final bool enabled;
  final String sampleText;
  final String includeKeyword;
  final String amountPattern;
  final String merchantPattern;

  factory NotificationParserRule.defaults() {
    return const NotificationParserRule(
      enabled: true,
      sampleText:
          "🍽️ 1\u00A0085\u00A0Ft összeget fizettél itt: Csepp Bu:fe'.\n"
          "A(z) HUF Zseb egyenlege: 71\u00A0795,87\u00A0Ft.",
      includeKeyword: 'fizettél',
      amountPattern: r'(?<amount>\d[\d\s.,]*)(?:\s*(?:Ft|HUF))',
      merchantPattern: r'itt:\s*(?<merchant>.+?)(?:\.|$)',
    );
  }

  factory NotificationParserRule.fromMap(Map<dynamic, dynamic> map) {
    final defaults = NotificationParserRule.defaults();
    return NotificationParserRule(
      enabled: map['enabled'] is bool
          ? map['enabled'] as bool
          : defaults.enabled,
      sampleText: _stringValue(map['sampleText'], defaults.sampleText),
      includeKeyword: _stringValue(
        map['includeKeyword'],
        defaults.includeKeyword,
      ),
      amountPattern: _stringValue(map['amountPattern'], defaults.amountPattern),
      merchantPattern: _stringValue(
        map['merchantPattern'],
        defaults.merchantPattern,
      ),
    );
  }

  NotificationParserPreview get preview =>
      NotificationParserPreview.fromRule(this);

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'enabled': enabled,
      'sampleText': sampleText,
      'includeKeyword': includeKeyword,
      'amountPattern': amountPattern,
      'merchantPattern': merchantPattern,
    };
  }

  NotificationParserRule copyWith({
    bool? enabled,
    String? sampleText,
    String? includeKeyword,
    String? amountPattern,
    String? merchantPattern,
  }) {
    return NotificationParserRule(
      enabled: enabled ?? this.enabled,
      sampleText: sampleText ?? this.sampleText,
      includeKeyword: includeKeyword ?? this.includeKeyword,
      amountPattern: amountPattern ?? this.amountPattern,
      merchantPattern: merchantPattern ?? this.merchantPattern,
    );
  }

  static String _stringValue(Object? value, String fallback) {
    final text = value?.toString();
    if (text == null) return fallback;
    return text;
  }
}

class NotificationParserPreview {
  const NotificationParserPreview({
    required this.amountText,
    required this.amountValue,
    required this.merchant,
    required this.errorText,
  });

  final String? amountText;
  final double? amountValue;
  final String? merchant;
  final String? errorText;

  bool get isReady =>
      amountValue != null && merchant != null && errorText == null;

  factory NotificationParserPreview.fromRule(NotificationParserRule rule) {
    final normalized = _normalizeText(rule.sampleText);
    try {
      if (normalized.isEmpty) {
        return const NotificationParserPreview(
          amountText: null,
          amountValue: null,
          merchant: null,
          errorText: 'Adj meg egy teszt értesítést.',
        );
      }

      final keyword = rule.includeKeyword.trim();
      if (keyword.isNotEmpty &&
          !normalized.toLowerCase().contains(
            _normalizeText(keyword).toLowerCase(),
          )) {
        return const NotificationParserPreview(
          amountText: null,
          amountValue: null,
          merchant: null,
          errorText: 'A minta nem tartalmazza a megadott kulcsszót.',
        );
      }

      final amountRegex = _compile(rule.amountPattern, 'Összeg regex');
      final merchantRegex = _compile(rule.merchantPattern, 'Bolt regex');
      final amountMatch = amountRegex.firstMatch(normalized);
      final merchantMatch = merchantRegex.firstMatch(normalized);

      final amountCapture = _capture(amountMatch, 'amount');
      final amountValue = _parseAmount(amountCapture);
      final amountText = amountMatch == null
          ? null
          : _normalizeText(amountMatch.group(0) ?? '');
      final merchant = _capture(merchantMatch, 'merchant')?.trim();

      if (amountMatch == null || amountValue == null) {
        return NotificationParserPreview(
          amountText: amountText,
          amountValue: amountValue,
          merchant: merchant?.isEmpty ?? true ? null : merchant,
          errorText: 'Összeg regex nem talált értéket.',
        );
      }
      if (merchant == null || merchant.isEmpty) {
        return NotificationParserPreview(
          amountText: amountText,
          amountValue: amountValue,
          merchant: null,
          errorText: 'Bolt regex nem talált értéket.',
        );
      }

      return NotificationParserPreview(
        amountText: amountText,
        amountValue: amountValue,
        merchant: merchant,
        errorText: null,
      );
    } on _ParserRuleException catch (error) {
      return NotificationParserPreview(
        amountText: null,
        amountValue: null,
        merchant: null,
        errorText: error.message,
      );
    }
  }

  static RegExp _compile(String pattern, String label) {
    if (pattern.trim().isEmpty) {
      throw _ParserRuleException('$label szükséges.');
    }
    try {
      return RegExp(
        pattern,
        caseSensitive: false,
        dotAll: true,
        multiLine: true,
      );
    } on FormatException catch (error) {
      throw _ParserRuleException('$label hibás: ${error.message}');
    }
  }

  static String? _capture(RegExpMatch? match, String name) {
    if (match == null) return null;
    try {
      final named = match.namedGroup(name);
      if (named != null && named.isNotEmpty) return named;
    } on ArgumentError {
      // User patterns may use a simple first capture group instead of a named group.
    }
    if (match.groupCount >= 1) return match.group(1);
    return match.group(0);
  }

  static double? _parseAmount(String? raw) {
    if (raw == null) return null;
    var cleaned = _normalizeText(raw).replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (cleaned.isEmpty) return null;
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');
    if (hasComma && hasDot) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasDot && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(cleaned)) {
      cleaned = cleaned.replaceAll('.', '');
    } else if (hasComma) {
      cleaned = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned);
  }

  static String _normalizeText(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ParserRuleException implements Exception {
  const _ParserRuleException(this.message);

  final String message;
}
