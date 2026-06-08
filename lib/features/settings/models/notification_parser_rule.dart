import '../../transactions/models/transaction_category.dart';

class NotificationParserConfig {
  const NotificationParserConfig({required this.profiles});

  final List<NotificationParserProfile> profiles;

  factory NotificationParserConfig.defaults() {
    return NotificationParserConfig(
      profiles: [NotificationParserProfile.defaults()],
    );
  }

  factory NotificationParserConfig.fromMap(Map<dynamic, dynamic> map) {
    final rows = map['profiles'];
    if (rows is List && rows.isNotEmpty) {
      return NotificationParserConfig(
        profiles: rows
            .whereType<Map<dynamic, dynamic>>()
            .map(NotificationParserProfile.fromMap)
            .toList(),
      );
    }
    return NotificationParserConfig(
      profiles: [NotificationParserProfile.fromFlatRuleMap(map)],
    );
  }

  List<NotificationParserProfile> get activeProfiles =>
      profiles.where((profile) => profile.enabled).toList(growable: false);

  NotificationParserProfile selected(String? id) {
    return profiles.firstWhere(
      (profile) => profile.id == id,
      orElse: () => profiles.isEmpty
          ? NotificationParserProfile.defaults()
          : profiles.first,
    );
  }

  NotificationParserConfig upsert(NotificationParserProfile profile) {
    var found = false;
    final rows = profiles.map((row) {
      if (row.id != profile.id) return row;
      found = true;
      return profile;
    }).toList();
    if (!found) rows.add(profile);
    return NotificationParserConfig(profiles: rows);
  }

  NotificationParserConfig remove(String id) {
    final rows = profiles.where((profile) => profile.id != id).toList();
    if (rows.isEmpty) return NotificationParserConfig.defaults();
    return NotificationParserConfig(profiles: rows);
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'profiles': profiles.map((profile) => profile.toMap()).toList(),
    };
  }
}

class NotificationParserProfile {
  const NotificationParserProfile({
    required this.id,
    required this.name,
    required this.enabled,
    required this.appFilterText,
    required this.packageName,
    required this.appLabel,
    required this.rule,
  });

  final String id;
  final String name;
  final bool enabled;
  final String appFilterText;
  final String packageName;
  final String appLabel;
  final NotificationParserRule rule;

  String get sampleText => rule.sampleText;
  String get includeKeyword => rule.includeKeyword;
  String get amountPattern => rule.amountPattern;
  String get merchantPattern => rule.merchantPattern;
  String get amountSelection => rule.amountSelection;
  String get merchantSelection => rule.merchantSelection;
  TransactionType get transactionType => rule.transactionType;
  NotificationParserPreview get preview => rule.preview;

  factory NotificationParserProfile.defaults({int index = 1}) {
    final suffix = index <= 1 ? '' : ' $index';
    return NotificationParserProfile(
      id: 'profile-$index',
      name: 'Profil$suffix',
      enabled: true,
      appFilterText: '',
      packageName: '',
      appLabel: '',
      rule: NotificationParserRule.defaults(),
    );
  }

  factory NotificationParserProfile.fromFlatRuleMap(Map<dynamic, dynamic> map) {
    final rule = NotificationParserRule.fromMap(map);
    return NotificationParserProfile(
      id: _stringValue(map['id'], 'profile-1'),
      name: _stringValue(map['name'], 'Profil'),
      enabled: map['enabled'] is bool ? map['enabled'] as bool : rule.enabled,
      appFilterText: _stringValue(map['appFilterText'], ''),
      packageName: _stringValue(map['packageName'], ''),
      appLabel: _stringValue(map['appLabel'], ''),
      rule: rule,
    );
  }

  factory NotificationParserProfile.fromMap(Map<dynamic, dynamic> map) {
    final nestedRule = map['rule'];
    final rule = nestedRule is Map<dynamic, dynamic>
        ? NotificationParserRule.fromMap(nestedRule)
        : NotificationParserRule.fromMap(map);
    return NotificationParserProfile(
      id: _stringValue(map['id'], 'profile-1'),
      name: _stringValue(map['name'], 'Profil'),
      enabled: map['enabled'] is bool ? map['enabled'] as bool : rule.enabled,
      appFilterText: _stringValue(map['appFilterText'], ''),
      packageName: _stringValue(map['packageName'], ''),
      appLabel: _stringValue(map['appLabel'], ''),
      rule: rule.copyWith(
        enabled: map['enabled'] is bool ? map['enabled'] as bool : rule.enabled,
      ),
    );
  }

