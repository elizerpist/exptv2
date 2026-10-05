#include <flutter/runtime_effect.glsl>

// Bounded 2.5D material for the real Balance Month spending ridge. The Dart
// side supplies a cached 1-D texture: red=ridge Y, green=local material foot,
// blue=local ridge slope. The financial curve is never displaced here; the
// shader only shades the already-clipped material surface.
uniform vec2 uSize;
uniform float uOpacity;
uniform vec4 uPlot;
uniform sampler2D uCurveTexture;

vec3 ramp(float depth) {
  vec3 pearl = vec3(0.984, 0.980, 1.0);
  vec3 top = vec3(0.718, 0.671, 1.0);
  vec3 shade = vec3(0.447, 0.361, 0.831);
  vec3 body = vec3(0.580, 0.510, 0.949);
  vec3 periwinkle = vec3(0.784, 0.773, 0.980);
  vec3 ice = vec3(0.863, 0.922, 0.980);
  vec3 mist = vec3(0.961, 0.969, 1.0);
  if (depth < .04) return mix(pearl, top, depth / .04);
  if (depth < .16) return mix(top, shade, (depth - .04) / .12);
  if (depth < .52) return mix(shade, body, (depth - .16) / .36);
  if (depth < .84) return mix(body, ice, (depth - .52) / .32);
  return mix(ice, mist, (depth - .84) / .16);
}

out vec4 fragColor;

void main() {
  // The lookup is encoded in the actual padded data plot, not in the outer
  // CustomPaint bounds. Keeping that coordinate space explicit guarantees
  // that the material's local ridge/foot interpolation matches Canvas.
  vec2 local = (FlutterFragCoord().xy - uPlot.xy) / max(uPlot.zw, vec2(1.0));
  vec4 curve = texture(uCurveTexture, vec2(clamp(local.x, 0.0, 1.0), .5));
  float ridge = curve.r;
  float foot = max(ridge + .002, curve.g);
  float depth = clamp((local.y - ridge) / (foot - ridge), 0.0, 1.0);
  float slope = curve.b * 2.0 - 1.0;

  // Normal approximates a left/top/front light falling across the locally
  // sampled material. The bright rim stays near v=0; volumetric light comes
  // from the filled body, not a broad glowing chart line.
  vec3 normal = normalize(vec3(-slope * 2.0, -0.95, .72));
  vec3 light = normalize(vec3(-.42, -.76, .64));
  float diffuse = clamp(dot(normal, light), .18, 1.0);
  float fresnel = pow(1.0 - clamp(normal.z, 0.0, 1.0), 2.0) * .18;
  float pixelScale = 1.0 / max(1.0, min(uSize.x, uSize.y));
  float ridgeBand = exp(-depth * (25.0 + pixelScale)) * .24;
  float occlusion = smoothstep(.02, .28, depth) * (1.0 - depth) * .12;
  vec3 color = ramp(depth);
  color = mix(color * .72, color * 1.12, diffuse);
  color += vec3(.15, .13, .22) * (fresnel + ridgeBand - occlusion);
  float alpha = pow(1.0 - depth, .58) * .94 * uOpacity;
  fragColor = vec4(color * alpha, alpha);
}
