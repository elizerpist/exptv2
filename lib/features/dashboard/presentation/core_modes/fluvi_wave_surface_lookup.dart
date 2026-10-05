part of 'fluvi_topographic_wave_chart.dart';

// A cached 2D attribute atlas of the projected triangles, not two same-x
// boundaries. Dynamic normal/depth/coverage data is generated from this terrain
// only. The State still owns publication, identity guards and image disposal.
final class _FluviWaveSurfaceTexture {
  const _FluviWaveSurfaceTexture._(this.image);
  final ui.Image image;

  static Future<_FluviWaveSurfaceTexture> fromTerrain(
    FluviTopographicWaveTerrain terrain,
  ) async {
    final scale = math.min(
      2.0,
      1024 / math.max(terrain.size.width, terrain.size.height),
    );
    final width = math.max(1, (terrain.size.width * scale).ceil());
    final height = math.max(1, (terrain.size.height * scale).ceil());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(width / terrain.size.width, height / terrain.size.height);
    final shell = terrain.shell;
    if (shell != null) {
      canvas.drawVertices(
        shell.attributeMesh(),
        BlendMode.dst,
        Paint()..isAntiAlias = true,
      );
    }
    final picture = recorder.endRecording();
    try {
      return _FluviWaveSurfaceTexture._(await picture.toImage(width, height));
    } finally {
      picture.dispose();
    }
  }
}
