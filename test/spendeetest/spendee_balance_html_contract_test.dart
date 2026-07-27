import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_b3ma3_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'frozen source SHA and final cascade declarations are authoritative',
    () {
      final source = File('balance_latest_layout.html').readAsStringSync();
      final parsed = BalanceHtmlContractParser.parse(source);

      expect(parsed.sha256, SpendeeBalanceB3mA3Manifest.sourceSha256);
      expect(
        parsed.finalValue('.stage2-redesign-insight-grid', 'height'),
        '128px',
      );
      expect(
        parsed.valuesFor('.stage2-redesign-top-categories-detail', 'height'),
        containsAll(<String>['208px', '248px']),
      );
      expect(
        parsed.finalValue('.stage2-redesign-top-categories-detail', 'height'),
        '208px',
      );
      expect(SpendeeBalanceV3DetailResolution.finalCardHeight, 248);
      expect(SpendeeBalanceV3DetailResolution.detailStageHeight, 258);
      expect(SpendeeBalanceB3mA3Manifest.v3Metrics, isNotEmpty);
    },
  );

  test('FastInfo manifest height resolves the frozen final cascade', () {
    expect(SpendeeBalanceB3mA3Manifest.fastInfoHeight, 128);
  });

  test('detail-card manifest height resolves the final specific cascade', () {
    expect(
      SpendeeBalanceB3mA3Manifest.detailCardHeight,
      same(SpendeeBalanceV3DetailResolution.finalCardHeight),
    );
    expect(SpendeeBalanceB3mA3Manifest.detailCardHeight, 248);
  });

  test(
    'detail-stage height preserves card, gap, and pagination arithmetic',
    () {
      expect(
        SpendeeBalanceB3mA3Manifest.detailStageHeight,
        same(SpendeeBalanceV3DetailResolution.detailStageHeight),
      );
      expect(
        SpendeeBalanceV3DetailResolution.detailStageHeight,
        SpendeeBalanceV3DetailResolution.finalCardHeight +
            SpendeeBalanceV3DetailResolution.paginationGap +
            SpendeeBalanceV3DetailResolution.paginationHeight,
      );
      expect(SpendeeBalanceB3mA3Manifest.detailStageHeight, 258);
    },
  );

  test('a changed final declaration is rejected', () {
    final frozenHtml = File('balance_latest_layout.html').readAsStringSync();
    final changed = frozenHtml.replaceFirst(
      '''.stage2-redesign-detail-stage .stage2-redesign-today-detail {
            height: 248px;''',
      '''.stage2-redesign-detail-stage .stage2-redesign-today-detail {
            height: 247px;''',
    );

    expect(
      () => BalanceHtmlContractParser.parseAndVerify(
        changed,
        expectedSha256: _sha256(changed),
      ),
      throwsA(
        isA<BalanceHtmlContractError>().having(
          (error) => error.message,
          'message',
          contains('.stage2-redesign-today-detail height'),
        ),
      ),
    );
  });

  test('the unchanged frozen source satisfies every declared metric', () {
    final frozenHtml = File('balance_latest_layout.html').readAsStringSync();
    expect(BalanceHtmlContractParser.parseAndVerify(frozenHtml), isNotNull);
  });

  test(
    'later applicable declaration, not an earlier value, is authoritative',
    () {
      const metric = BalanceHtmlMetric(
        name: 'fixture',
        selector: '.fixture-card',
        lineRange: (start: 1, end: 8),
        declarations: {
          'height': ['248px'],
        },
        finalValue: '248px',
      );
      const source =
          '.fixture-card { height: 248px; }\n'
          '.fixture-card { height: 247px; }';

      expect(
        () => BalanceHtmlContractParser.verifyMetrics(source, [metric]),
        throwsA(isA<BalanceHtmlContractError>()),
      );
    },
  );

  test('superstring selectors are not applicable declarations', () {
    const metric = BalanceHtmlMetric(
      name: 'fixture',
      selector: '.fixture-card',
      lineRange: (start: 1, end: 4),
      declarations: {
        'height': ['248px'],
      },
      finalValue: '248px',
    );
    const source =
        '.fixture-card-extra { height: 247px; }\n'
        '.fixture-card { height: 248px; }';

    expect(
      BalanceHtmlContractParser.verifyMetrics(source, [metric]),
      isNotNull,
    );
  });

  test('higher specificity survives a later lower-specificity declaration', () {
    const source =
        '.scope .fixture-card { height: 248px; }\n'
        '.fixture-card { height: 247px; }';
    expect(
      BalanceHtmlContractParser.parse(
        source,
      ).finalValue('.fixture-card', 'height', lineRange: (start: 1, end: 2)),
      '248px',
    );
  });
}

