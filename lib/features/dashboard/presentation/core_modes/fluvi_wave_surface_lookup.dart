part of 'fluvi_topographic_wave_chart.dart';

/// Two opaque rows: ridge and foot, each with 16-bit Y in R/G. Opaque alpha
/// avoids premultiplication corrupting encoded data. Samples are located by
/// physical x, not by spline-list index; shader reads the same texel centres.
final class _FluviWaveSurfaceTexture {
  const _FluviWaveSurfaceTexture._(this.image);
  final ui.Image image;
  static const width = 1024;

  static Future<_FluviWaveSurfaceTexture> fromTerrain(
    FluviTopographicWaveTerrain terrain,
  ) {
    final bytes = Uint8List(width * 2 * 4);
    final ridge = terrain.ridgeSamples;
    final feet = terrain.surfaceFootSamples;
    var lower = 0;
    for (var column = 0; column < width; column++) {
      final x = terrain.plot.left + terrain.plot.width * column / (width - 1);
      while (lower < ridge.length - 2 && ridge[lower + 1].dx < x) {
        lower++;
      }
      final upper = math.min(ridge.length - 1, lower + 1);
      final dx = ridge[upper].dx - ridge[lower].dx;
      final t = dx <= 0 ? 0.0 : (x - ridge[lower].dx) / dx;
      for (var row = 0; row < 2; row++) {
        final points = row == 0 ? ridge : feet;
        final y = FluviTopographicWaveTerrain._lerp(
          points[lower].dy,
          points[upper].dy,
          t,
        );
        final encoded = ((y - terrain.plot.top) / terrain.plot.height * 65535)
            .round()
            .clamp(0, 65535);
        final offset = (row * width + column) * 4;
        bytes[offset] = encoded >> 8;
        bytes[offset + 1] = encoded & 255;
        bytes[offset + 3] = 255;
      }
    }
    final result = Completer<_FluviWaveSurfaceTexture>();
    ui.decodeImageFromPixels(
      bytes,
      width,
      2,
      ui.PixelFormat.rgba8888,
      (image) => result.complete(_FluviWaveSurfaceTexture._(image)),
    );
    return result.future;
  }
}
