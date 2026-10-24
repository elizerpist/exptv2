import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'mother_card_raster_comparator.dart';

void main() {
  for (final entry in motherCardRasterEvidence.entries) {
    test(
      '${entry.key} accepts measured rounding but rejects visual changes',
      () {
        final rule = entry.value;
        final reference = Uint8List(rule.width * rule.height * 4)
          ..fillRange(0, rule.width * rule.height * 4, 128);
        final actual = Uint8List.fromList(reference);
        bool accepts({String? filename, int? width}) => acceptsMotherCardRaster(
          filename: filename ?? entry.key,
          actual: actual,
          reference: reference,
          width: width ?? rule.width,
          height: rule.height,
        );
        expect(accepts(), isTrue);
        final pixel = rule.pixels.first;
        actual[pixel * 4]++;
        expect(accepts(), isTrue);
        actual[pixel * 4]++;
        expect(
          accepts(),
          isFalse,
          reason: 'Two-unit color shifts are visible changes.',
        );
        actual.setAll(0, reference);
        actual[pixel * 4 + 3]++;
        expect(accepts(), isFalse, reason: 'Opacity never has a tolerance.');
        actual.setAll(0, reference);
        var outside = 0;
        while (rule.pixels.contains(outside)) {
          outside++;
        }
        actual[outside * 4]++;
        expect(
          accepts(),
          isFalse,
          reason: 'Every unmeasured pixel remains exact.',
        );
        actual.setAll(0, reference);
        for (final position in rule.pixels) {
          for (var channel = 0; channel < 3; channel++) {
            actual[position * 4 + channel]++;
          }
        }
        expect(
          accepts(),
          isFalse,
          reason: 'The total measured budget cannot grow.',
        );
        actual.setAll(0, reference);
        expect(accepts(filename: 'unrelated.png'), isFalse);
        expect(accepts(width: rule.width + 1), isFalse);
      },
    );
  }
}
