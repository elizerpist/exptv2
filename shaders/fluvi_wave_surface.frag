#include <flutter/runtime_effect.glsl>

// The atlas already contains the visible projected shell's normal and section
// depth. It is rasterized from the same triangles as the native mesh fallback.
uniform vec2 uSize;
uniform float uOpacity;
uniform vec3 uShade;
uniform vec3 uBody;
uniform vec3 uPearl;
uniform vec3 uPeriwinkle;
uniform vec3 uMist;
uniform vec3 uIcyBlue;
uniform vec3 uLight;
uniform vec4 uCoating;
uniform vec4 uTurn;
uniform vec4 uInner;
uniform float uTurnFacingFloor;
uniform vec4 uTurnBand;
uniform vec4 uGrazing;
uniform sampler2D uSurfaceTexture;
out vec4 fragColor;

void main() {
  vec4 sampleValue = texture(uSurfaceTexture, FlutterFragCoord().xy / uSize);
  if (sampleValue.a <= .001) { fragColor = vec4(0.0); return; }
  vec3 attributes = sampleValue.rgb / sampleValue.a;
  vec2 xy = attributes.rg * 2.0 - 1.0;
  vec3 normal = normalize(vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy)))));
  float depth = attributes.b;
  vec3 light = normalize(uLight);
  float diffuse = clamp(dot(normal, light), 0.0, 1.0);
  float specular = pow(max(0.0, dot(normal, normalize(light + vec3(0.0, 0.0, 1.0)))), uCoating.y);
  vec3 color = mix(uShade, uBody, uCoating.x + (1.0 - uCoating.x) * diffuse);
  color = mix(color, uPearl, specular * uCoating.z);
  float turningLight = pow(uTurnFacingFloor + (1.0 - uTurnFacingFloor) * abs(normal.y), uCoating.w) * smoothstep(uTurnBand.x, uTurnBand.y, depth) * (1.0 - smoothstep(uTurnBand.z, uTurnBand.w, depth));
  color = mix(color, uIcyBlue, turningLight * uTurn.x);
  color = mix(color, uPeriwinkle, smoothstep(uTurn.y, uTurn.z, depth) * uTurn.w);
  color = mix(color, uMist, smoothstep(uInner.x, uInner.y, depth) * uInner.z);
  float grazingLight = pow(1.0 - abs(normal.z), uGrazing.z) * smoothstep(uGrazing.x, uGrazing.y, depth) * uGrazing.w;
  color = mix(color, uPearl, grazingLight);
  float alpha = (1.0 - smoothstep(uInner.w, 1.0, depth)) * sampleValue.a * uOpacity;
  fragColor = vec4(color * alpha, alpha);
}
