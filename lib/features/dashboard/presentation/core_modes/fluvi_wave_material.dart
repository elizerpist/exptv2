part of 'fluvi_topographic_wave_chart.dart';

/// One palette/light policy for CPU mesh and fragment material. GPU constants
/// are uniforms from here, not a second palette. Both routes evaluate the
/// same height field, with x/y measured in logical pixels:
/// z(x,y) = roundness * (foot(x)-ridge(x)) * sin(pi * depth(x,y)).
/// Its analytic derivatives vary across AND down the surface. Financial ridge
/// coordinates are inputs; lighting never moves a datum.
abstract final class _FluviWaveMaterial {
  static const roundness = .28;
  // The sheet spans a wider physical x axis than its projected screen width.
  // Convert both partial derivatives to the same material-space units.
  static const horizontalUnit = 2.5;
  static const light = (-.6, -.7, 1.6);
  static const colors = [
    FluviTopographicWavePalette.deepViolet,
    FluviTopographicWavePalette.violet,
    FluviTopographicWavePalette.pearl,
    FluviTopographicWavePalette.periwinkle,
    FluviTopographicWavePalette.mist,
  ];

  static double smooth(double lo, double hi, double value) {
    final t = ((value - lo) / (hi - lo)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static (double, double, double) normal(
    double depth,
    double ridgeSlope,
    double footSlope,
  ) {
    final derivativeDepth = math.pi * math.cos(math.pi * depth);
    final derivativeWidth = footSlope - ridgeSlope;
    final zx =
        roundness *
        (derivativeWidth * math.sin(math.pi * depth) -
            derivativeDepth * (ridgeSlope + depth * derivativeWidth));
    final zy = roundness * derivativeDepth;
    final materialX = zx / horizontalUnit;
    final length = math.sqrt(materialX * materialX + zy * zy + 1);
    return (-materialX / length, -zy / length, 1 / length);
  }

  static Color color(double depth, double ridgeSlope, double footSlope) {
    final n = normal(depth, ridgeSlope, footSlope);
    final lightLength = math.sqrt(
      light.$1 * light.$1 + light.$2 * light.$2 + light.$3 * light.$3,
    );
    final l = (
      light.$1 / lightLength,
      light.$2 / lightLength,
      light.$3 / lightLength,
    );
    final diffuse = (n.$1 * l.$1 + n.$2 * l.$2 + n.$3 * l.$3).clamp(0.0, 1.0);
    final halfLength = math.sqrt(
      l.$1 * l.$1 + l.$2 * l.$2 + (l.$3 + 1) * (l.$3 + 1),
    );
    final specular = math
        .pow(
          math.max(
            0.0,
            (n.$1 * l.$1 + n.$2 * l.$2 + n.$3 * (l.$3 + 1)) / halfLength,
          ),
          10,
        )
        .toDouble();
    var result = Color.lerp(
      colors[0],
      colors[1],
      .68 + .32 * smooth(.10, .95, diffuse),
    )!;
    result = Color.lerp(
      result,
      colors[2],
      specular * .32 + math.exp(-depth * 48) * .12,
    )!;
    result = Color.lerp(result, colors[3], smooth(.12, .90, depth) * .85)!;
    result = Color.lerp(result, colors[4], smooth(.55, 1, depth) * .75)!;
    return result.withValues(alpha: .98 * (1 - smooth(.52, 1, depth)));
  }

  static void bind(ui.FragmentShader shader) {
    var index = 7;
    for (final color in colors) {
      shader.setFloat(index++, color.r);
      shader.setFloat(index++, color.g);
      shader.setFloat(index++, color.b);
    }
    shader.setFloat(index++, light.$1);
    shader.setFloat(index++, light.$2);
    shader.setFloat(index++, light.$3);
    shader.setFloat(index++, roundness);
    shader.setFloat(index++, _FluviWaveSurfaceTexture.width.toDouble());
    shader.setFloat(index++, horizontalUnit);
  }
}
