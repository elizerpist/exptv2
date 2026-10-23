import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const monthImpactGoldenNames = {
  'balance_day_four_avatar_selector.png',
  'balance_day_month_impact_positive_decrease.png',
  'balance_day_month_impact_crossed_positive.png',
  'balance_day_month_impact_crossed_negative.png',
  'balance_day_month_impact_negative_improvement.png',
  'balance_day_month_impact_neutral.png',
  'balance_day_month_impact_unavailable.png',
  'balance_day_month_impact_compact.png',
  'balance_day_month_impact_dashboard.png',
};

// Measured bbe9d5b2 ARM64/x64 evidence: five single-channel units in the
// 390x400 ribbon (179,213), (281,230), (297,231), (298,231), (343,241);
// three in the real 378x356 MotherCard (209,188), (88,203), (89,203).
// Only these new references allow <=8 total RGB quantization units within
// the ribbon's normalized bounds. Alpha, typography, selector and rail stay
// exact; this is never a global percentage or color-distance threshold.
bool acceptsMonthImpactRaster({
  required Uint8List actual,
  required Uint8List reference,
  required int width,
  required int height,
}) {
  if (actual.length != reference.length ||
      actual.length != width * height * 4) {
    return false;
  }
  var units = 0;
  for (var i = 0; i < actual.length; i += 4) {
    for (var channel = 0; channel < 4; channel++) {
      final delta = (actual[i + channel] - reference[i + channel]).abs();
      if (delta == 0) continue;
      final x = (i ~/ 4) % width, y = i ~/ 4 ~/ width;
      if (channel == 3 ||
          delta > 1 ||
          x < width * .04 ||
          x > width * .96 ||
          y < height * .45 ||
          y > height * .74 ||
          ++units > 8) {
        return false;
      }
    }
  }
  return true;
}

Future<bool> matchesMonthImpactRaster(
  Uint8List bytes,
  Uint8List referenceBytes,
  Uri golden,
) async {
  if (!monthImpactGoldenNames.contains(golden.pathSegments.last)) return false;
  final aCodec = await ui.instantiateImageCodec(bytes);
  final bCodec = await ui.instantiateImageCodec(referenceBytes);
  final a = (await aCodec.getNextFrame()).image;
  final b = (await bCodec.getNextFrame()).image;
  aCodec.dispose();
  bCodec.dispose();
  try {
    if (a.width != b.width || a.height != b.height) return false;
    final actual = (await a.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final reference = (await b.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final accepted = acceptsMonthImpactRaster(
      actual: actual,
      reference: reference,
      width: a.width,
      height: a.height,
    );
    var units = 0;
    for (var i = 0; i < actual.length; i++) {
      units += (actual[i] - reference[i]).abs();
    }
    if (units > 0) {
      debugPrint('Month impact raster: units=$units accepted=$accepted');
    }
    return accepted;
  } finally {
    a.dispose();
    b.dispose();
  }
}

final class MonthImpactRasterComparator extends LocalFileComparator {
  MonthImpactRasterComparator(super.testFile);
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    if (monthImpactGoldenNames.contains(golden.pathSegments.last) &&
        await matchesMonthImpactRaster(
          imageBytes,
          Uint8List.fromList(await getGoldenBytes(golden)),
          golden,
        )) {
      return true;
    }
    return super.compare(imageBytes, golden);
  }
}
