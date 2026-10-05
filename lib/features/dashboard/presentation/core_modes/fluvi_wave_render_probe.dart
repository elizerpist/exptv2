part of 'fluvi_topographic_wave_chart.dart';

/// Opt-in forensic scene. No controls or decoration enter the normal UI.
/// Resource factories let tests delay the real production resource owner.
final class FluviWaveDebugScope extends InheritedWidget {
  const FluviWaveDebugScope({
    super.key,
    required super.child,
    this.opaqueBody = false,
    this.materialOnly = false,
    this.bounds = false,
    this.glow = true,
    this.contours = true,
    this.onPaint,
    this.textureLoader,
    this.programLoader,
  });

  final bool opaqueBody;
  final bool materialOnly;
  final bool bounds;
  final bool glow;
  final bool contours;
  final ValueChanged<FluviWaveRenderMetrics>? onPaint;
  final Future<ui.Image> Function(FluviTopographicWaveTerrain)? textureLoader;
  final Future<ui.FragmentProgram> Function()? programLoader;

  static FluviWaveDebugScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluviWaveDebugScope>();

  @visibleForTesting
  static Future<ui.Image> createTexture(FluviTopographicWaveTerrain terrain) =>
      _FluviWaveSurfaceTexture.fromTerrain(
        terrain,
      ).then((value) => value.image);

  @override
  bool updateShouldNotify(FluviWaveDebugScope oldWidget) =>
      opaqueBody != oldWidget.opaqueBody ||
      materialOnly != oldWidget.materialOnly ||
      bounds != oldWidget.bounds ||
      glow != oldWidget.glow ||
      contours != oldWidget.contours ||
      onPaint != oldWidget.onPaint ||
      textureLoader != oldWidget.textureLoader ||
      programLoader != oldWidget.programLoader;
}

/// Bounded counters belonging to the chart State, not a second cache/authority.
/// Observers read them; no notifier or per-paint history is retained.
final class FluviWaveRenderMetrics {
  int geometryBuilds = 0;
  int geometryMicros = 0;
  int textureRequests = 0;
  int texturePublications = 0;
  int textureDisposals = 0;
  int textureMicros = 0;
  int paints = 0;
  String shaderState = 'not-requested';
  String? shaderError;
  String route = 'empty';
  FluviTopographicWaveTerrain? terrain;
  FluviTopographicWaveTerrain? textureTerrain;
  Rect? markerBounds;
  Rect? tooltipBounds;
  int? selectedIndex;
  int? selectedKey;
  int? selectedValueMinor;
  String? tooltipText;
  Stopwatch? lookupRequested;
  int? lookupRequestToPaintMicros;
  bool disposed = false;
  String? _lastPublication;

  Map<String, Object?> snapshot() => <String, Object?>{
    'geometryId': terrain == null ? null : identityHashCode(terrain!),
    'textureGeometryId': textureTerrain == null
        ? null
        : identityHashCode(textureTerrain!),
    'size': '${terrain?.size}',
    'clip': '${terrain == null ? null : Offset.zero & terrain!.size}',
    'plot': '${terrain?.plot}',
    'financialBaseline': terrain?.financialBaseline,
    'shellVertices': terrain?.shell?.vertexCount ?? 0,
    'projectedDepth': terrain?.shell?.depth,
    'styleRoute': route,
    'shaderState': shaderState,
    'shaderError': shaderError,
    'geometryBuilds': geometryBuilds,
    'geometryMicros': geometryMicros,
    'textureRequests': textureRequests,
    'texturePublications': texturePublications,
    'textureDisposals': textureDisposals,
    'textureMicros': textureMicros,
    'paints': paints,
    'selectedIndex': selectedIndex,
    'selectedKey': selectedKey,
    'selectedValueMinor': selectedValueMinor,
    'tooltipText': tooltipText,
    'lookupRequestToPaintMicros': lookupRequestToPaintMicros,
    'markerBounds': '$markerBounds',
    'tooltipBounds': '$tooltipBounds',
    'disposed': disposed,
  };

  void recordPaint(FluviTopographicWaveTerrain current, String path) {
    terrain = current;
    route = path;
    paints++;
    if (path == 'shader' && lookupRequested != null) {
      lookupRequestToPaintMicros = lookupRequested!.elapsedMicroseconds;
      lookupRequested = null;
    }
    if (!kFluviOnscreenDiagnosticsEnabled) return;
    final identity =
        '${identityHashCode(current)}:$path:${identityHashCode(textureTerrain)}:$shaderState';
    if (_lastPublication == identity) return;
    _lastPublication = identity;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BALANCE_MONTH_WAVE_PAINT',
        message:
            'geometry=${identityHashCode(current)} route=$path '
            'textureGeometry=${identityHashCode(textureTerrain)} '
            'size=${current.size} baseline=${current.financialBaseline} '
            'shader=$shaderState',
        error: shaderError,
      ),
    );
  }
}
