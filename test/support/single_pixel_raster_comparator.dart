import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// Only the explicitly named reference may differ by one pixel, one channel unit.
// Every other golden remains byte-exact. ARM64/x64 green sphere raster evidence:
// V5 (118,122): [46,252,206,255] vs [45,252,206,255].
// V6 (230,114): [46,254,207,255] vs [45,254,207,255].
final class SinglePixelRasterComparator extends LocalFileComparator {
  SinglePixelRasterComparator(super.testFile, {required this.goldenFilename});
  final String goldenFilename;
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    if (!golden.path.endsWith(goldenFilename)) {
      return super.compare(imageBytes, golden);
    }
    final referenceBytes = Uint8List.fromList(await getGoldenBytes(golden));
    final actualCodec = await ui.instantiateImageCodec(imageBytes);
    final referenceCodec = await ui.instantiateImageCodec(referenceBytes);
    final actual = (await actualCodec.getNextFrame()).image;
    final reference = (await referenceCodec.getNextFrame()).image;
    actualCodec.dispose();
    referenceCodec.dispose();
    var accepted = false;
    try {
      if (actual.width == reference.width &&
          actual.height == reference.height) {
        final a = (await actual.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final b = (await reference.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        var pixels = 0, maximumChannelDelta = 0;
        final evidence = <String>[];
        for (var i = 0; i < a.length; i += 4) {
          var differs = false;
          for (var channel = 0; channel < 4; channel++) {
            final delta = (a[i + channel] - b[i + channel]).abs();
            if (delta != 0) differs = true;
            if (delta > maximumChannelDelta) maximumChannelDelta = delta;
          }
          if (differs) {
            pixels++;
            if (evidence.length < 8) {
              evidence.add(
                '(${(i ~/ 4) % actual.width},${i ~/ 4 ~/ actual.width}) ${a.sublist(i, i + 4)} vs ${b.sublist(i, i + 4)}',
              );
            }
          }
        }
        accepted = pixels <= 1 && maximumChannelDelta <= 1;
        if (pixels != 0) {
          debugPrint(
            'Single-pixel raster evidence: pixels=$pixels maxChannelDelta=$maximumChannelDelta accepted=$accepted $evidence',
          );
        }
      }
    } finally {
      actual.dispose();
      reference.dispose();
    }
    return accepted || await super.compare(imageBytes, golden);
  }
}
