part of 'fluvi_topographic_wave_chart.dart';

// One palette/light policy for both rendering routes. Normals come from the
// actual projected shell tangents; material never reconstructs a height field.
abstract final class _FluviWaveMaterial {
  static const light = (-.6, -.7, 1.6);
  static const coating = (.72, 5.0, .32, .7);
  static const turn = (.98, .25, .80, .45);
  static const inner = (.55, .90, .90, .97);
  static const turnFacingFloor = .85;
  static const turnBand = (.06, .40, .62, .96);
  static const grazing = (.12, .50, 1.4, .95);
  static final lightLength = math.sqrt(
    light.$1 * light.$1 + light.$2 * light.$2 + light.$3 * light.$3,
  );
  static final l = (
    light.$1 / lightLength,
    light.$2 / lightLength,
    light.$3 / lightLength,
  );
  static final halfLength = math.sqrt(
    l.$1 * l.$1 + l.$2 * l.$2 + (l.$3 + 1) * (l.$3 + 1),
  );
  static const colors = [
    FluviTopographicWavePalette.deepViolet,
    FluviTopographicWavePalette.violet,
    FluviTopographicWavePalette.pearl,
    FluviTopographicWavePalette.periwinkle,
    FluviTopographicWavePalette.mist,
    FluviTopographicWavePalette.icyBlue,
  ];

  static double smooth(double lo, double hi, double value) {
    final t = ((value - lo) / (hi - lo)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  static Color color(double depth, (double, double, double) n) {
    final diffuse = (n.$1 * l.$1 + n.$2 * l.$2 + n.$3 * l.$3).clamp(0.0, 1.0);
    final specular = math
        .pow(
          math.max(
            0.0,
            (n.$1 * l.$1 + n.$2 * l.$2 + n.$3 * (l.$3 + 1)) / halfLength,
          ),
          coating.$2,
        )
        .toDouble();
    var result = Color.lerp(
      colors[0],
      colors[1],
      coating.$1 + (1 - coating.$1) * diffuse,
    )!;
    result = Color.lerp(result, colors[2], specular * coating.$3)!;
    final turningLight =
        math
            .pow(
              turnFacingFloor + (1 - turnFacingFloor) * n.$2.abs(),
              coating.$4,
            )
            .toDouble() *
        smooth(turnBand.$1, turnBand.$2, depth) *
        (1 - smooth(turnBand.$3, turnBand.$4, depth));
    result = Color.lerp(result, colors[5], turningLight * turn.$1)!;
    result = Color.lerp(
      result,
      colors[3],
      smooth(turn.$2, turn.$3, depth) * turn.$4,
    )!;
    result = Color.lerp(
      result,
      colors[4],
      smooth(inner.$1, inner.$2, depth) * inner.$3,
    )!;
    // A broad, soft highlight at the actual tangent silhouette makes the
    // rounded turn recede into the light material, without translucent layers.
    final grazingLight =
        math.pow(1 - n.$3.abs(), grazing.$3).toDouble() *
        smooth(grazing.$1, grazing.$2, depth) *
        grazing.$4;
    result = Color.lerp(result, colors[2], grazingLight)!;
    return result.withValues(alpha: 1 - smooth(inner.$4, 1, depth));
  }

  static void bind(ui.FragmentShader shader) {
    var index = 3;
    for (final color in colors) {
      shader.setFloat(index++, color.r);
      shader.setFloat(index++, color.g);
      shader.setFloat(index++, color.b);
    }
    shader.setFloat(index++, light.$1);
    shader.setFloat(index++, light.$2);
    shader.setFloat(index++, light.$3);
    for (final group in [coating, turn, inner]) {
      shader.setFloat(index++, group.$1);
      shader.setFloat(index++, group.$2);
      shader.setFloat(index++, group.$3);
      shader.setFloat(index++, group.$4);
    }
    shader.setFloat(index++, turnFacingFloor);
    shader.setFloat(index++, turnBand.$1);
    shader.setFloat(index++, turnBand.$2);
    shader.setFloat(index++, turnBand.$3);
    shader.setFloat(index++, turnBand.$4);
    shader.setFloat(index++, grazing.$1);
    shader.setFloat(index++, grazing.$2);
    shader.setFloat(index++, grazing.$3);
    shader.setFloat(index++, grazing.$4);
  }
}
