#include <flutter/runtime_effect.glsl>

// Same analytic height field as _FluviWaveMaterial. Palette and lighting
// authority stays in Dart, supplied as uniforms. No invented financial ridge.
uniform vec2 uSize;
uniform float uOpacity;
uniform vec4 uPlot;
uniform vec3 uShade;
uniform vec3 uBody;
uniform vec3 uPearl;
uniform vec3 uPeriwinkle;
uniform vec3 uMist;
uniform vec3 uLight;
uniform float uRoundness;
uniform float uLookupWidth;
uniform float uHorizontalUnit;
uniform sampler2D uCurveTexture;
out vec4 fragColor;

vec2 boundaries(float x) {
  float u = (clamp(x, 0.0, 1.0) * (uLookupWidth - 1.0) + .5) / uLookupWidth;
  vec2 ridge = texture(uCurveTexture, vec2(u, .25)).rg;
  vec2 foot = texture(uCurveTexture, vec2(u, .75)).rg;
  return vec2(dot(ridge, vec2(65280.0, 255.0)), dot(foot, vec2(65280.0, 255.0))) / 65535.0;
}

void main() {
  vec2 local = (FlutterFragCoord().xy - uPlot.xy) / uPlot.zw;
  vec2 curve = boundaries(local.x);
  if (curve.y <= curve.x) { fragColor = vec4(0.0); return; }
  float depth = clamp((local.y - curve.x) / (curve.y - curve.x), 0.0, 1.0);
  float stepX = 1.0 / (uLookupWidth - 1.0);
  float lo = max(0.0, local.x - stepX);
  float hi = min(1.0, local.x + stepX);
  vec2 slopes = (boundaries(hi) - boundaries(lo)) * uPlot.w / ((hi - lo) * uPlot.z);
  float dw = slopes.y - slopes.x;
  float dd = 3.14159265359 * cos(3.14159265359 * depth);
  float zx = uRoundness * (dw * sin(3.14159265359 * depth) - dd * (slopes.x + depth * dw));
  float zy = uRoundness * dd;
  vec3 normal = normalize(vec3(-zx / uHorizontalUnit, -zy, 1.0));
  vec3 light = normalize(uLight);
  float diffuse = clamp(dot(normal, light), 0.0, 1.0);
  float specular = pow(max(0.0, dot(normal, normalize(light + vec3(0.0, 0.0, 1.0)))), 10.0);
  vec3 color = mix(uShade, uBody, .68 + .32 * smoothstep(.10, .95, diffuse));
  color = mix(color, uPearl, specular * .32 + exp(-depth * 48.0) * .12);
  color = mix(color, uPeriwinkle, smoothstep(.12, .90, depth) * .85);
  color = mix(color, uMist, smoothstep(.55, 1.0, depth) * .75);
  float alpha = .98 * (1.0 - smoothstep(.52, 1.0, depth)) * uOpacity;
  fragColor = vec4(color * alpha, alpha);
}