class BalanceHtmlContractError extends Error {
  BalanceHtmlContractError(this.message);

  final String message;

  @override
  String toString() => 'BalanceHtmlContractError: $message';
}

class BalanceHtmlContract {
  const BalanceHtmlContract(this.sha256, this._source);

  final String sha256;
  final String _source;

  List<String> valuesFor(
    String selector,
    String declaration, {
    ({int start, int end})? lineRange,
  }) {
    final candidates = <({String value, int specificity, int order})>[];
    final lines = _source.split('\n');
    final start = (lineRange?.start ?? 1) - 1;
    final end = lineRange?.end ?? lines.length;
    for (var index = start; index < end && index < lines.length; index++) {
      var rule = lines[index];
      while (!rule.contains('{') && index + 1 < lines.length) {
        rule += '\n${lines[++index]}';
      }
      if (!rule.contains('{')) continue;
      while (!rule.contains('}') && index + 1 < lines.length) {
        rule += '\n${lines[++index]}';
      }
      if (!_isFrozenScreenRule(rule)) continue;
      final matchedSelector = _matchingSelector(
        rule.substring(0, rule.indexOf('{')),
        selector,
      );
      if (matchedSelector == null) {
        continue;
      }
      final ruleStart = rule.indexOf('{');
      final ruleEnd = rule.indexOf('}', ruleStart);
      if (ruleStart < 0 || ruleEnd < 0) continue;
      for (final found
          in BalanceHtmlContractParser._declarationPattern.allMatches(
            rule.substring(ruleStart + 1, ruleEnd),
          )) {
        if (found.group(1) == declaration) {
          candidates.add((
            value: found.group(2)!.trim(),
            specificity: _specificity(matchedSelector),
            order: index,
          ));
        }
      }
    }
    candidates.sort((left, right) {
      final specificity = left.specificity.compareTo(right.specificity);
      return specificity == 0 ? left.order.compareTo(right.order) : specificity;
    });
    return candidates.map((candidate) => candidate.value).toList();
  }

  String? finalValue(
    String selector,
    String declaration, {
    ({int start, int end})? lineRange,
  }) {
    final values = valuesFor(selector, declaration, lineRange: lineRange);
    return values.isEmpty ? null : values.last;
  }
}

class BalanceHtmlContractParser {
  static final _declarationPattern = RegExp(r'([\w-]+)\s*:\s*([^;]+);');

  static BalanceHtmlContract parse(String source) =>
      BalanceHtmlContract(_sha256(source), source);

  static BalanceHtmlContract parseAndVerify(
    String source, {
    String? expectedSha256,
  }) {
    final parsed = parse(source);
    if (parsed.sha256 !=
        (expectedSha256 ?? SpendeeBalanceB3mA3Manifest.sourceSha256)) {
      throw BalanceHtmlContractError('frozen source SHA-256 changed');
    }
    return verifyMetrics(
      source,
      SpendeeBalanceB3mA3Manifest.v3Metrics,
      expectedSha256: expectedSha256,
    );
  }

