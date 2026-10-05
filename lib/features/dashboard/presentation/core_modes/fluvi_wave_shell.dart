part of 'fluvi_topographic_wave_chart.dart';

/// A projected point and two-sided normal of the chart-local open shell.
@immutable
final class FluviWaveShellPoint {
  const FluviWaveShellPoint(this.position, this.normal);

  final Offset position;
  final (double, double, double) normal;
}

/// One swept, curved surface anchored to the exact financial ridge.
///
/// The second parameter is visual depth, never another financial series.
/// Mesh, material lookup and contours all sample this same parameterization.
final class FluviWaveShell {
  FluviWaveShell({
    required this.ridge,
    required this.plot,
    required this.depth,
  }) {
    final columns = ridge.length;
    _positions = Float32List(columns * rows * 2);
    _normals = Float32List(columns * rows * 3);
    final colors = Int32List(columns * rows);
    for (var column = 0; column < columns; column++) {
      for (var row = 0; row < rows; row++) {
        final v = row / (rows - 1);
        final point = sample(column, v);
        final index = column * rows + row;
        _positions[index * 2] = point.position.dx;
        _positions[index * 2 + 1] = point.position.dy;
        _normals[index * 3] = point.normal.$1;
        _normals[index * 3 + 1] = point.normal.$2;
        _normals[index * 3 + 2] = point.normal.$3;
        colors[index] = _FluviWaveMaterial.color(v, point.normal).toARGB32();
      }
    }
    _indices = Uint16List((columns - 1) * (rows - 1) * 6);
    var write = 0;
    // Far depth first: the near outer turn occludes the recessed return.
    for (var row = rows - 2; row >= 0; row--) {
      for (var column = 0; column < columns - 1; column++) {
        final a = column * rows + row;
        final b = (column + 1) * rows + row;
        for (final index in [a, b, a + 1, b, b + 1, a + 1]) {
          _indices[write++] = index;
        }
      }
    }
    mesh = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      colors: colors,
      indices: _indices,
    );
  }

  static const rows = 32;
  final List<Offset> ridge;
  final Rect plot;
  final double depth;
  late final Float32List _positions;
  late final Float32List _normals;
  late final Uint16List _indices;
  late final ui.Vertices mesh;

  int get vertexCount => ridge.length * rows;

  static const _heightTurn = .70;
  static const _heightReturn = .14;
  static const _cameraShear = .08;
  static double depthFor(Size size) => math.min(52.0, size.width * .17);

  static double horizontalInsetFor(Size size, double maxAmplitude) =>
      depthFor(size) +
      _cameraShear * maxAmplitude * (_heightTurn + _heightReturn);

  /// Samples the financial column through the rounded outer turn and return.
  FluviWaveShellPoint sample(int column, double v) {
    final point = ridge[column];
    final u = (point.dx - plot.left) / plot.width;
    final amplitude = math.max(
      0.0,
      FluviTopographicWaveTerrain._baselineFor(plot) - point.dy,
    );
    final angle = math.pi * v;
    final bend = math.sin(angle) * math.sin(angle);
    final bendDerivative = 2 * math.pi * math.sin(angle) * math.cos(angle);
    final sweep = math.sin(angle / 2);
    final sweepDerivative = math.pi / 2 * math.cos(angle / 2);
    final heightFall = _heightTurn * bend + _heightReturn * v;
    final heightDerivative = _heightTurn * bendDerivative + _heightReturn;
    final foreshortening = 1 - .20 * u;
    final position = Offset(
      point.dx +
          depth * foreshortening * sweep +
          _cameraShear * amplitude * heightFall,
      point.dy + plot.height * (.27 * bend + .18 * v) + amplitude * heightFall,
    );

    // Oblique camera shear also moves falling height to screen-right. Without
    // this, the visible outer turn becomes a vertical curtain even when the
    // far endpoint is displaced. Exact financial positions remain S(x,0).
    // These are derivatives of the projected surface S(x,v), not a separate
    // same-screen-x material height field.
    final slope = FluviTopographicWaveTerrain._slopeAt(ridge, column);
    final xu =
        1 -
        .20 * depth / plot.width * sweep -
        _cameraShear * slope * heightFall;
    final yu = slope * (1 - heightFall);
    final xv =
        depth * foreshortening * sweepDerivative +
        _cameraShear * amplitude * heightDerivative;
    final yv =
        plot.height * (.27 * bendDerivative + .18) +
        amplitude * heightDerivative;
    // Depth is foreshortened by the oblique view; lighting uses its physical
    // length as well as the projected tangents, avoiding a flat front normal.
    final physicalDepth = depth * 3;
    var nx = -yu * physicalDepth;
    var ny = xu * physicalDepth;
    var nz = yu * xv - xu * yv;
    if (nz < 0) {
      nx = -nx;
      ny = -ny;
      nz = -nz;
    }
    final length = math.sqrt(nx * nx + ny * ny + nz * nz);
    return FluviWaveShellPoint(position, (
      nx / length,
      ny / length,
      nz / length,
    ));
  }

  // Attribute pixels, not a chart bitmap: RG carries the projected normal,
  // B carries section depth, A carries geometric coverage. They are generated
  // only for a new shader terrain and follow the same triangle ordering.
  ui.Vertices attributeMesh() {
    final colors = Int32List(vertexCount);
    for (var index = 0; index < vertexCount; index++) {
      colors[index] = Color.fromARGB(
        255,
        ((_normals[index * 3] * .5 + .5) * 255).round().clamp(0, 255),
        ((_normals[index * 3 + 1] * .5 + .5) * 255).round().clamp(0, 255),
        (index % rows / (rows - 1) * 255).round(),
      ).toARGB32();
    }
    return ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      colors: colors,
      indices: _indices,
    );
  }

  // Used for diagnostic silhouette/compatibility only. Every triangle has
  // positive winding, so folded overlapping pieces do not cancel each other.
  Path silhouette() {
    final path = Path();
    for (var i = 0; i < _indices.length; i += 3) {
      Offset point(int index) =>
          Offset(_positions[index * 2], _positions[index * 2 + 1]);
      final a = point(_indices[i]);
      var b = point(_indices[i + 1]);
      var c = point(_indices[i + 2]);
      if ((b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx) < 0) {
        final previous = b;
        b = c;
        c = previous;
      }
      path
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();
    }
    return path;
  }
}
