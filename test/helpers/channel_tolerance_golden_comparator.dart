import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class ChannelToleranceGoldenComparator extends LocalFileComparator {
  ChannelToleranceGoldenComparator(
    super.testFile, {
    required this.maxChannelDelta,
  }) : assert(maxChannelDelta >= 0 && maxChannelDelta <= 255);

  final int maxChannelDelta;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = Uint8List.fromList(await getGoldenBytes(golden));
    if (listEquals(imageBytes, goldenBytes)) return true;

    final actual = await _decodePng(imageBytes);
    final expected = await _decodePng(goldenBytes);
    final sameSize =
        actual.width == expected.width && actual.height == expected.height;
    final withinTolerance =
        sameSize &&
        countPixelsOutsideChannelTolerance(
              actual.rgba,
              expected.rgba,
              maxChannelDelta: maxChannelDelta,
            ) ==
            0;
    if (withinTolerance) return true;

    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

int countPixelsOutsideChannelTolerance(
  Uint8List actual,
  Uint8List expected, {
  required int maxChannelDelta,
}) {
  if (actual.length != expected.length || actual.length % 4 != 0) return -1;
  var outliers = 0;
  for (var offset = 0; offset < actual.length; offset += 4) {
    var pixelOutsideTolerance = false;
    for (var channel = 0; channel < 4; channel += 1) {
      if ((actual[offset + channel] - expected[offset + channel]).abs() >
          maxChannelDelta) {
        pixelOutsideTolerance = true;
        break;
      }
    }
    if (pixelOutsideTolerance) outliers += 1;
  }
  return outliers;
}

Future<_DecodedPng> _decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        throw StateError('Could not decode golden image as raw RGBA.');
      }
      return _DecodedPng(
        width: image.width,
        height: image.height,
        rgba: byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

class _DecodedPng {
  const _DecodedPng({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final Uint8List rgba;
}