  static BalanceHtmlContract verifyMetrics(
    String source,
    Iterable<BalanceHtmlMetric> metrics, {
    String? expectedSha256,
  }) {
    final parsed = parse(source);
    if (expectedSha256 != null && parsed.sha256 != expectedSha256) {
      throw BalanceHtmlContractError('fixture SHA-256 changed');
    }
    for (final metric in metrics) {
      var finalValueWasDeclared = false;
      for (final declaration in metric.declarations.entries) {
        final expected = declaration.value.last;
        if (expected == metric.finalValue) finalValueWasDeclared = true;
        final actualValues = parsed.valuesFor(
          metric.selector,
          declaration.key,
          lineRange: metric.lineRange,
        );
        final actual = actualValues.isEmpty ? null : actualValues.last;
        if (actual != expected) {
          throw BalanceHtmlContractError(
            '${metric.selector} ${declaration.key}: expected $expected, got $actual',
          );
        }
      }
      if (!finalValueWasDeclared) {
        throw BalanceHtmlContractError(
          '${metric.selector}: finalValue ${metric.finalValue} is not declared',
        );
      }
    }
    return parsed;
  }
}

bool _selectorMatches(String ruleLine, String selector) {
  return _matchingSelector(ruleLine, selector) != null;
}

String? _matchingSelector(String ruleLine, String selector) {
  for (final rawSelector in ruleLine.split(',')) {
    final candidate = rawSelector.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (!candidate.endsWith(selector)) continue;
    final prefix = candidate.substring(0, candidate.length - selector.length);
    if (prefix.isEmpty || RegExp(r'[\s>+~]$').hasMatch(prefix)) {
      return candidate;
    }
  }
  return null;
}

int _specificity(String selector) =>
    RegExp(r'\.|\[|:').allMatches(selector).length;

bool _isFrozenScreenRule(String selector) {
  if (!selector.contains('[data-today-redesign-screen="true"]')) {
    return !selector.contains('[data-');
  }
  return !selector.contains('data-today-redesign-density') &&
      !selector.contains('data-budget-') &&
      !selector.contains('data-mind-');
}

String _sha256(String source) {
  const mask = 0xffffffff;
  const k = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];
  final bytes = utf8.encode(source);
  final padded = Uint8List(((bytes.length + 9 + 63) ~/ 64) * 64)
    ..setAll(0, bytes);
  padded[bytes.length] = 0x80;
  final bitLength = bytes.length * 8;
  for (var index = 0; index < 8; index++) {
    padded[padded.length - 1 - index] = (bitLength >>> (index * 8)) & 0xff;
  }
  var h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
  var h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
  int rotateRight(int value, int amount) =>
      ((value >>> amount) | ((value << (32 - amount)) & mask)) & mask;
  for (var offset = 0; offset < padded.length; offset += 64) {
    final words = List<int>.filled(64, 0);
    for (var index = 0; index < 16; index++) {
      final base = offset + index * 4;
      words[index] =
          (padded[base] << 24) |
          (padded[base + 1] << 16) |
          (padded[base + 2] << 8) |
          padded[base + 3];
    }
    for (var index = 16; index < 64; index++) {
      final s0 =
          rotateRight(words[index - 15], 7) ^
          rotateRight(words[index - 15], 18) ^
          (words[index - 15] >>> 3);
      final s1 =
          rotateRight(words[index - 2], 17) ^
          rotateRight(words[index - 2], 19) ^
          (words[index - 2] >>> 10);
      words[index] = (words[index - 16] + s0 + words[index - 7] + s1) & mask;
    }
    var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
    for (var index = 0; index < 64; index++) {
      final s1 = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25);
      final choice = (e & f) ^ ((~e) & g);
      final temp1 = (h + s1 + choice + k[index] + words[index]) & mask;
      final s0 = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22);
      final majority = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + majority) & mask;
      h = g;
      g = f;
      f = e;
      e = (d + temp1) & mask;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & mask;
    }
    h0 = (h0 + a) & mask;
    h1 = (h1 + b) & mask;
    h2 = (h2 + c) & mask;
    h3 = (h3 + d) & mask;
    h4 = (h4 + e) & mask;
    h5 = (h5 + f) & mask;
    h6 = (h6 + g) & mask;
    h7 = (h7 + h) & mask;
  }
  return [
    h0,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    h7,
  ].map((word) => word.toRadixString(16).padLeft(8, '0')).join();
}