  NotificationParserProfile copyWith({
    String? id,
    String? name,
    bool? enabled,
    String? appFilterText,
    String? packageName,
    String? appLabel,
    String? sampleText,
    String? includeKeyword,
    String? amountPattern,
    String? merchantPattern,
    String? amountSelection,
    String? merchantSelection,
    TransactionType? transactionType,
    NotificationParserRule? rule,
  }) {
    final nextEnabled = enabled ?? this.enabled;
    return NotificationParserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: nextEnabled,
      appFilterText: appFilterText ?? this.appFilterText,
      packageName: packageName ?? this.packageName,
      appLabel: appLabel ?? this.appLabel,
      rule: (rule ?? this.rule).copyWith(
        enabled: nextEnabled,
        sampleText: sampleText,
        includeKeyword: includeKeyword,
        amountPattern: amountPattern,
        merchantPattern: merchantPattern,
        amountSelection: amountSelection,
        merchantSelection: merchantSelection,
        transactionType: transactionType,
      ),
    );
  }

  NotificationParserProfile learnAmountFromSelection(String selection) {
    final normalized = NotificationParserPreview.normalizeText(selection);
    final sample = NotificationParserPreview.normalizeText(sampleText);
    final selectedMatch = _selectedAmountMatch(sample, normalized);
    final amountPattern = selectedMatch == null
        ? _amountCorePattern
        : _contextualAmountPattern(sample, selectedMatch);
    return copyWith(
      amountSelection: normalized,
      amountPattern: amountPattern,
    );
  }

  NotificationParserProfile learnMerchantFromSelection(String selection) {
    final normalized = NotificationParserPreview.normalizeText(selection);
    final sample = NotificationParserPreview.normalizeText(sampleText);
    final escaped = RegExp.escape(normalized);
    var pattern = '(?<merchant>$escaped)';
    if (RegExp('^\\s*$escaped\\s*:', caseSensitive: false).hasMatch(sample)) {
      pattern = r'^(?<merchant>[^:]{1,80}):\s*';
    } else if (RegExp('itt:\\s*$escaped', caseSensitive: false).hasMatch(sample)) {
      pattern = r'itt:\s*(?<merchant>.+?)(?:\.|$)';
    } else if (RegExp(
      ':\\s*$escaped\\s*-',
      caseSensitive: false,
    ).hasMatch(sample)) {
      pattern = r':\s*(?<merchant>[^-]+)\s*-';
    } else if (RegExp(
      'at\\s+$escaped',
      caseSensitive: false,
    ).hasMatch(sample)) {
      pattern = r'at\s+(?<merchant>.+)';
    }
    return copyWith(merchantSelection: normalized, merchantPattern: pattern);
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'enabled': enabled,
      'appFilterText': appFilterText,
      'packageName': packageName,
      'appLabel': appLabel,
      ...rule.toMap(),
    };
  }

  static String _stringValue(Object? value, String fallback) {
    final text = value?.toString();
    if (text == null) return fallback;
    return text;
  }

  static const _amountCorePattern =
      r'(?<amount>\d[\d\s.,]*)(?:\s*(?:Ft|HUF))';

  static RegExpMatch? _selectedAmountMatch(String sample, String selection) {
    for (final match in RegExp(
      r'\d[\d\s.,]*(?:\s*(?:Ft|HUF))',
      caseSensitive: false,
    ).allMatches(sample)) {
      final text = NotificationParserPreview.normalizeText(
        match.group(0) ?? '',
      );
      if (text == selection) return match;
    }
    return null;
  }

  static String _contextualAmountPattern(String sample, RegExpMatch match) {
    final after = sample.substring(match.end).trimLeft();
    final afterWords = _contextWords(after, fromStart: true);
    if (afterWords.isNotEmpty) {
      return '$_amountCorePattern(?=\\s+${_wordsPattern(afterWords)})';
    }

    final before = sample.substring(0, match.start).trimRight();
    final separator = RegExp(r'[-:]+$').firstMatch(before)?.group(0);
    if (separator != null && separator.isNotEmpty) {
      return '${_literalPattern(separator)}\\s*$_amountCorePattern';
    }

    final beforeWords = _contextWords(before, fromStart: false);
    if (beforeWords.isNotEmpty) {
      return '${_wordsPattern(beforeWords)}\\s+$_amountCorePattern';
    }
    return _amountCorePattern;
  }

  static List<String> _contextWords(String value, {required bool fromStart}) {
    final words = value
        .split(RegExp(r'\s+'))
        .map(_cleanToken)
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    return fromStart
        ? words.take(2).toList(growable: false)
        : words.skip(words.length > 2 ? words.length - 2 : 0).toList();
  }

  static String _wordsPattern(List<String> words) {
    return words.map(_literalPattern).join(r'\s+');
  }

  static String _literalPattern(String value) {
    final buffer = StringBuffer();
    for (final codePoint in value.runes) {
      final char = String.fromCharCode(codePoint);
      if (r'\^$.*+?()[]{}|'.contains(char)) {
        buffer.write('\\$char');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static String _cleanToken(String value) {
    return value.replaceAll(
      RegExp(r'^[\s:;,.!?()\[\]{}]+|[\s:;,.!?()\[\]{}]+$'),
      '',
    );
  }
}

class NotificationTrainingToken {
  const NotificationTrainingToken(this.text);

  final String text;

  static List<NotificationTrainingToken> fromSample(String sample) {
    final normalized = NotificationParserPreview.normalizeText(sample);
    if (normalized.isEmpty) return const [];
    final values = <String>[];
    void add(String value) {
      final cleaned = value.trim().replaceAll(RegExp(r'[.]+$'), '');
      if (cleaned.isNotEmpty && !values.contains(cleaned)) values.add(cleaned);
    }

    for (final match in RegExp(
      r'\d[\d\s.,]*(?:\s*(?:Ft|HUF))',
      caseSensitive: false,
    ).allMatches(normalized)) {
      add(match.group(0) ?? '');
    }
    for (final match in RegExp(
      r'itt:\s*(.+?)(?:\.|$)',
      caseSensitive: false,
    ).allMatches(normalized)) {
      add(match.group(1) ?? '');
    }
    for (final match in RegExp(
      r':\s*([^-]+?)\s*-',
      caseSensitive: false,
    ).allMatches(normalized)) {
      add(match.group(1) ?? '');
    }
    for (final part in normalized.split(RegExp(r'\s+'))) {
      final cleaned = NotificationParserProfile._cleanToken(part);
      if (cleaned.isEmpty) continue;
      if (!RegExp(r'^\d').hasMatch(cleaned) &&
          RegExp(r'[A-Za-z0-9À-ž]').hasMatch(cleaned)) {
        add(cleaned);
      }
    }
    return values.map(NotificationTrainingToken.new).toList(growable: false);
  }
}

class NotificationParserRule {
  const NotificationParserRule({
    required this.enabled,
    required this.sampleText,
    required this.includeKeyword,
    required this.amountPattern,
    required this.merchantPattern,
    this.amountSelection = '',
    this.merchantSelection = '',
    this.transactionType = TransactionType.expense,
  });

  final bool enabled;
  final String sampleText;
  final String includeKeyword;
  final String amountPattern;
  final String merchantPattern;
  final String amountSelection;
  final String merchantSelection;
  final TransactionType transactionType;

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
      amountSelection: _stringValue(map['amountSelection'], ''),
      merchantSelection: _stringValue(map['merchantSelection'], ''),
      transactionType: TransactionTypeX.fromAny(map['transactionType']),
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
      'amountSelection': amountSelection,
      'merchantSelection': merchantSelection,
      'transactionType': transactionType.nativeValue,
    };
  }

  NotificationParserRule copyWith({
    bool? enabled,
    String? sampleText,
    String? includeKeyword,
    String? amountPattern,
    String? merchantPattern,
    String? amountSelection,
    String? merchantSelection,
    TransactionType? transactionType,
  }) {
    return NotificationParserRule(
      enabled: enabled ?? this.enabled,
      sampleText: sampleText ?? this.sampleText,
      includeKeyword: includeKeyword ?? this.includeKeyword,
      amountPattern: amountPattern ?? this.amountPattern,
      merchantPattern: merchantPattern ?? this.merchantPattern,
      amountSelection: amountSelection ?? this.amountSelection,
      merchantSelection: merchantSelection ?? this.merchantSelection,
      transactionType: transactionType ?? this.transactionType,
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
    required this.transactionType,
    required this.errorText,
  });

  final String? amountText;
  final double? amountValue;
  final String? merchant;
  final TransactionType transactionType;
  final String? errorText;

  bool get isReady =>
      amountValue != null && merchant != null && errorText == null;

  factory NotificationParserPreview.fromRule(NotificationParserRule rule) {
    final normalized = normalizeText(rule.sampleText);
    try {
      if (normalized.isEmpty) {
        return NotificationParserPreview(
          amountText: null,
          amountValue: null,
          merchant: null,
          transactionType: rule.transactionType,
          errorText: 'Adj meg egy teszt értesítést.',
        );
      }

      final keyword = rule.includeKeyword.trim();
      if (keyword.isNotEmpty &&
          !normalized.toLowerCase().contains(
            normalizeText(keyword).toLowerCase(),
          )) {
        return NotificationParserPreview(
          amountText: null,
          amountValue: null,
          merchant: null,
          transactionType: rule.transactionType,
          errorText: 'A minta nem tartalmazza a megadott kulcsszót.',
        );
      }

      final amountRegex = _compile(rule.amountPattern, 'Összeg regex');
      final merchantRegex = _compile(rule.merchantPattern, 'Bolt regex');
      final amountMatch = amountRegex.firstMatch(normalized);
      final merchantMatch = merchantRegex.firstMatch(normalized);

      final amountCapture = _capture(amountMatch, 'amount');
      final amountValue = _parseAmount(amountCapture);
      final amountText = _amountTextFromMatch(amountMatch, amountCapture);
      final rawMerchant = _capture(merchantMatch, 'merchant')?.trim();
      final merchant = rawMerchant?.isNotEmpty == true
          ? rawMerchant
          : _inferPrefixMerchant(normalized, amountMatch);

      if (amountMatch == null || amountValue == null) {
        return NotificationParserPreview(
          amountText: amountText,
          amountValue: amountValue,
          merchant: merchant?.isEmpty ?? true ? null : merchant,
          transactionType: rule.transactionType,
          errorText: 'Összeg regex nem talált értéket.',
        );
      }
      if (merchant == null || merchant.isEmpty) {
        return NotificationParserPreview(
          amountText: amountText,
          amountValue: amountValue,
          merchant: null,
          transactionType: rule.transactionType,
          errorText: 'Bolt regex nem talált értéket.',
        );
      }

      return NotificationParserPreview(
        amountText: amountText,
        amountValue: amountValue,
        merchant: merchant,
        transactionType: rule.transactionType,
        errorText: null,
      );
    } on _ParserRuleException catch (error) {
      return NotificationParserPreview(
        amountText: null,
        amountValue: null,
        merchant: null,
        transactionType: rule.transactionType,
        errorText: error.message,
      );
    }
  }

  static String? _inferPrefixMerchant(String text, RegExpMatch? amountMatch) {
    if (amountMatch == null) return null;
    final beforeAmount = text.substring(0, amountMatch.start).trim();
    final colon = beforeAmount.lastIndexOf(':');
    if (colon <= 0) return null;
    final candidate = beforeAmount.substring(0, colon).trim();
    if (candidate.isEmpty || candidate.length > 80) return null;
    if (!RegExp(r'[A-Za-z0-9À-ž]').hasMatch(candidate)) return null;
    return candidate.replaceAll(RegExp(r'^[\s:;,.]+|[\s:;,.]+$'), '');
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

  static String? _amountTextFromMatch(RegExpMatch? match, String? capture) {
    if (capture == null) return null;
    final normalizedCapture = normalizeText(capture);
    final full = normalizeText(match?.group(0) ?? normalizedCapture);
    final start = full.toLowerCase().lastIndexOf(
      normalizedCapture.toLowerCase(),
    );
    if (start < 0) return normalizedCapture;

    final suffix = full.substring(start);
    final amountWithCurrency = RegExp(
      r'^\d[\d\s.,]*(?:\s*(?:Ft|HUF))?',
      caseSensitive: false,
    ).firstMatch(suffix);
    return normalizeText(amountWithCurrency?.group(0) ?? normalizedCapture);
  }

  static double? _parseAmount(String? raw) {
    if (raw == null) return null;
    var cleaned = normalizeText(raw).replaceAll(RegExp(r'[^0-9,\.]'), '');
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

  static String normalizeText(String value) {
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
